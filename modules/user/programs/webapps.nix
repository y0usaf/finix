{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./webapps/keybard.nix
    ./webapps/google-meet.nix
  ];

  options.user.programs.webapps = {
    enable = lib.mkEnableOption "web applications via Chromium";
  };

  config = lib.mkIf config.user.programs.webapps.enable {
    environment.systemPackages = [pkgs.ungoogled-chromium];
    user.programs = {
      keybard.enable = lib.mkDefault true;
      google-meet.enable = lib.mkDefault true;
    };
  };
}
