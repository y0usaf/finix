# Shared LibreWolf configuration used by both Darwin and NixOS
# Platform-specific packaging and file writing happens in darwin/nixos layers
{
  config,
  lib,
}: {
  # LibreWolf policies (slightly different from Firefox)
  browserPolicies =
    (import ./policies.nix {inherit config lib;}).browserPolicies
    // {
      DisableFirefoxAccounts = false;
    };

  # Browser preferences (locked and default)
  inherit (import ./prefs.nix {inherit config lib;}) locked default;

  # Firefox UI CSS
  inherit (import ./ui-chrome.nix) userChromeCss;

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
