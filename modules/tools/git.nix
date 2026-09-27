{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.tools.git.enable = lib.mkEnableOption "git configuration";
  config = lib.mkIf config.user.tools.git.enable {
    environment.systemPackages = [
      pkgs.git
      pkgs.openssh
    ];
    manzil.users."${config.user.name}".files.".config/git/config" = {
      generator = lib.generators.toGitINI;
      value = {
        user = {
          name = "y0usaf";
          email = "74448287+y0usaf@users.noreply.github.com";
        };
        core.editor = "nvim";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        url."git@github.com:" = {
          insteadOf = "https://github.com/";
          pushInsteadOf = "https://github.com/";
        };
      };
    };
  };
}
