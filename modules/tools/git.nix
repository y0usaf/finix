# Shared git options + config. Imported by both hosts: desktop via the
# recursive walk (shimmed), server explicitly (shimmed). The server has no
# tools.nix to set user.tools.git.enable, so default.nix enables it inline
# (desktop already sets it in hosts/y0usaf-desktop/tools.nix; idempotent).
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
      default = "y0usaf";
      description = "Git username.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "OA99@Outlook.com";
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
    manzil.users."${config.user.name}".files.".config/git/config" = {
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
        url."git@github.com:" = {
          insteadOf = "https://github.com/";
          pushInsteadOf = "https://github.com/";
        };
      };
    };
  };
}
