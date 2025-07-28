{
  config,
  lib,
  ...
}: let
  username = config.user.name;
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
    :root[tabsintitlebar]
        transition: none;
    }
    /* Rest of your existing CSS */
    .titlebar-buttonbox-container {
        display: var(--show-titlebar-buttons)
    }
    :root:not([customizing])
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
        min-height: 0;
    }
    :root:not([customizing])
    :root:not([customizing])
    :root:not([customizing])
    :root:not([customizing])
        -moz-appearance: none;
        padding-top: 0;
        padding-bottom: 0;
        -moz-box-align: stretch;
        margin: 0;
    }
        background-color: var(--toolbarbutton-hover-background);
    }
        padding: 0;
        transform: scale(0.6);
        background-color: transparent;
    }
    @media (-moz-os-version: windows-win10) {
        :root[sizemode=maximized]
            padding-top: calc(var(--uc-spacing-large) + var(--uc-spacing-medium));
        }
    }
        position: fixed;
        bottom: 0;
        width: var(--uc-navbar-width);
        height: var(--uc-bottom-toolbar-height);
        max-height: var(--uc-bottom-toolbar-height);
        margin: calc(-1 * var(--uc-spacing-small)) auto 0;
        border-top: none;
        left: 0;
        right: 0;
        z-index: 3;
    }
        margin-bottom: var(--uc-bottom-toolbar-height);
    }
        --uc-flex-justify: center
    }
    scrollbox[orient=horizontal]>slot {
        justify-content: var(--uc-flex-justify, initial)
    }
        height: var(--tab-height);
    }
        min-height: var(--tab-height);
    }
        min-height: 0;
    }
        height: auto;
    }
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
        -moz-appearance: none;
        background: none;
        border: none;
        box-shadow: none;
    }
    :root[tabsintitlebar]
        padding-right: 0;
        padding-left: 0;
    }
    :root[tabsintitlebar]
        padding-right: 0;
        padding-left: 0;
    }
        display: none;
    }
        height: calc(100vh - var(--uc-bottom-toolbar-height));
    }
        max-height: calc(100vh - var(--uc-bottom-toolbar-height));
    }
    @media screen and (max-width: 1000px) {
            width: 100vw;
        }
        :root {
            --uc-navbar-width: 100vw;
        }
    }
    .tab-content {
        padding-inline-start: var(--uc-spacing-small);
        padding-inline-end: var(--uc-spacing-small);
    }
    .tab-label {
        margin-inline-end: 0;
    }
    .tab-icon-sound {
        margin-inline-start: var(--uc-spacing-small);
    }
    :root[customizing]
        position: initial;
        width: initial;
        background: var(--toolbar-bgcolor);
    }
    :root[customizing]
        margin-bottom: 0;
    }
        --toolbarbutton-border-radius: 0;
        --urlbar-icon-border-radius: 0;
        backdrop-filter: blur(10px);
        background-color: transparent !important;
    }
        --toolbarbutton-border-radius: 0;
        --urlbar-icon-border-radius: 0;
    }
  '';
in {
  config = lib.mkIf config.home.programs.firefox.enable {
    hjem.users.${username} = {
      files = {
        ".mozilla/firefox/${username}.default/chrome/userChrome.css" = {
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
