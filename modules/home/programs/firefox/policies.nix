{
  config,
  lib,
  ...
}: let
  username = config.user.name;
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
    hjem.users.${username} = {
      files = {
        ".mozilla/firefox/policies/policies.json" = {
          text = policiesContent;
          clobber = true;
        };
      };
    };
  };
}
