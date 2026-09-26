-- The compositor core is mechanism-only; ALL window management below
-- comes from the `wm` module — Lua code built on the same public API
-- your config uses. Don't require it and write your own to replace the
-- WM wholesale.

local wm = require("wm")
wm.gaps = 8
-- The layout chunk below is selected by user.ui.tomoe.layout: "deck"
-- (two 16:9 columns, default) or "sway" (manual splits over workspaces).

-- settings.displays is clear-and-rebuild: every settings call drops
-- entries omitted from the table, so the toggle must re-send this
-- complete mutable table rather than a partial disabled-only table.
local displays = nix.displays
-- tomoe.outputs() becomes empty when every connector is disabled;
-- retain names here so restore does not need to enumerate dark outputs.
local blanked_outputs = nil
local blanked_ad_hoc = {}
local settings = {
  -- Alt, matching the niri setup this replaced (niri/input.nix mod-key).
  mod = "alt",
  border = { width = 2, focused = "#7aa2f7", unfocused = "#3b4261" },
  -- Dual-kawase blur behind shell layer surfaces, matched by
  -- namespace (= shell.window name): widget bars + notification
  -- popups. Bongo cat excluded — a blurred rect around a
  -- transparent overlay reads as a smudge.
  blur = {
    enabled = true,
    passes = 3,
    offset = 1.0,
    anti_artifact_margin = 96,
    layer_namespaces = { "bar-overlay-top", "bar-overlay-bottom", "moonshell.notifications" },
  },
  displays = displays,
}
if nix.nvidia then
  -- NVIDIA: a fenced frame queued to KMS before its render completes
  -- hangs the driver (whole-session freeze, niri discussion #3777);
  -- wait for the render CPU-side instead. NVIDIA-only: on any other
  -- GPU this just serializes every frame for nothing.
  settings.wait_for_frame_completion = true
end
tomoe.settings(settings)


-- Disable regular-window blur: off/on testing implicated it in
-- right-half flicker at 240 Hz on the desktop's NVIDIA/Samsung setup.
-- Layer-surface blur (panels and notifications) remains enabled.
tomoe.rule {
  apply = function(win)
    win:set_properties({ blur = false })
  end,
}

-- ─── Processes ───────────────────────────────────────────────────────────────
-- Single-quote a string for sh -c command lines built from nix values.
local function sh_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local random_wallpaper = "$(find " .. sh_quote(nix.wallpaper_dir) .. " -type f | shuf -n 1)"

tomoe.process.once("xwayland-satellite", { command = { nix.bin.xwayland_satellite } })
tomoe.process.once("swaybg", { command = {
  "sh", "-c",
  "swaybg -i " .. random_wallpaper .. " -m fill",
} })

-- ─── Shell (in-process since the fusion) ─────────────────────────────────
-- Compositor-drawn screencast picker: the portal asks this VM over
-- IPC and gets a tomoe.ui.menu — no foot+fzf chooser script. Rule
-- escape hatches: tomoe.rule { app_id = "^obs$", screencast = "DP-2" }
-- casts that output without asking; screencast = false denies.
require("screencast")

if nix.bar then
  -- Bar overlay + wallust bridge, deployed next to this file by the
  -- same module (folded in from ~/.config/moonshell; runs in this VM
  -- with zero extra processes and zero IPC — tomoe FUSION.md F2/F3).
  local _ms_font = shell.exec("fc-match monospace --format='%{family}'")
  if _ms_font == "" then _ms_font = "monospace" end
  local BarOverlay = dofile(os.getenv("HOME") .. "/.config/tomoe/shell/bar_overlay.lua")
  local _bar_opts = nix.bar
  _bar_opts.font_family = _ms_font
  BarOverlay.open(_bar_opts)
end

-- Notification popups: the compositor hosts the notification daemon
-- (FUSION.md F3); this builtin renders notify-send popups with ui.*,
-- colored from the wallust palette the bar just applied (a snapshot
-- at load — live wallust regenerates recolor on config reload).
local _Wallust = _G.__moonshell_wallust
local function _wc(name)
  local v = _Wallust and _Wallust.color(name)
  if type(v) == "number" then return _Wallust.hex(v) end
  return v
end
require("moonshell.notifications").setup({
  bg = _wc("bg"),
  fg = _wc("fg"),
  body_fg = _wc("fg"),
})

-- ─── Floating (shared by both layouts) ──────────────────────────────────────
-- Super+space toggles; the active layout's wm.arrange reads this set and
-- keeps floated windows raised above the tiling.
local floating = {} -- window id -> true: stays in its workspace, outside tiling

local function toggle_floating()
  local win = tomoe.focused_window()
  if not win then
    return
  end
  local id = win:id()
  -- Niri's floating transition normalizes fullscreen first. Do the
  -- same here: a fullscreen client becomes tiled on the first press
  -- instead of making Super+Space a no-op.
  if wm.fullscreen[id] or win:is_fullscreen() then
    floating[id] = nil
    wm.set_fullscreen(win, false)
    win:focus()
    return
  end
  if floating[id] then
    floating[id] = nil
    wm.arrange()
  else
    floating[id] = true
    wm.arrange()
    local area = tomoe.usable_area()
    local w = math.floor(area.w * 0.6)
    local h = math.floor(area.h * 0.6)
    win:set_geometry(
      area.x + math.floor((area.w - w) / 2),
      area.y + math.floor((area.h - h) / 2),
      w, h)
  end
  win:focus()
end

tomoe.on_reload("deck-floating", function()
  local ids = {}
  for id in pairs(floating) do
    ids[#ids + 1] = id
  end
  return ids
end, function(ids)
  floating = {}
  for _, id in ipairs(ids or {}) do
    if tomoe.window(id) then
      floating[id] = true
    end
  end
  wm.arrange()
end)
