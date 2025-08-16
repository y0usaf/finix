{
  config,
  lib,
  ...
}: let
  username = config.user.name;
  userChromeCss = ''
    /* Disable all animations */
    * {
      animation: none !important;
      transition: none !important;
      scroll-behavior: auto !important;
      padding: 0 !important;
      margin: 0 !important;
    }

    :root {
        --tab-font-size: 0.8em;
        --max-tab-width: none;
        --show-titlebar-buttons: none;
        --tab-height: 12pt;
        --toolbar-icon-size: calc(var(--tab-height) / 1.5);
        --uc-bottom-toolbar-height: 12pt
    }

    /* Disable specific Firefox animations */
    @media (prefers-reduced-motion: no-preference) {
      * {
        animation-duration: 0.001s !important;
        transition-duration: 0.001s !important;
      }
    }

    /* Disable smooth scrolling */
    html {
      scroll-behavior: auto !important;
    }

    /* Disable tab animations */
    .tabbrowser-tab {
      transition: none !important;
    }

    /* Disable toolbar animations */
    :root[tabsintitlebar] #toolbar-menubar[autohide=true][inactive] {
        transition: none !important;
    }

    /* Rest of your existing CSS */
    .titlebar-buttonbox-container {
        display: var(--show-titlebar-buttons)
    }

    :root:not([customizing]) #TabsToolbar {
        margin-left: 1pt!important;
        margin-right: 1pt!important;
        border-radius: 0!important;
        padding: 0!important;
        min-height: 0!important
    }

    .tabbrowser-tab * {
        margin: 0!important;
        border-radius: 0!important
    }

    .tabbrowser-tab {
        height: var(--tab-height);
        font-size: var(--tab-font-size)!important;
        min-height: 0!important;
        align-items: center!important;
        margin-bottom: 2pt!important
    }

    .tab-icon-image {
        height: auto!important;
        width: var(--toolbar-icon-size)!important;
        margin-right: 2pt!important
    }

    #tabbrowser-arrowscrollbox,#tabbrowser-tabs,#tabbrowser-tabs>.tabbrowser-arrowscrollbox {
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
        transform: scale(.6);
        background-color: transparent!important
    }

    @media (-moz-os-version:windows-win10) {
        :root[sizemode=maximized] #navigator-toolbox {
            padding-top: 7pt!important
        }
    }

    #nav-bar {
        position: fixed!important;
        bottom: 0!important;
        width: 100%!important;
        height: var(--uc-bottom-toolbar-height)!important;
        max-height: var(--uc-bottom-toolbar-height)!important;
        z-index: 1
    }

    #browser {
        margin-bottom: var(--uc-bottom-toolbar-height)!important
    }

    #tabbrowser-arrowscrollbox:not([overflowing]) {
        --uc-flex-justify: center
    }

    scrollbox[orient=horizontal]>slot {
        justify-content: var(--uc-flex-justify, initial)
    }

    #urlbar,#urlbar-input-container {
        height: var(--tab-height)!important
    }

    #urlbar,#urlbar[open] {
        min-height: var(--tab-height)!important
    }

    #urlbar-input-container {
        min-height: 0!important
    }

    #urlbar[open],#urlbar[open] #urlbar-input-container {
        height: auto!important
    }

    #identity-icon,#page-action-buttons img,#permissions-granted-icon,#star-button-box,#tracking-protection-icon,.searchbar-search-icon,.urlbar-page-action {
        height: auto!important;
        width: var(--toolbar-icon-size)!important;
        padding: 0!important
    }

    .toolbarbutton-1 {
        padding: 0 2pt!important
    }

    .toolbarbutton-1,.toolbarbutton-icon {
        -moz-appearance: none!important;
        padding-inline: 1pt!important;
        -moz-box-align: stretch;
        margin: 0!important
    }

    #PersonalToolbar toolbarbutton,#TabsToolbar toolbarbutton,#nav-bar toolbarbutton,.titlebar-button,.toolbaritem-combined-buttons {
        -moz-appearance: none!important;
        padding-top: 0!important;
        padding-bottom: 0!important;
        padding-inline: 1pt!important;
        -moz-box-align: stretch;
        margin: 0!important
    }

    .tab-close-button,.urlbar-icon,.urlbar-page-action {
        -moz-appearance: none!important;
        padding-inline: 1pt!important;
        -moz-box-align: stretch;
        margin: 0!important
    }

    .urlbar-page-action {
        padding-top: 0!important;
        padding-bottom: 0!important
    }

    .tab-close-button,.titlebar-button>image,.toolbarbutton-icon,.urlbar-icon,.urlbar-page-action>image {
        padding: 0!important;
        width: var(--toolbar-icon-size)!important;
        height: auto!important
    }

    #navigator-toolbox,.urlbarView {
        margin: 0!important;
        padding: 0!important
    }

    #navigator-toolbox {
        appearance: toolbar!important
    }

    #nav-bar {
        margin: -1pt auto 0!important;
        border-top: none!important;
        width: 75vw!important;
        left: 0!important;
        right: 0!important;
    }

    #titlebar {
        -moz-appearance: none!important;
        padding-bottom: 0!important
    }

    #TabsToolbar,#titlebar,toolbar {
        margin-bottom: 0!important
    }

    #TabsToolbar {
        padding-bottom: 0!important
    }

    toolbar {
        margin-top: 0!important;
        padding: 0!important
    }

    .urlbarView {
        font-size: var(--tab-font-size)!important;
        max-height: calc(60vh - 40pt)!important;
        overflow-y: auto!important
    }

    .urlbarView-row {
        padding-block: 1px!important
    }

    .urlbarView-row-inner {
        padding-inline: 2px!important
    }

    .urlbarView-row[label="Firefox Suggest"] {
        margin-top: 0 !important;
        overflow: hidden !important;
        display: none !important; /* Hide completely */
    }

    .urlbarView-secondary,.urlbarView-title,.urlbarView-url {
        padding: 0!important;
        margin: 0!important
    }

    #urlbar[breakout][breakout-extend] {
        box-shadow: 0 15pt 30pt rgba(0,0,0,.2);
        width: 50vw!important;
        left: 50%!important;
        right: auto!important;
        top: 20vh!important;
        margin: 0!important;
        position: fixed!important;
        z-index: 999!important;
        transform: translateX(-50%)!important;
        max-height: 60vh!important;
        min-height: 40pt!important
    }
    /* Remove toolbar springs */
    toolbarspring, .toolbar-spring, [anonid="spring"] {
      display: none !important;
    }

    #urlbar:not([breakout][breakout-extend]) #urlbar-input,#urlbar:not([focused]) #urlbar-input {
        text-align: center!important;
    }

    #urlbar-background,#urlbar-input-container {
        --toolbarbutton-border-radius: 0pt!important;
        --urlbar-icon-border-radius: 0pt!important
    }  '';
in {
  config = lib.mkIf config.home.programs.firefox.enable {
    hjem.users.${username} = {
      files = {
        ".mozilla/firefox/${username}/chrome/userChrome.css" = {
          text = userChromeCss;
          clobber = true;
        };
        ".mozilla/firefox/${username}.default-release/chrome/userChrome.css" = {
          text = userChromeCss;
          clobber = true;
        };
      };
    };
  };
}
