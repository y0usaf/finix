# A simple test module for Hjem - follows Home Manager pattern
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.cfg.test;
in {
  # Define module options
  options.cfg.test = {
    enable = mkEnableOption "test module";
  };

  # Config section with files
  config = mkIf cfg.enable {
    # Define files
    files = {
      ".config/TEST_MODULE.TXT" = {
        text = "This file is created by the test module";
      };
    };
  };
}