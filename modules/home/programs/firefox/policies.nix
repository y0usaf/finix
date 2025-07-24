{
  config,
  lib,
  ...
}: let
  username = "y0usaf";
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
        ".mozilla/firefox/policies/policies.json".text = policiesContent;
      };
    };
  };
}
