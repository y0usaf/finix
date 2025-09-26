{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.webapps;
in {
  imports = [
    ./webapps/keybard.nix
    ./webapps/google-meet.nix
  ];

  options.home.programs.webapps = {
    enable = lib.mkEnableOption "web applications via Chromium";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.ungoogled-chromium];
    home.programs = {
      keybard.enable = lib.mkDefault true;
      google-meet.enable = lib.mkDefault true;
    };
  };
}
