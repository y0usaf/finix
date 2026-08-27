{
  config,
  lib,
  ...
}: let
  toJSON = lib.generators.toJSON {};
in {
  config = lib.mkIf config.user.dev.pi.enable {
    # Both extensions write their default config files. pi runs from any
    # context (DE launcher, tmux, systemd) — file beats env var.
    manzil.users."${config.user.name}".files = {
      # Caveman: reads ~/.pi/agent/caveman.json on session start.
      ".pi/agent/caveman.json" = {
        generator = toJSON;
        value = {
          defaultLevel = "ultra";
          showStatus = true;
        };
      };

      # Ponytail: ~/.pi/agent/ponytail.json (patched from
      # ~/.config/ponytail/config.json in pi-flake).
      ".pi/agent/ponytail.json" = {
        generator = toJSON;
        value = {
          defaultMode = "ultra";
        };
      };
    };
  };
}