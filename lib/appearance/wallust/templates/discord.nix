# Discord/Vesktop quickCss template
''
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
  	--base-gray: oklch(54% 0 0);
  	--base-red: oklch(70% 0.13 0);
  	--base-green: oklch(70% 0.12 170);
  	--base-blue: oklch(70% 0.11 215);
  	--base-yellow: oklch(75% 0.12 90);
  	--base-purple: oklch(70% 0.12 310);

  	--text-0: oklch(from var(--base-gray) calc(l + 0.45) c h);
  	--text-1: oklch(from var(--base-gray) calc(l + 0.41) c h);
  	--text-2: oklch(from var(--base-gray) calc(l + 0.31) c h);
  	--text-3: oklch(from var(--base-gray) calc(l + 0.21) c h);
  	--text-4: oklch(from var(--base-gray) calc(l + 0.06) c h);
  	--text-5: oklch(from var(--base-gray) calc(l - 0.14) c h);

  	--bg-1: oklch(from var(--base-gray) calc(l - 0.23) c h);
  	--bg-2: oklch(from var(--base-gray) calc(l - 0.27) c h);
  	--bg-3: oklch(from var(--base-gray) calc(l - 0.31) c h);
  	--bg-4: oklch(0% 0 0);

  	--hover: oklch(from var(--base-gray) l c h / 0.1);
  	--active: oklch(from var(--base-gray) l c h / 0.2);
  	--active-2: oklch(from var(--base-gray) l c h / 0.3);
  	--message-hover: var(--hover);

  	--red-1: oklch(from var(--base-red) calc(l + 0.05) c h);
  	--red-2: var(--base-red);
  	--red-3: oklch(from var(--base-red) calc(l - 0.05) c h);
  	--red-4: oklch(from var(--base-red) calc(l - 0.10) c h);
  	--red-5: oklch(from var(--base-red) calc(l - 0.15) c h);

  	--green-1: oklch(from var(--base-green) calc(l + 0.05) c h);
  	--green-2: var(--base-green);
  	--green-3: oklch(from var(--base-green) calc(l - 0.05) c h);
  	--green-4: oklch(from var(--base-green) calc(l - 0.10) c h);
  	--green-5: oklch(from var(--base-green) calc(l - 0.15) c h);

  	--blue-1: oklch(from var(--base-blue) calc(l + 0.05) c h);
  	--blue-2: var(--base-blue);
  	--blue-3: oklch(from var(--base-blue) calc(l - 0.05) c h);
  	--blue-4: oklch(from var(--base-blue) calc(l - 0.10) c h);
  	--blue-5: oklch(from var(--base-blue) calc(l - 0.15) c h);

  	--yellow-1: oklch(from var(--base-yellow) calc(l + 0.05) c h);
  	--yellow-2: var(--base-yellow);
  	--yellow-3: oklch(from var(--base-yellow) calc(l - 0.05) c h);
  	--yellow-4: oklch(from var(--base-yellow) calc(l - 0.10) c h);
  	--yellow-5: oklch(from var(--base-yellow) calc(l - 0.15) c h);

  	--purple-1: oklch(from var(--base-purple) calc(l + 0.05) c h);
  	--purple-2: var(--base-purple);
  	--purple-3: oklch(from var(--base-purple) calc(l - 0.05) c h);
  	--purple-4: oklch(from var(--base-purple) calc(l - 0.10) c h);
  	--purple-5: oklch(from var(--base-purple) calc(l - 0.15) c h);

  	--accent-1: var(--purple-1);
  	--accent-2: var(--purple-2);
  	--accent-3: var(--purple-3);
  	--accent-4: var(--purple-4);
  	--accent-5: var(--purple-5);
  	--accent-new: var(--red-2);

  	--online: var(--green-2);
  	--dnd: var(--red-2);
  	--idle: var(--yellow-2);
  	--streaming: var(--purple-2);
  	--offline: var(--text-4);

  	--border-light: var(--text-5);
  	--border: var(--text-5);
  	--border-hover: var(--purple-2);
  	--button-border: oklch(from var(--text-1) l c h / 0.1);

  	--mention: linear-gradient(to right, color-mix(in hsl, var(--accent-2), transparent 90%) 40%, transparent);
  	--mention-hover: linear-gradient(to right, color-mix(in hsl, var(--accent-2), transparent 95%) 40%, transparent);
  	--reply: linear-gradient(to right, color-mix(in hsl, var(--text-3), transparent 90%) 40%, transparent);
  	--reply-hover: linear-gradient(to right, color-mix(in hsl, var(--text-3), transparent 95%) 40%, transparent);
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
  	--mention-background: color-mix(in hsl, var(--accent-2), transparent 90%);
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
''
