{
  and,
  and-optional,
  and-rest,
  append,
  at,
  below,
  blank,
  by,
  cddr,
  char-code,
  clock-text,
  collect,
  concatenate,
  cond,
  constant,
  context,
  copy-list,
  define-extension,
  defun,
  dolist,
  double,
  ecase,
  eq,
  equal,
  first,
  flet,
  for,
  format,
  from,
  function,
  gap,
  getf,
  hud--alpha,
  hud--c,
  hud--dim,
  hud--heat,
  hud--mix,
  hud--off,
  if',
  in',
  in-package,
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
  not,
  nthcdr,
  on,
  or',
  plusp,
  probe--gpu-p,
  probe--sample,
  publish-state,
  quote,
  realp,
  remove,
  remove-if,
  return,
  round,
  rows,
  second,
  service-state,
  setf,
  shell-surface,
  sort,
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
  values,
  when,
  ...
}: ({
  gap--ascii,
  gap--degrees,
  gap--gib,
  gap--fit,
  gap--px,
  gap--text,
  gap--item,
  gap--meter,
  gap--gauge,
  gap--words,
  gap--media,
  gap--battery,
  gap--network,
  gap--frame,
  gap--module,
  gap--line,
}: [
  [in-package (uninterned "tomoe-user")]
  blank
  ({text}: [defun gap--ascii [text] [remove-if ({c}: [lambda [c] [">" [char-code c] 126]]) text]])
  blank
  ({value'}: [defun gap--degrees [value'] [if' [realp value'] [format nil (str "~2D°") [max 0 [min 99 [round value']]]] (str "--°")]])
  blank
  ({mib}: [defun gap--gib [mib] [if' [realp mib] [format nil (str "~4,1FG") ["/" mib (double 1024)]] (str "--.-G")]])
  blank
  ({
    text,
    width,
  }:
    rows [
      [defun gap--fit [text width]]
      [[format nil (str "~vA") width [if' [">" [length text] width] [concatenate (quote string) [subseq text 0 ["-" width 2]] (str "..")] text]]]
    ])
  blank
  ({n}: [defun gap--px [n] [max 1 [round ["*" n [getf (constant gap) (kw "scale")]]]]])
  blank
  ({
    text,
    color,
  }:
    rows [
      [defun gap--text [text color]]
      [[ui (kw "text") (kw "text") text (kw "size") [gap--px 11] (kw "line-height") [gap--px 11] (kw "color") color (kw "font") [getf (constant gap) (kw "font")]]]
    ])
  blank
  ({
    p,
    children,
  }:
    rows [
      [defun gap--item [p children]]
      [
        [
          ui
          (kw "stack")
          (kw "children")
          (rows [
            [
              list
              (rows [
                [ui (kw "column") (kw "align") (kw "stretch")]
                [
                  (kw "children")
                  (rows [
                    [list [ui (kw "rect") (kw "height") [gap--px 3]]]
                    [[ui (kw "rect") (kw "height") [gap--px 8] (kw "background") [hud--alpha [hud--c p (kw "bg")] (str "e6")]]]
                  ])
                ]
              ])
            ]
            (rows [
              [ui (kw "row") (kw "height") [gap--px 11] (kw "align") (kw "end") (kw "gap") [gap--px 4]]
              [(kw "padding") [list 0 [gap--px 4] 0 [gap--px 4]]]
              [(kw "children") [remove nil children]]
            ])
          ])
        ]
      ]
    ])
  blank
  ({
    p,
    value',
    accent,
    zones,
  }:
    rows [
      [defun gap--meter [p value' accent zones]]
      ({filled}:
        rows [
          [let' [[filled ["*" 12 [max 0 [min 1 value']]]]]]
          (rows [
            [ui (kw "row") (kw "gap") [gap--px 1] (kw "height") [gap--px 8] (kw "align") (kw "end")]
            [
              (kw "children")
              ({i}:
                rows [
                  [loop for i below 12]
                  [
                    collect
                    (rows [
                      [ui (kw "rect") (kw "width") [gap--px 3] (kw "height") [gap--px 8]]
                      [
                        (kw "background")
                        (rows [
                          [hud--mix [hud--off p]]
                          [[if' zones [hud--heat ["*" 100 ["/" ["1+" i] 12]] accent p] accent]]
                          [[max 0 [min 1 ["-" filled i]]]]
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
    label,
    accent,
    percent,
    detail,
    zones,
  }:
    rows [
      [defun gap--gauge [p label accent percent detail and-optional [zones t]]]
      [
        [
          gap--item
          p
          (rows [
            [list [gap--text label accent]]
            [[gap--text [format nil (str "~3D%") [max 0 [min 100 percent]]] [hud--c p (kw "fg")]]]
            [[gap--meter p ["/" percent 100] accent zones]]
            [[when detail [gap--text detail [hud--dim p 0.75]]]]
          ])
        ]
      ]
    ])
  blank
  ({
    p,
    parts,
  }:
    rows [
      [defun gap--words [p and-rest parts]]
      [
        [
          gap--item
          p
          ({
            text,
            color,
          }: [loop for [text color] on parts by (function cddr) collect [gap--text text [or' color [hud--c p (kw "fg")]]]])
        ]
      ]
    ])
  blank
  ({
    p,
    snapshot,
  }:
    rows [
      [defun gap--media [p snapshot]]
      ({
        service,
        status,
        title,
        artist,
      }:
        rows [
          [
            "let*"
            (rows [
              [[service [service-state snapshot (kw "mpris")]]]
              [[status [getf service (kw "status")]]]
              [[title [getf service (kw "title")]]]
              [[artist [getf service (kw "artist")]]]
            ])
          ]
          (rows [
            [when [and [stringp title] [plusp [length title]] [member status (quote [(str "Playing") (str "Paused")]) (kw "test") (function equal)]]]
            (rows [
              [gap--words p [if' [equal status (str "Playing")] (str ">>") (str "||")] [hud--c p (kw "color5")]]
              (rows [
                [
                  gap--fit
                  [
                    gap--ascii
                    [
                      string-upcase
                      (rows [
                        [if' [and [stringp artist] [plusp [length artist]]]]
                        (at 5 [[format nil (str "~A - ~A") artist title]])
                        (at 5 title)
                      ])
                    ]
                  ]
                ]
                [[round [getf (constant gap) (kw "media-width")] [getf (constant gap) (kw "scale")]]]
              ])
              nil
            ])
          ])
        ])
    ])
  blank
  ({
    p,
    snapshot,
  }:
    rows [
      [defun gap--battery [p snapshot]]
      ({
        battery,
        percent,
        color,
      }:
        rows [
          [
            "let*"
            (rows [
              [[battery [service-state snapshot (kw "battery")]]]
              [[percent [round [getf battery (kw "percent") 0]]]]
              [
                [
                  color
                  (rows [
                    [cond [[getf battery (kw "charging")] [hud--c p (kw "color2")]] [["<" percent 15] [hud--c p (kw "color1")]]]
                    [[["<" percent 30] [hud--c p (kw "color3")]] [t [hud--c p (kw "color2")]]]
                  ])
                ]
              ]
            ])
          ]
          [[gap--gauge p [if' [getf battery (kw "charging")] (str "CHG") (str "BAT")] color percent nil nil]]
        ])
    ])
  blank
  ({
    p,
    snapshot,
  }:
    rows [
      [defun gap--network [p snapshot]]
      ({
        network,
        ssid,
        online,
      }:
        rows [
          [
            "let*"
            (rows [
              [[network [service-state snapshot (kw "network")]]]
              [[ssid [getf network (kw "ssid")]]]
              [[online [getf network (kw "connected")]]]
            ])
          ]
          (rows [
            [
              gap--words
              p
              (rows [
                [
                  gap--fit
                  (rows [
                    [cond [[and online [stringp ssid] [plusp [length ssid]]] [gap--ascii [string-upcase ssid]]]]
                    [[online (str "ONLINE")]]
                    [[t (str "OFFLINE")]]
                  ])
                ]
                20
              ])
            ]
            [[if' online [hud--c p (kw "color6")] [hud--c p (kw "color1")]]]
          ])
        ])
    ])
  blank
  ({
    p,
    snapshot,
  }:
    rows [
      [defun gap--frame [p snapshot]]
      ({
        battery,
        percent,
        powered,
      }:
        rows [
          [
            "let*"
            (rows [
              [[battery [state-value snapshot (kw "frame-battery")]]]
              [[percent [getf battery (kw "percent")]]]
              [[powered [not [equal [getf battery (kw "status")] (str "Discharging")]]]]
            ])
          ]
          (rows [
            [when percent]
            (rows [
              [gap--gauge p [if' powered (str "VR+") (str "VR")]]
              (rows [
                [cond [powered [hud--c p (kw "color2")]] [["<" percent 15] [hud--c p (kw "color1")]]]
                [[["<" percent 30] [hud--c p (kw "color3")]] [t [hud--c p (kw "color2")]]]
              ])
              [percent nil nil]
            ])
          ])
        ])
    ])
  blank
  ({
    module,
    p,
    state,
    snapshot,
  }:
    rows [
      [defun gap--module [module p state snapshot]]
      ({
        cpu,
        memory,
        gpu,
      }:
        rows [
          [let' [[cpu [getf state (kw "cpu")]] [memory [getf state (kw "memory")]] [gpu [getf state (kw "gpu")]]]]
          (rows [
            [ecase module]
            [[(kw "time") [gap--words p [clock-text [getf (constant gap) (kw "time")]] nil]]]
            [[(kw "date") [gap--words p [string-upcase [clock-text [getf (constant gap) (kw "date")]]] nil]]]
            [[(kw "media") [gap--media p snapshot]]]
            [[(kw "battery") [gap--battery p snapshot]]]
            [[(kw "network") [gap--network p snapshot]]]
            [[(kw "frame") [gap--frame p snapshot]]]
            [[(kw "cpu") [gap--gauge p (str "CPU") [hud--c p (kw "color4")] [getf cpu (kw "percent") 0] [gap--degrees [getf cpu (kw "temp")]]]]]
            [[(kw "memory") [gap--gauge p (str "MEM") [hud--c p (kw "color5")] [getf memory (kw "percent") 0] [gap--gib [getf memory (kw "used")]]]]]
            [
              [
                (kw "gpu")
                (rows [
                  [when [probe--gpu-p gpu]]
                  [[gap--gauge p (str "GPU") [hud--c p (kw "color2")] [getf gpu (kw "percent") 0] [gap--degrees [getf gpu (kw "temp")]]]]
                ])
              ]
            ]
            [
              [
                (kw "vram")
                (rows [
                  [when [probe--gpu-p gpu]]
                  (rows [
                    [gap--gauge p (str "VRAM") [hud--c p (kw "color6")]]
                    [[if' [plusp [or' [getf gpu (kw "total")] 0]] [round ["*" 100 [or' [getf gpu (kw "used")] 0]] [getf gpu (kw "total")]] 0]]
                    [[gap--gib [getf gpu (kw "used")]]]
                  ])
                ])
              ]
            ]
          ])
        ])
    ])
  blank
  ({panels}:
    rows [
      [defun gap--line [panels]]
      ({
        modules,
        pair,
        inset,
        seam,
      }:
        rows [
          [
            "let*"
            (rows [
              [[modules [getf (constant gap) (kw "modules")]]]
              [[pair [getf (constant gap) (kw "center-between")]]]
              [[inset [getf (constant gap) (kw "inset")]]]
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
                    items,
                    justify,
                    padding,
                  }:
                    rows [
                      [half [items justify padding]]
                      (rows [
                        [ui (kw "row") (kw "width") 0 (kw "grow") 1 (kw "height") [gap--px 11] (kw "gap") [gap--px 6] (kw "align") (kw "end") (kw "justify") justify (kw "padding") padding]
                        [(kw "children") [remove nil items]]
                      ])
                    ])
                ]
              ]
              (rows [
                [ui (kw "row") (kw "height") [gap--px 11] (kw "align") (kw "end") (kw "justify") (kw "center")]
                [
                  (kw "children")
                  (rows [
                    [if' seam]
                    (rows [
                      [list [half [subseq panels 0 seam] (kw "end") [list 0 inset 0 0]]]
                      [[half [nthcdr seam panels] (kw "start") [list 0 0 0 inset]]]
                    ])
                    [[list [ui (kw "row") (kw "height") [gap--px 11] (kw "gap") [gap--px 6] (kw "align") (kw "end") (kw "children") [remove nil panels]]]]
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
          [(kw "reads") [(kw "system") (kw "services") (kw "data") (kw "outputs")]]
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
        p,
        line,
        focal,
        wide,
        height,
        lift,
        hot,
      }:
        rows [
          [
            "let*"
            (rows [
              [[p [state-value snapshot (kw "hud-palette")]]]
              [
                [
                  line
                  [
                    gap--line
                    ({module}:
                      rows [
                        [loop for module in' [getf (constant gap) (kw "modules")]]
                        [collect [gap--module module p state snapshot]]
                      ])
                  ]
                ]
              ]
              [[focal [state-value snapshot (kw "focal-frame")]]]
              [[wide [first [sort [copy-list [context snapshot (kw "outputs")]] (function ">") (kw "key") ({o}: [lambda [o] [getf o (kw "width")]])]]]]
              [[height [gap--px 11]]]
              [[lift [gap--px 6]]]
              [
                [
                  hot
                  ({
                    probe,
                    temp,
                  }:
                    rows [
                      [loop for probe in' (quote [(kw "cpu") (kw "gpu")])]
                      [for temp "=" [getf [getf state probe] (kw "temp")]]
                      [thereis [and [realp temp] [">=" temp [getf (constant gap) (kw "hot")]]]]
                    ])
                ]
              ]
            ])
          ]
          (rows [
            [values state]
            (rows [
              [
                append
                (rows [
                  [list [interval (kw "sample") [getf (constant gap) (kw "sample")]]]
                  [[publish-state (kw "hud-hot") [and hot t]]]
                  (rows [
                    [publish-state (kw "bar-floor")]
                    (rows [
                      [when [member (kw "bottom") [getf (constant gap) (kw "edges")]]]
                      (rows [
                        [
                          cond
                          (rows [
                            focal
                            (rows [
                              [list (kw "output") [getf focal (kw "output")]]
                              [(kw "y") ["+" [getf focal (kw "top")] [getf focal (kw "height")] ["-" lift] height]]
                            ])
                          ])
                        ]
                        [[wide [list (kw "output") [getf wide (kw "name")] (kw "y") [getf wide (kw "height")]]]]
                      ])
                    ])
                  ])
                ])
              ]
              ({edge}:
                rows [
                  [loop for edge in' [getf (constant gap) (kw "edges")]]
                  [
                    collect
                    (rows [
                      [if' focal]
                      (rows [
                        [shell-surface edge line (kw "output") [getf focal (kw "output")] (kw "anchors") (quote [(kw "top") (kw "left")])]
                        [(kw "width") [getf focal (kw "width")] (kw "height") height]
                        [
                          (kw "margin")
                          (rows [
                            [
                              list
                              (rows [
                                [
                                  "-"
                                  (rows [
                                    [if' [eq edge (kw "top")]]
                                    [[getf focal (kw "top")]]
                                    [["+" [getf focal (kw "top")] [getf focal (kw "height")]]]
                                  ])
                                ]
                                lift
                              ])
                            ]
                            [0 0 [getf focal (kw "left")]]
                          ])
                        ]
                        [(kw "layer") (kw "overlay") (kw "background") (str "#00000000") (kw "click-through") t]
                      ])
                      (rows [
                        [shell-surface edge line (kw "output") [getf wide (kw "name")] (kw "anchors") [list edge (kw "left") (kw "right")]]
                        [(kw "height") height (kw "margin") [if' [eq edge (kw "top")] [list ["-" [gap--px 3]] 0 0 0] 0]]
                        [(kw "layer") (kw "overlay") (kw "background") (str "#00000000") (kw "click-through") t]
                      ])
                    ])
                  ]
                ])
            ])
            nil
          ])
        ])
    ])
])
