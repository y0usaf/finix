-- ~/.config/tomoe/shell/wallust.lua
-- Live Wallust -> moonshell.theme bridge (port of nur.wallust).
--
-- Reads ~/.cache/wallust/gtk-colors.css, applies the GTK color tokens,
-- and exposes a reactive version state so widgets repaint when Wallust
-- regenerates colors.

local theme = require("moonshell.theme")

local M = {}

M.path = os.getenv("WALLUST_GTK_COLORS")
    or ((os.getenv("HOME") or "/home/@USER@") .. "/.cache/wallust/gtk-colors.css")

M.version = shell.state(0)

M.colors = {
    bg = theme.base,
    fg = theme.text,
    accent = theme.accent,
    black = theme.crust or 0x000000,
}

local function shquote(s)
    s = tostring(s or "")
    -- Built from string.char(39) = single-quote to dodge nix
    -- indented-string escapes; esc is the POSIX quote-escape
    -- sequence: quote, backslash-quote, quote.
    local q = string.char(39)
    local esc = q .. "\\" .. q .. q
    return q .. s:gsub(q, esc) .. q
end

local function hex_to_int(value)
    if not value then return nil end
    local s = tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
    local hex = s:match("#([%x]+)") or s:match("^([%x]+)$")
    if not hex or #hex < 6 then return nil end
    hex = hex:sub(1, 6)
    return tonumber(hex, 16)
end

local function resolve_value(name, raw, seen)
    seen = seen or {}
    if not name or seen[name] then return nil end
    seen[name] = true

    local value = raw[name]
    if not value then return nil end

    local direct = hex_to_int(value)
    if direct then return direct end

    local ref = tostring(value):match("^@([%w_%-]+)$")
    if ref then return resolve_value(ref, raw, seen) end

    return nil
end

local function parse_css(css)
    css = css or ""
    local raw = {}

    -- Wallust GTK syntax: @define-color bg #rrggbb;
    for name, value in css:gmatch("@define%-color%s+([%w_%-]+)%s+([^;%s]+)") do
        raw[name] = value
    end

    -- Also accept CSS custom property syntax: --bg: #rrggbb;
    for name, value in css:gmatch("%-%-([%w_%-]+)%s*:%s*([^;%s]+)") do
        raw[name] = value
    end

    local out = {}
    for name, _ in pairs(raw) do
        out[name] = resolve_value(name, raw)
    end

    out.bg = out.bg or out.background or out.color0
    out.fg = out.fg or out.foreground or out.color15 or out.color7
    out.accent = out.accent or out.color4 or out.color5 or out.color6 or out.fg
    out.black = out.black or out.color0 or out.background or 0x000000

    return out
end

local function channel(color, shift)
    return math.floor(color / (2 ^ shift)) % 256
end

function M.mix(a, b, amount)
    amount = math.max(0, math.min(1, amount or 0.5))
    local ar, ag, ab = channel(a, 16), channel(a, 8), channel(a, 0)
    local br, bg, bb = channel(b, 16), channel(b, 8), channel(b, 0)
    local r = math.floor(ar + (br - ar) * amount + 0.5)
    local g = math.floor(ag + (bg - ag) * amount + 0.5)
    local bl = math.floor(ab + (bb - ab) * amount + 0.5)
    return r * 0x10000 + g * 0x100 + bl
end

function M.hex(color)
    return string.format("#%06x", color or 0)
end

function M.color(name, fallback)
    return M.colors[name] or fallback
end

function M.apply_css(css)
    local parsed = parse_css(css or "")

    M.colors.bg = parsed.bg or M.colors.bg
    M.colors.fg = parsed.fg or M.colors.fg
    M.colors.accent = parsed.accent or M.colors.accent
    M.colors.black = parsed.black or M.colors.black

    for name, value in pairs(parsed) do
        if value then M.colors[name] = value end
    end

    local hover = M.mix(M.colors.bg, M.colors.fg, 0.10)

    theme:set({
        base = M.colors.bg,
        mantle = M.colors.bg,
        crust = M.colors.black,
        surface0 = M.colors.bg,
        surface1 = hover,
        surface2 = M.colors.accent,

        text = M.colors.fg,
        subtext1 = M.colors.fg,
        subtext0 = M.colors.fg,

        accent = M.colors.accent,
        blue = M.colors.accent,
        sapphire = M.colors.accent,

        black = M.colors.black,
        font_size = 14,
        font_family = "monospace",
        bar_height = 24,
        widget_gap = 8,
        bar_padding = 0,
    })

    M.version:set(M.version:get() + 1)
end

function M.load(path)
    if path then M.path = path end
    local q = shquote(M.path)
    local css = shell.exec("if [ -r " .. q .. " ]; then cat " .. q .. "; fi")
    M.apply_css(css)
end

function M.watch(path)
    if path then M.path = path end
    M.load(M.path)

    if M._watched_path ~= M.path then
        M._watched_path = M.path
        shell.watch_file(M.path, function(css)
            M.apply_css(css)
        end)
    end
end

return M
