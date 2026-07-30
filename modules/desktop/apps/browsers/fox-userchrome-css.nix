_:
# Shared Firefox-family chrome CSS.
{
  config.user.programs.browser.shared = {
    userChromeCss = ''
      :root {
          --theme-frame: var(--lwt-accent-color, light-dark(#ffffff, #000000));
          --theme-toolbar: var(--toolbar-bgcolor, var(--theme-frame));
          --theme-tab-selected: var(--lwt-selected-tab-background-color, var(--theme-toolbar));
          --theme-toolbar-field: var(--toolbar-field-background-color, var(--theme-toolbar));
          --theme-tab-text: var(--tab-text-color, var(--lwt-tab-text, light-dark(#000000, #ffffff)));
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
          /* Suggestion-list sizing. The breakout urlbar sets font-size to
             1.3x --chrome-font-size and .urlbarView inherits it, so row
             heights must be expressed in em to track that. Firefox gives
             .urlbarView-title and .urlbarView-url line-height: 1.4
             (view-nova.css:581, :785), hence the 1.4em term. */
          --urlbarview-row-pad: 0.35em;
          --urlbarview-row-min: calc(1.4em + 2 * var(--urlbarview-row-pad));
          /* Zeroed here rather than on .urlbarView-row because Firefox derives
             --urlbarView-row-border from it on :root, and a custom property's
             var() references resolve on the element that declares it. */
          --urlbarView-row-gutter: 0px !important;
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

      /* Borrowed from Zen: with #nav-bar pinned to var(--bar-width), a wide
         child (searchbar, extension button row) would otherwise force the bar
         to overflow instead of flexing. min-width:0 lets flex shrink win. */
      #nav-bar-customization-target {
          min-width: 0 !important;
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
         universal selector.

         Nova (browser.nova.enabled, Fx 152+) redefines the design tokens in
         @layer tokens-foundation-nova, so the classic --border-radius-medium
         path is no longer what the urlbar uses. Ground truth from omni.ja:
           tokens-shared.css:693-728  --border-radius-large: 12px
                                      --border-radius-xlarge: 16px
                                      --border-radius-xxlarge: 24px
                                      --button-border-radius: xxlarge (was medium)
           urlbar/tokens.css:15,29    --urlbar-border-radius: button-border-radius
                                      --urlbarview-border-radius: 1.8462em
         Zeroing only medium/small left the 24px pill intact. */
      :root,
      menupopup,
      panel,
      toolbar {
          --panel-border-radius: 0px !important;
          --arrowpanel-border-radius: 0px !important;
          --toolbarbutton-border-radius: 0px !important;
          --tab-border-radius: 0px !important;
          --urlbar-border-radius: 0px !important;
          --border-radius-small: 0px !important;
          --border-radius-medium: 0px !important;
          --border-radius-large: 0px !important;
          --border-radius-xlarge: 0px !important;
          --border-radius-xxlarge: 0px !important;
          --button-border-radius: 0px !important;
          --urlbarview-border-radius: 0px !important;
          --urlbar-inner-border-radius: 0px !important;
          --urlbarView-row-border-radius: 0px !important;
          --urlbarView-icon-border-radius: 0px !important;
          /* Nova computes this as calc(--urlbar-height / 2 - 24px). With a
             ~17px bar that is -15.5px, i.e. the expanded urlbar background
             bleeds 15px past the input on every side. Pin it flush. */
          --urlbar-background-inset: 0px !important;
      }

      /* Fx 152 renamed the fill element: UrlbarInput.mjs:113 emits
         <html:div class="urlbar-background"> with no id, because the urlbar is
         now instantiable more than once (Smart Window). #urlbar-background is
         a dead selector on this build. #urlbar itself is still an id
         (browser.xhtml:6049, <html:moz-urlbar id="urlbar">), light DOM, so
         userChrome.css still reaches inside. */
      #urlbar,
      .urlbar-background,
      .urlbar-input-container,
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
          z-index: 1 !important;
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
          /* Floor from Zen: --breakout-width is a vw fraction, so a narrow
             window would shrink the overlay to uselessness. */
          min-width: min(600px, 90vw) !important;
          top: var(--breakout-top) !important;
          left: 50% !important;
          position: fixed !important;
          transform: translateX(-50%) !important;
          z-index: 999 !important;
          margin: 0 !important;
          box-shadow: 0 15px 30px rgba(0, 0, 0, 0.2) !important;
          font-size: calc(var(--chrome-font-size) * 1.3) !important;
      }

      /* Nova splits the urlbar fill across two elements depending on state
         (urlbar-searchbar.css:291-330):
           docked   -> .urlbar-background is display:none, the pill is painted
                       on .urlbar-input-container
           extended -> .urlbar-background returns as display:block
         Style both, or the frosted look only appears half the time. Neither
         responds to a background-color set on #urlbar, since .urlbar-background
         is position:absolute inset:0 and covers it. */
      #urlbar[breakout][breakout-extend] > .urlbar-background,
      #urlbar[breakout][breakout-extend] > .urlbar-input-container {
          background-color: color-mix(in srgb, var(--theme-toolbar-field) 75%, transparent) !important;
          backdrop-filter: blur(30px) !important;
          outline: 1px solid light-dark(rgba(20, 20, 20, 0.2), rgba(235, 235, 235, 0.2)) !important;
          outline-offset: -1px !important;
      }

      .urlbarView {
          max-height: 60vh !important;
          overflow-y: auto !important;
          bottom: 100% !important;
          top: auto !important;
      }

      /* browser.uidensity = 1 is compact (fox-options.nix:182), and Firefox
         gates both of its row height floors on the negation of that:
           view-nova.css:149  .urlbarView-row      min-height: --urlbarView-row-min-height
           view-nova.css:181  .urlbarView-row-inner min-height: --urlbarView-row-inner-min-height
         both inside :root:not([uidensity="compact"]).
         So under compact nothing sets row height but the content, and the
         blanket padding: 0 below removed the last of it. The row's highlight
         is background-clip: padding-box (view-nova.css:132), so it collapsed
         onto the bare line box and the 1.4 line-height glyphs rendered
         outside it. Restore an explicit floor. */
      .urlbarView-row {
          min-height: var(--urlbarview-row-min) !important;
      }

      .urlbarView-row > .urlbarView-row-inner {
          min-height: var(--urlbarview-row-min) !important;
          padding-block: var(--urlbarview-row-pad) !important;
          padding-inline: 0.5em !important;
      }

      /* Reset scoped one level deeper than before, so it no longer eats the
         row padding restored above. */
      .urlbarView-row-inner * {
          padding: 0 !important;
          margin: 0 !important;
      }

      /* Must follow the reset: equal specificity (0,1,0), so source order
         decides. Without this the favicon butts against the title. */
      .urlbarView-favicon {
          margin-inline-end: 0.4em !important;
      }

      :root[inFullscreen] #nav-bar {
          display: none !important;
      }
    '';
  };
}
