{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.ui.niri;
  inherit (config.home.core) defaults;
  agsEnabled = config.home.ui.ags.enable or false;
  # Force rebuild - updated launcher command
in {
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = [
        pkgs.niri
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.jq
        pkgs.swaybg
      ];
      files = {
        ".config/niri/config.kdl" = {
          text = ''
            ${builtins.readFile ./config/config.kdl}

            // Nix-interpolated startup commands
            spawn-at-startup "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
            spawn-at-startup "sh" "-c" "swaybg -i $(find ${config.home.directories.wallpapers.static.path} -type f | shuf -n 1) -m fill"
            ${lib.optionalString agsEnabled ''spawn-at-startup "${pkgs.ags}/bin/ags" "run" "/home/${config.user.name}/.config/ags/bar-overlay.tsx"''}

            // Nix-interpolated bind commands
            binds {
                "Mod+T" { spawn "${defaults.terminal}"; }
                "Super+R" { spawn "foot" "-a" "launcher" "${config.user.configDirectory}/scripts/sway-launcher-desktop.sh"; }

                "Mod+1" { spawn "${defaults.ide}"; }
                "Mod+2" { spawn "${defaults.browser}"; }
                "Mod+3" { spawn "vesktop"; }
                "Mod+4" { spawn "steam"; }
                "Mod+5" { spawn "obs"; }

                "Mod+E" { spawn "${defaults.fileManager}"; }
                "Mod+Shift+O" { spawn "${defaults.terminal}" "-e" "${defaults.editor}"; }

                "Mod+Shift+C" { spawn "sh" "-c" "killall swaybg; swaybg -i $(find ${config.home.directories.wallpapers.static.path} -type f | shuf -n 1) -m fill &"; }
            }
          '';
          clobber = true;
        };
      };
    };
  };
}
