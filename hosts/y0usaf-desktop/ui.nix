_: {
  user.ui = {
    nur.enable = false; # replaced by moonshell (nur's successor)
    moonshell.enable = true;
    cursor.enable = true;
    fonts.enable = true;
    foot.enable = true;
    gtk = {
      enable = true;
      scale = 1.5;
    };
    niri = {
      enable = false;
      extraConfig = ''
        window-rule {
          match app-id="launcher"
          open-floating true
        }
      '';
    };
    hyprland.enable = false;
    shojiwm.enable = false;
    tomoe = {
      enable = true;
      displays = {
        "DP-2" = {
          position = [0 0];
          resolution = "5120x1440@239.761";
        };
        "DP-4" = {
          position = [0 0];
          resolution = "5120x1440@239.761";
        };
        "HDMI-A-2" = {
          position = [5120 0];
          resolution = "1920x1080@60.000";
        };
      };
      extraConfig = ''
        -- Float the launcher (app-id "launcher") above the tiling flow.
        -- tomoe has no rule API; the wm module is plain Lua, so pull the
        -- window back out of its tiling list (wm's own on_window_open hook
        -- runs first) and center it in the usable area instead.
        tomoe.on_window_open(function(win)
          if win:app_id() ~= "launcher" then
            return
          end
          for i, w in ipairs(wm.workspaces[wm.active]) do
            if w:id() == win:id() then
              table.remove(wm.workspaces[wm.active], i)
              break
            end
          end
          wm.arrange()
          local area = tomoe.usable_area()
          local geo = win:geometry()
          local w = geo and geo.w or 0
          local h = geo and geo.h or 0
          if w == 0 or h == 0 then
            w, h = math.floor(area.w / 3), math.floor(area.h / 3)
          end
          win:set_geometry(
            area.x + math.floor((area.w - w) / 2),
            area.y + math.floor((area.h - h) / 2),
            w, h)
          win:raise()
          win:focus()
        end)

        -- Hide the lovely-injector console (app-id "steam_proton", title
        -- "Lovely x.y.z") — a blank proton terminal. Keep it alive but out
        -- of the tiling flow: the rule stops it stealing focus on open, and
        -- an arrange sweep hides it and drops it from the workspace lists
        -- (also catching windows a config reload restores back in).
        local function is_lovely(win)
          return win:app_id() == "steam_proton"
            and (win:title() or ""):find("^Lovely")
        end
        tomoe.rule { app_id = "^steam_proton$", title = "^Lovely", focus = false }
        local deck_arrange = wm.arrange
        function wm.arrange(...)
          for ws = 1, wm.workspace_count do
            local wins = wm.workspaces[ws]
            for i = #wins, 1, -1 do
              if is_lovely(wins[i]) then
                wins[i]:hide()
                table.remove(wins, i)
              end
            end
          end
          return deck_arrange(...)
        end
      '';
    };
    wayland.enable = true;
  };
}
