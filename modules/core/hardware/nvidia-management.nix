{
  config,
  pkgs,
  lib,
  ...
}: let
  nvidiaMgmt = config.hardware.nvidia.management;
  nvidiaMgmtScript =
    pkgs.writers.writePython3Bin "nvidia-management" {
      libraries = [pkgs.python313Packages.nvidia-ml-py];
    } ''
      import argparse
      import json
      import signal
      import sys
      import time
      from pathlib import Path
      from pynvml import (
          NVML_TEMPERATURE_GPU,
          nvmlDeviceGetHandleByIndex,
          nvmlDeviceGetNumFans,
          nvmlDeviceGetTemperature,
          nvmlDeviceSetDefaultFanSpeed_v2,
          nvmlDeviceSetFanSpeed_v2,
          nvmlDeviceSetGpcClkVfOffset,
          nvmlDeviceSetGpuLockedClocks,
          nvmlDeviceSetMemClkVfOffset,
          nvmlInit,
      )


      CONFIG_PATH = Path(
          "${pkgs.writeText "nvidia-config.json" (builtins.toJSON {
        inherit (nvidiaMgmt) maxClock minClock coreVoltageOffset memoryVoltageOffset fanCurve fanCurveInterval;
      })}"
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

          print("NVIDIA management applied successfully")


      def validate_fan_speed(speed: int):
          if not 0 <= speed <= 100:
              raise ValueError("Fan speed must be between 0 and 100")


      def validate_voltage(offset: int):
          if not -200 <= offset <= 100:
              raise ValueError("Voltage offset must be between -200 and 100 mV")


      def interpolate_fan_speed(curve: list, temp: int) -> int:
          if temp <= curve[0]["temp"]:
              return curve[0]["speed"]
          if temp >= curve[-1]["temp"]:
              return curve[-1]["speed"]
          for i in range(len(curve) - 1):
              lo = curve[i]
              hi = curve[i + 1]
              if lo["temp"] <= temp <= hi["temp"]:
                  ratio = (temp - lo["temp"]) / (hi["temp"] - lo["temp"])
                  return int(lo["speed"] + ratio * (hi["speed"] - lo["speed"]))
          return curve[-1]["speed"]


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


      def cmd_watch(_args):
          config = load_config(CONFIG_PATH)
          curve = sorted(config.get("fanCurve", []), key=lambda p: p["temp"])
          interval = config.get("fanCurveInterval", 5)

          if not curve:
              print("No fan curve configured", file=sys.stderr)
              sys.exit(1)

          handle = init_handle()
          num_fans = nvmlDeviceGetNumFans(handle)
          running = True

          def handle_signal(signum, frame):
              nonlocal running
              running = False

          signal.signal(signal.SIGTERM, handle_signal)
          signal.signal(signal.SIGINT, handle_signal)

          print(f"Starting fan curve daemon (interval={interval}s, fans={num_fans})")

          while running:
              temp = nvmlDeviceGetTemperature(handle, NVML_TEMPERATURE_GPU)
              target_speed = interpolate_fan_speed(curve, temp)
              for i in range(num_fans):
                  nvmlDeviceSetFanSpeed_v2(handle, i, target_speed)
              print(f"Temp: {temp}C -> Fan: {target_speed}%")
              time.sleep(interval)

          for i in range(num_fans):
              nvmlDeviceSetDefaultFanSpeed_v2(handle, i)
          print("Fan control restored to automatic")


      def cmd_fan_restore(_args):
          handle = init_handle()
          num_fans = nvmlDeviceGetNumFans(handle)
          for i in range(num_fans):
              nvmlDeviceSetDefaultFanSpeed_v2(handle, i)
          print(f"Restored {num_fans} fan(s) to automatic control")


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

          watch_parser = sub.add_parser(
              "watch",
              help="Run temperature-reactive fan curve daemon"
          )
          watch_parser.set_defaults(func=cmd_watch)

          restore_parser = sub.add_parser(
              "fan-restore",
              help="Restore fans to automatic control"
          )
          restore_parser.set_defaults(func=cmd_fan_restore)

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

  mkOpt = lib.mkOption;
  inherit (lib) types mkIf getExe;
  typeInt = types.int;
  typeNullOrInt = types.nullOr typeInt;
in {
  options.hardware.nvidia.management = {
    enable = lib.mkEnableOption "NVIDIA GPU management (clocks, voltage, fans)";
    maxClock = mkOpt {
      type = typeInt;
      default = 2500;
      description = "Maximum GPU clock in MHz";
    };
    minClock = mkOpt {
      type = typeInt;
      default = 300;
      description = "Minimum GPU clock in MHz";
    };
    coreVoltageOffset = mkOpt {
      type = typeNullOrInt;
      default = null;
      description = "Core voltage offset in mV (negative = undervolt)";
    };
    memoryVoltageOffset = mkOpt {
      type = typeNullOrInt;
      default = null;
      description = "Memory voltage offset in mV (negative = undervolt)";
    };
    fanCurve = mkOpt {
      type = types.listOf (types.submodule {
        options = {
          temp = mkOpt {
            type = typeInt;
            description = "GPU temperature in °C";
          };
          speed = mkOpt {
            type = typeInt;
            description = "Fan speed percentage";
          };
        };
      });
      default = [];
      description = "Fan curve as temp/speed points. A single point gives a fixed speed at all temperatures.";
    };
    fanCurveInterval = mkOpt {
      type = typeInt;
      default = 5;
      description = "Polling interval in seconds for fan curve daemon.";
    };
  };

  config = mkIf nvidiaMgmt.enable {
    environment.systemPackages = [nvidiaMgmtScript];

    systemd = {
      services = {
        nvidia-management = {
          description = "NVIDIA GPU Management (clocks, voltage, fans)";
          wantedBy = ["multi-user.target"];
          after = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${getExe nvidiaMgmtScript} apply";
            StandardOutput = "journal";
            StandardError = "journal";
          };
          unitConfig = {
            ConditionPathExists = "/dev/nvidiactl";
          };
        };
        nvidia-fan-curve = mkIf (nvidiaMgmt.fanCurve != []) {
          description = "NVIDIA GPU Fan Curve Daemon";
          wantedBy = ["multi-user.target"];
          after = ["multi-user.target"];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${getExe nvidiaMgmtScript} watch";
            ExecStop = "${getExe nvidiaMgmtScript} fan-restore";
            Restart = "on-failure";
            RestartSec = "5s";
            StandardOutput = "journal";
            StandardError = "journal";
          };
          unitConfig = {
            ConditionPathExists = "/dev/nvidiactl";
          };
        };
      };
    };
  };
}
