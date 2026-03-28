# Shared Firefox configuration used by both Darwin and NixOS
# Platform-specific packaging and file writing happens in darwin/nixos layers
{
  config,
  lib,
}: {
  # Firefox policies to apply (used by both platforms)
  browserPolicies =
    (import ./policies.nix {inherit config lib;}).browserPolicies
    // {
      DisableFirefoxStudies = true;
    };

  # Browser preferences (locked and default)
  inherit (import ./prefs.nix {inherit config lib;}) locked default;

  # Firefox UI CSS
  inherit (import ./ui-chrome.nix) userChromeCss;

  # Firefox web content CSS
  inherit (import ./ui-content.nix) userContentCss;

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
