{
  config,
  lib,
  ...
}: let
  username = config.user.name;
  policiesContent = builtins.toJSON {
    policies = {
      DisableTelemetry = true;
      DisableLibreWolfStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = false;
      };
      ExtensionSettings = {
        "*" = {
          installation_mode = "blocked";
          allowed_types = ["extension" "theme"];
        };
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/librewolf/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        # Dark Reader
        "addon@darkreader.org" = {
          install_url = "https://addons.mozilla.org/librewolf/downloads/latest/darkreader/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };
in {
  config = lib.mkIf config.home.programs.librewolf.enable {
    hjem.users.${username} = {
      files = {
        ".mozilla/librewolf/policies/policies.json" = {
          text = policiesContent;
          clobber = true;
        };
      };
    };
  };
}
