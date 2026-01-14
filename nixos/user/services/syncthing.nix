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
        gui.address = [
          "127.0.0.1:8384"
          "localhost:8384"
          "syncthing-desktop:8384"
          "syncthing-server:8384"
        ];
        inherit (config.user.services.syncthing) devices;
        folders =
          lib.optionalAttrs (config.hostname == "y0usaf-server") {
            music = {
              id = "oty33-aq3dt";
              label = "Music";
              path = "${config.user.homeDirectory}/Music";
              devices = ["desktop" "server" "phone"];
            };
            dcim = {
              id = "ti9yk-zu3xs";
              label = "DCIM";
              path = "${config.user.homeDirectory}/DCIM";
              devices = ["desktop" "server" "phone"];
            };
            pictures = {
              id = "zbxzv-35v4e";
              label = "Pictures";
              path = "${config.user.homeDirectory}/Pictures";
              devices = ["desktop" "server" "phone"];
            };
          }
          // config.user.services.syncthing.folders;
      };
    };
  };
}
