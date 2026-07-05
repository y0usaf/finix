_:
# Shared Firefox-family chrome CSS.
{
  config.user.programs.browser.shared = {
    userChromeCss = ''
      :root {
          --theme-frame: var(--lwt-accent-color, #000000);
          --theme-toolbar: var(--toolbar-bgcolor, var(--theme-frame));
          --theme-tab-selected: var(--lwt-selected-tab-background-color, var(--theme-toolbar));
          --theme-toolbar-field: var(--toolbar-field-background-color, var(--theme-toolbar));
          --theme-tab-text: var(--tab-text-color, var(--lwt-tab-text, #ffffff));
          --font-family: monospace;
          /* Thin-chrome sizing: everything derives from --chrome-font-size.
             Bar height = one line of text plus --bar-pad above and below;
             shrink or grow the chrome by touching these two values only. */
          --chrome-font-size: 11px;
          --bar-pad: 2px;
          --bar-width: 75vw;
          --bar-height: calc(var(--chrome-font-size) + 2 * var(--bar-pad) + 2px);
          --breakout-width: 50vw;
          --breakout-top: 20vh;
          --popup-offset-top: calc(var(--breakout-top) - 100vh);
          /* Collapse Firefox's own density floors so internal layout math
             follows the thin bars instead of fighting them. */
          --tab-min-height: var(--bar-height) !important;
          --urlbar-min-height: var(--bar-height) !important;
          --urlbar-height: var(--bar-height) !important;
          --urlbar-container-height: var(--bar-height) !important;
          --toolbarbutton-inner-padding: var(--bar-pad) !important;
          --toolbarbutton-outer-padding: 0px !important;
          --toolbar-start-end-padding: 0px !important;
          --tab-block-margin: 0px !important;
          --tab-inline-padding: 0.25em !important;
      }

      /* Chrome-wide font size: keeps text legible while the bars shrink
         around it. Content area is unaffected. */
      #TabsToolbar,
      #nav-bar,
      #titlebar {
          font-size: var(--chrome-font-size) !important;
      }

      /* Load-bearing layout hack: dissolve #navigator-toolbox so its children
         become direct flex siblings of #browser inside #main-window > body,
         then reorder them: menubar on top, titlebar/tabs above content,
         nav-bar below content. Everything below depends on this. */
      #navigator-toolbox {
          display: contents !important;
      }

      #toolbar-menubar {
          order: -2 !important;
      }

      #titlebar {
          order: -1 !important;
          background-color: var(--theme-frame) !important;
          min-height: var(--bar-height) !important;
          max-height: var(--bar-height) !important;
      }

      #main-window > body > #browser {
          order: 0 !important;
      }

      #nav-bar {
          order: 1 !important;
          width: var(--bar-width) !important;
          height: var(--bar-height) !important;
          margin: 0 auto !important;
          border: 0 !important;
          background-color: var(--theme-frame) !important;
      }

      #PersonalToolbar {
          display: none !important;
      }

      /* With #nav-bar moved below the content area, top-anchored panels still
         anchor near the bottom of the window; drag them up to the breakout
         urlbar's position (top: var(--breakout-top), see #urlbar[breakout]). */
      @media (-moz-platform: linux) {
          #notification-popup[side="top"],
          #permission-popup[side="top"],
          #customizationui-widget-panel[side="top"] {
              margin-top: var(--popup-offset-top) !important;
          }
      }

      .panel-viewstack {
          max-height: unset !important;
      }

      #TabsToolbar-customization-target,
      :root {
          background-color: var(--theme-frame) !important;
      }

      /* Square corners everywhere, via theme variables rather than a
         universal selector. */
      :root,
      menupopup,
      panel,
      toolbar {
          --panel-border-radius: 0px !important;
          --arrowpanel-border-radius: 0px !important;
          --toolbarbutton-border-radius: 0px !important;
          --tab-border-radius: 0px !important;
          --urlbar-border-radius: 0px !important;
          --border-radius-medium: 0px !important;
          --border-radius-small: 0px !important;
      }

      #urlbar,
      #urlbar-background,
      .tab-background,
      .toolbarbutton-1,
      .urlbarView-row {
          border-radius: 0 !important;
      }

      @media (prefers-reduced-motion: reduce) {
          * {
              animation: none !important;
              transition: none !important;
              scroll-behavior: auto !important;
          }
      }

      #statuspanel,
      .titlebar-buttonbox-container,
      .titlebar-spacer,
      .toolbar-spring,
      .urlbarView-row[label="LibreWolf Suggest"],
      toolbarspring {
          display: none !important;
      }

      :root:not([customizing]) #TabsToolbar {
          margin: 0 auto !important;
          width: var(--bar-width) !important;
          padding: 0 !important;
          min-height: 0 !important;
          max-height: var(--bar-height) !important;
          background-color: var(--theme-frame) !important;
      }

      #TabsToolbar,
      #titlebar,
      toolbar {
          margin: 0 !important;
          padding: 0 !important;
      }

      #tabbrowser-arrowscrollbox,
      #tabbrowser-tabs,
      #tabbrowser-tabs > .tabbrowser-arrowscrollbox,
      .tabbrowser-tab {
          min-height: 0 !important;
      }

      #tabbrowser-arrowscrollbox:not([overflowing]) {
          --uc-flex-justify: center !important;
      }

      scrollbox[orient="horizontal"] > slot {
          justify-content: var(--uc-flex-justify, initial) !important;
      }

      .tabbrowser-tab {
          height: var(--bar-height) !important;
          align-items: center !important;
          margin-bottom: 0 !important;
          background-color: var(--theme-frame) !important;
      }

      .tabbrowser-tab .tab-content,
      .tabbrowser-tab .tab-background,
      .tabbrowser-tab .tab-stack {
          margin: 0 !important;
      }

      .tabbrowser-tab[selected="true"],
      .tabbrowser-tab[selected="true"] .tab-background,
      .tabbrowser-tab[visuallyselected="true"],
      .tabbrowser-tab[visuallyselected="true"] .tab-background {
          background-color: var(--theme-tab-selected) !important;
      }

      #PersonalToolbar toolbarbutton,
      #TabsToolbar toolbarbutton,
      #nav-bar toolbarbutton,
      .toolbarbutton-1,
      toolbar .toolbarbutton-1,
      :root:not([customizing]) #TabsToolbar .titlebar-button,
      :root:not([customizing]) #tabbrowser-tabs .tabs-newtab-button,
      :root:not([customizing]) #tabs-newtab-button {
          -moz-appearance: none !important;
          margin: 0 !important;
          padding: 0 0.25em !important;
      }

      /* Icons track the chrome font size (1em = --chrome-font-size inside the
         bars) so they stay legible as the bars thin out. */
      .tab-icon-image,
      .toolbarbutton-icon,
      .urlbar-icon {
          width: 1em !important;
          height: auto !important;
          padding: 0 !important;
      }

      .tab-icon-image {
          margin-right: 0.3em !important;
      }

      #urlbar-container {
          font-family: var(--font-family) !important;
          margin: 0 !important;
          padding: 0 !important;
      }

      #urlbar {
          min-height: var(--bar-height) !important;
          border-color: transparent !important;
      }

      /* Docked urlbar hugs the thin bar; the breakout overlay below opts back
         into a comfortable size for actual typing. */
      #urlbar:not([breakout-extend]) {
          height: var(--bar-height) !important;
      }

      #urlbar:not([breakout-extend]) > .urlbar-input-container {
          height: var(--bar-height) !important;
          min-height: var(--bar-height) !important;
      }

      #urlbar-input {
          margin: 0 0.5em !important;
          text-align: center !important;
      }

      #urlbar > .urlbar-input-container {
          padding: 0 !important;
          border: 0 !important;
      }

      #urlbar[breakout][breakout-extend] {
          width: var(--breakout-width) !important;
          top: var(--breakout-top) !important;
          left: 50% !important;
          position: fixed !important;
          transform: translateX(-50%) !important;
          z-index: 999 !important;
          margin: 0 !important;
          box-shadow: 0 15px 30px rgba(0, 0, 0, 0.2) !important;
          background-color: var(--theme-toolbar-field) !important;
          font-size: calc(var(--chrome-font-size) * 1.3) !important;
      }

      .urlbarView {
          max-height: 60vh !important;
          overflow-y: auto !important;
          bottom: 100% !important;
          top: auto !important;
      }

      .urlbarView-row * {
          padding: 0 !important;
          margin: 0 !important;
      }

      :root[inFullscreen] #nav-bar {
          display: none !important;
      }
    '';
  };
}
