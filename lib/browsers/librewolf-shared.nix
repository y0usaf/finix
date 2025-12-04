# Shared LibreWolf configuration used by both Darwin and NixOS
# Platform-specific packaging and file writing happens in darwin/nixos layers
{
  config,
  lib,
}: let
  policies = import ./policies.nix {inherit config lib;};
  prefs = import ./prefs.nix {inherit config lib;};
  ui = import ./ui-chrome.nix;
in {
  # LibreWolf policies (slightly different from Firefox)
  browserPolicies =
    policies.browserPolicies
    // {
      DisableFirefoxAccounts = false;
    };

  # Browser preferences (locked and default)
  inherit (prefs) locked default;

  # Firefox UI CSS
  inherit (ui) userChromeCss;

  # LibreWolf profiles.ini configuration
  profilesIni = {
    Profile0 = {
      Name = "y0usaf";
      IsRelative = 1;
      Path = "y0usaf";
      Default = 1;
    };
    General = {
      StartWithLastProfile = 1;
      Version = 2;
    };
  };
}
