# NetworkManager for the desktop, replacing the wired-only dhcpcd setup.
#
# Why: dhcpcd alone left the MediaTek mt7921e (wlp96s0) with no supplicant, so
# the interface existed but could never associate — a phone hotspot was
# unreachable no matter what. NetworkManager owns both links now and its
# nmtui/nmcli land in systemPackages via the module itself (no explicit
# pkgs.networkmanager needed: finix's module adds cfg.package, which ships
# nmtui, nmcli, nm-online).
#
# Never run dhcpcd beside NetworkManager against the same interface: both
# would install competing leases/routes on eno1. `services.dhcpcd.enable`
# alone is not enough — modules/finix/common.nix defines
# `finit.services.dhcpcd.command` unconditionally, which materialises the
# service even when the option is off, so the finit stanza needs mkForce too.
# Same shape as ../y0usaf-framework/finix/network.nix.
#
# rc-manager=resolvconf + programs.resolvconf.enable: nixpkgs builds
# NetworkManager with a hardcoded resolvconf path, so the default
# rc-manager=auto silently selects resolvconf even with nothing providing it
# and DNS updates are dropped. Enable it for real (upstream finix module
# comment says the same).
{lib, ...}: {
  services = {
    dhcpcd.enable = lib.mkForce false;
    networkmanager = {
      enable = true;
      settings.main.rc-manager = "resolvconf";
    };
  };
  finit.services.dhcpcd.enable = lib.mkForce false;
  programs.resolvconf.enable = true;
}
