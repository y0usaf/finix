-- ~/.config/tomoe/shell/bar_overlay.lua
-- Local bar overlay config (nur's bar_overlay; runs in tomoe's VM
-- in-process — folded into the tomoe module with the fusion).
--
-- Uses one compositor-centered layer-shell surface per edge. Module blocks
-- render inside that fixed-width centered surface, so positioning is delegated
-- to the compositor instead of computed from an assumed display width.

local Wallust = _G.__moonshell_wallust
    or dofile(os.getenv("HOME") .. "/.config/tomoe/shell/wallust.lua")
_G.__moonshell_wallust = Wallust
local theme = require("moonshell.theme")

local DEFAULTS = @DEFAULTS@

local M = _G.__moonshell_widgets_bar_overlay or {}
_G.__moonshell_widgets_bar_overlay = M
M._layout_generation = M._layout_generation or 0
M._font_family = M._font_family or DEFAULTS.font_family

local DEFAULT_MODULES = DEFAULTS.modules

local function label(text)
    Wallust.version:get()
    return ui.text({
        content = tostring(text or ""),
        color = Wallust.color("fg", theme.text),
        weight = DEFAULTS.label.weight,
        size = DEFAULTS.label.size,
        font_family = M._font_family,
    })
end

local function block(children, opts)
    opts = opts or {}
    Wallust.version:get()

    return ui.hbox({
        width = opts.width,
        height = opts.height,
        gap = opts.gap or DEFAULTS.block.gap,
        bg = Wallust.color("bg", theme.base),
        border = opts.border or DEFAULTS.block.border,
        border_color = Wallust.color("accent", theme.accent),
        padding_top = opts.padding_top or opts.padding_y or DEFAULTS.block.padding_y, -- 0.15em
        padding_bottom = opts.padding_bottom or opts.padding_y or DEFAULTS.block.padding_y,
        padding_left = opts.padding_left or opts.padding_x or DEFAULTS.block.padding_x, -- 0.3em
        padding_right = opts.padding_right or opts.padding_x or DEFAULTS.block.padding_x,
        children = children or {},
    })
end

local function clock_state(format, interval_ms)
    local state = shell.state(os.date(format))
    shell.interval(interval_ms, function()
        state:set(os.date(format))
    end)
    return state
end

local function close_existing(name)
    -- moonshell window handles don't expose :close yet (PLAN M4);
    -- hot reload swaps the whole VM (windows included), so this
    -- only matters for same-VM re-open — pcall keeps it safe.
    local old = shell.get_window(name)
    if old then pcall(function() old:close() end) end
end

local function open_bongo(opts)
    local cfg = opts.bongo_cat or DEFAULTS.bongo_cat
    if not cfg or not cfg.enable then return nil end

    local keyboard = shell.services.keyboard
    if not keyboard then
        io.stderr:write("moonshell: no shell.services.keyboard facade; skipping bongo cat\n")
        return nil
    end
    local height = cfg.height or 80
    local width = math.floor(height * 864 / 360 + 0.5)
    local dir = cfg.asset_dir
    local paths = {
        both_up = dir .. "/bongo-cat-both-up.png",
        left_down = dir .. "/bongo-cat-left-down.png",
        right_down = dir .. "/bongo-cat-right-down.png",
        both_down = dir .. "/bongo-cat-both-down.png",
    }
    local frame = shell.state(paths.both_up)
    local left_token, right_token = 0, 0
    local left_live, right_live = false, false

    local function update_frame()
        local next_frame = paths.both_up
        if left_live and right_live then
            next_frame = paths.both_down
        elseif left_live then
            next_frame = paths.left_down
        elseif right_live then
            next_frame = paths.right_down
        end
        if frame:get() ~= next_frame then frame:set(next_frame) end
    end

    local last_sequence = keyboard:get().sequence
    keyboard:subscribe(function()
        local event = keyboard:get()
        if event.sequence == last_sequence then return end
        last_sequence = event.sequence
        if event.hand == "left" then
            left_token = left_token + 1
            local token = left_token
            left_live = true
            shell.once(cfg.keypress_duration or 100, function()
                if left_token == token then
                    left_live = false
                    update_frame()
                end
            end)
        else
            right_token = right_token + 1
            local token = right_token
            right_live = true
            shell.once(cfg.keypress_duration or 100, function()
                if right_token == token then
                    right_live = false
                    update_frame()
                end
            end)
        end
        update_frame()
    end)

    local name = cfg.name or "bongo-cat"
    close_existing(name)
    -- Layer-shell centers a bottom-anchored surface; margins on the
    -- unanchored edges are ignored, so x_offset is applied inside
    -- the surface: widen it by |x_offset| and justify the cat to
    -- the opposite edge. Negative offset = cat left of center.
    local x_offset = cfg.x_offset or 0
    -- Smithay arranges every layer surface — overlay included —
    -- inside the zone left by exclusive bars, so a bottom-exclusive
    -- widget bar pushes the cat up by the bar's whole thickness.
    -- Subtract it back: the cat is a free overlay and keeps its
    -- screen-edge margin.
    -- In-process (the tomoe global exists) native surfaces
    -- anchor to raw output edges, so no compensation needed;
    -- standalone layer-shell arranges overlays inside the
    -- exclusive zone and needs the margin pulled back.
    local exclusive_zone = 0
    if _G.tomoe == nil and opts.exclusive == true then
        for _, e in ipairs(opts.edges or DEFAULTS.edges or {}) do
            if e == "bottom" then
                exclusive_zone = (opts.height or DEFAULTS.height)
                    + (opts.indent or DEFAULTS.indent or 0)
            end
        end
    end
    local win = shell.window({
        name = name,
        anchor = DEFAULTS.anchors.bottom,
        popup_width = width + math.abs(x_offset),
        height = height,
        margin_bottom = (cfg.margin_bottom or 0) - exclusive_zone,
        layer = cfg.layer or "overlay",
        exclusive = false,
        bg = "#00000000",
    })
    win:render(function()
        return ui.hbox({
            width = width + math.abs(x_offset),
            height = height,
            justify = x_offset < 0 and "end" or "start",
            children = { ui.image({ src = frame:get(), width = width, height = height }) },
        })
    end)
    return win
end

function M.new(opts)
    opts = opts or {}

    local self = {
        modules = opts.modules or DEFAULT_MODULES,
        time = opts.time_state or clock_state(opts.time_format or DEFAULTS.time.format, opts.time_interval or DEFAULTS.time.interval),
        date = opts.date_state or clock_state(opts.date_format or DEFAULTS.date.format, opts.date_interval or DEFAULTS.date.interval),
    }

    function self:battery_block(width, height)
        local battery = shell.services.battery:get()
        local percent = battery.percent or 0
        local arrow = battery.charging and "↑" or "↓"

        return block({
            label(percent .. "%"),
            label(arrow),
        }, { width = width, height = height, gap = DEFAULTS.battery.gap })
    end

    function self:time_block(width, height)
        return block({ label(self.time:get()) }, { width = width, height = height })
    end

    function self:date_block(width, height)
        return block({ label(self.date:get()) }, { width = width, height = height })
    end

    -- Native in-VM service (tomoe FUSION.md F3): no subprocess polling.
    -- (sysinfo has only a placeholder facade upstream — nothing pushes
    -- it — so no sysinfo block here.)
    function self:network_block(width, height)
        local net = shell.services.network:get()
        local text = (net.connected and net.ssid and net.ssid ~= "") and net.ssid or "offline"
        return block({ label(text) }, { width = width, height = height })
    end

    function self:render_module(name, width, height)
        if name == "battery" then return self:battery_block(width, height) end
        if name == "time" then return self:time_block(width, height) end
        if name == "date" then return self:date_block(width, height) end
        if name == "network" then return self:network_block(width, height) end
        return ui.hbox({ width = width, height = height, children = {} })
    end

    return self
end

local function module_widths(opts)
    opts = opts or {}
    return {
        battery = opts.battery_width or DEFAULTS.module_widths.battery,
        time = opts.time_width or DEFAULTS.module_widths.time,
        date = opts.date_width or DEFAULTS.module_widths.date,
        network = opts.network_width or DEFAULTS.module_widths.network,
    }
end

local function render_edge(content, items, total_width, height, spacing)
    local children = {}
    for _, item in ipairs(items) do
        children[#children + 1] = content:render_module(item.name, item.width, height)
    end

    return ui.hbox({
        width = total_width,
        height = height,
        gap = spacing or DEFAULTS.block.gap,
        children = children,
    })
end

local function open_edge(edge, content, items, total_width, opts)
    local height = opts.height or DEFAULTS.height
    local fg = Wallust.hex(Wallust.color("fg", theme.text))
    local name = opts.name or ((opts.name_prefix or DEFAULTS.name_prefix) .. "-" .. edge)
    local spacing = opts.spacing or DEFAULTS.spacing
    local exclusive = opts.exclusive == true
    local indent = opts.indent or DEFAULTS.indent or 0

    close_existing(name)

    local win, render_fn
    if exclusive then
        -- Popup-anchored surfaces can't hold an exclusive zone (and
        -- overlay-layer zones are ignored), so the no-overlap bar is
        -- a full-width edge bar on the top layer. The widget row
        -- stays centered via justify; windows stop at its edge.
        render_fn = function()
            local children = {}
            for _, item in ipairs(items) do
                children[#children + 1] = content:render_module(item.name, item.width, height)
            end
            local row = ui.hbox({
                height = height,
                justify = "center",
                gap = spacing,
                children = children,
            })
            if indent <= 0 then return row end
            -- Indent: row pinned to the top of the taller surface;
            -- the empty strip below sits inside the exclusive zone,
            -- so windows respect the gap.
            return ui.vbox({
                align = "center",
                children = { row },
            })
        end
        win = shell.window({
            name = name,
            position = edge,
            height = height + indent,
            layer = "top",
            exclusive = true,
            bg = opts.bg or DEFAULTS.bg,
            fg = fg,
            font_size = opts.font_size or DEFAULTS.font_size,
            font_family = M._font_family,
        })
    else
        render_fn = function()
            return render_edge(content, items, total_width, height, spacing)
        end
        win = shell.window({
            name = name,
            anchor = DEFAULTS.anchors[edge],
            popup_width = total_width,
            height = height,
            margin_top = edge == "top" and (opts.margin_top or DEFAULTS.margin_top) or DEFAULTS.margin_top,
            margin_bottom = edge == "bottom" and (opts.margin_bottom or DEFAULTS.margin_bottom) or DEFAULTS.margin_bottom,
            layer = opts.layer or DEFAULTS.layer,
            exclusive = false,
            bg = opts.bg or DEFAULTS.bg,
            fg = fg,
            font_size = opts.font_size or DEFAULTS.font_size,
            font_family = M._font_family,
        })
    end
    win:render(render_fn)

    -- Until the runtime has fine-grained Lua dependency tracking, refresh
    -- these tiny module windows directly so clock/date repaint exactly
    -- when their backing state changes.
    shell.interval(opts.refresh_interval or DEFAULTS.refresh_interval, function()
        if opts.layout_generation and opts.layout_generation ~= M._layout_generation then return end
        win:render(render_fn)
    end)

    for _, item in ipairs(items) do
        item.window = win
    end
    return win
end

function M.open(opts)
    opts = opts or {}
    if opts.font_family then M._font_family = opts.font_family end
    M._layout_generation = M._layout_generation + 1
    local layout_generation = M._layout_generation
    Wallust.watch(opts.wallust_path)

    close_existing(opts.top_name or DEFAULTS.top_name)
    close_existing(opts.bottom_name or DEFAULTS.bottom_name)

    local modules = opts.modules or DEFAULT_MODULES
    local widths = module_widths(opts)
    local height = opts.height or DEFAULTS.height
    local spacing = opts.spacing or DEFAULTS.spacing
    local edges = opts.edges or DEFAULTS.edges

    local function has_edge(edge)
        for _, e in ipairs(edges) do
            if e == edge then return true end
        end
        return false
    end

    local items = {}
    for _, name in ipairs(modules) do
        if widths[name] then
            items[#items + 1] = { name = name, width = widths[name] }
        end
    end

    local total = 0
    for i, item in ipairs(items) do
        total = total + item.width
        if i > 1 then total = total + spacing end
    end

    local time = clock_state(opts.time_format or DEFAULTS.time.format, opts.time_interval or DEFAULTS.time.interval)
    local date = clock_state(opts.date_format or DEFAULTS.date.format, opts.date_interval or DEFAULTS.date.interval)

    local result = { items = items }

    if has_edge("top") then
        result.top_content = M.new({
            modules = modules,
            time_state = time,
            date_state = date,
        })
        result.top_window = open_edge("top", result.top_content, items, total, {
            name = opts.top_name or DEFAULTS.top_name,
            height = height,
            spacing = spacing,
            name_prefix = opts.name_prefix,
            margin_top = opts.margin_top,
            exclusive = opts.exclusive,
            refresh_interval = opts.refresh_interval,
            layout_generation = layout_generation,
        })
    end

    if has_edge("bottom") then
        result.bottom_content = M.new({
            modules = modules,
            time_state = time,
            date_state = date,
        })
        result.bottom_window = open_edge("bottom", result.bottom_content, items, total, {
            name = opts.bottom_name or DEFAULTS.bottom_name,
            height = height,
            spacing = spacing,
            name_prefix = opts.name_prefix,
            margin_bottom = opts.margin_bottom,
            exclusive = opts.exclusive,
            refresh_interval = opts.refresh_interval,
            layout_generation = layout_generation,
        })
    end

    result.bongo_window = open_bongo(opts)

    return result
end

return M
