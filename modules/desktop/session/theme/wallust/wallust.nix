{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  wallustPkg = pkgs.wallust;
  wallustCfg = config.user.appearance.wallust;

  inherit (builtins) toJSON;
  inherit (lib.types) anything attrsOf lines listOf str submodule;
in {
  options.user.appearance.wallust = {
    defaultTheme = lib.mkOption {
      type = str;
      default = "dopamine";
      description = "Default theme to apply on login.";
    };

    colorschemes = lib.mkOption {
      type = attrsOf anything;
      default = {};
      description = "Named Wallust colorschemes rendered to ~/.config/wallust/colorschemes.";
    };

    templates = lib.mkOption {
      type = attrsOf lines;
      default = {};
      description = "Wallust templates rendered to ~/.config/wallust/templates.";
    };

    targets = lib.mkOption {
      type = attrsOf (submodule {
        options = {
          template = lib.mkOption {
            type = str;
            description = "Template filename from ~/.config/wallust/templates.";
          };

          target = lib.mkOption {
            type = str;
            description = "Output path written by Wallust.";
          };
        };
      });
      default = {};
      description = "Wallust [templates] entries keyed by target name.";
    };

    startupDirs = lib.mkOption {
      type = listOf str;
      default = [
        "~/.config/zellij/layouts"
        "~/.cache/wal"
        "~/.cache/wallust"
        "~/.config/Vencord/settings"
        "~/.config/vesktop/settings"
        "~/.config/ags"
        "~/.local/share/vicinae/themes"
      ];
      description = "Directories created before applying the default Wallust theme.";
    };

    reloadHooks = lib.mkOption {
      type = listOf lines;
      default = [];
      description = "Shell snippets run by wt after Wallust and pywalfox updates.";
    };
  };

  config = {
    environment.systemPackages = [
      wallustPkg
      (pkgs.writeShellApplication {
        name = "wt";
        runtimeInputs = [wallustPkg pkgs.pywalfox-native];
        text = ''
          if [ -z "''${1:-}" ]; then
            echo "Usage: wt <command> [args...]"
            echo "Commands: cs <colorscheme>, theme <name>, run <image>"
            exit 1
          fi

          # Pass all args to wallust
          wallust "$@"

          # Brief delay for file write (avoid race conditions)
          sleep 0.5

          # Push live palette updates to the current terminal when supported
          if [ -t 1 ] && [ -f "$HOME/.cache/wallust/rudo-osc.sh" ]; then
            sh "$HOME/.cache/wallust/rudo-osc.sh"
          fi

          # Update pywalfox
          pywalfox --browser librewolf update

          ${lib.concatStringsSep "\n" wallustCfg.reloadHooks}
        '';
      })
    ];

    systemd.user.services.wallust-default = {
      description = "Apply default wallust theme";
      wantedBy = ["graphical-session-pre.target"];
      before = ["graphical-session.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "wallust-default" (({
            defaultTheme,
            wallustBin,
          }: ''
            # Ensure output directories exist (wallust templates write here)
            ${lib.concatMapStringsSep "\n" (dir: "mkdir -p ${dir}") wallustCfg.startupDirs}

            ${wallustBin} ${
              if builtins.hasAttr defaultTheme wallustCfg.colorschemes
              then "cs ~/.config/wallust/colorschemes/${defaultTheme}.json"
              else "theme ${defaultTheme}"
            }
          '') {
            wallustBin = "${wallustPkg}/bin/wallust";
            inherit (wallustCfg) defaultTheme;
          });
        RemainAfterExit = true;
      };
    };

    manzil.users."${config.user.name}" =
      {
        files =
          (lib.mapAttrs' (name: scheme:
            lib.nameValuePair ".config/wallust/colorschemes/${name}.json" {
              text = toJSON scheme;
            })
          wallustCfg.colorschemes)
          // (lib.mapAttrs' (name: template:
            lib.nameValuePair ".config/wallust/templates/${name}" {
              text = template;
            })
          wallustCfg.templates)
          // {
            ".config/wallust/wallust.toml" = {
              text = ''
                backend = "fastresize"
                color_space = "lch"
                palette = "dark"
                check_contrast = true

                [templates]
                ${lib.concatStringsSep "\n" (lib.mapAttrsToList (
                    name: target: ''${name} = { template = "${target.template}", target = "${target.target}" }''
                  )
                  wallustCfg.targets)}
              '';
            };
          };
      }
      // lib.optionalAttrs (lib.attrByPath ["user" "shell" "zellij" "zjstatus" "enable"] false config) {
        xdg.config.files."zellij/plugins/zjstatus-hints.wasm".source = "${flakeInputs.zjstatus-hints.packages."${pkgs.stdenv.hostPlatform.system}".default}/bin/zjstatus-hints.wasm";
      };
  };
}
