{
  abs,
  and,
  and-optional,
  append,
  assoc,
  at,
  bar,
  below,
  blank,
  by,
  cddr,
  clock-text,
  code-char,
  collect,
  concatenate,
  cond,
  constant,
  context,
  copy-list,
  define-extension,
  defparameter,
  defun,
  double,
  ecase,
  eq,
  eql,
  equal,
  exp,
  find,
  first,
  flet,
  float,
  for,
  format,
  from,
  function,
  getf,
  hex,
  hud,
  hud--c,
  hud--decay,
  hud--dim,
  hud--heat,
  hud--icon,
  hud--mix,
  hud--now,
  hud--off,
  hud--panel,
  hud--text,
  if',
  in',
  in-package,
  interval,
  kw,
  last,
  length,
  let',
  list,
  loop,
  max,
  member,
  min,
  multiple-value-bind,
  nil,
  not,
  nthcdr,
  null',
  on,
  or',
  parse-integer,
  plusp,
  publish-state,
  quote,
  realp,
  reduce,
  remove,
  remove-duplicates,
  repeat,
  return,
  round,
  rows,
  second,
  service-state,
  setf,
  shell-surface,
  sin,
  state-value,
  str,
  string,
  string-upcase,
  stringp,
  subseq,
  t,
  thereis,
  ui,
  uninterned,
  unless,
  values,
  when,
  ...
}: ({
  bar-probes,
  bar--sample,
  bar--target,
  bar--metric,
  bar--ease,
  bar--moving-p,
  bar--segments,
  bar--spark,
  bar--temp-color,
  bar--gauge,
  bar--degrees,
  bar--gib,
  bar--truncate,
  bar--nonempty,
  bar--media,
  bar--sweep,
  bar--eq,
  bar--clock,
  bar--battery,
  bar--network,
  bar--gpu-p,
  bar--module,
  bar--surfaces,
}: [
  [in-package (uninterned "tomoe-user")]
  blank
  [defparameter (constant bar-probes) (quote [[(kw "cpu") (kw "cpu")] [(kw "memory") (kw "memory")] [(kw "gpu") (kw "gpu")] [(kw "vram") (kw "gpu")]])]
  blank
  ({
    probe,
    previous,
    system,
  }:
    rows [
      [defun bar--sample [probe previous system]]
      ({sample}:
        rows [
          [let' [[sample [copy-list previous]]]]
          (rows [
            [ecase probe]
            (rows [
              (kw "cpu")
              ({
                total,
                idle,
              }:
                rows [
                  [let' [[total [getf system (kw "cpu-total")]] [idle [getf system (kw "cpu-idle")]]]]
                  (rows [
                    [when total]
                    ({spent}:
                      rows [
                        [let' [[spent ["-" total [getf sample (kw "total") total]]]]]
                        (rows [
                          [setf [getf sample (kw "percent")]]
                          (rows [
                            [if' [plusp spent]]
                            [[max 0 [min 100 [round ["*" 100 ["-" spent ["-" idle [getf sample (kw "idle") idle]]]] spent]]]]
                            [[getf sample (kw "percent") 0]]
                          ])
                          [[getf sample (kw "total")] total]
                          [[getf sample (kw "idle")] idle]
                          [[getf sample (kw "temp")] [getf system (kw "cpu-temperature")]]
                        ])
                      ])
                  ])
                ])
            ])
            (rows [
              (kw "memory")
              ({
                total,
                available,
              }:
                rows [
                  [let' [[total [getf system (kw "memory-total")]] [available [getf system (kw "memory-available")]]]]
                  (rows [
                    [when [and total [plusp total]]]
                    (rows [
                      [setf [getf sample (kw "percent")] [round ["*" 100 ["-" total available]] total]]
                      [[getf sample (kw "used")] [round ["-" total available] 1024]]
                    ])
                  ])
                ])
            ])
            (rows [
              (kw "gpu")
              ({gpu}:
                rows [
                  [let' [[gpu [first [getf system (kw "gpus")]]]]]
                  (rows [
                    [
                      cond
                      [
                        gpu
                        (rows [
                          [setf [getf sample (kw "util")] [max 0 [min 100 [getf gpu (kw "busy")]]]]
                          [[getf sample (kw "used")] [getf gpu (kw "vram-used")]]
                          [[getf sample (kw "total")] [getf gpu (kw "vram-total")]]
                          [[getf sample (kw "temp")] [getf gpu (kw "temperature")]]
                          [[getf sample (kw "failures")] 0]
                        ])
                      ]
                    ]
                    [[system [setf [getf sample (kw "failures")] ["1+" [getf sample (kw "failures") 0]]]]]
                  ])
                ])
            ])
          ])
          sample
        ])
    ])
  blank
  ({
    module,
    state,
  }:
    rows [
      [defun bar--target [module state]]
      ({gpu}:
        rows [
          [let' [[gpu [getf state (kw "gpu")]]]]
          (rows [
            [ecase module]
            [[(kw "cpu") [getf [getf state (kw "cpu")] (kw "percent") 0]]]
            [[(kw "memory") [getf [getf state (kw "memory")] (kw "percent") 0]]]
            [[(kw "gpu") [getf gpu (kw "util") 0]]]
            [
              [
                (kw "vram")
                (rows [
                  [if' [plusp [or' [getf gpu (kw "total")] 0]]]
                  [[round ["*" 100 [or' [getf gpu (kw "used")] 0]] [getf gpu (kw "total")]]]
                  0
                ])
              ]
            ]
          ])
        ])
    ])
  blank
  ({
    m,
    target,
    push',
  }:
    rows [
      [defun bar--metric [m target push']]
      ({
        m',
        old,
      }:
        rows [
          [let' [[m' [copy-list m]] [old [getf m (kw "target")]]]]
          (rows [
            [when [and old [or' [">=" ["-" target old] 25] [and [">=" target 90] ["<" old 90]]]]]
            [[setf [getf m' (kw "flash-at")] [hud--now]]]
          ])
          (rows [
            [when push']
            [[setf [getf m' (kw "history")] [last [append [getf m' (kw "history")] [list target]] [getf (constant bar) (kw "history")]]]]
          ])
          [[setf [getf m' (kw "target")] target]]
          (rows [
            [when [or' [null' [getf m' (kw "shown")]] ["<" [abs ["-" target [getf m' (kw "shown")]]] 3]]]
            [[setf [getf m' (kw "shown")] [float target (double 1)]]]
          ])
          m'
        ])
    ])
  blank
  ({
    m,
    dt,
  }:
    rows [
      [defun bar--ease [m dt]]
      ({
        m',
        shown,
        target,
        next,
      }:
        rows [
          [
            "let*"
            (rows [
              [[m' [copy-list m]] [shown [getf m' (kw "shown")]] [target [getf m' (kw "target")]]]
              [[next ["+" target ["*" ["-" shown target] [exp ["-" ["/" dt [getf (constant bar) (kw "tau")]]]]]]]]
            ])
          ]
          [[setf [getf m' (kw "shown")] [if' ["<" [abs ["-" next target]] 0.3] [float target (double 1)] next]]]
          m'
        ])
    ])
  blank
  ({m}:
    rows [
      [defun bar--moving-p [m]]
      (rows [
        [or' ["/=" [getf m (kw "shown")] [getf m (kw "target")]]]
        [[plusp [hud--decay [getf m (kw "flash-at")] [getf (constant bar) (kw "flash")]]]]
      ])
    ])
  blank
  ({
    p,
    value',
    accent,
    zones,
  }:
    rows [
      [defun bar--segments [p value' accent and-optional [zones t]]]
      ({
        count,
        filled,
      }:
        rows [
          [
            "let*"
            (rows [
              [[count [getf (constant bar) (kw "segments")]]]
              [[filled ["*" count [max 0 [min 1 value']]]]]
            ])
          ]
          (rows [
            [ui (kw "row") (kw "gap") 1 (kw "align") (kw "center")]
            [
              (kw "children")
              ({
                i,
                lit,
              }:
                rows [
                  [loop for i below count]
                  [for lit "=" [max 0 [min 1 ["-" filled i]]]]
                  [
                    collect
                    (rows [
                      [ui (kw "rect") (kw "width") 4 (kw "height") 14]
                      [
                        (kw "background")
                        (rows [
                          [hud--mix [hud--off p]]
                          [[if' zones [hud--heat ["*" 100 ["/" ["1+" i] count]] accent p] accent]]
                          lit
                        ])
                      ]
                    ])
                  ]
                ])
            ]
          ])
        ])
    ])
  blank
  ({
    p,
    history,
    accent,
  }:
    rows [
      [defun bar--spark [p history accent]]
      ({
        h,
        count,
        scale,
      }:
        rows [
          [
            "let*"
            (rows [
              [[h 16] [count [length history]]]
              [[scale [max 20 [reduce (function max) history (kw "initial-value") 0]]]]
            ])
          ]
          (rows [
            [ui (kw "row") (kw "gap") 1 (kw "align") (kw "end") (kw "height") h]
            [
              (kw "children")
              (rows [
                [
                  append
                  (rows [
                    [loop repeat ["-" [getf (constant bar) (kw "history")] count]]
                    [collect [ui (kw "rect") (kw "width") 2 (kw "height") 1 (kw "background") [hud--off p]]]
                  ])
                ]
                ({
                  v,
                  i,
                }:
                  rows [
                    [loop for v in' history]
                    [for i from 1]
                    [
                      collect
                      (rows [
                        [ui (kw "rect") (kw "width") 2 (kw "height") [max 1 [round ["*" h v] scale]]]
                        [
                          (kw "background")
                          (rows [
                            [hud--mix [hud--c p (kw "bg")] [hud--heat v accent p]]
                            [["+" 0.3 ["*" 0.7 ["/" i count]]]]
                          ])
                        ]
                      ])
                    ]
                  ])
              ])
            ]
          ])
        ])
    ])
  blank
  ({
    p,
    value',
  }:
    rows [
      [defun bar--temp-color [p value']]
      (rows [
        [cond [[not [realp value']] [hud--dim p]]]
        [[[">=" value' [getf (constant bar) (kw "hot")]] [hud--c p (kw "color1")]]]
        [[[">=" value' ["-" [getf (constant bar) (kw "hot")] 10]] [hud--c p (kw "color3")]]]
        [[t [hud--dim p 0.75]]]
      ])
    ])
  blank
  ({
    p,
    accent,
    label,
    m,
    detail,
    detail-color,
  }:
    rows [
      [defun bar--gauge [p accent label m detail detail-color]]
      ({
        shown,
        color,
        flash,
      }:
        rows [
          [
            "let*"
            (rows [
              [[shown [getf m (kw "shown") 0]]]
              [[color [hud--heat [round shown] accent p]]]
              [[flash [hud--decay [getf m (kw "flash-at")] [getf (constant bar) (kw "flash")]]]]
            ])
          ]
          (rows [
            [hud--panel p color]
            (rows [
              ["list*" [hud--text label 11 [hud--dim p]]]
              (rows [
                [ui (kw "row") (kw "align") (kw "end")]
                [
                  (kw "children")
                  (rows [
                    [list [hud--text [format nil (str "~3D") [round shown]] 16 [hud--mix [hud--c p (kw "fg")] color flash]]]
                    [[hud--text (str "%") 11 [hud--dim p]]]
                  ])
                ]
              ])
              [[bar--segments p ["/" shown 100] accent]]
              [[bar--spark p [getf m (kw "history")] accent]]
              [[when detail [list [hud--text detail 12 [or' detail-color [hud--dim p 0.75]]]]]]
            ])
            [(kw "flash") flash]
          ])
        ])
    ])
  blank
  ({value'}: [defun bar--degrees [value'] [when [realp value'] [format nil (str "~D°") [round value']]]])
  blank
  ({mib}: [defun bar--gib [mib] [when [realp mib] [format nil (str "~,1FG") ["/" mib (double 1024)]]]])
  blank
  ({
    text,
    limit,
  }:
    rows [
      [defun bar--truncate [text limit]]
      [[if' ["<=" [length text] limit] text [concatenate (quote string) [subseq text 0 ["1-" limit]] (str "…")]]]
    ])
  blank
  ({value'}: [defun bar--nonempty [value'] [and [stringp value'] [plusp [length value']] value']])
  blank
  ({
    snapshot,
    state,
    now,
  }:
    rows [
      [defun bar--media [snapshot state now]]
      ({
        service,
        status,
        title,
        artist,
        key,
      }:
        rows [
          [
            "let*"
            (rows [
              [[service [service-state snapshot (kw "mpris")]]]
              [[status [getf service (kw "status")]]]
              [[title [bar--nonempty [getf service (kw "title")]]]]
              [[artist [bar--nonempty [getf service (kw "artist")]]]]
              [[key [list [getf service (kw "player-name")] title status [getf service (kw "position")]]]]
            ])
          ]
          (rows [
            [unless [equal key [getf state (kw "media-key")]]]
            [[setf [getf state (kw "media-key")] key [getf state (kw "media-at")] now]]
          ])
          (rows [
            [
              values
              (rows [
                [when [and title [member status (quote [(str "Playing") (str "Paused")]) (kw "test") (function equal)]]]
                ({
                  length',
                  playing,
                  elapsed,
                  position',
                }:
                  rows [
                    [
                      "let*"
                      (rows [
                        [[length' [or' [getf service (kw "length")] 0]]]
                        [[playing [equal status (str "Playing")]]]
                        [[elapsed [if' playing ["-" now [getf state (kw "media-at") now]] 0]]]
                        [[position' [min length' ["+" [or' [getf service (kw "position")] 0] elapsed]]]]
                      ])
                    ]
                    (rows [
                      [list (kw "playing") playing]
                      [
                        (kw "label")
                        [
                          string-upcase
                          (rows [
                            [bar--truncate [if' artist [format nil (str "~A - ~A") artist title] title]]
                            [[getf (constant bar) (kw "media-width")]]
                          ])
                        ]
                      ]
                      [(kw "value") [if' [plusp length'] ["/" position' length'] 0]]
                    ])
                  ])
              ])
            ]
            state
          ])
        ])
    ])
  blank
  ({
    p,
    color,
    value',
  }:
    rows [
      [defun bar--sweep [p color value']]
      [[ui (kw "progress") (kw "height") 2 (kw "radius") 0 (kw "value") value' (kw "color") color (kw "track") [hud--off p]]]
    ])
  blank
  ({
    color,
    playing,
    now,
  }:
    rows [
      [defun bar--eq [color playing now]]
      (rows [
        [ui (kw "row") (kw "gap") 1 (kw "align") (kw "end") (kw "height") 14]
        [
          (kw "children")
          ({i}:
            rows [
              [loop for i below 5]
              [
                collect
                (rows [
                  [ui (kw "rect") (kw "width") 2]
                  [
                    (kw "height")
                    (rows [
                      [if' playing]
                      [["+" 2 [round ["*" 12 [abs [sin ["+" ["*" now ["+" 5.3 ["*" 2.1 i]]] ["*" 1.7 i]]]]]]]]
                      2
                    ])
                  ]
                  [(kw "background") color]
                ])
              ]
            ])
        ]
      ])
    ])
  blank
  ({
    p,
    state,
    now,
  }:
    rows [
      [defun bar--clock [p state now]]
      ({
        fg,
        accent,
        sec,
        tick,
        frac,
      }:
        rows [
          [
            "let*"
            (rows [
              [[fg [hud--c p (kw "fg")]] [accent [hud--c p (kw "accent")]]]
              [[sec [getf state (kw "sec") 0]]]
              [[tick [hud--decay [getf state (kw "minute-at")] 700]]]
              [[frac ["/" ["+" sec [min 1 ["-" now [getf state (kw "sec-at") now]]]] 60]]]
            ])
          ]
          (rows [
            [hud--panel p accent]
            (rows [
              [list [hud--icon (hex 983376) 14 accent]]
              (rows [
                [ui (kw "column") (kw "gap") 1 (kw "align") (kw "stretch")]
                [
                  (kw "children")
                  (rows [
                    [
                      list
                      (rows [
                        [ui (kw "row") (kw "align") (kw "end")]
                        [
                          (kw "children")
                          (rows [
                            [list [hud--text [getf state (kw "minute")] 18 [hud--mix fg accent tick]]]
                            [[hud--text [format nil (str ":~2,'0D") sec] 12 [hud--dim p]]]
                          ])
                        ]
                      ])
                    ]
                    [[bar--sweep p accent frac]]
                  ])
                ]
              ])
            ])
            [(kw "flash") tick]
          ])
        ])
    ])
  blank
  ({
    p,
    battery,
    label,
  }:
    rows [
      [defun bar--battery [p battery and-optional [label (str "BAT")]]]
      ({
        percent,
        charging,
        color,
      }:
        rows [
          [
            "let*"
            (rows [
              [[percent [round [getf battery (kw "percent") 0]]]]
              [[charging [getf battery (kw "charging")]]]
              [
                [
                  color
                  (rows [
                    [cond [charging [hud--c p (kw "color2")]] [["<" percent 15] [hud--c p (kw "color1")]]]
                    [[["<" percent 30] [hud--c p (kw "color3")]] [t [hud--c p (kw "color2")]]]
                  ])
                ]
              ]
            ])
          ]
          (rows [
            [hud--panel p color]
            (rows [
              ["list*" [hud--text label 11 [hud--dim p]]]
              (rows [
                [ui (kw "row") (kw "align") (kw "end")]
                [
                  (kw "children")
                  (rows [
                    [list [hud--text [format nil (str "~3D") percent] 16 [hud--c p (kw "fg")]]]
                    [[hud--text (str "%") 11 [hud--dim p]]]
                  ])
                ]
              ])
              [[bar--segments p ["/" percent 100] color nil]]
              [[when charging [list [hud--icon (hex 988171) 13 color]]]]
            ])
          ])
        ])
    ])
  blank
  ({
    p,
    network,
  }:
    rows [
      [defun bar--network [p network]]
      ({
        ssid,
        online,
        label,
        color,
      }:
        rows [
          [
            "let*"
            (rows [
              [[ssid [getf network (kw "ssid")]]]
              [[online [getf network (kw "connected")]]]
              [
                [
                  label
                  (rows [
                    [cond [[and online [stringp ssid] [plusp [length ssid]]] [string-upcase [remove [code-char 0] ssid]]]]
                    [[online (str "ONLINE")]]
                    [[t (str "OFFLINE")]]
                  ])
                ]
              ]
              [[color [if' online [hud--c p (kw "color6")] [hud--c p (kw "color1")]]]]
            ])
          ]
          [
            [
              hud--panel
              p
              color
              (rows [
                [list [hud--icon [if' online (hex 984489) (hex 984490)] 14 color]]
                [[hud--text [bar--truncate label 20] 14 [hud--c p (kw "fg")]]]
              ])
            ]
          ]
        ])
    ])
  blank
  ({state}:
    rows [
      [defun bar--gpu-p [state]]
      ({gpu}:
        rows [
          [let' [[gpu [getf state (kw "gpu")]]]]
          [[and [getf gpu (kw "util")] ["<" [getf gpu (kw "failures") 0] 3]]]
        ])
    ])
  blank
  ({
    module,
    p,
    state,
    snapshot,
    metrics,
    media,
    now,
  }:
    rows [
      [defun bar--module [module p state snapshot metrics media now]]
      ({
        cpu,
        gpu,
      }:
        rows [
          [let' [[cpu [getf state (kw "cpu")]] [gpu [getf state (kw "gpu")]]]]
          (rows [
            [ecase module]
            [[(kw "time") [bar--clock p state now]]]
            [
              [
                (kw "date")
                (rows [
                  [hud--panel p [hud--c p (kw "color4")]]
                  (rows [
                    [list [hud--icon (hex 983277) 14 [hud--c p (kw "color4")]]]
                    [[hud--text [string-upcase [clock-text [getf (constant bar) (kw "date")]]] 14 [hud--c p (kw "fg")]]]
                  ])
                ])
              ]
            ]
            [[(kw "battery") [bar--battery p [service-state snapshot (kw "battery")]]]]
            [[(kw "network") [bar--network p [service-state snapshot (kw "network")]]]]
            [
              [
                (kw "frame")
                ({frame}:
                  rows [
                    [let' [[frame [state-value snapshot (kw "frame-battery")]]]]
                    (rows [
                      [when [getf frame (kw "percent")]]
                      (rows [
                        [
                          bar--battery
                          p
                          (rows [
                            [list (kw "percent") [getf frame (kw "percent")]]
                            [(kw "charging") [not [equal [getf frame (kw "status")] (str "Discharging")]]]
                          ])
                        ]
                        (str "VR")
                      ])
                    ])
                  ])
              ]
            ]
            [
              [
                (kw "media")
                (rows [
                  [when media]
                  ({color}:
                    rows [
                      [let' [[color [hud--c p (kw "color5")]]]]
                      (rows [
                        [hud--panel p color]
                        (rows [
                          [list [bar--eq color [getf media (kw "playing")] now]]
                          (rows [
                            [ui (kw "column") (kw "gap") 3 (kw "align") (kw "stretch")]
                            [
                              (kw "children")
                              (rows [
                                [list [hud--text [getf media (kw "label")] 13 [hud--c p (kw "fg")]]]
                                [[bar--sweep p color [getf media (kw "value")]]]
                              ])
                            ]
                          ])
                        ])
                      ])
                    ])
                ])
              ]
            ]
            [
              [
                (kw "cpu")
                (rows [
                  [bar--gauge p [hud--c p (kw "color4")] (str "CPU") [getf metrics (kw "cpu")]]
                  [[bar--degrees [getf cpu (kw "temp")]] [bar--temp-color p [getf cpu (kw "temp")]]]
                ])
              ]
            ]
            [
              [
                (kw "memory")
                (rows [
                  [bar--gauge p [hud--c p (kw "color5")] (str "MEM") [getf metrics (kw "memory")]]
                  [[bar--gib [getf [getf state (kw "memory")] (kw "used")]] nil]
                ])
              ]
            ]
            [
              [
                (kw "gpu")
                (rows [
                  [when [bar--gpu-p state]]
                  (rows [
                    [bar--gauge p [hud--c p (kw "color2")] (str "GPU") [getf metrics (kw "gpu")]]
                    [[bar--degrees [getf gpu (kw "temp")]] [bar--temp-color p [getf gpu (kw "temp")]]]
                  ])
                ])
              ]
            ]
            [
              [
                (kw "vram")
                (rows [
                  [when [bar--gpu-p state]]
                  [[bar--gauge p [hud--c p (kw "color6")] (str "VRAM") [getf metrics (kw "vram")] [bar--gib [getf gpu (kw "used")]] nil]]
                ])
              ]
            ]
          ])
        ])
    ])
  blank
  ({
    modules,
    panels,
  }:
    rows [
      [defun bar--surfaces [modules panels]]
      ({
        h,
        gap',
        margin,
        inset,
        pair,
        seam,
      }:
        rows [
          [
            "let*"
            (rows [
              [[h ["+" [getf (constant hud) (kw "height")] [getf (constant hud) (kw "shadow")]]]]
              [[gap' [getf (constant bar) (kw "gap")]]]
              [[margin [getf (constant bar) (kw "margin")]]]
              [[inset [getf (constant bar) (kw "inset")]]]
              [[pair [getf (constant bar) (kw "center-between")]]]
              [
                [
                  seam
                  ({
                    a,
                    b,
                    index,
                  }:
                    rows [
                      [loop for [a b] on modules]
                      [for index from 1]
                      [when [and b [eq a [first pair]] [eq b [second pair]]] return index]
                    ])
                ]
              ]
            ])
          ]
          ({half}:
            rows [
              [
                flet
                [
                  ({
                    list',
                    justify,
                    padding,
                  }:
                    rows [
                      [half [list' justify padding]]
                      (rows [
                        [ui (kw "row") (kw "width") 0 (kw "grow") 1 (kw "height") h (kw "gap") gap' (kw "justify") justify (kw "padding") padding]
                        [(kw "children") [remove nil list']]
                      ])
                    ])
                ]
              ]
              ({edge}:
                rows [
                  [loop for edge in' [getf (constant bar) (kw "edges")]]
                  [
                    collect
                    (rows [
                      [shell-surface edge]
                      (rows [
                        [ui (kw "row") (kw "height") h (kw "justify") (kw "center")]
                        [
                          (kw "children")
                          (rows [
                            [if' seam]
                            (rows [
                              [list [half [subseq panels 0 seam] (kw "end") [list 0 inset 0 0]]]
                              [[half [nthcdr seam panels] (kw "start") [list 0 0 0 inset]]]
                            ])
                            [[list [ui (kw "row") (kw "height") h (kw "gap") gap' (kw "children") [remove nil panels]]]]
                          ])
                        ]
                      ])
                      [(kw "anchors") [if' seam [list edge (kw "left") (kw "right")] [list edge]]]
                      [(kw "margin") [if' [eq edge (kw "top")] [list margin 0 0 0] [list 0 0 margin 0]]]
                      [(kw "height") h (kw "layer") (kw "overlay")]
                      [(kw "exclusive-zone") 0]
                      [(kw "background") (str "#00000000") (kw "click-through") t]
                    ])
                  ]
                ])
            ])
        ])
    ])
  blank
  ({
    snapshot,
    state,
    event,
  }:
    rows [
      [
        define-extension
        (str "bar")
        (rows [
          [(kw "reads") [(kw "services") (kw "system") (kw "data")]]
          [
            (kw "state")
            (rows [
              [list (kw "cpu") nil (kw "memory") nil (kw "gpu") nil (kw "metrics") nil (kw "at") nil]
              [(kw "sec") nil (kw "sec-at") nil (kw "minute") nil (kw "minute-at") nil]
            ])
          ]
        ])
      ]
      [[snapshot state event]]
      ({
        modules,
        probes,
        probe,
      }:
        rows [
          [
            "let*"
            (rows [
              [[modules [getf (constant bar) (kw "modules")]]]
              [
                [
                  probes
                  [
                    remove-duplicates
                    ({
                      module,
                      source,
                    }:
                      rows [
                        [loop for module in' modules]
                        [for source "=" [second [assoc module (constant bar-probes)]]]
                        [when source collect source]
                      ])
                  ]
                ]
              ]
              [[probe [and [eq [getf event (kw "type")] (kw "timer")] [find [getf event (kw "name")] probes]]]]
            ])
          ]
          (rows [
            [when probe]
            [[setf [getf state probe] [bar--sample probe [getf state probe] [context snapshot (kw "system")]]]]
          ])
          ({
            p,
            now,
            dt,
            metrics,
            sec,
            minute,
          }:
            rows [
              [
                "let*"
                (rows [
                  [[p [state-value snapshot (kw "hud-palette")]]]
                  [[now [hud--now]]]
                  [[dt [if' [getf state (kw "at")] ["-" now [getf state (kw "at")]] 0]]]
                  [
                    [
                      metrics
                      ({
                        module,
                        source,
                      }:
                        rows [
                          [loop for [module source] in' (constant bar-probes)]
                          [when [member module modules]]
                          (at 8 [
                            append
                            [
                              list
                              module
                              (rows [
                                [
                                  bar--ease
                                  (rows [
                                    [bar--metric [getf [getf state (kw "metrics")] module]]
                                    [[bar--target module state]]
                                    [[eq source probe]]
                                  ])
                                ]
                                dt
                              ])
                            ]
                          ])
                        ])
                    ]
                  ]
                  [[sec [or' [parse-integer [clock-text (str "%S")] (kw "junk-allowed") t] 0]]]
                  [[minute [clock-text [getf (constant bar) (kw "time")]]]]
                ])
              ]
              [[setf [getf state (kw "metrics")] metrics [getf state (kw "at")] now]]
              (rows [
                [unless [eql sec [getf state (kw "sec")]]]
                [[setf [getf state (kw "sec")] sec [getf state (kw "sec-at")] now]]
              ])
              (rows [
                [unless [equal minute [getf state (kw "minute")]]]
                [[setf [getf state (kw "minute-at")] [when [getf state (kw "minute")] now] [getf state (kw "minute")] minute]]
              ])
              ({
                media,
                next,
              }:
                rows [
                  [multiple-value-bind [media next] [if' [member (kw "media") modules] [bar--media snapshot state now] [values nil state]]]
                  [[setf state next]]
                  ({
                    cpu-temp,
                    gpu-temp,
                    limit,
                    hot,
                    moving,
                    panels,
                  }:
                    rows [
                      [
                        "let*"
                        (rows [
                          [[cpu-temp [getf [getf state (kw "cpu")] (kw "temp")]]]
                          [[gpu-temp [getf [getf state (kw "gpu")] (kw "temp")]]]
                          [[limit [getf (constant bar) (kw "hot")]]]
                          [[hot [or' [and [realp cpu-temp] [">=" cpu-temp limit]] [and [realp gpu-temp] [">=" gpu-temp limit]]]]]
                          [[moving ({m}: [loop for [nil m] on metrics by (function cddr) thereis [bar--moving-p m]])]]
                          [
                            [
                              panels
                              ({module}:
                                rows [
                                  [loop for module in' modules]
                                  [collect [bar--module module p state snapshot metrics media now]]
                                ])
                            ]
                          ]
                        ])
                      ]
                      (rows [
                        [values state]
                        (rows [
                          [append [list [interval (kw "clock") [getf (constant bar) (kw "clock-tick")]]]]
                          ({source}:
                            rows [
                              [loop for source in' probes]
                              [when ["<" [getf [getf state source] (kw "failures") 0] 3]]
                              (at 8 [collect [interval source [getf [getf (constant bar) (kw "sample")] source]]])
                            ])
                          [[when moving [list [interval (kw "fast") [getf (constant bar) (kw "tick")]]]]]
                          [[list [publish-state (kw "hud-hot") [and hot t]]]]
                          [[bar--surfaces modules panels]]
                        ])
                        nil
                      ])
                    ])
                ])
            ])
        ])
    ])
])
