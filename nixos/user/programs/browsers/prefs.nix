{
  config,
  lib,
}: let
  sharedPrefs = import ../../../../lib/browsers/prefs.nix {
    config =
      config
      // rec {
        user =
          config.user
          // {
            programs =
              config.user.programs
              // {
                browser.hardwareAccel = {
                  webrender =
                    if config.system.hardware.nvidia.enable or false
                    then false
                    else true;
                  videoDecoding =
                    if config.system.hardware.nvidia.enable or false
                    then false
                    else true;
                  vaapi =
                    if config.system.hardware.nvidia.enable or false
                    then false
                    else true;
                  disabled =
                    if config.system.hardware.nvidia.enable or false
                    then true
                    else false;
                };
              };
          };
      };
    inherit lib;
  };
in
  sharedPrefs
