###############################################################################
# Firefox Module
# Configures Firefox with optimized settings and custom UI
# - Performance optimizations
# - Custom userChrome for minimal UI
# - Hardware acceleration controls
# - Auto-detection of Firefox profiles
###############################################################################
{
  config,
  lib,
  pkgs,
  profile,
  ...
}: let
  cfg = config.modules.apps.firefox;

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
    # Enable userChrome customizations (needed for the CSS)
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # Disable hardware acceleration if using Nvidia
    "gfx.webrender.all" =
      if profile.modules.core.nvidia.enable
      then false
      else true;
    "media.hardware-video-decoding.enabled" =
      if profile.modules.core.nvidia.enable
      then false
      else true;
    "media.ffmpeg.vaapi.enabled" =
      if profile.modules.core.nvidia.enable
      then false
      else true;
    "layers.acceleration.disabled" =
      if profile.modules.core.nvidia.enable
      then true
      else false;

    # Performance settings
    "browser.sessionstore.interval" = 15000; # Reduce writes to disk (default 15000)
    "network.http.max-persistent-connections-per-server" = 10; # Increase connections per server
    "browser.cache.disk.enable" = false; # Disable disk cache in favor of memory cache
    "browser.cache.memory.enable" = true;
    "browser.cache.memory.capacity" = 1048576; # 1GB memory cache
    "browser.sessionhistory.max_entries" = 50; # Reduce memory usage from session history
    "network.prefetch-next" = true; # Enable link prefetching
    "network.dns.disablePrefetch" = false;
    "network.predictor.enabled" = true;

    # Basic UI settings
    "browser.tabs.drawInTitlebar" = true;
    "browser.theme.toolbar-theme" = 0;

    # Enable Browser Toolbox and development features
    "devtools.chrome.enabled" = true;
    "devtools.debugger.remote-enabled" = true;
    "devtools.debugger.prompt-connection" = false;
    "browser.enabledE10S" = false;

    # Theme and UI settings
    "browser.theme.dark-private-windows" = false;

    # Development settings
    "dom.webcomponents.enabled" = true;
    "layout.css.shadow-parts.enabled" = true;
  };

  userChromeCss = ''
    /* >>> Global Resets & Variables <<< */
    /*
     * WARNING: The following rule is very aggressive and might break UI elements.
     * Consider applying zero padding/margin only to specific elements you want to reset.
     * Uncomment if you understand the risks and require this global reset.
     */
    /*
    * {
      padding: 0 !important;
      margin: 0 !important;
    }
    */

    /* Disable all animations */
    * {
      animation: none !important;
      transition: none !important;
      scroll-behavior: auto !important; /* Override smooth scrolling */
    }

    /* Further ensure animations are minimal even if prefers-reduced-motion is not set */
    @media (prefers-reduced-motion: no-preference) {
      * {
        animation-duration: 0.001s !important;
        transition-duration: 0.001s !important;
      }
    }

    /* Disable smooth scrolling explicitly */
    html {
      scroll-behavior: auto !important;
    }

    :root {
        --tab-font-size: 0.8em;
        --max-tab-width: none; /* Allow tabs to shrink */
        --show-titlebar-buttons: none; /* Hide window controls */
        --tab-height: 12pt;
        --toolbar-icon-size: calc(var(--tab-height) / 1.5);
        --uc-bottom-toolbar-height: 12pt; /* Height for bottom nav bar */
    }

    /* >>> Titlebar & Tabs <<< */

    /* Hide window control buttons */
    .titlebar-buttonbox-container {
        display: var(--show-titlebar-buttons);
    }

    /* General Tab toolbar styling */
    :root:not([customizing]) #TabsToolbar {
        margin-left: 1pt !important;
        margin-right: 1pt !important;
        border-radius: 0 !important;
        padding: 0 !important;
        min-height: 0 !important;
    }

    /* Reset margins/borders within tabs */
    .tabbrowser-tab * {
        margin: 0 !important;
        border-radius: 0 !important;
    }

    /* Individual tab styling */
    .tabbrowser-tab {
        height: var(--tab-height);
        font-size: var(--tab-font-size) !important;
        min-height: 0 !important;
        align-items: center !important;
        margin-bottom: 2pt !important; /* Space below tabs */
        transition: none !important; /* Disable tab animations */
    }

    /* Tab icon sizing */
    .tab-icon-image {
        height: auto !important;
        width: var(--toolbar-icon-size) !important;
        margin-right: 2pt !important;
    }

    /* Ensure tab bar container takes minimum height */
    #tabbrowser-arrowscrollbox,
    #tabbrowser-tabs,
    #tabbrowser-tabs > .tabbrowser-arrowscrollbox {
        min-height: 0 !important;
    }

    /* New Tab button styling */
    :root:not([customizing]) #TabsToolbar .titlebar-button,
    :root:not([customizing]) #TabsToolbar-customization-target > .toolbarbutton-1,
    :root:not([customizing]) #tabbrowser-tabs .tabs-newtab-button,
    :root:not([customizing]) #tabs-newtab-button {
        -moz-appearance: none !important;
        padding-top: 0 !important;
        padding-bottom: 0 !important;
        -moz-box-align: stretch;
        margin: 0 !important;
    }

    #tabbrowser-tabs .tabs-newtab-button:hover,
    #tabs-newtab-button:hover {
        background-color: var(--toolbarbutton-hover-background);
    }

    #tabbrowser-tabs .tabs-newtab-button > .toolbarbutton-icon,
    #tabs-newtab-button > .toolbarbutton-icon {
        padding: 0 !important;
        transform: scale(.6);
        background-color: transparent !important;
    }

    /* Adjust padding for maximized windows on Windows 10+ */
    @media (-moz-os-version: windows-win10) {
        :root[sizemode=maximized] #navigator-toolbox {
            padding-top: 7pt !important;
        }
    }

    /* >>> Bottom Navigation Bar <<< */

    /* Position nav-bar at the bottom */
    #nav-bar {
        position: fixed !important;
        bottom: 0 !important;
        width: 100% !important; /* Full width initially */
        height: var(--uc-bottom-toolbar-height) !important;
        max-height: var(--uc-bottom-toolbar-height) !important;
        z-index: 1; /* Ensure it's above page content */
        /* Centering and width adjustment */
        margin: -1pt auto 0 !important; /* Negative top margin for border overlap */
        border-top: none !important;
        width: 75vw !important; /* Centered width */
        left: 0 !important; /* Required for margin: auto centering */
        right: 0 !important; /* Required for margin: auto centering */
    }

    /* Add margin to the bottom of the browser content area to prevent overlap */
    #browser {
        margin-bottom: var(--uc-bottom-toolbar-height) !important;
    }

    /* >>> URL Bar & Toolbar Items <<< */

    /* Center tabs when not overflowing */
    #tabbrowser-arrowscrollbox:not([overflowing]) {
        --uc-flex-justify: center;
    }
    scrollbox[orient=horizontal] > slot {
        justify-content: var(--uc-flex-justify, initial);
    }

    /* URL bar height */
    #urlbar,
    #urlbar-input-container {
        height: var(--tab-height) !important;
        min-height: 0 !important; /* Override default min-height */
    }
    #urlbar, #urlbar[open] {
        min-height: var(--tab-height) !important; /* Ensure min-height even when open */
    }
    /* Allow URL bar dropdown to expand */
    #urlbar[open],
    #urlbar[open] #urlbar-input-container {
        height: auto !important;
    }

    /* Icon sizing in URL bar and toolbars */
    #identity-icon,
    #page-action-buttons img,
    #permissions-granted-icon,
    #star-button-box,
    #tracking-protection-icon,
    .searchbar-search-icon,
    .urlbar-page-action,
    .tab-close-button,
    .titlebar-button > image,
    .toolbarbutton-icon,
    .urlbar-icon,
    .urlbar-page-action > image {
        height: auto !important;
        width: var(--toolbar-icon-size) !important;
        padding: 0 !important;
    }

    /* General toolbar button padding/margin reset */
    .toolbarbutton-1,
    .toolbarbutton-icon,
    #PersonalToolbar toolbarbutton,
    #TabsToolbar toolbarbutton,
    #nav-bar toolbarbutton,
    .titlebar-button,
    .toolbaritem-combined-buttons,
    .tab-close-button,
    .urlbar-icon,
    .urlbar-page-action {
        -moz-appearance: none !important;
        padding-inline: 1pt !important;
        -moz-box-align: stretch;
        margin: 0 !important;
    }
    .toolbarbutton-1 {
        padding: 0 2pt !important; /* Specific padding for some buttons */
    }
    #PersonalToolbar toolbarbutton,
    #TabsToolbar toolbarbutton,
    #nav-bar toolbarbutton,
    .titlebar-button,
    .toolbaritem-combined-buttons,
    .urlbar-page-action {
        padding-top: 0 !important;
        padding-bottom: 0 !important;
    }

    /* Remove padding/margin from main toolbox and URL bar dropdown */
    #navigator-toolbox,
    .urlbarView {
        margin: 0 !important;
        padding: 0 !important;
    }

    /* Style main toolbox like a standard toolbar */
    #navigator-toolbox {
        appearance: toolbar !important;
    }

    /* Remove bottom margin/padding from toolbars */
    #titlebar {
        -moz-appearance: none !important;
        padding-bottom: 0 !important;
    }
    #TabsToolbar,
    #titlebar,
    toolbar {
        margin-bottom: 0 !important;
    }
    #TabsToolbar {
        padding-bottom: 0 !important;
    }
    toolbar {
        margin-top: 0 !important;
        padding: 0 !important;
    }

    /* >>> URL Bar Dropdown (View) <<< */

    /* Font size and max height for dropdown */
    .urlbarView {
        font-size: var(--tab-font-size) !important;
        max-height: calc(60vh - 40pt) !important;
        overflow-y: auto !important;
    }

    /* Row padding */
    .urlbarView-row {
        padding-block: 1pt !important;
    }
    .urlbarView-row-inner {
        padding-inline: 2pt !important;
    }

    /* Hide Firefox Suggest entries */
    .urlbarView-row[label="Firefox Suggest"] {
        margin-top: 0 !important;
        overflow: hidden !important;
        display: none !important; /* Hide completely */
    }

    /* Text padding/margin reset within dropdown rows */
    .urlbarView-secondary,
    .urlbarView-title,
    .urlbarView-url {
        padding: 0 !important;
        margin: 0 !important;
    }

    /* Styling for the "breakout" (centered, modal-like) URL bar */
    #urlbar[breakout][breakout-extend] {
        box-shadow: 0 15pt 30pt rgba(0, 0, 0, .2);
        width: 50vw !important; /* Centered width */
        left: 50% !important; /* Position start at center */
        right: auto !important;
        top: 20vh !important; /* Position from top */
        margin: 0 !important;
        position: fixed !important; /* Fixed position */
        z-index: 999 !important; /* Ensure it's on top */
        transform: translateX(-50%) !important; /* Center horizontally */
        max-height: 60vh !important;
        min-height: 40pt !important;
    }

    /* Center text in URL bar when not focused or broken out */
    #urlbar:not([breakout][breakout-extend]) #urlbar-input,
    #urlbar:not([focused]) #urlbar-input {
        text-align: center !important;
    }

    /* Remove border radius from URL bar elements */
    #urlbar-background,
    #urlbar-input-container {
        --toolbarbutton-border-radius: 0pt !important;
        --urlbar-icon-border-radius: 0pt !important;
    }

    /* >>> Miscellaneous <<< */

    /* Remove flexible space elements from toolbars */
    toolbarspring,
    .toolbar-spring,
    [anonid="spring"] {
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
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.apps.firefox = {
    enable = lib.mkEnableOption "Firefox browser with optimized settings";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Programs
    ###########################################################################
    programs.firefox = {
      enable = true;
      profiles = {
        "y0usaf" = {
          settings = commonSettings;
          userChrome = userChromeCss;
        };
      };

      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = false;
        };
        ExtensionSettings = {
          "*" = {
            installation_mode = "allowed";
            allowed_types = ["extension" "theme"];
          };
        };
      };
    };

    ###########################################################################
    # Environment Variables
    ###########################################################################
    programs.zsh = {
      envExtra = ''
        # Firefox environment variables
        export MOZ_ENABLE_WAYLAND=1
        export MOZ_USE_XINPUT2=1
      '';
    };
  };
}
