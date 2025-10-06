{
  config,
  lib,
  ...
}: let
  cfg = config.home.services.syncthing;
in {
  options.home.services.syncthing = {
    enable = lib.mkEnableOption "Syncthing service";

    user = lib.mkOption {
      type = lib.types.str;
      default = config.user.name;
      description = "User to run Syncthing as";
    };

    devices = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {};
      description = "Syncthing devices configuration";
    };

    folders = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {};
      description = "Syncthing folders configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = cfg.user;
      dataDir = config.user.homeDirectory;
      configDir = "${config.user.homeDirectory}/.config/syncthing";

      settings = {
        devices = cfg.devices;
        folders = cfg.folders;
      };
    };
  };
}
