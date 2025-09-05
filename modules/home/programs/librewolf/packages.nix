{
  config,
  lib,
  pkgs,
  ...
}: let
  username = config.user.name;
in {
  config = lib.mkIf config.home.programs.librewolf.enable {
    hjem.users.${username} = {
      packages = with pkgs; [
        (wrapFirefox librewolf-unwrapped {
          extraPolicies = {
            DisableFirefoxAccounts = false;
            DisableTelemetry = true;
            DisableLibreWolfStudies = true;
            DisablePocket = true;
            DisableFormHistory = true;
            NoDefaultBookmarks = true;
            NewTabPage = false;
            EnableTrackingProtection = {
              Value = true;
              Locked = false;
            };
            SanitizeOnShutdown = {
              History = true;
              FormData = true;
              Downloads = true;
              Sessions = true;
              Cookies = false;
              Cache = true;
              SiteSettings = false;
              OfflineApps = true;
            };
            ExtensionSettings = {
              "*" = {
                installation_mode = "blocked";
                allowed_types = ["extension" "theme"];
              };
              "uBlock0@raymondhill.net" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                installation_mode = "force_installed";
                allowed_in_private_browsing = true;
              };
              "addon@darkreader.org" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
                installation_mode = "force_installed";
                allowed_in_private_browsing = true;
              };
              # Vimium C
              "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi";
                installation_mode = "force_installed";
                allowed_in_private_browsing = true;
              };
              # Violentmonkey
              "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi";
                installation_mode = "force_installed";
                allowed_in_private_browsing = true;
              };
              # Twitch 5
              "{9b10e8f6-99b7-4a5e-9b7c-28c6db85cba7}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/twitch_5/latest.xpi";
                installation_mode = "force_installed";
                allowed_in_private_browsing = true;
              };
            };
          };
        })
      ];
      files = {
        ".config/zsh/.zprofile" = {
          text = lib.mkAfter ''
            export MOZ_ENABLE_WAYLAND=1
            export MOZ_USE_XINPUT2=1
          '';
          clobber = true;
        };
      };
    };
  };
}
