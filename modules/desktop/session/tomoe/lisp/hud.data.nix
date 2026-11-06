{
  and,
  and-key,
  and-optional,
  blank,
  by,
  case,
  code-char,
  collect,
  concatenate,
  cond,
  constant,
  defun,
  double,
  float,
  for,
  format,
  from,
  get-internal-real-time,
  getf,
  hud,
  if',
  in-package,
  internal-time-units-per-second,
  kw,
  length,
  let',
  list,
  loop,
  max,
  min,
  most-positive-fixnum,
  nil,
  or',
  parse-integer,
  plusp,
  quote,
  repeat,
  round,
  rows,
  str,
  string,
  t,
  theme,
  ui,
  uninterned,
  ...
}: ({
  hud--now',
  hud--since,
  hud--decay',
  hud--c',
  hud--hex2,
  hud--alpha',
  hud--fade,
  hud--mix',
  hud--text',
  hud--icon',
  hud--dim',
  hud--off',
  hud--heat',
  hud--frame,
  hud--panel',
}: [
  [in-package (uninterned "tomoe-user")]
  blank
  (rows [
    [defun hud--now' []]
    [["/" [float [get-internal-real-time] (double 1)] internal-time-units-per-second]]
  ])
  blank
  ({at'}:
    rows [
      [defun hud--since [at']]
      [[if' at' ["*" 1000 ["-" [hud--now'] at']] most-positive-fixnum]]
    ])
  blank
  ({
    at',
    ms,
  }:
    rows [
      [defun hud--decay' [at' ms]]
      ({elapsed}:
        rows [
          [let' [[elapsed [hud--since at']]]]
          [[if' ["<" elapsed ms] ["-" 1 ["/" elapsed ms]] 0]]
        ])
    ])
  blank
  ({
    p,
    key,
  }:
    rows [
      [defun hud--c' [p key]]
      (rows [
        [or' [getf p key]]
        [
          [
            theme
            (rows [
              [case key]
              [[(kw "bg") (kw "base")] [[(kw "fg") (kw "color15")] (kw "text")] [(kw "color1") (kw "red")] [(kw "color2") (kw "green")] [(kw "color3") (kw "yellow")]]
              [[(kw "color4") (kw "blue")] [(kw "color5") (kw "mauve")] [(kw "color6") (kw "sky")] [(kw "color8") (kw "surface2")] [t (kw "accent")]]
            ])
          ]
        ]
      ])
    ])
  blank
  ({n}: [defun hud--hex2 [n] [format nil (str "~2,'0X") [max 0 [min 255 [round n]]]]])
  blank
  ({
    hex',
    aa,
  }: [defun hud--alpha' [hex' aa] [if' ["=" [length hex'] 7] [concatenate (quote string) hex' aa] hex']])
  blank
  ({
    hex',
    fraction,
  }: [defun hud--fade [hex' fraction] [hud--alpha' hex' [hud--hex2 ["*" 255 fraction]]]])
  blank
  ({
    a,
    b,
    f,
  }:
    rows [
      [defun hud--mix' [a b f]]
      (rows [
        [cond [["<=" f 0] a]]
        (rows [
          [[and ["=" [length a] 7] ["=" [length b] 7]]]
          (rows [
            [format nil (str "#~{~A~}")]
            ({i}:
              rows [
                [loop for i from 1 by 2 repeat 3]
                [
                  collect
                  [
                    hud--hex2
                    (rows [
                      ["+" ["*" ["-" 1 f] [parse-integer a (kw "start") i (kw "end") ["+" i 2] (kw "radix") 16]]]
                      [["*" f [parse-integer b (kw "start") i (kw "end") ["+" i 2] (kw "radix") 16]]]
                    ])
                  ]
                ]
              ])
          ])
        ])
        [[t b]]
      ])
    ])
  blank
  ({
    text,
    size,
    color,
    font,
  }:
    rows [
      [defun hud--text' [text size color and-optional [font [getf (constant hud) (kw "font")]]]]
      [[ui (kw "text") (kw "text") text (kw "size") size (kw "color") color (kw "font") font]]
    ])
  blank
  ({
    code,
    size,
    color,
  }:
    rows [
      [defun hud--icon' [code size color]]
      [[hud--text' [string [code-char code]] size color [getf (constant hud) (kw "icon-font")]]]
    ])
  blank
  ({
    p,
    fraction,
  }: [defun hud--dim' [p and-optional [fraction 0.6]] [hud--fade [hud--c' p (kw "fg")] fraction]])
  blank
  ({p}: [defun hud--off' [p] [hud--mix' [hud--c' p (kw "bg")] [hud--c' p (kw "fg")] 0.14]])
  blank
  ({
    percent,
    accent,
    p,
  }:
    rows [
      [defun hud--heat' [percent accent p]]
      [[cond [[">=" percent 90] [hud--c' p (kw "color1")]] [[">=" percent 70] [hud--c' p (kw "color3")]] [t accent]]]
    ])
  blank
  ({
    p,
    accent,
    flash,
    content,
    height,
  }:
    rows [
      [defun hud--frame [p accent flash content and-key height]]
      ({
        s,
        edge,
        body,
      }:
        rows [
          [
            "let*"
            (rows [
              [[s [getf (constant hud) (kw "shadow")]]]
              [[edge [hud--mix' accent [hud--c' p (kw "fg")] flash]]]
              [
                [
                  body
                  (rows [
                    [ui (kw "row") (kw "height") height (kw "align") (kw "stretch")]
                    [(kw "background") [hud--alpha' [hud--c' p (kw "bg")] (str "eb")]]
                    [(kw "border") 1 (kw "border-color") [hud--alpha' edge [if' [plusp flash] (str "ff") (str "b3")]]]
                    [(kw "children") [list [ui (kw "rect") (kw "width") 3 (kw "background") edge] content]]
                  ])
                ]
              ]
            ])
          ]
          [
            [
              ui
              (kw "stack")
              (kw "children")
              (rows [
                [
                  list
                  (rows [
                    [ui (kw "row") (kw "padding") [list s 0 0 s] (kw "align") (kw "stretch")]
                    [(kw "children") [list [ui (kw "rect") (kw "grow") 1 (kw "background") [hud--mix' [hud--c' p (kw "bg")] edge 0.6]]]]
                  ])
                ]
                [[ui (kw "row") (kw "padding") [list 0 s s 0] (kw "children") [list body]]]
              ])
            ]
          ]
        ])
    ])
  blank
  ({
    p,
    accent,
    children,
    flash,
  }:
    rows [
      [defun hud--panel' [p accent children and-key [flash 0]]]
      (rows [
        [hud--frame p accent flash [ui (kw "row") (kw "align") (kw "center") (kw "gap") 8 (kw "padding") (quote [0 10 0 8]) (kw "children") children]]
        [(kw "height") [getf (constant hud) (kw "height")]]
      ])
    ])
])
