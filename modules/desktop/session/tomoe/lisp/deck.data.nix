{
  and,
  append,
  apply,
  assoc,
  bind-key,
  blank,
  car,
  case,
  cdr,
  ceiling,
  collect,
  cond,
  cons,
  constant,
  context,
  count-if,
  define-extension,
  defparameter,
  defun,
  dolist,
  eq,
  eql,
  equal,
  evenp,
  find,
  find-if,
  first,
  floor,
  focus,
  for,
  fullscreen,
  function,
  getf,
  if',
  in',
  in-package,
  integerp,
  kw,
  lambda,
  launch,
  layout,
  layout-bindings,
  length,
  let',
  list,
  loop,
  mapcar,
  max,
  member,
  mod,
  nil,
  not,
  nth,
  null',
  or',
  place,
  plusp,
  policy--area,
  policy--centred,
  policy--launch,
  policy--terminal,
  policy--unmanaged-p,
  position,
  previous-context,
  publish-state,
  push,
  quote,
  raise-window,
  remove,
  remove-if,
  remove-if-not,
  reverse,
  rotatef,
  rows,
  setf,
  setting,
  sqrt,
  str,
  string-downcase,
  t,
  third,
  uninterned,
  unless,
  values,
  when,
  ...
}: ({
  deck--state,
  deck--entry,
  deck--layout-entry,
  deck--windows,
  deck--fronts,
  deck--side-of,
  deck--column,
  deck--column-commands,
  deck--narrow-p',
  deck--front,
  deck--after-front,
  deck--manageable-p,
  deck--current,
  deck--output-of,
  deck--area,
  deck--left-width,
  deck--grid-columns,
  deck--grid-extra,
  deck--grid-cell,
  deck--split,
  deck--seam,
  deck--box,
  deck--places,
  deck--focus-window,
  deck--adopt-front,
  deck--rotate,
  deck--reorder,
  deck--reorder-all,
  deck--cycle,
  deck--swap-columns,
  deck--to-column,
  deck--set-fullscreen,
  deck--toggle-floating,
  deck--command,
  deck--request,
  deck--raises,
}: [
  [in-package (uninterned "tomoe-user")]
  blank
  (rows [
    [defun deck--state []]
    (rows [
      [list (kw "grid") nil (kw "ratio") 1 (kw "focus") nil]
      [(kw "columns") nil (kw "windows") nil]
      [(kw "fronts") [list [cons (kw "left") nil] [cons (kw "right") nil]]]
      [(kw "floating") nil (kw "floats") nil (kw "fullscreen") nil]
    ])
  ])
  blank
  ({
    list',
    id,
  }: [defun deck--entry [list' id] [assoc id list']])
  ({
    layout',
    id,
  }: [defun deck--layout-entry [layout' id] [find id layout' (kw "key") ({entry}: [lambda [entry] [getf entry (kw "id")]])]])
  ({state}: [defun deck--windows [state] [getf state (kw "windows")]])
  ({state}: [defun deck--fronts [state] [getf state (kw "fronts")]])
  ({
    state,
    id,
  }:
    rows [
      [defun deck--side-of [state id]]
      ({entry}: [let' [[entry [deck--entry [getf state (kw "columns")] id]]] [and entry [cdr entry]]])
    ])
  ({
    state,
    side,
  }:
    rows [
      [defun deck--column [state side]]
      [[remove-if-not ({id}: [lambda [id] [eql [deck--side-of state id] side]]) [deck--windows state]]]
    ])
  (rows [
    [defparameter (constant deck--column-commands)]
    (quote [(str "focus-left") (str "focus-right") (str "swap-columns") (str "to-left") (str "to-right") (str "ratio")])
  ])
  ({area}:
    rows [
      [defun deck--narrow-p' [area]]
      ({output}:
        rows [
          [let' [[output [and area [getf area (kw "output")]]]]]
          [[and output ["<" ["*" 9 [getf output (kw "width")]] ["*" 21 [getf output (kw "height")]]]]]
        ])
    ])
  ({
    state,
    side,
  }:
    rows [
      [defun deck--front [state side]]
      (str ''
        The window SIDE's deck shows in front. An adopted front counts only while it is
        still in that column: a front can outlive its window between a close and the
        handoff that replaces it, and a column placed against a front that is gone would
        be placed nowhere and show nothing at all.'')
      ({
        entry,
        recorded,
        column,
      }:
        rows [
          [
            "let*"
            (rows [
              [[entry [assoc side [deck--fronts state]]]]
              [[recorded [and entry [cdr entry]]]]
              [[column [deck--column state side]]]
            ])
          ]
          [[if' [member recorded column] recorded [first column]]]
        ])
    ])
  ({
    state,
    order,
    side,
    gone,
  }:
    rows [
      [defun deck--after-front [state order side gone]]
      (str ''
        The window that takes the front of SIDE in ORDER once GONE closes, or NIL when
        the column empties. GONE still sits in ORDER, so the entry after it is the window
        a scroll would have revealed; at the bottom of the column, the one above it.'')
      ({
        column,
        index,
        next,
      }:
        rows [
          [
            "let*"
            (rows [
              [[column [remove-if-not ({id}: [lambda [id] [eql [deck--side-of state id] side]]) order]]]
              [[index [position gone column]]]
              [[next [and index [nth [if' ["<" ["1+" index] [length column]] ["1+" index] [max 0 ["1-" index]]] column]]]]
            ])
          ]
          [[unless [eql next gone] next]]
        ])
    ])
  ({
    state,
    id,
  }:
    rows [
      [defun deck--manageable-p [state id]]
      [[and [not [member id [getf state (kw "fullscreen")]]] [not [member id [getf state (kw "floating")]]]]]
    ])
  blank
  ({state}:
    rows [
      [defun deck--current [state]]
      (str ''
        The window a command acts on: the focused one while it is in the window set,
        otherwise whatever the deck still shows. A command must never depend on an id a
        gone window left behind, or the keys go dead.'')
      ({
        focus',
        windows,
      }:
        rows [
          [
            let'
            (rows [
              [[focus' [getf state (kw "focus")]]]
              [[windows [deck--windows state]]]
            ])
          ]
          (rows [
            [or' [and [member focus' windows] focus']]
            [[deck--front state (kw "left")]]
            [[deck--front state (kw "right")]]
            [[first windows]]
          ])
        ])
    ])
  blank
  ({
    outputs,
    entry,
  }:
    rows [
      [defun deck--output-of [outputs entry]]
      ({
        cx,
        cy,
      }:
        rows [
          [
            let'
            (rows [
              [[cx ["+" [getf entry (kw "x")] [floor [getf entry (kw "width")] 2]]]]
              [[cy ["+" [getf entry (kw "y")] [floor [getf entry (kw "height")] 2]]]]
            ])
          ]
          (rows [
            [
              find-if
              ({output}:
                rows [
                  [lambda [output]]
                  (rows [
                    [and ["<=" [getf output (kw "x")] cx ["+" [getf output (kw "x")] [getf output (kw "width")]]]]
                    [["<=" [getf output (kw "y")] cy ["+" [getf output (kw "y")] [getf output (kw "height")]]]]
                  ])
                ])
            ]
            outputs
          ])
        ])
    ])
  blank
  ({snapshot}:
    rows [
      [defun deck--area [snapshot]]
      (str "The focused window's output box and the area its exclusive zones leave free.")
      ({
        outputs,
        focus',
        entry,
        output,
        area,
      }:
        rows [
          [
            "let*"
            (rows [
              [[outputs [context snapshot (kw "outputs")]]]
              [[focus' [previous-context snapshot (kw "focus")]]]
              [[entry [and focus' [deck--layout-entry [previous-context snapshot (kw "layout")] focus']]]]
              [[output [or' [and entry [deck--output-of outputs entry]] [first outputs]]]]
              [[area [and output [policy--area snapshot [getf output (kw "name")]]]]]
            ])
          ]
          (rows [
            [when area]
            [["list*" (kw "output") output area]]
          ])
        ])
    ])
  blank
  ({
    state,
    width,
  }:
    rows [
      [defun deck--left-width [state width]]
      (str "How wide the left column is, out of WIDTH less the seam between the columns.")
      [[floor ["*" ["-" width [getf (constant layout) (kw "seam")]] [nth ["1-" [getf state (kw "ratio")]] [getf (constant layout) (kw "ratios")]]]]]
    ])
  blank
  ({state}:
    rows [
      [defun deck--grid-columns [state]]
      [[ceiling [sqrt [count-if ({id}: [lambda [id] [deck--manageable-p state id]]) [deck--windows state]]]]]
    ])
  blank
  ({cols}:
    rows [
      [defun deck--grid-extra [cols]]
      (str ''
        How much wider than a window gap the middle of an even grid is: it splits on
        the deck's seam, so whatever stands there stays between the columns.'')
      [[if' [evenp cols] ["-" [getf (constant layout) (kw "seam")] [getf (constant layout) (kw "gaps")]] 0]]
    ])
  blank
  ({
    cols,
    width,
  }:
    rows [
      [defun deck--grid-cell [cols width]]
      [[floor ["-" width ["*" ["1-" cols] [getf (constant layout) (kw "gaps")]] [deck--grid-extra cols]] cols]]
    ])
  blank
  ({
    state,
    width,
  }:
    rows [
      [defun deck--split [state width]]
      (str ''
        Where the seam starts within the tiled WIDTH, or NIL when the deck has no
        middle seam: a grid with an odd number of columns.'')
      (rows [
        [if' [getf state (kw "grid")]]
        ({cols}:
          rows [
            [let' [[cols [deck--grid-columns state]]]]
            (rows [
              [when [and [plusp cols] [evenp cols]]]
              ({half}:
                rows [
                  [let' [[half ["/" cols 2]]]]
                  [["+" ["*" half [deck--grid-cell cols width]] ["*" ["1-" half] [getf (constant layout) (kw "gaps")]]]]
                ])
            ])
          ])
        [[deck--left-width state width]]
      ])
    ])
  blank
  ({
    state,
    area,
  }:
    rows [
      [defun deck--seam [state area]]
      (str ''
        The free strip in the deck's middle seam on AREA, a window gap in from each
        side; NIL on a narrow output, while a window is fullscreen, in a grid with an
        odd number of columns, or when the seam is no wider than two gaps.'')
      ({
        gaps,
        x,
        split,
        inner,
      }:
        rows [
          [
            "let*"
            (rows [
              [[gaps [getf (constant layout) (kw "gaps")]]]
              [[x [and area ["+" [getf area (kw "x")] gaps]]]]
              [[split [and area [deck--split state ["-" [getf area (kw "width")] ["*" 2 gaps]]]]]]
              [[inner ["-" [getf (constant layout) (kw "seam")] ["*" 2 gaps]]]]
            ])
          ]
          (rows [
            [unless [or' [null' split] [getf state (kw "fullscreen")] [deck--narrow-p' area] [not [plusp inner]]]]
            (rows [
              [list (kw "output") [getf [getf area (kw "output")] (kw "name")]]
              [(kw "x") ["+" x split gaps] (kw "y") ["+" [getf area (kw "y")] gaps]]
              [(kw "width") inner (kw "height") ["-" [getf area (kw "height")] ["*" 2 gaps]]]
            ])
          ])
        ])
    ])
  blank
  ({
    state,
    area,
    id,
  }:
    rows [
      [defun deck--box [state area id]]
      (str "Where ID goes, or NIL when it is not in the window set.")
      ({
        gaps,
        x,
        y,
        width,
        height,
      }:
        rows [
          [
            "let*"
            (rows [
              [[gaps [getf (constant layout) (kw "gaps")]]]
              [[x ["+" [getf area (kw "x")] gaps]] [y ["+" [getf area (kw "y")] gaps]]]
              [[width ["-" [getf area (kw "width")] ["*" 2 gaps]]] [height ["-" [getf area (kw "height")] ["*" 2 gaps]]]]
            ])
          ]
          (rows [
            cond
            [[[not [member id [deck--windows state]]] nil]]
            (rows [
              [[member id [getf state (kw "fullscreen")]]]
              ({output}:
                rows [
                  [let' [[output [getf area (kw "output")]]]]
                  [[list [getf output (kw "x")] [getf output (kw "y")] [getf output (kw "width")] [getf output (kw "height")]]]
                ])
            ])
            [[[member id [getf state (kw "floating")]] [cdr [deck--entry [getf state (kw "floats")] id]]]]
            (rows [
              [[getf state (kw "grid")]]
              ({
                wins,
                index,
                count,
                cols,
                rows',
                cell-width,
                cell-height,
                column,
                row,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [
                        [
                          wins
                          (rows [
                            [remove-if-not ({candidate}: [lambda [candidate] [deck--manageable-p state candidate]])]
                            [[deck--windows state]]
                          ])
                        ]
                      ]
                      [[index [position id wins]]]
                      [[count [length wins]]]
                      [[cols [ceiling [sqrt count]]]]
                      [[rows' [ceiling count cols]]]
                      [[cell-width [deck--grid-cell cols width]]]
                      [[cell-height [floor ["-" height ["*" ["1-" rows'] gaps]] rows']]]
                      [[column [mod index cols]]]
                      [[row [floor index cols]]]
                    ])
                  ]
                  (rows [
                    [list ["+" x ["*" column ["+" cell-width gaps]] [if' [">=" column ["/" cols 2]] [deck--grid-extra cols] 0]]]
                    [["+" y ["*" row ["+" cell-height gaps]]]]
                    [cell-width cell-height]
                  ])
                ])
            ])
            (rows [
              [[deck--narrow-p' area]]
              ({
                column,
                front,
                index,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [
                        [
                          column
                          (rows [
                            [remove-if-not ({candidate}: [lambda [candidate] [deck--manageable-p state candidate]])]
                            [[deck--windows state]]
                          ])
                        ]
                      ]
                      [[front [or' [position [deck--current state] column] 0]]]
                      [[index [position id column]]]
                    ])
                  ]
                  (rows [
                    [when index]
                    [[list x ["+" y ["*" ["-" index front] ["+" height gaps]]] width height]]
                  ])
                ])
            ])
            (rows [
              t
              ({
                seam,
                left-width,
                right-width,
                side,
                column,
                front,
                index,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[seam [getf (constant layout) (kw "seam")]]]
                      [[left-width [deck--left-width state width]]]
                      [[right-width ["-" width seam left-width]]]
                      [[side [deck--side-of state id]]]
                      [[column [deck--column state side]]]
                      [[front [position [deck--front state side] column]]]
                      [[index [position id column]]]
                    ])
                  ]
                  (rows [
                    [when [and side index front]]
                    (rows [
                      [list [if' [eql side (kw "left")] x ["+" x left-width seam]]]
                      [["+" y ["*" ["-" index front] ["+" height gaps]]]]
                      [[if' [eql side (kw "left")] left-width right-width]]
                      height
                    ])
                  ])
                ])
            ])
          ])
        ])
    ])
  blank
  ({
    managed,
    state,
    area,
  }:
    rows [
      [defun deck--places [managed state area]]
      (str "One place effect per managed window: exactly one owner, no duplicates.")
      ({windows}:
        rows [
          [let' [[windows [deck--windows state]]]]
          ({
            window,
            id,
            box,
          }:
            rows [
              [loop for window in' managed]
              [for id "=" [getf window (kw "id")]]
              [for box "=" [deck--box state area id]]
              [
                append
                [
                  list
                  (rows [
                    [if' box]
                    [[apply (function place) id [append box [list t]]]]
                    (rows [
                      [place id 0 0 [max 1 [getf window (kw "width")]]]
                      [[max 1 [getf window (kw "height")]] nil]
                    ])
                  ])
                ]
              ]
              [
                append
                [
                  list
                  [
                    fullscreen
                    id
                    (rows [
                      [and box [member id windows]]
                      [[member id [getf state (kw "fullscreen")]]]
                      t
                    ])
                  ]
                ]
              ]
            ])
        ])
    ])
  blank
  ({
    state,
    id,
  }:
    rows [
      [defun deck--focus-window [state id]]
      [[setf [getf state (kw "focus")] id]]
      state
    ])
  blank
  ({
    state,
    side,
    id,
  }:
    rows [
      [defun deck--adopt-front [state side id]]
      ({fronts}:
        rows [
          [let' [[fronts [deck--fronts state]]]]
          [[setf [cdr [assoc side fronts]] id]]
        ])
      state
    ])
  blank
  ({
    state,
    direction,
  }:
    rows [
      [defun deck--rotate [state direction]]
      (str "Scroll the side holding the current window; the deck wraps.")
      ({
        id,
        side,
        column,
      }:
        rows [
          [
            "let*"
            (rows [
              [[id [deck--current state]]]
              [[side [deck--side-of state id]]]
              [[column [deck--column state side]]]
            ])
          ]
          (rows [
            [when [and side column]]
            ({
              index,
              target,
            }:
              rows [
                [
                  "let*"
                  (rows [
                    [[index [position id column]]]
                    [[target [nth [mod ["+" index direction] [length column]] column]]]
                  ])
                ]
                [[deck--adopt-front state side target]]
                [[deck--focus-window state target]]
              ])
          ])
        ])
    ])
  blank
  ({
    state,
    direction,
  }:
    rows [
      [defun deck--reorder [state direction]]
      (str "Swap the current window with its neighbour in its own column's order.")
      ({
        id,
        side,
        column,
        index,
        other,
        order,
        mine,
        theirs,
      }:
        rows [
          [
            "let*"
            (rows [
              [[id [deck--current state]]]
              [[side [deck--side-of state id]]]
              [[column [deck--column state side]]]
              [[index [position id column]]]
              [[other [and index [">=" ["+" index direction] 0] [nth ["+" index direction] column]]]]
              [[order [deck--windows state]]]
              [[mine [and other [position id order]]]]
              [[theirs [and other [position other order]]]]
            ])
          ]
          (rows [
            [when [and other mine theirs]]
            (rows [
              [setf [nth mine order] other]
              [[nth theirs order] id]
            ])
          ])
          state
        ])
    ])
  blank
  ({
    state,
    direction,
  }:
    rows [
      [defun deck--reorder-all [state direction]]
      ({
        order,
        index,
        target,
      }:
        rows [
          [
            "let*"
            (rows [
              [[order [deck--windows state]]]
              [[index [position [deck--current state] order]]]
              [[target [and index ["+" index direction]]]]
            ])
          ]
          (rows [
            [when [and target ["<" (-1) target [length order]]]]
            [[rotatef [nth index order] [nth target order]]]
          ])
          state
        ])
    ])
  blank
  ({
    state,
    direction,
  }:
    rows [
      [defun deck--cycle [state direction]]
      (str "Focus the next or previous window in the window set, wrapping.")
      ({
        order,
        id,
        index,
        target,
      }:
        rows [
          [
            "let*"
            (rows [
              [[order [deck--windows state]]]
              [[id [deck--current state]]]
              [[index [or' [position id order] 0]]]
              [[target [and order [nth [mod ["+" index direction] [length order]] order]]]]
            ])
          ]
          (rows [
            [when target]
            ({side}:
              rows [
                [let' [[side [deck--side-of state target]]]]
                [[when side [deck--adopt-front state side target]]]
              ])
            [[deck--focus-window state target]]
          ])
        ])
    ])
  blank
  ({state}:
    rows [
      [defun deck--swap-columns [state]]
      ({entry}:
        rows [
          [dolist [entry [getf state (kw "columns")]]]
          [[setf [cdr entry] [if' [eql [cdr entry] (kw "left")] (kw "right") (kw "left")]]]
        ])
      ({fronts}:
        rows [
          [let' [[fronts [deck--fronts state]]]]
          ({
            left,
            right,
          }:
            rows [
              [let' [[left [cdr [assoc (kw "left") fronts]]] [right [cdr [assoc (kw "right") fronts]]]]]
              [[setf [cdr [assoc (kw "left") fronts]] right [cdr [assoc (kw "right") fronts]] left]]
            ])
        ])
      state
    ])
  blank
  ({
    state,
    side,
  }:
    rows [
      [defun deck--to-column [state side]]
      (str "Send the current window to SIDE, where it becomes that deck's front.")
      ({
        id,
        previous,
      }:
        rows [
          [
            "let*"
            (rows [
              [[id [deck--current state]]]
              [[previous [deck--side-of state id]]]
            ])
          ]
          (rows [
            [when [and id [deck--manageable-p state id]]]
            (rows [
              [when [and previous [not [eql previous side]] [eql id [deck--front state previous]]]]
              ({
                column,
                index,
                next,
              }:
                rows [
                  [
                    "let*"
                    (rows [
                      [[column [deck--column state previous]]]
                      [[index [position id column]]]
                      [[next [and index [nth [mod ["1+" index] [length column]] column]]]]
                    ])
                  ]
                  [[deck--adopt-front state previous [if' [and next [not [eql next id]]] next nil]]]
                ])
            ])
            [[setf [cdr [assoc id [getf state (kw "columns")]]] side]]
            [[deck--adopt-front state side id]]
          ])
          state
        ])
    ])
  blank
  ({
    state,
    id,
    on',
  }:
    rows [
      [defun deck--set-fullscreen [state id on']]
      [[setf [getf state (kw "fullscreen")] [remove id [getf state (kw "fullscreen")]]]]
      (rows [
        [when on']
        [[setf [getf state (kw "floating")] [remove id [getf state (kw "floating")]]]]
        [[push id [getf state (kw "fullscreen")]]]
        [[deck--focus-window state id]]
      ])
      state
    ])
  blank
  ({
    state,
    area,
  }:
    rows [
      [defun deck--toggle-floating [state area]]
      ({id}:
        rows [
          [let' [[id [deck--current state]]]]
          (rows [
            cond
            [[[null' id]]]
            [[[member id [getf state (kw "fullscreen")]] [deck--set-fullscreen state id nil]]]
            (rows [
              [[member id [getf state (kw "floating")]]]
              (rows [
                [setf [getf state (kw "floating")] [remove id [getf state (kw "floating")]]]
                [[getf state (kw "floats")] [remove id [getf state (kw "floats")] (kw "key") (function car)]]
              ])
            ])
            (rows [
              area
              [[push id [getf state (kw "floating")]]]
              [[push [cons id [policy--centred area [getf (constant layout) (kw "float-ratio")]]] [getf state (kw "floats")]]]
            ])
          ])
          state
        ])
    ])
  blank
  ({
    state,
    area,
    command,
  }:
    rows [
      [defun deck--command [state area command]]
      (rows [
        cond
        (rows [
          (rows [
            [and [deck--narrow-p' area]]
            (rows [
              [or' [member command (constant deck--column-commands) (kw "test") (function equal)]]
              [[member command (quote [(str "scroll-down") (str "scroll-up") (str "move-down") (str "move-up")]) (kw "test") (function equal)]]
            ])
          ])
          (rows [
            [cond [[equal command (str "scroll-down")] [deck--cycle state 1]]]
            [[[equal command (str "scroll-up")] [deck--cycle state (-1)]]]
            [[[equal command (str "move-down")] [deck--reorder-all state 1]]]
            [[[equal command (str "move-up")] [deck--reorder-all state (-1)]]]
          ])
        ])
        (rows [
          [[equal command (str "focus-left")]]
          [[deck--focus-window state [or' [deck--front state (kw "left")] [deck--current state]]]]
        ])
        (rows [
          [[equal command (str "focus-right")]]
          [[deck--focus-window state [or' [deck--front state (kw "right")] [deck--current state]]]]
        ])
        [[[equal command (str "scroll-down")] [deck--rotate state 1]]]
        [[[equal command (str "scroll-up")] [deck--rotate state (-1)]]]
        [[[equal command (str "next")] [deck--cycle state 1]]]
        [[[equal command (str "previous")] [deck--cycle state (-1)]]]
        [[[equal command (str "swap-columns")] [deck--swap-columns state]]]
        [[[equal command (str "move-down")] [deck--reorder state 1]]]
        [[[equal command (str "move-up")] [deck--reorder state (-1)]]]
        [[[equal command (str "to-left")] [deck--to-column state (kw "left")]]]
        [[[equal command (str "to-right")] [deck--to-column state (kw "right")]]]
        [[[equal command (str "grid")] [setf [getf state (kw "grid")] [not [getf state (kw "grid")]]]]]
        (rows [
          [[equal command (str "ratio")]]
          [[setf [getf state (kw "ratio")] ["1+" [mod [getf state (kw "ratio")] [length [getf (constant layout) (kw "ratios")]]]]]]
        ])
        [[[equal command (str "floating")] [deck--toggle-floating state area]]]
        (rows [
          [[equal command (str "fullscreen")]]
          ({id}:
            rows [
              [let' [[id [deck--current state]]]]
              [[when id [deck--set-fullscreen state id [not [member id [getf state (kw "fullscreen")]]]]]]
            ])
        ])
        [[t state]]
      ])
    ])
  blank
  ({
    state,
    id,
    request,
    requested,
  }:
    rows [
      [defun deck--request [state id request requested]]
      (rows [
        [case request]
        [[(kw "fullscreen") [deck--set-fullscreen state id requested]]]
        [[(kw "unfullscreen") [deck--set-fullscreen state id nil]]]
        (rows [
          (kw "activate")
          ({side}:
            rows [
              [let' [[side [deck--side-of state id]]]]
              [[when [and side [deck--manageable-p state id]] [deck--adopt-front state side id]]]
              [[deck--focus-window state id]]
            ])
        ])
      ])
      state
    ])
  blank
  ({
    state,
    current,
  }:
    rows [
      [defun deck--raises [state current]]
      (rows [
        [mapcar (function raise-window)]
        (rows [
          [append [remove current [reverse [getf state (kw "floating")]]]]
          [[when [member current [getf state (kw "floating")]] [list current]]]
          [[getf state (kw "fullscreen")]]
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
      [define-extension (str "deck")]
      (rows [
        [
          (kw "reads")
          (rows [
            [(kw "windows") (kw "rules") (kw "data") (kw "outputs") (kw "workareas") (kw "layout") (kw "focus") (kw "key") (kw "button") (kw "pointer") (kw "request")]
            (kw "settings")
          ])
        ]
        [(kw "state") [deck--state] (kw "admission") t]
      ])
      [[snapshot state event]]
      ({
        windows,
        ids,
        focused,
        area,
        type,
        command,
        terminal,
      }:
        rows [
          [
            "let*"
            (rows [
              [
                [
                  windows
                  (rows [
                    [remove-if ({window}: [lambda [window] [policy--unmanaged-p snapshot window]])]
                    [[context snapshot (kw "windows")]]
                  ])
                ]
              ]
              [[ids [mapcar ({window}: [lambda [window] [getf window (kw "id")]]) windows]]]
              [[focused [previous-context snapshot (kw "focus")]]]
              [[area [deck--area snapshot]]]
              [[type [getf event (kw "type")]]]
              [[command [and [eq type (kw "key")] [equal [getf event (kw "owner")] (str "deck")] [getf event (kw "command")]]]]
              [[terminal [and [equal command (str "terminal")] [policy--terminal windows]]]]
            ])
          ]
          (rows [
            [when [eq type (kw "unmap")]]
            ({gone}:
              rows [
                [let' [[gone [getf event (kw "id")]]]]
                ({side}:
                  rows [
                    [dolist [side (quote [(kw "left") (kw "right")])]]
                    (rows [
                      [when [eql gone [cdr [assoc side [getf state (kw "fronts")]]]]]
                      ({next}:
                        rows [
                          [let' [[next [deck--after-front state [deck--windows state] side gone]]]]
                          [[setf [cdr [assoc side [getf state (kw "fronts")]]] next]]
                          (rows [
                            [when [and next [eql gone [getf state (kw "focus")]]]]
                            [[setf [getf state (kw "focus")] next]]
                          ])
                        ])
                    ])
                  ])
              ])
          ])
          (rows [
            [setf [getf state (kw "windows")] [remove-if-not ({id}: [lambda [id] [member id ids]]) [getf state (kw "windows")]]]
            [
              [getf state (kw "columns")]
              (rows [
                [remove-if-not ({entry}: [lambda [entry] [member [car entry] ids]])]
                [[getf state (kw "columns")]]
              ])
            ]
            [[getf state (kw "fronts")]]
            ({entry}:
              rows [
                [loop for entry in' [getf state (kw "fronts")]]
                [
                  collect
                  (rows [
                    [if' [and [cdr entry] [not [member [cdr entry] ids]]]]
                    [[cons [car entry] nil]]
                    entry
                  ])
                ]
              ])
            [[getf state (kw "floating")] [remove-if-not ({id}: [lambda [id] [member id ids]]) [getf state (kw "floating")]]]
            [
              [getf state (kw "floats")]
              (rows [
                [remove-if-not ({entry}: [lambda [entry] [member [car entry] ids]])]
                [[getf state (kw "floats")]]
              ])
            ]
            [
              [getf state (kw "fullscreen")]
              (rows [
                [remove-if-not ({id}: [lambda [id] [member id ids]])]
                [[getf state (kw "fullscreen")]]
              ])
            ]
          ])
          [[unless [member [getf state (kw "focus")] ids] [setf [getf state (kw "focus")] nil]]]
          (rows [
            [
              when
              (rows [
                [and focused [not [eql focused [getf state (kw "focus")]]]]
                [[member focused [deck--windows state]]]
                [[deck--manageable-p state focused]]
              ])
            ]
            ({side}:
              rows [
                [let' [[side [deck--side-of state focused]]]]
                (rows [
                  [when side]
                  [[deck--adopt-front state side focused]]
                  [[deck--focus-window state focused]]
                ])
              ])
          ])
          ({window}:
            rows [
              [dolist [window windows]]
              ({id}:
                rows [
                  [let' [[id [getf window (kw "id")]]]]
                  (rows [
                    [unless [or' [deck--side-of state id] [member id [getf state (kw "floating")]]]]
                    ({
                      focus-side,
                      left,
                      right,
                      side,
                    }:
                      rows [
                        [
                          "let*"
                          (rows [
                            [[focus-side [and focused [deck--side-of state focused]]]]
                            [[left [length [deck--column state (kw "left")]]]]
                            [[right [length [deck--column state (kw "right")]]]]
                            [[side [or' focus-side [if' ["<=" left right] (kw "left") (kw "right")]]]]
                          ])
                        ]
                        [[push [cons id side] [getf state (kw "columns")]]]
                        [[setf [getf state (kw "windows")] [append [getf state (kw "windows")] [list id]]]]
                        [[deck--adopt-front state side id]]
                        [[setf [getf state (kw "focus")] id]]
                        (rows [
                          [when [getf window (kw "fullscreen-requested")]]
                          [[deck--set-fullscreen state id t]]
                        ])
                      ])
                  ])
                ])
            ])
          (rows [
            [when command]
            [[deck--command state area command]]
          ])
          (rows [
            [when terminal]
            [[deck--request state terminal (kw "activate") nil]]
          ])
          (rows [
            [when [and [member type (quote [(kw "metadata") (kw "request")])] [member [getf event (kw "id")] ids]]]
            [[deck--request state [getf event (kw "id")] [getf event (kw "request")] [getf event (kw "requested")]]]
          ])
          (rows [
            [
              when
              (rows [
                [or' [and [eq type (kw "button")] [eql [getf event (kw "state")] (kw "pressed")]]]
                (rows [
                  [and [eq type (kw "pointer")] [eq [getf event (kw "state")] (kw "enter")] [getf event (kw "moved")]]
                  [[setting snapshot (kw "focus-follows-mouse")]]
                ])
              ])
            ]
            ({id}:
              rows [
                [let' [[id [getf event (kw "id")]]]]
                (rows [
                  [when [and [integerp id] [member id [deck--windows state]]]]
                  (rows [
                    [when [and [deck--manageable-p state id] [deck--side-of state id]]]
                    [[deck--adopt-front state [deck--side-of state id] id]]
                  ])
                  [[deck--focus-window state id]]
                ])
              ])
          ])
          ({current}:
            rows [
              [let' [[current [deck--current state]]]]
              (rows [
                [values state]
                (rows [
                  [
                    append
                    (rows [
                      [mapcar ({binding}: [lambda [binding] [apply (function bind-key) binding]])]
                      (rows [
                        [if' [deck--narrow-p' area]]
                        (rows [
                          [
                            remove-if
                            ({binding}:
                              rows [
                                [lambda [binding]]
                                (rows [
                                  [member [string-downcase [third binding]]]
                                  [(constant deck--column-commands) (kw "test") (function equal)]
                                ])
                              ])
                          ]
                          (constant layout-bindings)
                        ])
                        (constant layout-bindings)
                      ])
                    ])
                  ]
                  [[when area [deck--places windows state area]]]
                  [[list [publish-state (kw "deck-seam") [deck--seam state area]]]]
                  [[deck--raises state current]]
                  [[list [focus current (kw "raise") nil]]]
                ])
                (rows [
                  [when [and [equal command (str "terminal")] [null' terminal]]]
                  [[list [apply (function launch) [policy--launch (str "terminal")]]]]
                ])
              ])
            ])
        ])
    ])
])
