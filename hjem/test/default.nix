# A simple test module for Hjem - uses hjome alias for simple configuration
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  # Define module options
  options.cfg.hjome.test = {
    enable = mkEnableOption "test module";
  };

  # Config section - module is imported into hjem user config
  config = mkIf config.cfg.hjome.test.enable {
    files = {
      ".config/TEST_MODULE.TXT" = {
        text = "This file is created by the test module";
      };
    };
  };
}