[
  {
    select = "html.tn-themed";
    set = [
      ["--frost" "blur(40px) saturate(190%)"]
      ["--frost-edge" "0 0 0 1px light-dark(var(--l2), var(--l3)), inset 0 1px 0 var(--glass-hi)"]
      ["--frost-ink" "var(--t1)"]
    ];
  }
  {
    select = "html.tn-themed .cmdk, html.tn-themed .dlg-card, html.tn-themed .mdl, html.tn-themed .pk-sheet, html.tn-themed .sf-overlay.modal > .sf-ov-card, html.tn-themed .sf-prefs .pf-editor > .sf-col, html.tn-themed .tn-hd, html.tn-themed .tn-sc";
    set = [
      ["-webkit-backdrop-filter" "var(--frost) !important"]
      ["backdrop-filter" "var(--frost) !important"]
    ];
  }
  {
    at = "@media (prefers-contrast: more)";
    rules = [
      {
        select = "html.tn-themed";
        set = [
          ["--frost" "none"]
        ];
      }
    ];
  }
]
