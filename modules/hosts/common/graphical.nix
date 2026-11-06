{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [../../finix/desktop ../../finix/tailscale.nix];

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
    getty = {
      enable = true;
      ttys = ["tty1" "tty2"];
    };
    openssh.settings.Port = [2222];
    nix-daemon.settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = ["http://192.168.2.66:8787/cache"];
      trusted-public-keys = ["cache:lPd94Ltnv0ZYpkoK5UtQi/VrGkEtHRT7Af6jUzy3PLA="];
      connect-timeout = 5;
      fallback = true;
      download-attempts = 1;
    };
  };

  user.account.extraGroups = ["networkmanager" "video" "render" "seat"];

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

  xdg = {
    portal.enable = true;
    icons.enable = true;
    mime.enable = true;
  };

  fonts.fontconfig.enable = true;

  environment.systemPackages = [pkgs.efibootmgr];

  environment.etc."udev/hwdb.bin".source = lib.mkIf config.services.udev.enable (lib.mkForce (pkgs.runCommand "hwdb.bin"
    {
      preferLocalBuild = true;
      allowSubstitutes = false;
      packages = lib.unique (map toString ([pkgs.udev] ++ config.services.udev.packages));
    }
    ''
      mkdir -p etc/udev/hwdb.d
      for i in $packages; do
        for j in $i/{etc,lib,var/lib}/udev/hwdb.d/*; do
          [ -e "$j" ] || continue
          cp "$j" "etc/udev/hwdb.d/$(basename "$j")"
        done
      done
      res="$(${pkgs.buildPackages.eudev}/bin/udevadm hwdb --update --root "$PWD" 2>&1)"
      echo "$res"
      [ -z "$(echo "$res" | grep -E '^(Error|Failed)')" ]
      mv etc/udev/hwdb.bin "$out"
    ''));

  manzil = {
    finit.conditions = [config.finix.persistence.homeCondition];
    clobberByDefault = true;
  };
}
