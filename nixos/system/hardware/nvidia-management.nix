{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.hardware.nvidia.management;

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
      import argparse
      import json
      import sys
      from pathlib import Path
      from pynvml import (
          nvmlDeviceGetHandleByIndex,
          nvmlDeviceSetFanSpeed_v2,
          nvmlDeviceSetGpcClkVfOffset,
          nvmlDeviceSetGpuLockedClocks,
          nvmlDeviceSetMemClkVfOffset,
          nvmlInit,
      )


      CONFIG_PATH = Path(
          "${configFile}"
      )


      def init_handle():
          nvmlInit()
          return nvmlDeviceGetHandleByIndex(0)


      def load_config(path: Path) -> dict:
          if not path.exists():
              raise FileNotFoundError(f"Config file not found: {path}")
          with path.open() as f:
              return json.load(f)


      def apply_settings(config: dict):
          handle = init_handle()

          max_clock = config.get("maxClock")
          min_clock = config.get("minClock", 300)
          if max_clock is not None:
              nvmlDeviceSetGpuLockedClocks(handle, min_clock, max_clock)
              print(f"✓ Set GPU clocks to min {min_clock} MHz / max {max_clock} MHz")

          core_offset = config.get("coreVoltageOffset")
          if core_offset is not None:
              validate_voltage(core_offset)
              nvmlDeviceSetGpcClkVfOffset(handle, core_offset)
              print(f"✓ Set core voltage offset to {core_offset} mV")

          mem_offset = config.get("memoryVoltageOffset")
          if mem_offset is not None:
              validate_voltage(mem_offset)
              nvmlDeviceSetMemClkVfOffset(handle, mem_offset)
              print(f"✓ Set memory voltage offset to {mem_offset} mV")

          fan_speed = config.get("fanSpeed")
          if fan_speed is not None:
              validate_fan_speed(fan_speed)
              nvmlDeviceSetFanSpeed_v2(handle, 0, fan_speed)
              print(f"✓ Set fan speed to {fan_speed}%")

          print("NVIDIA management applied successfully")


      def validate_fan_speed(speed: int):
          if not 0 <= speed <= 100:
              raise ValueError("Fan speed must be between 0 and 100")


      def validate_voltage(offset: int):
          if not -200 <= offset <= 100:
              raise ValueError("Voltage offset must be between -200 and 100 mV")


      def cmd_apply(_args):
          config = load_config(CONFIG_PATH)
          apply_settings(config)


      def cmd_fan(args):
          speed = int(args.speed)
          validate_fan_speed(speed)
          handle = init_handle()
          nvmlDeviceSetFanSpeed_v2(handle, 0, speed)
          print(f"✓ Set GPU fan speed to {speed}%")


      def cmd_core_voltage(args):
          offset = int(args.offset)
          validate_voltage(offset)
          handle = init_handle()
          nvmlDeviceSetGpcClkVfOffset(handle, offset)
          print(f"✓ Set core voltage offset to {offset} mV")


      def cmd_mem_voltage(args):
          offset = int(args.offset)
          validate_voltage(offset)
          handle = init_handle()
          nvmlDeviceSetMemClkVfOffset(handle, offset)
          print(f"✓ Set memory voltage offset to {offset} mV")


      def build_parser():
          parser = argparse.ArgumentParser(
              prog="nvidia-management",
              description="NVIDIA GPU management (clocks, voltage, fans)",
          )
          sub = parser.add_subparsers(dest="command", required=True)

          apply_parser = sub.add_parser(
              "apply",
              help="Apply settings from config file"
          )
          apply_parser.set_defaults(func=cmd_apply)

          fan_parser = sub.add_parser(
              "fan",
              help="Set fan speed (0-100)"
          )
          fan_parser.add_argument(
              "speed",
              type=int,
              help="Fan speed percentage"
          )
          fan_parser.set_defaults(func=cmd_fan)

          core_parser = sub.add_parser(
              "core-voltage",
              help="Set core voltage offset (mV)"
          )
          core_parser.add_argument(
              "offset",
              type=int,
              help="Voltage offset in mV (-200 to 100)"
          )
          core_parser.set_defaults(func=cmd_core_voltage)

          mem_parser = sub.add_parser(
              "mem-voltage",
              help="Set memory voltage offset (mV)"
          )
          mem_parser.add_argument(
              "offset",
              type=int,
              help="Voltage offset in mV (-200 to 100)"
          )
          mem_parser.set_defaults(func=cmd_mem_voltage)

          return parser


      def main(argv=None):
          parser = build_parser()
          args = parser.parse_args(argv)
          try:
              args.func(args)
          except Exception as e:
              print(f"Error: {e}", file=sys.stderr)
              sys.exit(1)


      if __name__ == "__main__":
          main()
    '';
in {
  options.hardware.nvidia.management = {
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
    environment.systemPackages = [nvidiaMgmtScript];

    systemd.services.nvidia-management = {
      description = "NVIDIA GPU Management (clocks, voltage, fans)";
      wantedBy = ["multi-user.target"];
      after = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe nvidiaMgmtScript} apply";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      unitConfig = {
        ConditionPathExists = "/dev/nvidiactl";
      };
    };
  };
}
