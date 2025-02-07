{
  config,
  lib,
  pkgs,
  profile,
  ...
}: let
  # Function to read directory contents
  readDir = path: builtins.readDir path;

  # Function to get profile directories
  getProfiles = profilesPath: let
    contents = readDir profilesPath;
    # Filter directories that end with .default or .default-release
    isProfile = name: value:
      value
      == "directory"
      && (lib.hasSuffix ".default" name || lib.hasSuffix ".default-release" name);
    profiles = lib.filterAttrs isProfile contents;
  in
    builtins.attrNames profiles;

  # Common settings and CSS for all profiles
  commonSettings = {
    # Enable userChrome customizations
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    
    # Enable Browser Toolbox and development features
    "devtools.chrome.enabled" = true;
    "devtools.debugger.remote-enabled" = true;
    "devtools.debugger.prompt-connection" = false;
    "browser.enabledE10S" = false;
    
    # Theme and UI settings
    "browser.tabs.drawInTitlebar" = true;
    "browser.chrome.toolbar_style" = 1;
    "browser.theme.dark-private-windows" = false;
    "browser.theme.toolbar-theme" = 0;
    
    # Development settings
    "dom.webcomponents.enabled" = true;
    "layout.css.shadow-parts.enabled" = true;
  };

  userChromeCss = ''
    /*--------------------------------------------------------------------------------------------------*
     *     CASCADE THEME (Mouse Edition) Revised for In-line One-liner Layout (No hidden bars)         *
     *--------------------------------------------------------------------------------------------------*/

    /*---------------------------------------------------------------------*
     |                   Root Variables (Cascade defaults)                 |
     *---------------------------------------------------------------------*/
    :root {
      /* Dark Theme Colours */
      --window-colour:           #1f2122;
      --secondary-colour:        #141616;
      --inverted-colour:         #FAFAFC;

      /* Container Tab Colours */
      --uc-identity-color-blue:      #7ED6DF;
      --uc-identity-color-turquoise: #55E6C1;
      --uc-identity-color-green:     #B8E994;
      --uc-identity-color-yellow:    #F7D794;
      --uc-identity-color-orange:    #F19066;
      --uc-identity-color-red:       #FC5C65;
      --uc-identity-color-pink:      #F78FB3;
      --uc-identity-color-purple:    #786FA6;
        
      /* URL suggestions highlight */
      --urlbar-popup-url-color: var(--uc-identity-color-purple) !important;
         
      /* Layout and sizing */
      --uc-border-radius: 0;
      --uc-urlbar-width: clamp(250px, 50vw, 600px);
      --uc-active-tab-width: clamp(50px, 18vw, 220px);
      --uc-inactive-tab-width: clamp(50px, 15vw, 200px);

      --show-tab-close-button: none;
      --show-tab-close-button-hover: -moz-inline-box;
      --container-tabs-indicator-margin: 0px;

      --tab-font-size: 0.8em;
      --tab-font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      --tab-height: 1rem;
      --navbar-bg-color: var(--window-colour);
      --navbar-min-width: 1000px;
      --navbar-max-width: 2000px;

      --uc-theme-colour: var(--window-colour);
      --uc-hover-colour: var(--secondary-colour);
      --uc-inverted-colour: var(--inverted-colour);

      /* Additional variable for Cascade's one-liner layout */
      --urlbar-min-height: 2rem;
    }

    /*---------------------------------------------------------------------*
     |                          Global Resets                              |
     *---------------------------------------------------------------------*/
    * {
      animation: none !important;
      transition: none !important;
    }

    /*---------------------------------------------------------------------*
     |                    Tabs & Minimalism Settings                       |
     *---------------------------------------------------------------------*/
    .tabbrowser-tab * {
      margin: 0 !important;
      border-radius: 0 !important;
      font-family: var(--tab-font-family) !important;
    }
    .tabbrowser-tab {
      height: var(--tab-height) !important;
      font-size: var(--tab-font-size) !important;
      min-height: 0 !important;
      align-items: center !important;
      margin-bottom: 5px !important;
    }
    .tab-icon-image,
    .tab-icon-sound,
    .tab-close-button {
      height: calc(var(--tab-height) * 0.8) !important;
      width: calc(var(--tab-height) * 0.8) !important;
      padding: 2px !important;
    }

    /*---------------------------------------------------------------------*
     |            Navigation & Toolbar Layout (Cascade Style)              |
     *---------------------------------------------------------------------*/
    #TabsToolbar,
    #nav-bar {
      background: var(--navbar-bg-color) !important;
      height: var(--tab-height) !important;
      width: var(--navbar-min-width) !important;
      position: relative !important;
    }
    @media (min-width: 2000px) {
      #TabsToolbar,
      #nav-bar {
        margin-left: calc((100vw - var(--navbar-min-width)) / 2) !important;
        width: var(--navbar-min-width) !important;
      }
    }
    @media (min-width: 1000px) and (max-width: 1999px) {
      #TabsToolbar,
      #nav-bar {
        margin-left: calc((100vw - var(--navbar-min-width)) / 2) !important;
        width: calc(100vw - (100vw - var(--navbar-min-width))) !important;
      }
    }
    @media (max-width: 999px) {
      #TabsToolbar,
      #nav-bar {
        margin-left: 0 !important;
        width: 100vw !important;
      }
    }
    /* Cascade One-liner Layout Adjustments */
    @media (min-width: 1000px) { 
      /* move tabs bar to make room for the URL bar */
      #TabsToolbar { margin-left: var(--uc-urlbar-width) !important; }
      /* position the nav bar inline (instead of hiding it) */
      #nav-bar { margin: calc((var(--urlbar-min-height) * -1) - 8px)
                        calc(100vw - var(--uc-urlbar-width)) 0 0 !important; }
    }

    /*---------------------------------------------------------------------*
     |                     Toolbar & UI Consistency                        |
     *---------------------------------------------------------------------*/
    #navigator-toolbox,
    body,
    #urlbar-input,
    #urlbar-input:focus,
    #toolbar-menubar,
    #toolbar-menubar:hover,
    #urlbar-background,
    toolbarbutton,
    toolbarbutton:hover {
      background-color: var(--navbar-bg-color) !important;
    }
    #navigator-toolbox { border: 0 !important; }
    #nav-bar { background: transparent !important; }
    #page-action-buttons,
    #PanelUI-button { display: none !important; }

    .toolbarbutton-icon,
    .urlbar-icon,
    #identity-icon,
    #tracking-protection-icon,
    #PanelUI-menu-button {
      height: var(--tab-height) !important;
      width: var(--tab-height) !important;
      padding: 2px !important;
    }
    #TabsToolbar-customization-target {
      width: 100% !important;
      display: flex !important;
      align-items: center !important;
    }
    .toolbar-items {
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
    }
    .tabbrowser-tab {
      margin: 0 !important;
    }
    .tabbrowser-tab .tab-background {
      background: var(--uc-theme-colour) !important;
      box-shadow: none !important;
    }
    .tabbrowser-tab[selected] .tab-background {
      background: var(--uc-hover-colour) !important;
    }
    .tabbrowser-tab[selected][fadein]:not([pinned]) {
      max-width: var(--uc-active-tab-width) !important;
    }
    .tabbrowser-tab[fadein]:not([selected]):not([pinned]) {
      max-width: var(--uc-inactive-tab-width) !important;
    }
    .tabbrowser-tab:not([pinned]) .tab-close-button {
      display: var(--show-tab-close-button) !important;
    }
    .tabbrowser-tab:not([pinned]):hover .tab-close-button {
      display: var(--show-tab-close-button-hover) !important;
    }
    .tabbrowser-tab[usercontextid] > .tab-stack > .tab-background > .tab-context-line {
      margin: -1px var(--container-tabs-indicator-margin) 0 var(--container-tabs-indicator-margin) !important;
      border-radius: var(--uc-border-radius) !important;
    }
    .identity-color-blue      { --identity-tab-color: var(--uc-identity-color-blue) !important;
                                --identity-icon-color: var(--uc-identity-color-blue) !important; }
    .identity-color-turquoise { --identity-tab-color: var(--uc-identity-color-turquoise) !important;
                                --identity-icon-color: var(--uc-identity-color-turquoise) !important; }
    .identity-color-green     { --identity-tab-color: var(--uc-identity-color-green) !important;
                                --identity-icon-color: var(--uc-identity-color-green) !important; }
    .identity-color-yellow    { --identity-tab-color: var(--uc-identity-color-yellow) !important;
                                --identity-icon-color: var(--uc-identity-color-yellow) !important; }
    .identity-color-orange    { --identity-tab-color: var(--uc-identity-color-orange) !important;
                                --identity-icon-color: var(--uc-identity-color-orange) !important; }
    .identity-color-red       { --identity-tab-color: var(--uc-identity-color-red) !important;
                                --identity-icon-color: var(--uc-identity-color-red) !important; }
    .identity-color-pink      { --identity-tab-color: var(--uc-identity-color-pink) !important;
                                --identity-icon-color: var(--uc-identity-color-pink) !important; }
    .identity-color-purple    { --identity-tab-color: var(--uc-identity-color-purple) !important;
                                --identity-icon-color: var(--uc-identity-color-purple) !important; }

    /*---------------------------------------------------------------------*
     |              Cascade Button/Icon Visibility Adjustments             |
     *---------------------------------------------------------------------*/
    #back-button { display: -moz-inline-box !important; }
    #forward-button, #stop-button, #reload-button { display: none !important; }
    #star-button { display: none !important; }
    #urlbar-zoom-button { display: none !important; }
    #PanelUI-button { display: -moz-inline-box !important; }
    #reader-mode-button { display: none !important; }
    #tracking-protection-icon-container { display: none !important; }
    #identity-permission-box { display: none !important; }
    .tab-secondary-label { display: none !important; }
    #pageActionButton, #page-action-buttons { display: none !important; }

    /*---------------------------------------------------------------------*
     |                    Additional UI Adjustments                        |
     *---------------------------------------------------------------------*/
    .titlebar-buttonbox-container { display: -moz-inline-box !important; }
    .titlebar-spacer { display: none !important; }
    #tabbrowser-tabs[haspinnedtabs]:not([positionpinnedtabs])
      > #tabbrowser-arrowscrollbox
      > .tabbrowser-tab[first-visible-unpinned-tab] { margin-inline-start: 0 !important; }
    .tabbrowser-tab > .tab-stack > .tab-background { box-shadow: none !important; }
    .tab-icon-image:not([pinned]) { opacity: 1 !important; }
    .tab-icon-overlay:not([crashed]),
    .tab-icon-overlay[pinned][crashed][selected] {
      top: 5px !important;
      z-index: 1 !important;
      padding: 1.5px !important;
      inset-inline-end: -8px !important;
      width: 16px !important;
      height: 16px !important;
      border-radius: 10px !important;
    }
    .tab-icon-overlay:not([sharing], [crashed]):is([soundplaying], [muted], [activemedia-blocked]) {
      stroke: transparent !important;
      background: var(--uc-theme-colour) !important;
      opacity: 1 !important;
      fill-opacity: 0.8 !important;
      color: currentColor !important;
      stroke: var(--uc-theme-colour) !important;
    }
    .tabbrowser-tab[selected] .tab-icon-overlay:not([sharing], [crashed]):is([soundplaying], [muted], [activemedia-blocked]) {
      stroke: var(--uc-hover-colour) !important;
      background-color: var(--uc-hover-colour) !important;
    }
    .tab-icon-overlay:not([pinned], [sharing], [crashed]):is([soundplaying], [muted], [activemedia-blocked]) {
      margin-inline-end: 9.5px !important;
    }
    .tab-icon-overlay:not([crashed])[soundplaying]:hover,
    .tab-icon-overlay:not([crashed])[muted]:hover,
    .tab-icon-overlay:not([crashed])[activemedia-blocked]:hover {
      color: currentColor !important;
      stroke: var(--uc-inverted-colour) !important;
      background-color: var(--uc-inverted-colour) !important;
      fill-opacity: 0.95 !important;
    }
    #TabsToolbar .tab-icon-overlay:not([crashed])[soundplaying],
    #TabsToolbar .tab-icon-overlay:not([crashed])[muted],
    #TabsToolbar .tab-icon-overlay:not([crashed])[activemedia-blocked] {
      color: var(--uc-inverted-colour) !important;
    }
    #TabsToolbar .tab-icon-overlay:not([crashed])[soundplaying]:hover,
    #TabsToolbar .tab-icon-overlay:not([crashed])[muted]:hover,
    #TabsToolbar .tab-icon-overlay:not([crashed])[activemedia-blocked]:hover {
      color: var(--uc-theme-colour) !important;
    }
    #nav-bar {
      border: none !important;
      box-shadow: none !important;
      background: transparent !important;
    }
    #navigator-toolbox { border-bottom: none !important; }
    #urlbar, #urlbar * { box-shadow: none !important; }
    #urlbar-background { border: var(--uc-hover-colour) !important; }
    #urlbar[focused="true"] > #urlbar-background,
    #urlbar:not([open]) > #urlbar-background { background: transparent !important; }
    #urlbar[open] > #urlbar-background { background: var(--uc-theme-colour) !important; }
    .urlbarView-row:hover > .urlbarView-row-inner,
    .urlbarView-row[selected] > .urlbarView-row-inner { background: var(--uc-hover-colour) !important; }
  '';

  # Get the profiles from the Firefox directory
  profilesPath = "${config.home.homeDirectory}/.mozilla/firefox";
  profiles =
    if builtins.pathExists profilesPath
    then getProfiles profilesPath
    else [];

  # Create profile configurations
  mkProfileConfig = name: {
    inherit name;
    settings = commonSettings;
    userChrome = userChromeCss;
  };

  # Generate profile configurations for all detected profiles
  profileConfigs = builtins.listToAttrs (map
    (name: {
      inherit name;
      value = mkProfileConfig name;
    })
    profiles);
in {
  programs.firefox = {
    enable = true;
    profiles = {
      "y0usaf" = {
        settings = commonSettings;
        userChrome = userChromeCss;
      };
    };
  };
}
