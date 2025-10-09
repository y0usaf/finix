{
  config,
  lib,
  ...
}: {
  options.user.services.syncthing = {
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

  config = lib.mkIf config.user.services.syncthing.enable {
    services.syncthing = {
      enable = true;
      inherit (config.user.services.syncthing) user;
      dataDir = config.user.homeDirectory;
      configDir = "${config.user.homeDirectory}/.config/syncthing";

      settings = {
        inherit (config.user.services.syncthing) devices folders;
      };
    };
  };
}
