{
  userChromeCss = ''
    :root {
        /* Firefox Theme API vars (set by pywalfox, fallback to defaults) */
        --theme-frame: var(--lwt-accent-color, #000000);
        --theme-toolbar: var(--toolbar-bgcolor, var(--theme-frame));
        --theme-tab-selected: var(--lwt-selected-tab-background-color, var(--theme-toolbar));
        --theme-toolbar-field: var(--toolbar-field-background-color, var(--theme-toolbar));
        --theme-tab-text: var(--tab-text-color, var(--lwt-tab-text, #ffffff));
        --theme-field-text: var(--toolbar-field-color, var(--theme-tab-text));
        --theme-icon: var(--lwt-toolbarbutton-icon-fill, #ffffff);

        --font-family: 'DejaVu Sans Mono';
        --font-size: 0.6875rem;
        --bar-width: 75vw;
        --bar-height: 1.2em;
        --breakout-width: 50vw;
        --breakout-top: 20vh
    }

    /* Force frame background on root and titlebar areas */
    :root, #titlebar, #TabsToolbar-customization-target {
        background-color: var(--theme-frame)!important
    }

    * {
        border-radius: 0!important
    }

    @media (prefers-reduced-motion:reduce) {
        * {
            animation: none!important;
            transition: none!important;
            scroll-behavior: auto!important
        }
    }

    #statuspanel,.titlebar-buttonbox-container,.titlebar-spacer,.toolbar-spring,.urlbarView-row[label="LibreWolf Suggest"],[anonid=spring],toolbarspring {
        display: none!important
    }

    menupopup,panel {
        --panel-border-radius: 0px!important
    }

    :root:not([customizing]) #TabsToolbar {
        margin: 0 auto!important;
        width: var(--bar-width)!important;
        padding: 0!important;
        min-height: 0!important;
        max-height: var(--bar-height)!important;
        background-color: var(--theme-frame)!important
    }

    .tabbrowser-tab * {
        margin: 0!important
    }

    .tabbrowser-tab {
        height: var(--bar-height)!important;
        font-size: var(--font-size)!important;
        align-items: center!important;
        margin-bottom: .2em!important;
        background-color: var(--theme-frame)!important
    }

    .tabbrowser-tab[selected="true"],.tabbrowser-tab[visuallyselected="true"],.tabbrowser-tab[selected="true"] .tab-background,.tabbrowser-tab[visuallyselected="true"] .tab-background {
        background-color: var(--theme-tab-selected)!important
    }

    #tabbrowser-tabs>.tabbrowser-arrowscrollbox,.tabbrowser-tab {
        min-height: 0!important
    }

    :root:not([customizing]) #TabsToolbar .titlebar-button,:root:not([customizing]) #TabsToolbar-customization-target>.toolbarbutton-1,:root:not([customizing]) #tabbrowser-tabs .tabs-newtab-button,:root:not([customizing]) #tabs-newtab-button {
        -moz-appearance: none!important;
        padding-top: 0!important;
        padding-bottom: 0!important;
        -moz-box-align: stretch!important;
        margin: 0!important
    }

    #tabbrowser-tabs .tabs-newtab-button:hover,#tabs-newtab-button:hover {
        background-color: var(--toolbarbutton-hover-background)!important
    }

    #tabbrowser-tabs .tabs-newtab-button>.toolbarbutton-icon,#tabs-newtab-button>.toolbarbutton-icon {
        padding: 0!important;
        transform: scale(1)!important;
        background-color: transparent!important
    }

    #tabbrowser-arrowscrollbox:not([overflowing]) {
        --uc-flex-justify: center!important
    }

    scrollbox[orient=horizontal]>slot {
        justify-content: var(--uc-flex-justify, initial)!important
    }

    #nav-bar {
        position: fixed!important;
        bottom: 0!important;
        width: var(--bar-width)!important;
        height: var(--bar-height)!important;
        max-height: var(--bar-height)!important;
        margin: -.25em auto 0!important;
        border-top: none!important;
        left: 0!important;
        right: 0!important;
        z-index: 1!important;
        background-color: var(--theme-frame)!important
    }

    #browser {
        margin-bottom: var(--bar-height)!important
    }

    :root[inFullscreen] #nav-bar {
        display: none!important
    }

    :root[inFullscreen] #browser {
        margin-bottom: 0!important
    }

    #urlbar-container {
        font-family: var(--font-family)!important;
        font-size: var(--font-size)!important;
        margin: 0!important;
        padding: 0!important
    }

    #urlbar {
        min-height: var(--bar-height)!important;
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
        box-shadow: 0 15px 30px rgba(0,0,0,.2)!important;
        background-color: var(--theme-toolbar-field)!important
    }

    .urlbarView {
        font-size: var(--font-size)!important;
        max-height: 60vh!important;
        overflow-y: auto!important;
        bottom: 100%!important;
        top: auto!important
    }

    .urlbarView-row * {
        padding: 0!important;
        margin: 0!important
    }

    .tab-icon-image,.toolbarbutton-icon,.urlbar-icon {
        width: .8em!important;
        height: auto!important;
        padding: 0!important
    }

    .tab-icon-image {
        margin-right: .3em!important
    }

    #PersonalToolbar toolbarbutton,#TabsToolbar toolbarbutton,#nav-bar toolbarbutton,.toolbarbutton-1,toolbar .toolbarbutton-1 {
        -moz-appearance: none!important;
        margin: 0!important;
        padding: 0 .5em!important
    }

    #navigator-toolbox {
        border: 0!important;
        appearance: toolbar!important;
        background-color: var(--theme-frame)!important
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
            padding-top: .5em!important
        }
    }
  '';
}
