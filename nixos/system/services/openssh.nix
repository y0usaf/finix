_: {
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      AuthorizedKeysFile = ".ssh/authorized_keys Tokens/authorized_keys";
    };
  };
}
