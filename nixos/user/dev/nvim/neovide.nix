{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.user.dev.nvim.enable && config.user.dev.nvim.neovide) {
    # Package installed at system level via environment.systemPackages
    environment.systemPackages = [
      pkgs.neovide
    ];
    hjem.users.${config.user.name} = {
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
