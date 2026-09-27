{
  config,
  lib,
  pkgs,
  ...
}: let
  wallustPkg = pkgs.wallust;
  wallustCfg = config.user.appearance.wallust;

  inherit (lib.types) anything attrsOf lines str submodule;
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

          wallust "$@"

          sleep 0.5

          if [ -t 1 ] && [ -f "$HOME/.cache/wallust/rudo-osc.sh" ]; then
            sh "$HOME/.cache/wallust/rudo-osc.sh"
          fi

          pywalfox --browser librewolf update


        '';
      })
    ];

    manzil.users."${config.user.name}" = {
      files =
        (lib.mapAttrs' (name: scheme:
          lib.nameValuePair ".config/wallust/colorschemes/${name}.json" {
            generator = lib.generators.toJSON {};
            value = scheme;
          })
        wallustCfg.colorschemes)
        // (lib.mapAttrs' (name: template:
          lib.nameValuePair ".config/wallust/templates/${name}" {
            text = template;
          })
        wallustCfg.templates)
        // {
          ".config/wallust/wallust.toml" = {
            generator = (pkgs.formats.toml {}).generate "nix-generated.toml";
            value = {
              backend = "fastresize";
              color_space = "lch";
              palette = "dark";
              check_contrast = true;
              templates = wallustCfg.targets;
            };
          };
        };
    };
  };
}
