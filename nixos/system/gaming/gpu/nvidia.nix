{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.gaming.gpu.nvidia;

  nvidiaConfig = builtins.toJSON {
    maxClock = cfg.maxClock;
    minClock = cfg.minClock;
    coreVoltageOffset = cfg.coreVoltageOffset;
    memoryVoltageOffset = cfg.memoryVoltageOffset;
    fanSpeed = cfg.fanSpeed;
  };

  configFile = pkgs.writeText "nvidia-config.json" nvidiaConfig;

  nvidiaMgmtScript =
    pkgs.writers.writePython3Bin "nvidia-management" {
      libraries = with pkgs.python313Packages; [nvidia-ml-py];
    } ''
      import json
      import sys
      from pynvml import (
          nvmlInit,
          nvmlDeviceGetHandleByIndex,
          nvmlDeviceSetGpuLockedClocks,
          nvmlDeviceSetGpcClkVfOffset,
          nvmlDeviceSetMemClkVfOffset,
          nvmlDeviceSetFanSpeed_v2,
      )

      try:
          cfg_file = '${configFile}'
          with open(cfg_file) as f:
              config = json.load(f)

          nvmlInit()
          handle = nvmlDeviceGetHandleByIndex(0)

          # Apply GPU locked clocks
          if config.get('maxClock'):
              nvmlDeviceSetGpuLockedClocks(
                  handle,
                  config.get('minClock', 300),
                  config['maxClock']
              )
              print("✓ Set GPU clocks")

          # Apply core voltage offset
          if config.get('coreVoltageOffset') is not None:
              nvmlDeviceSetGpcClkVfOffset(handle, config['coreVoltageOffset'])
              print("✓ Set core voltage offset")

          # Apply memory voltage offset
          if config.get('memoryVoltageOffset') is not None:
              nvmlDeviceSetMemClkVfOffset(handle, config['memoryVoltageOffset'])
              print("✓ Set memory voltage offset")

          # Set fan speed
          if config.get('fanSpeed') is not None:
              nvmlDeviceSetFanSpeed_v2(handle, 0, config['fanSpeed'])
              print("✓ Set fan speed")

          print("NVIDIA management applied successfully")

      except Exception as e:
          print(f"Error applying NVIDIA settings: {e}", file=sys.stderr)
          sys.exit(1)
    '';

  nvifaControlScript =
    pkgs.writers.writePython3Bin "nvidia-set-fan" {
      libraries = with pkgs.python313Packages; [nvidia-ml-py];
    } ''
      import sys
      from pynvml import (
          nvmlInit,
          nvmlDeviceGetHandleByIndex,
          nvmlDeviceSetFanSpeed_v2,
      )

      if len(sys.argv) != 2:
          print("Usage: nvidia-set-fan <speed_0_to_100>")
          sys.exit(1)

      try:
          speed = int(sys.argv[1])
          if not 0 <= speed <= 100:
              print("Error: Speed must be between 0 and 100")
              sys.exit(1)

          nvmlInit()
          handle = nvmlDeviceGetHandleByIndex(0)
          nvmlDeviceSetFanSpeed_v2(handle, 0, speed)
          print(f"✓ Set GPU fan speed to {speed}%")

      except ValueError:
          print("Error: Speed must be an integer")
          sys.exit(1)
      except Exception as e:
          print(f"Error setting fan speed: {e}", file=sys.stderr)
          sys.exit(1)
    '';
in {
  options.gaming.gpu.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU management (clocks, voltage, fans)";
    maxClock = lib.mkOption {
      type = lib.types.int;
      default = 2500;
      description = "Maximum GPU clock in MHz";
    };
    minClock = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Minimum GPU clock in MHz";
    };
    coreVoltageOffset = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Core voltage offset in mV (negative = undervolt)";
    };
    memoryVoltageOffset = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Memory voltage offset in mV (negative = undervolt)";
    };
    fanSpeed = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Fan speed percentage (0-100), null for auto";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      nvidiaMgmtScript
      nvifaControlScript
    ];

    systemd.services.nvidia-management = {
      description = "NVIDIA GPU Management (clocks, voltage, fans)";
      wantedBy = ["multi-user.target"];
      after = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe nvidiaMgmtScript}";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      unitConfig = {
        ConditionPathExists = "/dev/nvidiactl";
      };
    };
  };
}
