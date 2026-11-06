{
  adjust-brightness,
  and,
  apply,
  bind-key,
  blank,
  close-window,
  cond,
  constant,
  context,
  declare,
  define-extension,
  eq,
  equal,
  function,
  getf,
  ignore,
  in-package,
  kw,
  lambda,
  launch,
  let',
  list,
  mapcar,
  media-control,
  nil,
  null',
  output-power,
  policy--launch,
  policy-bindings,
  quit,
  rows,
  screenshot,
  str,
  t,
  uninterned,
  values,
  when,
  ...
}: [
  [in-package (uninterned "tomoe-user")]
  blank
  ({
    snapshot,
    state,
    event,
  }:
    rows [
      [define-extension (str "user") [(kw "reads") [(kw "key") (kw "focus")] (kw "state") nil] [snapshot state event]]
      [[declare [ignore state]]]
      ({
        command,
        focused,
      }:
        rows [
          [
            let'
            (rows [
              [
                [
                  command
                  (rows [
                    [
                      when
                      (rows [
                        [and [eq [getf event (kw "type")] (kw "key")]]
                        [[equal [getf event (kw "owner")] (str "user")]]
                      ])
                    ]
                    [[getf event (kw "command")]]
                  ])
                ]
              ]
              [[focused [context snapshot (kw "focus")]]]
            ])
          ]
          (rows [
            [values nil]
            [[mapcar ({binding}: [lambda [binding] [apply (function bind-key) binding]]) (constant policy-bindings)]]
            (rows [
              cond
              [[[null' command] nil]]
              [[[equal command (str "close")] [when focused [list [close-window focused]]]]]
              [[[equal command (str "quit")] [list [quit]]]]
              [[[equal command (str "power")] [list [output-power (kw "toggle")]]]]
              [[[equal command (str "screenshot")] [list [screenshot]]]]
              [[[equal command (str "screenshot-screen")] [list [screenshot (kw "screen")]]]]
              [[[equal command (str "play-pause")] [list [media-control (kw "play-pause")]]]]
              [[[equal command (str "track-next")] [list [media-control (kw "next")]]]]
              [[[equal command (str "track-prev")] [list [media-control (kw "previous")]]]]
              [[[equal command (str "brightness-up")] [list [adjust-brightness 5]]]]
              [[[equal command (str "brightness-down")] [list [adjust-brightness (-5)]]]]
              (rows [
                t
                ({argv}:
                  rows [
                    [let' [[argv [policy--launch command]]]]
                    [[when argv [list [apply (function launch) argv]]]]
                  ])
              ])
            ])
          ])
        ])
    ])
]
