# MinimalImprovement - Extremely compact Discord theme
''
  /**
   * @name MinimalImprovement-Wallust
   * @description Extremely compact Discord theme - fixed sizes, no frills
   * @version 3.0.0
   */

  /* ============================================
     VARIABLES - rem-based for scalability
     ============================================ */
  :root {
    --mi-server-width: 2.5rem;
    --mi-sidebar-width: 10rem;
    --mi-members-width: 8.5rem;
    --mi-header-height: 1.75rem;
    --mi-row-height: 1.5rem;
    --mi-avatar: 1.5rem;
    --mi-icon: 1rem;
    --mi-gap: 0.125rem;
    --mi-pad: 0.25rem;

    /* Wallust colors */
    --mi-bg: {{background}};
    --mi-bg2: {{color0}};
    --mi-fg: {{foreground}};
    --mi-fg2: {{color7}};
    --mi-muted: {{color8}};
    --mi-accent: {{color5}};
    --mi-border: {{color8}};
  }

  /* ============================================
     GLOBAL
     ============================================ */
  * { border-radius: 0 !important; }

  /* ============================================
     SERVER LIST
     ============================================ */
  [class*="guilds_"] {
    width: var(--mi-server-width) !important;
  }

  [class*="guilds_"] [class*="listItem_"] {
    width: var(--mi-server-width) !important;
    height: 2.25rem !important;
  }

  [class*="guilds_"] svg[width="48"] {
    width: 2rem !important;
    height: 2rem !important;
  }

  [class*="guilds_"] [class*="wrapper_"] {
    width: 2rem !important;
    height: 2rem !important;
  }

  [class*="guilds_"] [class*="expandedFolderBackground_"] {
    width: 2.125rem !important;
  }

  [class*="numberBadge_"] {
    min-width: 0.875rem !important;
    height: 0.875rem !important;
    font-size: 0.625rem !important;
  }

  /* ============================================
     CHANNEL SIDEBAR
     ============================================ */
  [class*="sidebar_"]:not([class*="sidebarRegion"]) {
    width: var(--mi-sidebar-width) !important;
  }

  [class*="privateChannels_"] {
    width: var(--mi-sidebar-width) !important;
  }

  /* Channel rows */
  [class*="link_"][class*="channel"],
  [class*="wrapper_"][class*="channel"],
  [class*="containerDefault_"] {
    height: var(--mi-row-height) !important;
    padding: var(--mi-gap) var(--mi-pad) !important;
  }

  /* Category headers */
  [class*="containerDefault_"][class*="clickable"] h2,
  [class*="name_"][class*="container"] {
    font-size: 0.625rem !important;
  }

  /* Channel icons */
  [class*="iconContainer_"] {
    width: var(--mi-icon) !important;
    height: var(--mi-icon) !important;
    margin-right: var(--mi-gap) !important;
  }

  /* Unread pill */
  [class*="unread_"][class*="item"] {
    width: 0.1875rem !important;
  }

  /* ============================================
     MEMBER LIST
     ============================================ */
  [class*="membersWrap_"],
  [class*="members_"]:not([class*="Group"]) {
    width: var(--mi-members-width) !important;
    min-width: unset !important;
  }

  [class*="member_"][class*="container"],
  [class*="member_"][class*="layout"] {
    height: var(--mi-row-height) !important;
    padding: var(--mi-gap) var(--mi-pad) !important;
  }

  [class*="member_"] [class*="avatar_"] {
    width: 1.25rem !important;
    height: 1.25rem !important;
  }

  [class*="membersGroup_"] {
    height: 1.25rem !important;
    font-size: 0.625rem !important;
    padding: var(--mi-gap) var(--mi-pad) !important;
  }

  /* ============================================
     HEADER
     ============================================ */
  [class*="title_"][class*="container"],
  [class*="container_"][class*="title"],
  [class*="subtitleContainer_"],
  header[class*="container_"] {
    height: var(--mi-header-height) !important;
    min-height: var(--mi-header-height) !important;
  }

  [class*="toolbar_"] button,
  [class*="toolbar_"] [class*="iconWrapper_"] {
    width: 1.5rem !important;
    height: 1.5rem !important;
  }

  /* ============================================
     MESSAGES
     ============================================ */
  [class*="cozy_"][class*="wrapper_"],
  [class*="message_"][class*="cozy"] {
    padding: var(--mi-gap) var(--mi-pad) var(--mi-gap) calc(var(--mi-avatar) + 0.5rem) !important;
    min-height: unset !important;
  }

  [class*="cozy_"] [class*="avatar_"],
  [class*="message_"] [class*="avatar_"] {
    width: var(--mi-avatar) !important;
    height: var(--mi-avatar) !important;
    top: var(--mi-gap) !important;
    left: var(--mi-pad) !important;
  }

  [class*="messageContent_"],
  [class*="markup_"] {
    font-size: 0.8125rem !important;
    line-height: 1.2 !important;
  }

  [class*="timestamp_"] {
    font-size: 0.625rem !important;
  }

  [class*="reactions_"] {
    margin-top: var(--mi-gap) !important;
  }

  [class*="reaction_"] {
    height: 1.25rem !important;
    padding: 0 0.25rem !important;
    font-size: 0.75rem !important;
  }

  [class*="buttons_"][class*="container"] {
    top: -0.25rem !important;
  }

  [class*="buttonContainer_"] button {
    height: 1.5rem !important;
    width: 1.5rem !important;
  }

  [class*="divider_"] {
    margin: var(--mi-gap) 0 !important;
  }

  /* ============================================
     COMPOSER
     ============================================ */
  [class*="channelTextArea_"],
  [class*="form_"][class*="chat"] {
    margin: var(--mi-gap) var(--mi-pad) var(--mi-pad) !important;
    padding: 0 !important;
  }

  [class*="scrollableContainer_"][class*="inner"] {
    min-height: 1.75rem !important;
    padding: var(--mi-gap) var(--mi-pad) !important;
  }

  [class*="attachButton_"],
  [class*="emojiButton_"],
  [class*="stickerButton_"] {
    width: 1.5rem !important;
    height: 1.5rem !important;
  }

  /* ============================================
     NOW PLAYING / ACTIVITY - fixed width
     ============================================ */
  [class*="nowPlayingColumn_"] {
    width: var(--mi-members-width) !important;
    min-width: unset !important;
  }

  /* ============================================
     PANELS (bottom user area)
     ============================================ */
  [class*="panels_"] {
    height: 2.75rem !important;
  }

  [class*="panels_"] [class*="container_"] {
    padding: var(--mi-gap) var(--mi-pad) !important;
  }

  [class*="panels_"] [class*="avatar_"] {
    width: 1.75rem !important;
    height: 1.75rem !important;
  }

  /* ============================================
     SETTINGS
     ============================================ */
  [class*="sidebarRegion_"] {
    width: 10rem !important;
    flex: 0 0 10rem !important;
  }

  [class*="contentColumn_"],
  [class*="contentRegion_"] {
    max-width: 100% !important;
  }

  [class*="item_"][class*="side"] {
    height: var(--mi-row-height) !important;
    padding: var(--mi-gap) var(--mi-pad) !important;
    font-size: 0.8125rem !important;
  }

  /* ============================================
     MENUS & TOOLTIPS
     ============================================ */
  [role="menu"] {
    padding: var(--mi-gap) !important;
  }

  [role="menuitem"] {
    height: var(--mi-row-height) !important;
    padding: var(--mi-gap) var(--mi-pad) !important;
    font-size: 0.8125rem !important;
  }

  [class*="tooltip_"] {
    padding: var(--mi-gap) var(--mi-pad) !important;
    font-size: 0.75rem !important;
  }

  /* ============================================
     VOICE
     ============================================ */
  [class*="voiceUser_"] {
    height: var(--mi-row-height) !important;
    padding: var(--mi-gap) var(--mi-pad) !important;
  }

  [class*="voiceUser_"] [class*="avatar_"] {
    width: 1.25rem !important;
    height: 1.25rem !important;
  }

  /* ============================================
     SEARCH / THREADS / INBOX
     ============================================ */
  [class*="searchResultsWrap_"] {
    width: 22.5rem !important;
  }

  [class*="sidebar_"][class*="thread"] {
    width: 17.5rem !important;
  }

  /* ============================================
     EMBEDS
     ============================================ */
  [class*="embedWrapper_"] {
    padding: var(--mi-pad) !important;
    margin-top: var(--mi-gap) !important;
  }

  /* ============================================
     COLORS
     ============================================ */
  body, .theme-dark, .theme-light {
    --background-primary: var(--mi-bg) !important;
    --background-secondary: var(--mi-bg2) !important;
    --background-secondary-alt: var(--mi-bg2) !important;
    --background-tertiary: var(--mi-bg) !important;
    --background-floating: var(--mi-bg2) !important;
    --text-normal: var(--mi-fg) !important;
    --text-muted: var(--mi-muted) !important;
    --header-primary: var(--mi-fg) !important;
    --header-secondary: var(--mi-fg2) !important;
    --interactive-normal: var(--mi-fg2) !important;
    --interactive-hover: var(--mi-fg) !important;
    --brand-experiment: var(--mi-accent) !important;
  }

  /* ============================================
     BORDERS
     ============================================ */
  [class*="sidebar_"],
  [class*="membersWrap_"],
  [class*="panels_"] {
    border: 1px solid var(--mi-border) !important;
  }
''
