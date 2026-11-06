{
  across,
  and,
  and-optional,
  and-rest,
  append,
  apply,
  at,
  blank,
  cassette,
  cassette--c,
  cassette--degrees,
  cassette--fit,
  cassette--gib,
  cassette--grille,
  cassette--height,
  cassette--hot-p,
  cassette--led,
  cassette--module,
  cassette--plate,
  cassette--px,
  cassette--reel,
  cassette--split,
  cassette--window,
  cassette--zone,
  char,
  clock-text,
  collect,
  constant,
  context,
  deck--narrow-p,
  declare,
  define-extension,
  defun,
  destructuring-bind,
  do,
  dolist,
  dot,
  downto,
  ecase,
  eq,
  equal,
  find,
  for,
  format,
  from,
  function,
  getf,
  if',
  ignore,
  in',
  in-package,
  intern,
  interval,
  kw,
  lambda,
  length,
  let',
  list,
  loop,
  max,
  member,
  min,
  nil,
  nthcdr,
  on,
  or',
  plusp,
  position-if,
  probe--gpu-p,
  probe--sample,
  publish-state,
  quote,
  realp,
  remove,
  remove-if-not,
  round,
  rows,
  service-state,
  setf,
  shell-surface,
  special,
  state-value,
  str,
  string,
  string-right-trim,
  string-upcase,
  stringp,
  subseq,
  t,
  thereis,
  ui,
  uninterned,
  values,
  when,
  while,
  with',
  ...
}: ({
  spine--parts,
  spine--text,
  spine--groove,
  spine--ladder,
  spine--gauge,
  spine--counter,
  spine--date,
  spine--stacked,
  spine--media,
  spine--module,
  spine--cell,
  spine--run,
  spine--tray-height,
  spine--body,
  spine--covered-p,
  spine--fullscreen-p,
  spine--plates,
}: [
  [in-package (uninterned "tomoe-user")]
  blank
  ({text}:
    rows [
      [defun spine--parts [text]]
      ({
        start,
        i,
        part,
      }:
        rows [
          [loop with' start "=" 0]
          [for i "=" [position-if ({c}: [lambda [c] [member c (quote [(char ":") (char "Space")])]]) text (kw "start") start]]
          [for part "=" [subseq text start i]]
          [when [plusp [length part]] collect part]
          [while i do [setf start ["1+" i]]]
        ])
    ])
  blank
  ({
    text,
    color,
    size,
  }:
    rows [
      [defun spine--text [text color and-optional [size 11]]]
      (rows [
        [ui (kw "text") (kw "text") text (kw "size") [cassette--px size] (kw "line-height") [cassette--px size] (kw "color") color]
        [(kw "font") [getf (constant cassette) (kw "font")]]
      ])
    ])
  blank
  (rows [
    [defun spine--groove []]
    [[ui (kw "rect") (kw "height") 1 (kw "background") [cassette--c (kw "groove")]]]
  ])
  blank
  ({fraction}:
    rows [
      [defun spine--ladder [fraction]]
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
            [ui (kw "column") (kw "gap") [cassette--px 1] (kw "align") (kw "center")]
            [
              (kw "children")
              ({i}:
                rows [
                  [loop for i from ["1-" count] downto 0]
                  [
                    collect
                    (rows [
                      [ui (kw "rect") (kw "width") [cassette--px 8] (kw "height") [cassette--px 3]]
                      [(kw "background") [if' ["<" i lit] [cassette--zone ["/" ["1+" i] count]] [cassette--c (kw "led-off")]]]
                    ])
                  ]
                ])
            ]
          ])
        ])
    ])
  blank
  ({
    label,
    percent,
    detail,
    hot,
  }:
    rows [
      [defun spine--gauge [label percent detail and-optional hot]]
      ({percent'}:
        rows [
          [let' [[percent' [max 0 [min 100 [round [or' percent 0]]]]]]]
          (rows [
            [ui (kw "column") (kw "align") (kw "center") (kw "gap") [cassette--px 2]]
            [
              (kw "children")
              (rows [
                [remove nil]
                (rows [
                  [list [spine--text label [cassette--c (kw "dim")] 7]]
                  [[spine--ladder ["/" percent' 100]]]
                  (rows [
                    [ui (kw "row") (kw "align") (kw "end")]
                    [
                      (kw "children")
                      (rows [
                        [list [spine--text [format nil (str "~D") percent'] [cassette--c (kw "ink")]]]
                        [[spine--text (str "%") [cassette--c (kw "dim")] 7]]
                      ])
                    ]
                  ])
                  [[when detail [spine--text detail [if' hot [cassette--c (kw "orange")] [cassette--c (kw "dim")]] 7]]]
                ])
              ])
            ]
          ])
        ])
    ])
  blank
  (rows [
    [defun spine--counter []]
    (rows [
      [ui (kw "column") (kw "align") (kw "stretch") (kw "gap") [cassette--px 1]]
      [
        (kw "children")
        ({part}:
          rows [
            [loop for part in' [spine--parts [clock-text [getf (constant cassette) (kw "time")]]]]
            [
              collect
              (rows [
                [cassette--window part (kw "face") [cassette--c (kw "counter")] (kw "rim") [cassette--c (kw "rim")]]
                (at 23 [(kw "ghost") [cassette--c (kw "counter-ghost")] (kw "ink") [cassette--c (kw "amber")]])
              ])
            ]
          ])
      ]
    ])
  ])
  blank
  (rows [
    [defun spine--date []]
    ({
      day,
      date,
      month,
      rest',
    }:
      rows [
        [destructuring-bind [and-optional day date month and-rest rest']]
        [[spine--parts [string-upcase [clock-text [getf (constant cassette) (kw "date")]]]]]
        [[declare [ignore rest']]]
        (rows [
          [ui (kw "column") (kw "align") (kw "center") (kw "gap") [cassette--px 2]]
          [
            (kw "children")
            (rows [
              [remove nil]
              (rows [
                [list [when day [spine--text day [cassette--c (kw "dim")] 7]]]
                [[when date [spine--text date [cassette--c (kw "ink")]]]]
                [[when month [spine--text month [cassette--c (kw "dim")] 7]]]
              ])
            ])
          ]
        ])
      ])
  ])
  blank
  ({
    text,
    color,
  }:
    rows [
      [defun spine--stacked [text color]]
      (rows [
        [ui (kw "column") (kw "align") (kw "center")]
        [
          (kw "children")
          ({c}:
            rows [
              [loop for c across [string-right-trim (str " ") text]]
              [collect [spine--text [string c] color 8]]
            ])
        ]
      ])
    ])
  blank
  ({snapshot}:
    rows [
      [defun spine--media [snapshot]]
      ({
        service,
        status,
        title,
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
              [[length' [getf service (kw "length")]]]
              [[position' [getf service (kw "position")]]]
              [[played [if' [and [realp length'] [plusp length'] [realp position']] [max 0 [min 1 ["/" position' length']]] 0]]]
            ])
          ]
          (rows [
            [when [and [stringp title] [plusp [length title]] [member status (quote [(str "Playing") (str "Paused")]) (kw "test") (function equal)]]]
            (rows [
              [ui (kw "column") (kw "align") (kw "center") (kw "gap") [cassette--px 4]]
              [
                (kw "children")
                (rows [
                  [list [cassette--led [equal status (str "Playing")]]]
                  [[cassette--reel ["-" 1 played]]]
                  [[spine--stacked [cassette--fit title [getf (constant cassette) (kw "spine-title")]] [cassette--c (kw "ink")]]]
                  [[cassette--reel played]]
                ])
              ]
            ])
          ])
        ])
    ])
  blank
  ({
    module,
    state,
    snapshot,
  }:
    rows [
      [defun spine--module [module state snapshot]]
      ({
        cpu,
        memory,
        gpu,
      }:
        rows [
          [let' [[cpu [getf state (kw "cpu")]] [memory [getf state (kw "memory")]] [gpu [getf state (kw "gpu")]]]]
          (rows [
            [ecase module]
            [[(kw "time") [spine--counter]]]
            [[(kw "date") [spine--date]]]
            [[(kw "media") [spine--media snapshot]]]
            [[(kw "cpu") [spine--gauge (str "CPU") [getf cpu (kw "percent")] [cassette--degrees [getf cpu (kw "temp")]] [cassette--hot-p [getf cpu (kw "temp")]]]]]
            [[(kw "memory") [spine--gauge (str "MEM") [getf memory (kw "percent")] [cassette--gib [getf memory (kw "used")]]]]]
            [
              [
                (kw "gpu")
                (rows [
                  [when [probe--gpu-p gpu]]
                  [[spine--gauge (str "GPU") [getf gpu (kw "percent")] [cassette--degrees [getf gpu (kw "temp")]] [cassette--hot-p [getf gpu (kw "temp")]]]]
                ])
              ]
            ]
            [
              [
                (kw "vram")
                (rows [
                  [when [probe--gpu-p gpu]]
                  (rows [
                    [spine--gauge (str "VRAM") [if' [plusp [or' [getf gpu (kw "total")] 0]] [round ["*" 100 [or' [getf gpu (kw "used")] 0]] [getf gpu (kw "total")]] 0]]
                    [[cassette--gib [getf gpu (kw "used")]]]
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
                    [[spine--gauge [if' [getf battery (kw "charging")] (str "CHG") (str "BAT")] [getf battery (kw "percent")] nil]]
                  ])
              ]
            ]
            [
              [
                (kw "network")
                ({online}:
                  rows [
                    [let' [[online [getf [service-state snapshot (kw "network")] (kw "connected")]]]]
                    (rows [
                      [ui (kw "column") (kw "align") (kw "center") (kw "gap") [cassette--px 3]]
                      [
                        (kw "children")
                        (rows [
                          [list [cassette--led online]]
                          [[spine--text [if' online (str "NET") (str "OFF")] [cassette--c (kw "dim")] 7]]
                        ])
                      ]
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
                      [[spine--gauge [if' [equal [getf battery (kw "status")] (str "Discharging")] (str "VR") (str "VR+")] [getf battery (kw "percent")] nil]]
                    ])
                  ])
              ]
            ]
          ])
        ])
    ])
  blank
  ({item}:
    rows [
      [defun spine--cell [item]]
      [[ui (kw "row") (kw "justify") (kw "center") (kw "padding") [list [cassette--px 6] 0 [cassette--px 6] 0] (kw "children") [list item]]]
    ])
  blank
  ({items}:
    rows [
      [defun spine--run [items]]
      (rows [
        [ui (kw "column") (kw "height") 0 (kw "grow") 1 (kw "align") (kw "stretch") (kw "justify") (kw "center")]
        [
          (kw "children")
          ({
            item,
            rest',
          }:
            rows [
              [loop for [item dot rest'] on [remove nil items]]
              [collect [spine--cell item]]
              [when rest' collect [spine--groove]]
            ])
        ]
      ])
    ])
  blank
  ({tray}:
    rows [
      [defun spine--tray-height [tray]]
      (str ''
        Logical height of the tray slot that TRAY, a published :shelf-tray request
        of (:count N :size PX), asks for at the top of the spine.'')
      [["*" [getf tray (kw "count") 0] [getf tray (kw "size") 0]]]
    ])
  blank
  ({
    items,
    tray-height,
  }:
    rows [
      [defun spine--body [items and-optional [tray-height 0]]]
      (rows [
        [ui (kw "column") (kw "align") (kw "stretch") (kw "background") [cassette--c (kw "face")] (kw "border") 1 (kw "border-color") [cassette--c (kw "rim")]]
        [
          (kw "children")
          (rows [
            [remove nil]
            (rows [
              [
                list
                (rows [
                  [when [plusp tray-height]]
                  [[ui (kw "rect") (kw "height") tray-height (kw "background") [cassette--c (kw "counter")]]]
                ])
              ]
              [[spine--cell [cassette--grille]]]
              [[spine--run items]]
              [[spine--cell [cassette--grille]]]
            ])
          ])
        ]
      ])
    ])
  blank
  ({
    snapshot,
    box,
  }:
    rows [
      [defun spine--covered-p [snapshot box]]
      (str ''
        Whether a placed window overlaps BOX. Tiled windows never reach the seam, so
        this is a float or a fullscreen window, which the spine then sits beneath.'')
      ({entry}:
        rows [
          [loop for entry in' [context snapshot (kw "layout")]]
          [
            thereis
            (rows [
              [and [getf entry (kw "visible")]]
              [["<" [getf entry (kw "x")] ["+" [getf box (kw "x")] [getf box (kw "width")]]]]
              [["<" [getf box (kw "x")] ["+" [getf entry (kw "x")] [getf entry (kw "width")]]]]
              [["<" [getf entry (kw "y")] ["+" [getf box (kw "y")] [getf box (kw "height")]]]]
              [["<" [getf box (kw "y")] ["+" [getf entry (kw "y")] [getf entry (kw "height")]]]]
            ])
          ]
        ])
    ])
  blank
  ({
    snapshot,
    output,
  }:
    rows [
      [defun spine--fullscreen-p [snapshot output]]
      ({entry}:
        rows [
          [loop for entry in' [context snapshot (kw "layout")]]
          [
            thereis
            (rows [
              [and [getf entry (kw "visible")] [getf entry (kw "fullscreen")]]
              [["<=" [getf entry (kw "x")] [getf output (kw "x")] ["+" [getf entry (kw "x")] [getf entry (kw "width")] (-1)]]]
              [["<=" [getf entry (kw "y")] [getf output (kw "y")] ["+" [getf entry (kw "y")] [getf entry (kw "height")] (-1)]]]
            ])
          ]
        ])
    ])
  blank
  ({
    items,
    output,
    focal,
    snapshot,
  }:
    rows [
      [defun spine--plates [items output focal snapshot]]
      ({
        split,
        layer,
      }:
        rows [
          [
            let'
            (rows [
              [[split [or' [cassette--split] [length items]]]]
              [[layer [if' [spine--fullscreen-p snapshot output] (kw "bottom") (kw "top")]]]
            ])
          ]
          ({
            edge,
            plate,
            height,
          }:
            rows [
              [loop for edge in' (quote [(kw "top") (kw "bottom")])]
              [for plate "=" [cassette--plate [if' [eq edge (kw "top")] [subseq items 0 split] [nthcdr split items]] (kw "both") edge]]
              [for height "=" [cassette--height edge]]
              [when plate]
              (at 8 [
                collect
                (rows [
                  [apply (function shell-surface) [intern [format nil (str "~A-~A") edge [getf output (kw "name")]] (kw "keyword")] plate]
                  [(kw "output") [getf output (kw "name")] (kw "layer") layer]
                  [(kw "background") (str "#00000000") (kw "blur") t (kw "click-through") t]
                  (rows [
                    [if' focal]
                    (rows [
                      [list (kw "anchors") (quote [(kw "top")])]
                      [
                        (kw "margin")
                        (rows [
                          [
                            list
                            (rows [
                              ["-" ["+" [getf focal (kw "top")] [if' [eq edge (kw "top")] 0 [getf focal (kw "height")]]]]
                              [[round height 2]]
                            ])
                          ]
                          [0 0 0]
                        ])
                      ]
                    ])
                    (rows [
                      [list (kw "anchors") [list edge] (kw "margin") [if' [eq edge (kw "top")] (quote [(-1) 0 0 0]) (quote [0 0 (-1) 0])]]
                      [(kw "exclusive-zone") ["1-" height]]
                    ])
                  ])
                ])
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
          [(kw "reads") [(kw "system") (kw "services") (kw "data") (kw "outputs") (kw "layout")]]
          [(kw "state") [list (kw "cpu") nil (kw "memory") nil (kw "gpu") nil]]
        ])
      ]
      [[snapshot state event]]
      (rows [
        [when [and [eq [getf event (kw "type")] (kw "timer")] [eq [getf event (kw "name")] (kw "sample")]]]
        ({system}:
          rows [
            [let' [[system [context snapshot (kw "system")]]]]
            ({probe}:
              rows [
                [dolist [probe (quote [(kw "cpu") (kw "memory") (kw "gpu")])]]
                [[setf [getf state probe] [probe--sample probe [getf state probe] system]]]
              ])
          ])
      ])
      ({
        cassette-mode,
        seam,
        output,
        scale,
        narrow,
        focal,
        tray-height,
        items,
        hot,
      }:
        rows [
          [
            "let*"
            (rows [
              [[(special cassette-mode) [state-value snapshot (kw "theme-mode") (kw "dark")]]]
              [[seam [state-value snapshot (kw "deck-seam")]]]
              [
                [
                  output
                  [
                    and
                    seam
                    (rows [
                      [find [getf seam (kw "output")] [context snapshot (kw "outputs")]]
                      [(kw "key") ({o}: [lambda [o] [getf o (kw "name")]]) (kw "test") (function equal)]
                    ])
                  ]
                ]
              ]
              [[scale [and output ["/" [getf output (kw "scale-120") 120] 120]]]]
              [[narrow [remove-if-not ({o}: [lambda [o] [deck--narrow-p [list (kw "output") o]]]) [context snapshot (kw "outputs")]]]]
              [[focal [state-value snapshot (kw "focal-frame")]]]
              [[tray-height [spine--tray-height [state-value snapshot (kw "shelf-tray")]]]]
              [
                [
                  items
                  (rows [
                    [when narrow]
                    ({module}:
                      rows [
                        [loop for module in' [getf (constant cassette) (kw "modules")]]
                        [collect [cassette--module module state snapshot]]
                      ])
                  ])
                ]
              ]
              [[hot ({probe}: [loop for probe in' (quote [(kw "cpu") (kw "gpu")]) thereis [cassette--hot-p [getf [getf state probe] (kw "temp")]]])]]
            ])
          ]
          (rows [
            [values state]
            (rows [
              [
                append
                (rows [
                  [list [interval (kw "sample") [getf (constant cassette) (kw "sample")]]]
                  [[publish-state (kw "hud-hot") [and hot t]]]
                ])
              ]
              (rows [
                [when [and output [plusp tray-height]]]
                [
                  [
                    list
                    (rows [
                      [publish-state (kw "shelf-tray-rect")]
                      (rows [
                        [list (kw "output") [getf seam (kw "output")]]
                        [(kw "x") [getf seam (kw "x")] (kw "y") ["+" [getf seam (kw "y")] [round scale]]]
                        [(kw "width") [getf seam (kw "width")]]
                        [(kw "height") [round ["*" tray-height scale]]]
                      ])
                    ])
                  ]
                ]
              ])
              (rows [
                [when output]
                [
                  [
                    list
                    (rows [
                      [
                        shell-surface
                        (kw "spine")
                        (rows [
                          [
                            spine--body
                            ({module}:
                              rows [
                                [loop for module in' [getf (constant cassette) (kw "modules")]]
                                [collect [spine--module module state snapshot]]
                              ])
                          ]
                          tray-height
                        ])
                      ]
                      [(kw "output") [getf output (kw "name")] (kw "anchors") (quote [(kw "top") (kw "left")])]
                      [(kw "width") [round [getf seam (kw "width")] scale] (kw "height") [round [getf seam (kw "height")] scale]]
                      [
                        (kw "margin")
                        (rows [
                          [list [round ["-" [getf seam (kw "y")] [getf output (kw "y")]] scale] 0 0]
                          [[round ["-" [getf seam (kw "x")] [getf output (kw "x")]] scale]]
                        ])
                      ]
                      [(kw "layer") [if' [spine--covered-p snapshot seam] (kw "bottom") (kw "top")]]
                      [(kw "background") (str "#00000000") (kw "blur") t]
                      [(kw "click-through") t (kw "slide") t]
                    ])
                  ]
                ]
              ])
              ({o}:
                rows [
                  [loop for o in' narrow]
                  [append [spine--plates items o [and [equal [getf focal (kw "output")] [getf o (kw "name")]] focal] snapshot]]
                ])
            ])
            nil
          ])
        ])
    ])
])
