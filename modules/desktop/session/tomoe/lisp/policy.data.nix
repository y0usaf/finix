{
  and,
  and-optional,
  append,
  apply,
  assoc,
  blank,
  cdr,
  configure-output,
  constant,
  context,
  declare,
  define-extension,
  defun,
  dot,
  equal,
  find,
  first,
  floor,
  focus,
  function,
  getf,
  hide-window,
  ignore,
  in-package,
  kw,
  lambda,
  length,
  let',
  list,
  mapcar,
  max,
  nil,
  or',
  place,
  policy-displays,
  policy-hidden-window,
  policy-launcher,
  policy-launches,
  policy-settings,
  policy-terminal,
  quote,
  rows,
  rules-for,
  second,
  settings,
  str,
  stringp,
  t,
  uninterned,
  values,
  when,
  window-properties,
  window-rule,
  ...
}: ({
  policy--prefix-p,
  policy--launch',
  policy--terminal',
  policy--unmanaged-p',
  policy--area',
  policy--centred',
}: [
  [in-package (uninterned "tomoe-user")]
  blank
  ({
    prefix,
    text,
  }:
    rows [
      [defun policy--prefix-p [prefix text]]
      (rows [
        [and [stringp text] [">=" [length text] [length prefix]]]
        [["string=" prefix text (kw "end2") [length prefix]]]
      ])
    ])
  blank
  ({command}:
    rows [
      [defun policy--launch' [command]]
      [[second [assoc command (constant policy-launches) (kw "test") (function equal)]]]
    ])
  blank
  ({windows}:
    rows [
      [defun policy--terminal' [windows]]
      (rows [
        [
          getf
          (rows [
            [find [getf (constant policy-terminal) (kw "app-id")] windows]
            [(kw "key") ({window}: [lambda [window] [getf window (kw "app-id")]]) (kw "test") (function equal)]
          ])
        ]
        (kw "id")
      ])
    ])
  blank
  ({
    snapshot,
    window,
  }:
    rows [
      [defun policy--unmanaged-p' [snapshot window]]
      ({properties}:
        rows [
          [let' [[properties [rules-for snapshot window]]]]
          [[or' [cdr [assoc (kw "float") properties]] [cdr [assoc (kw "hidden") properties]]]]
        ])
    ])
  blank
  ({
    snapshot,
    name,
  }:
    rows [
      [defun policy--area' [snapshot and-optional name]]
      ({areas}:
        rows [
          [let' [[areas [context snapshot (kw "workareas")]]]]
          (rows [
            [or' [find name areas (kw "test") (function equal) (kw "key") ({area}: [lambda [area] [getf area (kw "name")]])]]
            [[first areas]]
          ])
        ])
    ])
  blank
  ({
    area,
    ratio',
  }:
    rows [
      [defun policy--centred' [area ratio']]
      ({
        width,
        height,
      }:
        rows [
          [
            let'
            (rows [
              [[width [max 1 [floor ["*" [getf area (kw "width")] ratio']]]]]
              [[height [max 1 [floor ["*" [getf area (kw "height")] ratio']]]]]
            ])
          ]
          (rows [
            [list ["+" [getf area (kw "x")] [floor ["-" [getf area (kw "width")] width] 2]]]
            [["+" [getf area (kw "y")] [floor ["-" [getf area (kw "height")] height] 2]]]
            [width height]
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
      [define-extension (str "session") [] [snapshot state event]]
      [[declare [ignore snapshot event]]]
      (rows [
        [values state]
        (rows [
          [append [mapcar ({display}: [lambda [display] [apply (function configure-output) display]]) (constant policy-displays)]]
          [[list [apply (function settings) (constant policy-settings)]]]
        ])
        nil
      ])
    ])
  blank
  ({
    snapshot,
    state,
    event,
  }:
    rows [
      [define-extension (str "rules") [] [snapshot state event]]
      [[declare [ignore snapshot event]]]
      (rows [
        [values state]
        (rows [
          [
            list
            (rows [
              [window-rule (kw "launcher")]
              [
                (kw "match")
                ({
                  window,
                  snapshot,
                }:
                  rows [
                    [lambda [window snapshot]]
                    [[declare [ignore snapshot]]]
                    [
                      [
                        or'
                        [equal [getf window (kw "app-id")] [getf (constant policy-launcher) (kw "app-id")]]
                        [
                          and
                          [equal [getf window (kw "app-id")] [getf (constant policy-terminal) (kw "app-id")]]
                          [equal [getf window (kw "title")] (str "launcher")]
                        ]
                      ]
                    ]
                  ])
              ]
              [(kw "properties") (quote [[(kw "float") dot t]]) (kw "reads") (quote [(kw "workareas")])]
              [
                (kw "apply")
                ({
                  window,
                  snapshot,
                  state,
                  event,
                }:
                  rows [
                    [lambda [window snapshot state event]]
                    [[declare [ignore event]]]
                    ({
                      id,
                      area,
                    }:
                      rows [
                        [
                          let'
                          (rows [
                            [[id [getf window (kw "id")]]]
                            [[area [policy--area' snapshot]]]
                          ])
                        ]
                        (rows [
                          [values state]
                          (rows [
                            [
                              append
                              (rows [
                                [when area]
                                [
                                  [
                                    list
                                    [
                                      apply
                                      (function place)
                                      id
                                      (rows [
                                        policy--centred'
                                        [area [getf (constant policy-launcher) (kw "ratio")]]
                                      ])
                                    ]
                                  ]
                                ]
                              ])
                            ]
                            [
                              [
                                list
                                [window-properties id (kw "border") (quote [(kw "focused") (str "#00000000") (kw "unfocused") (str "#00000000")])]
                                [focus id]
                              ]
                            ]
                          ])
                          nil
                        ])
                      ])
                  ])
              ]
            ])
          ]
          (rows [
            [window-rule (kw "hidden") (kw "app-id") [getf (constant policy-hidden-window) (kw "app-id")]]
            [
              (kw "match")
              ({
                window,
                snapshot,
              }:
                rows [
                  [lambda [window snapshot]]
                  [[declare [ignore snapshot]]]
                  (rows [
                    [policy--prefix-p [getf (constant policy-hidden-window) (kw "title-prefix")]]
                    [[getf window (kw "title")]]
                  ])
                ])
            ]
            [(kw "properties") (quote [[(kw "hidden") dot t]])]
            [
              (kw "apply")
              ({
                window,
                snapshot,
                state,
                event,
              }:
                rows [
                  [lambda [window snapshot state event]]
                  [[declare [ignore snapshot event]]]
                  [[values state [list [hide-window [getf window (kw "id")]]] nil]]
                ])
            ]
          ])
        ])
        nil
      ])
    ])
])
