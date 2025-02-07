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
    /* Minimalist Tabs, Hidden Addressbar, Pop-out Addressbar, and Centered Tabs */

    /* 1. Root variables for consistent theming */
    :root {
      --tab-font-size: 0.8em;
      --tab-font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      --max-tab-width: none;
      --tab-height: 1rem;  /* Reduced tab height to make tabs less massive */
      --navbar-bg-color: black;
      --navbar-min-width: 1000px;
      --navbar-max-width: 2000px;
    }

    /* 2. Reset borders */
    * {
      border: 0;
    }

    /* 3. Minimalist Tabs Settings */
    .tabbrowser-tab * {
      margin: 0 !important;
      border-radius: 0 !important;
      font-family: var(--tab-font-family) !important;
    }

    .tabbrowser-tab {
      height: var(--tab-height);
      font-size: var(--tab-font-size) !important;
      min-height: 0 !important;
      align-items: center !important;
      margin-bottom: 5px !important;
    }

    .tabbrowser-tab[fadein]:not([pinned]) {
      max-width: var(--max-tab-width) !important;
    }

    .tab-icon-image {
      height: auto !important;
      width: calc(var(--tab-height) / 1.5) !important;
      margin-right: 4px !important;
    }

    /* 4. Navigation and Tabs Toolbar Background and Layout */
    #TabsToolbar,
    #nav-bar {
      background: var(--navbar-bg-color) !important;
      height: var(--tab-height) !important;
    }

    /* Responsive layout for navigation toolbar */
    @media (min-width: 2000px) {
      #TabsToolbar,
      #nav-bar {
        margin-left: calc((100vw - var(--navbar-min-width)) / 2);
        width: var(--navbar-min-width);
      }
    }

    @media (min-width: 1000px) and (max-width: 1999px) {
      #TabsToolbar,
      #nav-bar {
        margin-left: calc((100vw - var(--navbar-min-width)) / 2);
        width: calc(100vw - (100vw - var(--navbar-min-width)));
      }
    }

    @media (max-width: 999px) {
      #TabsToolbar,
      #nav-bar {
        margin-left: 0;
        width: 100vw;
      }
    }

    /* 5. Hide the Addressbar by Default */
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

    /* 6. Main Window Centring for Pop-out Addressbar */
    #main-window {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      height: 100vh;
    }

    /* 7. Pop-out Addressbar Styling with scalable units */
    #urlbar[breakout][breakout-extend] {
      position: fixed !important;
      top: 30vh !important;
      left: 50% !important;
      transform: translateX(-50%) !important;
      box-shadow: 0 1rem 2rem rgba(0, 0, 0, 0.2) !important;
      width: 50vw !important;   /* Always 50% of the viewport width */
      z-index: 1000 !important;
    }

    /* 8. Optional: Remove rounded corners from URL bar elements */
    #urlbar-background,
    #urlbar-input-container {
      --toolbarbutton-border-radius: 0px;
    }

    #urlbar-input-container {
      --urlbar-icon-border-radius: 0px;
    }

    /* 9. Center URL bar text when not expanded/focused */
    #urlbar:not([breakout][breakout-extend]) #urlbar-input,
    #urlbar:not([focused]) #urlbar-input {
      text-align: center !important;
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
