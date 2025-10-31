{
  config,
  lib,
}: let
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
