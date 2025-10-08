{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  username = config.user.name;
in {
  config = lib.mkIf (cfg.enable && cfg.neovide) {
    # Package installed at system level via environment.systemPackages
    environment.systemPackages = [
      pkgs.neovide
    ];
    hjem.users.${username} = {
      files.".config/neovide/config.toml" = {
        clobber = true;
        text = ''
          [font]
          normal = ["Fast_Mono"]
          size = 14.0
          [window]
          transparency = 0.9
          [input]
          ime = true
        '';
      };
    };
  };
}
