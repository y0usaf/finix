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
      default = {
        desktop.id = "KII4S2Y-KWA6M4K-MCQAUOO-C6PMX4L-V5JVDPW-HHZF52D-HP57BNH-EKCCZQC";
        laptop.id = "EAHAPON-XKBJVGI-44SGTXR-WU6BF5U-WZKHJXS-7QNTBHQ-D4ICOVA-I346HQ7";
        framework.id = "ICJT4KW-Q4KTA73-W2CO2HS-DCG6AFG-NXZTZPA-UI34ITG-4LW4NOT-BGB36AB";
        server.id = "GY3T3SL-3JOOX3I-2SE72PF-V6ZSTIE-QI4EIYK-OBL6IDV-4IWLDDG-VM2ATAG";
        phone = {
          id = "JYAIN4T-MXQYDAP-2M6CSKX-KKRYVJC-5GMSRYP-LSZRRRV-QSOWY7W-YNQGOAC";
          compression = "never";
        };
      };
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
        inherit (config.user.services.syncthing) devices folders;
      };
    };
  };
}
