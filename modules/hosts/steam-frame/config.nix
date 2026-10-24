{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../tools/git.nix
    ../../tools/tmux.nix
    ./bolo.nix
    ./mado.nix
  ];

  options.user.name = lib.mkOption {
    type = lib.types.str;
    default = "steamos";
  };

  config = {
    time.timeZone = "America/Toronto";
    frame.charge.limit = 80;

    environment = {
      systemPackages = [pkgs.neovim];
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };

    manzil = {
      clobberByDefault = true;
      users.${config.user.name}.files = (import ../shared.nix {inherit lib pkgs;}).bashFiles {};
    };
  };
}
