{
  assign,
  blank,
  dofile,
  dot,
  field,
  fn,
  hl,
  index,
  os,
  package,
  require,
  rows,
  str,
  table,
  tonumber,
  ...
}: [
  [dofile [[(dot os "getenv") (str "OMARCHY_PATH")] ".." (str "/default/hypr/bootstrap.lua")]]
  blank
  (assign (index (dot package "loaded") (str "default.hypr.autostart")) [true])
  blank
  [
    (dot hl "config")
    (table (rows [
      (field "misc" (table [(field "disable_watchdog_warning" true)]))
      (field "xwayland" (table [(field "enabled" false)]))
    ]))
  ]
  blank
  [
    (dot hl "monitor")
    (table (rows [
      (field "output" (str ""))
      (field "mode" [(dot os "getenv") (str "OMARCHY_MODE")])
      (field "position" (str "0x0"))
      (field "scale" [tonumber [(dot os "getenv") (str "OMARCHY_SCALE")]])
    ]))
  ]
  blank
  [require (str "default.hypr.omarchy")]
  [require (str "default.hypr.toggles")]
  blank
  [
    (dot hl "on")
    (str "hyprland.start")
    (fn [
      [(dot hl "exec_cmd") (str "omarchy-launch-shell")]
    ])
  ]
]
