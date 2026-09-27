{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.${config.user.name}.shell = lib.mkForce "${pkgs.bashInteractive}/bin/bash";

  environment.systemPackages = [pkgs.nix pkgs.efibootmgr];

  user.dev = {
    paseo = {
      enable = true;
      relay.enable = false;
      environmentFiles = ["/home/y0usaf/Tokens/ANTHROPIC_API_KEY.txt"];
    };
    claude-code.enable = true;
  };
}
