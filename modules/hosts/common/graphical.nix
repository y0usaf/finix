{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [../../finix/desktop];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    i2c.enable = true;
  };

  services = {
    udev.enable = true;
    seatd.enable = true;
    dbus.enable = true;
    bluetooth.enable = true;
    polkit.enable = true;
    rtkit.enable = true;
    upower.enable = true;
    udisks2.enable = true;
    nftables.enable = true;
    networkmanager = {
      enable = true;
      settings.main.rc-manager = "resolvconf";
    };
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

  users.users.${config.user.name}.extraGroups = ["networkmanager" "video" "render" "seat"];

  system.activation.scripts.networkManagerConnections = {
    deps = ["etc"];
    text = ''
      src=/persist/etc/NetworkManager/system-connections
      dst=/etc/NetworkManager/system-connections
      ${pkgs.coreutils}/bin/install -d -m 0700 "$dst"
      if [ -d "$src" ]; then
        ${pkgs.findutils}/bin/find "$src" -maxdepth 1 -type f -exec \
          ${pkgs.coreutils}/bin/install -m 0600 -o root -g root {} "$dst/" \;
      fi
    '';
  };
  programs.resolvconf.enable = true;

  xdg = {
    portal.enable = true;
    icons.enable = true;
    mime.enable = true;
  };

  fonts.fontconfig.enable = true;

  environment.systemPackages = [
    pkgs.efibootmgr
  ];

  networking.hosts."100.105.204.116" = ["y0usaf-server"];

  manzil = {
    finit.conditions = ["task/persist-user-binds/success"];
    clobberByDefault = true;
  };
}
