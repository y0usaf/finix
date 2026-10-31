{
  config,
  flakeInputs,
  lib,
  pkgs,
  ...
}: let
  cleanker = flakeInputs.cleanker.packages."${pkgs.stdenv.hostPlatform.system}".default;
in {
  environment.systemPackages = [
    pkgs.git
    pkgs.openssh
    cleanker
  ];
  manzil.users."${config.user.name}".files.".config/git/config" = {
    generator = lib.generators.toGitINI;
    value = {
      user = {
        name = "y0usaf";
        email = "74448287+y0usaf@users.noreply.github.com";
      };
      core.editor = "nvim";
      core.hooksPath = "${cleanker}/share/git-hooks";
      cleanker.owners = "y0usaf sylvarant-ai";
      cleanker.roots = "${config.user.homeDirectory}/dev/developing ${config.user.homeDirectory}/dev/maintaining";
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
