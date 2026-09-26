
local wm = require("wm")
wm.gaps = 8

local displays = nix.displays
local blanked_outputs = nil
local blanked_ad_hoc = {}
local settings = {
  mod = "alt",
  border = { width = 2, focused = "#7aa2f7", unfocused = "#3b4261" },
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
  settings.wait_for_frame_completion = true
end
tomoe.settings(settings)

tomoe.rule {
  apply = function(win)
    win:set_properties({ blur = false })
  end,
}

local function sh_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local random_wallpaper = "$(find " .. sh_quote(nix.wallpaper_dir) .. " -type f | shuf -n 1)"

tomoe.process.once("xwayland-satellite", { command = { nix.bin.xwayland_satellite } })
tomoe.process.once("swaybg", { command = {
  "sh", "-c",
  "swaybg -i " .. random_wallpaper .. " -m fill",
} })

require("screencast")

if nix.bar then
  local _ms_font = shell.exec("fc-match monospace --format='%{family}'")
  if _ms_font == "" then _ms_font = "monospace" end
  local BarOverlay = dofile(os.getenv("HOME") .. "/.config/tomoe/shell/bar_overlay.lua")
  local _bar_opts = nix.bar
  _bar_opts.font_family = _ms_font
  BarOverlay.open(_bar_opts)
end

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

local floating = {}

local function toggle_floating()
  local win = tomoe.focused_window()
  if not win then
    return
  end
  local id = win:id()
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
