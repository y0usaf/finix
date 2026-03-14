{
  config,
  lib,
  ...
}: {
  config =
    lib.mkIf (
      (config.user.programs.discord.stable.enable or false)
      || (config.user.programs.discord.canary.enable or false)
    ) {
      hjem.users."${config.user.name}".files = {
        ".config/Vencord/themes/visual-refresh.css".text = ''
          /* Hide the Visual Refresh title bar */
          .visual-refresh {
            --custom-app-top-bar-height: 0px !important;
            div.base__5e434 > div.bar_c38106 {
              display: none;
            }
          }

          /* Adjust guild list top offset after hiding title bar */
          .visual-refresh {
            ul[data-list-id="guildsnav"] > div.itemsContainer_ef3116 {
              margin-top: 8px;
            }
          }

          /* Make "Read All" vencord button text smaller */
          button.vc-ranb-button {
            font-size: 9.5pt;
            font-weight: normal;
          }

          /* Hide Discover button */
          div[data-list-item-id="guildsnav___guild-discover-button"] {
            display: none !important;
          }

          /* Hide the buttons next to mute and deafen */
          div[class^=buttons__] {
            gap: 2px;
            div[class^=micButtonParent__] {
              button[role="switch"] {
                border-radius: var(--radius-sm) !important;
                ~ button {
                  display: none;
                }
              }
            }
          }
        '';
      };
    };
}
