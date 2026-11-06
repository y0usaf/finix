{
  and,
  and-key,
  and-optional,
  append,
  at,
  below,
  blank,
  cassette,
  char,
  char-code,
  clock-text,
  collect,
  concatenate,
  cond,
  constant,
  defun,
  defvar,
  digit-char-p,
  dot,
  double,
  ecase,
  eq,
  equal,
  first,
  for,
  format,
  from,
  function,
  getf,
  if',
  in-package,
  kw,
  lambda,
  length,
  let',
  list,
  loop,
  map,
  max,
  member,
  min,
  nil,
  oddp,
  on,
  or',
  parse-integer,
  plusp,
  probe--gpu-p,
  quote,
  realp,
  remove,
  remove-if,
  repeat,
  return,
  round,
  rows,
  second,
  service-state,
  special,
  state-value,
  str,
  string,
  string-upcase,
  stringp,
  subseq,
  substitute,
  t,
  ui,
  uninterned,
  when,
  ...
}: ({
  cassette--px',
  cassette-mode,
  cassette--c',
  cassette--text,
  cassette--engraved,
  cassette--ghost,
  cassette--window',
  cassette--zone',
  cassette--ladder,
  cassette--led',
  cassette--gauge,
  cassette--degrees',
  cassette--gib',
  cassette--hot-p',
  cassette--fit',
  cassette--reel',
  cassette--media,
  cassette--counter,
  cassette--module',
  cassette--grille',
  cassette--groove,
  cassette--plate',
  cassette--shadow,
  cassette--height',
  cassette--split',
}: [
  [in-package (uninterned "tomoe-user")]
  blank
  ({n}: [defun cassette--px' [n] [max 1 [round ["*" n [getf (constant cassette) (kw "scale")]]]]])
  blank
  [defvar (special cassette-mode) (kw "dark")]
  blank
  ({key}: [defun cassette--c' [key] [getf [getf [getf (constant cassette) (kw "colors")] (special cassette-mode)] key]])
  blank
  ({
    text,
    color,
  }:
    rows [
      [defun cassette--text [text color]]
      [[ui (kw "text") (kw "text") text (kw "size") [cassette--px' 11] (kw "line-height") [cassette--px' 11] (kw "color") color (kw "font") [getf (constant cassette) (kw "font")]]]
    ])
  blank
  ({
    text,
    color,
  }:
    rows [
      [defun cassette--engraved [text color]]
      [
        [
          ui
          (kw "stack")
          (kw "children")
          (rows [
            [list [ui (kw "column") (kw "padding") (quote [1 0 0 0]) (kw "children") [list [cassette--text text [cassette--c' (kw "shine")]]]]]
            [[cassette--text text color]]
          ])
        ]
      ]
    ])
  blank
  ({text}: [defun cassette--ghost [text] [map (quote string) ({c}: [lambda [c] [if' [digit-char-p c] (char "8") c]]) text]])
  blank
  ({
    text,
    face,
    rim,
    ghost,
    ink,
    shown,
  }:
    rows [
      [
        defun
        cassette--window'
        (rows [
          [text and-key [face [cassette--c' (kw "lcd")]] [rim [cassette--c' (kw "rim")]] [ghost [cassette--c' (kw "ghost")]]]
          (at 11 [[ink [cassette--c' (kw "ink")]] [shown text]])
        ])
      ]
      (rows [
        [ui (kw "column") (kw "background") face (kw "border") 1 (kw "border-color") rim]
        [
          (kw "children")
          (rows [
            [list [ui (kw "rect") (kw "height") 1 (kw "background") rim]]
            (rows [
              [ui (kw "row") (kw "height") [cassette--px' 11] (kw "align") (kw "center") (kw "padding") [list 0 [cassette--px' 3] 0 [cassette--px' 3]]]
              [
                (kw "children")
                [
                  list
                  [
                    ui
                    (kw "stack")
                    (kw "children")
                    (rows [
                      [list [cassette--text [cassette--ghost text] ghost]]
                      [[cassette--text shown ink]]
                    ])
                  ]
                ]
              ]
            ])
          ])
        ]
      ])
    ])
  blank
  ({x}:
    rows [
      [defun cassette--zone' [x]]
      [[cond [[">" x 0.84] [cassette--c' (kw "red")]] [[">" x 0.6] [cassette--c' (kw "amber")]] [t [cassette--c' (kw "green")]]]]
    ])
  blank
  ({fraction}:
    rows [
      [defun cassette--ladder [fraction]]
      ({
        count,
        lit,
      }:
        rows [
          [
            "let*"
            (rows [
              [[count [getf (constant cassette) (kw "segments")]]]
              [[lit [round ["*" count [max 0 [min 1 fraction]]]]]]
            ])
          ]
          (rows [
            [ui (kw "row") (kw "gap") [cassette--px' 1] (kw "align") (kw "center")]
            [
              (kw "children")
              ({i}:
                rows [
                  [loop for i below count]
                  [
                    collect
                    (rows [
                      [ui (kw "rect") (kw "width") [cassette--px' 4] (kw "height") [cassette--px' 8]]
                      [(kw "background") [if' ["<" i lit] [cassette--zone' ["/" ["1+" i] count]] [cassette--c' (kw "led-off")]]]
                    ])
                  ]
                ])
            ]
          ])
        ])
    ])
  blank
  ({on'}:
    rows [
      [defun cassette--led' [on']]
      [[ui (kw "rect") (kw "width") [cassette--px' 3] (kw "height") [cassette--px' 3] (kw "background") [if' on' [cassette--c' (kw "orange")] [cassette--c' (kw "led-off")]]]]
    ])
  blank
  ({
    label,
    percent,
    detail,
    hot,
  }:
    rows [
      [defun cassette--gauge [label percent detail and-optional hot]]
      ({percent'}:
        rows [
          [let' [[percent' [max 0 [min 100 [round [or' percent 0]]]]]]]
          (rows [
            [list [cassette--engraved label [cassette--c' (kw "ink")]]]
            [[cassette--window' [format nil (str "~3D%") percent']]]
            [[cassette--ladder ["/" percent' 100]]]
            [[when detail [cassette--engraved detail [if' hot [cassette--c' (kw "orange")] [cassette--c' (kw "dim")]]]]]
          ])
        ])
    ])
  blank
  ({value'}: [defun cassette--degrees' [value'] [if' [realp value'] [format nil (str "~2D°") [max 0 [min 99 [round value']]]] (str "--°")]])
  blank
  ({mib}: [defun cassette--gib' [mib] [if' [realp mib] [format nil (str "~4,1FG") ["/" mib (double 1024)]] (str "--.-G")]])
  blank
  ({value'}: [defun cassette--hot-p' [value'] [and [realp value'] [">=" value' [getf (constant cassette) (kw "hot")]]]])
  blank
  ({
    text,
    width,
  }:
    rows [
      [defun cassette--fit' [text width]]
      ({clean}:
        rows [
          [let' [[clean [string-upcase [remove-if ({c}: [lambda [c] [">" [char-code c] 126]]) text]]]]]
          [[format nil (str "~vA") width [if' [">" [length clean] width] [concatenate (quote string) [subseq clean 0 ["-" width 2]] (str "..")] clean]]]
        ])
    ])
  blank
  ({amount}:
    rows [
      [defun cassette--reel' [amount]]
      ({
        box,
        hub,
        size,
      }:
        rows [
          [
            "let*"
            (rows [
              [[box [cassette--px' 12]]]
              [[hub [cassette--px' 4]]]
              [[size ["+" hub ["*" 2 [round ["*" ["-" box hub] [max 0 [min 1 amount]]] 2]]]]]
            ])
          ]
          (rows [
            [ui (kw "stack") (kw "width") box (kw "height") box]
            [
              (kw "children")
              (rows [
                [
                  list
                  (rows [
                    [ui (kw "row") (kw "width") box (kw "height") box (kw "justify") (kw "center") (kw "align") (kw "center")]
                    [
                      (kw "children")
                      [
                        list
                        (rows [
                          [ui (kw "circular-progress") (kw "size") size (kw "thickness") [max 1 ["/" ["-" size hub] 2]] (kw "value") 1]
                          [(kw "color") [cassette--c' (kw "tape")] (kw "track") [cassette--c' (kw "tape")]]
                        ])
                      ]
                    ]
                  ])
                ]
                (rows [
                  [ui (kw "row") (kw "width") box (kw "height") box (kw "justify") (kw "center") (kw "align") (kw "center")]
                  [
                    (kw "children")
                    [
                      list
                      (rows [
                        [ui (kw "circular-progress") (kw "size") hub (kw "thickness") 1 (kw "value") 1]
                        [(kw "color") [cassette--c' (kw "ink")] (kw "track") [cassette--c' (kw "ink")]]
                      ])
                    ]
                  ]
                ])
              ])
            ]
          ])
        ])
    ])
  blank
  ({snapshot}:
    rows [
      [defun cassette--media [snapshot]]
      ({
        service,
        status,
        title,
        artist,
        length',
        position',
        played,
      }:
        rows [
          [
            "let*"
            (rows [
              [[service [service-state snapshot (kw "mpris")]]]
              [[status [getf service (kw "status")]]]
              [[title [getf service (kw "title")]]]
              [[artist [getf service (kw "artist")]]]
              [[length' [getf service (kw "length")]]]
              [[position' [getf service (kw "position")]]]
              [[played [if' [and [realp length'] [plusp length'] [realp position']] [max 0 [min 1 ["/" position' length']]] 0]]]
            ])
          ]
          (rows [
            [when [and [stringp title] [plusp [length title]] [member status (quote [(str "Playing") (str "Paused")]) (kw "test") (function equal)]]]
            (rows [
              [list [cassette--led' [equal status (str "Playing")]]]
              (rows [
                [ui (kw "row") (kw "height") [cassette--px' 12] (kw "align") (kw "center") (kw "gap") [cassette--px' 3] (kw "padding") [list 0 [cassette--px' 4] 0 0]]
                [(kw "background") [cassette--c' (kw "paper")] (kw "border") 1 (kw "border-color") [cassette--c' (kw "rim")]]
                [
                  (kw "children")
                  (rows [
                    [list [ui (kw "rect") (kw "width") [cassette--px' 2] (kw "height") ["-" [cassette--px' 12] 2] (kw "background") [cassette--c' (kw "orange")]]]
                    [[ui (kw "rect") (kw "width") [cassette--px' 2] (kw "height") ["-" [cassette--px' 12] 2] (kw "background") [cassette--c' (kw "teal")]]]
                    [[cassette--reel' ["-" 1 played]]]
                    (rows [
                      [
                        cassette--text
                        (rows [
                          [
                            cassette--fit'
                            (rows [
                              [if' [and [stringp artist] [plusp [length artist]]]]
                              [[format nil (str "~A - ~A") artist title]]
                              title
                            ])
                          ]
                          [[getf (constant cassette) (kw "media-width")]]
                        ])
                      ]
                      [[cassette--c' (kw "ink")]]
                    ])
                    [[cassette--reel' played]]
                  ])
                ]
              ])
            ])
          ])
        ])
    ])
  blank
  (rows [
    [defun cassette--counter []]
    ({time}:
      rows [
        [let' [[time [clock-text [getf (constant cassette) (kw "time")]]]]]
        [
          [
            list
            (rows [
              [cassette--window' time (kw "face") [cassette--c' (kw "counter")] (kw "rim") [cassette--c' (kw "ink")] (kw "ghost") [cassette--c' (kw "counter-ghost")]]
              (at 23 [(kw "ink") [cassette--c' (kw "amber")]])
              (at 23 [(kw "shown") [if' [oddp [parse-integer [clock-text (str "%S")]]] [substitute (char "Space") (char ":") time] time]])
            ])
          ]
        ]
      ])
  ])
  blank
  ({
    module,
    state,
    snapshot,
  }:
    rows [
      [defun cassette--module' [module state snapshot]]
      ({
        cpu,
        memory,
        gpu,
      }:
        rows [
          [let' [[cpu [getf state (kw "cpu")]] [memory [getf state (kw "memory")]] [gpu [getf state (kw "gpu")]]]]
          (rows [
            [ecase module]
            [[(kw "time") [cassette--counter]]]
            [[(kw "date") [list [cassette--engraved [string-upcase [clock-text [getf (constant cassette) (kw "date")]]] [cassette--c' (kw "ink")]]]]]
            [[(kw "media") [cassette--media snapshot]]]
            [[(kw "cpu") [cassette--gauge (str "CPU") [getf cpu (kw "percent")] [cassette--degrees' [getf cpu (kw "temp")]] [cassette--hot-p' [getf cpu (kw "temp")]]]]]
            [[(kw "memory") [cassette--gauge (str "MEM") [getf memory (kw "percent")] [cassette--gib' [getf memory (kw "used")]]]]]
            [
              [
                (kw "gpu")
                (rows [
                  [when [probe--gpu-p gpu]]
                  [[cassette--gauge (str "GPU") [getf gpu (kw "percent")] [cassette--degrees' [getf gpu (kw "temp")]] [cassette--hot-p' [getf gpu (kw "temp")]]]]
                ])
              ]
            ]
            [
              [
                (kw "vram")
                (rows [
                  [when [probe--gpu-p gpu]]
                  (rows [
                    [cassette--gauge (str "VRAM") [if' [plusp [or' [getf gpu (kw "total")] 0]] [round ["*" 100 [or' [getf gpu (kw "used")] 0]] [getf gpu (kw "total")]] 0]]
                    [[cassette--gib' [getf gpu (kw "used")]]]
                  ])
                ])
              ]
            ]
            [
              [
                (kw "battery")
                ({battery}:
                  rows [
                    [let' [[battery [service-state snapshot (kw "battery")]]]]
                    [[cassette--gauge [if' [getf battery (kw "charging")] (str "CHG") (str "BAT")] [getf battery (kw "percent")] nil]]
                  ])
              ]
            ]
            [
              [
                (kw "network")
                ({
                  network,
                  ssid,
                  online,
                }:
                  rows [
                    ["let*" [[network [service-state snapshot (kw "network")]] [ssid [getf network (kw "ssid")]] [online [getf network (kw "connected")]]]]
                    (rows [
                      [list [cassette--led' online]]
                      (rows [
                        [cassette--engraved [cassette--fit' [cond [[and online [stringp ssid] [plusp [length ssid]]] ssid] [online (str "online")] [t (str "offline")]] 16]]
                        [[cassette--c' (kw "ink")]]
                      ])
                    ])
                  ])
              ]
            ]
            [
              [
                (kw "frame")
                ({battery}:
                  rows [
                    [let' [[battery [state-value snapshot (kw "frame-battery")]]]]
                    (rows [
                      [when [getf battery (kw "percent")]]
                      [[cassette--gauge [if' [equal [getf battery (kw "status")] (str "Discharging")] (str "VR") (str "VR+")] [getf battery (kw "percent")] nil]]
                    ])
                  ])
              ]
            ]
          ])
        ])
    ])
  blank
  (rows [
    [defun cassette--grille' []]
    ({hole}:
      rows [
        [let' [[hole [cassette--px' 1]]]]
        (rows [
          [ui (kw "column") (kw "gap") hole]
          [
            (kw "children")
            (rows [
              [loop repeat 4]
              [
                collect
                (rows [
                  [ui (kw "row") (kw "gap") hole]
                  [(kw "children") [loop repeat 6 collect [ui (kw "rect") (kw "width") hole (kw "height") hole (kw "background") [cassette--c' (kw "hole")]]]]
                ])
              ]
            ])
          ]
        ])
      ])
  ])
  blank
  (rows [
    [defun cassette--groove []]
    [
      [
        ui
        (kw "row")
        (kw "children")
        (rows [
          [list [ui (kw "rect") (kw "width") 1 (kw "height") [cassette--px' 10] (kw "background") [cassette--c' (kw "groove")]]]
          [[ui (kw "rect") (kw "width") 1 (kw "height") [cassette--px' 10] (kw "background") [cassette--c' (kw "shine")]]]
        ])
      ]
    ]
  ])
  blank
  ({
    items,
    grille,
    edge,
  }:
    rows [
      [defun cassette--plate' [items grille edge]]
      ({
        parts,
        body,
      }:
        rows [
          [
            "let*"
            (rows [
              [
                [
                  parts
                  ({
                    item,
                    rest',
                  }:
                    rows [
                      [loop for [item dot rest'] on [remove nil items]]
                      [collect [ui (kw "row") (kw "gap") [cassette--px' 4] (kw "align") (kw "center") (kw "children") [remove nil item]]]
                      [when rest' collect [cassette--groove]]
                    ])
                ]
              ]
              [
                [
                  body
                  (rows [
                    [ui (kw "row") (kw "height") [cassette--px' 16] (kw "align") (kw "center") (kw "gap") [cassette--px' 6]]
                    [(kw "padding") [list 0 [cassette--px' 6] 0 [cassette--px' 6]]]
                    [
                      (kw "children")
                      (rows [
                        [append [when [member grille (quote [(kw "start") (kw "both")])] [list [cassette--grille']]]]
                        parts
                        [[when [member grille (quote [(kw "end") (kw "both")])] [list [cassette--grille']]]]
                      ])
                    ]
                  ])
                ]
              ]
            ])
          ]
          (rows [
            [when parts]
            ({plate}:
              rows [
                [
                  let'
                  [
                    [
                      plate
                      (rows [
                        [ui (kw "column") (kw "align") (kw "stretch") (kw "background") [cassette--c' (kw "face")] (kw "border") 1 (kw "border-color") [cassette--c' (kw "ink")]]
                        [
                          (kw "children")
                          (rows [
                            [list [ui (kw "rect") (kw "height") 1 (kw "background") [cassette--c' (kw "shine")]]]
                            body
                            [[ui (kw "rect") (kw "height") 1 (kw "background") [cassette--c' (kw "shade")]]]
                          ])
                        ]
                      ])
                    ]
                  ]
                ]
                (rows [
                  [if' [eq edge (kw "top")]]
                  (rows [
                    [ui (kw "column") (kw "align") (kw "stretch")]
                    [
                      (kw "children")
                      [
                        list
                        plate
                        (rows [
                          [ui (kw "row") (kw "height") [cassette--shadow] (kw "padding") [list 0 0 0 [cassette--shadow]]]
                          [(kw "children") [list [ui (kw "rect") (kw "grow") 1 (kw "height") [cassette--shadow] (kw "background") [cassette--c' (kw "shadow")]]]]
                        ])
                      ]
                    ]
                  ])
                  plate
                ])
              ])
          ])
        ])
    ])
  blank
  [defun cassette--shadow [] [cassette--px' 2]]
  blank
  ({edge}: [defun cassette--height' [edge] ["+" [cassette--px' 16] 4 [if' [eq edge (kw "top")] [cassette--shadow] 0]]])
  blank
  (rows [
    [defun cassette--split' []]
    ({pair}:
      rows [
        [let' [[pair [getf (constant cassette) (kw "center-between")]]]]
        ({
          a,
          b,
          index,
        }:
          rows [
            [loop for [a b] on [getf (constant cassette) (kw "modules")]]
            [for index from 1]
            [when [and b [eq a [first pair]] [eq b [second pair]]] return index]
          ])
      ])
  ])
])
