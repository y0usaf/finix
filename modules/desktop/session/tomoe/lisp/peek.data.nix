{
  and,
  apply,
  bind-key,
  blank,
  cond,
  cons,
  constant,
  context,
  define-extension,
  eq,
  equal,
  focus,
  function,
  getf,
  hide-window,
  in-package,
  intersection,
  kw,
  lambda,
  let',
  mapcar,
  nil,
  peek,
  rows,
  setf,
  str,
  subsetp,
  uninterned,
  unless,
  values,
  when,
  ...
}: [
  [in-package (uninterned "tomoe-user")]
  blank
  ({
    snapshot,
    hidden,
    event,
  }:
    rows [
      [define-extension (str "peek") [(kw "reads") [(kw "key") (kw "windows")] (kw "state") nil] [snapshot hidden event]]
      ({live}:
        rows [
          [let' [[live [mapcar ({window}: [lambda [window] [getf window (kw "id")]]) [context snapshot (kw "windows")]]]]]
          [
            [
              setf
              hidden
              (rows [
                [
                  cond
                  (rows [
                    [[and [eq [getf event (kw "type")] (kw "key")] [equal [getf event (kw "owner")] (str "peek")]]]
                    [[unless hidden live]]
                  ])
                ]
                [[[subsetp live hidden] [intersection hidden live]]]
              ])
            ]
          ]
          (rows [
            [values hidden]
            (rows [
              ["list*" [apply (function bind-key) [getf (constant peek) (kw "bind")]]]
              [[when hidden [cons [focus nil] [mapcar (function hide-window) hidden]]]]
            ])
            nil
          ])
        ])
    ])
]
