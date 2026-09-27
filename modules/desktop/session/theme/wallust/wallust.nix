{
  config,
  lib,
  pkgs,
  ...
}: let
  wallustPkg = pkgs.wallust;
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".cache/wallust"
  ];
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
      (lib.importJSON ./colorschemes.json))
      // (lib.mapAttrs' (name: _:
        lib.nameValuePair ".config/wallust/templates/${name}" {
          text = builtins.readFile ./templates/${name};
        })
      (builtins.readDir ./templates))
      // {
        ".config/wallust/wallust.toml" = {
          generator = (pkgs.formats.toml {}).generate "nix-generated.toml";
          value = {
            backend = "fastresize";
            color_space = "lch";
            palette = "dark";
            check_contrast = true;
            templates = {
              cmus-colors = {
                template = "cmus-colors.theme";
                target = "~/.config/cmus/wallust-auto.theme";
              };
              colors-css = {
                template = "colors.css";
                target = "~/.cache/wallust/colors.css";
              };
              discord-colors = {
                template = "discord-colors.css";
                target = "~/.config/Vencord/themes/wallust-colors.css";
              };
              foot-colors = {
                template = "foot-colors.ini";
                target = "~/.cache/wallust/colors_foot.ini";
              };
              gtk-colors = {
                template = "gtk-colors.css";
                target = "~/.cache/wallust/gtk-colors.css";
              };
              monstar-colors = {
                template = "monstar-theme";
                target = "~/.cache/wallust/colors_monstar";
              };
              obsidian-colors = {
                template = "obsidian-colors.css";
                target = "~/Documents/obsidian/.obsidian/snippets/wallust-colours.css";
              };
              pywal-colors = {
                template = "colors.json";
                target = "~/.cache/wal/colors.json";
              };
              rudo-osc = {
                template = "rudo-osc.sh";
                target = "~/.cache/wallust/rudo-osc.sh";
              };
              rudo-theme = {
                template = "rudo-theme.toml";
                target = "~/.cache/wallust/rudo-theme.toml";
              };
              shell-colors = {
                template = "shell-colors.sh";
                target = "~/.cache/wallust/shell-colors.sh";
              };
              vesktop-colors = {
                template = "discord-colors.css";
                target = "~/.config/vesktop/themes/wallust-colors.css";
              };
            };
          };
        };
      };
  };
}
