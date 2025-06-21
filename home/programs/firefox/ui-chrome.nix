###############################################################################
# Firefox UserChrome CSS Module
# Custom CSS for minimal Firefox UI with bottom navbar
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.shared) username;

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
    #navigator-toolbox > toolbar {
        -moz-appearance: none;
        background: none;
        border: none;
        box-shadow: none;
    }

    :root[tabsintitlebar] #nav-bar {
        padding-right: 0;
        padding-left: 0;
    }

    :root[tabsintitlebar] #TabsToolbar {
        padding-right: 0;
        padding-left: 0;
    }

    #navigator-toolbox::after {
        display: none;
    }

    #tabbrowser-tabbox {
        height: calc(100vh - var(--uc-bottom-toolbar-height));
    }

    #sidebar-box {
        max-height: calc(100vh - var(--uc-bottom-toolbar-height));
    }

    @media screen and (max-width: 1000px) {
        #nav-bar {
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

    :root[customizing] #nav-bar {
        position: initial;
        width: initial;
        background: var(--toolbar-bgcolor);
    }

    :root[customizing] #browser {
        margin-bottom: 0;
    }

    #urlbar-background,
    #urlbar-input-container {
        --toolbarbutton-border-radius: 0;
        --urlbar-icon-border-radius: 0;
    }
  '';
in {
  config = lib.mkIf config.home.programs.firefox.enable {
    users.users.${username}.maid = {
      file.home = {
        # Default profile userChrome.css
        ".mozilla/firefox/${username}.default/chrome/userChrome.css".text = userChromeCss;
        # Alternative profile paths (Firefox creates different profile names)
        ".mozilla/firefox/${username}.default-release/chrome/userChrome.css".text = userChromeCss;
      };
    };
  };
}
