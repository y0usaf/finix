# Shared Firefox configuration used by both Darwin and NixOS
# Platform-specific packaging and file writing happens in darwin/nixos layers
{
  config,
  lib,
}: let
  policies = import ./policies.nix {inherit config lib;};
  prefs = import ./prefs.nix {inherit config lib;};
  ui = import ./ui-chrome.nix;
in {
  # Firefox policies to apply (used by both platforms)
  browserPolicies =
    policies.browserPolicies
    // {
      DisableFirefoxStudies = true;
    };

  # Browser preferences (locked and default)
  inherit (prefs) locked default;

  # Firefox UI CSS
  inherit (ui) userChromeCss;

  # Standard profiles.ini configuration
  profilesIni = {
    Profile0 = {
      Name = "default";
      IsRelative = 1;
      Path = "default";
      Default = 1;
    };
    General = {
      StartWithLastProfile = 1;
      Version = 2;
    };
  };
}
