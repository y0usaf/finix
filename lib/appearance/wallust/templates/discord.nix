# Discord/Vesktop quickCss template
''
  @import url("https://raw.codeberg.page/AllPurposeMat/Disblock-Origin/DisblockOrigin.theme.css");

  /* Global resets */
  *, *::before, *::after {
  	border-radius: 0 !important;
  }

  /* Remove avatar/profile picture circular masks */
  [class*="mask__"] > foreignObject,
  [class*="svg__"] > foreignObject,
  [class*="avatar"] foreignObject {
  	mask: none !important;
  	clip-path: none !important;
  }
  [class*="svg_"] > mask,
  [class*="svg__"] > circle,
  [class*="svg__"] > g,
  [class*="svg__"] rect[mask] {
  	display: none !important;
  }
  [class*="wrapper__"] svg,
  [class*="avatar"] svg {
  	clip-path: none !important;
  	mask: none !important;
  }
  img[class*="avatar"] {
  	clip-path: none !important;
  	border-radius: 0 !important;
  }

  /* Hide Visual Refresh titlebar */
  .visual-refresh {
  	--custom-app-top-bar-height: 0 !important;
  }
  [class*="titleBar"], [class*="bar_c38106"], [class*="base__5e434"] > [class*="bar_"] {
  	display: none !important;
  }
  [class*="itemsContainer_ef3116"], [data-list-id="guildsnav"] > [class*="itemsContainer"] {
  	margin-top: 8px !important;
  }

  /* Monospace font override */
  body {
  	--font: monospace !important;
  	--code-font: monospace !important;
  	--font-primary: var(--font), 'gg sans' !important;
  	--font-display: var(--font), 'gg sans' !important;
  	--font-code: var(--code-font), 'gg mono' !important;
  }

  /* Wallust color palette */
  :root {
  	--base-red: {{color1}} !important;
  	--base-green: {{color2}} !important;
  	--base-blue: {{color4}} !important;
  	--base-yellow: {{color3}} !important;
  	--base-purple: {{color5}} !important;

  	--text-0: {{foreground}} !important;
  	--text-1: {{color15}} !important;
  	--text-2: {{color7}} !important;
  	--text-3: {{color7}} !important;
  	--text-4: {{color7}} !important;
  	--text-5: {{cursor}} !important;

  	--bg-1: {{color0}} !important;
  	--bg-2: {{color0}} !important;
  	--bg-3: {{color0}} !important;
  	--bg-4: {{background}} !important;

  	--hover: color-mix(in srgb, {{color8}} 10%, transparent) !important;
  	--active: color-mix(in srgb, {{color8}} 20%, transparent) !important;
  	--active-2: color-mix(in srgb, {{color8}} 30%, transparent) !important;
  	--message-hover: var(--hover) !important;

  	--red-1: {{color9}} !important;
  	--red-2: {{color1}} !important;
  	--red-3: {{color1}} !important;
  	--red-4: {{color1}} !important;
  	--red-5: {{color1}} !important;

  	--green-1: {{color10}} !important;
  	--green-2: {{color2}} !important;
  	--green-3: {{color2}} !important;
  	--green-4: {{color2}} !important;
  	--green-5: {{color2}} !important;

  	--blue-1: {{color12}} !important;
  	--blue-2: {{color4}} !important;
  	--blue-3: {{color4}} !important;
  	--blue-4: {{color4}} !important;
  	--blue-5: {{color4}} !important;

  	--yellow-1: {{color11}} !important;
  	--yellow-2: {{color3}} !important;
  	--yellow-3: {{color3}} !important;
  	--yellow-4: {{color3}} !important;
  	--yellow-5: {{color3}} !important;

  	--purple-1: {{color13}} !important;
  	--purple-2: {{color5}} !important;
  	--purple-3: {{color5}} !important;
  	--purple-4: {{color5}} !important;
  	--purple-5: {{color5}} !important;

  	--accent-1: var(--purple-1) !important;
  	--accent-2: var(--purple-2) !important;
  	--accent-3: var(--purple-3) !important;
  	--accent-4: var(--purple-4) !important;
  	--accent-5: var(--purple-5) !important;
  	--accent-new: var(--red-2) !important;

  	--online: var(--green-2) !important;
  	--dnd: var(--red-2) !important;
  	--idle: var(--yellow-2) !important;
  	--streaming: var(--purple-2) !important;
  	--offline: var(--text-4) !important;

  	--border-light: var(--text-5) !important;
  	--border: var(--text-5) !important;
  	--border-hover: var(--purple-2) !important;
  	--button-border: color-mix(in srgb, {{foreground}} 10%, transparent) !important;

  	--mention: linear-gradient(to right, color-mix(in srgb, var(--accent-2) 10%, transparent) 40%, transparent) !important;
  	--mention-hover: linear-gradient(to right, color-mix(in srgb, var(--accent-2) 5%, transparent) 40%, transparent) !important;
  	--reply: linear-gradient(to right, color-mix(in srgb, var(--text-3) 10%, transparent) 40%, transparent) !important;
  	--reply-hover: linear-gradient(to right, color-mix(in srgb, var(--text-3) 5%, transparent) 40%, transparent) !important;
  }

  /* Discord CSS variable mappings */
  body, .theme-dark:not(.custom-user-profile-theme), .theme-light:not(.custom-user-profile-theme) {
  	--activity-card-background: var(--bg-3) !important;
  	--background-accent: var(--bg-2) !important;
  	--background-floating: var(--bg-3) !important;
  	--background-nested-floating: var(--bg-4) !important;
  	--background-mentioned: var(--mention) !important;
  	--background-mentioned-hover: var(--mention-hover) !important;
  	--background-message-highlight: var(--reply) !important;
  	--background-message-highlight-hover: var(--reply-hover) !important;
  	--background-message-hover: var(--message-hover) !important;
  	--background-primary: var(--bg-4) !important;
  	--background-secondary: var(--bg-3) !important;
  	--background-secondary-alt: var(--bg-3) !important;
  	--background-tertiary: var(--bg-4) !important;
  	--bg-base-primary: var(--bg-4) !important;
  	--bg-base-secondary: var(--bg-4) !important;
  	--bg-base-tertiary: var(--bg-3) !important;
  	--background-base-low: var(--bg-4) !important;
  	--background-base-lower: var(--bg-4) !important;
  	--background-base-lowest: var(--bg-4) !important;
  	--background-mod-subtle: var(--hover) !important;
  	--background-mod-normal: var(--active) !important;
  	--background-mod-strong: var(--active-2) !important;
  	--background-modifier-accent: var(--hover) !important;
  	--background-modifier-active: var(--active) !important;
  	--background-modifier-hover: var(--hover) !important;
  	--background-modifier-selected: var(--active) !important;
  	--background-surface-high: var(--bg-3) !important;
  	--background-surface-higher: var(--bg-3) !important;
  	--background-surface-highest: var(--bg-3) !important;
  	--bg-surface-overlay: var(--bg-4) !important;
  	--bg-surface-raised: var(--bg-3) !important;
  	--text-brand: var(--accent-1) !important;
  	--text-danger: var(--red-1) !important;
  	--text-link: var(--accent-1) !important;
  	--text-low-contrast: var(--text-4) !important;
  	--text-muted: var(--text-5) !important;
  	--text-muted-on-default: var(--text-4) !important;
  	--text-normal: var(--text-3) !important;
  	--text-positive: var(--green-1) !important;
  	--text-primary: var(--text-3) !important;
  	--text-secondary: var(--text-4) !important;
  	--text-tertiary: var(--text-4) !important;
  	--text-warning: var(--yellow-1) !important;
  	--text-default: var(--text-3) !important;
  	--border-faint: var(--border-light) !important;
  	--border-subtle: var(--border) !important;
  	--border-normal: var(--border) !important;
  	--border-strong: var(--border) !important;
  	--input-border: var(--border) !important;
  	--status-danger: var(--red-2) !important;
  	--status-dnd: var(--dnd) !important;
  	--status-idle: var(--idle) !important;
  	--status-offline: var(--offline) !important;
  	--status-online: var(--online) !important;
  	--status-positive: var(--green-2) !important;
  	--status-speaking: var(--green-2) !important;
  	--status-warning: var(--yellow-2) !important;
  	--interactive-normal: var(--text-4) !important;
  	--interactive-hover: var(--text-3) !important;
  	--interactive-active: var(--text-3) !important;
  	--interactive-muted: var(--text-5) !important;
  	--bg-brand: var(--accent-2) !important;
  	--brand-360: var(--accent-2) !important;
  	--brand-500: var(--accent-2) !important;
  	--blurple-50: var(--accent-2) !important;
  	--mention-foreground: var(--accent-1) !important;
  	--mention-background: color-mix(in hsl, var(--accent-2), transparent 90%) !important;
  	--input-background: var(--bg-3) !important;
  	--channel-text-area-placeholder: var(--text-5) !important;
  	--deprecated-text-input-bg: var(--bg-3) !important;
  	--deprecated-text-input-border: var(--border-light) !important;
  	--modal-background: var(--bg-4) !important;
  	--modal-footer-background: var(--bg-4) !important;
  	--scrollbar-auto-thumb: var(--bg-3) !important;
  	--scrollbar-auto-track: transparent !important;
  	--scrollbar-thin-thumb: var(--bg-3) !important;
  	--scrollbar-thin-track: transparent !important;
  	--chat-background-default: var(--bg-3) !important;
  	--chat-text-muted: var(--text-5) !important;
  	--white: var(--text-0) !important;
  	--white-500: var(--text-0) !important;
  	--background-code: var(--bg-3) !important;
  	--card-primary-bg: var(--bg-3) !important;
  	--card-secondary-bg: var(--bg-2) !important;
  }
''
