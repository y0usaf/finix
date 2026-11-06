{
  and,
  append,
  blank,
  cassette,
  cassette--height,
  cassette--hot-p,
  cassette--module,
  cassette--plate,
  cassette--split,
  collect,
  cond,
  constant,
  context,
  copy-list,
  define-extension,
  defun,
  dolist,
  eq,
  first,
  flet,
  for,
  function,
  getf,
  if',
  in',
  in-package,
  interval,
  kw,
  lambda,
  let',
  list,
  loop,
  member,
  nil,
  nthcdr,
  probe--sample,
  publish-state,
  quote,
  remove,
  round,
  rows,
  setf,
  shell-surface,
  sort,
  state-value,
  str,
  subseq,
  t,
  thereis,
  ui,
  uninterned,
  values,
  when,
  ...
}: ({cassette--line}: [
  [in-package (uninterned "tomoe-user")]
  blank
  ({
    items,
    edge,
  }:
    rows [
      [defun cassette--line [items edge]]
      ({
        inset,
        seam,
      }:
        rows [
          [
            let'
            (rows [
              [[inset [getf (constant cassette) (kw "inset")]]]
              [[seam [cassette--split]]]
            ])
          ]
          ({half}:
            rows [
              [
                flet
                [
                  ({
                    plate,
                    justify,
                    padding,
                  }:
                    rows [
                      [half [plate justify padding]]
                      [[ui (kw "row") (kw "width") 0 (kw "grow") 1 (kw "justify") justify (kw "padding") padding (kw "children") [remove nil [list plate]]]]
                    ])
                ]
              ]
              (rows [
                [ui (kw "row") (kw "align") (kw "start") (kw "justify") (kw "center")]
                [
                  (kw "children")
                  (rows [
                    [if' seam]
                    (rows [
                      [list [half [cassette--plate [subseq items 0 seam] (kw "start") edge] (kw "end") [list 0 inset 0 0]]]
                      [[half [cassette--plate [nthcdr seam items] (kw "end") edge] (kw "start") [list 0 0 0 inset]]]
                    ])
                    [[remove nil [list [cassette--plate items (kw "both") edge]]]]
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
        items,
        focal,
        wide,
        height,
        hot,
      }:
        rows [
          [
            "let*"
            (rows [
              [
                [
                  items
                  ({module}:
                    rows [
                      [loop for module in' [getf (constant cassette) (kw "modules")]]
                      [collect [cassette--module module state snapshot]]
                    ])
                ]
              ]
              [[focal [state-value snapshot (kw "focal-frame")]]]
              [[wide [first [sort [copy-list [context snapshot (kw "outputs")]] (function ">") (kw "key") ({o}: [lambda [o] [getf o (kw "width")]])]]]]
              [[height [cassette--height (kw "bottom")]]]
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
                  (rows [
                    [publish-state (kw "bar-floor")]
                    (rows [
                      [when [member (kw "bottom") [getf (constant cassette) (kw "edges")]]]
                      (rows [
                        [
                          cond
                          [
                            focal
                            (rows [
                              [list (kw "output") [getf focal (kw "output")]]
                              [(kw "y") ["+" [getf focal (kw "top")] [getf focal (kw "height")] [round height 2]]]
                            ])
                          ]
                        ]
                        [[wide [list (kw "output") [getf wide (kw "name")] (kw "y") [getf wide (kw "height")]]]]
                      ])
                    ])
                  ])
                ])
              ]
              ({
                edge,
                line,
                height,
              }:
                rows [
                  [loop for edge in' [getf (constant cassette) (kw "edges")]]
                  [for line "=" [cassette--line items edge]]
                  [for height "=" [cassette--height edge]]
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
                                [[round height 2]]
                              ])
                            ]
                            [0 0 [getf focal (kw "left")]]
                          ])
                        ]
                        [(kw "layer") (kw "overlay") (kw "background") (str "#00000000") (kw "click-through") t]
                      ])
                      (rows [
                        [shell-surface edge line (kw "output") [getf wide (kw "name")] (kw "anchors") [list edge (kw "left") (kw "right")]]
                        [(kw "height") height (kw "margin") [if' [eq edge (kw "top")] (quote [(-1) 0 0 0]) (quote [0 0 (-1) 0])]]
                        [(kw "exclusive-zone") 0]
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
