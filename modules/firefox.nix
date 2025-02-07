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
    /* Define custom properties for scalable values */
    :root {
      --tab-height: clamp(20px, 2.5vh, 30px);
      --navbar-bg-color: black;
      --navbar-fixed-width: 1000px;
      --navbar-side-padding: 1rem;
      --tab-font-size: 0.8em;
      --tab-font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      --max-tab-width: none;
    }

    /* Remove borders universally */
    * {
      border: 0;
    }

    /* Toolbar and tab styling */
    #TabsToolbar,
    #nav-bar {
      height: var(--tab-height) !important;
      width: 100%;
      max-width: var(--navbar-fixed-width);
      margin: 0 auto;
      padding: 0 var(--navbar-side-padding);
      background: var(--navbar-bg-color) !important;
    }
    .tabbrowser-tab {
      height: var(--tab-height) !important;
    }

    /* Center toolbars and scroll containers */
    #tabbrowser-arrowscrollbox:not([overflowing]) {
      --uc-flex-justify: center;
    }
    #tabbrowser-tabs,
    .tabbrowser-arrowscrollbox,
    scrollbox[smoothscroll="true"] {
      display: flex !important;
      justify-content: center !important;
    }
    scrollbox[orient="horizontal"] {
      justify-content: var(--uc-flex-justify, center) !important;
    }

    /* Hide spacer elements */
    .titlebar-spacer {
      display: none !important;
    }

    /* Main window layout */
    #main-window {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      height: 100vh;
    }

    /* URL bar styling when expanded */
    #main-window #urlbar[breakout][breakout-extend] {
      box-shadow: 0 15px 30px rgba(0, 0, 0, 0.2);
      width: 100% !important;
      left: 0;
      right: 0;
      margin: 30vh auto 0 !important;
      justify-content: center;
    }

    /* Remove rounded corners from URL bar components */
    #urlbar-background,
    #urlbar-input-container {
      --toolbarbutton-border-radius: 0;
      --urlbar-icon-border-radius: 0;
    }

    /* Center URL bar text when not focused/expanded */
    #urlbar:not([breakout][breakout-extend]) #urlbar-input,
    #urlbar:not([focused]) #urlbar-input {
      text-align: center !important;
    }

    /* Uniform background color for various UI elements */
    #main-window,
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

    /* Minimalist Tabs and Hidden Addressbar */

    /* 1. Minimalist Tabs Settings */
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

    /* Hide extra tab elements to keep things minimalist */
    .tab-close-button,
    .new-tab-button,
    #firefox-view-button,
    #scrollbutton-up,
    .tab-secondary-label,
    #tabs-newtab-button,
    #titlebar spacer,
    #alltabs-button,
    #scrollbutton-down,
    #new-tab-button {
      display: none !important;
    }

    .tab-icon-image {
      height: auto !important;
      width: calc(var(--tab-height) / 1.5) !important;
      margin-right: 4px !important;
    }

    /* 2. Hide the Addressbar by Default */
    /* When not customizing, the navigation bar (#nav-bar) and popup URL field (#urlbar[popover])
       are hidden: they have no pointer-events, are shifted upward (via negative margin),
       and are fully transparent (opacity: 0). */
    :root:not([customizing]) #nav-bar,
    :root:not([customizing]) #urlbar[popover] {
      pointer-events: none;
      margin: 0 0 -40px !important;
      opacity: 0 !important;
    }

    /* When the address bar or navigation bar receives focus, it becomes visible and interactive */
    :root:not([customizing]) #nav-bar:focus-within,
    :root:not([customizing]) #urlbar[popover]:focus-within,
    :root:not([customizing]) #nav-bar:has(#urlbar[popover]:focus-within),
    :root:not([customizing]) #nav-bar:focus-within #urlbar[popover] {
      pointer-events: auto;
      margin: 0 0 auto !important;
      opacity: 1 !important;
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
