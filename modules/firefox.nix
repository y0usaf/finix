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
    /*----------------------------------------------------------------------------------*
     *   COMBINED CASCADE THEME (Mouse Edition) + MINIMAL ONE-LINER PROTON UI LAYOUT   *
     *----------------------------------------------------------------------------------*/

    /*---------------------------------------------------------------------*
     |                Root Variables: Colors, Sizing and Layout            |
     *---------------------------------------------------------------------*/
    :root {
      /* Cascade theme colours (Dark theme) */
      --window-colour:           #1f2122;
      --secondary-colour:        #141616;
      --inverted-colour:         #FAFAFC;

      /* Container Tab Colours from Cascade */
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

      /* Global border radius */
      --uc-border-radius: 0;

      /* URL bar and Tab width settings */
      --uc-urlbar-width:       clamp(250px, 50vw, 600px);
      --uc-active-tab-width:   clamp(50px, 18vw, 220px);
      --uc-inactive-tab-width: clamp(50px, 15vw, 200px);

      /* Tab close button options */
      --show-tab-close-button:        none;
      --show-tab-close-button-hover:  -moz-inline-box;

      /* Container tabs indicator margin */
      --container-tabs-indicator-margin: 0px;

      /* Minimal layout variables */
      --tab-font-size:      0.8em;
      --tab-font-family:    -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      --tab-height:         1rem;
      --navbar-bg-color:    var(--window-colour);
      --navbar-min-width:   1000px;
      --navbar-max-width:   2000px;

      /* Cascade "one-liner" extra colours */
      --uc-theme-colour:    var(--window-colour);
      --uc-hover-colour:    var(--secondary-colour);
      --uc-inverted-colour: var(--inverted-colour);
    }

    /*---------------------------------------------------------------------*
     |                           Global Resets                             |
     *---------------------------------------------------------------------*/
    * {
      animation: none !important;
      transition: none !important;
    }

    /*---------------------------------------------------------------------*
     |                        Tabs Minimalism Settings                     |
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
      width:  calc(var(--tab-height) * 0.8) !important;
      padding: 2px !important;
    }

    /*---------------------------------------------------------------------*
     |                   Navigation & Toolbar Layout                       |
     *---------------------------------------------------------------------*/
    #TabsToolbar,
    #nav-bar {
      background: var(--navbar-bg-color) !important;
      height: var(--tab-height) !important;
      margin: 0 auto !important;
      width: var(--navbar-min-width) !important;
      position: relative !important;
    }

    /* Responsive adjustments for nav bar and tabs toolbar */
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

    /*---------------------------------------------------------------------*
     |                  Pop-out URLbar & One-liner Addressbar                |
     *---------------------------------------------------------------------*/
    :root:not([customizing]) #nav-bar,
    :root:not([customizing]) #urlbar[popover] {
      pointer-events: none;
      margin: 0 0 -40px !important;
      opacity: 0 !important;
    }
    :root:not([customizing]) #nav-bar:focus-within,
    :root:not([customizing]) #urlbar[popover]:focus-within,
    :root:not([customizing]) #nav-bar:has(#urlbar[popover]:focus-within),
    :root:not([customizing]) #nav-bar:focus-within #urlbar[popover] {
      pointer-events: auto;
      margin: 0 0 auto !important;
      opacity: 1 !important;
    }

    /* Pop-out URLbar styling (kept from your current CSS) */
    #urlbar[breakout][breakout-extend] {
      position: fixed !important;
      top: 30vh !important;
      left: 50% !important;
      transform: translateX(-50%) !important;
      box-shadow: 0 1rem 2rem rgba(0, 0, 0, 0.2) !important;
      width: 50vw !important;
      z-index: 1000 !important;
    }

    /* Ensure the URLbar container takes full width & remove extraneous margins */
    #urlbar-container {
      width: 100% !important;
      margin: 0 !important;
    }
    #urlbar {
      background: transparent !important;
      border: none !important;
      box-shadow: none !important;
    }
    #urlbar[breakout-extend] {
      width: 100vw !important;
    }
    /* Center the URLbar text when not expanded/focused */
    #urlbar:not([breakout][breakout-extend]) #urlbar-input,
    #urlbar:not([focused]) #urlbar-input {
      text-align: center !important;
    }

    /*---------------------------------------------------------------------*
     |                   Overall UI & Background Consistency               |
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

    scrollbox[smoothscroll="true"] {
      display: flex !important;
      justify-content: center !important;
    }

    /* Center Tabs when not overflowing */
    #tabbrowser-arrowscrollbox:not([overflowing]) {
      --uc-flex-justify: center;
    }
    scrollbox[orient="horizontal"] {
      justify-content: var(--uc-flex-justify, initial) !important;
    }

    /*---------------------------------------------------------------------*
     |             Additional Cascade-Specific (Minimal adjustments)       |
     *---------------------------------------------------------------------*/

    /* Remove extra borders/shadows */
    #navigator-toolbox {
      border: 0 !important;
    }
    #nav-bar {
      background: transparent !important;
      margin: -36px auto 0 !important;
    }
    #page-action-buttons,
    #PanelUI-button {
      display: none !important;
    }

    /* Scale toolbar icons to match the minimal tab height */
    .toolbarbutton-icon,
    .urlbar-icon,
    #identity-icon,
    #tracking-protection-icon,
    #PanelUI-menu-button {
      height: var(--tab-height) !important;
      width: var(--tab-height) !important;
      padding: 2px !important;
    }

    /* Ensure toolbar buttons align with the tabs */
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

    /* Minimal adjustments for tab backgrounds and widths */
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

    /* Container tabs indicator */
    .tabbrowser-tab[usercontextid] > .tab-stack > .tab-background > .tab-context-line {
      margin: -1px var(--container-tabs-indicator-margin) 0 var(--container-tabs-indicator-margin) !important;
      border-radius: var(--uc-border-radius) !important;
    }

    /* Identity color styling for container tabs */
    .identity-color-blue      { --identity-tab-color: var(--uc-identity-color-blue) !important;      --identity-icon-color: var(--uc-identity-color-blue) !important; }
    .identity-color-turquoise { --identity-tab-color: var(--uc-identity-color-turquoise) !important; --identity-icon-color: var(--uc-identity-color-turquoise) !important; }
    .identity-color-green     { --identity-tab-color: var(--uc-identity-color-green) !important;     --identity-icon-color: var(--uc-identity-color-green) !important; }
    .identity-color-yellow    { --identity-tab-color: var(--uc-identity-color-yellow) !important;    --identity-icon-color: var(--uc-identity-color-yellow) !important; }
    .identity-color-orange    { --identity-tab-color: var(--uc-identity-color-orange) !important;    --identity-icon-color: var(--uc-identity-color-orange) !important; }
    .identity-color-red       { --identity-tab-color: var(--uc-identity-color-red) !important;       --identity-icon-color: var(--uc-identity-color-red) !important; }
    .identity-color-pink      { --identity-tab-color: var(--uc-identity-color-pink) !important;      --identity-icon-color: var(--uc-identity-color-pink) !important; }
    .identity-color-purple    { --identity-tab-color: var(--uc-identity-color-purple) !important;    --identity-icon-color: var(--uc-identity-color-purple) !important; }

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
