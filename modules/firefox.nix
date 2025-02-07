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
    /* Root variables for consistent theming */
    :root {
      --tab-height: 20px;
      --navbar-bg-color: black;
      --navbar-min-width: 1000px;
      --navbar-max-width: 2000px;
    }

    /* Reset borders */
    * {
      border: 0;
    }

    /* Set consistent height for tabs and navigation bar */
    #TabsToolbar,
    #nav-bar,
    .tabbrowser-tab {
      height: var(--tab-height) !important;
    }

    /* Apply background color to navigation elements */
    #TabsToolbar,
    #nav-bar {
      background: var(--navbar-bg-color) !important;
    }

    /* Responsive layout for large screens (>= 2000px) */
    @media (min-width: 2000px) {
      #TabsToolbar,
      #nav-bar {
        margin-left: calc((100vw - var(--navbar-min-width)) / 2);
        width: var(--navbar-min-width);
      }
    }

    /* Responsive layout for medium screens (1000px - 1999px) */
    @media (min-width: 1000px) and (max-width: 1999px) {
      #TabsToolbar,
      #nav-bar {
        margin-left: calc((100vw - var(--navbar-min-width)) / 2);
        width: calc(100vw - (100vw - var(--navbar-min-width)));
      }
    }

    /* Responsive layout for small screens (< 1000px) */
    @media (max-width: 999px) {
      #TabsToolbar,
      #nav-bar {
        margin-left: 0;
        width: 100vw;
      }
    }

    /* Center scrollbox contents */
    scrollbox[smoothscroll="true"] {
      display: flex !important;
      justify-content: center !important;
    }

    /* Center main window content */
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

    /* Remove rounded corners from URL bar */
    #urlbar-background,
    #urlbar-input-container {
      --toolbarbutton-border-radius: 0px;
    }

    #urlbar-input-container {
      --urlbar-icon-border-radius: 0px;
    }

    /* Center URL bar text when not focused/expanded */
    #urlbar:not([breakout][breakout-extend]) #urlbar-input,
    #urlbar:not([focused]) #urlbar-input {
      text-align: center !important;
    }

    /* Consistent background color across all UI elements */
    #TabsToolbar,
    #main-window,
    #nav-bar,
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
    profiles = profileConfigs;
  };
}
