{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.tools.git = {
    enable = lib.mkEnableOption "git configuration";
    name = lib.mkOption {
      type = lib.types.str;
      description = "Git username.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "Git email address.";
    };
    editor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "Default editor for git.";
    };
  };
  config = lib.mkIf config.user.tools.git.enable {
    environment.systemPackages = [
      pkgs.git
      pkgs.openssh
    ];
    usr = {
      files = {
        ".config/git/config" = {
          clobber = true;
          generator = lib.generators.toGitINI;
          value = {
            user = {
              name = config.user.tools.git.name;
              email = config.user.tools.git.email;
            };
            core = {
              editor = config.user.tools.git.editor;
            };
            init = {
              defaultBranch = "main";
            };
            pull = {
              rebase = true;
            };
            push = {
              autoSetupRemote = true;
            };
            url."git@github.com:".pushInsteadOf = "https://github.com/";
          };
        };
      };
    };
  };
}
