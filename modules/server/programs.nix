{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.${config.user.name}.shell = lib.mkForce "${pkgs.bashInteractive}/bin/bash";

  user = {
    tools = {
      git.enable = true;
      tmux.enable = true;
    };
    dev = {
      paseo = {
        enable = true;
        relay.enable = false;
        environmentFiles = ["/home/y0usaf/Tokens/ANTHROPIC_API_KEY.txt"];
      };
      claude-code.enable = true;
    };
  };
}
