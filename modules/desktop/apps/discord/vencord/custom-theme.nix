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
      manzil.users."${config.user.name}".files = {
        ".config/Vencord/themes/custom-theme.css".text = ''
          /**
           * @name custom-theme
           * @description system24 base + MinimalImprovement chat/member tweaks
           * @author refact0r, Juicysteak117
           * @license MIT
           * @source https://github.com/refact0r/system24
           * @source https://github.com/Juicysteak117/MinimalImprovement
           */


          :root {
              --custom-guild-list-padding: 6px;
              --panel-backdrop-filter: none;

          }

          body {
              --custom-guild-list-width: calc(var(--guildbar-avatar-size) + var(--custom-guild-list-padding) * 2 + var(--border-thickness) * 2);
              --border-hover-transition: 0.2s ease;
              --custom-channel-textarea-text-area-height: var(--chatbar-height);
              --dms-icon-color-before: var(--icon-subtle);
              --dms-icon-color-after: var(--white);
              --custom-app-top-bar-height: var(--top-bar-height);
              --window-control-size: 14px;
              --custom-chatbar: separated !important;
              --chatbar-height: 40px !important;
              --label-color: var(--text-muted);
              --label-hover-color: var(--brand-360);
              --label-font-weight: 500;
          }

          .container__89463 > .toolbar__89463,
          .container__89463 > .contentContainer__89463,
          .guilds__5e434,
          .sidebarList__5e434,
          .panels__5e434,
          .chat_f75fb0 > .subtitleContainer_f75fb0,
          .chatContent_f75fb0,
          .container_c8ffbb,
          .content_f75fb0 > .membersWrap_c8ffbb,
          .container__133bf > .container__9293f,
          .container_f391e3 > .container__9293f,
          .homeWrapper__0920e > .container__9293f,
          .container__01ae2 > .container__9293f,
          .container_fb64c9 > .container__9293f,
          .peopleColumn__133bf,
          .nowPlayingColumn__133bf,
          .mainPageScroller_ca1a02,
          .headerBar__1a9ce,
          .scroller__23746,
          .container_f391e3 > .content_f75fb0,
          .shop__6db1d,
          .content_f75fb0 > aside > .outer_c0bea0,
          .searchResultsWrap_a98f3b,
          .container_f369db,
          .chat_fb64c9,
          .container_a592e1,
          .callContainer_cb9592,
          .wrapper_cb9592.sidebarOpen_cb9592 .callContainer_cb9592,
          .callContainer__722ff,
          .chat_f75fb0 > .header_c791b2,
          .chat_f75fb0 > .scrollerBase_d125d2,
          .chat_f75fb0 > .header__0b563,
          .chat_f75fb0 > .container__0b563 {
              background-color: var(--background-base-lower);
              border-radius: var(--radius-lg);
              border: var(--border-thickness) solid var(--border-subtle);
              backdrop-filter: var(--panel-backdrop-filter);
              box-sizing: border-box;
              transition: border-color var(--border-hover-transition);

              &:hover {
                  border-color: var(--border-hover);
              }
          }

          .panels__5e434 {
              bottom: 0;
              left: 0;
              width: 100%;
          }

          .sidebar__5e434 {
              margin: 0 var(--gap) var(--gap) var(--gap);
          }

          .guilds__5e434 {
              margin-bottom: calc(var(--custom-app-panels-height, 0) + var(--gap));
              margin-right: var(--gap);
          }
          .guilds__5e434 + div:not(.sidebarList__5e434) {
              width: 100% !important;
          }
          .scroller_ef3116 {
              padding-top: var(--custom-guild-list-padding) !important;
              padding-bottom: var(--custom-guild-list-padding);
          }
          .folderGroup__48112 {
              width: 100%;
          }
          .listItem__650eb {
              width: 100%;
          }

          .sidebarList__5e434 {
              margin-bottom: calc(var(--custom-app-panels-height, 0) + var(--gap));
          }
          .container__2637a {
              padding-bottom: 0;
          }
          .clickable_f37cb1,
              .container__2637a,
              .header_f37cb1 {
              background: none;
          }
          .scroller__629e4 {
              margin-bottom: 0;
          }

          /* fix discord's idiotic server banners */
          .bannerImage_f37cb1,
          .bannerImg_f37cb1 {
              width: 100%;
          }
          .bannerVisible_f37cb1 .headerEllipseBackdrop_f37cb1 {
              display: none;
          }
          .headerGlass_f37cb1 {
              top: 0;
              left: 0;
              right: 0;
              width: auto;
              border-radius: var(--radius-lg) var(--radius-lg) 0 0;
          }

          .sidebar__5e434:after {
              display: none;
          }

          .wrapper_ef3116 {
              mask: none;
          }

          .chat_f75fb0 {
              border: none !important;
              background: none;
          }
          .chatContent_f75fb0 {
              overflow: hidden;
          }
          .container__133bf,
              .page__5e434 {
              padding-bottom: var(--gap);
              padding-right: var(--gap);
              border: none !important;
              background: none;
          }
          .page__5e434 > .chat_f75fb0,
          .page__5e434 > .container__133bf {
              padding: 0;
          }

          .container__9293f {
              margin-bottom: var(--gap);
          }

          .subtitleContainer_f75fb0 {
              margin-bottom: var(--gap);
          }
          .title_f75fb0 {
              border: none;
              background: none !important;
              margin-bottom: 0;
          }

          .page__5e434 > div > .chat_f75fb0 > .content_f75fb0 {
              border-left: none;
          }
          .tabBody__133bf {
              border: none !important;
          }

          .listeningAlong_e0cf27 {
              border-top: none !important;
          }

          .container_c8ffbb {
              margin-left: var(--gap);
              overflow: hidden;
              height: auto;
              min-width: fit-content;
          }
          .content_f75fb0 > .membersWrap_c8ffbb {
              margin-left: var(--gap);
              overflow: hidden;
              height: auto;
              min-width: fit-content;
          }
          .members_c8ffbb,
              .member_c8ffbb {
              background: none;
          }

          .resizeHandle__01ae2 {
              background: transparent;
          }

          .privateChannels_e6b769,
              .scroller__99e7c {
              background: none;
          }
          .scroller__99e7c {
              margin-bottom: 0;
          }

          .tabBody__133bf {
              background: none;
          }

          .nowPlayingColumn__133bf {
              margin-left: var(--gap);
          }
          .container__7d20c {
              background: none;
          }
          .scroller__7d20c {
              border: none;
          }

          .homeWrapper__0920e {
              border: none;
              background: none;
          }
          .applicationStore_f07d62 {
              background: none;
          }

          .shop__6db1d {
              overflow: hidden;
              height: auto;
          }
          .shop__08415 {
              margin-top: calc(var(--custom-channel-header-height) * -1 - 16px);
          }

          .container__955a3 {
              border: none;
          }

          .content_f75fb0 > aside > .outer_c0bea0 {
              margin-left: var(--gap);
              overflow: hidden;
              /* min-width: 340px; */
              background-position: center calc(-1 * var(--border-thickness));
              background-size: 100% calc(100% + 2 * var(--border-thickness));
          }

          .searchResultsWrap_a98f3b {
              margin-left: var(--gap);
          }

          .notice__6e2b9 {
              margin: 0 var(--gap) var(--gap) 0;
              border-radius: var(--radius-md);
              box-sizing: border-box;
              height: 40px;
          }

          .container__01ae2 {
              border: none;
              background: none;
          }
          .chat_a44415::before {
              display: none;
          }
          .channelChatWrapper_cb9592 {
              background: none;
          }

          .page__5e434 > div > .chatLayerWrapper__01ae2 {
              margin: 0 var(--gap) var(--gap) 0;
              height: calc(100% - var(--gap));
          }
          .container__01ae2 {
              padding-left: calc((var(--gap) - var(--chat-resize-handle-width)));
          }

          .container_fb64c9 {
              background: none;
          }
          .chat_fb64c9::before {
              display: none;
          }

          .container_a592e1 {
              overflow: hidden;
          }
          .backdrop__8a7fc {
              background-color: var(--background-base-lower);
          }

          .wrapper_cb9592 {
              background: none;
              margin-bottom: var(--gap);
          }
          .wrapper_cb9592.fullScreen_cb9592 {
              margin-top: var(--gap);
              margin-left: var(--gap);
              width: calc(100% - var(--gap));
              height: calc(100% - var(--gap));
          }

          .standardSidebarView__23e6b,
          .contentRegion__23e6b,
          .sidebarRegionScroller__23e6b,
          .contentRegionScroller__23e6b {
              background: none;
          }
          .standardSidebarView__23e6b {
              backdrop-filter: var(--panel-backdrop-filter);
          }

          .wrapper_cdf8a9,
          .wrapper_cdf8a9 > .wrapper_fc8177 {
              background: none;
          }
          .page__5e434 > .container__89463,
          .page__5e434 > .chat_f75fb0 {
              background: none !important;
          }

          .newMessagesBar__0f481 {
              top: 12px;
              left: 12px;
              right: 12px;
              border-radius: var(--radius-sm);
              padding: 0 8px;
          }

          .bottom__7aaec,
              .unreadBottom__629e4 {
              bottom: 0;
          }

          .unreadMentionsIndicatorBottom_ef3116,
              .unreadMentionsIndicatorTop_ef3116 {
              width: calc(var(--guildbar-avatar-size) + var(--custom-guild-list-padding) * 2);
              padding: calc(var(--custom-guild-list-padding) / 2);
          }

          #vc-spotify-player {
              background: none;
          }

          .channelTextArea_f75fb0 {
              border-radius: var(--radius-md);
          }
          .themedBackground__74017 {
              background: none;
          }
          .slateTextArea_ec4baf {
              margin-left: 2px;
          }

          .divider__908e2 {
              border-width: var(--divider-thickness);
              border-radius: var(--divider-thickness);
          }
          .endCap__908e2 {
              margin-top: calc(var(--divider-thickness) / -2);
          }
          .divider__908e2 .content__908e2 {
              margin-top: calc(var(--divider-thickness) - var(--divider-thickness) * 2);
          }

          .message__5126c.mentioned__5126c::before,
          .replying__5126c::before,
          .ephemeral__5126c::before {
              width: var(--divider-thickness);
              border-radius: var(--divider-thickness);
              height: calc(100% - 2 * var(--radius-sm));
              top: var(--radius-sm);
              left: calc(var(--divider-thickness) / -2 + 1px);
              left: calc(var(--radius-sm) / 2);
          }

          .message__5126c {
              border-radius: var(--radius-md);
              margin-left: 4px;
              padding-block: 1px !important;
          }

          .pill_e5445c.wrapper__58105 {
              width: calc((var(--custom-guild-list-padding) - 4px) / 2 + 4px);
          }
          .item__58105 {
              width: 4px;
              border-radius: 4px;
              margin-left: calc((var(--custom-guild-list-padding) - 4px) / 2);
          }

          .embedFull__623de {
              border: 4px solid var(--border-normal);
              border-top-color: var(--border-subtle) !important;
              border-top-width: 1px;
              border-bottom-color: var(--border-subtle) !important;
              border-bottom-width: 1px;
              border-right-color: var(--border-subtle) !important;
              border-right-width: 1px;
          }

          .reaction__23977,
              .reactionBtn__23977.forceShow__23977 {
              border-width: 2px;
          }

          .embedFull__623de,
              .hljs,
              .imageWrapper_af017a,
              .container__9271d {
              border-radius: var(--radius-md);
          }

          .outer_c0bea0,
              .contentWrapper__08434 {
              border-radius: var(--radius-lg);
          }
          .inner_c0bea0 {
              border-radius: calc(var(--radius-lg) - 4px);
          }

          .outer_c0bea0 {
              border: 1px solid var(--border-subtle);
              background-position: center calc(-1 * var(--border-thickness));
              background-size: 100% calc(100% + 2 * var(--border-thickness));
          }
          .root__24502 {
              background: none;
          }

          .container__37e49 {
              margin-inline-start: 0;
              -webkit-margin-start: 0;
          }
          .container__37e49 .container__4bbc6 {
              border-radius: var(--radius-lg);
              width: 100%;
              height: 100%;
              top: 0;
              left: 0;
          }

          .app__160d8,
          #app-mount,
          body {
              background: transparent !important;
          }

          [class*='scroll'] {
              will-change: scroll-position;
          }
          .burstGlow__23977 {
              display: none;
          }

          .attachWrapper__0923f {
              padding-top: 0;
              padding-bottom: 0;
              display: flex;
              align-items: center;
              justify-content: center;
          }
          .icon__4d3a9 {
              padding-top: 0;
              padding-bottom: 0;
          }
          .attachButton__74017 {
              display: flex;
              align-items: center;
          }

              .chatContent_f75fb0 {
                  background: none;
                  border-radius: 0;
                  border: none;
                  backdrop-filter: none;
              }
              .messagesWrapper__36d07 {
                  background-color: var(--background-base-lower);
                  border-radius: var(--radius-lg);
                  border: var(--border-thickness) solid var(--border-subtle);
                  backdrop-filter: var(--panel-backdrop-filter);
                  transition: border-color var(--border-hover-transition);
                  overflow: hidden;

                  &:hover {
                      border-color: var(--border-hover);
                  }
              }
              .scrollerSpacer__36d07 {
                  height: calc(26px + var(--space-xs));
              }
              .scroller__36d07::-webkit-scrollbar-track {
                  margin-bottom: calc(26px);
              }
              .chatContent_f75fb0:has(.typing_b88801) .messagesWrapper__36d07::before {
                  content: ''';
                  position: absolute;
                  bottom: 0;
                  left: 0;
                  right: 0;
                  background: var(--background-base-lower);
                  height: 26px;
                  border-radius: 0 0 var(--radius-lg) var(--radius-lg);
                  z-index: 2;
              }
              .form_f75fb0 {
                  display: flex;
                  flex-direction: column;
                  padding: 0;
                  width: 100%;
                  margin-top: 0;
              }
              .typing_b88801 {
                  position: absolute;
                  order: -1;
                  top: calc(-26px + var(--border-thickness) * -1);
                  left: calc(var(--border-thickness));
                  border-radius: 0 0 0 var(--radius-lg);
                  padding: 0 0 0 var(--space-sm);
                  height: 26px;
              }
              .channelBottomBarArea_f75fb0 {
                  margin-top: var(--gap);
              }
              .channelTextArea_f75fb0 {
                  margin: 0;
                  box-sizing: border-box;
                  min-height: var(--chatbar-height);
                  background-color: var(--background-base-lower);
                  border-radius: var(--radius-lg);
                  border: var(--border-thickness) solid var(--border-subtle);
                  backdrop-filter: var(--panel-backdrop-filter);
                  transition: border-color var(--border-hover-transition);

                  &:hover {
                      border-color: var(--border-hover);
                  }
              }
              .stackedBars__74017 {
                  background: none !important;
              }
              .wrapper__44df5 {
                  margin: var(--gap) 0 0 0;
                  height: var(--chatbar-height);
                  padding: 0;
                  border-radius: var(--radius-lg);
                  border: var(--border-thickness) solid var(--border-subtle);
                  backdrop-filter: var(--panel-backdrop-filter);
                  transition: border-color var(--border-hover-transition);

                  &:hover {
                      border-color: var(--border-hover);
                  }
              }

              body,
              .theme-dark:not(.custom-user-profile-theme),
              .theme-light:not(.custom-user-profile-theme) {
                  --app-frame-background: var(--bg-3);
                  --app-frame-border: var(--border);
                  --app-message-embed-secondary-text: var(--text-2);
                  --background-accent: var(--bg-2);
                  --background-base-low: var(--bg-4);
                  --background-base-lower: var(--bg-4);
                  --background-base-lowest: var(--bg-4);
                  --background-brand: var(--accent-2);
                  --background-code: var(--bg-3);
                  --background-feedback-critical: color-mix(in hsl, var(--red-2), transparent 80%);
                  --background-feedback-info: color-mix(in hsl, var(--blue-2), transparent 80%);
                  --background-feedback-positive: color-mix(in hsl, var(--green-2), transparent 80%);
                  --background-feedback-warning: color-mix(in hsl, var(--yellow-2), transparent 80%);
                  --background-feedback-notification: var(--accent-new);
                  --background-mod-muted: var(--hover);
                  --background-mod-normal: var(--bg-2);
                  --background-mod-strong: var(--bg-1);
                  --background-mod-subtle: var(--hover);
                  --background-scrim: hsl(0, 0%, 0%, 0.7);
                  --background-scrim-lightbox: hsl(0, 0%, 0%, 0.9);
                  --background-secondary-alt: var(--bg-3);
                  --background-surface-high: var(--bg-3);
                  --background-surface-higher: var(--bg-3);
                  --background-surface-highest: var(--bg-3);
                  /* --background-tile-gradient-pink-end: yellow;
           */
                  --badge-background-default: var(--accent-2);
                  --badge-expressive-background-default: var(--accent-2);
                  --badge-expressive-text-default: var(--text-0);
                  --badge-notification-background: var(--accent-new);
                  --badge-text-default: var(--text-0);
                  --bg-surface-overlay-tmp: var(--bg-3);
                  --border-muted: var(--border-light);
                  --border-normal: var(--border);
                  --border-strong: var(--border);
                  --border-subtle: var(--border);
                  --button-outline-primary-text: var(--text-1);
                  --card-background-default: var(--bg-3);
                  --channel-icon: var(--text-4);
                  --channel-text-area-placeholder: var(--text-5);
                  --channels-default: var(--text-4);
                  --channeltextarea-background: var(--border);
                  --chat-background-default: var(--bg-3);
                  --chat-text-muted: var(--text-5);
                  --checkbox-background-default: var(--bg-2);
                  --checkbox-background-hover: var(--bg-1);
                  --checkbox-background-selected-default: var(--accent-2);
                  --checkbox-background-selected-hover: var(--accent-3);
                  --checkbox-border-active: var(--border);
                  --checkbox-border-default: var(--border);
                  --checkbox-border-hover: var(--border);
                  --checkbox-border-selected-default: var(--button-border);
                  --checkbox-border-selected-hover: var(--button-border);
                  --checkbox-icon-active: var(--text-0);
                  --content-inventory-media-seekbar-container: var(--bg-1);
                  --content-inventory-overlay-text-primary: var(--text-2);
                  --content-inventory-overlay-text-secondary: var(--text-3);
                  --control-brand-foreground: var(--accent-2);
                  --control-connect-background-active: var(--accent-5);
                  --control-connect-background-default: var(--accent-4);
                  --control-connect-background-hover: var(--accent-3);
                  --control-connect-border-active: var(--button-border);
                  --control-connect-border-default: var(--button-border);
                  --control-connect-border-hover: var(--button-border);
                  --control-connect-icon-active: var(--text-0);
                  --control-connect-icon-default: var(--text-0);
                  --control-connect-icon-hover: var(--text-0);
                  --control-connect-text-active: var(--text-0);
                  --control-connect-text-default: var(--text-0);
                  --control-connect-text-hover: var(--text-0);
                  --control-critical-primary-background-active: var(--red-5);
                  --control-critical-primary-background-default: var(--red-3);
                  --control-critical-primary-background-hover: var(--red-4);
                  --control-critical-primary-border-active: var(--button-border);
                  --control-critical-primary-border-default: var(--button-border);
                  --control-critical-primary-border-hover: var(--button-border);
                  --control-critical-primary-icon-active: var(--text-0);
                  --control-critical-primary-icon-default: var(--text-0);
                  --control-critical-primary-icon-hover: var(--text-0);
                  --control-critical-primary-text-active: var(--text-0);
                  --control-critical-primary-text-default: var(--text-0);
                  --control-critical-primary-text-hover: var(--text-0);
                  --control-critical-secondary-background-active: var(--text-5);
                  --control-critical-secondary-background-default: var(--bg-2);
                  --control-critical-secondary-background-hover: var(--bg-1);
                  --control-critical-secondary-border-active: var(--border-light);
                  --control-critical-secondary-border-default: var(--border-light);
                  --control-critical-secondary-border-hover: var(--border-light);
                  --control-critical-secondary-icon-active: var(--red-2);
                  --control-critical-secondary-icon-default: var(--red-2);
                  --control-critical-secondary-icon-hover: var(--red-2);
                  --control-critical-secondary-text-active: var(--red-2);
                  --control-critical-secondary-text-default: var(--red-2);
                  --control-critical-secondary-text-hover: var(--red-2);
                  --control-expressive-background-active: var(--text-3);
                  --control-expressive-background-default: var(--text-1);
                  --control-expressive-background-hover: var(--text-2);
                  --control-expressive-border-active: var(--button-border);
                  --control-expressive-border-default: var(--button-border);
                  --control-expressive-border-hover: var(--button-border);
                  --control-expressive-icon-active: var(--bg-4);
                  --control-expressive-icon-default: var(--bg-4);
                  --control-expressive-icon-hover: var(--bg-4);
                  --control-expressive-text-active: var(--bg-4);
                  --control-expressive-text-default: var(--bg-4);
                  --control-expressive-text-hover: var(--bg-4);
                  --control-icon-only-background-active: var(--active);
                  --control-icon-only-background-hover: var(--hover);
                  --control-icon-only-border-active: var(--border-light);
                  --control-icon-only-border-hover: var(--border-light);
                  --control-icon-only-icon-active: var(--text-3);
                  --control-icon-only-icon-default: var(--text-4);
                  --control-icon-only-icon-hover: var(--text-3);
                  --control-overlay-primary-background-active: var(--text-3);
                  --control-overlay-primary-background-default: var(--text-1);
                  --control-overlay-primary-background-hover: var(--text-2);
                  --control-overlay-primary-border-active: var(--button-border);
                  --control-overlay-primary-border-default: var(--button-border);
                  --control-overlay-primary-border-hover: var(--button-border);
                  --control-overlay-primary-icon-active: var(--bg-4);
                  --control-overlay-primary-icon-default: var(--bg-4);
                  --control-overlay-primary-icon-hover: var(--bg-4);
                  --control-overlay-primary-text-active: var(--bg-4);
                  --control-overlay-primary-text-default: var(--bg-4);
                  --control-overlay-primary-text-hover: var(--bg-4);
                  --control-overlay-secondary-background-active: hsl(0, 0%, 0%, 0.4);
                  --control-overlay-secondary-background-default: hsl(0, 0%, 0%, 0.5);
                  --control-overlay-secondary-background-hover: hsl(0, 0%, 0%, 0.6);
                  --control-overlay-secondary-border-active: var(--border-light);
                  --control-overlay-secondary-border-default: var(--border-light);
                  --control-overlay-secondary-border-hover: var(--border-light);
                  --control-overlay-secondary-icon-active: var(--text-3);
                  --control-overlay-secondary-icon-default: var(--text-3);
                  --control-overlay-secondary-icon-hover: var(--text-3);
                  --control-overlay-secondary-text-active: var(--text-3);
                  --control-overlay-secondary-text-default: var(--text-3);
                  --control-overlay-secondary-text-hover: var(--text-3);
                  --control-primary-background-active: var(--accent-5);
                  --control-primary-background-default: var(--accent-3);
                  --control-primary-background-hover: var(--accent-4);
                  --control-primary-border-active: var(--button-border);
                  --control-primary-border-default: var(--button-border);
                  --control-primary-border-hover: var(--button-border);
                  --control-primary-icon-active: var(--text-0);
                  --control-primary-icon-default: var(--text-0);
                  --control-primary-icon-hover: var(--text-0);
                  --control-primary-text-active: var(--text-0);
                  --control-primary-text-default: var(--text-0);
                  --control-primary-text-hover: var(--text-0);
                  --control-secondary-background-active: var(--text-5);
                  --control-secondary-background-default: var(--bg-2);
                  --control-secondary-background-hover: var(--bg-1);
                  --control-secondary-border-active: var(--border-light);
                  --control-secondary-border-default: var(--border-light);
                  --control-secondary-border-hover: var(--border-light);
                  --control-secondary-icon-active: var(--text-3);
                  --control-secondary-icon-default: var(--text-3);
                  --control-secondary-icon-hover: var(--text-3);
                  --control-secondary-text-active: var(--text-3);
                  --control-secondary-text-default: var(--text-3);
                  --control-secondary-text-hover: var(--text-3);
                  /* --expressive-gradient-blue-end: lime;
           */
                  --gradient-progress-pill-background: var(--text-5);
                  --home-background: var(--bg-4);
                  --icon-feedback-critical: var(--red-1);
                  --icon-feedback-info: var(--blue-1);
                  --icon-feedback-positive: var(--green-1);
                  --icon-feedback-warning: var(--yellow-1);
                  --icon-link: var(--text-4);
                  --icon-muted: var(--text-5);
                  --icon-status-dnd: var(--dnd);
                  --icon-status-idle: var(--idle);
                  --icon-status-offline: var(--offline);
                  --icon-status-online: var(--online);
                  --icon-strong: var(--text-3);
                  --icon-subtle: var(--text-4);
                  --input-background-default: var(--bg-3);
                  --input-background-error-default: color-mix(in hsl, var(--red-2), transparent 90%);
                  --input-border-active: var(--accent-2);
                  --input-border-default: var(--border-light);
                  --input-border-error-default: var(--red-2);
                  --input-border-hover: var(--border);
                  --input-placeholder-text-default: var(--text-5);
                  --input-text-default: var(--text-3);
                  --input-text-error-default: var(--text-3);
                  --interactive-background-active: var(--active);
                  --interactive-background-hover: var(--hover);
                  --interactive-background-selected: var(--active);
                  --interactive-icon-active: var(--text-3);
                  --interactive-icon-default: var(--text-4);
                  --interactive-icon-hover: var(--text-3);
                  --interactive-muted: var(--text-5);
                  --interactive-text-active: var(--text-3);
                  --interactive-text-default: var(--text-4);
                  --interactive-text-hover: var(--text-3);
                  --mention-background: color-mix(in hsl, var(--accent-2), transparent 90%);
                  --mention-foreground: var(--accent-1);
                  --message-background-hover: var(--message-hover);
                  --message-highlight-background-default: var(--reply);
                  --message-highlight-background-hover: var(--reply-hover);
                  --message-mentioned-background-default: var(--mention);
                  --message-mentioned-background-hover: var(--mention-hover);
                  --message-reacted-background-default: color-mix(in hsl, var(--accent-2), transparent 80%);
                  --message-reacted-text-default: var(--text-2);
                  --modal-background: var(--bg-4);
                  --modal-footer-background: var(--bg-4);
                  --notice-background-critical: var(--red-3);
                  --notice-background-info: var(--blue-3);
                  --notice-background-positive: var(--green-3);
                  --notice-background-warning: var(--yellow-3);
                  --notice-text-critical: var(--text-0);
                  --notice-text-info: var(--text-0);
                  --notice-text-positive: var(--text-0);
                  --notice-text-warning: var(--text-0);
                  --polls-victor-fill: color-mix(in hsl, var(--green-2), transparent 90%);
                  --polls-voted-fill: color-mix(in hsl, var(--accent-2), transparent 90%);
                  /* --premium-nitro-pink-text: magenta; */
                  --radio-background-active: var(--bg-2);
                  --radio-background-default: var(--bg-3);
                  --radio-background-hover: var(--bg-2);
                  --radio-background-selected-default: var(--accent-2);
                  --radio-background-selected-hover: var(--accent-3);
                  --radio-border-active: var(--border);
                  --radio-border-default: var(--border);
                  --radio-border-hover: var(--border);
                  --radio-border-selected-default: var(--button-border);
                  --radio-border-selected-hover: var(--button-border);
                  --radio-thumb-background-active: var(--text-0);
                  --redesign-button-overlay-alpha-background: hsl(0, 0%, 0%, 0.5);
                  --redesign-button-overlay-alpha-pressed-background: hsl(0, 0%, 0%, 0.7);
                  --redesign-button-overlay-alpha-text: var(--text-3);
                  --redesign-button-secondary-background: var(--bg-2);
                  --redesign-button-secondary-pressed-background: var(--bg-1);
                  --redesign-button-secondary-text: var(--text-3);
                  --scrollbar-auto-thumb: var(--bg-3);
                  --scrollbar-auto-track: transparent;
                  --scrollbar-thin-thumb: var(--bg-3);
                  --scrollbar-thin-track: transparent;
                  --spine-default: var(--text-5);
                  --status-danger: var(--red-2);
                  --status-online: var(--green-2);
                  --status-positive: var(--green-2);
                  --status-positive-background: var(--green-2);
                  --status-speaking: var(--green-2);
                  --status-warning: var(--yellow-2);
                  --text-brand: var(--accent-1);
                  --text-default: var(--text-3);
                  --text-feedback-critical: var(--red-1);
                  --text-feedback-info: var(--accent-1);
                  --text-feedback-positive: var(--green-1);
                  --text-feedback-warning: var(--yellow-1);
                  --text-link: var(--accent-1);
                  --text-muted: var(--text-5);
                  --text-overlay-light: var(--text-0);
                  --text-status-dnd: var(--dnd);
                  --text-status-idle: var(--idle);
                  --text-status-offline: var(--offline);
                  --text-status-online: var(--online);
                  --text-strong: var(--text-2);
                  --text-subtle: var(--text-4);
                  --textbox-markdown-syntax: var(--text-4);
                  --user-profile-background-hover: var(--hover);
                  --user-profile-border: var(--border);
                  --user-profile-note-background-focus: var(--bg-4);
                  --user-profile-overlay-background: var(--bg-4);
                  --user-profile-overlay-background-hover: var(--hover);
                  --user-profile-toolbar-background: var(--bg-3);
                  --user-profile-toolbar-border: var(--border);

                  --white: var(--text-0);
                  --white-500: var(--text-0);

                  --brand-360: var(--accent-2);
                  --brand-500: var(--accent-2);
                  --blurple-50: var(--accent-2);

                  --red-400: var(--red-2);
                  --red-500: var(--red-3);

                  --green-360: var(--green-2);
                  --yellow-300: var(--yellow-2);
                  --primary-400: var(--text-4);
              }

              .custom-user-profile-theme {
                  --white: var(--text-1);
                  --white-500: var(--text-1);
              }

              ::placeholder {
                  color: var(--text-5);
              }

              .bg__960e4 {
                  background: var(--bg-3);
              }

              .modeUnreadImportant__2ea32 .icon__2ea32,
                  .wrapper__2ea32:hover .icon__2ea32 {
                  color: var(--text-3);
              }

              .text_b88801 > strong {
                  color: var(--text-3);
              }

              .hiddenVisually_b18fe2[aria-expanded="false"] > .folderPreviewWrapper__48112 {
                  --background-primary: var(--bg-3);
              }

              .panel__5dec7,
                  .container__722ff {
                  background: none;
              }

              .side_aa8da2 .item_aa8da2:hover {
                  background-color: var(--bg-3) !important;
              }
              .side_aa8da2 .item_aa8da2:active,
              .side_aa8da2 .item_aa8da2.selected_aa8da2 {
                  background-color: var(--bg-2) !important;
              }

              .quickSelectPopout_ebaca5,
                  .participantsButton__211d1,
                  .voiceBar__7aaec,
                  .mainCard_f369db,
                  .accountProfileCard__1fed1 {
                  background-color: var(--bg-3);
              }

              .colorable_f1ceac.primaryDark_f1ceac,
                  .reaction_f8896c {
                  background-color: var(--bg-2);
              }

              .expandedFolderIconWrapper__48112 > svg[style="color: rgb(88, 101, 242);"] {
                  color: var(--accent-2) !important;
              }
              .colorPickerSwatch__459fb[style="background-color: rgb(88, 101, 242);"],
                  .newBadge_faa96b,
                  .mentioned__5126c:before {
                  background-color: var(--accent-2) !important;
              }
              .replying__5126c:before {
                  background-color: var(--text-2) !important;
              }

              .badge_c3d04b {
                  background-color: var(--text-1);
              }

              #app-mount .message__5126c.replying__5126c:hover {
                  background: var(--reply-hover);
              }

              .voiceBar__7aaec .barText__7aaec, .voiceChannelsIcon__7aaec {
                  color: var(--accent-2);
              }

              .ephemeral__5126c {
                  background: var(--mention) !important;
              }
              .ephemeral__5126c:hover {
                  background: var(--mention-hover) !important;
              }

              .botTagRegular__82f07 {
                  background-color: var(--accent-2);
              }
              .botTagOP__82f07 {
                  color: var(--text-0);
              }

              .productCardBadge_b8a6bd {
                  background-color: var(--bg-2) !important;
                  color: var(--text-3) !important;
              }

              #app-mount .addFriend__133bf:hover {
                  color: var(--text-0);
              }
              #app-mount .addFriend__133bf[aria-selected=true] {
                  background-color: var(--accent-5) !important;
                  color: var(--text-0);
              }

              .container__3f21e,
              .vc-switch-container {
                  background-color: var(--bg-1) !important;
                  transition: background-color 0.2s ease;
              }
              .container__3f21e.checked__3f21e,
              .vc-switch-container.vc-switch-checked {
                  background-color: var(--accent-2) !important;
              }
              .container__3f21e .slider__3f21e > svg > path,
              .vc-switch-container .vc-switch-slider > svg > path {
                  fill: var(--bg-1) !important;
                  transition: fill 0.2s ease;
              }
              .container__3f21e.checked__3f21e .slider__3f21e > svg > path,
              .vc-switch-container.vc-switch-checked .vc-switch-slider > svg > path {
                  fill: var(--accent-2) !important;
              }
              .container__3f21e rect[fill='white'],
              .vc-switch-container .vc-switch-slider rect[fill='white'] {
                  fill: var(--text-3) !important;
                  transition: fill 0.2s ease;
              }
              .container__3f21e.checked__3f21e rect[fill='white'],
              .vc-switch-container.vc-switch-checked .vc-switch-slider rect[fill='white'] {
                  fill: var(--text-0) !important;
              }

              .refreshIcon__88a69 {
                  fill: var(--text-0);
              }

              .categoryText_d02962,
                  .bannerColor_fb7f94,
                  .backButton_e4cb9a,
                  .viewersIcon_d6b206,
                  .bottomControls_e4cb9a,
                  .pictureInPictureVideo_e4cb9a .controlIcon_f1ceac,
                  .bannerVisible_f37cb1 .name_f37cb1,
                  .dropdownButtonBannerVisible__2637a,
                  .mediaMosaicAltText__0f481,
                  .bannerButton_fb7f94,
                  .embed__98ba8 {
                  color: var(--text-1);
              }
              .headerText_e4cb9a.base_eb1a4c,
                  .participantName__2cdb8 {
                  color: var(--text-1) !important;
              }
              .playPausePopIcon_cf09d8 > path,
              .normalIconColor__979b1 {
                  fill: var(--text-1);
              }
              .headerTitle_e4cb9a:hover {
                  border-color: var(--text-1) !important;
              }
              .controlIcon_cf09d8,
                  .wrapper_cf09d8,
                  .iconWrapper__6eb54,
                  .wrapper__926d7,
                  .viewersIcon_d6b206:hover ,
                  .headerTitle_e4cb9a:hover .backButton_e4cb9a,
                  .viewersIcon_d6b206:hover,
                  .pictureInPictureVideo_e4cb9a .controlIcon_f1ceac:hover {
                  color: var(--text-2);
              }
              .wrapper__926d7 a:link,
                  .wrapper__926d7 a:visited,
                  .headerTitle_e4cb9a:hover .headerText_e4cb9a.base_eb1a4c {
                  color: var(--text-2) !important;
              }
              .downloadHoverButtonIcon__6c706,
              .iconContainer__211d1>svg,
              .selectedIcon__2f4f7,
              .colorable_f1ceac.primaryDark_f1ceac .centerIcon_f1ceac,
              .colorable_f1ceac.primaryDark_f1ceac,
              .iconBadge__650eb.base__2b1f5,
              #app-mount .akaBadge__488b1,
              #app-mount .message__9a9f9,
              .friendRequestsButton__523aa .base__2b1f5,
              .tooltipBlack__382e7,
              .colorable_f1ceac.primaryDark_f1ceac, .colorable_f1ceac.primaryDark_f1ceac .centerIcon_f1ceac,
              .item_caf372.active_caf372,
              .interactive__972a0.interactiveSelected__972a0 {
                  color: var(--text-3);
              }
              .status__2f4f7 path[fill='var(--white)'],
                  .emptyChannelIcon__00de6 path[fill='var(--white)'] {
                  fill: var(--text-3);
              }
              .grabber_a562c8 {
                  background-color: var(--text-3);
              }
              .textBadge__2b1f5 {
                  color: var(--text-0);
              }
              .textBadge__2b1f5[style='background-color: var(--primary-500);'] {
                  background-color: var(--bg-2) !important;
                  --white-500: var(--text-3);
              }

              .unread__3b95d,
                  .item_caf372,
                  .interactive__972a0 {
                  color: var(--text-4);
              }

              .colorable_f1ceac.white_f1ceac {
                  background-color: var(--primary-130);
                  color: var(--bg-4);
              }

              .iconBadge__650eb.isCurrentUserConnected__650eb {
                  color: var(--text-0);
              }

              .lookOutlined__201d5.colorWhite__201d5 {
                  border-color: var(--text-5);
                  color: var(--text-3);
              }

              .container__37e49,
                  .numberBadge__2b1f5,
                  .toolbar__9293f {
                  --status-danger: var(--accent-new);
              }

              .container__37e49 .button__67645.redGlow__67645 {
                  background-color: color-mix(in hsl, var(--accent-new), transparent 90%);
              }
              .container__37e49 .button__67645.enabled__67645.redGlow__67645:hover {
                  background-color: color-mix(in hsl, var(--accent-new), transparent 80%);
              }

              .divider__5126c {
                  --divider-color: var(--accent-new);
              }

              .icon_c1e9c4 > circle[fill="#C12A35"] {
                  fill: var(--accent-new) !important;
              }

              .iconBadge__9293f,
                  .mentionsBar__7aaec,
                  .mention__3b95d,
                  .badge_c99c29 {
                  background-color: var(--accent-new);
              }

              .newMessagesBar__0f481 {
                  background-color: var(--accent-3);
              }
              .barButtonAlt__0f481 {
                  --control-secondary-background-default: var(--accent-3);
                  --control-secondary-background-hover: var(--accent-4);
              }

              .updateIconForeground__49676 {
                  fill: var(--green-1);
              }

              .colorable_f1ceac.red_f1ceac:hover {
                  background-color: var(--red-4);
              }
              .button_f7ecac.dangerous_f7ecac:hover {
                  color: var(--red-4);
              }
              .contentWrapper__08434 ::-webkit-scrollbar-thumb {
                  background-color: var(--bg-1);
              }

              .circleIconButton__5bc7e {
                  color: var(--text-3);
              }
              .circleIconButton__5bc7e:hover {
                  color: var(--bg-4);
              }

              .tooltipGrey_c36707 {
                  color: var(--text-3);
                  background-color: var(--bg-3);
              }

              .textContentFooter__9a337 {
                  background: linear-gradient(0deg, var(--bg-4), transparent);
              }

              .result__2dc39:after {
                  display: none;
              }
              .result__2dc39:hover {
                  outline: 2px solid var(--accent-2);
              }

              .reactionBtn__23977.forceShow__23977:hover {
                  border-color: var(--bg-2);
              }

              .flash__03436[data-flash=true] {
                  background: var(--background-message-highlight);
              }

              .container__8a031 {
                  background-color: var(--bg-4);
              }

              .flash__03436[data-flash='true'] {
                  background: var(--reply);
              }

              rect[fill='#84858d'] {
                  fill: var(--offline);
              }
              .status_a423bd[style='background-color: rgb(132, 133, 141);'] {
                  background-color: var(--offline) !important;
              }
              rect[fill='#45a366'],
                  path[fill='#45a366'],
                  path[fill='var(--status-positive)'],
                  .vc-platform-indicator > svg[fill="#45a366"] {
                  fill: var(--online);
              }
              .status_a423bd[style='background-color: rgb(69, 163, 102);'] {
                  background-color: var(--online) !important;
              }
              rect[fill='#ffc04e'],
              .vc-platform-indicator > svg[fill='#ffc04e'] {
                  fill: var(--idle);
              }
              .status_a423bd[style='background-color: rgb(255, 192, 78);'] {
                  background-color: var(--idle) !important;
              }
              rect[fill='#da3e44'],
              .vc-platform-indicator > svg[fill='#da3e44'] {
                  fill: var(--dnd);
              }
              .status_a423bd[style='background-color: rgb(218, 62, 68);'] {
                  background-color: var(--dnd) !important;
              }
              rect[fill='#9147ff'] {
                  fill: var(--streaming);
              }
              div[style='display: flex; justify-content: center; align-items: center; border-radius: 5px; background-color: rgb(69, 163, 102); height: 10px; width: 25px;'] {
                  background-color: var(--online) !important;
              }

              .radioBar__88a69[style='--radio-bar-accent-color: var(--yellow-360); padding: 10px;'] {
                  --radio-bar-accent-color: var(--yellow-2) !important;
              }
              .radioBar__88a69[style='--radio-bar-accent-color: var(--green-360); padding: 10px;'] {
                  --radio-bar-accent-color: var(--green-2) !important;
              }
              .radioBar__88a69[style='--radio-bar-accent-color: var(--red-400); padding: 10px;'] {
                  --radio-bar-accent-color: var(--red-2) !important;
              }

              #vc-spotify-player {
                  --vc-spotify-green: var(--accent-2);
              }

              .vcd-screen-picker-option-radio[data-checked='true'] .defaultColor__4bd52 {
                  color: var(--text-0);
              }

              .memberRowContainer__71c22.memberSelected__71c22 td {
                  background: var(--bg-3);
              }

              ::selection,
              .highlight {
                  background: var(--accent-3);
                  color: var(--text-0);
              }

              .switchIndicator_a28278[style*='background-color: rgb(88, 101, 242)'] {
                  background-color: var(--accent-3) !important;
              }
              .switchIndicator_a28278[style*='background-color: rgb(68, 82, 187)'] {
                  background-color: var(--accent-4) !important;
              }

          /* dms-button.css */

              .wrapper__6e9f8[data-list-item-id='guildsnav___home'] > .childWrapper__6e9f8 {
                  color: var(--dms-icon-color-before);
              }
              .wrapper__6e9f8[data-list-item-id='guildsnav___home']:hover > .childWrapper__6e9f8,
              .wrapper__6e9f8[data-list-item-id='guildsnav___home'].selected__6e9f8 > .childWrapper__6e9f8 {
                  color: var(--dms-icon-color-after);
              }

          /* top-bar.css */

          .platform-osx .wrapper_ef3116 {
              margin-top: max(0px, calc(36px - var(--top-bar-height)));
          }

              #app-mount {
                  --custom-channel-header-height: calc(var(--guildbar-avatar-size) + var(--space-xs) + var(--border-thickness) * 2);
                  /* --top-bar-right-margin: calc(32px + var(--space-xs)); */
                  --top-bar-right-margin: calc(32px + var(--space-xs));
                  --custom-app-panels-height: 80px;
              }

              .title_c38106,
              .trailing_c38106 > a[href='https://support.discord.com'] {
                  display: none;
              }
              .trailing_c38106 {
                  position: absolute;
                  top: calc(var(--top-bar-height) + 8px + var(--border-thickness));
                  right: calc(var(--gap) + var(--border-thickness));
                  gap: var(--space-xs);
                  z-index: 1000;
                  padding-right: var(--space-xs);
                  height: 32px;
              }
              .systemBar_c38106 .trailing_c38106 {
                  top: var(--space-xs);
              }
              .winButtons_c38106 {
                  padding: 0;
              }
              .winButton_c38106 {
                  height: calc(var(--window-control-size) * 2);
              }
              .winButtons_c38106::before {
                  height: 16px;
                  width: var(--space-xs);
                  box-sizing: border-box;
                  margin: 0;
              }
              .toolbar__9293f {
                  padding-right: var(--top-bar-right-margin);
              }
              .navBarContent__88ef1,
              .headerBarContent__1a9ce {
                  padding-right: var(--top-bar-right-margin);
              }
              .headerBar__8a7fc {
                  padding-right: calc(var(--top-bar-right-margin) + var(--space-sm));
              }
              .searchFloating__1ac1c {
                  right: calc(var(--top-bar-right-margin) + var(--space-sm));
              }
              .balanceWidgetMenu__80679 {
                  margin-right: var(--top-bar-right-margin);
              }
              .inviteToolbar__133bf {
                  padding-right: 0;
              }
              .chat_f75fb0 > .layerContainer__59d0d {
                  z-index: 999;
              }
              .subtitleContainer_f75fb0 {
                  height: var(--custom-channel-header-height);
              }
              .title_f75fb0.container__9293f {
                  min-height: 0;
                  height: auto;
              }
              .followButton_f75fb0 {
                  padding-top: 0;
                  padding-bottom: 0;
              }
              .base__5e434:has(.notice__6e2b9) > .bar_c38106 > .trailing_c38106 {
                  top: calc(var(--top-bar-height) + 8px + 40px + var(--gap) + var(--border-thickness));
              }
              .base__5e434:has(.winButtons_c38106) {
                  --top-bar-right-margin: calc(32px + 3 * var(--space-xs) + 6 * var(--window-control-size) + 1px);
              }
              .base__5e434:has(.trailing_c38106 > .button__85643) {
                  --top-bar-right-margin: calc(32px * 2 + 2 * var(--space-xs));
              }
              .base__5e434:has(.winButtons_c38106):has(.trailing_c38106 > .button__85643) {
                  --top-bar-right-margin: calc(32px * 2 + 5 * var(--space-xs) + 6 * var(--window-control-size) + 1px);
              }
              /* .base__5e434:has(.trailing_c38106 > .button__85643:nth-of-type(3)) {
                  --top-bar-right-margin: calc(32px * 3 + 3 * var(--space-xs));
              }
              .base__5e434:has(.winButtons_c38106) {
                  --top-bar-right-margin: calc(32px * 2 + 5 * var(--space-xs) + 6 * var(--window-control-size) + 1px);
              }
              .base__5e434:has(.winButtons_c38106):has(.trailing_c38106 > .button__85643:nth-of-type(3)) {
                  --top-bar-right-margin: calc(32px * 3 + 6 * var(--space-xs) + 6 * var(--window-control-size) + 1px);
              } */

          /* transparency-blur.css */

          /* user-panel.css */

              .panels__5e434 {
                  bottom: 0;
                  right: 0;
                  left: unset;
                  width: calc(var(--custom-guild-sidebar-width) - var(--custom-guild-list-width));
                  height: 80px;
                  overflow: hidden;
              }
              .panels__5e434 > .container__37e49 {
                  height: 100%;
                  display: flex;
                  align-items: center;
                  padding: 0;
              }
              .panels__5e434 .flex__7c0ba,
              .panels__5e434 .avatarWrapper__37e49,
              .panels__5e434 .wrapper__37e49 {
                  height: 100%;
                  align-items: center;
              }
              .guilds__5e434 {
                  margin-bottom: 0;
              }
              .accountProfileCard__1fed1 {
                  padding-block: 0 !important;
              }

          /* window-controls.css */

              .winButton_c38106 {
                  width: calc(var(--window-control-size) * 2);
                  height: calc(var(--window-control-size) * 2);
              }
              .winButtons_c38106 {
                  gap: 0;
              }

          body {
              letter-spacing: -0.05ch;

              --border-thickness: 2px;
              --border-hover-transition: 0.2s ease;

              --animations: off;

              --top-bar-height: var(--gap);

              --window-control-size: 14px;

              --dms-icon-color-before: var(--icon-subtle);
              --dms-icon-color-after: var(--white);

              --small-user-panel: on;

              --unrounding: on;

              --custom-spotify-bar: on;
              --ascii-titles: off;
              --ascii-loader: system24;

              --panel-labels: on;
              --label-color: var(--text-muted);
              --label-font-weight: 500;
          }

          :root {
              --colors: on;

              --text-0: var(--bg-4);
              --text-1: oklch(95% 0 0);
              --text-2: oklch(85% 0 0);
              --text-3: oklch(75% 0 0);
              --text-4: oklch(60% 0 0);
              --text-5: oklch(40% 0 0);

              --bg-1: oklch(31% 0 0);
              --bg-2: oklch(27% 0 0);
              --bg-3: oklch(23% 0 0);
              --bg-4: oklch(19% 0 0);
              --hover: oklch(54% 0 0 / 0.1);
              --active: oklch(54% 0 0 / 0.2);
              --active-2: oklch(54% 0 0 / 0.3);
              --message-hover: var(--hover);

              --accent-1: var(--purple-1);
              --accent-2: var(--purple-2);
              --accent-3: var(--purple-3);
              --accent-4: var(--purple-4);
              --accent-5: var(--purple-5);
              --accent-new: var(--accent-2);
              --mention: linear-gradient(to right, color-mix(in hsl, var(--accent-2), transparent 90%) 40%, transparent);
              --mention-hover: linear-gradient(to right, color-mix(in hsl, var(--accent-2), transparent 95%) 40%, transparent);
              --reply: linear-gradient(to right, color-mix(in hsl, var(--text-3), transparent 90%) 40%, transparent);
              --reply-hover: linear-gradient(to right, color-mix(in hsl, var(--text-3), transparent 95%) 40%, transparent);

              --online: var(--green-2);
              --dnd: var(--red-2);
              --idle: var(--yellow-2);
              --streaming: var(--purple-2);
              --offline: var(--text-4);

              --border-light: var(--hover);
              --border: var(--active);
              --border-hover: var(--accent-2);
              --button-border: hsl(220, 0%, 100%, 0.1);

              --red-1: oklch(75% 0.13 0);
              --red-2: oklch(70% 0.13 0);
              --red-3: oklch(65% 0.13 0);
              --red-4: oklch(60% 0.13 0);
              --red-5: oklch(55% 0.13 0);

              --green-1: oklch(75% 0.12 170);
              --green-2: oklch(70% 0.12 170);
              --green-3: oklch(65% 0.12 170);
              --green-4: oklch(60% 0.12 170);
              --green-5: oklch(55% 0.12 160);

              --blue-1: oklch(75% 0.11 215);
              --blue-2: oklch(70% 0.11 215);
              --blue-3: oklch(65% 0.11 215);
              --blue-4: oklch(60% 0.11 215);
              --blue-5: oklch(55% 0.11 215);

              --yellow-1: oklch(80% 0.12 90);
              --yellow-2: oklch(75% 0.12 90);
              --yellow-3: oklch(70% 0.12 90);
              --yellow-4: oklch(65% 0.12 90);
              --yellow-5: oklch(60% 0.12 90);

              --purple-1: oklch(75% 0.12 310);
              --purple-2: oklch(70% 0.12 310);
              --purple-3: oklch(65% 0.12 310);
              --purple-4: oklch(60% 0.12 310);
              --purple-5: oklch(55% 0.12 310);
          }

          .visual-refresh {
              .bg__960e4 {
                  background: var(--background-base-low);
              }
              .container__01ae2 {
                  background-color: var(--background-base-low);
              }
              .container__37e49 {
                  padding: 8px;
              }
          }

              .content_a2f514 {
                  display: flex;
                  flex-direction: column;
                  align-items: center;
                  gap: 20px;
              }
              .content_a2f514 > .spinner_a2f514 {
                  display: none;
              }
              .content_a2f514::before {
                  display: block;
                  content: ' ⟋|､\A(°､ ｡ 7\A |､  ~ヽ\A じしf_,)〳';
                  font-size: 18px;
                  white-space: pre;
                  line-height: 1.2;
                  background: linear-gradient(to right, var(--brand-360) 0%, var(--background-accent) 25%, var(--background-accent) 75%, var(--brand-360) 100%);
                  -webkit-background-clip: text;
                  -webkit-text-fill-color: transparent;
                  background-size: 200% auto;
                  animation: textShine 1.5s linear infinite reverse;
              }
              .text_a2f514 {
                  position: static;
              }

              @keyframes textShine {
                  0% {
                      background-position: 0% 50%;
                  }
                  50% {
                      background-position: 100% 50%;
                  }
                  50.0001% {
                      background-position: -100%, 50%;
                  }
                  100% {
                      background-position: 0% 50%;
                  }
              }

              #app-mount .wrapper__44b0c,
              #app-mount .container__1ce5d {
                  --online-2: var(--online);
                  --dnd-2: var(--dnd);
                  --idle-2: var(--idle);
                  --offline-2: var(--offline);
                  --streaming-2: var(--streaming);
              }

          /* panel-labels.css */

          /* spotify-bar.css */

              .visual-refresh {
                  /* text-like spotify progress bar */
                  #vc-spotify-progress-bar {
                      margin: 8px 0 0 0;
                  }
                  .vc-spotify-button-row {
                      margin-top: 8px;
                  }
                  #app-mount #vc-spotify-progress-bar .bar_a562c8 {
                      height: 22px !important;
                      top: 0 !important;
                      background-color: var(--background-surface-high);
                  }
                  #app-mount #vc-spotify-progress-bar .barFill_a562c8 {
                      height: 22px !important;
                  }
                  #vc-spotify-progress-bar .vc-spotify-time-left,
                  #vc-spotify-progress-bar .vc-spotify-time-right {
                      z-index: 1;
                      top: 0;
                      margin-top: 0;
                      mix-blend-mode: difference;
                      font-size: 16px;
                      line-height: 22px;
                      pointer-events: none;
                  }
                  #vc-spotify-progress-bar .vc-spotify-time-left {
                      left: 6px;
                  }
                  #vc-spotify-progress-bar .vc-spotify-time-right {
                      right: 6px;
                  }
                  #vc-spotify-progress-bar .grabber_a562c8 {
                      visibility: hidden;
                  }
              }

              *,
              *::before,
              *::after {
                  border-radius: 0 !important;
              }

              .svg_cc5dd2 > mask,
              .svg__44b0c > rect,
              .svg__44b0c > circle,
              .svg__44b0c > g,
              .svg__44b0c rect[mask='url(#:rhi:)'],
              .avatar__20a53 .status_a423bd {
                  display: none;
              }

              .mask__68edb > foreignObject,
              .svg__44b0c > foreignObject,
              .svg__2338f > foreignObject {
                  mask: none;
              }

              .wrapper__44b0c,
              .container__1ce5d {
                  --online-2: #43a25a;
                  --dnd-2: #d83a41;
                  --idle-2: #ca9654;
                  --offline-2: #82838b;
                  --streaming-2: #9147ff;
              }
              .wrapper__44b0c:has(rect)::after,
              .container__1ce5d:has(.status_a423bd)::after {
                  content: ''';
                  display: block;
                  position: absolute;
                  height: 8px;
                  width: 8px;
                  bottom: -4px;
                  right: -4px;
                  border: 2px solid var(--background-base-lower);
              }
              .wrapper__44b0c:has(rect[fill='#45a366'])::after,
              .container__1ce5d:has(.status_a423bd[style='background-color: rgb(67, 162, 90);'])::after {
                  background: var(--online-2) !important;
              }
              .wrapper__44b0c:has(rect[fill='#da3e44'])::after {
                  background: var(--dnd-2) !important;
              }
              .wrapper__44b0c:has(rect[fill='#ffc04e'])::after {
                  background: var(--idle-2) !important;
              }
              .wrapper__44b0c:has(rect[fill='#84858d'])::after {
                  background: var(--offline-2) !important;
              }
              .wrapper__44b0c:has(rect[fill='#9147ff'])::after {
                  background: var(--streaming-2);
              }

              .lowerBadge_cc5dd2 {
                  border: 2px solid var(--background-base-lower);
                  bottom: -4px;
                  right: -4px;
              }
              .upperBadge_cc5dd2 {
                  border: 2px solid var(--background-base-lower);
                  top: -4px;
                  right: -4px;
              }
              .folderGroup__48112.isExpanded__48112 > .stack_dbd263 {
                  overflow: visible !important;
              }

              .slider__3f21e > rect[rx='10'] {
                  rx: 0 !important;
              }

              ::-webkit-scrollbar-thumb {
                  border-radius: 0 !important;
              }

          /* user settings */
          body {
              --gap: 0.25em;
              --divider-thickness: 0.1em;
              --border-thickness: 0.1em;
          }

          /* ============================================================
             CHAT WINDOW — from MinimalImprovement (MIT)
             https://github.com/Juicysteak117/MinimalImprovement
             ============================================================ */

          /* Chat message avatars (smaller) */
          .avatar_c19a55 { height: 20px !important; width: 20px !important; margin-left: -16px; }
          .avatar_c19a55 { margin-left: -2px; }
          .clickableHeader-2Cygs8 .avatar_c19a55:active, .clickableHeader-2Cygs8 .avatar_c19a55:hover { transform: none; filter: none; }
          .container-1YxwTf .large-3ChYtB { margin: 2px 8px 0 18px; width: 20px; height: 20px; }
          .container-1YxwTf .image-33JSyf { margin: 0; }
          .avatarDecoration_c19a55 { width: calc(28px*var(--decoration-to-avatar-ratio)); height: calc(28px*var(--decoration-to-avatar-ratio)); left: calc(31px - 40px*var(--decoration-to-avatar-ratio)/2); margin-top: calc(22px - .125rem - 40px*var(--decoration-to-avatar-ratio)/2); }

          /* Message layout */
          .username_c19a55 { font-weight: 400; font-size: 14.8px; }
          .timestampCozy-1HNQR2 { font-weight: 400; }
          .timestampCozyAlt-1Hs08c { width: 35px; overflow: hidden; }
          .timestamp_c19a55 { color: #6e7175 !important; }
          .container__235ca { padding: 0 16px 0 47px; }
          .cozy_c19a55 .header_c19a55 { padding-left: 13px; margin-left: -13px; }
          .cozy_c19a55.wrapper_c19a55 { padding-left: 47px; }
          .cozy_c19a55 .messageContent_c19a55 { padding-left: 23px; margin-left: -23px; }
          .cozy_c19a55 .timestamp_c19a55.alt_c19a55 { left: -16px; }
          .cozy_c19a55 .repliedMessage_c19a55:before { --gutter: 5px; }
          .compact_c19a55.wrapper_c19a55 { padding-left: 58px; }
          .compact_c19a55 .container__235ca { padding: 0 1rem 0 69px; }
          .compact_c19a55 .timestamp_c19a55 { margin-left: 3px; margin-right: 0px; }
          .compact_c19a55.wrapper_c19a55, .cozy_c19a55.wrapper_c19a55 { padding-top: 0; padding-bottom: 0; }

          /* Message states */
          .message__5126c.mentioned__5126c.selected__5126c, .mouse-mode .mentioned__5126c:hover { background-color: var(--background-mentioned); }
          .message__5126c.mentioned__5126c.selected__5126c, .mouse-mode.full-motion .mentioned__5126c:hover, .theme-dark .mentioned__5126c:hover { background-color: var(--background-mentioned); }
          .theme-dark .groupStart__5126c { margin-top: 2px; }
          .theme-dark .hasContent__5126c { margin-top: 7px !important; margin-bottom: 7px !important; }
          .theme-dark .beforeGroup__5126c { margin-bottom: 3px !important; margin-top: -3px !important; top: 5px !important; }

          /* ============================================================
             MEMBER LIST — from MinimalImprovement (MIT)
             ============================================================ */

          /* Container */
          .members_c8ffbb { width: 240px; min-width: 240px; max-width: 240px; }
          .theme-dark .members_c8ffbb-loading { border-left: 2px solid #1e2124; }
          .members_c8ffbb::-webkit-scrollbar { width: 0px !important; height: 0 !important; }

          /* Group header */
          .membersGroup_c8ffbb { margin: 3px 0 2px 0 !important; font-size: 13px !important; padding: 0 8px 0 38px; height: auto; line-height: 13px; overflow: visible; text-overflow: clip; display: block; white-space: normal; max-width: 240px; }

          /* Member rows */
          .member-3W1lQa { margin: 1px 0 1px 6px; }
          .theme-dark .memberOnline-1CIh-0 { height: 30px; }
          .theme-dark .memberOffline-2lN7gt { height: 30px; }
          .memberInner-2CPc3V { width: 190px; }
          .member__5d473 { margin-left: 0; padding-left: 0px; max-width: 250px; }
          .nameTag-3p0yK- { font-size: 14px; }
          .theme-dark .members_c8ffbb .member.popout-open, .theme-dark .members_c8ffbb .member:hover { background: #282b30; }

          /* Member avatars (smaller) */
          .members_c8ffbb .avatar-small { margin: 0 10px 0 0 !important; }
          .membersWrap_c8ffbb .small-5Os1Bb { height: 20px; width: 20px; }
          .membersWrap_c8ffbb .status-oxiHuE { height: 6px; width: 6px; }
          .membersWrap_c8ffbb .avatar__91a9d .wrapper-1VLyxH, .membersWrap_c8ffbb .avatar__91a9d { height: 22px !important; width: 22px !important; margin-top: 9px; }
          .membersWrap_c8ffbb .layout__91a9d { height: 28px; }
          .membersWrap_c8ffbb .name__91a9d { font-size: 15px; }
          .avatar-17mtNa .wrapper-1VLyxH, .member-3W1lQa .avatarWrapper-3B0ndJ { height: 20px !important; width: 20px !important; }
          .avatar__91a9d svg[class*="mask_"] { height: 28px; width: 28px; }
          .offline__5d473 .avatar__91a9d svg[class*="mask_"] { height: 22px; width: 22px; }
          .avatarDecoration-2OJuSI { height: calc(28px*var(--decoration-to-avatar-ratio)); width: calc(28px*var(--decoration-to-avatar-ratio)); top: calc((.35 - var(--decoration-to-avatar-ratio)/2)*100%); }

          /* Activity icons hidden */
          .activityIcon-1mtTk4 { display: none; }
          .activityIcon-S3CciC { display: none; }

          /* Scroller spacer */
          div[class*="scroller-2FKFPG da-scroller members_c8ffbb da-members"] div[style*="width: 100%;"]:last-of-type { height: 500px !important; }
          div[class*="scroller-2FKFPG da-scroller members_c8ffbb da-members scrolling-CehiO2 da-scrolling"] div[style*="width: 100%;"]:last-of-type { height: 500px !important; }

          /* Member list items */
          .memberListItem-31QoHj { margin: 4px -4px; }
          .popout-13LQ_3 .memberListContainer-13tNU9 { margin-top: 6px; }
          .popout-13LQ_3 .wrapper-3Rixsz { padding: 4px 8px; }
          .wrapper-3Rixsz:last-child { margin-bottom: 4px; }
          .member-3W1lQa rect[mask] { mask: url(#svg-mask-status-online); }

        '';
      };
    };
}
