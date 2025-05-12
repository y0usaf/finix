#===============================================================================
#                      🟣 Vesktop Configuration 🟣
#===============================================================================
# Vesktop: Alternate Discord client with Vencord built-in
# See: https://github.com/Vencord/Vesktop
#===============================================================================
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.programs.vesktop;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.programs.vesktop = {
    enable = lib.mkEnableOption "Vesktop (Discord client) module";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.vesktop;
      description = "The vesktop package to use.";
    };
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Vesktop settings written to $XDG_CONFIG_HOME/vesktop/settings.json.";
    };
    vencord = {
      settings = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Vencord settings written to $XDG_CONFIG_HOME/vesktop/settings/settings.json.";
      };
      themes = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Themes to add for Vencord.";
      };
      useSystem = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable Vencord package from Nixpkgs.";
      };
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."vesktop/settings.json".text = builtins.toJSON cfg.settings;
    xdg.configFile."vesktop/settings/settings.json".text = builtins.toJSON cfg.vencord.settings;
    # Themes and useSystem can be handled as needed by user
  };
}
