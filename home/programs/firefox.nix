###############################################################################
# Firefox Module (Maid)
# Configures Firefox with optimized settings and custom UI
# - Performance optimizations
# - Custom userChrome for minimal UI
# - Hardware acceleration controls
# - Direct profile configuration
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.firefox;
  inherit (config.shared) username;

  # Common settings for Firefox profiles
  commonSettings = {
    # Enable userChrome customizations (needed for the CSS)
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # Disable hardware acceleration if using Nvidia
    "gfx.webrender.all" =
      if config.system.hardware.nvidia.enable or false
      then false
      else true;
    "media.hardware-video-decoding.enabled" =
      if config.system.hardware.nvidia.enable or false
      then false
      else true;
    "media.ffmpeg.vaapi.enabled" =
      if config.system.hardware.nvidia.enable or false
      then false
      else true;
    "layers.acceleration.disabled" =
      if config.system.hardware.nvidia.enable or false
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
    /* Disable all animations */
    * {
      animation: none;
      transition: none;
      scroll-behavior: auto;
      padding: 0;
      margin: 0;
    }

    :root {
        /* Base sizing variables */
        --tab-font-size: 0.8em;
        --max-tab-width: none;
        --show-titlebar-buttons: none;
        --tab-height: 12pt;
        --toolbar-icon-size: calc(var(--tab-height) / 1.5);
        
        /* Spacing variables */
        --uc-spacing-small: 1pt;
        --uc-spacing-medium: 2pt;
        --uc-spacing-large: 4pt;
        
        /* Layout variables */
        --uc-bottom-toolbar-height: 12pt;
        --uc-navbar-width: 75vw;
        --uc-urlbar-width: 50vw;
        --uc-urlbar-bottom-offset: calc(var(--uc-bottom-toolbar-height) + var(--uc-spacing-medium));
        
        /* Animation control */
        --uc-animation-duration: 0.001s;
        --uc-transition-duration: 0.001s;
    }

    /* Disable specific Firefox animations */
    @media (prefers-reduced-motion: no-preference) {
      * {
        animation-duration: var(--uc-animation-duration);
        transition-duration: var(--uc-transition-duration);
      }
    }

    /* Disable smooth scrolling */
    html {
      scroll-behavior: auto;
    }

    /* Disable tab animations */
    .tabbrowser-tab {
      transition: none;
    }

    /* Disable toolbar animations */
    :root[tabsintitlebar] #toolbar-menubar[autohide=true][inactive] {
        transition: none;
    }

    /* Rest of your existing CSS */
    .titlebar-buttonbox-container {
        display: var(--show-titlebar-buttons)
    }

    :root:not([customizing]) #TabsToolbar {
        margin-left: var(--uc-spacing-small);
        margin-right: var(--uc-spacing-small);
        border-radius: 0;
        padding: 0;
        min-height: 0;
    }

    .tabbrowser-tab * {
        margin: 0;
        border-radius: 0;
    }

    .tabbrowser-tab {
        height: var(--tab-height);
        font-size: var(--tab-font-size);
        min-height: 0;
        align-items: center;
        margin-bottom: var(--uc-spacing-medium);
    }

    .tab-icon-image {
        height: auto;
        width: var(--toolbar-icon-size);
        margin-right: var(--uc-spacing-medium);
    }

    #tabbrowser-arrowscrollbox,
    #tabbrowser-tabs,
    #tabbrowser-tabs > .tabbrowser-arrowscrollbox {
        min-height: 0;
    }

    :root:not([customizing]) #TabsToolbar .titlebar-button,
    :root:not([customizing]) #TabsToolbar-customization-target > .toolbarbutton-1,
    :root:not([customizing]) #tabbrowser-tabs .tabs-newtab-button,
    :root:not([customizing]) #tabs-newtab-button {
        -moz-appearance: none;
        padding-top: 0;
        padding-bottom: 0;
        -moz-box-align: stretch;
        margin: 0;
    }

    #tabbrowser-tabs .tabs-newtab-button:hover,
    #tabs-newtab-button:hover {
        background-color: var(--toolbarbutton-hover-background);
    }

    #tabbrowser-tabs .tabs-newtab-button > .toolbarbutton-icon,
    #tabs-newtab-button > .toolbarbutton-icon {
        padding: 0;
        transform: scale(0.6);
        background-color: transparent;
    }

    @media (-moz-os-version: windows-win10) {
        :root[sizemode=maximized] #navigator-toolbox {
            padding-top: calc(var(--uc-spacing-large) + var(--uc-spacing-medium));
        }
    }

    #nav-bar {
        position: fixed;
        bottom: 0;
        width: var(--uc-navbar-width);
        height: var(--uc-bottom-toolbar-height);
        max-height: var(--uc-bottom-toolbar-height);
        margin: calc(-1 * var(--uc-spacing-small)) auto 0;
        border-top: none;
        left: 0;
        right: 0;
        z-index: 1;
    }

    #browser {
        margin-bottom: var(--uc-bottom-toolbar-height);
    }

    #tabbrowser-arrowscrollbox:not([overflowing]) {
        --uc-flex-justify: center
    }

    scrollbox[orient=horizontal]>slot {
        justify-content: var(--uc-flex-justify, initial)
    }

    #urlbar,
    #urlbar-input-container {
        height: var(--tab-height);
    }

    #urlbar,
    #urlbar[open] {
        min-height: var(--tab-height);
    }

    #urlbar-input-container {
        min-height: 0;
    }

    #urlbar[open],
    #urlbar[open] #urlbar-input-container {
        height: auto;
    }

    #identity-icon,
    #page-action-buttons img,
    #permissions-granted-icon,
    #star-button-box,
    #tracking-protection-icon,
    .searchbar-search-icon,
    .urlbar-page-action {
        height: auto;
        width: var(--toolbar-icon-size);
        padding: 0;
    }

    .toolbarbutton-1 {
        padding: 0 var(--uc-spacing-medium);
    }

    .toolbarbutton-1,
    .toolbarbutton-icon {
        -moz-appearance: none;
        padding-inline: var(--uc-spacing-small);
        -moz-box-align: stretch;
        margin: 0;
    }

    #PersonalToolbar toolbarbutton,
    #TabsToolbar toolbarbutton,
    #nav-bar toolbarbutton,
    .titlebar-button,
    .toolbaritem-combined-buttons {
        -moz-appearance: none;
        padding-top: 0;
        padding-bottom: 0;
        padding-inline: var(--uc-spacing-small);
        -moz-box-align: stretch;
        margin: 0;
    }

    .tab-close-button,
    .urlbar-icon,
    .urlbar-page-action {
        -moz-appearance: none;
        padding-inline: var(--uc-spacing-small);
        -moz-box-align: stretch;
        margin: 0;
    }

    .urlbar-page-action {
        padding-top: 0;
        padding-bottom: 0;
    }

    .tab-close-button,
    .titlebar-button > image,
    .toolbarbutton-icon,
    .urlbar-icon,
    .urlbar-page-action > image {
        padding: 0;
        width: var(--toolbar-icon-size);
        height: auto;
    }

    #navigator-toolbox,
    .urlbarView {
        margin: 0;
        padding: 0;
    }

    #navigator-toolbox {
        appearance: toolbar;
    }


    #titlebar {
        -moz-appearance: none;
        padding-bottom: 0;
    }

    #TabsToolbar,
    #titlebar,
    toolbar {
        margin-bottom: 0;
    }

    #TabsToolbar {
        padding-bottom: 0;
    }

    toolbar {
        margin-top: 0;
        padding: 0;
    }

    .urlbarView {
        font-size: var(--tab-font-size);
        max-height: calc(60vh - calc(var(--tab-height) * 3));
        overflow-y: auto;
    }

    .urlbarView-row {
        padding-block: var(--uc-spacing-small);
    }

    .urlbarView-row-inner {
        padding-inline: var(--uc-spacing-medium);
    }

    .urlbarView-row[label="Firefox Suggest"] {
        margin-top: 0;
        overflow: hidden;
        display: none; /* Hide completely */
    }

    .urlbarView-secondary,
    .urlbarView-title,
    .urlbarView-url {
        padding: 0;
        margin: 0;
    }

    #urlbar[breakout][breakout-extend] {
        box-shadow: 0 var(--uc-spacing-large) calc(var(--uc-spacing-large) * 2) rgba(0, 0, 0, 0.2);
        width: var(--uc-urlbar-width);
        left: 50%;
        right: auto;
        bottom: var(--uc-urlbar-bottom-offset);
        margin: 0;
        position: fixed;
        z-index: 999;
        transform: translateX(-50%);
        max-height: 60vh;
        min-height: calc(var(--tab-height) * 3);
    }
    /* Remove toolbar springs */
    toolbarspring,
    .toolbar-spring,
    [anonid="spring"] {
        display: none;
    }

    #urlbar:not([breakout][breakout-extend]) #urlbar-input,
    #urlbar:not([focused]) #urlbar-input {
        text-align: center;
    }

    #urlbar-background,
    #urlbar-input-container {
        --toolbarbutton-border-radius: 0;
        --urlbar-icon-border-radius: 0;
    }
  '';

  # Generate user.js content for Firefox profile
  userJsContent = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      key: value: let
        jsValue =
          if builtins.isBool value
          then
            (
              if value
              then "true"
              else "false"
            )
          else if builtins.isInt value
          then toString value
          else if builtins.isString value
          then ''"${value}"''
          else toString value;
      in ''user_pref("${key}", ${jsValue});''
    )
    commonSettings
  );

  # Firefox policies.json content
  policiesContent = builtins.toJSON {
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
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.programs.firefox = {
    enable = lib.mkEnableOption "Firefox browser with optimized settings";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.${username}.maid = {
      packages = with pkgs; [
        firefox
      ];

      file.home = {
        # Environment variables
        ".profile".text = lib.mkAfter ''
          # Firefox environment variables
          export MOZ_ENABLE_WAYLAND=1
          export MOZ_USE_XINPUT2=1
        '';

        # Default profile user.js (will be created if profile exists)
        ".mozilla/firefox/${username}.default/user.js".text = userJsContent;

        # Default profile userChrome.css
        ".mozilla/firefox/${username}.default/chrome/userChrome.css".text = userChromeCss;

        # Alternative profile paths (Firefox creates different profile names)
        ".mozilla/firefox/${username}.default-release/user.js".text = userJsContent;
        ".mozilla/firefox/${username}.default-release/chrome/userChrome.css".text = userChromeCss;

        # Firefox Policies (system-wide)
        ".mozilla/firefox/policies/policies.json".text = policiesContent;
      };
    };
  };
}
