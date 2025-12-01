# Shared wallust templates for NixOS and Darwin
# These use Jinja2 syntax: {{ color0 }}, {{ background | red }}, etc.
{lib}: rec {
  # Shared CSS variables template - importable by any CSS file
  # Output: ~/.config/wallust/colors.css
  colorsCss = ''
    /* Wallust generated colors - @import this file for dynamic theming */
    :root {
      /* Base terminal colors */
      --wallust-color0: {{ color0 }};
      --wallust-color1: {{ color1 }};
      --wallust-color2: {{ color2 }};
      --wallust-color3: {{ color3 }};
      --wallust-color4: {{ color4 }};
      --wallust-color5: {{ color5 }};
      --wallust-color6: {{ color6 }};
      --wallust-color7: {{ color7 }};
      --wallust-color8: {{ color8 }};
      --wallust-color9: {{ color9 }};
      --wallust-color10: {{ color10 }};
      --wallust-color11: {{ color11 }};
      --wallust-color12: {{ color12 }};
      --wallust-color13: {{ color13 }};
      --wallust-color14: {{ color14 }};
      --wallust-color15: {{ color15 }};

      /* Special colors */
      --wallust-background: {{ background }};
      --wallust-foreground: {{ foreground }};
      --wallust-cursor: {{ cursor }};

      /* Semantic aliases */
      --wallust-bg: {{ background }};
      --wallust-fg: {{ foreground }};
      --wallust-black: {{ color0 }};
      --wallust-red: {{ color1 }};
      --wallust-green: {{ color2 }};
      --wallust-yellow: {{ color3 }};
      --wallust-blue: {{ color4 }};
      --wallust-magenta: {{ color5 }};
      --wallust-cyan: {{ color6 }};
      --wallust-white: {{ color7 }};
      --wallust-bright-black: {{ color8 }};
      --wallust-bright-red: {{ color9 }};
      --wallust-bright-green: {{ color10 }};
      --wallust-bright-yellow: {{ color11 }};
      --wallust-bright-blue: {{ color12 }};
      --wallust-bright-magenta: {{ color13 }};
      --wallust-bright-cyan: {{ color14 }};
      --wallust-bright-white: {{ color15 }};
    }
  '';

  # Foot terminal colors (uses | strip to remove # from hex)
  footColors = ''
    [colors]
    foreground={{foreground | strip}}
    background={{background | strip}}
    selection-foreground={{background | strip}}
    selection-background={{foreground | strip}}
    urls={{color6 | strip}}

    regular0={{color0 | strip}}
    regular1={{color1 | strip}}
    regular2={{color2 | strip}}
    regular3={{color3 | strip}}
    regular4={{color4 | strip}}
    regular5={{color5 | strip}}
    regular6={{color6 | strip}}
    regular7={{color7 | strip}}

    bright0={{color8 | strip}}
    bright1={{color9 | strip}}
    bright2={{color10 | strip}}
    bright3={{color11 | strip}}
    bright4={{color12 | strip}}
    bright5={{color13 | strip}}
    bright6={{color14 | strip}}
    bright7={{color15 | strip}}
  '';

  # Discord quickCss with wallust colors baked in
  discordQuickCss = ''
    @import url("https://raw.codeberg.page/AllPurposeMat/Disblock-Origin/DisblockOrigin.theme.css");
    :root {
    	container-name: root;
    	--custom-guild-list-padding: 8px;
    	--gap: 3px;
    	--divider-thickness: 1px;
    	--border-thickness: 1px;
    	--top-bar-height: var(--gap);
    	--chatbar-height: 44px;
    	--window-control-size: 12px;
    	--custom-guild-list-width: calc(var(--guildbar-avatar-size) + var(--custom-guild-list-padding) * 2 + var(--border-thickness) * 2);
    	--custom-app-top-bar-height: var(--top-bar-height);
    	--custom-channel-textarea-text-area-height: var(--chatbar-height);
    	--custom-channel-header-height: calc(var(--guildbar-avatar-size) + var(--space-xs) + var(--border-thickness) * 2);
    	--top-bar-right-margin: calc(32px + var(--space-xs));
    	--border-hover-transition: 0.2s ease;
    	--list-item-transition: 0.2s ease;
    	--dms-icon-svg-transition: 0.4s ease;
    	--panel-backdrop-filter: none;
    	--border-hover: var(--accent-2);
    }
    body {
    	container-name: body;
    	--font: monospace;
    	--code-font: monospace;
    	--font-primary: var(--font), 'gg sans';
    	--font-display: var(--font), 'gg sans';
    	--font-code: var(--code-font), 'gg mono';
    	line-height: 1.3;
    }
    :root {
    	/* Wallust-driven base colors */
    	--base-gray: {{ foreground }};
    	--base-red: {{ color1 }};
    	--base-green: {{ color2 }};
    	--base-blue: {{ color4 }};
    	--base-yellow: {{ color3 }};
    	--base-purple: {{ color5 }};

    	/* Text colors */
    	--text-0: {{ color15 }};
    	--text-1: {{ color7 }};
    	--text-2: {{ foreground }};
    	--text-3: color-mix(in srgb, {{ foreground }} 80%, {{ background }});
    	--text-4: color-mix(in srgb, {{ foreground }} 60%, {{ background }});
    	--text-5: color-mix(in srgb, {{ foreground }} 40%, {{ background }});

    	/* Background colors */
    	--bg-1: color-mix(in srgb, {{ background }} 90%, {{ foreground }});
    	--bg-2: color-mix(in srgb, {{ background }} 95%, {{ foreground }});
    	--bg-3: {{ background }};
    	--bg-4: {{ color0 }};

    	/* Interaction states */
    	--hover: color-mix(in srgb, {{ foreground }} 10%, transparent);
    	--active: color-mix(in srgb, {{ foreground }} 20%, transparent);
    	--active-2: color-mix(in srgb, {{ foreground }} 30%, transparent);
    	--message-hover: var(--hover);

    	/* Red variants */
    	--red-1: {{ color9 }};
    	--red-2: {{ color1 }};
    	--red-3: color-mix(in srgb, {{ color1 }} 85%, black);
    	--red-4: color-mix(in srgb, {{ color1 }} 70%, black);
    	--red-5: color-mix(in srgb, {{ color1 }} 55%, black);

    	/* Green variants */
    	--green-1: {{ color10 }};
    	--green-2: {{ color2 }};
    	--green-3: color-mix(in srgb, {{ color2 }} 85%, black);
    	--green-4: color-mix(in srgb, {{ color2 }} 70%, black);
    	--green-5: color-mix(in srgb, {{ color2 }} 55%, black);

    	/* Blue variants */
    	--blue-1: {{ color12 }};
    	--blue-2: {{ color4 }};
    	--blue-3: color-mix(in srgb, {{ color4 }} 85%, black);
    	--blue-4: color-mix(in srgb, {{ color4 }} 70%, black);
    	--blue-5: color-mix(in srgb, {{ color4 }} 55%, black);

    	/* Yellow variants */
    	--yellow-1: {{ color11 }};
    	--yellow-2: {{ color3 }};
    	--yellow-3: color-mix(in srgb, {{ color3 }} 85%, black);
    	--yellow-4: color-mix(in srgb, {{ color3 }} 70%, black);
    	--yellow-5: color-mix(in srgb, {{ color3 }} 55%, black);

    	/* Purple/accent variants */
    	--purple-1: {{ color13 }};
    	--purple-2: {{ color5 }};
    	--purple-3: color-mix(in srgb, {{ color5 }} 85%, black);
    	--purple-4: color-mix(in srgb, {{ color5 }} 70%, black);
    	--purple-5: color-mix(in srgb, {{ color5 }} 55%, black);

    	/* Accent aliases */
    	--accent-1: var(--purple-1);
    	--accent-2: var(--purple-2);
    	--accent-3: var(--purple-3);
    	--accent-4: var(--purple-4);
    	--accent-5: var(--purple-5);
    	--accent-new: var(--red-2);

    	/* Status colors */
    	--online: var(--green-2);
    	--dnd: var(--red-2);
    	--idle: var(--yellow-2);
    	--streaming: var(--purple-2);
    	--offline: var(--text-4);

    	/* Border colors */
    	--border-light: var(--text-5);
    	--border: var(--text-5);
    	--border-hover: var(--purple-2);
    	--button-border: color-mix(in srgb, var(--text-1) 10%, transparent);

    	/* Mention/reply highlights */
    	--mention: linear-gradient(to right, color-mix(in srgb, var(--accent-2), transparent 90%) 40%, transparent);
    	--mention-hover: linear-gradient(to right, color-mix(in srgb, var(--accent-2), transparent 95%) 40%, transparent);
    	--reply: linear-gradient(to right, color-mix(in srgb, var(--text-3), transparent 90%) 40%, transparent);
    	--reply-hover: linear-gradient(to right, color-mix(in srgb, var(--text-3), transparent 95%) 40%, transparent);
    }
    *,*::before,*::after {
    	border-radius: 0 !important;
    }
    .app__160d8,#app-mount,body {
    	background: transparent !important;
    }
    ::placeholder {
    	color: var(--text-5);
    }
    ::selection,.highlight {
    	background: var(--accent-3);
    	color: var(--text-0);
    }
    [class*='scroll'] {
    	will-change: scroll-position;
    }
    ::-webkit-scrollbar-thumb {
    	border-radius: 0 !important;
    }
    .visual-refresh {
    	.guilds_c48ade,.sidebarList_c48ade,.panels_c48ade,.chat_f75fb0 > .subtitleContainer_f75fb0,.container_c8ffbb,.content_f75fb0 > .membersWrap_c8ffbb,.container__133bf > .container__9293f,.container_f391e3 > .container__9293f,.homeWrapper__0920e > .container__9293f,.container__01ae2 > .container__9293f,.container_fb64c9 > .container__9293f,.peopleColumn__133bf,.nowPlayingColumn__133bf,.scroller_c880e8,.container_f391e3 > .content_f75fb0,.shop__6db1d,.content_f75fb0 > .outer_c0bea0,.searchResultsWrap_a9e706,.container_f369db,.chat_fb64c9,.container_a592e1,.callContainer_cb9592,.wrapper_cb9592.sidebarOpen_cb9592 .callContainer_cb9592,.callContainer__722ff,.chat_f75fb0 > .header_c791b2,.chat_f75fb0 > .scrollerBase_d125d2,.chat_f75fb0 > .header__0b563,.chat_f75fb0 > .container__0b563 {
    		background-color: var(--background-base-lower);
    		border: var(--border-thickness) solid var(--border-hover);
    		backdrop-filter: var(--panel-backdrop-filter);
    		box-sizing: border-box;
    		transition: border-color var(--border-hover-transition);
    	}
    	.guilds_c48ade:hover,.sidebarList_c48ade:hover,.panels_c48ade:hover,.chat_f75fb0 > .subtitleContainer_f75fb0:hover,.container_c8ffbb:hover,.content_f75fb0 > .membersWrap_c8ffbb:hover,.container__133bf > .container__9293f:hover,.container_f391e3 > .container__9293f:hover,.homeWrapper__0920e > .container__9293f:hover,.container__01ae2 > .container__9293f:hover,.container_fb64c9 > .container__9293f:hover,.peopleColumn__133bf:hover,.nowPlayingColumn__133bf:hover,.scroller_c880e8:hover,.container_f391e3 > .content_f75fb0:hover,.shop__6db1d:hover,.content_f75fb0 > .outer_c0bea0:hover,.searchResultsWrap_a9e706:hover,.container_f369db:hover,.chat_fb64c9:hover,.container_a592e1:hover,.callContainer_cb9592:hover,.wrapper_cb9592.sidebarOpen_cb9592 .callContainer_cb9592:hover,.callContainer__722ff:hover,.chat_f75fb0 > .header_c791b2:hover,.chat_f75fb0 > .scrollerBase_d125d2:hover,.chat_f75fb0 > .header__0b563:hover,.chat_f75fb0 > .container__0b563:hover {
    		border-color: var(--border-hover);
    	}
    }
    .visual-refresh {
    	.panels_c48ade {
    		bottom: 0;
    		left: 0;
    		width: 100%;
    	}
    	.sidebar_c48ade {
    		margin: 0 var(--gap) var(--gap) var(--gap);
    	}
    	.guilds_c48ade {
    		margin-bottom: calc(var(--custom-app-panels-height, 0) + var(--gap));
    		margin-right: var(--gap);
    	}
    	.guilds_c48ade + div:not(.sidebarList_c48ade) {
    		width: 100% !important;
    	}
    	.sidebarList_c48ade {
    		margin-bottom: calc(var(--custom-app-panels-height, 0) + var(--gap));
    	}
    	.scroller_ef3116 {
    		padding: var(--custom-guild-list-padding) 0;
    	}
    	.folderGroup__48112,.listItem__650eb {
    		width: 100%;
    	}
    	.container__2637a {
    		padding-bottom: 0;
    	}
    	.container__9293f {
    		margin-bottom: var(--gap);
    	}
    	.title_c38106,.trailing_c38106 > a[href="https://support.discord.com"] {
    		display: none;
    	}
    	.trailing_c38106 {
    		position: absolute;
    		top: calc(var(--top-bar-height) + 8px + var(--border-thickness));
    		right: calc(var(--gap) + var(--border-thickness));
    		gap: var(--space-xs);
    		z-index: 1000;
    		padding-right: var(--space-xs);
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
    	.chat_f75fb0 > .layerContainer_da8173 {
    		z-index: 999;
    	}
    }
    .visual-refresh {
    	.chat_f75fb0 {
    		border: none !important;
    		background: none;
    	}
    	.chatContent_f75fb0 {
    		overflow: hidden;
    		background: none;
    	}
    	.container__133bf,.page_c48ade {
    		padding-bottom: var(--gap);
    		padding-right: var(--gap);
    		border: none !important;
    		background: none;
    	}
    	.page_c48ade > .chat_f75fb0,.page_c48ade > .container__133bf {
    		padding: 0;
    	}
    	.subtitleContainer_f75fb0 {
    		margin-bottom: var(--gap);
    		height: var(--custom-channel-header-height);
    	}
    	.title_f75fb0 {
    		border: none;
    		background: none;
    		margin-bottom: 0;
    		height: auto;
    		min-height: 0;
    	}
    	.page_c48ade > div > .chat_f75fb0 > .content_f75fb0 {
    		border-left: none;
    	}
    	.messagesWrapper__36d07 {
    		background-color: var(--background-base-lower);
    		border: var(--border-thickness) solid var(--border-hover);
    		backdrop-filter: var(--panel-backdrop-filter);
    		transition: border-color var(--border-hover-transition);
    	}
    	.messagesWrapper__36d07:hover {
    		border-color: var(--border-hover);
    	}
    	.scrollerSpacer__36d07 {
    		height: calc(26px + var(--space-xs));
    	}
    	.scroller__36d07::-webkit-scrollbar-track {
    		margin-bottom: 26px;
    	}
    	.form_f75fb0 {
    		display: flex;
    		flex-direction: column;
    		padding: 0;
    		width: 100%;
    		margin-top: 0;
    	}
    	.channelBottomBarArea_f75fb0 {
    		margin-top: var(--gap);
    	}
    	.channelTextArea_f75fb0 {
    		margin: 0;
    		background-color: var(--background-base-lower);
    		border: var(--border-thickness) solid var(--border-subtle);
    		backdrop-filter: var(--panel-backdrop-filter);
    		transition: border-color var(--border-hover-transition);
    	}
    	.channelTextArea_f75fb0:hover {
    		border-color: var(--border-hover);
    	}
    	.themedBackground__74017 {
    		background: none;
    		border: var(--border-thickness) solid var(--border-hover) !important;
    	}
    	.slateTextArea_ec4baf {
    		margin-left: 2px;
    	}
    	.chatContent_f75fb0:has(.typing_b88801) .messagesWrapper__36d07::before {
    		content: "";
    		position: absolute;
    		bottom: 0;
    		left: 0;
    		right: 0;
    		background: var(--background-base-lower);
    		height: 26px;
    		z-index: 2;
    	}
    	.typing_b88801 {
    		position: absolute;
    		order: -1;
    		top: calc(-26px + var(--border-thickness) * -1);
    		left: calc(var(--border-thickness));
    		padding: 0 0 0 var(--space-sm);
    		height: 26px;
    	}
    	.newMessagesBar__0f481 {
    		top: 12px;
    		left: 12px;
    		right: 12px;
    		padding: 0 8px;
    	}
    	.message__5126c.mentioned__5126c::before,.replying__5126c::before,.ephemeral__5126c::before {
    		width: var(--divider-thickness);
    		height: calc(100% - 2px);
    		top: 1px;
    		left: 1px;
    	}
    	.message__5126c {
    		margin-left: 4px;
    	}
    	.divider__908e2 {
    		border-width: var(--divider-thickness);
    	}
    	.endCap__908e2 {
    		margin-top: calc(var(--divider-thickness) / -2);
    	}
    	.divider__908e2 .content__908e2 {
    		margin-top: calc(var(--divider-thickness) - var(--divider-thickness) * 2);
    	}
    }
    .visual-refresh {
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
    	.members_c8ffbb,.member_c8ffbb {
    		background: none;
    	}
    	.resizeHandle__01ae2 {
    		background: transparent;
    	}
    	.privateChannels__35e86,.scroller__99e7c {
    		background: none;
    	}
    	.scroller__99e7c {
    		margin-bottom: 0;
    	}
    	.content_f75fb0 > .outer_c0bea0 {
    		margin-left: var(--gap);
    		overflow: hidden;
    		height: auto;
    		min-width: 340px;
    		background-position: center calc(-1 * var(--border-thickness));
    		background-size: 100% calc(100% + 2 * var(--border-thickness));
    	}
    	.outer_c0bea0 {
    		border: 1px solid var(--border-subtle);
    		background-position: center calc(-1 * var(--border-thickness));
    		background-size: 100% calc(100% + 2 * var(--border-thickness));
    	}
    }
    .visual-refresh {
    	.wrapper__2ea32 .link__2ea32,.container__91a9d,.channel__972a0,.side_b3f026 .item_b3f026 {
    		transition: margin-left var(--list-item-transition);
    		will-change: margin-left;
    	}
    	.wrapper__2ea32:hover .link__2ea32,.side_b3f026 .item_b3f026:hover {
    		margin-left: 10px;
    	}
    	.container__91a9d:hover,.channel__972a0:hover {
    		margin-left: 18px;
    	}
    	.unread__2ea32 {
    		width: 8px;
    		height: 8px;
    		margin-left: -4px;
    		transition: var(--list-item-transition);
    		will-change: margin-left;
    	}
    	.wrapper__2ea32:hover .unread__2ea32 {
    		margin-left: 4px;
    	}
    	.pill_e5445c.wrapper__58105 {
    		width: calc((var(--custom-guild-list-padding) - 4px) / 2 + 4px);
    	}
    	.item__58105 {
    		width: 4px;
    		margin-left: calc((var(--custom-guild-list-padding) - 4px) / 2);
    	}
    }
    body,.theme-dark:not(.custom-user-profile-theme),.theme-light:not(.custom-user-profile-theme) {
    	--activity-card-background: var(--bg-3);
    	--background-accent: var(--bg-2);
    	--background-floating: var(--bg-3);
    	--background-nested-floating: var(--bg-4);
    	--background-mentioned: var(--mention);
    	--background-mentioned-hover: var(--mention-hover);
    	--background-message-highlight: var(--reply);
    	--background-message-highlight-hover: var(--reply-hover);
    	--background-message-hover: var(--message-hover);
    	--background-primary: var(--bg-4);
    	--background-secondary: var(--bg-3);
    	--background-secondary-alt: var(--bg-3);
    	--background-tertiary: var(--bg-4);
    	--bg-base-primary: var(--bg-4);
    	--bg-base-secondary: var(--bg-4);
    	--bg-base-tertiary: var(--bg-3);
    	--background-base-low: var(--bg-4);
    	--background-base-lower: var(--bg-4);
    	--background-base-lowest: var(--bg-4);
    	--background-mod-subtle: var(--hover);
    	--background-mod-normal: var(--active);
    	--background-mod-strong: var(--active-2);
    	--background-modifier-accent: var(--hover);
    	--background-modifier-active: var(--active);
    	--background-modifier-hover: var(--hover);
    	--background-modifier-selected: var(--active);
    	--background-surface-high: var(--bg-3);
    	--background-surface-higher: var(--bg-3);
    	--background-surface-highest: var(--bg-3);
    	--bg-surface-overlay: var(--bg-4);
    	--bg-surface-raised: var(--bg-3);
    	--text-brand: var(--accent-1);
    	--text-danger: var(--red-1);
    	--text-link: var(--accent-1);
    	--text-low-contrast: var(--text-4);
    	--text-muted: var(--text-5);
    	--text-muted-on-default: var(--text-4);
    	--text-normal: var(--text-3);
    	--text-positive: var(--green-1);
    	--text-primary: var(--text-3);
    	--text-secondary: var(--text-4);
    	--text-tertiary: var(--text-4);
    	--text-warning: var(--yellow-1);
    	--text-default: var(--text-3);
    	--border-faint: var(--border-light);
    	--border-subtle: var(--border);
    	--border-normal: var(--border);
    	--border-strong: var(--border);
    	--input-border: var(--border);
    	--status-danger: var(--red-2);
    	--status-dnd: var(--dnd);
    	--status-idle: var(--idle);
    	--status-offline: var(--offline);
    	--status-online: var(--online);
    	--status-positive: var(--green-2);
    	--status-speaking: var(--green-2);
    	--status-warning: var(--yellow-2);
    	--interactive-normal: var(--text-4);
    	--interactive-hover: var(--text-3);
    	--interactive-active: var(--text-3);
    	--interactive-muted: var(--text-5);
    	--bg-brand: var(--accent-2);
    	--brand-360: var(--accent-2);
    	--brand-500: var(--accent-2);
    	--blurple-50: var(--accent-2);
    	--mention-foreground: var(--accent-1);
    	--mention-background: color-mix(in srgb, var(--accent-2), transparent 90%);
    	--input-background: var(--bg-3);
    	--channel-text-area-placeholder: var(--text-5);
    	--deprecated-text-input-bg: var(--bg-3);
    	--deprecated-text-input-border: var(--border-light);
    	--modal-background: var(--bg-4);
    	--modal-footer-background: var(--bg-4);
    	--scrollbar-auto-thumb: var(--bg-3);
    	--scrollbar-auto-track: transparent;
    	--scrollbar-thin-thumb: var(--bg-3);
    	--scrollbar-thin-track: transparent;
    	--chat-background-default: var(--bg-3);
    	--chat-text-muted: var(--text-5);
    	--white: var(--text-0);
    	--white-500: var(--text-0);
    	--background-code: var(--bg-3);
    	--card-primary-bg: var(--bg-3);
    	--card-secondary-bg: var(--bg-2);
    }
    .burstGlow__23977 {
    	display: none;
    }
    .svg_cc5dd2 > mask,.svg__44b0c > circle,.svg__44b0c > g,.svg__44b0c rect[mask*='url(#'],.avatar__20a53 .status_a423bd {
    	display: none;
    }
    .svg__44b0c > rect {
    	opacity: 0;
    }
    .mask__68edb > foreignObject,.svg__44b0c > foreignObject,.svg__2338f > foreignObject {
    	mask: none;
    }
    .wrapper__44b0c,.container__1ce5d {
    	--online-2: var(--online);
    	--dnd-2: var(--dnd);
    	--idle-2: var(--idle);
    	--offline-2: var(--offline);
    	--streaming-2: var(--streaming);
    }
    .wrapper__44b0c:has(rect)::after,.container__1ce5d:has(.status_a423bd)::after {
    	content: "";
    	display: block;
    	position: absolute;
    	height: 8px;
    	width: 8px;
    	bottom: -4px;
    	right: -4px;
    	border: 2px solid var(--background-base-lower);
    	z-index: 1;
    }
    .wrapper__44b0c:has(rect[fill='#43a25a'])::after,
    .wrapper__44b0c:has(rect[fill='rgb(67, 162, 90)'])::after,
    .container__1ce5d:has(.status_a423bd[style*='background-color: rgb(67, 162, 90)'])::after {
    	background: var(--online-2) !important;
    }
    .wrapper__44b0c:has(rect[fill='#d83a42'])::after,
    .wrapper__44b0c:has(rect[fill='#f23f43'])::after,
    .wrapper__44b0c:has(rect[fill='rgb(216, 58, 66)'])::after,
    .wrapper__44b0c:has(rect[fill='rgb(242, 63, 67)'])::after {
    	background: var(--dnd-2) !important;
    }
    .wrapper__44b0c:has(rect[fill='#ca9654'])::after,
    .wrapper__44b0c:has(rect[fill='#faa61a'])::after,
    .wrapper__44b0c:has(rect[fill='rgb(202, 150, 84)'])::after,
    .wrapper__44b0c:has(rect[fill='rgb(250, 166, 26)'])::after {
    	background: var(--idle-2) !important;
    }
    .wrapper__44b0c:has(rect[fill='#82838b'])::after,
    .wrapper__44b0c:has(rect[fill='#80848e'])::after,
    .wrapper__44b0c:has(rect[fill='rgb(130, 131, 139)'])::after,
    .wrapper__44b0c:has(rect[fill='rgb(128, 132, 142)'])::after {
    	background: var(--offline-2) !important;
    }
    .wrapper__44b0c:has(rect[fill='#9147ff'])::after,
    .wrapper__44b0c:has(rect[fill='#593695'])::after,
    .wrapper__44b0c:has(rect[fill='rgb(145, 71, 255)'])::after,
    .wrapper__44b0c:has(rect[fill='rgb(89, 54, 149)'])::after {
    	background: var(--streaming-2) !important;
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
    	content: ' __ ___ __ __\A _______ _______/ /____ ____ ___ |__ \\/ // /\A / ___/ / / / ___/ __/ _ \\/ __ `__ \\__/ / // /_\A (__ ) /_/ (__ ) /_/ __/ / / / / / __/__ __/\A/____/\\__, /____/\\__/\\___/_/ /_/ /_/____/ /_/ \A /____/ ';
    	font-size: 18px;
    	font-family: monospace;
    	white-space: pre;
    	line-height: 1.2;
    	background: linear-gradient(to right, var(--brand-360) 0%, var(--background-accent) 25%, var(--background-accent) 75%, var(--brand-360) 100%);
    	-webkit-background-clip: text;
    	-webkit-text-fill-color: transparent;
    	background-size: 200% auto;
    	animation: textShine 1.5s linear infinite reverse;
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
  '';

  # Pywal-compatible colors.json for pywalfox (raw Jinja2 template, no leading whitespace)
  pywalColorsJson = ''    {
    "wallpaper": "{{wallpaper}}",
    "alpha": "{{alpha}}",
    "special": {
    "background": "{{background}}",
    "foreground": "{{foreground}}",
    "cursor": "{{cursor}}"
    },
    "colors": {
    "color0": "{{color0}}",
    "color1": "{{color1}}",
    "color2": "{{color2}}",
    "color3": "{{color3}}",
    "color4": "{{color4}}",
    "color5": "{{color5}}",
    "color6": "{{color6}}",
    "color7": "{{color7}}",
    "color8": "{{color8}}",
    "color9": "{{color9}}",
    "color10": "{{color10}}",
    "color11": "{{color11}}",
    "color12": "{{color12}}",
    "color13": "{{color13}}",
    "color14": "{{color14}}",
    "color15": "{{color15}}"
    }
    }'';

  # Wallust config template generator
  mkWallustConfig = {extraTemplates ? ""}: ''
    backend = "fastresize"
    color_space = "lch"
    palette = "dark"
    check_contrast = true

    [templates]
    # Shared CSS variables - importable by GTK, browsers, Discord, etc.
    colors-css = { template = "colors.css", target = "~/.cache/wallust/colors.css" }

    # Pywal-compatible colors.json for pywalfox
    pywal-colors = { template = "colors.json", target = "~/.cache/wal/colors.json" }

    # Foot terminal colors (cache-only theming)
    foot-colors = { template = "foot-colors.ini", target = "~/.cache/wallust/colors_foot.ini" }

    # Zellij templates
    zellij-config = { template = "zellij-config.kdl", target = "~/.config/zellij/config.kdl" }
    zellij-layout = { template = "zellij-layout.kdl", target = "~/.config/zellij/layouts/zjstatus.kdl" }

    # Discord quickCss (Vencord + Vesktop)
    discord-vencord = { template = "discord-quickcss.css", target = "~/.config/Vencord/settings/quickCss.css" }
    discord-vesktop = { template = "discord-quickcss.css", target = "~/.config/vesktop/settings/quickCss.css" }
    ${extraTemplates}
  '';

  # Generate full zellij config.kdl template (base config + theme)
  mkZellijConfigTemplate = {zjstatusEnabled ? false}: ''
    hide_session_name false
    copy_on_select true
    show_startup_tips false
    on_force_close "quit"
    session_serialization false
    pane_frames true
    ${lib.optionalString zjstatusEnabled ''default_layout "zjstatus"''}

    // Using default keybindings for now

    ${lib.optionalString zjstatusEnabled ''
      plugins {
        zjstatus-hints location="file:~/.config/zellij/plugins/zjstatus-hints.wasm" {
          max_length 0
          pipe_name "zjstatus_hints"

          // Global defaults
          key_fg "#000000"
          key_bg "#FFFFFF"
          label_fg "#FFFFFF"
          label_bg "#333333"

          // ═══════════════════════════════════════════════════════════
          // NORMAL MODE - Mode switchers (rainbow base colors)
          // ═══════════════════════════════════════════════════════════
          pane_key_bg "#FF3355"
          pane_label_bg "#991133"
          tab_key_bg "#33FF88"
          tab_label_bg "#119944"
          resize_key_bg "#3388FF"
          resize_label_bg "#1144AA"
          move_key_bg "#FFDD33"
          move_label_bg "#AA8800"
          scroll_key_bg "#DD55FF"
          scroll_label_bg "#8822AA"
          search_key_bg "#33DDFF"
          search_label_bg "#1188AA"
          session_key_bg "#FF8833"
          session_label_bg "#AA4400"
          quit_key_bg "#FF3388"
          quit_label_bg "#AA1155"

          // ═══════════════════════════════════════════════════════════
          // PANE MODE - Red family (mode-specific with dots)
          // ═══════════════════════════════════════════════════════════
          "pane.new_key_bg" "#FF5566"
          "pane.new_label_bg" "#AA2233"
          "pane.close_key_bg" "#FF4455"
          "pane.close_label_bg" "#992233"
          fullscreen_key_bg "#FF6677"
          fullscreen_label_bg "#AA3344"
          float_key_bg "#FF7788"
          float_label_bg "#AA4455"
          embed_key_bg "#FF8899"
          embed_label_bg "#AA5566"
          split_right_key_bg "#FF99AA"
          split_right_label_bg "#AA6677"
          split_down_key_bg "#FFAABB"
          split_down_label_bg "#AA7788"
          "pane.rename_key_bg" "#FFBBCC"
          "pane.rename_label_bg" "#AA8899"
          "pane.move_key_bg" "#FF6688"
          "pane.move_label_bg" "#AA3355"
          "pane.select_key_bg" "#FF7799"
          "pane.select_label_bg" "#AA4466"

          // ═══════════════════════════════════════════════════════════
          // TAB MODE - Green family (mode-specific with dots)
          // ═══════════════════════════════════════════════════════════
          "tab.new_key_bg" "#55FF99"
          "tab.new_label_bg" "#22AA55"
          "tab.close_key_bg" "#44EE88"
          "tab.close_label_bg" "#119944"
          break_pane_key_bg "#66FFAA"
          break_pane_label_bg "#33AA66"
          sync_key_bg "#77FFBB"
          sync_label_bg "#44AA77"
          "tab.rename_key_bg" "#88FFCC"
          "tab.rename_label_bg" "#55AA88"
          "tab.move_key_bg" "#99FFDD"
          "tab.move_label_bg" "#66AA99"
          "tab.select_key_bg" "#AAFFEE"
          "tab.select_label_bg" "#77AAAA"

          // ═══════════════════════════════════════════════════════════
          // RESIZE MODE - Blue family
          // ═══════════════════════════════════════════════════════════
          // resize reuses mode switcher color
          increase_key_bg "#55AAFF"
          increase_label_bg "#2266BB"
          decrease_key_bg "#4499EE"
          decrease_label_bg "#1155AA"

          // ═══════════════════════════════════════════════════════════
          // SCROLL MODE - Magenta family
          // ═══════════════════════════════════════════════════════════
          // scroll, search reuse mode switcher colors
          page_key_bg "#EE66FF"
          page_label_bg "#9933AA"
          half_page_key_bg "#DD77FF"
          half_page_label_bg "#8844AA"
          edit_key_bg "#CC88FF"
          edit_label_bg "#7755AA"

          // ═══════════════════════════════════════════════════════════
          // SEARCH MODE - Cyan family
          // ═══════════════════════════════════════════════════════════
          // search, scroll, page, half page reuse colors
          down_key_bg "#44EEFF"
          down_label_bg "#2299AA"
          up_key_bg "#55FFFF"
          up_label_bg "#33AAAA"

          // ═══════════════════════════════════════════════════════════
          // SESSION MODE - Orange family
          // ═══════════════════════════════════════════════════════════
          detach_key_bg "#FF9944"
          detach_label_bg "#AA5500"
          manager_key_bg "#FFAA55"
          manager_label_bg "#AA6611"
          config_key_bg "#FFBB66"
          config_label_bg "#AA7722"
          plugins_key_bg "#FFCC77"
          plugins_label_bg "#AA8833"
          about_key_bg "#FFDD88"
          about_label_bg "#AA9944"

          // ═══════════════════════════════════════════════════════════
          // SHARED - Used across multiple modes
          // ═══════════════════════════════════════════════════════════
          select_key_bg "#AAAAAA"
          select_label_bg "#555555"
          normal_key_bg "#888888"
          normal_label_bg "#444444"
        }
      }

      load_plugins {
        zjstatus-hints
      }
    ''}

    ${zellijTheme}
  '';

  # zjstatus layout with dynamic colors in hints bar
  zjstatusLayout = ''
    layout {
      default_tab_template {
        pane size=1 borderless=true {
          plugin location="https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm" {
            format_left   ""
            format_center "#[bg=yellow,fg=black,bold] {session} #[bg=reset,fg=reset] {mode} {tabs} #[bg=cyan,fg=black,bold] {datetime}"
            format_right  ""
            format_space  ""

            session "{name}"
            format_hide_on_overlength "true"
            format_precedence "lrc"

            border_enabled  "false"
            hide_frame_for_single_pane "false"

            // Mode badges
            mode_normal        "#[bg=blue,fg=black,bold] NORMAL "
            mode_locked        "#[bg=red,fg=white,bold] LOCKED "
            mode_resize        "#[bg=yellow,fg=black,bold] RESIZE "
            mode_pane          "#[bg=green,fg=black,bold] PANE "
            mode_tab           "#[bg=yellow,fg=black,bold] TAB "
            mode_scroll        "#[bg=magenta,fg=white,bold] SCROLL "
            mode_enter_search  "#[bg=magenta,fg=white,bold] SEARCH "
            mode_search        "#[bg=magenta,fg=white,bold] SEARCH "
            mode_rename_tab    "#[bg=yellow,fg=black,bold] RENAME "
            mode_rename_pane   "#[bg=green,fg=black,bold] RENAME "
            mode_session       "#[bg=magenta,fg=white,bold] SESSION "
            mode_move          "#[bg=yellow,fg=black,bold] MOVE "
            mode_prompt        "#[bg=magenta,fg=white,bold] PROMPT "
            mode_tmux          "#[bg=red,fg=white,bold] TMUX "

            // Tabs
            tab_normal              "#[bg=bright_black,fg=black] {name} {floating_indicator}"
            tab_normal_fullscreen   "#[bg=bright_black,fg=black] {name} [] {floating_indicator}"
            tab_normal_sync         "#[bg=bright_black,fg=black] {name} <> {floating_indicator}"
            tab_active              "#[bg=cyan,fg=black,bold] {name} {floating_indicator}"
            tab_active_fullscreen   "#[bg=cyan,fg=black,bold] {name} [] {floating_indicator}"
            tab_active_sync         "#[bg=cyan,fg=black,bold] {name} <> {floating_indicator}"
            tab_floating_indicator  "⬚ "

            datetime          "#[bg=cyan,fg=black,bold] {format} "
            datetime_format   "%d/%m/%y %H:%M:%S"
            datetime_timezone "Canada/Toronto"
          }
        }
        children
        pane size=1 borderless=true {
          plugin location="https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm" {
            format_left   ""
            format_center "{pipe_zjstatus_hints}"
            format_right  ""
            format_space  ""

            border_enabled  "false"
            hide_frame_for_single_pane "false"

            pipe_zjstatus_hints_format "{output}"
            pipe_zjstatus_hints_rendermode "raw"
          }
        }
      }
    }
  '';

  # Zellij theme with dynamic RGB colors
  zellijTheme = ''
        themes {
          wallust {
            text_unselected {
              base {{ color7 | red }} {{ color7 | green }} {{ color7 | blue }}
              background {{ background | red }} {{ background | green }} {{ background | blue }}
              emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
              emphasis_1 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
              emphasis_2 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
              emphasis_3 {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
            }
            text_selected {
              base {{ color15 | red }} {{ color15 | green }} {{ color15 | blue }}
              background {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
              emphasis_0 {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
              emphasis_1 {{ color11 | red }} {{ color11 | green }} {{ color11 | blue }}
              emphasis_2 {{ color13 | red }} {{ color13 | green }} {{ color13 | blue }}
              emphasis_3 {{ color12 | red }} {{ color12 | green }} {{ color12 | blue }}
            }
            ribbon_unselected {
              base {{ color0 | red }} {{ color0 | green }} {{ color0 | blue }}
              background {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
              emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
              emphasis_1 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
              emphasis_2 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
              emphasis_3 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
            }
            ribbon_selected {
              base {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
              background {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
              emphasis_0 {{ color11 | red }} {{ color11 | green }} {{ color11 | blue }}
              emphasis_1 {{ color13 | red }} {{ color13 | green }} {{ color13 | blue }}
              emphasis_2 {{ color12 | red }} {{ color12 | green }} {{ color12 | blue }}
              emphasis_3 {{ color14 | red }} {{ color14 | green }} {{ color14 | blue }}
            }
            table_title {
              base {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
              background {{ background | red }} {{ background | green }} {{ background | blue }}
              emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
              emphasis_1 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
              emphasis_2 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
              emphasis_3 {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
            }
            table_cell_unselected {
              base {{ color7 | red }} {{ color7 | green }} {{ color7 | blue }}
              background {{ background | red }} {{ background | green }} {{ background | blue }}
              emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
              emphasis_1 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
              emphasis_2 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
              emphasis_3 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
            }
            table_cell_selected {
              base {{ color15 | red }} {{ color15 | green }} {{ color15 | blue }}
              background {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
              emphasis_0 {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
              emphasis_1 {{ color11 | red }} {{ color11 | green }} {{ color11 | blue }}
              emphasis_2 {{ color13 | red }} {{ color13 | green }} {{ color13 | blue }}
              emphasis_3 {{ color12 | red }} {{ color12 | green }} {{ color12 | blue }}
            }
            list_unselected {
              base {{ color7 | red }} {{ color7 | green }} {{ color7 | blue }}
              background {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
              emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
              emphasis_1 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
              emphasis_2 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
              emphasis_3 {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
            }
            list_selected {
              base {{ color15 | red }} {{ color15 | green }} {{ color15 | blue }}
              background {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
              emphasis_0 {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
              emphasis_1 {{ color11 | red }} {{ color11 | green }} {{ color11 | blue }}
              emphasis_2 {{ color13 | red }} {{ color13 | green }} {{ color13 | blue }}
              emphasis_3 {{ color12 | red }} {{ color12 | green }} {{ color12 | blue }}
            }
            frame_selected {
              {% if "golden" in wallpaper %}
              base {{ color11 | red }} {{ color11 | green }} {{ color11 | blue }}
              {% elif "dopamine" in wallpaper %}
              base {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
              {% elif "sunset-red" in wallpaper %}
              base {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
              {% else %}
              base {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
              {% endif %}
              background {{ background | red }} {{ background | green }} {{ background | blue }}
              emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
              emphasis_1 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
              emphasis_2 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
              emphasis_3 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
            }
            frame_highlight {
              base {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
              background {{ background | red }} {{ background | green }} {{ background | blue }}
              emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
              emphasis_1 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
              emphasis_2 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
              emphasis_3 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
            }
            frame_unselected {
              base {{ color7 | red }} {{ color7 | green }} {{ color7 | blue }}
              background {{ background | red }} {{ background | green }} {{ background | blue }}
              emphasis_0 {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
              emphasis_1 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
              emphasis_2 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
              emphasis_3 {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
            }
            exit_code_success {
              base {{ color2 | red }} {{ color2 | green }} {{ color2 | blue }}
              background {{ background | red }} {{ background | green }} {{ background | blue }}
              emphasis_0 {{ color10 | red }} {{ color10 | green }} {{ color10 | blue }}
              emphasis_1 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
              emphasis_2 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
              emphasis_3 {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
            }
            exit_code_error {
              base {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
              background {{ background | red }} {{ background | green }} {{ background | blue }}
              emphasis_0 {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
              emphasis_1 {{ color7 | red }} {{ color7 | green }} {{ color7 | blue }}
              emphasis_2 {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
              emphasis_3 {{ color0 | red }} {{ color0 | green }} {{ color0 | blue }}
            }
          }
        }
        ui {
          pane_frames {
            rounded_corners false
            hide_session_name false
          }
        }
        theme "wallust"
  '';
}
