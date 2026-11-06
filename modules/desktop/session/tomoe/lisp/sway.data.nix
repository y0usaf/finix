{
  abs,
  acons,
  and,
  append,
  apply,
  assoc,
  atom,
  below,
  bind-key,
  blank,
  car,
  case,
  cdr,
  collect,
  cond,
  cons,
  constant,
  context,
  define-extension,
  defun,
  destructuring-bind,
  do,
  dolist,
  dot,
  eq,
  eql,
  equal,
  fifth,
  find,
  first,
  flet,
  floor,
  focus,
  for,
  fourth,
  from,
  fullscreen,
  function,
  getf,
  hide-window,
  if',
  in',
  in-package,
  incf,
  integerp,
  kw,
  labels,
  lambda,
  last,
  launch,
  layout,
  layout-bindings,
  ldiff,
  length,
  let',
  list,
  loop,
  mapcar,
  max,
  member,
  min,
  mod,
  nil,
  not,
  nreverse,
  nth,
  null',
  on,
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
  push,
  quote,
  raise-window,
  remove,
  remove-if,
  remove-if-not,
  rest,
  return,
  reverse,
  rows,
  second,
  setf,
  setting,
  settings,
  show-window,
  str,
  t,
  third,
  to,
  uninterned,
  unless,
  values,
  when,
  zerop,
  ...
}: ({
  sway--leaves,
  sway--prune,
  sway--insert,
  sway--swap,
  sway--boxes,
  sway--neighbour,
}: [
  [in-package (uninterned "tomoe-user")]
  blank
  ({tree}:
    rows [
      [defun sway--leaves [tree]]
      (rows [
        [cond [[null' tree] nil]]
        [[[integerp tree] [list tree]]]
        [[t ({kid}: [loop for kid in' [rest tree] append [sway--leaves kid]])]]
      ])
    ])
  blank
  ({
    tree,
    keep,
  }:
    rows [
      [defun sway--prune [tree keep]]
      (rows [
        [cond [[null' tree] nil]]
        [[[integerp tree] [when [member tree keep] tree]]]
        [
          [
            t
            ({kids}:
              rows [
                [
                  let'
                  [
                    [
                      kids
                      ({
                        kid,
                        pruned,
                      }:
                        rows [
                          [loop for kid in' [rest tree]]
                          [for pruned "=" [sway--prune kid keep]]
                          [when pruned collect pruned]
                        ])
                    ]
                  ]
                ]
                [[if' [rest kids] [cons [first tree] kids] [first kids]]]
              ])
          ]
        ]
      ])
    ])
  blank
  ({
    tree,
    target,
    id,
    direction,
  }:
    rows [
      [defun sway--insert [tree target id direction]]
      (rows [
        [cond [[integerp tree] [if' [eql tree target] [list direction tree id] tree]]]
        (rows [
          [[and [eq [first tree] direction] [member target [rest tree]]]]
          ({tail}:
            rows [
              [let' [[tail [member target [rest tree]]]]]
              [[append [ldiff tree [rest tail]] [list id] [rest tail]]]
            ])
        ])
        [
          [
            t
            (rows [
              [cons [first tree]]
              ({kid}:
                rows [
                  [loop for kid in' [rest tree]]
                  [
                    collect
                    (rows [
                      [if' [member target [sway--leaves kid]]]
                      [[sway--insert kid target id direction]]
                      kid
                    ])
                  ]
                ])
            ])
          ]
        ]
      ])
    ])
  blank
  ({
    tree,
    a,
    b,
  }:
    rows [
      [defun sway--swap [tree a b]]
      (rows [
        [cond [[eql tree a] b]]
        [[[eql tree b] a]]
        [[[atom tree] tree]]
        [[t [cons [first tree] ({kid}: [loop for kid in' [rest tree] collect [sway--swap kid a b]])]]]
      ])
    ])
  blank
  ({
    tree,
    x,
    y,
    width,
    height,
    gap',
  }:
    rows [
      [defun sway--boxes [tree x y width height gap']]
      (rows [
        [if' [integerp tree]]
        [[list [list tree x y width height]]]
        ({
          kids,
          horizontal,
          origin,
          span,
          step,
          start,
        }:
          rows [
            [
              "let*"
              (rows [
                [[kids [rest tree]]]
                [[horizontal [eq [first tree] (kw "h")]]]
                [[origin [if' horizontal x y]]]
                [[span [if' horizontal width height]]]
                [[step [floor ["-" span ["*" ["1-" [length kids]] gap']] [length kids]]]]
                [[start origin]]
              ])
            ]
            ({
              kid,
              more,
              size,
            }:
              rows [
                [loop for [kid dot more] on kids]
                [for size "=" [if' more step ["-" ["+" origin span] start]]]
                [
                  append
                  (rows [
                    [if' horizontal]
                    [[sway--boxes kid start y size height gap']]
                    [[sway--boxes kid x start width size gap']]
                  ])
                ]
                [do [incf start ["+" size gap']]]
              ])
          ])
      ])
    ])
  blank
  ({
    boxes,
    id,
    dx,
    dy,
  }:
    rows [
      [defun sway--neighbour [boxes id dx dy]]
      ({
        from',
        best,
        distance,
      }:
        rows [
          [let' [[from' [assoc id boxes]] [best nil] [distance nil]]]
          ({centre}:
            rows [
              [flet [({box}: [centre [box] [list ["+" [second box] ["/" [fourth box] 2]] ["+" [third box] ["/" [fifth box] 2]]]])]]
              (rows [
                [when from']
                ({
                  fx,
                  fy,
                }:
                  rows [
                    [destructuring-bind [fx fy] [centre from']]
                    ({box}:
                      rows [
                        [dolist [box boxes]]
                        ({
                          cx,
                          cy,
                        }:
                          rows [
                            [destructuring-bind [cx cy] [centre box]]
                            ({
                              ddx,
                              ddy,
                              along,
                              across',
                              far,
                            }:
                              rows [
                                [
                                  "let*"
                                  (rows [
                                    [[ddx ["-" cx fx]] [ddy ["-" cy fy]]]
                                    [[along [if' [zerop dx] ddy ddx]]]
                                    [[across' [if' [zerop dx] ddx ddy]]]
                                    [[far ["+" [abs ddx] [abs ddy]]]]
                                  ])
                                ]
                                (rows [
                                  [
                                    when
                                    (rows [
                                      [and [not [eq box from']]]
                                      [[eq [plusp along] [plusp ["+" dx dy]]]]
                                      [[">" [abs along] [abs across']]]
                                      [[or' [null' distance] ["<" far distance]]]
                                    ])
                                  ]
                                  [[setf best [first box] distance far]]
                                ])
                              ])
                          ])
                      ])
                  ])
              ])
            ])
          best
        ])
    ])
  blank
  ({
    snapshot,
    state,
    event,
  }:
    rows [
      [define-extension (str "sway")]
      (rows [
        [(kw "reads") [(kw "windows") (kw "rules") (kw "data") (kw "workareas") (kw "outputs") (kw "focus") (kw "key") (kw "button") (kw "pointer") (kw "request") (kw "settings")]]
        [
          (kw "state")
          (rows [
            [list (kw "active") 1 (kw "workspaces") nil (kw "trees") nil (kw "split") nil (kw "focus") nil]
            [(kw "fullscreen") nil (kw "floating") nil]
          ])
        ]
        [(kw "admission") t]
      ])
      [[snapshot state event]]
      ({
        windows,
        ids,
        count,
        gap',
        area,
        output',
        type,
        command,
        motion,
        active,
        workspaces,
        trees,
        split,
        focused,
        fullscreen',
        floating,
        external,
        terminal,
        new,
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
              [[count [getf (constant layout) (kw "workspaces")]]]
              [[gap' [getf (constant layout) (kw "gaps")]]]
              [[area [policy--area snapshot]]]
              [
                [
                  output'
                  [
                    and
                    area
                    (rows [
                      [find [getf area (kw "name")] [context snapshot (kw "outputs")]]
                      [(kw "test") (function equal) (kw "key") ({output}: [lambda [output] [getf output (kw "name")]])]
                    ])
                  ]
                ]
              ]
              [[type [getf event (kw "type")]]]
              [[command [and [eq type (kw "key")] [equal [getf event (kw "owner")] (str "sway")] [getf event (kw "command")]]]]
              [
                [
                  motion
                  [
                    rest
                    (rows [
                      [
                        assoc
                        command
                        (quote (rows [
                          [[(str "focus-left") (-1) 0] [(str "focus-right") 1 0]]
                          [[(str "focus-up") 0 (-1)] [(str "focus-down") 0 1]]
                        ]))
                      ]
                      [(kw "test") (function equal)]
                    ])
                  ]
                ]
              ]
              [[active [max 1 [min count [getf state (kw "active")]]]]]
              [
                [
                  workspaces
                  ({index}:
                    rows [
                      [loop for index below count]
                      [
                        collect
                        (rows [
                          [remove-if-not ({id}: [lambda [id] [member id ids]])]
                          [[nth index [getf state (kw "workspaces")]]]
                        ])
                      ]
                    ])
                ]
              ]
              [[trees ({index}: [loop for index below count collect [nth index [getf state (kw "trees")]]])]]
              [[split [remove-if-not ({entry}: [lambda [entry] [member [car entry] ids]]) [getf state (kw "split")]]]]
              [[focused [getf state (kw "focus")]]]
              [[fullscreen' [remove-if-not ({id}: [lambda [id] [member id ids]]) [getf state (kw "fullscreen")]]]]
              [[floating [remove-if-not ({entry}: [lambda [entry] [member [car entry] ids]]) [getf state (kw "floating")]]]]
              [[external [previous-context snapshot (kw "focus")]]]
              [[terminal [and [equal command (str "terminal")] [policy--terminal windows]]]]
              [[new nil]]
            ])
          ]
          ({
            workspace,
            home,
            boxes,
            arrange,
            arrange-all,
            switch,
            neighbour,
          }:
            rows [
              [
                labels
                (rows [
                  ({number}: [workspace [number] [nth ["1-" number] workspaces]])
                  ({id}: [
                    home
                    [id]
                    ({
                      list',
                      number,
                    }:
                      rows [
                        [loop for list' in' workspaces for number from 1]
                        [when [member id list'] return number]
                      ])
                  ])
                  ({tree}:
                    rows [
                      [boxes [tree]]
                      (rows [
                        [when [and tree area]]
                        (rows [
                          [sway--boxes tree ["+" [getf area (kw "x")] gap'] ["+" [getf area (kw "y")] gap']]
                          [["-" [getf area (kw "width")] ["*" 2 gap']] ["-" [getf area (kw "height")] ["*" 2 gap']] gap']
                        ])
                      ])
                    ])
                  ({number}:
                    rows [
                      [arrange [number]]
                      ({
                        keep,
                        tree,
                      }:
                        rows [
                          [
                            "let*"
                            (rows [
                              [
                                [
                                  keep
                                  (rows [
                                    [remove-if ({id}: [lambda [id] [or' [member id fullscreen'] [assoc id floating]]])]
                                    [[workspace number]]
                                  ])
                                ]
                              ]
                              [[tree [sway--prune [nth ["1-" number] trees] keep]]]
                            ])
                          ]
                          ({id}:
                            rows [
                              [dolist [id keep]]
                              (rows [
                                [unless [member id [sway--leaves tree]]]
                                (rows [
                                  [setf tree]
                                  (rows [
                                    [if' [null' tree]]
                                    id
                                    ({
                                      leaves,
                                      target,
                                      box,
                                      direction,
                                    }:
                                      rows [
                                        [
                                          "let*"
                                          (rows [
                                            [[leaves [sway--leaves tree]]]
                                            [[target [if' [member focused leaves] focused [car [last leaves]]]]]
                                            [[box [assoc target [boxes tree]]]]
                                            [
                                              [
                                                direction
                                                (rows [
                                                  [or' [cdr [assoc target split]]]
                                                  [[if' [and box [">" [fifth box] [fourth box]]] (kw "v") (kw "h")]]
                                                ])
                                              ]
                                            ]
                                          ])
                                        ]
                                        [[setf split [remove target split (kw "key") (function car)]]]
                                        [[sway--insert tree target id direction]]
                                      ])
                                  ])
                                ])
                              ])
                            ])
                          [[setf [nth ["1-" number] trees] tree]]
                        ])
                    ])
                  [[arrange-all [] ({number}: [loop for number from 1 to count do [arrange number]])]]
                  ({number}:
                    rows [
                      [switch [number]]
                      [[setf active number focused [car [last [workspace number]]]]]
                    ])
                  ({direction}: [neighbour [direction] ["1+" [mod ["+" active (-1) direction] count]]])
                ])
              ]
              (rows [
                [when [and [member external ids] [not [eql external focused]]]]
                [[setf focused external active [or' [home external] active]]]
              ])
              ({known}:
                rows [
                  [let' [[known ({list'}: [loop for list' in' workspaces append list'])]]]
                  ({window}:
                    rows [
                      [dolist [window windows]]
                      ({id}:
                        rows [
                          [let' [[id [getf window (kw "id")]]]]
                          (rows [
                            [unless [member id known]]
                            [[setf [nth ["1-" active] workspaces] [append [workspace active] [list id]]]]
                            [[when [getf window (kw "fullscreen-requested")] [push id fullscreen']]]
                            [[push id new]]
                          ])
                        ])
                    ])
                ])
              (rows [
                [case type]
                (rows [
                  (kw "button")
                  (rows [
                    [when [and [eq [getf event (kw "state")] (kw "pressed")] [member [getf event (kw "id")] [workspace active]]]]
                    [[setf focused [getf event (kw "id")]]]
                  ])
                ])
                (rows [
                  (kw "pointer")
                  (rows [
                    [
                      when
                      (rows [
                        [and [eq [getf event (kw "state")] (kw "enter")] [getf event (kw "moved")]]
                        [[setting snapshot (kw "focus-follows-mouse")]]
                        [[member [getf event (kw "id")] [workspace active]]]
                      ])
                    ]
                    [[setf focused [getf event (kw "id")]]]
                  ])
                ])
                (rows [
                  [[(kw "metadata") (kw "request")]]
                  ({id}:
                    rows [
                      [let' [[id [getf event (kw "id")]]]]
                      (rows [
                        [when [member id ids]]
                        (rows [
                          [case [getf event (kw "request")]]
                          (rows [
                            (kw "fullscreen")
                            [[setf fullscreen' [remove id fullscreen']]]
                            [[when [getf event (kw "requested")] [push id fullscreen'] [setf focused id]]]
                          ])
                          [[(kw "unfullscreen") [setf fullscreen' [remove id fullscreen']]]]
                          [[(kw "activate") [setf active [or' [home id] active] focused id]]]
                        ])
                      ])
                    ])
                ])
              ])
              (rows [
                [when terminal]
                [[setf active [or' [home terminal] active] focused terminal]]
              ])
              [[arrange-all]]
              ({current}:
                rows [
                  [let' [[current [and [member focused [workspace active]] focused]]]]
                  (rows [
                    cond
                    [[[null' command]]]
                    (rows [
                      motion
                      ({target}:
                        rows [
                          [let' [[target [apply (function sway--neighbour) [boxes [nth ["1-" active] trees]] current motion]]]]
                          [[when target [setf focused target]]]
                        ])
                    ])
                    [[[equal command (str "workspace-next")] [switch [neighbour 1]]]]
                    [[[equal command (str "workspace-previous")] [switch [neighbour (-1)]]]]
                    [[[null' current]]]
                    (rows [
                      [[member command (quote [(str "move-next") (str "move-previous")]) (kw "test") (function equal)]]
                      ({number}:
                        rows [
                          [let' [[number [neighbour [if' [equal command (str "move-next")] 1 (-1)]]]]]
                          (rows [
                            [setf [nth ["1-" active] workspaces] [remove current [workspace active]]]
                            [[nth ["1-" number] workspaces] [append [workspace number] [list current]]]
                          ])
                          [[switch number]]
                        ])
                    ])
                    (rows [
                      [[member command (quote [(str "swap-previous") (str "swap-next")]) (kw "test") (function equal)]]
                      ({
                        leaves,
                        index,
                        other,
                      }:
                        rows [
                          [
                            "let*"
                            (rows [
                              [[leaves [sway--leaves [nth ["1-" active] trees]]]]
                              [[index [position current leaves]]]
                              [[other [and index ["+" index [if' [equal command (str "swap-next")] 1 (-1)]]]]]
                            ])
                          ]
                          (rows [
                            [when [and other ["<" (-1) other [length leaves]]]]
                            (rows [
                              [setf [nth ["1-" active] trees]]
                              [[sway--swap [nth ["1-" active] trees] current [nth other leaves]]]
                            ])
                          ])
                        ])
                    ])
                    (rows [
                      [[equal command (str "split-horizontal")]]
                      [[setf split [acons current (kw "h") [remove current split (kw "key") (function car)]]]]
                    ])
                    (rows [
                      [[equal command (str "split-vertical")]]
                      [[setf split [acons current (kw "v") [remove current split (kw "key") (function car)]]]]
                    ])
                    (rows [
                      [[equal command (str "fullscreen")]]
                      (rows [
                        [if' [member current fullscreen']]
                        [[setf fullscreen' [remove current fullscreen']]]
                        [[push current fullscreen']]
                      ])
                    ])
                    (rows [
                      [[equal command (str "floating")]]
                      (rows [
                        [cond [[member current fullscreen'] [setf fullscreen' [remove current fullscreen']]]]
                        [[[assoc current floating] [setf floating [remove current floating (kw "key") (function car)]]]]
                        [
                          [
                            area
                            (rows [
                              [push [cons current [policy--centred area [getf (constant layout) (kw "float-ratio")]]]]
                              floating
                            ])
                          ]
                        ]
                      ])
                    ])
                  ])
                ])
              [[arrange-all]]
              ({arrived}:
                rows [
                  [let' [[arrived [remove-if-not ({id}: [lambda [id] [member id [workspace active]]]) new]]]]
                  [[when arrived [setf focused [first arrived]]]]
                ])
              (rows [
                [unless [member focused [workspace active]]]
                [[setf focused [car [last [workspace active]]]]]
              ])
              ({effects}:
                rows [
                  [let' [[effects nil]]]
                  ({id}:
                    rows [
                      [dolist [id ids]]
                      ({
                        number,
                        shown,
                        box,
                      }:
                        rows [
                          [
                            "let*"
                            (rows [
                              [[number [home id]]]
                              [[shown [eql number active]]]
                              [
                                [
                                  box
                                  (rows [
                                    [
                                      cond
                                      (rows [
                                        [[member id fullscreen']]
                                        [
                                          [
                                            and
                                            output'
                                            (rows [
                                              [list [getf output' (kw "x")] [getf output' (kw "y")]]
                                              [[getf output' (kw "width")] [getf output' (kw "height")]]
                                            ])
                                          ]
                                        ]
                                      ])
                                    ]
                                    [[[cdr [assoc id floating]]]]
                                    [[t [rest [assoc id [boxes [nth ["1-" number] trees]]]]]]
                                  ])
                                ]
                              ]
                            ])
                          ]
                          (rows [
                            [
                              push
                              (rows [
                                [if' box]
                                ({
                                  x,
                                  y,
                                  width,
                                  height,
                                }:
                                  rows [
                                    [destructuring-bind [x y width height] box]
                                    [[place id x y [max 1 width] [max 1 height] shown]]
                                  ])
                                [[if' shown [show-window id] [hide-window id]]]
                              ])
                            ]
                            effects
                          ])
                          [[push [fullscreen id [and [member id fullscreen'] t]] effects]]
                        ])
                    ])
                  ({floats}:
                    rows [
                      [
                        let'
                        [
                          [
                            floats
                            (rows [
                              [remove-if ({id}: [lambda [id] [member id fullscreen']])]
                              [[mapcar (function car) [reverse floating]]]
                            ])
                          ]
                        ]
                      ]
                      ({id}:
                        rows [
                          [
                            dolist
                            [
                              id
                              (rows [
                                [append [remove focused floats]]
                                [[when [member focused floats] [list focused]]]
                                fullscreen'
                              ])
                            ]
                          ]
                          [[when [member id [workspace active]] [push [raise-window id] effects]]]
                        ])
                    ])
                  [[push [focus focused (kw "raise") nil] effects]]
                  [[push [settings (kw "animations") nil] effects]]
                  ({binding}: [dolist [binding (constant layout-bindings)] [push [apply (function bind-key) binding] effects]])
                  (rows [
                    [
                      values
                      (rows [
                        [list (kw "active") active (kw "workspaces") workspaces (kw "trees") trees (kw "split") split]
                        [(kw "focus") focused (kw "fullscreen") fullscreen' (kw "floating") floating]
                      ])
                    ]
                    [[nreverse effects]]
                    (rows [
                      [when [and [equal command (str "terminal")] [null' terminal]]]
                      [[list [apply (function launch) [policy--launch (str "terminal")]]]]
                    ])
                  ])
                ])
            ])
        ])
    ])
])
