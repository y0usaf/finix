{lib, ...}: {
  user.dev = {
    paseo = {
      enable = true;
      relay.enable = false;
      listenAddress = "100.105.204.116";
      group = "users";
      environmentFiles = [
        "/home/y0usaf/Tokens/ANTHROPIC_API_KEY.txt"
      ];
    };
    claude-code.enable = true;
  };
}
