{lib, ...}: {
  user.ui = {
    cudaterm.enable = true;
    monstar.enable = lib.mkForce false;
    tomoeLua.enable = true;
    tomoe = {
      displays = {
        "DP-4" = {
          position = [0 0];
          resolution = "5120x1440";
        };
        "HDMI-A-2" = {
          position = [5120 0];
          resolution = "1920x1080@60.000";
        };
      };

      bar.modules = ["cpu" "memory" "gpu" "bongo" "time" "date"];
      extraConfig = ''
        tomoe.settings { honor_xdg_activation_with_invalid_serial = true }
        local launcher_return_focus = {}
        tomoe.on_window_open(function(win)
          if win:app_id() ~= "launcher" then
            return
          end
          local previous = tomoe.focused_window()
          launcher_return_focus[win:id()] = previous and previous:id()
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

        tomoe.on_window_close(function(win)
          local previous_id = launcher_return_focus[win:id()]
          if not previous_id then
            return
          end
          launcher_return_focus[win:id()] = nil
          if not tomoe.focused_window() then
            local previous = tomoe.window(previous_id)
            if previous then
              previous:focus()
            end
          end
        end)

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
  };
}
