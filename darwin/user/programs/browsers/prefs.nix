{
  config,
  lib,
}: let
  # Import shared prefs with Darwin-specific hardware acceleration settings
  sharedPrefs = import ../../../lib/shared/browsers/prefs.nix {
    config =
      config
      // {
        user.programs.browser.hardwareAccel = {
          webrender = true;
          videoDecoding = true;
          vaapi = false;
          disabled = false;
        };
      };
    inherit lib;
  };
in
  sharedPrefs
