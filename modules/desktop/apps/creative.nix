{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.creative = {
    enable = lib.mkEnableOption "creative applications module";
  };
  config = lib.mkIf config.user.programs.creative.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/Pinta"
    ];
    environment.systemPackages = [
      pkgs.pinta
      pkgs.gimp
    ];
  };
}
