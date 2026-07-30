-- ~/.config/tomoe/shell/sysinfo.lua
-- CPU / memory / GPU sampler for the bar overlay.
--
-- Upstream tomoe declares `shell.services.sysinfo` in
-- resources/moonshell/services.lua as a *placeholder* facade: the shape
-- {cpu_percent, memory_percent} exists, nothing pushes it. This file is the
-- missing push side, written in Lua so it needs no tomoe rebuild. It calls
-- the same `facade:set(snapshot)` a native Rust backend would call
-- (crates/moonshell-runtime/src/services_bridge.rs pushes battery/network
-- exactly this way), so promoting it later is: delete this file, add
-- sysinfo.rs, widgets untouched.
--
-- Sampling discipline:
--   cpu/memory/temps  pure /proc + /sys reads, sub-millisecond, no subprocess
--   gpu (amdgpu)      /sys/class/drm/cardN/device/{gpu_busy_percent,mem_info_vram_*}
--   gpu (nvidia)      nvidia-smi via shell.exec_async (~31 ms, off the
--                     compositor thread; the nvidia driver exposes no
--                     utilization counter in sysfs, only NVML/nvidia-smi)
--
-- Portability: the GPU backend is *probed at runtime*, never assumed. A
-- machine with no nvidia module and no amdgpu busy counter reports
-- gpu_available = false and the widget renders nothing — the same contract
-- upstream's battery service uses for desktops without a battery.

local M = _G.__moonshell_sysinfo or {}
_G.__moonshell_sysinfo = M

-- ── tiny sysfs/procfs helpers ──────────────────────────────────────────
-- No globbing: Lua has no glob and io.popen("ls") would spawn a shell for
-- data we can find with bounded io.open probes (a miss costs one failed
-- openat, microseconds).

local function read_file(path)
    local fh = io.open(path, "r")
    if not fh then return nil end
    local data = fh:read("*a")
    fh:close()
    return data
end

local function read_number(path)
    local data = read_file(path)
    if not data then return nil end
    return tonumber(data:match("^%s*(%-?%d+)"))
end

local function read_word(path)
    local data = read_file(path)
    if not data then return nil end
    return data:match("^%s*(%S+)")
end

local function clamp_percent(v)
    if v < 0 then return 0 end
    if v > 100 then return 100 end
    return v
end

local function round(v)
    return math.floor(v + 0.5)
end

-- ── snapshot ───────────────────────────────────────────────────────────
-- Superset of upstream's placeholder shape. cpu_percent / memory_percent
-- keep their upstream names and units so a native backend can take over.

M.state = M.state or {
    cpu_percent = 0,
    memory_percent = 0,
    memory_used_mb = 0,
    memory_total_mb = 0,
    cpu_temp_c = nil,

    gpu_available = false,
    gpu_vendor = nil, -- "nvidia" | "amd"
    gpu_percent = 0,
    gpu_mem_used_mb = 0,
    gpu_mem_total_mb = 0,
    gpu_temp_c = nil,
}

local function push()
    local svc = shell.services and shell.services.sysinfo
    if not svc then return end
    local copy = {}
    for k, v in pairs(M.state) do copy[k] = v end
    svc:set(copy)
end

--- Current snapshot. Prefers the service facade (so a future native
--- backend wins automatically); falls back to the local table.
function M.get()
    local svc = shell.services and shell.services.sysinfo
    if svc then
        local s = svc:get()
        if s and s.cpu_percent then return s end
    end
    return M.state
end

-- ── CPU utilization ────────────────────────────────────────────────────
-- /proc/stat's first line is cumulative jiffies since boot:
--   cpu user nice system idle iowait irq softirq steal guest guest_nice
-- A percentage needs two samples: busy fraction = 1 - Δidle/Δtotal.
-- "idle" for this purpose is idle+iowait (the CPU was not executing).

local prev_total, prev_idle

local function sample_cpu()
    local data = read_file("/proc/stat")
    if not data then return end
    local nums = data:match("^cpu%s+([%d%s]+)")
    if not nums then return end

    local fields, total = {}, 0
    for v in nums:gmatch("%d+") do
        local n = tonumber(v)
        fields[#fields + 1] = n
        total = total + n
    end
    if #fields < 5 then return end
    local idle = fields[4] + fields[5]

    if prev_total then
        local dtotal = total - prev_total
        local didle = idle - prev_idle
        if dtotal > 0 then
            M.state.cpu_percent = clamp_percent(round((dtotal - didle) / dtotal * 100))
        end
    end
    prev_total, prev_idle = total, idle
end

-- ── Memory ─────────────────────────────────────────────────────────────
-- MemAvailable (not MemFree) is the kernel's own estimate of what a new
-- allocation could get without swapping; free pages plus reclaimable
-- cache. Using MemFree would report ~95% used on any box with warm cache.

local function sample_memory()
    local data = read_file("/proc/meminfo")
    if not data then return end
    local total_kb = tonumber(data:match("MemTotal:%s+(%d+)"))
    local avail_kb = tonumber(data:match("MemAvailable:%s+(%d+)"))
    if not (total_kb and avail_kb and total_kb > 0) then return end

    local used_kb = total_kb - avail_kb
    M.state.memory_percent = clamp_percent(round(used_kb / total_kb * 100))
    M.state.memory_used_mb = round(used_kb / 1024)
    M.state.memory_total_mb = round(total_kb / 1024)
end

-- ── CPU temperature ────────────────────────────────────────────────────
-- hwmon indices are allocation-order, not stable across boots, so the
-- chip is found by name each start: k10temp (AMD) / coretemp (Intel),
-- then the die-wide sensor inside it (Tctl / "Package id 0").

local CPU_HWMON_NAMES = { k10temp = "Tctl", coretemp = "Package id 0", zenpower = "Tdie" }

local cpu_temp_path

local function probe_cpu_temp()
    for i = 0, 15 do
        local base = "/sys/class/hwmon/hwmon" .. i
        local name = read_word(base .. "/name")
        if name then
            local want = CPU_HWMON_NAMES[name]
            if want then
                for t = 1, 8 do
                    local label = read_file(base .. "/temp" .. t .. "_label")
                    if label and label:match("^%s*(.-)%s*$") == want then
                        return base .. "/temp" .. t .. "_input"
                    end
                end
                -- Chip matched but no labelled die sensor: temp1 is the
                -- conventional primary reading.
                if read_number(base .. "/temp1_input") then
                    return base .. "/temp1_input"
                end
            end
        end
    end
    return nil
end

local function sample_cpu_temp()
    if not cpu_temp_path then return end
    local milli = read_number(cpu_temp_path)
    if milli then M.state.cpu_temp_c = round(milli / 1000) end
end

-- ── GPU: amdgpu / generic DRM sysfs backend ────────────────────────────
-- amdgpu exports a ready-made busy percentage plus VRAM byte counters.
-- Cheap enough to poll at the same cadence as the CPU.

local function find_drm_card_with_busy(preferred)
    local function ok(card)
        return read_number("/sys/class/drm/" .. card .. "/device/gpu_busy_percent") ~= nil
    end
    if preferred and preferred ~= "" and ok(preferred) then return preferred end
    for i = 0, 9 do
        local card = "card" .. i
        if ok(card) then return card end
    end
    return nil
end

local function find_card_hwmon(card)
    local base = "/sys/class/drm/" .. card .. "/device/hwmon"
    for i = 0, 15 do
        local path = base .. "/hwmon" .. i .. "/temp1_input"
        if read_number(path) then return path end
    end
    return nil
end

local function make_amd_sampler(card)
    local dev = "/sys/class/drm/" .. card .. "/device/"
    local temp_path = find_card_hwmon(card)
    return function()
        local busy = read_number(dev .. "gpu_busy_percent")
        if not busy then return end
        M.state.gpu_percent = clamp_percent(busy)
        local used = read_number(dev .. "mem_info_vram_used")
        local total = read_number(dev .. "mem_info_vram_total")
        if used and total and total > 0 then
            M.state.gpu_mem_used_mb = round(used / 1048576)
            M.state.gpu_mem_total_mb = round(total / 1048576)
        end
        if temp_path then
            local milli = read_number(temp_path)
            if milli then M.state.gpu_temp_c = round(milli / 1000) end
        end
    end
end

-- ── GPU: NVIDIA backend ────────────────────────────────────────────────
-- The proprietary driver publishes no utilization counter under /sys or
-- /proc; NVML is the only source and nvidia-smi is its CLI. Ran async so
-- the ~31 ms never touches the compositor thread. In-flight guard: a slow
-- call must not stack up behind the next tick.

local nvidia_inflight = false
local nvidia_failures = 0
local NVIDIA_QUERY =
    "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu "
    .. "--format=csv,noheader,nounits 2>/dev/null"

local function nvidia_present()
    -- Kernel module loaded? Cheaper and more honest than shelling out to
    -- `command -v nvidia-smi`, and it stays false in a container without
    -- the device passed through.
    return read_file("/proc/driver/nvidia/version") ~= nil
end

local function sample_nvidia()
    if nvidia_inflight or nvidia_failures >= 3 then return end
    nvidia_inflight = true
    shell.exec_async(NVIDIA_QUERY, function(out)
        nvidia_inflight = false
        local util, used, total, temp =
            (out or ""):match("(%d+),%s*(%d+),%s*(%d+),%s*(%d+)")
        if not util then
            nvidia_failures = nvidia_failures + 1
            if nvidia_failures >= 3 then
                M.state.gpu_available = false
                io.stderr:write("sysinfo: nvidia-smi unusable, GPU module disabled\n")
                push()
            end
            return
        end
        nvidia_failures = 0
        M.state.gpu_percent = clamp_percent(tonumber(util))
        M.state.gpu_mem_used_mb = tonumber(used)
        M.state.gpu_mem_total_mb = tonumber(total)
        M.state.gpu_temp_c = tonumber(temp)
        push()
    end)
end

-- Pick a GPU backend. `prefer` is "auto" | "nvidia" | "amd" | "none".
-- auto favours a discrete NVIDIA card over an AMD iGPU, because on a
-- hybrid box (this desktop: card1 Raphael iGPU + card2 RTX 4090) the
-- iGPU's busy counter reads ~0 while the dGPU does all the work.
local function probe_gpu(prefer, card_hint)
    prefer = prefer or "auto"
    if prefer == "none" then return nil end

    if (prefer == "auto" or prefer == "nvidia") and nvidia_present() then
        M.state.gpu_vendor = "nvidia"
        M.state.gpu_available = true
        return sample_nvidia
    end

    if prefer == "auto" or prefer == "amd" then
        local card = find_drm_card_with_busy(card_hint)
        if card then
            M.state.gpu_vendor = "amd"
            M.state.gpu_available = true
            return make_amd_sampler(card)
        end
    end

    return nil
end

-- ── start ──────────────────────────────────────────────────────────────
-- Idempotent per VM: a second BarOverlay.open() in the same Lua state must
-- not register a second set of timers. A config reload builds a fresh VM,
-- which clears _G and therefore this guard.

--- @param opts table|nil
---   cpu_interval    ms between /proc/stat samples (default 1000)
---   memory_interval ms between /proc/meminfo samples (default 2000)
---   gpu_interval    ms between GPU samples (default 2000)
---   gpu_prefer      "auto" | "nvidia" | "amd" | "none"
---   gpu_card        DRM card hint for the sysfs backend, e.g. "card1"
function M.start(opts)
    if M._started then return M end
    M._started = true
    opts = opts or {}

    cpu_temp_path = probe_cpu_temp()
    local gpu_sampler = probe_gpu(opts.gpu_prefer, opts.gpu_card)

    -- One immediate pass so the bar is populated on the first frame
    -- instead of after a full interval (cpu_percent needs two samples and
    -- stays 0 until the second tick — unavoidable with delta counters).
    sample_cpu()
    sample_memory()
    sample_cpu_temp()
    if gpu_sampler then gpu_sampler() end
    push()

    shell.interval(opts.cpu_interval or 1000, function()
        sample_cpu()
        sample_cpu_temp()
        push()
    end)

    shell.interval(opts.memory_interval or 2000, function()
        sample_memory()
        push()
    end)

    if gpu_sampler then
        shell.interval(opts.gpu_interval or 2000, function()
            gpu_sampler()
            push()
        end)
    end

    return M
end

return M
