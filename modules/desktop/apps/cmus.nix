{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.cmus = {
    enable = lib.mkEnableOption "cmus music player";
  };

  config = lib.mkIf config.user.programs.cmus.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/cmus"
    ];
    environment.systemPackages = [pkgs.cmus];
    manzil.users."${config.user.name}".files.".config/cmus/rc".text = ''
      colorscheme wallust-auto

    '';
  };
}
