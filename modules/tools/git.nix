{
  config,
  lib,
  pkgs,
  ...
}: let
  policy-sweep = import ../../pkgs/policy-sweep.nix {inherit pkgs;};
in {
  environment.systemPackages = [
    pkgs.git
    pkgs.openssh
    policy-sweep
  ];
  manzil.users."${config.user.name}".files.".config/git/config" = {
    generator = lib.generators.toGitINI;
    value = {
      user = {
        name = "y0usaf";
        email = "74448287+y0usaf@users.noreply.github.com";
      };
      core.editor = "nvim";
      core.hooksPath = "${policy-sweep}/share/git-hooks";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      url."git@github.com:" = {
        insteadOf = "https://github.com/";
        pushInsteadOf = "https://github.com/";
      };
    };
  };
}
