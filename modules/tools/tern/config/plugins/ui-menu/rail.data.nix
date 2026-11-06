{
  AgentFinishedEvent,
  AgentStateEvent,
  TabInfo,
  any,
  assign,
  blank,
  boolean,
  dot,
  field,
  fn,
  for,
  hex,
  idx,
  if',
  ifElse,
  ifExpr,
  infix,
  ipairs,
  len,
  local,
  localFunction,
  math,
  nil,
  not,
  number,
  opt,
  os,
  pair,
  paren,
  pcall,
  return,
  rows,
  str,
  string,
  table,
  table',
  tern,
  tonumber,
  tostring,
  tuple,
  type',
  typed,
  unicode,
  utf8,
  ...
}: ({
  on,
  MARKED,
  enabled,
  COLORS,
  SHELLS,
  SECTIONS,
  SECTION_MARK,
  STATUS_MARK,
  AGE_BASE,
  AGE_TICK_MS,
  color_at,
  agent_state,
  unseen,
  since,
  marks,
  age_index,
  id_list,
  toggle,
  save_map,
  load_map,
  focused_tab,
  load,
  prune,
  tab_view,
  arrange,
  tick,
  apply,
  strip_icon,
}: [
  (local (typed on (table [(pair string boolean)])) (table []))
  blank
  (local MARKED (table [(str "rail_sections") (str "rail_status") (str "rail_ages") (str "rail_compact")]))
  blank
  (localFunction enabled (typed [] boolean) [
    (for [{_ = null;} {id = null;}] [ipairs MARKED] ({
      _,
      id,
    }: [
      (if' (idx on id) [
        (return true)
      ])
    ]))
    (return false)
  ])
  blank
  (local COLORS (table [(str "red") (str "orange") (str "yellow") (str "green") (str "teal") (str "blue") (str "purple") (str "pink")]))
  (local SHELLS (table [(field "zsh" true) (field "bash" true) (field "fish" true) (field "nu" true) (field "sh" true) (field "dash" true) (field "ksh" true)]))
  (local SECTIONS (table [(str "pinned") (str "needs") (str "working") (str "idle")]))
  (local SECTION_MARK (table [(field "pinned" (str [(unicode "2061")])) (field "needs" (str [(unicode "2062")])) (field "working" (str [(unicode "2063")])) (field "idle" (str [(unicode "2064")]))]))
  (local STATUS_MARK (rows (table [
    (field "working" (str ""))
    (field "input" (str [(unicode "206B")]))
    (field "completed" (str [(unicode "206C")]))
    (field "failed" (str [(unicode "206D")]))
    (field "idle" (str [(unicode "206E")]))
  ])))
  (local AGE_BASE (hex 917760))
  (local AGE_TICK_MS 30000)
  blank
  (local color_at 0)
  (local (typed agent_state (table [(pair number string)])) (table []))
  (local (typed unseen (table [(pair number string)])) (table []))
  (local (typed since (table [(pair number number)])) (table []))
  (local (typed marks (table [(pair number string)])) (table []))
  blank
  (localFunction age_index (typed [{seconds = number;}] number) ({
    seconds,
    minutes,
    hours,
  }: [
    (local minutes [(dot math "floor") (infix [seconds "/" 60])])
    (if' (infix [minutes "<" 60]) [
      (return minutes)
    ])
    (local hours [(dot math "floor") (infix [minutes "/" 60])])
    (if' (infix [hours "<" 24]) [
      (return (infix [59 "+" hours]))
    ])
    (return (infix [82 "+" [(dot math "min") [(dot math "floor") (infix [hours "/" 24])] 30]]))
  ]))
  blank
  (localFunction id_list (typed [{key = string;}] (table [number])) ({
    key,
    saved,
    list,
  }: [
    (local saved [(dot tern "kv.get") key])
    (local list (table []))
    (if' (infix [[type' saved] "==" (str "table")]) [
      (for [{_ = null;} {id = null;}] [ipairs saved] ({
        _,
        id,
      }: [
        (if' (infix [[type' id] "==" (str "number")]) [
          (assign (idx list (infix [(len list) "+" 1])) id)
        ])
      ]))
    ])
    (return list)
  ]))
  blank
  (localFunction toggle (typed [{key = string;} {id = number;}] boolean) ({
    key,
    id,
    kept,
    had,
  }: [
    (local kept (table []))
    (local had false)
    (for [{_ = null;} {other = null;}] [ipairs [id_list key]] ({
      _,
      other,
    }: [
      (ifElse (infix [other "==" id]) [
          (assign had true)
        ] [
          (assign (idx kept (infix [(len kept) "+" 1])) other)
        ])
    ]))
    (if' (not had) [
      (assign (idx kept (infix [(len kept) "+" 1])) id)
    ])
    [(dot tern "kv.set") key [(dot tern "json.array") kept]]
    (return (not had))
  ]))
  blank
  (localFunction save_map [{key = string;} {map = table [(pair number any)];}] ({
    key,
    map,
    saved,
  }: [
    (local saved (table []))
    (for [{pane = null;} {value = null;}] map ({
      pane,
      value,
    }: [
      (assign (idx saved [tostring pane]) value)
    ]))
    [(dot tern "kv.set") key saved]
  ]))
  blank
  (localFunction load_map (typed [{key = string;} {kind = string;}] (table [(pair number any)])) ({
    key,
    kind,
    map,
    saved,
  }: [
    (local map (table []))
    (local saved [(dot tern "kv.get") key])
    (if' (infix [[type' saved] "==" (str "table")]) [
      (for [{pane = null;} {value = null;}] saved ({
        pane,
        value,
        id,
      }: [
        (local id [tonumber pane])
        (if' (infix [id "and" [type' value] "==" kind]) [
          (assign (idx map id) value)
        ])
      ]))
    ])
    (return map)
  ]))
  blank
  (localFunction focused_tab (typed [{cx = null;}] (opt number)) ({
    cx,
    pane,
  }: [
    (local pane [(dot cx "session:focused")])
    (return (infix [pane "and" [(dot cx "session:tab_of") pane] "or" nil]))
  ]))
  blank
  (localFunction load [{cx = null;}] ({
    cx,
    ok,
    list,
  }: [
    (assign unseen [load_map (str "rail_unseen") (str "string")])
    (assign since [load_map (str "rail_since") (str "number")])
    (assign agent_state (table []))
    (local [ok list] [
      pcall
      (fn [] [
        (return [(dot cx "agents:list")])
      ])
    ])
    (if' ok [
      (for [{_ = null;} {agent = null;}] [ipairs list] ({
        _,
        agent,
      }: [
        (assign (idx agent_state (dot agent "pane")) (dot agent "state"))
      ]))
    ])
  ]))
  blank
  (localFunction prune [{cx = null;}] ({
    cx,
    focused,
    live,
    changed,
    tabs,
    pins,
    kept,
  }: [
    (local focused [focused_tab cx])
    (local live (table []))
    (for [{_ = null;} {pane = null;}] [ipairs [(dot cx "session:panes")]] ({
      _,
      pane,
    }: [
      (assign (idx live (dot pane "pane")) (dot pane "tab"))
    ]))
    (local changed false)
    (for [{pane = null;}] unseen ({pane}: [
      (if' (infix [(idx live pane) "==" nil "or" (idx live pane) "==" focused]) [
        (assign (idx unseen pane) nil)
        (assign changed true)
      ])
    ]))
    (if' changed [
      [save_map (str "rail_unseen") unseen]
    ])
    (assign changed false)
    (for [{pane = null;}] since ({pane}: [
      (if' (infix [(idx live pane) "==" nil]) [
        (assign (idx since pane) nil)
        (assign changed true)
      ])
    ]))
    (if' changed [
      [save_map (str "rail_since") since]
    ])
    (local tabs (table []))
    (for [{_ = null;} {tab = null;}] [ipairs [(dot cx "session:tabs")]] ({
      _,
      tab,
    }: [
      (assign (idx tabs (dot tab "id")) true)
    ]))
    (local pins [id_list (str "rail_pins")])
    (local kept (table []))
    (for [{_ = null;} {id = null;}] [ipairs pins] ({
      _,
      id,
    }: [
      (if' (idx tabs id) [
        (assign (idx kept (infix [(len kept) "+" 1])) id)
      ])
    ]))
    (if' (infix [(len kept) "~=" (len pins)]) [
      [(dot tern "kv.set") (str "rail_pins") [(dot tern "json.array") kept]]
    ])
  ]))
  blank
  (localFunction tab_view (typed [{cx = null;} {tab = TabInfo;}] (tuple [string (opt number)])) ({
    cx,
    tab,
    working,
    input,
    completed,
    failed,
    stamp,
    status,
  }: [
    (local [working input completed failed] (tuple [(dot tab "busy") false false false]))
    (local (typed stamp (opt number)) nil)
    (for [{_ = null;} {pane = null;}] [ipairs [(dot cx "session:panes")]] ({
      _,
      pane,
    }: [
      (if' (infix [(dot pane "tab") "==" (dot tab "id")]) ({
        state,
        at,
      }: [
        (local state (idx agent_state (dot pane "pane")))
        (ifElse (infix [state "==" (str "working")]) [
            (assign working true)
          ] (if' (infix [state "==" (str "waiting_input")]) [
            (assign input true)
          ]))
        (ifElse (infix [(idx unseen (dot pane "pane")) "==" (str "failed")]) [
            (assign failed true)
          ] (if' (infix [(idx unseen (dot pane "pane")) "==" (str "done")]) [
            (assign completed true)
          ]))
        (local at (idx since (dot pane "pane")))
        (if' (infix [at "and" (infix [(not stamp) "or" at ">" stamp])]) [
          (assign stamp at)
        ])
      ]))
    ]))
    (local status (rows (ifExpr [[input] [(str "input")] [working (str "working")] [failed (str "failed")] [completed (str "completed")] [(str "idle")]])))
    (return (tuple [status stamp]))
  ]))
  blank
  (localFunction arrange [{cx = null;}] ({
    cx,
    pins,
    rank,
    now,
    sessions,
  }: [
    [prune cx]
    (local pins (table []))
    (for [{_ = null;} {id = null;}] [ipairs [id_list (str "rail_pins")]] ({
      _,
      id,
    }: [
      (assign (idx pins id) true)
    ]))
    (local rank (table []))
    (for [{i = null;} {name = null;}] [ipairs SECTIONS] ({
      i,
      name,
    }: [
      (assign (idx rank name) i)
    ]))
    (local now [(dot os "time")])
    (local (typed sessions (table [(pair number (table [(table [(field "tab" TabInfo) (field "section" string)])]))])) (table []))
    (assign marks (table []))
    (for [{_ = null;} {tab = null;}] [ipairs [(dot cx "session:tabs")]] ({
      _,
      tab,
      status,
      stamp,
      section,
      age,
      list,
    }: [
      (local [status stamp] [tab_view cx tab])
      (local section (rows (ifExpr [[(not (dot on "rail_sections"))] [(str "idle")] [(idx pins (dot tab "id"))] [(str "pinned")] [(infix [status "==" (str "input")]) (str "needs")] [(infix [status "==" (str "working")]) (str "working")] [(str "idle")]])))
      (local age (ifExpr [stamp [(dot utf8 "char") (infix [AGE_BASE "+" [age_index [(dot math "max") 0 (infix [now "-" stamp])]]])] (str "")]))
      (assign (idx marks (dot tab "id")) (infix [(idx SECTION_MARK section) ".." (idx STATUS_MARK (ifExpr [(dot on "rail_status") status (str "idle")])) ".." age]))
      (local list (infix [(idx sessions (dot tab "session")) "or" (table [])]))
      (assign (idx sessions (dot tab "session")) list)
      (assign (idx list (infix [(len list) "+" 1])) (table [(field "tab" tab) (field "section" section)]))
    ]))
    (for [{_ = null;} {list = null;}] sessions ({
      _,
      list,
    }: [
      [
        (dot table' "sort")
        list
        (fn [{a = null;} {b = null;}] ({
          a,
          b,
        }: [
          (if' (infix [(dot a "section") "~=" (dot b "section")]) [
            (return (infix [(idx rank (dot a "section")) "<" (idx rank (dot b "section"))]))
          ])
          (return (infix [(dot a "tab.position") "<" (dot b "tab.position")]))
        ]))
      ]
      (if' (dot on "rail_sections") [
        (for [{position = null;} {entry = null;}] [ipairs list] ({
          position,
          entry,
        }: [
          (if' (infix [(dot entry "tab.position") "~=" position]) [
            [(dot cx "layout:order_tab") (dot entry "tab.id") position]
          ])
        ]))
      ])
    ]))
    [(dot tern "chrome.refresh")]
  ]))
  blank
  (localFunction tick [{cx = null;}] ({cx}: [
    (if' (infix [cx "and" [enabled]]) [
      [arrange cx]
    ])
    [(dot tern "timer") AGE_TICK_MS tick]
  ]))
  blank
  (localFunction apply [{cx = null;}] ({cx}: [
    (ifElse [enabled] [
        [load cx]
        [arrange cx]
      ] [
        (assign marks (table []))
        [(dot tern "chrome.refresh")]
      ])
  ]))
  blank
  [
    (dot tern "on")
    (str "window_start")
    (fn [{cx = null;}] ({cx}: [
      [apply cx]
    ]))
  ]
  blank
  [
    (dot tern "timer")
    0
    (fn [{cx = null;}] ({cx}: [
      (if' (infix [cx "and" [enabled]]) [
        [load cx]
      ])
      [tick cx]
    ]))
  ]
  blank
  (for [{_ = null;} {name = null;}] [ipairs (table [(str "tab_created") (str "tab_closed") (str "pane_closed") (str "command_started") (str "command_finished") (str "focus")])] ({
    _,
    name,
  }: [
    [
      (dot tern "on")
      name
      (fn [{_ = null;} {cx = null;}] ({
        _,
        cx,
      }: [
        (if' [enabled] [
          [arrange cx]
        ])
      ]))
    ]
  ]))
  blank
  [
    (dot tern "on")
    (str "agent_state")
    (fn [{ev = AgentStateEvent;} {cx = null;}] ({
      ev,
      cx,
    }: [
      (if' (not [enabled]) [
        return
      ])
      (assign (idx agent_state (dot ev "pane")) (dot ev "new"))
      (if' (infix [(dot ev "old") "~=" (dot ev "new")]) [
        (assign (idx since (dot ev "pane")) [(dot os "time")])
        [save_map (str "rail_since") since]
      ])
      (if' (infix [(dot ev "new") "==" (str "working") "and" (idx unseen (dot ev "pane"))]) [
        (assign (idx unseen (dot ev "pane")) nil)
        [save_map (str "rail_unseen") unseen]
      ])
      [arrange cx]
    ]))
  ]
  blank
  [
    (dot tern "on")
    (str "agent_finished")
    (fn [{ev = AgentFinishedEvent;} {cx = null;}] ({
      ev,
      cx,
    }: [
      (if' (not [enabled]) [
        return
      ])
      (ifElse (infix [(dot ev "result") "==" (str "closed") "or" (dot ev "result") "==" (str "exited")]) [
          (assign (idx unseen (dot ev "pane")) nil)
          (assign (idx agent_state (dot ev "pane")) nil)
        ] (if' (infix [[(dot cx "session:tab_of") (dot ev "pane")] "~=" [focused_tab cx]]) [
          (assign (idx unseen (dot ev "pane")) (dot ev "result"))
        ]))
      (assign (idx since (dot ev "pane")) [(dot os "time")])
      [save_map (str "rail_since") since]
      [save_map (str "rail_unseen") unseen]
      [arrange cx]
    ]))
  ]
  blank
  (localFunction strip_icon (typed [{title = string;}] string) ({
    title,
    ok,
    first,
  }: [
    (local [ok first] [pcall (dot utf8 "codepoint") title 1])
    (if' (infix [ok "and" first "and" (infix [(paren (infix [first ">=" (hex 57344) "and" first "<=" (hex 63743)])) "or" first ">=" (hex 983040)])]) ({rest}: [
      (local rest (infix [[(dot utf8 "offset") title 2] "or" (len title) "+" 1]))
      (return (paren [(dot [(dot title ":sub") rest] ":gsub") (str "^%s+") (str "")]))
    ]))
    (return title)
  ]))
  blank
  [
    (dot tern "chrome.tab_title")
    (fn [{tab = null;}] ({
      tab,
      title,
    }: [
      (if' (not [enabled]) [
        (return nil)
      ])
      (local title (dot tab "name"))
      (if' (infix [(not title) "or" title "==" (str "")]) [
        (assign title [strip_icon (infix [(dot tab "title") "or" (str "")])])
        (if' (idx SHELLS (dot tab "program")) [
          (assign title [(dot title ":gsub") (str "^[^%s:]+@[^%s:]+:%s*") (str "")])
        ])
        (if' (infix [title "==" (str "")]) ({cwd}: [
          (local cwd (infix [(dot tab "cwd") "or" (str "")]))
          (assign title (infix [[(dot cwd ":match") (str "([^/]+)/*$")] "or" cwd]))
        ]))
      ])
      (return (infix [(infix [(idx marks (dot tab "id")) "or" (str "")]) ".." title]))
    ]))
  ]
  blank
  [
    (dot tern "command")
    (rows (table [
      (field "id" (str "pin"))
      (field "title" (str "Sidebar: Pin or unpin this tab"))
      (field "icon" (str "pin"))
      (field "run" (fn [{cx = null;}] ({
        cx,
        tab,
      }: [
        (local tab [focused_tab cx])
        (if' (infix [tab "and" (dot on "rail_sections")]) [
          [(dot cx ":toast") (str "info") (infix [[toggle (str "rail_pins") tab] "and" (str "Pinned") "or" (str "Unpinned")])]
          [arrange cx]
        ])
      ])))
    ]))
  ]
  blank
  [
    (dot tern "command")
    (rows (table [
      (field "id" (str "colour"))
      (field "title" (str "Sidebar: Colour this tab"))
      (field "icon" (str "palette"))
      (field "run" (fn [{cx = null;}] ({
        cx,
        tab,
      }: [
        (local tab [focused_tab cx])
        (if' tab [
          (assign color_at (infix [color_at "%" (len COLORS) "+" 1]))
          [(dot cx "layout:color_tab") tab (idx COLORS color_at)]
        ])
      ])))
    ]))
  ]
  blank
  [
    (dot tern "command")
    (rows (table [
      (field "id" (str "autohide"))
      (field "title" (str "Sidebar: Toggle auto-hide"))
      (field "icon" (str "sidebar"))
      (field "run" (fn [{cx = null;}] ({
        cx,
        hidden,
      }: [
        (local hidden (not [(dot cx "settings:get") (str "tabs_autohide")]))
        [(dot cx "settings:set") (str "tabs_autohide") hidden]
        [(dot cx ":toast") (str "info") (infix [hidden "and" (str "Sidebar tucks away") "or" (str "Sidebar stays open")])]
      ])))
    ]))
  ]
  blank
  [(dot tern "bind") (str "ctrl+alt+p") (str "plugin.ui-menu.pin")]
  [(dot tern "bind") (str "ctrl+alt+j") (str "next_tab")]
  [(dot tern "bind") (str "ctrl+alt+k") (str "previous_tab")]
  blank
  (return (rows (table [
    (field "tweaks" (rows (table [
      (rows (table [
        (field "id" (str "rail_sections"))
        (field "label" (str "sections: pinned, needs you, working, idle"))
        (field "group" (str "Rail"))
        (field "apply" apply)
      ]))
      (rows (table [
        (field "id" (str "rail_status"))
        (field "label" (str "status rings and lines"))
        (field "group" (str "Rail"))
        (field "apply" apply)
      ]))
      (rows (table [
        (field "id" (str "rail_ages"))
        (field "label" (str "ages"))
        (field "group" (str "Rail"))
        (field "apply" apply)
      ]))
      (rows (table [
        (field "id" (str "rail_compact"))
        (field "label" (str "one-line idle rows"))
        (field "group" (str "Rail"))
        (field "apply" apply)
      ]))
      (rows (table [
        (field "id" (str "rail_card"))
        (field "label" (str "selected tab card"))
        (field "group" (str "Rail"))
      ]))
      (rows (table [
        (field "id" (str "rail_header"))
        (field "label" (str "+ and bell in the header"))
        (field "group" (str "Rail"))
      ]))
    ])))
    (field "bind" (fn [{state = table [(pair string boolean)];}] ({state}: [
      (assign on state)
    ])))
  ])))
])
