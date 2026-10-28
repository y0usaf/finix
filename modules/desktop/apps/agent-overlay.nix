{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  userName = config.user.name;
  runtimeDir = "/run/user/${toString config.users.users.${userName}.uid}";
  overlay = flakeInputs.agent-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  config = lib.mkIf config.hardware.nvidia.enable {
    finit.services.agent-overlay = {
      description = "agent-overlay creatures on the Tomoe bar (${userName})";
      user = userName;
      environment = {
        HOME = config.users.users.${userName}.home;
        XDG_RUNTIME_DIR = runtimeDir;
        WAYLAND_DISPLAY = "tomoe-0";
      };
      path = ["/run/current-system/sw"];
      command = "${pkgs.writeShellScript "agent-overlay-start" ''
        while [ ! -S ${runtimeDir}/tomoe-0 ]; do
          ${pkgs.coreutils}/bin/sleep 1
        done
        exec ${overlay}/bin/overlay
      ''}";
      log = true;
    };
  };
}
