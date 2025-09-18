{
  config,
  lib,
  ...
}: let
  username = config.user.name;
  userChromeCss = ''
    /* === CSS VARIABLES === */
    :root {
        /* Base colors */
        --color-bg-primary: #333;
        --color-fg-primary: #fff;
        --color-border-inactive: #f00;
        --color-border-active: #fff;
        --color-transparent: transparent;
        --color-tab-active: rgba(255, 255, 255, 0.2);
        --color-tab-inactive: rgba(255, 255, 255, 0.1);

        /* Typography */
        --font-family: monospace;
        --font-size: 8.25pt;

        /* Spacing system */
        --space-xs: 0.05em;
        --space-sm: 0.1em;
        --space-md: 0.2em;

        /* Element sizing */
        --size-icon: 1em;
        --size-element: 1.6em;
        --size-toolbar: 2.0em;

        /* Layout dimensions */
        --layout-bar-width: 75vw;
        --layout-breakout-width: 50vw;
        --layout-breakout-top: 20vh;

        /* Border properties */
        --border-width: 1.5pt;
        --border-radius: 0pt;
        --border-transition: 0.2s ease;

        /* Shadow system */
        --shadow-popup: 0 11.25pt 22.5pt rgba(0,0,0,.2);

        /* Layout spacing */
        --margin-toolbar: 6pt;
        --margin-tabs: 1.5pt;
        --margin-nav: 3.75pt;
        --margin-browser: 2.5em;
        --margin-label: 1rem;

        /* Padding system */
        --padding-toolbar: 0;
        --padding-nav: 0;
        --padding-label: 0 2px;
        --padding-toolbar-button: 0pt;
        --padding-windows: 7px;

        /* Position offsets */
        --offset-label-bottom: -0.2rem;
        --offset-label-top: -0.9rem;
        --offset-label-margin: -1rem 0.75rem;

        /* Height constraints */
        --height-suggestions: calc(60vh - 30pt);

        /* Tab configuration */
        --tab-block-margin: 0px!important;
        --tab-height: var(--size-element);
        --tab-active-bg: var(--color-tab-active);
        --tab-inactive-bg: var(--color-tab-inactive);
        --tab-active-fg: var(--color-fg-primary);
        --tab-inactive-fg: var(--color-fg-primary);

        /* URL bar configuration */
        --urlbar-height: var(--size-element);
        --urlbar-focused-bg: var(--color-bg-primary);
        --urlbar-bg: var(--color-bg-primary);

        /* Toolbar configuration */
        --toolbar-height: var(--size-toolbar);
        --toolbar-bg: var(--color-bg-primary);
        --icon-size: var(--size-icon);

        /* Legacy spacing names (for compatibility) */
        --spacing-xs: var(--space-xs);
        --spacing-sm: var(--space-sm);
        --spacing-md: var(--space-md);

        /* Layout aliases */
        --bar-width: var(--layout-bar-width);
        --breakout-width: var(--layout-breakout-width);
        --breakout-top: var(--layout-breakout-top);

        /* Firefox internal overrides */
        --toolbarbutton-border-radius: var(--border-radius)!important;
        --toolbarbutton-inner-padding: 0pt var(--spacing-sm)!important;
        --toolbar-field-focus-background-color: var(--urlbar-focused-bg)!important;
        --toolbar-field-background-color: var(--urlbar-bg)!important;
        --toolbar-field-focus-border-color: var(--color-transparent)!important;
        --toolbar-bgcolor: var(--toolbar-bg)!important
    }

    /* === GLOBAL RESETS === */
    /* Disable all animations and transitions */
    * {
        animation: none!important;
        transition: none!important;
        scroll-behavior: auto!important
    }

    /* Main window background theming */
    #browser,#main-window,#navigator-toolbox,#tabbrowser-tabpanels,.browserContainer,.browserStack,body,html {
        background-color: var(--color-bg-primary)!important;
        color: var(--color-fg-primary)!important
    }

    /* === UI ELEMENT REMOVAL === */
    /* Hide unwanted UI elements */
    #statuspanel,.titlebar-buttonbox-container,.titlebar-spacer,.toolbar-spring,.urlbarView-row[label="LibreWolf Suggest"],[anonid=spring],toolbarspring {
        display: none!important
    }

    /* Remove border radius from popups */
    menupopup,panel {
        --panel-border-radius: 0px!important
    }

    menu,menucaption,menuitem {
        border-radius: 0!important
    }

    /* Empty rule for titlebar cleanup */
    .titlebar-buttonbox-container {
    }

    /* === TAB BAR STYLING === */
    /* Main tab toolbar container */
    :root:not([customizing]) #TabsToolbar {
        margin: var(--margin-toolbar) auto var(--margin-tabs)!important;
        width: var(--bar-width)!important;
        border: var(--border-width) solid var(--color-border-inactive)!important;
        border-color: var(--color-border-inactive)!important;
        border-radius: var(--border-radius)!important;
        padding: var(--padding-toolbar)!important;
        min-height: 0!important;
        max-height: none!important;
        transition: border-color 0.2s ease!important
    }

    /* Tab toolbar hover state */
    :root:not([customizing]) #TabsToolbar:focus,:root:not([customizing]) #TabsToolbar:hover {
        border-color: var(--color-border-active)!important
    }

    /* Tab toolbar label */
    :root:not([customizing]) #TabsToolbar::before {
        content: "tabs";
        background-color: var(--toolbar-bg);
        position: absolute;
        left: 50%;
        transform: translateX(-50%);
        bottom: var(--offset-label-bottom);
        padding: var(--padding-label);
        font-size: var(--font-size);
        font-family: var(--font-family);
        color: var(--color-border-inactive);
        transition: color 0.2s ease;
        z-index: 9999!important
    }

    /* Tab toolbar label hover */
    :root:not([customizing]) #TabsToolbar:hover::before {
        color: var(--color-border-active)
    }

    /* Individual tab styling */
    .tabbrowser-tab * {
        margin: 0!important;
        border-radius: 0!important
    }

    .tabbrowser-tab {
        height: var(--tab-height);
        font-size: var(--font-size)!important;
        min-height: 0!important;
        align-items: center!important;
        margin-bottom: 0!important
    }

    /* Tab background colors */
    .tabbrowser-tab:not([selected]) .tab-background {
        background-color: var(--tab-inactive-bg)!important
    }

    .tabbrowser-tab[selected] .tab-background {
        background-color: var(--tab-active-bg)!important
    }

    /* Tab text color */
    .tabbrowser-tab .tab-content {
        color: var(--tab-active-fg)!important
    }

    /* Tab container height reset */
    #tabbrowser-tabs>.tabbrowser-arrowscrollbox {
        min-height: 0!important
    }

    /* Tab toolbar button styling */
    :root:not([customizing]) #TabsToolbar .titlebar-button,:root:not([customizing]) #TabsToolbar-customization-target>.toolbarbutton-1,:root:not([customizing]) #tabbrowser-tabs .tabs-newtab-button,:root:not([customizing]) #tabs-newtab-button {
        -moz-appearance: none!important;
        padding: 0!important;
        -moz-box-align: stretch;
        margin: 0!important
    }

    /* New tab button hover */
    #tabbrowser-tabs .tabs-newtab-button:hover,#tabs-newtab-button:hover {
        background-color: var(--toolbarbutton-hover-background)
    }

    /* New tab button icon */
    #tabbrowser-tabs .tabs-newtab-button>.toolbarbutton-icon,#tabs-newtab-button>.toolbarbutton-icon {
        padding: 0!important;
        transform: scale(1);
        background-color: transparent!important
    }

    /* Tab centering when not overflowing */
    #tabbrowser-arrowscrollbox:not([overflowing]) {
        --uc-flex-justify: center
    }

    scrollbox[orient=horizontal]>slot {
        justify-content: var(--uc-flex-justify, initial)
    }

    /* === NAVIGATION BAR STYLING === */
    /* Navigator toolbox reset */
    #navigator-toolbox {
        margin: 0!important;
        padding: 0!important
    }

    /* Main navigation bar */
    #nav-bar {
        position: fixed!important;
        bottom: 0!important;
        width: var(--bar-width)!important;
        left: 0!important;
        right: 0!important;
        margin: var(--margin-nav) auto!important;
        z-index: 1!important;
        border: var(--border-width) solid var(--color-border-inactive)!important;
        border-color: var(--color-border-inactive)!important;
        border-radius: var(--border-radius)!important;
        transition: border-color 0.2s ease!important;
        padding: var(--padding-nav)!important
    }

    /* Navigation bar flex container */
    #nav-bar-customization-target {
        -webkit-box-flex: 1
    }

    /* Hover states for main elements */
    #browser:focus,#browser:hover,#nav-bar:focus,#nav-bar:hover {
        border-color: var(--color-border-active)!important
    }

    /* Navigation bar label */
    #nav-bar::before {
        content: "nav";
        background-color: var(--toolbar-bg);
        position: absolute;
        left: 50%;
        transform: translateX(-50%);
        top: var(--offset-label-bottom);
        padding: var(--padding-label);
        color: var(--color-border-inactive);
        transition: color 0.2s ease;
        z-index: 9999!important
    }

    /* Label hover states */
    #browser:hover::before,#nav-bar:hover::before {
        color: var(--color-border-active)
    }

    /* === BROWSER CONTENT AREA === */
    /* Main browser and customization containers */
    #browser,#customization-container {
        margin: var(--margin-toolbar) var(--margin-toolbar) var(--margin-browser)!important;
        border: var(--border-width) solid var(--color-border-inactive)!important;
        border-color: var(--color-border-inactive)!important;
        border-radius: var(--border-radius)!important;
        transition: border-color 0.2s ease!important;
        position: relative!important
    }

    /* Remove bottom margin in fullscreen mode */
    :root[inFullscreen] #browser,
    :root[inFullscreen] #customization-container {
        margin-bottom: var(--margin-toolbar)!important
    }

    /* Font inheritance for labels and containers */
    #browser::before,#nav-bar::before,#urlbar-container {
        font-family: var(--font-family);
        font-size: var(--font-size)
    }

    /* Browser content label */
    #browser::before {
        content: "main";
        background-color: var(--toolbar-bg);
        position: absolute;
        margin: var(--offset-label-margin);
        padding: var(--padding-label);
        color: var(--color-border-inactive);
        transition: color 0.2s ease;
        z-index: 9999!important
    }

    /* Panel sizing fix */
    .panel-viewstack {
        max-height: unset!important
    }

    /* === URL BAR STYLING === */
    /* URL bar container */
    #urlbar-container {
        margin: 0!important;
        padding: 0!important
    }

    /* Main URL bar */
    #urlbar {
        min-height: var(--urlbar-height)!important;
        border-color: transparent!important
    }

    /* URL bar input field */
    #urlbar-input {
        margin: 0!important;
        text-align: center!important
    }

    /* URL bar input container */
    #urlbar>.urlbar-input-container {
        padding: 0!important;
        border: 0!important
    }

    /* URL bar text centering */
    #urlbar:not([breakout][breakout-extend]) #urlbar-input,#urlbar:not([focused]) #urlbar-input {
        text-align: center!important
    }

    /* URL bar breakout/popup mode */
    #urlbar[breakout][breakout-extend] {
        width: var(--breakout-width)!important;
        top: var(--breakout-top)!important;
        left: 50%!important;
        position: fixed!important;
        transform: translateX(-50%)!important;
        z-index: 999!important;
        margin: 0!important;
        box-shadow: var(--shadow-popup)
    }

    /* === URL BAR SUGGESTIONS === */
    /* URL bar suggestion view */
    .urlbarView {
        font-size: var(--font-size)!important;
        max-height: var(--height-suggestions)!important;
        overflow-y: auto!important
    }

    /* Individual suggestion rows */
    .urlbarView-row {
        padding-block: 0!important
    }

    .urlbarView-row-inner {
        padding-inline: 0!important
    }

    /* === ICON AND BUTTON STYLING === */
    /* Unified icon sizing */
    .tab-icon-image,.toolbarbutton-icon,.urlbar-icon {
        width: var(--icon-size)!important;
        height: auto!important;
        padding: 0!important
    }

    /* Tab icon spacing */
    .tab-icon-image {
        margin-right: var(--spacing-sm)!important
    }

    /* Toolbar button reset */
    #PersonalToolbar toolbarbutton,#TabsToolbar toolbarbutton,#nav-bar toolbarbutton,.toolbarbutton-1,toolbar .toolbarbutton-1 {
        -moz-appearance: none!important;
        margin: 0!important;
        padding: 0!important
    }

    /* === GENERAL CLEANUP === */
    /* Navigator toolbox appearance */
    #navigator-toolbox {
        border: 0!important;
        appearance: toolbar!important
    }

    /* Toolbar margin/padding reset */
    #TabsToolbar,#titlebar,toolbar {
        margin: 0!important;
        padding: 0!important
    }

    /* Tab container height reset */
    #tabbrowser-arrowscrollbox,#tabbrowser-tabs {
        min-height: 0!important
    }

    /* === PLATFORM-SPECIFIC FIXES === */
    /* Windows 10 maximized window fix */
    @media (-moz-os-version:windows-win10) {
        :root[sizemode=maximized] #navigator-toolbox {
            padding-top: var(--padding-windows)!important
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
