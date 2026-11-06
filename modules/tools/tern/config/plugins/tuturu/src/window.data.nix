{
  AgentBlock,
  CommandFinishedEvent,
  PaneInfo,
  ProcessResult,
  StatusPaneInfo,
  StatusSegment,
  WindowCx,
  assign,
  blank,
  boolean,
  cast,
  comment,
  dot,
  field,
  fn,
  for,
  idx,
  if',
  ifElse,
  ifExpr,
  infix,
  len,
  local,
  localFunction,
  math,
  neg,
  nil,
  not,
  number,
  opt,
  os,
  pair,
  paren,
  pcall,
  proproblems,
  return,
  rows,
  str,
  string,
  table,
  table',
  tern,
  tonumber,
  tostring,
  trailing,
  tuple,
  type,
  type',
  typed,
  update,
  while,
  ...
}: ({
  Config,
  TICK_MS,
  CONFIG_EVERY_TICKS,
  MIN_GAP_MS,
  CLAIM_WINDOW_S,
  SEP,
  DATA_SEP,
  DATA_CONFIG,
  PLUGIN_CONFIG,
  trim,
  strip_comment,
  unquote,
  default_config,
  is_absolute,
  resolve_path,
  parse_config,
  config,
  config_source,
  config_key,
  warned,
  read_config_file,
  load_config,
  snapshot_key,
  maybe_reload_config,
  is_muted,
  refresh_muted,
  claim_chime,
  spawn,
  linux_player,
  linux_probe_failed,
  linux_probing,
  linux_queue,
  LINUX_PLAYERS,
  linux_argv,
  probe_linux_player,
  warned_no_player,
  play_file,
  last_chime_at,
  chime,
  list_agents,
  alerts,
  agent_state,
  seeded,
  tick_count,
  tick_body,
  tick,
  startup_problems,
}: [
  (comment "--!strict")
  (comment "-- Tuturu: a sound when a pane raises an unseen alert, an agent yields to you,")
  (comment "-- or a long shell command finishes.")
  (comment "--")
  (comment "-- Triggers (all for panes you are not looking at, unless only_unfocused=false):")
  (comment "--   alert  a pane's unseen-alert flag rises: a terminal bell, an agent that")
  (comment "--          finished or is waiting out of sight, or a pane whose program")
  (comment "--          exited. Tern shows one alert per pane until you look at it, so a")
  (comment "--          second bell while the flag stands chimes nothing new.")
  (comment "--   yield  an agent block leaves \"working\" for \"idle\": its turn is done and")
  (comment "--          control is back with you. (working -> \"waiting_input\" plays the")
  (comment "--          alert sound instead: it needs you, not just your attention.)")
  (comment "--   done   a shell command ran longer than min_seconds and finished.")
  (comment "--")
  (comment "-- Chimes never overlap: simultaneous events share one chime, and a chime in")
  (comment "-- one window suppresses the same moment's chime in every other window.")
  (comment "--")
  (comment "-- Configuration is sounds.toml in the plugin folder (ships with defaults) or")
  (comment "-- <plugin data>/sounds.toml, which wins when present so a reinstall keeps")
  (comment "-- your sounds. It is re-read every few seconds; no reload needed.")
  blank
  (type Config (rows (table [
    (field "sounds" (table [(pair string string)]))
    (field "only_unfocused" boolean)
    (field "min_seconds" number)
  ])))
  blank
  (local TICK_MS 250)
  (trailing (local CONFIG_EVERY_TICKS 20) "-- re-read sounds.toml about every 5 s")
  (trailing (local MIN_GAP_MS 500) "-- chimes never overlap")
  (trailing (local CLAIM_WINDOW_S 2) "-- cross-window dedup: one chime per moment")
  blank
  (local SEP (ifExpr [(infix [(dot tern "runtime.os") "==" (str "windows")]) (str "\\") (str "/")]))
  (local DATA_SEP (infix [(dot tern "plugin.data") ".." SEP]))
  (local DATA_CONFIG (infix [DATA_SEP ".." (str "sounds.toml")]))
  (local PLUGIN_CONFIG (infix [(dot tern "plugin.dir") ".." SEP ".." (str "sounds.toml")]))
  blank
  (comment "-- Config ----------------------------------------------------------------------------------")
  blank
  (localFunction trim (typed [{s = string;}] string) ({s}: [
    (return (paren [(dot string "gsub") s (str "^%s*(.-)%s*$") (str "%1")]))
  ]))
  blank
  (comment "-- Cut a `#` comment, keeping `#` inside quotes.")
  (localFunction strip_comment (typed [{line = string;}] string) ({
    line,
    in_single,
    in_double,
    i,
  }: [
    (local in_single false)
    (local in_double false)
    (local i 1)
    (while (infix [i "<=" (len line)]) ({c}: [
      (local c [(dot string "sub") line i i])
      (ifElse (infix [c "==" (str "\\") "and" (infix [in_single "or" in_double])]) [
          (update "+=" i 2)
        ] (ifElse (infix [c "==" (str "'") "and" (not in_double)]) [
            (assign in_single (not in_single))
            (update "+=" i 1)
          ] (ifElse (infix [c "==" (str "\"") "and" (not in_single)]) [
              (assign in_double (not in_double))
              (update "+=" i 1)
            ] (ifElse (infix [c "==" (str "#") "and" (not in_single) "and" (not in_double)]) [
                (return [(dot string "sub") line 1 (infix [i "-" 1])])
              ] [
                (update "+=" i 1)
              ]))))
    ]))
    (return line)
  ]))
  blank
  (comment "-- A quoted value without its quotes, or nil when not quoted. Only the")
  (comment "-- matching quote and the backslash unescape, so Windows paths work as-is")
  (comment "-- in double quotes (`\"C:\\sounds\\ping.wav\"` needs no doubling).")
  (localFunction unquote (typed [{s = string;}] (opt string)) ({
    s,
    first,
    inner,
  }: [
    (if' (infix [(len s) "<" 2]) [
      (return nil)
    ])
    (local first [(dot string "sub") s 1 1])
    (if' (infix [first "~=" (str "\"") "and" first "~=" (str "'")]) [
      (return nil)
    ])
    (if' (infix [[(dot string "sub") s (-1)] "~=" first]) [
      (return nil)
    ])
    (local inner [(dot string "sub") s 2 (-2)])
    (ifElse (infix [first "==" (str "\"")]) [
        (assign inner [(dot string "gsub") inner (str "\\\"") (str "\"")])
        (assign inner [(dot string "gsub") inner (str "\\\\") (str "\\")])
      ] [
        (assign inner [(dot string "gsub") inner (str "\\'") (str "'")])
      ])
    (return inner)
  ]))
  blank
  (localFunction default_config (typed [] Config) ({dir}: [
    (local dir (infix [(dot tern "plugin.dir") ".." SEP ".." (str "sounds")]))
    (return (rows (table [
      (field "sounds" (rows (table [
        (field "alert" (infix [dir ".." SEP ".." (str "alert.wav")]))
        (field "yield" (infix [dir ".." SEP ".." (str "yield.wav")]))
        (field "done" (infix [dir ".." SEP ".." (str "done.wav")]))
      ])))
      (field "only_unfocused" true)
      (field "min_seconds" 30)
    ])))
  ]))
  blank
  (localFunction is_absolute (typed [{p = string;}] boolean) ({p}: [
    (if' (infix [[(dot string "sub") p 1 1] "==" (str "/")]) [
      (return true)
    ])
    (return (infix [[(dot string "match") p (str "^[A-Za-z]:[\\/]")] "~=" nil "or" [(dot string "sub") p 1 2] "==" (str "\\\\")]))
  ]))
  blank
  (localFunction resolve_path (typed [{p = string;} {base = string;}] string) ({
    p,
    base,
  }: [
    (if' (infix [[(dot string "sub") p 1 1] "==" (str "~")]) ({home}: [
      (local home (infix [[(dot tern "getenv") (str "HOME")] "or" [(dot tern "getenv") (str "USERPROFILE")] "or" (str "")]))
      (if' (infix [home "~=" (str "")]) [
        (assign p (infix [home ".." [(dot string "sub") p 2]]))
      ])
    ]))
    (if' [is_absolute p] [
      (return p)
    ])
    (return (infix [base ".." SEP ".." p]))
  ]))
  blank
  (localFunction parse_config (typed [{text = string;} {base = string;}] (tuple [Config (table [string])])) ({
    text,
    base,
    config,
    problems,
  }: [
    (local config [default_config])
    (local (typed problems (table [string])) (table []))
    (for [{raw = null;}] [(dot string "gmatch") text (str "[^\r\n]+")] ({
      raw,
      line,
    }: [
      (local line [trim [strip_comment raw]])
      (if' (infix [line "~=" (str "")]) ({
        key,
        value,
      }: [
        (local [key value] [(dot string "match") line (str "^([A-Za-z_][%w_]*)%s*=%s*(.-)%s*$")])
        (ifElse (infix [key "==" nil "or" value "==" nil "or" value "==" (str "")]) [
            [(dot table' "insert") problems (infix [(str "Skipping line: ") ".." line])]
          ] (ifElse (infix [key "==" (str "alert") "or" key "==" (str "yield") "or" key "==" (str "done")]) ({quoted}: [
              (local quoted [unquote value])
              (ifElse (infix [quoted "==" nil]) [
                  [(dot table' "insert") problems (infix [key ".." (str ": expected a quoted path, got ") ".." value])]
                ] (ifElse (infix [quoted "==" (str "")]) [
                    (assign (idx (dot config "sounds") key) (str ""))
                  ] [
                    (assign (idx (dot config "sounds") key) [resolve_path quoted base])
                  ]))
            ]) (ifElse (infix [key "==" (str "only_unfocused")]) [
                (ifElse (infix [value "==" (str "true")]) [
                    (assign (dot config "only_unfocused") true)
                  ] (ifElse (infix [value "==" (str "false")]) [
                      (assign (dot config "only_unfocused") false)
                    ] [
                      [(dot table' "insert") problems (infix [(str "only_unfocused: expected true or false, got ") ".." value])]
                    ]))
              ] (ifElse (infix [key "==" (str "min_seconds")]) ({n}: [
                  (local n [tonumber value])
                  (ifElse (infix [n "==" nil "or" n "<" 0]) [
                      [(dot table' "insert") proproblems (infix [(str "min_seconds: expected seconds >= 0, got ") ".." value])]
                    ] [
                      (assign (dot config "min_seconds") n)
                    ])
                ]) [
                  [(dot table' "insert") problems (infix [(str "Unknown key: ") ".." key])]
                ]))))
      ]))
    ]))
    (return (tuple [config problems]))
  ]))
  blank
  (local config [default_config])
  (local config_source (str "(defaults)"))
  (local (typed config_key (opt string)) nil)
  (local (typed warned (table [(pair string boolean)])) (table []))
  blank
  (comment "-- The data-folder config wins when it reads; the shipped one is the fallback.")
  (localFunction read_config_file (typed [] (tuple [(opt string) (opt string)])) [
    (for [{_ = null;} {path = null;}] (table [DATA_CONFIG PLUGIN_CONFIG]) ({
      _,
      path,
      ok,
      text,
    }: [
      (local [ok text] [pcall (dot tern "fs.read") path (infix [64 "*" 1024])])
      (if' (infix [ok "and" [type' text] "==" (str "string")]) [
        (return (tuple [(cast text string) path]))
      ])
    ]))
    (return (tuple [nil nil]))
  ])
  blank
  (localFunction load_config (typed [] (table [string])) ({
    text,
    path,
    parsed,
    problems,
  }: [
    (local [text path] [read_config_file])
    (if' (infix [text "==" nil "or" path "==" nil]) [
      (assign config [default_config])
      (assign config_source (str "(defaults)"))
      (assign warned (table []))
      (return (table []))
    ])
    (local [parsed problems] [parse_config text (ifExpr [(infix [path "==" DATA_CONFIG]) (dot tern "plugin.data") (dot tern "plugin.dir")])])
    (assign config parsed)
    (assign config_source path)
    (assign warned (table []))
    (for [{kind = null;} {sound = null;}] (dot config "sounds") ({
      kind,
      sound,
    }: [
      (if' (infix [sound "~=" (str "") "and" (not [(dot tern "fs.exists") sound])]) [
        [(dot table' "insert") problems (infix [kind ".." (str ": file not found: ") ".." sound])]
      ])
    ]))
    (return problems)
  ]))
  blank
  (localFunction snapshot_key (typed [] (opt string)) ({
    text,
    path,
  }: [
    (local [text path] [read_config_file])
    (if' (infix [text "==" nil "or" path "==" nil]) [
      (return nil)
    ])
    (return (infix [path ".." (str "\n") ".." text]))
  ]))
  blank
  (localFunction maybe_reload_config [] ({
    key,
    problems,
  }: [
    (local key [snapshot_key])
    (if' (infix [key "==" config_key]) [
      return
    ])
    (assign config_key key)
    (local problems [load_config])
    (if' (infix [(len problems) ">" 0]) [
      [(dot tern "log.warn") (infix [(str "Tuturu: ") ".." [(dot table' "concat") problems (str "; ")]])]
    ])
  ]))
  blank
  (comment "-- Mute + cross-window claim -----------------------------------------------------------------")
  blank
  (local is_muted false)
  blank
  (localFunction refresh_muted [] ({
    ok,
    value,
  }: [
    (local [ok value] [pcall (dot tern "kv.get") (str "muted")])
    (assign is_muted (infix [ok "and" value "==" true]))
  ]))
  blank
  (comment "-- One chime per moment across windows: whoever claims it plays it.")
  (localFunction claim_chime (typed [] boolean) ({
    now_s,
    ok,
    at,
  }: [
    (local now_s [(dot os "time")])
    (local [ok at] [pcall (dot tern "kv.get") (str "last_chime")])
    (if' (infix [ok "and" [type' at] "==" (str "number") "and" now_s "-" (cast at number) "<" CLAIM_WINDOW_S]) [
      (return false)
    ])
    [pcall (dot tern "kv.set") (str "last_chime") now_s]
    (return true)
  ]))
  blank
  (comment "-- Playback ----------------------------------------------------------------------------------")
  blank
  (localFunction spawn [{argv = table [string];} {path = string;}] ({
    argv,
    path,
    ok,
    err,
  }: [
    (local [ok err] [
      pcall
      (fn [] [
        [
          (dot tern "process.run")
          argv
          (table [(field "timeout_ms" 15000)])
          (fn [{result = ProcessResult;}] ({result}: [
            (ifElse (dot result "timed_out") [
                [(dot tern "log.warn") (infix [(str "Tuturu: playing ") ".." path ".." (str " timed out")])]
              ] (if' (infix [(dot result "status") "~=" 0]) ({detail}: [
                (local detail (ifExpr [(infix [(dot result "stderr") "~=" (str "")]) (dot result "stderr") (infix [(str "exit ") ".." [tostring (dot result "status")]])]))
                [(dot tern "log.warn") (infix [(str "Tuturu: couldn't play ") ".." path ".." (str ": ") ".." [trim detail]])]
              ])))
          ]))
        ]
      ])
    ])
    (if' (not ok) [
      [(dot tern "log.warn") (infix [(str "Tuturu: couldn't start the player: ") ".." [tostring err]])]
    ])
  ]))
  blank
  (local (typed linux_player (opt string)) nil)
  (local linux_probe_failed false)
  (local linux_probing false)
  (local (typed linux_queue (table [string])) (table []))
  blank
  (comment "-- Preference order: PipeWire-native first (pw-play ships with pipewire),")
  (comment "-- then PulseAudio, ALSA, then the heavy/general players.")
  (local LINUX_PLAYERS (table [(str "pw-play") (str "paplay") (str "aplay") (str "ffplay") (str "play")]))
  blank
  (localFunction linux_argv (typed [{player = string;} {path = string;}] (table [string])) ({
    player,
    path,
  }: [
    (ifElse (infix [player "==" (str "ffplay")]) [
        (return (table [(str "ffplay") (str "-nodisp") (str "-autoexit") (str "-loglevel") (str "quiet") path]))
      ] (ifElse (infix [player "==" (str "play")]) [
          (return (table [(str "play") (str "-q") path]))
        ] (ifElse (infix [player "==" (str "aplay")]) [
            (return (table [(str "aplay") (str "-q") path]))
          ] (ifElse (infix [player "==" (str "paplay")]) [
              (return (table [(str "paplay") path]))
            ] [
              (return (table [(str "pw-play") path]))
            ]))))
  ]))
  blank
  (localFunction probe_linux_player [] ({
    names,
    ok,
    err,
  }: [
    (if' (infix [linux_probing "or" linux_probe_failed "or" linux_player "~=" nil]) [
      return
    ])
    (assign linux_probing true)
    (comment "-- One probe per player would serialize N spawns; instead ask sh for the")
    (comment "-- first match in preference order and read back which one answered.")
    (local names [(dot table' "concat") LINUX_PLAYERS (str " ")])
    (local [ok err] [
      pcall
      (fn [] [
        (rows [
          (dot tern "process.run")
          (table [(str "sh") (str "-c") (infix [(str "for p in ") ".." names ".." (str "; do command -v $p >/dev/null 2>&1 && { echo $p; exit 0; }; done; exit 1")])])
          (table [(field "timeout_ms" 5000)])
          (fn [{result = ProcessResult;}] ({
            result,
            name,
          }: [
            (assign linux_probing false)
            (local name [(dot string "match") (dot result "stdout") (str "([%w-]+)")])
            (ifElse (infix [(dot result "status") "==" 0 "and" name "~=" nil "and" name "~=" (str "")]) [
                (assign linux_player name)
                (for [{_ = null;} {path = null;}] linux_queue ({
                  _,
                  path,
                }: [
                  [spawn [linux_argv name path] path]
                ]))
              ] [
                (assign linux_probe_failed true)
                [(dot tern "log.warn") (infix [(str "Tuturu: no sound player found (need one of: ") ".." names ".." (str ")")])]
              ])
            (assign linux_queue (table []))
          ]))
        ])
      ])
    ])
    (if' (not ok) [
      (assign linux_probing false)
      (assign linux_probe_failed true)
      (assign linux_queue (table []))
      [(dot tern "log.warn") (infix [(str "Tuturu: couldn't probe for a sound player: ") ".." [tostring err]])]
    ])
  ]))
  blank
  (local warned_no_player false)
  blank
  (localFunction play_file [{path = string;}] ({
    path,
    os_name,
  }: [
    (local os_name (dot tern "runtime.os"))
    (ifElse (infix [os_name "==" (str "ios")]) [
        return
      ] (ifElse (infix [os_name "==" (str "windows")]) [
          (comment "-- Via wscript (a windowless GUI host): spawning hidden PowerShell")
          (comment "-- directly still flashes a console box on creation. SoundPlayer")
          (comment "-- takes WAV only.")
          [spawn (table [(str "wscript.exe") (str "//Nologo") (infix [(dot tern "plugin.dir") ".." SEP ".." (str "scripts") ".." SEP ".." (str "play.vbs")]) path]) path]
        ] (ifElse (infix [os_name "==" (str "macos")]) [
            [spawn (table [(str "afplay") path]) path]
          ] (ifElse (infix [os_name "==" (str "linux")]) ({player}: [
              (local player linux_player)
              (ifElse (infix [player "~=" nil]) [
                  [spawn [linux_argv player path] path]
                ] (ifElse (not linux_probe_failed) [
                    [(dot table' "insert") linux_queue path]
                    [probe_linux_player]
                  ] (if' (not warned_no_player) [
                    (assign warned_no_player true)
                    [(dot tern "log.warn") (str "Tuturu: silent (no Linux player; install pipewire-pulse, alsa-utils, sox or ffmpeg)")]
                  ])))
            ]) [
              [(dot tern "log.warn") (infix [(str "Tuturu: no player for ") ".." os_name])]
            ]))))
  ]))
  blank
  (local last_chime_at (neg (dot math "huge")))
  blank
  (localFunction chime [{kind = string;} {_pane = number;}] ({
    kind,
    _pane,
    path,
    ok_exists,
    exists,
    now,
  }: [
    (local path (idx (dot config "sounds") kind))
    (if' (infix [path "==" nil "or" path "==" (str "") "or" is_muted]) [
      return
    ])
    (local [ok_exists exists] [pcall (dot tern "fs.exists") path])
    (if' (infix [(not ok_exists) "or" (not exists)]) [
      (if' (not (idx warned path)) [
        (assign (idx warned path) true)
        [(dot tern "log.warn") (infix [(str "Tuturu: ") ".." kind ".." (str " sound not found: ") ".." path])]
      ])
      return
    ])
    (local now [(dot tern "now")])
    (if' (infix [now "-" last_chime_at "<" MIN_GAP_MS]) [
      return
    ])
    (if' (not [claim_chime]) [
      return
    ])
    (assign last_chime_at now)
    [play_file path]
  ]))
  blank
  (comment "-- Triggers ----------------------------------------------------------------------------------")
  blank
  (localFunction list_agents (typed [{cx = WindowCx;}] (table [AgentBlock])) ({
    cx,
    ok,
    agents,
  }: [
    (local [ok agents] [
      pcall
      (fn [] [
        (return [(dot cx "agents:list")])
      ])
    ])
    (if' ok [
      (return (cast agents (table [AgentBlock])))
    ])
    (return (table []))
  ]))
  blank
  (local (typed alerts (table [(pair number boolean)])) (table []))
  (local (typed agent_state (table [(pair number string)])) (table []))
  (local seeded false)
  (local tick_count 0)
  blank
  (localFunction tick_body [{cx = WindowCx;}] ({
    cx,
    candidates,
    focused,
    now_alerts,
    now_states,
  }: [
    (update "+=" tick_count 1)
    (if' (infix [tick_count "%" CONFIG_EVERY_TICKS "==" 0]) [
      [maybe_reload_config]
    ])
    [refresh_muted]
    blank
    (comment "-- One candidate per pane; the alert edge wins over a same-tick yield.")
    (local (typed candidates (table [(pair number string)])) (table []))
    (local (typed focused (table [(pair number boolean)])) (table []))
    blank
    (local (typed now_alerts (table [(pair number boolean)])) (table []))
    (for [{_ = null;} {pane = null;}] [(dot cx "session:panes")] ({
      _,
      pane,
      id,
      alerted,
    }: [
      (local id (dot pane "pane"))
      (local alerted (infix [(dot pane "alert") "==" true]))
      (assign (idx now_alerts id) alerted)
      (assign (idx focused id) (infix [(dot pane "focused") "==" true]))
      (if' (infix [seeded "and" alerted "and" (not (idx alerts id))]) [
        (assign (idx candidates id) (str "alert"))
      ])
    ]))
    (assign alerts now_alerts)
    blank
    (local (typed now_states (table [(pair number string)])) (table []))
    (for [{_ = null;} {agent = null;}] [list_agents cx] ({
      _,
      agent,
      id,
      prev,
    }: [
      (local id (dot agent "pane"))
      (assign (idx now_states id) (dot agent "state"))
      (local prev (idx agent_state id))
      (if' (infix [prev "==" (str "working") "and" (infix [(dot agent "state") "==" (str "idle") "or" (dot agent "state") "==" (str "waiting_input")])]) [
        (if' (infix [(idx candidates id) "==" nil]) [
          (assign (idx candidates id) (ifExpr [(infix [(dot agent "state") "==" (str "waiting_input")]) (str "alert") (str "yield")]))
        ])
      ])
    ]))
    (assign agent_state now_states)
    blank
    (for [{id = null;} {kind = null;}] candidates ({
      id,
      kind,
    }: [
      (ifElse (infix [(dot config "only_unfocused") "and" (idx focused id)]) [
          (comment "-- You are looking at it; no chime.")
        ] [
          [chime kind id]
        ])
    ]))
    (assign seeded true)
  ]))
  blank
  (comment "-- The timer re-arms first so one bad tick can't stop the loop.")
  (localFunction tick [{cx = opt WindowCx;}] ({
    cx,
    ok,
    err,
  }: [
    [(dot tern "timer") TICK_MS tick]
    (if' (infix [cx "==" nil]) [
      return
    ])
    (local [ok err] [pcall tick_body (cast cx WindowCx)])
    (if' (not ok) [
      [(dot tern "log.warn") (infix [(str "Chime tick failed: ") ".." [tostring err]])]
    ])
  ]))
  blank
  [(dot tern "timer") TICK_MS tick]
  blank
  [
    (dot tern "on")
    (str "command_finished")
    (fn [{ev = CommandFinishedEvent;} {cx = WindowCx;}] ({
      ev,
      cx,
      ok,
      info,
    }: [
      (if' (infix [(dot ev "took_ms") "<" (dot config "min_seconds") "*" 1000]) [
        return
      ])
      (local [ok info] [
        pcall
        (fn (typed [] (opt PaneInfo)) [
          (return [(dot cx "session:pane") (dot ev "pane")])
        ])
      ])
      (if' (infix [(not ok) "or" info "==" nil]) [
        return
      ])
      (if' (infix [(dot config "only_unfocused") "and" (dot info "focused")]) [
        return
      ])
      [chime (str "done") (dot ev "pane")]
    ]))
  ]
  blank
  (comment "-- Palette + status ----------------------------------------------------------------------------")
  blank
  [
    (dot tern "command")
    (rows (table [
      (field "id" (str "mute"))
      (field "title" (str "Tuturu: Mute / unmute"))
      (field "icon" (str "bell"))
      (field "run" (fn [{cx = WindowCx;}] ({cx}: [
        (assign is_muted (not is_muted))
        [pcall (dot tern "kv.set") (str "muted") is_muted]
        [(dot tern "chrome.refresh")]
        [(dot cx ":toast") (str "info") (str "Chime") (ifExpr [is_muted (str "Muted") (str "Unmuted")])]
      ])))
    ]))
  ]
  blank
  [
    (dot tern "command")
    (rows (table [
      (field "id" (str "test"))
      (field "title" (str "Tuturu: Play test sound"))
      (field "icon" (str "bell"))
      (field "run" (fn [{cx = WindowCx;}] ({
        cx,
        path,
        ok_exists,
        exists,
      }: [
        (local path (idx (dot config "sounds") (str "yield")))
        (if' (infix [path "==" nil "or" path "==" (str "")]) [
          [(dot cx ":toast") (str "error") (str "Chime") (str "No yield sound configured")]
          return
        ])
        (local [ok_exists exists] [pcall (dot tern "fs.exists") path])
        (if' (infix [(not ok_exists) "or" (not exists)]) [
          [(dot cx ":toast") (str "error") (str "Chime") (infix [(str "Missing: ") ".." path])]
          return
        ])
        [play_file path]
        [(dot cx ":toast") (str "info") (str "Chime") (infix [(str "Playing ") ".." path])]
      ])))
    ]))
  ]
  blank
  [
    (dot tern "command")
    (rows (table [
      (field "id" (str "reload"))
      (field "title" (str "Tuturu: Reload sounds"))
      (field "icon" (str "bell"))
      (field "run" (fn [{cx = WindowCx;}] ({
        cx,
        problems,
      }: [
        (assign config_key [snapshot_key])
        (local problems [load_config])
        (ifElse (infix [(len problems) "==" 0]) [
            [(dot cx ":toast") (str "info") (str "Chime") (infix [(str "Sounds reloaded from ") ".." config_source])]
          ] [
            [(dot cx ":toast") (str "error") (str "Chime") [(dot table' "concat") problems (str "\n")]]
          ])
      ])))
    ]))
  ]
  blank
  [
    (dot tern "command")
    (rows (table [
      (field "id" (str "diagnose"))
      (field "title" (str "Tuturu: Diagnose panes and agents"))
      (field "icon" (str "bell"))
      (field "run" (fn [{cx = WindowCx;}] ({
        cx,
        lines,
        out,
        ok_write,
        err,
      }: [
        (local (typed lines (table [string])) (table []))
        [(dot table' "insert") lines (infix [(str "config: ") ".." config_source])]
        [(dot table' "insert") lines (infix [(str "muted: ") ".." [tostring is_muted]])]
        [(dot table' "insert") lines (infix [(str "only_unfocused: ") ".." [tostring (dot config "only_unfocused")]])]
        [(dot table' "insert") lines (infix [(str "min_seconds: ") ".." [tostring (dot config "min_seconds")]])]
        (for [{_ = null;} {kind = null;}] (table [(str "alert") (str "yield") (str "done")]) ({
          _,
          kind,
          path,
          mark,
        }: [
          (local path (idx (dot config "sounds") kind))
          (local mark (str "(off)"))
          (if' (infix [path "~=" nil "and" path "~=" (str "")]) ({
            ok_exists,
            exists,
          }: [
            (local [ok_exists exists] [pcall (dot tern "fs.exists") path])
            (assign mark (infix [path ".." (ifExpr [(infix [ok_exists "and" exists]) (str "") (str "  MISSING")])]))
          ]))
          [(dot table' "insert") lines (infix [kind ".." (str " = ") ".." mark])]
        ]))
        [(dot table' "insert") lines (str "")]
        [(dot table' "insert") lines (str "panes:")]
        (for [{_ = null;} {pane = null;}] [(dot cx "session:panes")] ({
          _,
          pane,
        }: [
          (rows [(dot table' "insert") lines (rows (infix [(str "  ") ".." [tostring (dot pane "pane")] ".." (str " kind=") ".." [tostring (dot pane "kind")] ".." (str " program=") ".." [tostring (dot pane "program")] ".." (str " busy=") ".." [tostring (dot pane "busy")] ".." (str " alert=") ".." [tostring (dot pane "alert")] ".." (str " focused=") ".." [tostring (dot pane "focused")] ".." (str " at_prompt=") ".." [tostring (dot pane "at_prompt")] ".." (str " title=") ".." [(dot string "sub") (dot pane "title") 1 60]]))])
        ]))
        [(dot table' "insert") lines (str "")]
        [(dot table' "insert") lines (str "agents:")]
        (for [{_ = null;} {agent = null;}] [list_agents cx] ({
          _,
          agent,
        }: [
          (rows [(dot table' "insert") lines (rows (infix [(str "  ") ".." [tostring (dot agent "pane")] ".." (str " state=") ".." (dot agent "state") ".." (str " command=") ".." [tostring (dot agent "command")] ".." (str " model=") ".." [tostring (dot agent "model")]]))])
        ]))
        (local out (infix [(dot tern "plugin.data") ".." SEP ".." (str "diagnose.txt")]))
        (local [ok_write err] [pcall (dot tern "fs.write") out (infix [[(dot table' "concat") lines (str "\n")] ".." (str "\n")])])
        (ifElse ok_write [
            [(dot cx ":toast") (str "info") (str "Chime") (infix [(str "Wrote ") ".." out])]
          ] [
            [(dot cx ":toast") (str "error") (str "Chime") (infix [(str "Couldn't write ") ".." out ".." (str ": ") ".." [tostring err]])]
          ])
      ])))
    ]))
  ]
  blank
  (comment "-- Mute is invisible otherwise; the segment shows it and clicks back to sound.")
  [
    (dot tern "chrome.status")
    (fn (typed [{_pane = StatusPaneInfo;}] (opt (table [StatusSegment]))) ({_pane}: [
      (if' is_muted [
        (return (table [(table [(field "text" (str "tuturu muted")) (field "icon" (str "bell")) (field "tone" (str "muted")) (field "command" (str "plugin.tuturu.mute"))])]))
      ])
      (return nil)
    ]))
  ]
  blank
  (comment "-- Startup -------------------------------------------------------------------------------------")
  blank
  [refresh_muted]
  (assign config_key [snapshot_key])
  (local startup_problems [load_config])
  (if' (infix [(len startup_problems) ">" 0]) [
    [(dot tern "log.warn") (infix [(str "Tuturu: ") ".." [(dot table' "concat") startup_problems (str "; ")]])]
  ])
])
