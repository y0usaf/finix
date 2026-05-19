_: {
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      AuthorizedKeysFile = ".ssh/authorized_keys Tokens/authorized_keys /etc/ssh/authorized_keys.d/%u";
    };
  };

  programs.ssh.knownHosts = {
    "github.com" = {
      hostNames = ["github.com"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
  };
}
