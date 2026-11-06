{
  PickItem,
  WindowCx,
  blank,
  comment,
  dot,
  error,
  field,
  fn,
  for,
  if',
  ifElse,
  infix,
  ipairs,
  local,
  localFunction,
  nil,
  not,
  opt,
  return,
  rows,
  str,
  string,
  table,
  table',
  tern,
  type',
  typed,
  ...
}: ({
  blocks,
  agents,
  launch,
  menu,
}: [
  (comment "--!strict")
  blank
  (local blocks (rows (table [
    (table [(field "label" (str "Terminal")) (field "detail" (str "shell block")) (field "icon" (str "terminal")) (field "action" (str "new_shell_block"))])
    (table [(field "label" (str "Browser")) (field "detail" (str "web page")) (field "icon" (str "globe")) (field "action" (str "new_browser_block"))])
    (table [(field "label" (str "Git")) (field "detail" (str "status, commits")) (field "icon" (str "branch")) (field "action" (str "new_git_block"))])
    (table [(field "label" (str "Board")) (field "detail" (str "lanes and cards")) (field "icon" (str "kanban")) (field "action" (str "new_board_block"))])
    (table [(field "label" (str "Canvas")) (field "detail" (str "shapes and notes")) (field "icon" (str "canvas")) (field "action" (str "new_canvas_block"))])
    (table [(field "label" (str "Task manager")) (field "detail" (str "processes")) (field "icon" (str "list-checks")) (field "action" (str "new_task_manager_block"))])
    (table [(field "label" (str "Screen")) (field "detail" (str "remote display")) (field "icon" (str "monitor")) (field "action" (str "new_screen_block"))])
  ])))
  blank
  (local agents (rows (table [
    (table [(field "label" (str "omp")) (field "icon" (str "app-omp")) (field "command" (str "omp"))])
    (table [(field "label" (str "Claude Code")) (field "icon" (str "app-claude")) (field "command" (str "tern acp claude"))])
    (table [(field "label" (str "Codex")) (field "icon" (str "app-codex")) (field "command" (str "tern acp codex"))])
  ])))
  blank
  (localFunction launch [{cx = WindowCx;} {command = string;}] ({
    cx,
    command,
    placement,
    id,
    info,
  }: [
    (local placement [(dot cx "settings:get") (str "agent_placement")])
    (if' (infix [placement "==" (str "new_tab")]) [
      [(dot cx "layout:new_tab") (table [(field "command" command)])]
      return
    ])
    (local id [(dot cx "session:focused")])
    (local info (infix [id "and" [(dot cx "session:pane") id] "or" nil]))
    (if' (not info) [
      [(dot cx "layout:new_tab") (table [(field "command" command)])]
      return
    ])
    (if' (infix [placement "==" (str "replace_if_alone")]) ({
      tab,
      layout,
    }: [
      (local tab [(dot cx "session:tab_of") (dot info "pane")])
      (local layout (infix [tab "and" [(dot cx "session:layout") tab]]))
      (if' (infix [layout "and" (dot layout "root.pane")]) ({pane}: [
        (local pane [(dot cx "layout:split") (dot info "pane") (str "right") (table [(field "command" command)])])
        (if' pane [
          [(dot cx "layout:close") (dot info "pane")]
        ])
        return
      ]))
    ]))
    [(dot cx "layout:split") (dot info "pane") (str "right") (table [(field "command" command)])]
  ]))
  blank
  (localFunction menu [{cx = WindowCx;}] ({
    cx,
    items,
    custom,
  }: [
    (local (typed items (table [PickItem])) (table []))
    (for [{_ = null;} {row = null;}] [ipairs blocks] ({
      _,
      row,
    }: [
      [
        (dot table' "insert")
        items
        (rows (table [
          (field "label" (dot row "label"))
          (field "detail" (dot row "detail"))
          (field "group" (str "Blocks"))
          (field "icon" (dot row "icon"))
          (field "action" (dot row "action"))
        ]))
      ]
    ]))
    (for [{_ = null;} {row = null;}] [ipairs agents] ({
      _,
      row,
    }: [
      [
        (dot table' "insert")
        items
        (rows (table [
          (field "label" (dot row "label"))
          (field "group" (str "Agents"))
          (field "icon" (dot row "icon"))
          (field "command" (dot row "command"))
        ]))
      ]
    ]))
    (local custom [(dot cx "settings:get") (str "agents.custom")])
    (if' (infix [[type' custom] "==" (str "table")]) [
      (for [{_ = null;} {entry = null;}] [ipairs custom] ({
        _,
        entry,
        name,
        command,
      }: [
        (local name (infix [[type' entry] "==" (str "table") "and" (dot entry "name") "or" nil]))
        (local command (infix [[type' entry] "==" (str "table") "and" (dot entry "command") "or" nil]))
        (if' (infix [[type' name] "==" (str "string") "and" [type' command] "==" (str "string") "and" name "~=" (str "") "and" command "~=" (str "")]) [
          [
            (dot table' "insert")
            items
            (rows (table [
              (field "label" name)
              (field "group" (str "Agents"))
              (field "icon" (str "puzzle"))
              (field "command" command)
            ]))
          ]
        ])
      ]))
    ])
    [(dot table' "insert") items (table [(field "label" (str "Carly")) (field "group" (str "Agents")) (field "icon" (str "sparkle")) (field "action" (str "new_carly_block"))])]
    (for [{_ = null;} {block = null;}] [ipairs [(dot cx "session:block_types")]] ({
      _,
      block,
    }: [
      (if' (infix [(dot block "palette") "and" (dot block "kind") "~=" (str "canvas") "and" (dot block "kind") "~=" (str "tern.canvas")]) [
        [
          (dot table' "insert")
          items
          (rows (table [
            (field "label" (dot block "title"))
            (field "detail" (dot block "kind"))
            (field "group" (str "Plugins"))
            (field "icon" (dot block "icon"))
            (field "kind" (dot block "kind"))
          ]))
        ]
      ])
    ]))
    [
      (rows (dot [(dot cx ":pick") (table [(field "items" items) (field "placeholder" (str "New block")) (field "icon" (str "plus")) (field "action" (str "create"))])] ":next"))
      (fn [{item = opt PickItem;} {_err = opt string;} {fresh = opt WindowCx;}] ({
        item,
        _err,
        fresh,
        next_cx,
      }: [
        (if' (not item) [
          return
        ])
        (local next_cx (infix [fresh "or" cx]))
        (ifElse (dot item "command") [
            [launch next_cx (dot item "command")]
          ] (ifElse (dot item "kind") [
              [(dot next_cx ":new_block") (dot item "kind")]
            ] (if' (dot item "action") [
              [(dot next_cx ":action") (dot item "action")]
            ])))
      ]))
    ]
  ]))
  blank
  [
    (dot tern "command")
    (rows (table [
      (field "id" (str "new_block"))
      (field "title" (str "New block…"))
      (field "icon" (str "plus"))
      (field "keys" (table [(str "ctrl+n")]))
      (field "run" menu)
    ]))
  ]
])
