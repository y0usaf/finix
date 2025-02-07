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
    /* Minimalist Tab Bar */
    :root {
      --tab-height: 1rem;
      --tab-font-size: 0.8em;
      --tab-font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    }

    .tabbrowser-tab,
    .tabbrowser-tab * {
      margin: 0 !important;
      padding: 0 !important;
      border: 0 !important;
      font-family: var(--tab-font-family) !important;
    }

    .tabbrowser-tab {
      height: var(--tab-height) !important;
      font-size: var(--tab-font-size) !important;
      align-items: center !important;
      margin-bottom: 2px !important;
    }

    /* Hide extra tab elements for a cleaner look */
    .tab-close-button,
    .new-tab-button,
    #firefox-view-button,
    #tabs-newtab-button {
      display: none !important;
    }

    /* Hidden-by-default Address Bar (appears on focus) */
    :root:not([customizing]) #nav-bar,
    :root:not([customizing]) #urlbar[popover] {
      opacity: 0 !important;
      pointer-events: none !important;
      margin-top: -40px !important;
    }

    :root:not([customizing]) #nav-bar:focus-within,
    :root:not([customizing]) #urlbar[popover]:focus-within {
      opacity: 1 !important;
      pointer-events: auto !important;
      margin-top: 0 !important;
    }

    /* Popout URL Bar Styling */
    #urlbar[breakout][breakout-extend] {
      position: fixed !important;
      top: 30vh !important;
      left: 50% !important;
      transform: translateX(-50%) !important;
      width: 50vw !important;
      box-shadow: 0 1rem 2rem rgba(0, 0, 0, 0.2) !important;
      z-index: 1000 !important;
    }

    /* 10. Consistent background for various UI elements */
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

    /* 11. Center scrollbox contents */
    scrollbox[smoothscroll="true"] {
      display: flex !important;
      justify-content: center !important;
    }

    /***** CENTER TABS RULES *****/
    /* When tabs are not overflowing, center them */
    #tabbrowser-arrowscrollbox:not([overflowing]) {
      --uc-flex-justify: center;
    }
    scrollbox[orient="horizontal"] {
      justify-content: var(--uc-flex-justify, initial);
    }

    /* --- Integrated Additional CSS --- */

    /* Title bar */
    .titlebar-buttonbox {
        display: none !important;
    }

    .titlebar-spacer {
        display: none !important;
    }

    /* Tab bar */
    #navigator-toolbox {
        border: 0px !important;
    }

    #TabsToolbar {
        margin-left: 20vw !important;
    }

    /* Nav bar */
    #nav-bar {
        background: transparent !important;
        margin-right: 80vw !important;
        margin-top: -36px !important;
    }

    /* URL bar */
    #back-button {
        display: none !important;
    }

    #forward-button {
        display: none !important;
    }

    #tracking-protection-icon-container {
        display: none !important;
    }

    #urlbar-container {
        width: auto !important;
    }

    #urlbar {
        background: transparent !important;
        border: none !important;
        box-shadow: none !important;
    }

    #urlbar[breakout-extend] {
        width: 100vw !important;
    }

    #page-action-buttons {
        display: none !important;
    }

    #PanelUI-button {
        display: none !important;
    }
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
