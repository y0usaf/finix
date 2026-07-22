{
  config,
  lib,
  ...
}: let
  readKey = path: lib.removeSuffix "\n" (builtins.readFile path);
in {
  services.openssh = {
    enable = true;
    # Real sshd lives off :22 — tailscaled intercepts tailnet:22 for
    # Tailscale SSH (kept as the rescue path). Server overrides to 2200
    # because forgejo owns 2222 there.
    ports = lib.mkDefault [2222];
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      AuthorizedKeysFile = ".ssh/authorized_keys Tokens/authorized_keys /etc/ssh/authorized_keys.d/%u";
    };
  };

  # sshd reachable over the tailnet only; never LAN/WAN.
  networking.firewall.interfaces."tailscale0".allowedTCPPorts =
    config.services.openssh.ports;

  # Every machine's user key may log in everywhere (pubkeys live in-repo).
  users.users."${config.user.name}".openssh.authorizedKeys.keys = [
    (readKey ../../../hosts/y0usaf-desktop/user-ssh.pub)
    (readKey ../../../hosts/y0usaf-framework/user-ssh.pub)
    (readKey ../../../hosts/y0usaf-server/user-ssh.pub)
    (readKey ../../../hosts/android-phone/user-ssh.pub)
  ];

  # System-wide pins (/etc/ssh/ssh_known_hosts). Port-qualified names:
  # ssh matches "[host]:port" when the port is non-default.
  programs.ssh.knownHosts = {
    "github.com" = {
      hostNames = ["github.com"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
    "y0usaf-desktop" = {
      hostNames = ["[y0usaf-desktop]:2222" "[100.90.54.18]:2222"];
      publicKeyFile = ../../../hosts/y0usaf-desktop/host-ssh-ed25519.pub;
    };
    "y0usaf-framework" = {
      hostNames = ["[y0usaf-framework]:2222" "[100.82.221.125]:2222"];
      publicKeyFile = ../../../hosts/y0usaf-framework/host-ssh-ed25519.pub;
    };
    "y0usaf-server" = {
      hostNames = ["[y0usaf-server]:2200" "[100.105.204.116]:2200"];
      publicKeyFile = ../../../hosts/y0usaf-server/host-ssh-ed25519.pub;
    };
    "android-phone" = {
      hostNames = ["[100.93.111.41]:8022" "[192.168.2.34]:8022"];
      publicKeyFile = ../../../hosts/android-phone/host-ssh-ed25519.pub;
    };
  };
}
