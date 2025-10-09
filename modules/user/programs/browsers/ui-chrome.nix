{
  config,
  lib,
  ...
}: let
  username = config.user.name;
  userChromeCss = ''
    :root {
        /* Single theme color - change this to customize entire theme */
        --theme-color: #000000;

        /* Transparent white overlays for UI elements */
        --overlay-1: rgba(255, 255, 255, 0.05);
        --overlay-2: rgba(255, 255, 255, 0.1);
        --overlay-3: rgba(255, 255, 255, 0.15);
        --overlay-4: rgba(255, 255, 255, 0.2);

        /* Text colors derived from theme */
        --text-primary: rgba(255, 255, 255, 0.9);
        --text-secondary: rgba(255, 255, 255, 0.5);

        /* Font and base sizing */
        --font-family: 'DejaVu Sans Mono';
        --font-size: 0.6875rem;

        /* Layout dimensions */
        --bar-width: 75vw;
        --breakout-width: 50vw;
        --breakout-top: 20vh;

        /* Derived UI colors */
        --tab-active-bg: rgba(255, 255, 255, 0.2);
        --tab-inactive-bg: rgba(255, 255, 255, 0.1);
        --tab-active-fg: var(--text-primary);
        --tab-inactive-fg: var(--text-secondary);
        --urlbar-focused-bg: var(--overlay-3);
        --urlbar-bg: transparent;
        --toolbar-bg: var(--overlay-1);

        /* Browser variable overrides */
        --toolbarbutton-border-radius: 0px!important;
        --toolbarbutton-inner-padding: 0 0.5em!important;
        --toolbar-field-focus-background-color: var(--urlbar-focused-bg)!important;
        --toolbar-field-background-color: var(--urlbar-bg)!important;
        --toolbar-field-focus-border-color: transparent!important;
        --toolbar-bgcolor: var(--toolbar-bg)!important
    }

    * {
        animation: none!important;
        transition: none!important;
        scroll-behavior: auto!important
    }

    #statuspanel,.titlebar-buttonbox-container,.titlebar-spacer,.toolbar-spring,.urlbarView-row[label="LibreWolf Suggest"],[anonid=spring],toolbarspring {
        display: none!important
    }

    menupopup,panel {
        --panel-border-radius: 0px!important
    }

    menu,menucaption,menuitem {
        border-radius: 0!important
    }

    .titlebar-buttonbox-container {
    }

    :root:not([customizing]) #TabsToolbar {
        margin: 0 auto!important;
        width: var(--bar-width)!important;
        border-radius: 0!important;
        padding: 0!important;
        min-height: 0!important;
        max-height: 1.2em!important
    }

    .tabbrowser-tab * {
        margin: 0!important;
        border-radius: 0!important
    }

    .tabbrowser-tab {
        height: 1.2em;
        font-size: var(--font-size)!important;
        align-items: center!important;
        margin-bottom: 0.2em!important
    }

    #tabbrowser-tabs>.tabbrowser-arrowscrollbox,.tabbrowser-tab {
        min-height: 0!important
    }

    :root:not([customizing]) #TabsToolbar .titlebar-button,:root:not([customizing]) #TabsToolbar-customization-target>.toolbarbutton-1,:root:not([customizing]) #tabbrowser-tabs .tabs-newtab-button,:root:not([customizing]) #tabs-newtab-button {
        -moz-appearance: none!important;
        padding-top: 0!important;
        padding-bottom: 0!important;
        -moz-box-align: stretch;
        margin: 0!important
    }

    #tabbrowser-tabs .tabs-newtab-button:hover,#tabs-newtab-button:hover {
        background-color: var(--toolbarbutton-hover-background)
    }

    #tabbrowser-tabs .tabs-newtab-button>.toolbarbutton-icon,#tabs-newtab-button>.toolbarbutton-icon {
        padding: 0!important;
        transform: scale(1);
        background-color: transparent!important
    }

    #tabbrowser-arrowscrollbox:not([overflowing]) {
        --uc-flex-justify: center
    }

    scrollbox[orient=horizontal]>slot {
        justify-content: var(--uc-flex-justify, initial)
    }

    #nav-bar {
        position: fixed!important;
        bottom: 0!important;
        width: var(--bar-width)!important;
        height: 2.2em!important;
        max-height: 2.2em!important;
        margin: -0.25em auto 0!important;
        border-top: none!important;
        left: 0!important;
        right: 0!important;
        z-index: 1
    }

    #browser {
        margin-bottom: 2.2em!important
    }

    :root[inFullscreen] #nav-bar {
        display: none!important
    }

    :root[inFullscreen] #browser {
        margin-bottom: 0!important
    }

    #urlbar-container {
        font-family: var(--font-family);
        font-size: var(--font-size);
        margin: 0!important;
        padding: 0!important
    }

    #urlbar {
        min-height: 2.4em!important;
        border-color: transparent!important
    }

    #urlbar-input {
        margin: 0 1em!important;
        text-align: center!important
    }

    #urlbar>.urlbar-input-container {
        padding: 0!important;
        border: 0!important
    }

    #urlbar[breakout][breakout-extend] {
        width: var(--breakout-width)!important;
        top: var(--breakout-top)!important;
        left: 50%!important;
        position: fixed!important;
        transform: translateX(-50%)!important;
        z-index: 999!important;
        margin: 0!important;
        box-shadow: 0 15px 30px rgba(0,0,0,.2);
        background-color: var(--theme-color)!important
    }

    .urlbarView {
        font-size: var(--font-size)!important;
        max-height: 60vh!important;
        overflow-y: auto!important
    }

    .urlbarView-row * {
        padding: 0!important;
        margin: 0!important
    }

    .tab-icon-image,.toolbarbutton-icon,.urlbar-icon {
        width: 0.8em!important;
        height: auto!important;
        padding: 0!important
    }

    .tab-icon-image {
        margin-right: 0.3em!important
    }

    #PersonalToolbar toolbarbutton,#TabsToolbar toolbarbutton,#nav-bar toolbarbutton,.toolbarbutton-1,toolbar .toolbarbutton-1 {
        -moz-appearance: none!important;
        margin: 0!important;
        padding: 0 0.5em!important
    }

    #navigator-toolbox {
        border: 0!important;
        appearance: toolbar!important
    }

    #TabsToolbar,#titlebar,toolbar {
        margin: 0!important;
        padding: 0!important
    }

    #tabbrowser-arrowscrollbox,#tabbrowser-tabs {
        min-height: 0!important
    }

    @media (-moz-os-version:windows-win10) {
        :root[sizemode=maximized] #navigator-toolbox {
            padding-top: 0.5em!important
        }
    }
  '';
in {
  config = lib.mkIf config.user.programs.librewolf.enable {
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
