[
  {
    select = "html.tn-themed, html.tn-themed.glass";
    set = [
      ["--page" "transparent"]
      ["--panel" "transparent"]
      ["--topbar-bg" "transparent"]
      ["--tn-page-a" "0"]
      ["--tn-panel-a" "0"]
      ["--tv-bg" "transparent"]
      ["--modal-filter" "none"]
      ["--modal-dim-filter" "none"]
    ];
  }
  {
    select = "html.tn-themed *, html.tn-themed *::before, html.tn-themed *::after";
    set = [
      ["backdrop-filter" "none !important"]
      ["-webkit-backdrop-filter" "none !important"]
    ];
  }
  {
    select = "html.tn-themed body, html.tn-themed .tn-body, html.tn-themed .tn-head, html.tn-themed #panel, html.tn-themed #sidebar, html.tn-themed #tabbar, html.tn-themed #statusline";
    set = [
      ["background" "transparent"]
    ];
  }
]
