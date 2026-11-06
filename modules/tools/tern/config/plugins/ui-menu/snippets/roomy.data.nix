[
  {
    select = "html.tn-themed #pick .cmdk.tn-pk";
    set = [
      ["display" "flex"]
      ["flex-direction" "column"]
      ["max-height" "calc(87vh - 24px) !important"]
    ];
  }
  {
    select = "html.tn-themed #pick .cmdk.tn-pk > .ck-top, html.tn-themed #pick .cmdk.tn-pk > .ck-foot";
    set = [
      ["flex" "none"]
    ];
  }
  {
    select = "html.tn-themed #pick .cmdk.tn-pk .ck-list";
    set = [
      ["max-height" "none !important"]
      ["min-height" "0"]
      ["flex" "1 1 auto"]
    ];
  }
]
