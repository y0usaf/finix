{
  and,
  append,
  assoc,
  at,
  blank,
  by,
  cdr,
  char,
  char',
  cond,
  cons,
  constant,
  context,
  define-extension,
  defun,
  digit-char-p,
  do,
  dotimes,
  eq,
  eql,
  equal,
  every,
  exec-async,
  first,
  for,
  from,
  function,
  getf,
  hud--c,
  hud--decay,
  hud--mix,
  hud--now,
  hud-theme,
  if',
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
  member,
  nil,
  not,
  nreverse,
  null',
  or',
  parse-integer,
  plusp,
  publish-state,
  push,
  quote,
  read-line,
  repeat,
  return,
  reverse,
  rows,
  second,
  setf,
  settings,
  str,
  string-upcase,
  subseq,
  sum,
  t,
  third,
  uninterned,
  unless,
  values,
  watch-file,
  when,
  while,
  with',
  with-input-from-string,
  ...
}: ({
  theme--words,
  theme--hex-p,
  theme--resolve,
  theme--palette,
  theme--mode,
}: [
  [in-package (uninterned "tomoe-user")]
  blank
  ({line}:
    rows [
      [defun theme--words [line]]
      ({
        words,
        start,
      }:
        rows [
          [let' [[words nil] [start nil]]]
          ({i}:
            rows [
              [dotimes [i ["1+" [length line]] [nreverse words]]]
              (rows [
                [if' [and ["<" i [length line]] [not [member [char' line i] (quote [(char "Space") (char "Tab") (char ";") (char "Return")])]]]]
                [[unless start [setf start i]]]
                [[when start [push [subseq line start i] words] [setf start nil]]]
              ])
            ])
        ])
    ])
  blank
  ({value'}:
    rows [
      [defun theme--hex-p [value']]
      (rows [
        [and [member [length value'] (quote [4 7 9])] ["char=" [char' value' 0] (char "#")]]
        [[every ({c}: [lambda [c] [digit-char-p c 16]]) [subseq value' 1]]]
      ])
    ])
  blank
  ({
    name,
    table,
  }:
    rows [
      [defun theme--resolve [name table]]
      ({key}:
        rows [
          [loop with' key "=" name]
          [repeat 8]
          [
            do
            ({value'}:
              rows [
                [let' [[value' [cdr [assoc key table (kw "test") (function equal)]]]]]
                (rows [
                  [cond [[null' value'] [return nil]]]
                  [[["char=" [char' value' 0] (char "@")] [setf key [subseq value' 1]]]]
                  [[[theme--hex-p value'] [return value']]]
                  [[t [return nil]]]
                ])
              ])
          ]
        ])
    ])
  blank
  ({css}:
    rows [
      [defun theme--palette [css]]
      ({table}:
        rows [
          [let' [[table nil]]]
          ({in'}:
            rows [
              [with-input-from-string [in' css]]
              ({line}:
                rows [
                  [loop for line "=" [read-line in' nil] while line]
                  [
                    do
                    ({words}:
                      rows [
                        [let' [[words [theme--words line]]]]
                        (rows [
                          [when [and ["=" 3 [length words]] [equal [first words] (str "@define-color")]]]
                          [[push [cons [second words] [third words]] table]]
                        ])
                      ])
                  ]
                ])
            ])
          ({
            name,
            value',
          }:
            rows [
              [loop for [name] in' [reverse table]]
              [for value' "=" [theme--resolve name table]]
              [when value' append [list [intern [string-upcase name] (kw "keyword")] value']]
            ])
        ])
    ])
  blank
  ({p}:
    rows [
      [defun theme--mode [p]]
      ({bg}:
        rows [
          [let' [[bg [getf p (kw "bg")]]]]
          (rows [
            [
              if'
              (rows [
                [and bg ["=" [length bg] 7]]
                (rows [
                  [
                    ">"
                    ({
                      i,
                      weight,
                    }:
                      rows [
                        [loop for i from 1 by 2]
                        [for weight in' (quote [0.2126 0.7152 0.0722])]
                        [sum ["*" weight [parse-integer bg (kw "start") i (kw "end") ["+" i 2] (kw "radix") 16]]]
                      ])
                  ]
                  127.5
                ])
              ])
            ]
            (kw "light")
            (kw "dark")
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
      [define-extension (str "theme") [(kw "reads") [(kw "focus")] (kw "state") [list (kw "palette") nil (kw "watch") nil (kw "focus") nil (kw "focus-at") nil]]]
      [[snapshot state event]]
      ({
        type,
        name,
        focus',
      }:
        rows [
          [let' [[type [getf event (kw "type")]] [name [getf event (kw "name")]] [focus' [context snapshot (kw "focus")]]]]
          (rows [
            [
              cond
              (rows [
                [[and [eq type (kw "exec")] [member name (quote [(kw "palette") (kw "reread")])] [eql [getf event (kw "code")] 0]]]
                (rows [
                  [setf [getf state (kw "palette")] [or' [theme--palette [getf event (kw "stdout")]] [getf state (kw "palette")]]]
                  [[getf state (kw "watch")] t]
                ])
              ])
            ]
            (rows [
              [[and [eq type (kw "watch")] [eq name (kw "palette")]]]
              [[setf [getf state (kw "palette")] [or' [theme--palette [getf event (kw "content")]] [getf state (kw "palette")]]]]
            ])
          ])
          (rows [
            [unless [equal focus' [getf state (kw "focus")]]]
            [[setf [getf state (kw "focus")] focus' [getf state (kw "focus-at")] [when focus' [hud--now]]]]
          ])
          ({
            fixed,
            p,
            flash,
          }:
            rows [
              [
                "let*"
                (rows [
                  [[fixed [getf (constant hud-theme) (kw "palette")]]]
                  [[p [or' fixed [getf state (kw "palette")]]]]
                  [[flash [hud--decay [getf state (kw "focus-at")] [getf (constant hud-theme) (kw "focus-flash")]]]]
                ])
              ]
              (rows [
                [values state]
                (rows [
                  [
                    append
                    [
                      unless
                      fixed
                      [
                        list
                        (rows [
                          [exec-async [if' [getf state (kw "watch")] (kw "reread") (kw "palette")]]
                          (at 16 [[getf (constant hud-theme) (kw "palette-command")]])
                        ])
                      ]
                    ]
                  ]
                  [[when [getf state (kw "watch")] [list [watch-file (kw "palette") [getf (constant hud-theme) (kw "palette-file")]]]]]
                  [[when [plusp flash] [list [interval (kw "tick") [getf (constant hud-theme) (kw "tick")]]]]]
                  [
                    [
                      when
                      p
                      (rows [
                        [list [publish-state (kw "hud-palette") p]]
                        [[publish-state (kw "theme-mode") [theme--mode p]]]
                        [
                          [
                            publish-state
                            (kw "theme")
                            (rows [
                              [list (kw "base") [hud--c p (kw "bg")] (kw "text") [hud--c p (kw "fg")]]
                              [(kw "accent") [hud--c p (kw "accent")] (kw "error") [hud--c p (kw "color1")]]
                              [(kw "surface1") [hud--c p (kw "color8")]]
                              [(kw "subtext0") [hud--mix [hud--c p (kw "bg")] [hud--c p (kw "fg")] 0.78]]
                            ])
                          ]
                        ]
                      ])
                    ]
                  ]
                  [
                    [
                      list
                      [
                        settings
                        (kw "border")
                        (rows [
                          [list (kw "width") [getf (constant hud-theme) (kw "border")] (kw "radius") 0]
                          [(kw "focused") [hud--mix [hud--c p (kw "accent")] [hud--c p (kw "fg")] flash]]
                          [(kw "unfocused") [hud--c p (kw "color8")]]
                        ])
                      ]
                    ]
                  ]
                ])
                nil
              ])
            ])
        ])
    ])
])
