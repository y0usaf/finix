{
  config,
  lib,
  ...
}: let
  username = config.user.name;
  userChromeCss = ''
    :root {
        /* Tab behavior */
        --tab-block-margin: 0px !important;

        /* Theme colors */
        --tab-active-bg: #057;
        --tab-inactive-bg: #333;
        --tab-active-fg: #eee;
        --tab-inactive-fg: #888;
        --urlbar-focused-bg: #41404c;
        --urlbar-bg: #1c1b22;
        --toolbar-bg: #2b2a33;

        /* Typography */
        --font-family: 'DejaVu Sans Mono';
        --font-size: 11px;

        /* Sizing (text-relative) */
        --tab-height: 1.6em;
        --urlbar-height: 1.6em;
        --toolbar-height: 1.4em;
        --icon-size: 1em;

        /* Spacing (text-relative) */
        --spacing-xs: 0.05em;
        --spacing-sm: 0.1em;
        --spacing-md: 0.2em;

        /* Layout */
        --bar-width: 75vw;
        --breakout-width: 50vw;
        --breakout-top: 20vh;

        /* Browser overrides */
        --toolbarbutton-border-radius: 0px !important;
        --toolbarbutton-inner-padding: 0px var(--spacing-sm) !important;
        --toolbar-field-focus-background-color: var(--urlbar-focused-bg) !important;
        --toolbar-field-background-color: var(--urlbar-bg) !important;
        --toolbar-field-focus-border-color: transparent !important;
        --toolbar-bgcolor: var(--toolbar-bg) !important;
    }

    /* --- ANIMATION CONTROL -------------------------------- */
    * {
        animation: none !important;
        transition: none !important;
        scroll-behavior: auto !important;
    }

    /* --- GENERAL DEBLOAT ---------------------------------- */
    #statuspanel,
    .titlebar-buttonbox-container,
    .titlebar-spacer,
    toolbarspring,
    .toolbar-spring,
    [anonid="spring"],
    .urlbarView-row[label="LibreWolf Suggest"] {
        display: none !important;
    }

    /* Remove radius from popups */
    menupopup, panel { --panel-border-radius: 0px !important; }
    menu, menuitem, menucaption { border-radius: 0px !important; }

    /* --- TAB STYLING --------------------------------------- */
    .titlebar-buttonbox-container {
        display: none;
    }

    :root:not([customizing]) #TabsToolbar {
        margin: 0 auto !important;
        width: var(--bar-width) !important;
        border-radius: 0 !important;
        padding: 0 !important;
        min-height: 0 !important;
        max-height: var(--tab-height) !important;
    }

    .tabbrowser-tab * {
        margin: 0 !important;
        border-radius: 0 !important;
    }

    .tabbrowser-tab {
        height: var(--tab-height);
        font-size: var(--font-size) !important;
        min-height: 0 !important;
        align-items: center !important;
        margin-bottom: var(--spacing-sm) !important;
    }

    .tab-icon-image {
        height: auto !important;
        width: var(--icon-size) !important;
        margin-right: var(--spacing-sm) !important;
    }

    #tabbrowser-arrowscrollbox,
    #tabbrowser-tabs,
    #tabbrowser-tabs > .tabbrowser-arrowscrollbox {
        min-height: 0 !important;
    }

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
        transform: scale(1.0);
        background-color: transparent !important;
    }

    /* Tab centering */
    #tabbrowser-arrowscrollbox:not([overflowing]) { --uc-flex-justify: center; }
    scrollbox[orient=horizontal]>slot { justify-content: var(--uc-flex-justify, initial); }

    /* --- NAVBAR STYLING ----------------------------------- */
    #nav-bar {
        position: fixed !important;
        bottom: 0 !important;
        width: var(--bar-width) !important;
        height: var(--toolbar-height) !important;
        max-height: var(--toolbar-height) !important;
        margin: calc(-1 * var(--spacing-xs)) auto 0 !important;
        border-top: none !important;
        left: 0 !important;
        right: 0 !important;
        z-index: 1;
    }

    #browser { margin-bottom: var(--toolbar-height) !important; }

    /* Hide navbar and expand content in fullscreen */
    :root[inFullscreen] #nav-bar {
        display: none !important;
    }

    :root[inFullscreen] #browser {
        margin-bottom: 0 !important;
    }

    /* Urlbar styling */
    #urlbar-container {
        font-family: var(--font-family);
        font-size: var(--font-size);
        margin: 0 !important;
        padding: 0 !important;
    }

    #urlbar {
        min-height: var(--urlbar-height) !important;
        border-color: transparent !important;
    }

    #urlbar-input {
        margin: 0 var(--spacing-md) !important;
    }

    #urlbar > .urlbar-input-container {
        padding: 0 !important;
        border: 0 !important;
    }

    /* Center urlbar text always */
    #urlbar-input {
        text-align: center !important;
    }

    /* Breakout urlbar */
    #urlbar[breakout][breakout-extend] {
        width: var(--breakout-width) !important;
        top: var(--breakout-top) !important;
        left: 50% !important;
        position: fixed !important;
        transform: translateX(-50%) !important;
        z-index: 999 !important;
        margin: 0 !important;
        box-shadow: 0 15px 30px rgba(0,0,0,.2);
    }

    /* Urlbar view */
    .urlbarView {
        font-size: var(--font-size) !important;
        max-height: calc(60vh - 40px) !important;
        overflow-y: auto !important;
    }

    /* Remove spacing from urlbar suggestions */
    .urlbarView-row * {
        padding: 0 !important;
        margin: 0 !important;
    }

    /* --- ICON AND BUTTON STYLING -------------------------- */
    .tab-icon-image,
    .toolbarbutton-icon,
    .urlbar-icon {
        width: var(--icon-size) !important;
        height: auto !important;
        padding: 0 !important;
    }

    .tab-icon-image { margin-right: var(--spacing-sm) !important; }

    /* Button cleanup */
    toolbar .toolbarbutton-1,
    .toolbarbutton-1,
    #PersonalToolbar toolbarbutton,
    #TabsToolbar toolbarbutton,
    #nav-bar toolbarbutton {
        -moz-appearance: none !important;
        margin: 0 !important;
        padding: 0 var(--spacing-sm) !important;
    }

    /* --- GENERAL CLEANUP ---------------------------------- */
    #navigator-toolbox {
        border: none !important;
        appearance: toolbar !important;
    }

    #titlebar,
    #TabsToolbar,
    toolbar {
        margin: 0 !important;
        padding: 0 !important;
    }

    #tabbrowser-tabs,
    #tabbrowser-arrowscrollbox {
        min-height: 0 !important;
    }

    /* Windows-specific */
    @media (-moz-os-version:windows-win10) {
        :root[sizemode=maximized] #navigator-toolbox {
            padding-top: 7px !important;
        }
    }
  '';
in {
  config = lib.mkIf config.home.programs.librewolf.enable {
    hjem.users.${username} = {
      files = {
        ".librewolf/${username}/chrome/userChrome.css" = {
          text = userChromeCss;
          clobber = true;
        };
      };
    };
  };
}
