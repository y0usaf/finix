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
    bayt.users."${config.user.name}".files.".config/git/config" = {
      generator = lib.generators.toGitINI;
      value = {
        user = {
          inherit (config.user.tools.git) name email;
        };
        core = {
          inherit (config.user.tools.git) editor;
        };
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        url."git@github.com:".pushInsteadOf = "https://github.com/";
      };
    };
  };
}
