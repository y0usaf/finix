{
  FocusEvent,
  TabEvent,
  TabInfo,
  WindowCx,
  assign,
  blank,
  comment,
  dot,
  fn,
  for,
  if',
  infix,
  ipairs,
  local,
  localFunction,
  nil,
  not,
  number,
  opt,
  return,
  str,
  tern,
  tuple,
  typed,
  ...
}: ({
  last,
  previous,
  note,
  focused_tab,
  tab_info,
  place,
}: [
  (comment "--!strict")
  blank
  (local (typed last (opt number)) nil)
  (local (typed previous (opt number)) nil)
  blank
  (localFunction note [{id = opt number;}] ({id}: [
    (if' (infix [id "and" id "~=" last]) [
      (assign previous last)
      (assign last id)
    ])
  ]))
  blank
  (localFunction focused_tab (typed [{cx = WindowCx;}] (opt number)) ({
    cx,
    pane,
  }: [
    (local pane [(dot cx "session:focused")])
    (return (infix [pane "and" [(dot cx "session:tab_of") pane] "or" nil]))
  ]))
  blank
  (localFunction tab_info (typed [{cx = WindowCx;} {id = number;}] (opt TabInfo)) ({
    cx,
    id,
  }: [
    (for [{_ = null;} {info = null;}] [ipairs [(dot cx "session:tabs")]] ({
      _,
      info,
    }: [
      (if' (infix [(dot info "id") "==" id]) [
        (return info)
      ])
    ]))
    (return nil)
  ]))
  blank
  (localFunction place [{cx = WindowCx;} {id = number;} {anchor = opt number;}] ({
    cx,
    id,
    anchor,
    info,
    at,
  }: [
    (if' (infix [(not anchor) "or" anchor "==" id]) [
      return
    ])
    (local info [tab_info cx id])
    (local at [tab_info cx anchor])
    (if' (infix [(not info) "or" (not at) "or" (dot info "session") "~=" (dot at "session")]) [
      return
    ])
    (if' (infix [(dot info "position") ">" (dot at "position") "+" 1]) [
      [(dot cx "layout:order_tab") id (infix [(dot at "position") "+" 1])]
    ])
  ]))
  blank
  [
    (dot tern "on")
    (str "window_start")
    (fn [{cx = WindowCx;}] ({cx}: [
      (assign [last previous] (tuple [nil nil]))
      [note [focused_tab cx]]
    ]))
  ]
  blank
  [
    (dot tern "on")
    (str "focus")
    (fn [{ev = FocusEvent;}] ({ev}: [
      [note (dot ev "tab")]
    ]))
  ]
  blank
  [
    (dot tern "timer")
    0
    (fn [{cx = opt WindowCx;}] ({cx}: [
      [note (infix [cx "and" [focused_tab cx]])]
    ]))
  ]
  blank
  [
    (dot tern "on")
    (str "tab_created")
    (fn [{ev = TabEvent;} {cx = WindowCx;}] ({
      ev,
      cx,
    }: [
      (if' (infix [[focused_tab cx] "~=" (dot ev "tab")]) [
        return
      ])
      [place cx (dot ev "tab") (infix [last "==" (dot ev "tab") "and" previous "or" last])]
    ]))
  ]
])
