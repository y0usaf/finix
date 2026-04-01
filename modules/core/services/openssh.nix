_: {
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      AuthorizedKeysFile = ".ssh/authorized_keys Tokens/authorized_keys /etc/ssh/authorized_keys.d/%u";
    };
  };
}
