{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.stoat-desktop = {
    enable = lib.mkEnableOption "stoat-desktop";
  };

  config = lib.mkIf config.user.programs.stoat-desktop.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/stoat-desktop"
    ];
    environment.systemPackages = [pkgs.stoat-desktop];
  };
}
