{
  action,
  and,
  append,
  apply,
  assoc,
  at,
  bind-key,
  blank,
  car,
  cdr,
  ceiling,
  collect,
  cond,
  constant,
  copy-list,
  declare,
  defpackage,
  defparameter,
  defun,
  destructuring-bind,
  do,
  dolist,
  dot,
  eq,
  eql,
  equal,
  find,
  first,
  flet,
  floor,
  for,
  fourth,
  from,
  function,
  getf,
  if',
  ignore,
  in',
  in-package,
  integerp,
  kw,
  lambda,
  last,
  length,
  let',
  list,
  listp,
  loop,
  mapcar,
  max,
  member,
  min,
  mod,
  multiple-value-bind,
  nil,
  not,
  nth,
  null',
  or',
  plusp,
  position,
  progn,
  quote,
  ratio,
  register-command,
  register-component,
  register-keymap,
  register-layout-provider,
  registry,
  remove,
  remove-if,
  remove-if-not,
  rest,
  rotatef,
  rows,
  second,
  set-option,
  setf,
  sort,
  sqrt,
  str,
  t,
  third,
  uninterned,
  unless,
  value,
  values,
  when,
  ...
}: ({
  ratios,
  pane-id,
  sorted-panes,
  tiled-p,
  deck-state,
  state-list,
  deck-model,
  model-state,
  fit-insets,
  deck-viewport,
  deck-frame,
  floating-rect,
  deck-columns,
  deck-grid,
  deck-place,
  column-of,
  focus-column,
  scroll-deck,
  move-in-deck,
  swap-columns,
  to-column,
  close-pane,
}: [
  (rows [
    [defpackage (uninterned "ekko-deck")]
    [[(kw "use") (uninterned "cl") (uninterned "ekko/extensions")]]
  ])
  [in-package (uninterned "ekko-deck")]
  blank
  (rows [
    [defparameter (constant ratios) (quote [(ratio 1 2) (ratio 2 3) (ratio 1 3)])]
    (str "Ctrl+r column split cycle, like tomoe's 16:9+16:9 / 21:9+11:9 / 11:9+21:9.")
  ])
  blank
  ({pane}: [defun pane-id [pane] [getf pane (kw "id")]])
  blank
  ({snapshot}:
    rows [
      [defun sorted-panes [snapshot]]
      [[sort [copy-list [value snapshot (kw "panes")]] (function "<") (kw "key") (function pane-id)]]
    ])
  blank
  ({pane}:
    rows [
      [defun tiled-p [pane]]
      [[not [or' [getf pane (kw "minimized")] [getf pane (kw "floating")]]]]
    ])
  blank
  ({snapshot}:
    rows [
      [defun deck-state [snapshot]]
      [[rest [assoc (str "deck") [value snapshot (kw "component-state")] (kw "test") (function equal)]]]
    ])
  blank
  ({
    state,
    key,
  }:
    rows [
      [defun state-list [state key]]
      ({value'}:
        rows [
          [let' [[value' [getf state key]]]]
          [[and [listp value'] value']]
        ])
    ])
  blank
  ({snapshot}:
    rows [
      [defun deck-model [snapshot]]
      (str ''
        Resolve the workspace into (:left :right) ordered column id lists, their
        tiled subsets (:vl :vr), front ids (:fl :fr), :ratio, :grid and :pending.
        Dead panes drop out; unassigned panes join the :pending column — the deck a
        command last worked in, like a spawn joining the focused window's column in
        tomoe — or balance into the shorter one (ties go left), and take its front.'')
      ({
        state,
        panes,
        live,
        visible,
        left,
        right,
        pending,
        new,
      }:
        rows [
          [
            "let*"
            (rows [
              [[state [deck-state snapshot]]]
              [[panes [sorted-panes snapshot]]]
              [[live [mapcar (function pane-id) panes]]]
              [[visible [mapcar (function pane-id) [remove-if-not (function tiled-p) panes]]]]
              [
                [
                  left
                  (rows [
                    [remove-if-not ({id}: [lambda [id] [member id live]])]
                    [[state-list state (kw "left")]]
                  ])
                ]
              ]
              [
                [
                  right
                  (rows [
                    [remove-if-not ({id}: [lambda [id] [member id live]])]
                    [[state-list state (kw "right")]]
                  ])
                ]
              ]
              [[pending ({p}: [let' [[p [getf state (kw "pending")]]] [and [member p (quote [(kw "left") (kw "right")])] p]])]]
              [
                [
                  new
                  (rows [
                    [remove-if ({id}: [lambda [id] [or' [member id left] [member id right]]])]
                    live
                  ])
                ]
              ]
            ])
          ]
          ({id}:
            rows [
              [dolist [id new]]
              (rows [
                [
                  if'
                  (rows [
                    [or' [eq pending (kw "left")]]
                    [[and [null' pending] ["<=" [length left] [length right]]]]
                  ])
                ]
                [[setf left [append left [list id]]]]
                [[setf right [append right [list id]]]]
              ])
            ])
          ({
            subset,
            joined,
          }:
            rows [
              [
                flet
                (rows [
                  ({col}: [subset [col] [remove-if-not ({id}: [lambda [id] [member id visible]]) col]])
                  ({col}: [joined [col] [car [last [remove-if-not ({id}: [lambda [id] [member id col]]) new]]]])
                ])
              ]
              ({
                vl,
                vr,
                focus',
              }:
                rows [
                  [
                    let'
                    (rows [
                      [[vl [subset left]] [vr [subset right]]]
                      [[focus' [value snapshot (kw "focus")]]]
                    ])
                  ]
                  ({front}:
                    rows [
                      [
                        flet
                        [
                          ({
                            col,
                            vcol,
                            stored,
                          }:
                            rows [
                              [front [col vcol stored]]
                              (rows [
                                [or' [joined col]]
                                [[and [member focus' vcol] focus']]
                                [[and [member stored vcol] stored]]
                                [[first vcol]]
                              ])
                            ])
                        ]
                      ]
                      (rows [
                        [list (kw "left") left (kw "right") right (kw "vl") vl (kw "vr") vr]
                        [(kw "fl") [front left vl [getf state (kw "fl")]]]
                        [(kw "fr") [front right vr [getf state (kw "fr")]]]
                        [(kw "ratio") ({r}: [let' [[r [getf state (kw "ratio")]]] [if' [integerp r] r 0]])]
                        [(kw "grid") [and [getf state (kw "grid")] t]]
                        [(kw "pending") pending]
                        [(kw "visible") visible]
                      ])
                    ])
                ])
            ])
        ])
    ])
  blank
  ({model}:
    rows [
      [defun model-state [model]]
      (rows [
        [list (kw "left") [getf model (kw "left")] (kw "right") [getf model (kw "right")]]
        [(kw "fl") [getf model (kw "fl")] (kw "fr") [getf model (kw "fr")]]
        [(kw "ratio") [getf model (kw "ratio")] (kw "grid") [getf model (kw "grid")]]
        [(kw "pending") [getf model (kw "pending")]]
      ])
    ])
  blank
  ({
    width,
    height,
    insets,
  }:
    rows [
      [defun fit-insets [width height insets]]
      ({
        top,
        left,
        bottom,
        right,
      }:
        rows [
          [
            "let*"
            (rows [
              [[top [min [first insets] [max 0 ["1-" height]]]]]
              [[left [min [fourth insets] [max 0 ["1-" width]]]]]
              [[bottom [min [third insets] [max 0 ["-" height top 1]]]]]
              [[right [min [second insets] [max 0 ["-" width left 1]]]]]
            ])
          ]
          [[list top right bottom left]]
        ])
    ])
  blank
  ({snapshot}:
    rows [
      [defun deck-viewport [snapshot]]
      ({
        viewport,
        geometry,
        cols,
        rows',
        insets,
      }:
        rows [
          [
            "let*"
            (rows [
              [[viewport [value snapshot (kw "viewport")]] [geometry [value snapshot (kw "geometry")]]]
              [[cols [getf viewport (kw "cols")]] [rows' [getf viewport (kw "rows")]]]
              [[insets [fit-insets cols rows' [getf geometry (kw "viewport-insets") (quote [0 0 1 0])]]]]
            ])
          ]
          (rows [
            [values [fourth insets] [first insets]]
            [["-" cols [second insets] [fourth insets]]]
            [["-" rows' [first insets] [third insets]]]
          ])
        ])
    ])
  blank
  ({
    snapshot,
    id,
    x,
    y,
    width,
    height,
  }:
    rows [
      [defun deck-frame [snapshot id x y width height]]
      ({
        geometry,
        requested,
        boundary,
      }:
        rows [
          [
            "let*"
            (rows [
              [[geometry [value snapshot (kw "geometry")]]]
              [[requested [copy-list [getf geometry (kw "pane-insets") (quote [1 0 0 0])]]]]
              [[boundary [getf geometry (kw "boundary-insets")]]]
            ])
          ]
          (rows [
            [when boundary]
            ({
              left,
              top,
              vw,
              vh,
            }:
              rows [
                [multiple-value-bind [left top vw vh] [deck-viewport snapshot]]
                ({
                  outside,
                  index,
                }:
                  rows [
                    [
                      loop
                      for
                      outside
                      in'
                      (rows [
                        [list ["=" y top] ["=" ["+" x width] ["+" left vw]]]
                        [["=" ["+" y height] ["+" top vh]] ["=" x left]]
                      ])
                    ]
                    [for index from 0 when outside do [setf [nth index requested] [nth index boundary]]]
                  ])
              ])
          ])
          ({insets}:
            rows [
              [let' [[insets [fit-insets width height requested]]]]
              (rows [
                [list (kw "pane") id (kw "x") ["+" x [fourth insets]] (kw "y") ["+" y [first insets]]]
                [(kw "cols") ["-" width [second insets] [fourth insets]]]
                [(kw "rows") ["-" height [first insets] [third insets]]]
                [(kw "outer") [list x y width height]]
              ])
            ])
        ])
    ])
  blank
  ({
    pane,
    index,
    left,
    top,
    width,
    height,
  }:
    rows [
      [defun floating-rect [pane index left top width height]]
      ({
        x,
        y,
        w,
        h,
      }:
        rows [
          [destructuring-bind [x y w h]]
          ({f}:
            rows [
              [let' [[f [getf pane (kw "floating")]]]]
              (rows [
                [if' [and [listp f] ["=" [length f] 4]] f]
                (rows [
                  [list ["+" left ["*" 3 [mod index 8]]] ["+" top [mod index 8]]]
                  [[max 12 [floor ["*" width 3] 4]] [max 4 [floor ["*" height 3] 4]]]
                ])
              ])
            ])
          ({
            w',
            h',
          }:
            rows [
              [let' [[w' [min width [max 12 w]]] [h' [min height [max 4 h]]]]]
              (rows [
                [list [max left [min x ["+" left width ["-" w']]]]]
                [[max top [min y ["+" top height ["-" h']]]] w' h']
              ])
            ])
        ])
    ])
  blank
  ({
    snapshot,
    model,
    x,
    y,
    w,
    h,
    gap',
  }:
    rows [
      [defun deck-columns [snapshot model x y w h gap']]
      ({
        ratio',
        lw,
        rw,
      }:
        rows [
          [
            "let*"
            (rows [
              [[ratio' [nth [mod [getf model (kw "ratio")] [length (constant ratios)]] (constant ratios)]]]
              [[lw [max 1 [min ["-" w gap' 1] [floor ["*" ["-" w gap'] ratio']]]]]]
              [[rw [max 1 ["-" w gap' lw]]]]
            ])
          ]
          ({place'}:
            rows [
              [
                flet
                [
                  ({
                    vcol,
                    front,
                    cx,
                    cw,
                  }:
                    rows [
                      [place' [vcol front cx cw]]
                      ({fi}:
                        rows [
                          [let' [[fi [or' [position front vcol] 0]]]]
                          ({
                            id,
                            i,
                          }:
                            rows [
                              [loop for id in' vcol for i from 0]
                              [collect [deck-frame snapshot id cx ["+" y ["*" ["-" i fi] h]] cw h]]
                            ])
                        ])
                    ])
                ]
              ]
              (rows [
                [append [place' [getf model (kw "vl")] [getf model (kw "fl")] x lw]]
                [[place' [getf model (kw "vr")] [getf model (kw "fr")] ["+" x lw gap'] rw]]
              ])
            ])
        ])
    ])
  blank
  ({
    snapshot,
    model,
    x,
    y,
    w,
    h,
    gap',
  }:
    rows [
      [defun deck-grid [snapshot model x y w h gap']]
      ({
        ids,
        n,
      }:
        rows [
          ["let*" [[ids [getf model (kw "visible")]] [n [length ids]]]]
          (rows [
            [when [plusp n]]
            ({
              cols,
              rows',
              cw,
              ch,
            }:
              rows [
                [
                  "let*"
                  (rows [
                    [[cols [max 1 [ceiling [sqrt n]]]]]
                    [[rows' [ceiling n cols]]]
                    [[cw [max 1 [floor ["-" w ["*" ["1-" cols] gap']] cols]]]]
                    [[ch [max 1 [floor ["-" h ["*" ["1-" rows'] gap']] rows']]]]
                  ])
                ]
                ({
                  id,
                  i,
                }:
                  rows [
                    [loop for id in' ids for i from 0]
                    [
                      collect
                      (rows [
                        [deck-frame snapshot id]
                        [["+" x ["*" [mod i cols] ["+" cw gap']]]]
                        [["+" y ["*" [floor i cols] ["+" ch gap']]]]
                        [cw ch]
                      ])
                    ]
                  ])
              ])
          ])
        ])
    ])
  blank
  ({
    snapshot,
    event,
  }:
    rows [
      [defun deck-place [snapshot event]]
      [[declare [ignore event]]]
      ({
        model,
        gap',
        focus',
      }:
        rows [
          [
            "let*"
            (rows [
              [[model [deck-model snapshot]]]
              [[gap' [first [getf [value snapshot (kw "geometry")] (kw "split-gaps") (quote [1 0])]]]]
              [[focus' [value snapshot (kw "focus")]]]
            ])
          ]
          ({
            x,
            y,
            w,
            h,
          }:
            rows [
              [multiple-value-bind [x y w h] [deck-viewport snapshot]]
              ({placements}:
                rows [
                  [
                    let'
                    [
                      (rows [
                        placements
                        (at 2 (rows [
                          [
                            append
                            (rows [
                              [if' [getf model (kw "grid")]]
                              [[deck-grid snapshot model x y w h gap']]
                              [[deck-columns snapshot model x y w h gap']]
                            ])
                          ]
                          ({
                            pane,
                            i,
                          }:
                            rows [
                              [loop for pane in' [sorted-panes snapshot] for i from 0]
                              [when [getf pane (kw "floating")]]
                              [
                                collect
                                (rows [
                                  [apply (function deck-frame) snapshot [pane-id pane]]
                                  [[floating-rect pane i x y w h]]
                                ])
                              ]
                            ])
                        ]))
                      ])
                    ]
                  ]
                  (rows [
                    [
                      when
                      (rows [
                        [and [value snapshot (kw "zoom")]]
                        [[find focus' placements (kw "key") ({pl}: [lambda [pl] [getf pl (kw "pane")]])]]
                      ])
                    ]
                    (rows [
                      [setf placements]
                      (rows [
                        [
                          append
                          ({pl}:
                            rows [
                              [loop for pl in' placements]
                              [unless [eql focus' [getf pl (kw "pane")]]]
                              [
                                collect
                                ({hidden}:
                                  rows [
                                    [let' [[hidden [copy-list pl]]]]
                                    [[setf [getf hidden (kw "visible")] nil]]
                                    hidden
                                  ])
                              ]
                            ])
                        ]
                        [[list [deck-frame snapshot focus' x y w h]]]
                      ])
                    ])
                  ])
                  [
                    [
                      list
                      (rows [
                        [action (kw "place-panes") (quote (kw "version")) 1 (quote (kw "placements")) placements]
                        [(quote (kw "camera")) (quote [0 0])]
                      ])
                    ]
                  ]
                ])
            ])
        ])
    ])
  blank
  ({
    model,
    focus',
  }:
    rows [
      [defun column-of [model focus']]
      (rows [
        [cond [[member focus' [getf model (kw "vl")]] (kw "left")]]
        [[[member focus' [getf model (kw "vr")]] (kw "right")]]
      ])
    ])
  blank
  ({side}:
    rows [
      [defun focus-column [side]]
      ({
        snapshot,
        event,
      }:
        rows [
          [lambda [snapshot event]]
          [[declare [ignore event]]]
          ({
            model,
            front,
          }:
            rows [
              [
                "let*"
                (rows [
                  [[model [deck-model snapshot]]]
                  [[front [getf model [if' [eq side (kw "left")] (kw "fl") (kw "fr")]]]]
                ])
              ]
              (rows [
                [when front]
                [[setf [getf model (kw "pending")] side]]
                (rows [
                  [list [action (kw "focus") (quote (kw "pane")) front]]
                  [[action (kw "set-state") (quote (kw "value")) [model-state model]]]
                ])
              ])
            ])
        ])
    ])
  blank
  ({dir}:
    rows [
      [defun scroll-deck [dir]]
      ({
        snapshot,
        event,
      }:
        rows [
          [lambda [snapshot event]]
          [[declare [ignore event]]]
          ({
            model,
            side,
          }:
            rows [
              [
                "let*"
                (rows [
                  [[model [deck-model snapshot]]]
                  [[side [column-of model [value snapshot (kw "focus")]]]]
                ])
              ]
              (rows [
                [when side]
                ({
                  vcol,
                  fkey,
                }:
                  rows [
                    [
                      let'
                      (rows [
                        [[vcol [getf model [if' [eq side (kw "left")] (kw "vl") (kw "vr")]]]]
                        [[fkey [if' [eq side (kw "left")] (kw "fl") (kw "fr")]]]
                      ])
                    ]
                    (rows [
                      [when [">" [length vcol] 1]]
                      ({target}:
                        rows [
                          [
                            let'
                            [
                              [
                                target
                                (rows [
                                  [
                                    nth
                                    (rows [
                                      [mod ["+" [or' [position [getf model fkey] vcol] 0] dir]]
                                      (at 4 [[length vcol]])
                                    ])
                                  ]
                                  vcol
                                ])
                              ]
                            ]
                          ]
                          (rows [
                            [setf [getf model fkey] target]
                            [[getf model (kw "pending")] side]
                          ])
                          (rows [
                            [list [action (kw "focus") (quote (kw "pane")) target]]
                            [[action (kw "set-state") (quote (kw "value")) [model-state model]]]
                          ])
                        ])
                    ])
                  ])
              ])
            ])
        ])
    ])
  blank
  ({dir}:
    rows [
      [defun move-in-deck [dir]]
      ({
        snapshot,
        event,
      }:
        rows [
          [lambda [snapshot event]]
          [[declare [ignore event]]]
          ({
            model,
            focus',
            side,
          }:
            rows [
              [
                "let*"
                (rows [
                  [[model [deck-model snapshot]]]
                  [[focus' [value snapshot (kw "focus")]]]
                  [
                    [
                      side
                      (rows [
                        [cond [[member focus' [getf model (kw "left")]] (kw "left")]]
                        [[[member focus' [getf model (kw "right")]] (kw "right")]]
                      ])
                    ]
                  ]
                ])
              ]
              (rows [
                [when side]
                ({
                  col,
                  i,
                  j,
                }:
                  rows [
                    [
                      "let*"
                      (rows [
                        [[col [getf model side]]]
                        [[i [position focus' col]] [j [and i ["+" i dir]]]]
                      ])
                    ]
                    (rows [
                      [when [and j ["<=" 0 j] ["<" j [length col]]]]
                      [[rotatef [nth i col] [nth j col]]]
                      [[setf [getf model (kw "pending")] side]]
                      [[list [action (kw "set-state") (quote (kw "value")) [model-state model]]]]
                    ])
                  ])
              ])
            ])
        ])
    ])
  blank
  ({
    snapshot,
    event,
  }:
    rows [
      [defun swap-columns [snapshot event]]
      [[declare [ignore event]]]
      ({model}:
        rows [
          [let' [[model [deck-model snapshot]]]]
          [[rotatef [getf model (kw "left")] [getf model (kw "right")]]]
          [[rotatef [getf model (kw "vl")] [getf model (kw "vr")]]]
          [[rotatef [getf model (kw "fl")] [getf model (kw "fr")]]]
          ({focus'}:
            rows [
              [let' [[focus' [value snapshot (kw "focus")]]]]
              (rows [
                [setf [getf model (kw "pending")]]
                (rows [
                  [cond [[member focus' [getf model (kw "left")]] (kw "left")]]
                  [[[member focus' [getf model (kw "right")]] (kw "right")]]
                  [[t [getf model (kw "pending")]]]
                ])
              ])
            ])
          [[list [action (kw "set-state") (quote (kw "value")) [model-state model]]]]
        ])
    ])
  blank
  ({target}:
    rows [
      [defun to-column [target]]
      ({
        snapshot,
        event,
      }:
        rows [
          [lambda [snapshot event]]
          [[declare [ignore event]]]
          ({
            model,
            focus',
            side,
          }:
            rows [
              [
                "let*"
                (rows [
                  [[model [deck-model snapshot]]]
                  [[focus' [value snapshot (kw "focus")]]]
                  [
                    [
                      side
                      (rows [
                        [cond [[member focus' [getf model (kw "left")]] (kw "left")]]
                        [[[member focus' [getf model (kw "right")]] (kw "right")]]
                      ])
                    ]
                  ]
                ])
              ]
              (rows [
                [when [and side [not [eq side target]]]]
                ({
                  col,
                  i,
                  skey,
                  tkey,
                  tfkey,
                }:
                  rows [
                    [
                      "let*"
                      (rows [
                        [[col [getf model side]] [i [position focus' col]]]
                        [[skey [if' [eq side (kw "left")] (kw "fl") (kw "fr")]]]
                        [[tkey [if' [eq target (kw "left")] (kw "left") (kw "right")]]]
                        [[tfkey [if' [eq target (kw "left")] (kw "fl") (kw "fr")]]]
                      ])
                    ]
                    (rows [
                      [when [eql focus' [getf model skey]]]
                      [[setf [getf model skey] [nth [mod ["1+" i] [length col]] col]]]
                    ])
                    (rows [
                      [setf [getf model side] [remove focus' col]]
                      [[getf model tkey] [append [getf model tkey] [list focus']]]
                      [[getf model tfkey] focus']
                      [[getf model (kw "pending")] target]
                    ])
                    [[list [action (kw "set-state") (quote (kw "value")) [model-state model]]]]
                  ])
              ])
            ])
        ])
    ])
  blank
  ({
    snapshot,
    event,
  }:
    rows [
      [defun close-pane [snapshot event]]
      [[declare [ignore event]]]
      ({
        model,
        focus',
        side,
      }:
        rows [
          [
            "let*"
            (rows [
              [[model [deck-model snapshot]]]
              [[focus' [value snapshot (kw "focus")]]]
              [[side [column-of model focus']]]
            ])
          ]
          (rows [
            [if' side]
            ({
              vcol,
              fkey,
              target,
            }:
              rows [
                [
                  "let*"
                  (rows [
                    [[vcol [getf model [if' [eq side (kw "left")] (kw "vl") (kw "vr")]]]]
                    [[fkey [if' [eq side (kw "left")] (kw "fl") (kw "fr")]]]
                    [
                      [
                        target
                        (rows [
                          [and [">" [length vcol] 1]]
                          (rows [
                            [
                              nth
                              (rows [
                                [mod ["1+" [or' [position focus' vcol] 0]]]
                                [[length vcol]]
                              ])
                            ]
                            vcol
                          ])
                        ])
                      ]
                    ]
                  ])
                ]
                (rows [
                  [if' target]
                  (rows [
                    [
                      progn
                      (rows [
                        [setf [getf model fkey] target]
                        [[getf model (kw "pending")] side]
                      ])
                    ]
                    (at 7 (rows [
                      [list [action (kw "close") (quote (kw "focus")) target]]
                      [[action (kw "set-state") (quote (kw "value")) [model-state model]]]
                    ]))
                  ])
                  [[list [action (kw "close")]]]
                ])
              ])
            [[list [action (kw "close")]]]
          ])
        ])
    ])
  blank
  [register-component (kw "id") (quote (kw "deck")) (kw "reads") (quote [(kw "panes") (kw "focus") (kw "component-state")])]
  (rows [
    [register-layout-provider (kw "component") (quote (kw "deck")) (kw "name") (str "deck") (kw "api-version") 1]
    [
      (kw "reads")
      (quote (rows [
        [(kw "panes") (kw "focus") (kw "viewport") (kw "geometry")]
        [(kw "component-state") (kw "zoom")]
      ]))
    ]
    [(kw "handler") (function deck-place)]
  ])
  [set-option (kw "component") (quote (kw "deck")) (kw "name") (quote (kw "layout-provider")) (kw "value") (str "deck")]
  [set-option (kw "component") (quote (kw "deck")) (kw "name") (quote (kw "split-gaps")) (kw "value") (quote [1 0])]
  blank
  [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-focus-left") (kw "handler") [focus-column (kw "left")]]
  [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-focus-right") (kw "handler") [focus-column (kw "right")]]
  [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-scroll-down") (kw "handler") [scroll-deck 1]]
  [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-scroll-up") (kw "handler") [scroll-deck (-1)]]
  [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-move-down") (kw "handler") [move-in-deck 1]]
  [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-move-up") (kw "handler") [move-in-deck (-1)]]
  [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-swap-columns") (kw "handler") (function swap-columns)]
  [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-to-left") (kw "handler") [to-column (kw "left")]]
  [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-to-right") (kw "handler") [to-column (kw "right")]]
  [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-close") (kw "handler") (function close-pane)]
  (rows [
    [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-new")]
    [
      (kw "handler")
      ({
        snapshot,
        event,
      }:
        rows [
          [lambda [snapshot event] [declare [ignore event]]]
          ({
            model,
            side,
          }:
            rows [
              [
                "let*"
                (rows [
                  [[model [deck-model snapshot]]]
                  [[side [column-of model [value snapshot (kw "focus")]]]]
                ])
              ]
              [[when side [setf [getf model (kw "pending")] side]]]
              (rows [
                [list [action (kw "split") (quote (kw "axis")) (quote (kw "columns"))]]
                [[action (kw "set-state") (quote (kw "value")) [model-state model]]]
              ])
            ])
        ])
    ]
  ])
  (rows [
    [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-grid-toggle")]
    [
      (kw "handler")
      ({
        snapshot,
        event,
      }:
        rows [
          [lambda [snapshot event] [declare [ignore event]]]
          ({model}:
            rows [
              [let' [[model [deck-model snapshot]]]]
              [[setf [getf model (kw "grid")] [not [getf model (kw "grid")]]]]
              [[list [action (kw "set-state") (quote (kw "value")) [model-state model]]]]
            ])
        ])
    ]
  ])
  (rows [
    [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-ratio-cycle")]
    [
      (kw "handler")
      ({
        snapshot,
        event,
      }:
        rows [
          [lambda [snapshot event] [declare [ignore event]]]
          ({model}:
            rows [
              [let' [[model [deck-model snapshot]]]]
              (rows [
                [setf [getf model (kw "ratio")]]
                [[mod ["1+" [getf model (kw "ratio")]] [length (constant ratios)]]]
              ])
              [[list [action (kw "set-state") (quote (kw "value")) [model-state model]]]]
            ])
        ])
    ]
  ])
  (rows [
    [register-command (kw "component") (quote (kw "deck")) (kw "name") (str "deck-mode")]
    [
      (kw "handler")
      ({
        snapshot,
        event,
      }:
        rows [
          [lambda [snapshot event] [declare [ignore snapshot event]]]
          [[list [action (kw "set-keymap") (quote (kw "name")) (quote (kw "deck"))]]]
        ])
    ]
  ])
  blank
  (rows [
    [
      when
      (rows [
        [find (quote (kw "normal")) [getf [registry] (quote (kw "keymaps"))]]
        [(kw "key") ({m}: [lambda [m] [getf m (quote (kw "name"))]])]
      ])
    ]
    [[register-keymap (kw "component") (quote (kw "deck")) (kw "name") (quote (kw "deck")) (kw "unbound") (quote (kw "ignore"))]]
    ({spec}:
      rows [
        [
          dolist
          [
            spec
            (quote (rows [
              [[(str "C-h") dot (str "deck-focus-left")] [(str "C-l") dot (str "deck-focus-right")]]
              [[(str "C-j") dot (str "deck-scroll-down")] [(str "C-k") dot (str "deck-scroll-up")]]
              [[(str "C-o") dot (str "deck-grid-toggle")] [(str "C-r") dot (str "deck-ratio-cycle")]]
              [[(str "C-d") dot (str "deck-mode")]]
              [[(str "C-[") dot (str "deck-to-left")] [(str "C-]") dot (str "deck-to-right")]]
              [[(str "C-Tab") dot (str "deck-swap-columns")]]
              [[(str "C-J") dot (str "deck-move-down")] [(str "C-K") dot (str "deck-move-up")]]
            ]))
          ]
        ]
        [[bind-key (kw "component") (quote (kw "deck")) (kw "map") (quote (kw "normal")) (kw "key") [car spec] (kw "command") [cdr spec]]]
      ])
    ({spec}:
      rows [
        [
          dolist
          [
            spec
            (quote (rows [
              [[(str "h") dot (str "deck-focus-left")] [(str "l") dot (str "deck-focus-right")]]
              [[(str "j") dot (str "deck-scroll-down")] [(str "k") dot (str "deck-scroll-up")]]
              [[(str "J") dot (str "deck-move-down")] [(str "K") dot (str "deck-move-up")]]
              [[(str "H") dot (str "deck-swap-columns")] [(str "L") dot (str "deck-swap-columns")]]
              [[(str "[") dot (str "deck-to-left")] [(str "]") dot (str "deck-to-right")]]
              [[(str "o") dot (str "deck-grid-toggle")] [(str "r") dot (str "deck-ratio-cycle")]]
              [[(str "n") dot (str "deck-new")] [(str "q") dot (str "deck-close")]]
              [[(str "Escape") dot (str "normal-mode")] [(str "Enter") dot (str "normal-mode")]]
            ]))
          ]
        ]
        [[bind-key (kw "component") (quote (kw "deck")) (kw "map") (quote (kw "deck")) (kw "key") [car spec] (kw "command") [cdr spec]]]
      ])
  ])
])
