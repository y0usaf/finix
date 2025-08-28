{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;

  cssContent = lib.concatStringsSep "\n\n" [
    ''
      /* External theme imports */
      @import url("https://raw.codeberg.page/AllPurposeMat/Disblock-Origin/DisblockOrigin.theme.css");
    ''
    ''
      /* Hide the Visual Refresh title bar */
      .visual-refresh {
        /* Hide the bar itself */
        --custom-app-top-bar-height: 0 !important;
        /* Title bar buttons are still visible so hide them too */
        div.base_c48ade > div.bar_c38106 {
          display: none;
        }
        /* Bring the server list down a few pixels */
        ul[data-list-id="guildsnav"] > div.itemsContainer_ef3116 {
          margin-top: 8px;
        }
      }
    ''
    ''
      /* Global typography overrides */
      * {
        font-family: monospace !important;
      }
    ''
    ''
      /* Global border radius overrides */
      * {
        border-radius: 0 !important;
      }
    ''
  ];
in {
  config = mkIf config.home.programs.vesktop.enable {
    hjem.users.${config.user.name}.files.".config/vesktop/settings/quickCss.css" = {
      text = cssContent;
    };
  };
}