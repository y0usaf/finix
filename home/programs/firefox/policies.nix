###############################################################################
# Firefox Policies Module
# Simple Firefox enterprise policies configuration
###############################################################################
{
  config,
  lib,
  ...
}: let
  inherit (config.shared) username;

  # Firefox policies.json content
  policiesContent = builtins.toJSON {
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = false;
      };
      ExtensionSettings = {
        "*" = {
          installation_mode = "allowed";
          allowed_types = ["extension" "theme"];
        };
      };
    };
  };
in {
  config = lib.mkIf config.home.programs.firefox.enable {
    users.users.${username}.maid = {
      file.home = {
        # Firefox Policies (system-wide)
        ".mozilla/firefox/policies/policies.json".text = policiesContent;
      };
    };
  };
}
