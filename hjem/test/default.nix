# A simple test module for Hjem
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.test;
in {
  # Define module options
  options.test = {
    enable = mkEnableOption "test module";
  };

  # Config section - only applied when enabled
  config = mkIf cfg.enable {
    # Create test files when the module is enabled
    files = {
      ".config/TEST_MODULE.TXT" = {
        text = "This file is created by the test module";
      };
    };
  };
}