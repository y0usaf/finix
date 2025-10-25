{pkgs, ...}: {
  # Home-manager configuration for user services
  home-manager.users.y0usaf = {
    # Syncthing configuration
    services.syncthing = {
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
          # Tokens folder - shared on all devices including macbook
          tokens = {
            id = "bv79n-fh4kx";
            label = "Tokens";
            path = "/Users/y0usaf/Tokens";
            devices = ["desktop" "laptop" "server" "phone"];
          };
        };
      };
    };

    # Git configuration
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "y0usaf";
          email = "OA99@Outlook.com";
        };
      };
    };

    # SSH configuration
    programs.ssh = {
      enable = true;

      matchBlocks = {
        "*" = {
          # Global defaults for all hosts
          forwardAgent = true;
          addKeysToAgent = "yes";
          serverAliveInterval = 60;
          serverAliveCountMax = 5;
          controlMaster = "auto";
          controlPath = "%d/.ssh/master-%r@%h:%p";
          controlPersist = "10m";
          setEnv = {
            TERM = "xterm-256color";
          };
        };

        "server" = {
          hostname = "192.168.2.66";
          user = "y0usaf";
        };

        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "/Users/y0usaf/Tokens/id_rsa_y0usaf";
        };

        "forgejo" = {
          hostname = "y0usaf-server";
          port = 2222;
          user = "forgejo";
          identityFile = "/Users/y0usaf/Tokens/id_rsa_y0usaf";
          identitiesOnly = true;
        };
      };
    };

    # SSH agent service via launchd
    launchd.agents.ssh-agent = {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.openssh}/bin/ssh-agent"
          "-D"
          "-a"
          "/Users/y0usaf/.ssh/agent.sock"
        ];
        Sockets = {
          Listeners = {
            SockPathName = "/Users/y0usaf/.ssh/agent.sock";
          };
        };
      };
    };

    # Set SSH_AUTH_SOCK environment variable
    home.sessionVariables = {
      SSH_AUTH_SOCK = "/Users/y0usaf/.ssh/agent.sock";
    };

    # Home-manager state version
    home.stateVersion = "24.11";
  };
}
