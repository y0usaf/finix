-- ─── Binds (mirroring niri/keybindings.nix; Mod = Alt) ───────────────────────
-- Mod+t is the ekko terminal. Ekko retitles its host window to
-- "ekko …" while a client is attached, and the spawned terminal
-- also carries the "ekko-term" app-id, so a later press focuses
-- the live window — hopping to its workspace first — instead of
-- spawning another client onto the shared session.
local function ekko_window()
  for _, win in ipairs(tomoe.windows()) do
    local title = win:title() or ""
    if win:app_id() == "ekko-term" or title:match("^ekko") then
      return win
    end
  end
end
tomoe.bind("Mod+t", function()
  local win = ekko_window()
  if not win then
    tomoe.spawn(nix.terminal .. " --app-id ekko-term")
    return
  end
  -- Hop to the window's workspace first: wm.switch shows it via
  -- arrange; focus on a hidden window is a no-op.
  for n, wins in pairs(wm.workspaces or {}) do
    if n ~= wm.active then
      for _, w in ipairs(wins) do
        if w:id() == win:id() then
          wm.switch(n)
        end
      end
    end
  end
  -- Deck layout only: focus() on a buried window leaves it behind
  -- the column's front. Promote it to the deck front, then arrange
  -- — `vis`/`column` are the deck chunk's locals, absent under sway.
  if type(vis) == "function" and type(column) == "table" then
    local side = column[win:id()]
    if side then
      vis()[side] = win:id()
      wm.arrange()
    end
  end
  win:show()
  win:raise()
  win:focus()
end, "Terminal")
tomoe.bind("Mod+Shift+r", "reload-config", "Reload Config")
tomoe.bind("Super+r", function() tomoe.spawn(nix.launcher) end, "Run an Application")
tomoe.bind("Mod+e", function() tomoe.spawn("pcmanfm") end, "File Manager")
tomoe.bind("Super+Shift+o", function() tomoe.spawn(nix.terminal .. " -e nvim") end, "Editor")
tomoe.bind("Mod+q", wm.close_focused, "Close Window")
tomoe.bind("Mod+f", wm.toggle_fullscreen, "Toggle Fullscreen")
tomoe.bind("Super+space", toggle_floating, "Toggle Floating")
tomoe.bind("Mod+Shift+e", "quit")
tomoe.bind("Mod+Shift+slash", "show-hotkey-overlay")

-- ─── Displays ────────────────────────────────────────────────────────────────
tomoe.bind("Mod+9", function()
  if blanked_outputs then
    for _, name in ipairs(blanked_outputs) do
      if blanked_ad_hoc[name] then
        displays[name] = nil
      elseif displays[name] then
        -- Missing disabled parses as false in lua.rs, so clear it
        -- explicitly on restore while retaining all other settings.
        displays[name].disabled = false
      end
    end
    blanked_outputs = nil
    blanked_ad_hoc = {}
    tomoe.settings { displays = displays }
    return
  end

  local outputs = tomoe.outputs()
  if #outputs == 0 then
    return
  end
  blanked_outputs = {}
  for _, output in ipairs(outputs) do
    local name = output.name
    if displays[name] == nil then
      displays[name] = {}
      blanked_ad_hoc[name] = true
    end
    displays[name].disabled = true
    blanked_outputs[#blanked_outputs + 1] = name
  end
  tomoe.settings { displays = displays }
end, "Blank/Restore All Outputs")

-- ─── Screenshots / wallpaper ─────────────────────────────────────────────────
tomoe.bind("Mod+g", "screenshot", "Screenshot")
tomoe.bind("Mod+Shift+g", "screenshot-screen", "Screenshot Screen")
tomoe.bind("Mod+Shift+c", function() tomoe.spawn("killall swaybg; swaybg -i " .. random_wallpaper .. " -m fill &") end, "Random Wallpaper")

-- ─── Media ───────────────────────────────────────────────────────────────────
tomoe.bind("XF86AudioRaiseVolume", function() tomoe.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") end)
tomoe.bind("XF86AudioLowerVolume", function() tomoe.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") end)
tomoe.bind("XF86AudioMute", function() tomoe.spawn("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") end)
tomoe.bind("XF86AudioPlay", function() tomoe.spawn("playerctl play-pause") end)
tomoe.bind("XF86AudioNext", function() tomoe.spawn("playerctl next") end)
tomoe.bind("XF86AudioPrev", function() tomoe.spawn("playerctl previous") end)
tomoe.bind("XF86AudioMicMute", function() tomoe.spawn("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") end)
tomoe.bind("XF86MonBrightnessUp", function() tomoe.spawn("brightnessctl set 5%+") end)
tomoe.bind("XF86MonBrightnessDown", function() tomoe.spawn("brightnessctl set 5%-") end)
