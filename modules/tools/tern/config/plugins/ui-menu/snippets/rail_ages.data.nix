lib: let
  row = "html.lay-rail.tabs-h .tb-tabs .tt";
  labels = ["now"] ++ map (m: "${toString m}m") (lib.range 1 59) ++ map (h: "${toString h}h") (lib.range 1 23) ++ map (d: "${toString d}d") (lib.range 1 30);
  mark = i: "[title*=\"\\${lib.toHexString (917760 + i)}\"]";
in
  [
    {
      select = "html.lay-rail.tabs-h .tb-tabs .tt .mk .hint";
      set = [
        ["display" "none !important"]
      ];
    }
    {
      select = "html.lay-rail.tabs-h .tb-tabs .tt .mk";
      set = [
        ["flex" "none !important"]
      ];
    }
    {
      select = "html.lay-rail.tabs-h .tb-tabs .tt .mk::before";
      set = [
        ["font-size" "11px"]
        ["color" "var(--t4)"]
        ["font-family" "var(--sans)"]
      ];
    }
  ]
  ++ lib.concatLists (lib.imap0 (i: label: [
      {
        select = "${row}.working${mark i} .sub::before";
        set = [
          ["content" "\"Working · ${label}\" !important"]
        ];
      }
      {
        select = "${row}:not(.working)${mark i} .mk::before";
        set = [
          ["content" "\"${label}\" !important"]
        ];
      }
    ])
    labels)
