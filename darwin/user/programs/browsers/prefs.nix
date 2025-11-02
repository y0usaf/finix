{
  config,
  lib,
}: let
  sharedPrefs = import ../../../../lib/browsers/prefs.nix {
    config =
      config
      // {
        user =
          (config.user or {})
          // {
            ui =
              (config.user.ui or {})
              // {
                fonts =
                  config.user.ui.fonts or {
                    mainFontName = "Iosevka Term Slab";
                    backup = {name = "Symbols Nerd Font";};
                    emoji = {name = "Apple Color Emoji";};
                  };
              };
            programs =
              (config.user.programs or {})
              // {
                browser.hardwareAccel = {
                  webrender = true;
                  videoDecoding = true;
                  vaapi = false;
                  disabled = false;
                };
              };
          };
      };
    inherit lib;
  };
in
  sharedPrefs
