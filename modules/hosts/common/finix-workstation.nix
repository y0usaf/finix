{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    pkgs.efibootmgr
    pkgs.btrfs-progs
  ];

  networking.hosts."100.105.204.116" = ["y0usaf-server"];

  finix.persistence.identity.restoreMachineId = true;

  manzil = {
    finit.conditions = ["task/persist-user-binds/success"];
    clobberByDefault = true;
  };

  services = {
    getty.ttys = ["tty1" "tty2"];
    openssh.settings.Port = [2222];
    nix-daemon.settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters =
        [
          "http://192.168.2.66:8787/cache"
          "http://y0usaf-server:8787/cache"
        ]
        ++ lib.optional config.hardware.nvidia.enable "https://cuda-maintainers.cachix.org";
      trusted-public-keys =
        ["cache:lPd94Ltnv0ZYpkoK5UtQi/VrGkEtHRT7Af6jUzy3PLA="]
        ++ lib.optional config.hardware.nvidia.enable "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E=";
      connect-timeout = 5;
      fallback = true;
      download-attempts = 1;
    };
  };
}
