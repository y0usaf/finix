{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../tools/git.nix
    ../../tools/tmux.nix
  ];

  options.user.name = lib.mkOption {
    type = lib.types.str;
    default = "steamos";
  };

  config = {
    time.timeZone = "America/Toronto";

    environment = {
      systemPackages = [pkgs.neovim];
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };

    manzil = {
      clobberByDefault = true;
      users.${config.user.name}.files = {
        ".bashrc".text = ''
          case $- in
            *i*) ;;
            *) return ;;
          esac

          HISTSIZE=10000
          HISTFILESIZE=10000
          HISTCONTROL=ignoreboth:erasedups
          shopt -s histappend checkwinsize

          alias la="ls -a"
          alias ll="ls -l"
          alias lla="ls -la"
        '';
        ".bash_profile".text = ''
          [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
        '';
      };
    };
  };
}
