{
  assign,
  blank,
  boolean,
  dot,
  error,
  field,
  fn,
  for,
  idx,
  if',
  ifElse,
  ifExpr,
  infix,
  ipairs,
  len,
  local,
  localFunction,
  nil,
  not,
  opt,
  os,
  pair,
  paren,
  pcall,
  require,
  return,
  rows,
  tostring,
  str,
  string,
  table,
  table',
  tern,
  tuple,
  type',
  typed,
  unicode,
  ...
}: ({
  Rail,
  TWEAKS,
  saved,
  on,
  by_id,
  rail,
  single,
  pinned,
  folding,
  guard,
  paint,
  LOOKS,
  plugins,
  toggle,
  menu,
  children,
  walk,
  live,
  shown,
  want,
  wears,
  pick,
}: [
  (local Rail [require (str "./rail")])
  [(dot tern "css") (str "ui-menu-base") (infix [[(dot tern "fs.read") (infix [(dot tern "plugin.dir") ".." (str "/snippets/rail.css")])] ".." [(dot tern "fs.read") (infix [(dot tern "plugin.dir") ".." (str "/snippets/settings.css")])]])]
  blank
  (local TWEAKS (rows (table [
    (rows (table [
      (field "id" (str "mini"))
      (field "label" (str "Mini"))
      (field "group" (str "Look layers"))
      (field "default" false)
      (field "layer" true)
    ]))
    (rows (table [
      (field "id" (str "ozette"))
      (field "label" (str "Ozette"))
      (field "group" (str "Look layers"))
      (field "default" false)
      (field "layer" true)
    ]))
    (rows (table [
      (field "id" (str "ozette-motion"))
      (field "label" (str "Ozette motion"))
      (field "parent" (str "ozette"))
      (field "default" false)
      (field "layer" true)
      (field "requires" (table [(str "ozette")]))
    ]))
    (rows (table [
      (field "id" (str "ozette-cmus"))
      (field "label" (str "Ozette cmus player"))
      (field "parent" (str "ozette"))
      (field "default" false)
      (field "layer" true)
      (field "requires" (table [(str "ozette")]))
    ]))
    (rows (table [
      (field "id" (str "ozette-answer-bubbles"))
      (field "requires" (table [(str "ozette") (str "answer-bubbles")]))
    ]))
    (rows (table [
      (field "id" (str "ozette-bot-you"))
      (field "requires" (table [(str "ozette") (str "bot-you")]))
    ]))
    (rows (table [
      (field "id" (str "yorha"))
      (field "label" (str "YoRHa"))
      (field "group" (str "Look layers"))
      (field "default" false)
      (field "layer" true)
    ]))
    (rows (table [
      (field "id" (str "bot-yorha-labels"))
      (field "label" (str "YoRHa labels"))
      (field "parent" (str "yorha"))
      (field "requires" (table [(str "yorha")]))
    ]))
    (rows (table [
      (field "id" (str "grok"))
      (field "label" (str "Grok"))
      (field "group" (str "Look layers"))
      (field "default" false)
      (field "layer" true)
    ]))
    (rows (table [
      (field "id" (str "scratch"))
      (field "label" (str "Unset all"))
      (field "group" (str "Look layers"))
      (field "default" false)
      (field "layer" true)
    ]))
    (rows (table [
      (field "id" (str "attention"))
      (field "label" (str "status dot attention colours"))
      (field "group" (str "Chrome"))
    ]))
    (rows (table [
      (field "id" (str "grips"))
      (field "label" (str "hide window buttons and pane grips"))
      (field "group" (str "Chrome"))
    ]))
    (rows (table [
      (field "id" (str "dividers"))
      (field "label" (str "invisible pane dividers"))
      (field "group" (str "Chrome"))
    ]))
    (rows (table [
      (field "id" (str "transparent"))
      (field "label" (str "transparent window"))
      (field "group" (str "Glass"))
      (field "default" false)
    ]))
    (rows (table [
      (field "id" (str "single"))
      (field "label" (str "Single session"))
      (field "group" (str "Chrome"))
    ]))
    (rows (table [
      (field "id" (str "account"))
      (field "label" (str "hide account and peers"))
      (field "group" (str "Chrome"))
    ]))
    (rows (table [
      (field "id" (str "files"))
      (field "label" (str "hide files"))
      (field "group" (str "Chrome"))
    ]))
    (rows (table [
      (field "id" (str "roomy"))
      (field "label" (str "tall pickers"))
      (field "group" (str "Chrome"))
    ]))
    (rows (table [
      (field "id" (str "inbox"))
      (field "label" (str "centred inbox"))
      (field "group" (str "Chrome"))
    ]))
    (rows (table [
      (field "id" (str "pane-borders"))
      (field "label" (str "Ekko pane borders"))
      (field "group" (str "Chrome"))
      (field "default" false)
    ]))
    (rows (table [
      (field "id" (str "frost"))
      (field "label" (str "modal frost"))
      (field "group" (str "Glass"))
    ]))
    (rows (table [
      (field "id" (str "user-frost"))
      (field "label" (str "frosted your messages"))
      (field "parent" (str "frost"))
      (field "requires" (table [(str "frost")]))
    ]))
    (rows (table [
      (field "id" (str "composer-frost"))
      (field "label" (str "frosted composer"))
      (field "group" (str "Glass"))
      (field "parent" (str "frost"))
      (field "requires" (table [(str "frost")]))
    ]))
    (rows (table [
      (field "id" (str "bot-you-frost"))
      (field "requires" (table [(str "user-frost") (str "bot-you")]))
    ]))
    (rows (table [
      (field "id" (str "reply-frost"))
      (field "label" (str "frosted replies"))
      (field "parent" (str "frost"))
      (field "requires" (table [(str "frost")]))
    ]))
    (rows (table [
      (field "id" (str "answer-frost"))
      (field "requires" (table [(str "reply-frost") (str "answer-bubbles")]))
    ]))
    (rows (table [
      (field "id" (str "bot-answer-frost"))
      (field "requires" (table [(str "reply-frost") (str "bot-answer-bubbles")]))
    ]))
    (rows (table [
      (field "id" (str "width"))
      (field "label" (str "rail width"))
      (field "group" (str "Rail"))
    ]))
    (rows (table [
      (field "id" (str "tabs"))
      (field "label" (str "tab rows"))
      (field "group" (str "Rail"))
    ]))
    (rows (table [
      (field "id" (str "buttons"))
      (field "label" (str "rail buttons"))
      (field "group" (str "Rail"))
    ]))
    (rows (table [
      (field "id" (str "centering"))
      (field "label" (str "rail centering"))
      (field "group" (str "Rail"))
    ]))
    (rows (table [
      (field "id" (str "bottom"))
      (field "label" (str "rail bottom"))
      (field "group" (str "Rail"))
    ]))
    (rows (table [
      (field "id" (str "lock"))
      (field "label" (str "lock the rail layout"))
      (field "group" (str "Layout"))
    ]))
    (rows (table [
      (field "id" (str "answer-bubbles"))
      (field "label" (str "answer bubbles"))
      (field "group" (str "omp"))
    ]))
    (rows (table [
      (field "id" (str "work-rail"))
      (field "label" (str "work steps on a rail"))
      (field "group" (str "omp"))
    ]))
    (rows (table [
      (field "id" (str "row-keys"))
      (field "label" (str "hide rail row shortcuts"))
      (field "group" (str "Rail"))
    ]))
    (rows (table [
      (field "id" (str "turn-stats"))
      (field "label" (str "hide turn stats"))
      (field "group" (str "omp"))
    ]))
    (rows (table [
      (field "id" (str "chat-still"))
      (field "label" (str "no streaming"))
      (field "group" (str "omp"))
    ]))
    (rows (table [
      (field "id" (str "bot-answer-bubbles"))
      (field "label" (str "answer bubbles"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-work-rail"))
      (field "label" (str "work steps on a rail"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-turn-stats"))
      (field "label" (str "hide turn stats"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-chat-still"))
      (field "label" (str "no streaming"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-tints"))
      (field "label" (str "tint colours and font"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-layout"))
      (field "label" (str "header, hero and placeholders"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-spacing"))
      (field "label" (str "tight message spacing"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-cards"))
    ]))
    (rows (table [
      (field "id" (str "bot-you"))
      (field "label" (str "your message bubbles"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-text"))
      (field "label" (str "message text spacing"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-dock"))
      (field "label" (str "hide composer meters"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-time"))
      (field "label" (str "timestamps"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-events"))
      (field "label" (str "event rows"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-ask"))
      (field "label" (str "question cards"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-names"))
      (field "label" (str "names and status line"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-stop"))
      (field "label" (str "stop button"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-rail"))
      (field "label" (str "roster tabs in the rail"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "bot-jobs"))
      (field "label" (str "hide job notices"))
      (field "group" (str "omp bots"))
    ]))
    (rows (table [
      (field "id" (str "yorha-answer-bubbles"))
      (field "requires" (table [(str "yorha") (str "answer-bubbles")]))
    ]))
    (rows (table [
      (field "id" (str "yorha-bot-answer-bubbles"))
      (field "requires" (table [(str "yorha") (str "bot-answer-bubbles")]))
    ]))
    (rows (table [
      (field "id" (str "yorha-bot-you"))
      (field "requires" (table [(str "yorha") (str "bot-you")]))
    ]))
    (rows (table [
      (field "id" (str "grok-answer-bubbles"))
      (field "requires" (table [(str "grok") (str "answer-bubbles")]))
    ]))
    (rows (table [
      (field "id" (str "grok-user-bubbles"))
      (field "requires" (table [(str "grok") (str "answer-bubbles")]))
    ]))
    (rows (table [
      (field "id" (str "grok-bot-answer-bubbles"))
      (field "requires" (table [(str "grok") (str "bot-answer-bubbles")]))
    ]))
    (rows (table [
      (field "id" (str "grok-bot-you"))
      (field "requires" (table [(str "grok") (str "bot-you")]))
    ]))
  ])))
  blank
  (for [{_ = null;} {t = null;}] [ipairs (dot Rail "tweaks")] ({
    _,
    t,
  }: [
    [(dot table' "insert") TWEAKS t]
  ]))
  blank
  (local saved [(dot tern "kv.get") (str "on")])
  (local on (table []))
  (local by_id (table []))
  (for [{_ = null;} {t = null;}] [ipairs TWEAKS] ({
    _,
    t,
    ok,
    css,
  }: [
    (local [ok css] [pcall (dot tern "fs.read") (infix [(dot tern "plugin.dir") ".." (str "/snippets/") ".." (dot t "id") ".." (str ".css")])])
    (if' ok [
      (assign (dot t "css") css)
    ])
    (assign (idx on (dot t "id")) (ifExpr [(infix [[type' saved] "==" (str "table") "and" (idx saved (dot t "id")) "~=" nil]) (infix [(idx saved (dot t "id")) "==" true]) (infix [(dot t "default") "~=" false])]))
    (assign (idx by_id (dot t "id")) t)
  ]))
  (local children (table []))
  (for [{_ = null;} {t = null;}] [ipairs TWEAKS] ({
    _,
    t,
  }: [
    (for [{_ = null;} {id = null;}] [ipairs (infix [(dot t "requires") "or" (table [])])] ({
      _,
      id,
    }: [
      (if' (not (idx by_id id)) [
        [error (infix [(str "ui-menu: ") ".." (dot t "id") ".." (str " requires unknown option ") ".." id])]
      ])
    ]))
    (if' (dot t "parent") [
      (if' (not (idx by_id (dot t "parent"))) [
        [error (infix [(str "ui-menu: ") ".." (dot t "id") ".." (str " has unknown parent ") ".." (dot t "parent")])]
      ])
      (if' (not (idx children (dot t "parent"))) [
        (assign (idx children (dot t "parent")) (table []))
      ])
      [(dot table' "insert") (idx children (dot t "parent")) t]
    ])
  ]))
  blank
  (localFunction walk [{t = null;} {path = null;}] ({
    t,
    path,
  }: [
    (if' (idx path (dot t "id")) [
      [error (infix [(str "ui-menu: requirement cycle through ") ".." (dot t "id")])]
    ])
    (assign (idx path (dot t "id")) true)
    (for [{_ = null;} {id = null;}] [ipairs (infix [(dot t "requires") "or" (table [])])] ({
      _,
      id,
    }: [
      [walk (idx by_id id) path]
    ]))
    (assign (idx path (dot t "id")) nil)
  ]))
  blank
  (for [{_ = null;} {t = null;}] [ipairs TWEAKS] ({
    _,
    t,
  }: [
    [walk t (table [])]
  ]))
  [(dot tern "kv.set") (str "menu") nil]
  blank
  [(dot Rail "bind") on]
  blank
  (local pinned nil)
  (local folding false)
  (localFunction single [{cx = null;}] ({
    cx,
    key,
    pins,
    ok,
    err,
  }: [
    (local key [(dot cx ":window_key")])
    (local pins (infix [[(dot tern "kv.get") (str "single-pins")] "or" (table [])]))
    (if' (not (dot on "single")) [
      (assign pinned nil)
      (if' (infix [(idx pins key) "~=" nil]) [
        (assign (idx pins key) nil)
        [(dot tern "kv.set") (str "single-pins") pins]
      ])
      return
    ])
    (if' folding [return])
    (assign folding true)
    (local [ok err] [
      pcall
      (fn [] ({
        sessions,
        anchor,
        sources,
        sourceTabs,
        count,
        panes,
        groups,
        parked,
        hostPanes,
        result,
        reason,
      }: [
        (local sessions [(dot cx "sessions:list")])
        (local anchor nil)
        (local [result reason] (tuple [nil nil]))
        (assign pinned (infix [pinned "or" (idx pins key)]))
        (for [{_ = null;} {session = null;}] [ipairs sessions] ({
          _,
          session,
        }: [
          (if' (infix [(dot session "id") "==" pinned]) [(assign anchor session)])
        ]))
        (if' (not anchor) [
          (assign anchor [(dot cx "sessions:current")])
          (assign pinned (dot anchor "id"))
          (assign (idx pins key) pinned)
          [(dot tern "kv.set") (str "single-pins") pins]
        ])
        (if' (infix [(dot [(dot cx "sessions:current")] "id") "~=" pinned]) [[(dot cx "sessions:switch") pinned]])
        (local sources (table []))
        (local sourceTabs (table []))
        (local count 0)
        (for [{_ = null;} {session = null;}] [ipairs sessions] ({
          _,
          session,
        }: [
          (if' (infix [(dot session "id") "~=" pinned "and" (dot session "host") "==" (dot anchor "host")]) [
            (assign (idx sources (dot session "id")) true)
            (assign count (infix [count "+" 1]))
          ])
        ]))
        (if' (infix [count "==" 0]) [return])
        (for [{_ = null;} {session = null;}] [ipairs [(dot cx "session:sessions")]] ({
          _,
          session,
        }: [
          (if' (idx sources (dot session "id")) [
            (for [{_ = null;} {tab = null;}] [ipairs (dot session "tabs")] ({
              _,
              tab,
            }: [(assign (idx sourceTabs tab) true)]))
          ])
        ]))
        (local panes [(dot cx "session:panes")])
        (local groups (table []))
        (for [{_ = null;} {tab = null;}] [ipairs [(dot cx "session:tabs")]] ({
          _,
          tab,
          blocks,
        }: [
          (local blocks (table []))
          (if' (infix [(dot tab "session") "==" pinned]) [
            [(dot table' "insert") groups (table [(field "tab" (dot tab "id")) (field "blocks" (table []))])]
          ])
          (if' (idx sourceTabs (dot tab "id")) [
            (for [{_ = null;} {pane = null;}] [ipairs panes] ({
              _,
              pane,
            }: [
              (if' (infix [(dot pane "tab") "==" (dot tab "id")]) [[(dot table' "insert") blocks (dot pane "pane")]])
            ]))
            (if' (infix [(len blocks) ">" 0]) [[(dot table' "insert") groups (table [(field "name" (dot tab "name")) (field "color" (dot tab "color")) (field "blocks" blocks)])]])
          ])
        ]))
        (local parked (table []))
        (local hostPanes (table []))
        (for [{_ = null;} {host = null;}] [ipairs [(dot cx "hosts:list")]] ({
          _,
          host,
        }: [
          (if' (infix [(dot host "id") "==" (dot anchor "host")]) [
            (for [{_ = null;} {pane = null;}] [ipairs (dot host "panes")] ({
              _,
              pane,
            }: [(assign (idx hostPanes pane) true)]))
          ])
        ]))
        (for [{_ = null;} {pane = null;}] [ipairs panes] ({
          _,
          pane,
        }: [
          (if' (infix [(dot pane "parked") "and" (idx hostPanes (dot pane "pane"))]) [
            [(dot table' "insert") parked (dot pane "pane")]
            [(dot table' "insert") groups (table [(field "blocks" (table [(dot pane "pane")]))])]
          ])
        ]))
        (if' (infix [(len groups) ">" 0]) [
          (assign [result reason] [(dot cx "layout:arrange") (table [(field "session" pinned) (field "tabs" groups)])])
          (if' (not result) [[error reason]])
          (for [{_ = null;} {pane = null;}] [ipairs parked] ({
            _,
            pane,
          }: [[(dot cx "layout:park") pane]]))
        ])
        (for [{_ = null;} {session = null;}] [ipairs sessions] ({
          _,
          session,
        }: [
          (if' (idx sources (dot session "id")) [[(dot cx "sessions:close") (dot session "id")]])
        ]))
      ]))
    ])
    (assign folding false)
    (if' (not ok) [
      [(dot tern "log.error") (infix [(str "Single session: ") ".." [tostring err]])]
      [(dot cx ":toast") (str "error") (infix [(str "Single session: ") ".." [tostring err]])]
    ])
  ]))
  (for [{_ = null;} {event = null;}] [ipairs (table [(str "focus") (str "pane_created") (str "tab_created") (str "session_ended")])] ({
    _,
    event,
  }: [
    [
      (dot tern "on")
      event
      (fn [{ev = null;} {cx = null;}] ({
        ev,
        cx,
        ...
      }: [[single cx]]))
    ]
  ]))
  blank
  (localFunction rail [{cx = null;}] ({cx}: [
    [
      pcall
      (fn [] [
        [(dot cx ":action") (str "layout:rail")]
      ])
    ]
    [
      pcall
      (fn [] [
        [(dot cx ":action") (str "tabs:horizontal")]
      ])
    ]
  ]))
  blank
  (localFunction guard [{ids = null;} {id = null;} {message = null;}] ({
    ids,
    id,
    message,
  }: [
    (for [{_ = null;} {command = null;}] [ipairs ids] ({
      _,
      command,
    }: [
      [
        pcall
        (fn [] [
          [
            (dot tern "override")
            command
            (fn [{cx = null;}] ({cx}: [
              (if' (infix [id "and" (not (idx on id))]) [
                (return false)
              ])
              [(dot cx ":toast") (str "info") message]
              (return true)
            ]))
          ]
        ])
      ]
    ]))
  ]))
  blank
  [guard (table [(str "layout:float") (str "layout:tiles") (str "layout:studio") (str "next_layout") (str "toggle_tab_orientation") (str "tabs:vertical")]) (str "lock") (str "The rail is locked")]
  [guard (table [(str "pane_headers:never") (str "pane_headers:split") (str "pane_headers:always") (str "status_bar") (str "interface_style")]) nil (str "This config fixes the chrome")]
  [guard (table [(str "files") (str "focus_files") (str "reveal_active_file")]) (str "files") (str "Files are off")]
  [guard (table [(str "new_session") (str "new_session_on_host") (str "switch_session") (str "rename_session") (str "close_session") (str "lock_session") (str "move_session_up") (str "move_session_down") (str "move_pane_to_session") (str "collapse_all_sessions") (str "expand_all_sessions")]) (str "single") (str "Tabs only: one pinned session")]
  blank
  [
    (dot tern "on")
    (str "window_start")
    (fn [{cx = null;}] ({cx}: [
      [
        pcall
        (fn [] [
          [
            (dot cx "settings:set_many")
            (rows (table [
              (field "layout" (str "Rail"))
              (field "tabs" (str "Horizontal"))
              (field "pane_headers" (str "Never"))
              (field "density" (str "Compact"))
              (field "status_bar" true)
              (field "material" (str "Glass"))
            ]))
          ]
        ])
      ]
      (if' (dot on "lock") [
        [rail cx]
      ])
      [single cx]
    ]))
  ]
  blank
  (for [{_ = null;} {ms = null;}] [ipairs (table [0 300 1200])] ({
    _,
    ms,
  }: [
    [
      (dot tern "timer")
      ms
      (fn [{cx = null;}] ({cx}: [
        (if' (infix [cx "and" (dot on "lock")]) [
          [rail cx]
        ])
        (if' cx [
          [single cx]
        ])
      ]))
    ]
  ]))
  blank
  (localFunction live [{t = null;}] ({t}: [
    (if' (not (idx on (dot t "id"))) [
      (return false)
    ])
    (for [{_ = null;} {id = null;}] [ipairs (infix [(dot t "requires") "or" (table [])])] ({
      _,
      id,
    }: [
      (if' (not [live (idx by_id id)]) [
        (return false)
      ])
    ]))
    (return true)
  ]))
  blank
  (local shown (table []))
  (localFunction paint [] [
    (for [{_ = null;} {t = null;}] [ipairs TWEAKS] ({
      _,
      t,
      yes,
    }: [
      (local yes [live t])
      (if' (infix [(dot t "css") "and" (idx shown (dot t "id")) "~=" yes]) [
        (assign (idx shown (dot t "id")) yes)
        [(dot tern "css") (infix [(str "ui-menu-") ".." (dot t "id")]) (ifExpr [yes (dot t "css") (str "")])]
      ])
    ]))
  ])
  blank
  [paint]
  blank
  (local LOOKS (rows (table [
    (table [(field "label" (str "Mini")) (field "layers" (table [(str "mini")]))])
    (table [(field "label" (str "Ozette")) (field "layers" (table [(str "ozette") (str "ozette-motion") (str "ozette-cmus")]))])
    (table [(field "label" (str "YoRHa")) (field "layers" (table [(str "yorha")]))])
    (table [(field "label" (str "Grok")) (field "layers" (table [(str "grok")]))])
    (table [(field "label" (str "Unset all")) (field "layers" (table [(str "scratch")]))])
    (table [(field "label" (str "None")) (field "layers" (table []))])
  ])))
  blank
  (localFunction plugins (typed [] (table [(pair string string)])) ({
    root,
    found,
  }: [
    (local root (infix [(dot tern "plugin.dir") ".." (str "/..")]))
    (local found (table []))
    (for [{_ = null;} {entry = null;}] [ipairs [(dot tern "fs.list") root]] ({
      _,
      entry,
      dir,
      ok,
      manifest,
    }: [
      (local dir (infix [root ".." (str "/") ".." entry]))
      (if' [(dot entry ":match") (str "%.path$")] [
        (assign dir (paren [(dot [(dot tern "fs.read") dir] ":gsub") (str "%s+$") (str "")]))
      ])
      (local [ok manifest] [pcall (dot tern "fs.read") (infix [dir ".." (str "/plugin.toml")])])
      (if' ok ({
        id,
        name,
      }: [
        (assign manifest (infix [(str "\n") ".." manifest]))
        (local [id name] (tuple [[(dot manifest ":match") (str "\nid%s*=%s*\"([^\"]+)\"")] [(dot manifest ":match") (str "\nname%s*=%s*\"([^\"]+)\"")]]))
        (if' id [
          (assign (idx found id) (infix [name "or" id]))
        ])
      ]))
    ]))
    (return found)
  ]))
  blank
  (localFunction want [{layers = null;}] ({
    layers,
    set,
  }: [
    (local set (table []))
    (for [{_ = null;} {t = null;}] [ipairs TWEAKS] ({
      _,
      t,
    }: [
      (if' (dot t "layer") [
        (assign (idx set (dot t "id")) false)
      ])
    ]))
    (for [{_ = null;} {id = null;}] [ipairs layers] ({
      _,
      id,
    }: [
      (assign (idx set id) true)
    ]))
    (return set)
  ]))
  blank
  (localFunction wears [{layers = null;}] ({layers}: [
    (for [{id = null;} {yes = null;}] [want layers] ({
      id,
      yes,
    }: [
      (if' (infix [(idx on id) "~=" yes]) [
        (return false)
      ])
    ]))
    (return true)
  ]))
  blank
  (localFunction pick [{layers = null;}] ({layers}: [
    (for [{id = null;} {yes = null;}] [want layers] ({
      id,
      yes,
    }: [
      (assign (idx on id) yes)
    ]))
    [(dot tern "kv.set") (str "on") on]
    [paint]
  ]))
  blank
  (localFunction toggle [{cx = null;} {t = null;}] ({
    cx,
    t,
  }: [
    (assign (idx on (dot t "id")) (not (idx on (dot t "id"))))
    (if' (infix [(idx on (dot t "id")) "and" (dot t "excludes")]) [
      (for [{_ = null;} {id = null;}] [ipairs (dot t "excludes")] ({
        _,
        id,
      }: [
        (assign (idx on id) false)
      ]))
    ])
    [(dot tern "kv.set") (str "on") on]
    [paint]
    (if' (dot t "apply") [
      [(dot t "apply") cx]
    ])
    (if' (infix [(dot t "id") "==" (str "lock") "and" (dot on "lock")]) [
      [rail cx]
    ])
    (if' (infix [(dot t "id") "==" (str "single")]) [
      [single cx]
    ])
    [(dot tern "chrome.refresh")]
  ]))
  blank
  (localFunction menu [{cx = null;}] ({
    cx,
    disabled,
    off,
    installed,
    items,
    add,
    ids,
    groups,
    row,
  }: [
    (local disabled (infix [[(dot cx "settings:get") (str "plugins_disabled")] "or" (table [])]))
    (local off (table []))
    (for [{_ = null;} {id = null;}] [ipairs disabled] ({
      _,
      id,
    }: [
      (assign (idx off id) true)
    ]))
    (local installed [plugins])
    (local items (table []))
    (localFunction add [{item = null;} {state = opt boolean;}] ({
      item,
      state,
    }: [
      (if' (infix [state "~=" nil]) [
        (assign (dot item "detail") (ifExpr [state (str "on") (str "off")]))
        (assign (dot item "current") state)
      ])
      (assign (idx items (infix [(len items) "+" 1])) item)
    ]))
    (for [{i = null;} {l = null;}] [ipairs LOOKS] ({
      i,
      l,
    }: [
      [add (table [(field "label" (dot l "label")) (field "group" (str "Look")) (field "icon" (str "palette")) (field "look" i) (field "current" [wears (dot l "layers")])])]
    ]))
    (local ids (table []))
    (for [{id = null;}] installed ({id}: [
      (if' (infix [id "~=" (dot tern "plugin.id")]) [
        (assign (idx ids (infix [(len ids) "+" 1])) id)
      ])
    ]))
    [
      (dot table' "sort")
      ids
      (fn [{a = null;} {b = null;}] ({
        a,
        b,
      }: [
        (return (infix [[(dot (idx installed a) ":lower")] "<" [(dot (idx installed b) ":lower")]]))
      ]))
    ]
    (for [{_ = null;} {id = null;}] [ipairs ids] ({
      _,
      id,
    }: [
      [add (table [(field "label" (idx installed id)) (field "group" (str "Plugins")) (field "icon" (str "puzzle")) (field "plugin" id)]) (not (idx off id))]
    ]))
    (local groups (table []))
    (for [{_ = null;} {t = null;}] [ipairs TWEAKS] ({
      _,
      t,
    }: [
      (if' (infix [(dot t "label") "and" (not (dot t "parent"))]) [
        (if' (not (idx groups (dot t "group"))) [
          (assign (idx groups (dot t "group")) (table []))
          (assign (idx groups (infix [(len groups) "+" 1])) (dot t "group"))
        ])
        [(dot table' "insert") (idx groups (dot t "group")) t]
      ])
    ]))
    (localFunction row [{t = null;} {group = null;} {depth = null;}] ({
      t,
      group,
      depth,
      label,
      need,
    }: [
      (local label (infix [[(dot string "rep") (str [(unicode "2003")]) depth] ".." (dot t "label")]))
      (local need nil)
      (for [{_ = null;} {id = null;}] [ipairs (infix [(dot t "requires") "or" (table [])])] ({
        _,
        id,
      }: [
        (if' (infix [(not need) "and" (not [live (idx by_id id)])]) [
          (assign need (infix [(dot (idx by_id id) "label") "or" id]))
        ])
      ]))
      (ifElse need [
          [add (table [(field "label" label) (field "group" group) (field "tweak" (dot t "id")) (field "need" need) (field "detail" (infix [(str "needs ") ".." need]))])]
        ] [
          [add (table [(field "label" label) (field "group" group) (field "tweak" (dot t "id"))]) (idx on (dot t "id"))]
        ])
      (for [{_ = null;} {c = null;}] [ipairs (infix [(idx children (dot t "id")) "or" (table [])])] ({
        _,
        c,
      }: [
        (if' (dot c "label") [
          [row c group (infix [depth "+" 1])]
        ])
      ]))
    ]))
    (for [{_ = null;} {group = null;}] [ipairs groups] ({
      _,
      group,
    }: [
      (for [{_ = null;} {t = null;}] [ipairs (idx groups group)] ({
        _,
        t,
      }: [
        [row t group 0]
      ]))
    ]))
    [
      (dot [(dot cx ":pick") (table [(field "items" items) (field "placeholder" (str "Settings")) (field "icon" (str "sliders")) (field "action" (str "toggle"))])] ":next")
      (fn [{item = null;} {_ = null;} {again = null;}] ({
        item,
        _,
        again,
        list,
      }: [
        (if' (infix [(not item) "or" (not again)]) [
          return
        ])
        (if' (dot item "need") [
          [(dot again ":toast") (str "info") (infix [(str "Turn on ") ".." (dot item "need") ".." (str " first")])]
          (return [menu again])
        ])
        (if' (dot item "tweak") [
          [toggle again (idx by_id (dot item "tweak"))]
          (return [menu again])
        ])
        (if' (dot item "look") [
          [pick (dot (idx LOOKS (dot item "look")) "layers")]
          (return [menu again])
        ])
        (assign (idx off (dot item "plugin")) (not (idx off (dot item "plugin"))))
        (local list (table []))
        (for [{id = null;} {yes = null;}] off ({
          id,
          yes,
        }: [
          (if' (infix [yes "and" id "~=" (dot tern "plugin.id")]) [
            (assign (idx list (infix [(len list) "+" 1])) id)
          ])
        ]))
        [(dot table' "sort") list]
        [(dot tern "kv.set") (str "reopen") (table [(field "at" [(dot os "time")]) (field "window" [(dot again ":window_key")])])]
        [(dot again "settings:set") (str "plugins_disabled") [(dot tern "json.array") list]]
      ]))
    ]
  ]))
  blank
  [
    (dot tern "command")
    (rows (table [
      (field "id" (str "menu"))
      (field "title" (str "Settings menu: look, plugins and UI tweaks"))
      (field "icon" (str "sliders"))
      (field "keys" (table [(str "ctrl+alt+,")]))
      (field "run" (fn [{cx = null;}] ({cx}: [
        [menu cx]
      ])))
    ]))
  ]
  blank
  [
    (dot tern "timer")
    0
    (fn [{cx = null;}] ({
      cx,
      asked,
    }: [
      (local asked [(dot tern "kv.get") (str "reopen")])
      (if' (infix [cx "and" [type' asked] "==" (str "table") "and" (dot asked "window") "==" [(dot cx ":window_key")]]) [
        [(dot tern "kv.set") (str "reopen") nil]
        (if' (infix [[(dot os "time")] "-" (dot asked "at") "<=" 5]) [
          [menu cx]
        ])
      ])
    ]))
  ]
])
