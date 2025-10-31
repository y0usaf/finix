{config, ...}: {
  home-manager.users.y0usaf.services.syncthing = {
    enable = true;

    settings = {
      devices = {
        desktop = {
          id = "KII4S2Y-KWA6M4K-MCQAUOO-C6PMX4L-V5JVDPW-HHZF52D-HP57BNH-EKCCZQC";
        };
        laptop = {
          id = "EAHAPON-XKBJVGI-44SGTXR-WU6BF5U-WZKHJXS-7QNTBHQ-D4ICOVA-I346HQ7";
        };
        server = {
          id = "GY3T3SL-3JOOX3I-2SE72PF-V6ZSTIE-QI4EIYK-OBL6IDV-4IWLDDG-VM2ATAG";
        };
        phone = {
          id = "JYAIN4T-MXQYDAP-2M6CSKX-KKRYVJC-5GMSRYP-LSZRRRV-QSOWY7W-YNQGOAC";
          compression = "never";
        };
      };

      folders = {
        tokens = {
          id = "bv79n-fh4kx";
          label = "Tokens";
          path = "${config.user.homeDirectory}/Tokens";
          devices = ["desktop" "laptop" "server" "phone"];
        };
      };
    };
  };
}
