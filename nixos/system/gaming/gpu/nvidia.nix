{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.gaming.gpu.nvidia;
in {
  options.gaming.gpu.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU optimizations for gaming";
    maxClock = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Maximum GPU clock in MHz (null to disable)";
    };
    coreOffset = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "GPU core clock offset in MHz (null to disable)";
    };
    memOffset = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "GPU memory clock offset in MHz (null to disable)";
    };
    powerLimit = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Power limit in watts (null to disable)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.nvidia_oc];

    systemd.services.nvidia-overclock = {
      description = "NVIDIA GPU overclocking/undervolting";
      wantedBy = ["multi-user.target"];
      after = ["nvidia-persistenced.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${lib.getExe pkgs.nvidia_oc} set --index 0 --min-clock 0 \
          ${lib.optionalString (cfg.maxClock != null) "--max-clock ${toString cfg.maxClock}"} \
          ${lib.optionalString (cfg.coreOffset != null) "--freq-offset ${toString cfg.coreOffset}"} \
          ${lib.optionalString (cfg.memOffset != null) "--mem-offset ${toString (cfg.memOffset * 2)}"} \
          ${lib.optionalString (cfg.powerLimit != null) "--power-limit ${toString (cfg.powerLimit * 1000)}"}
        '';
      };
    };
  };
}
