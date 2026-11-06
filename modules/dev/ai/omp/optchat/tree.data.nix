{
  Buffer,
  Error,
  Math,
  Number,
  array,
  arrayOf,
  arrow,
  below,
  blank,
  boolean,
  break,
  call,
  class,
  const,
  continue,
  dot,
  export,
  field,
  fn,
  for,
  forOf,
  idx,
  if',
  import',
  inc,
  infix,
  interface,
  let',
  method,
  new,
  not,
  num,
  number,
  obj,
  prop,
  readonly,
  regex,
  return,
  rows,
  spread,
  str,
  string,
  sub,
  ternary,
  this,
  throw',
  tpl,
  typed,
  void,
  while,
  ...
}: ({
  EMPTY_VIEW,
  NODE,
  PLACEHOLDER,
  bytes,
  flat,
  key,
  Limits,
  Part,
  Meta,
  start,
  end,
  partKey,
  cut,
  Tree,
}: [
  (import' [EMPTY_VIEW NODE PLACEHOLDER bytes flat key] (str "./store.ts"))
  blank
  (export (interface Limits [
    (typed "max" number)
    (typed "min" number)
    (typed "draining" boolean)
  ]))
  blank
  (export (interface Part [
    (typed "l" number)
    (typed "i" number)
  ]))
  blank
  (export (interface Meta [
    (typed "time" number)
    (typed "session" string)
  ]))
  blank
  (export (const start ({p}: (arrow [(typed p Part)] (infix [(dot p "i") "*" 2 "**" (dot p "l")])))))
  (export (const end ({p}: (arrow [(typed p Part)] (infix [[(dot p "i") "+" 1] "*" 2 "**" (dot p "l")])))))
  (export (const partKey ({p}: (arrow [(typed p Part)] (call key [(dot p "l") (dot p "i")])))))
  blank
  (export ({text}: (fn cut (typed [(typed text string)] string) [
    (if' (infix [(call bytes [text]) "<=" NODE]) (return text))
    (return (call (dot (call (dot (call (dot (call (dot Buffer "from") [text (str "utf8")]) "subarray") [0 NODE]) "toString") [(str "utf8")]) "replace") [(regex "\\uFFFD+$" "") (str "")]))
  ])))
  blank
  (export (class Tree [
    (field (typed "msgs" (arrayOf Meta)) (array []))
    (field (typed "nodes" (arrayOf (arrayOf string))) (array []))
    (field (typed "view" (arrayOf Part)) (array []))
    (field (typed "small" (arrayOf Part)) (array []))
    (field (typed "big" Limits) (obj [(prop "max" (num "128_000")) (prop "min" (num "64_000")) (prop "draining" false)]))
    (field (typed "little" Limits) (obj [(prop "max" (num "32_000")) (prop "min" (num "16_000")) (prop "draining" false)]))
    blank
    ({onBuilt}: (method "constructor" [
      (readonly (typed onBuilt ({
        p,
        text,
      }: (arrow [(typed p Part) (typed text string)] void))))
    ] []))
    blank
    ({p}: (method "has" (typed [(typed p Part)] boolean) [
      (return (infix [(dot p "l") ">=" 0 "&&" (dot p "i") ">=" 0 "&&" (dot p "l") "<" (dot this "nodes.length") "&&" (dot p "i") "<" (dot (idx (dot this "nodes") (dot p "l")) "length")]))
    ]))
    blank
    ({p}: (method "built" (typed [(typed p Part)] boolean) [
      (return (infix [(call (dot this "has") [p]) "&&" (idx (idx (dot this "nodes") (dot p "l")) (dot p "i")) "!==" (str "")]))
    ]))
    blank
    ({p}: (method "text" (typed [(typed p Part)] string) [
      (return (ternary (call (dot this "built") [p]) (idx (idx (dot this "nodes") (dot p "l")) (dot p "i")) PLACEHOLDER))
    ]))
    blank
    ({n}: (method "grow" (typed [] void) [
      (const n (dot this "msgs.length"))
      ({
        l,
        level,
        want,
      }: (for (let' l 0) (infix [2 "**" l "<=" n]) (inc l) [
        (if' (infix [l "===" (dot this "nodes.length")]) (call (dot this "nodes.push") [(array [])]))
        (const level (idx (dot this "nodes") l))
        (const want (call (dot Math "floor") [(infix [n "/" 2 "**" l])]))
        (while (infix [(dot level "length") "<" want]) (call (dot level "push") [(str "")]))
      ]))
    ]))
    blank
    ({
      meta,
      text,
      i,
    }: (method "add" (typed [(typed meta Meta) (typed text string)] boolean) [
      (call (dot this "msgs.push") [meta])
      (call (dot this "grow") [])
      (const i (infix [(dot this "msgs.length") "-" 1]))
      (if' (infix [(call bytes [text]) "<=" NODE]) (call (dot this "set") [(obj [(prop "l" 0) i]) text]))
      (call (dot this "view.push") [(obj [(prop "l" 0) i])])
      (call (dot this "small.push") [(obj [(prop "l" 0) i])])
      (return (call (dot this "fit") [(dot this "msgs.length")]))
    ]))
    blank
    ({
      l,
      i,
      a,
      b,
    }: (method "join" (typed [(typed l number) (typed i number)] boolean) [
      (const a (idx (idx (dot this "nodes") (infix [l "-" 1])) (infix [2 "*" i])))
      (const b (idx (idx (dot this "nodes") (infix [l "-" 1])) (infix [2 "*" i "+" 1])))
      (if' (infix [(idx (idx (dot this "nodes") l) i) "!==" (str "") "||" a "===" (str "") "||" b "===" (str "") "||" (call bytes [a]) "+" 1 "+" (call bytes [b]) ">" NODE]) (return false))
      (infix [(idx (idx (dot this "nodes") l) i) "=" (tpl [(sub a) "\\n" (sub b)])])
      (call (dot this "onBuilt") [(obj [l i]) (idx (idx (dot this "nodes") l) i)])
      (return true)
    ]))
    blank
    ({
      p,
      text,
      at,
    }: (method "set" (typed [(typed p Part) (typed text string)] void) [
      (infix [(idx (idx (dot this "nodes") (dot p "l")) (dot p "i")) "=" text])
      (call (dot this "onBuilt") [p text])
      (let' at p)
      (while (below (infix (rows [
          (dot at "l")
          "+"
          1
          "<"
          (dot this "nodes.length")
          "&&"
          (dot at "i")
          ">>"
          1
          "<"
          (dot (idx (dot this "nodes") (infix [(dot at "l") "+" 1])) "length")
          "&&"
          (call (dot this "join") [(infix [(dot at "l") "+" 1]) (infix [(dot at "i") ">>" 1])])
        ]))) [
          (infix [at "=" (obj [(prop "l" (infix [(dot at "l") "+" 1])) (prop "i" (infix [(dot at "i") ">>" 1]))])])
        ])
    ]))
    blank
    (method "freeMerges" (typed [] void) [
      ({l}: (for (let' l 1) (infix [l "<" (dot this "nodes.length")]) (inc l) [
        ({i}: (for (let' i 0) (infix [i "<" (dot (idx (dot this "nodes") l) "length")]) (inc i) (call (dot this "join") [l i])))
      ]))
    ])
    blank
    ({
      n,
      merged,
    }: (method "fit" (typed [(typed n number)] boolean) [
      (const merged (call (dot this "squeeze") [(dot this "view") n (dot this "big")]))
      (if' merged [
        (infix [(dot this "small") "=" (array [(spread (dot this "view"))])])
        (infix [(dot this "little.draining") "=" true])
      ])
      (call (dot this "squeeze") [(dot this "small") n (dot this "little")])
      (return merged)
    ]))
    blank
    ({
      view,
      n,
      limits,
      size,
      merged,
    }: (method "squeeze" (typed [(typed view (arrayOf Part)) (typed n number) (typed limits Limits)] boolean) [
      (let' size 0)
      (let' merged false)
      ({p}: (forOf p view (infix [size "+=" (call bytes [(call (dot this "text") [p])])])))
      (if' (infix [size ">" (dot limits "max")]) (infix [(dot limits "draining") "=" true]))
      (while (infix [(dot limits "draining") "&&" size ">" (dot limits "min")]) ({
        best,
        due,
        a,
        b,
        parent,
      }: [
        (let' best (-1))
        (let' due 0)
        ({
          k,
          a,
          b,
          d,
        }: (for (let' k 0) (infix [k "+" 1 "<" (dot view "length")]) (inc k) [
          (const a (idx view k))
          (const b (idx view (infix [k "+" 1])))
          (if' (infix [(dot a "l") "!==" (dot b "l") "||" (dot a "i") "%" 2 "!==" 0 "||" (dot b "i") "!==" (dot a "i") "+" 1 "||" (not (call (dot this "built") [(obj [(prop "l" (infix [(dot a "l") "+" 1])) (prop "i" (infix [(dot a "i") "/" 2]))])]))]) continue)
          (const d (infix [[n "-" (call end [b]) "+" 1] "/" 2 "**" (dot a "l")]))
          (if' (infix [best "<" 0 "||" d ">" due]) [
            (infix [best "=" k])
            (infix [due "=" d])
          ])
        ]))
        (if' (infix [best "<" 0]) (return merged))
        (const a (idx view best))
        (const b (idx view (infix [best "+" 1])))
        (const parent (obj [(prop "l" (infix [(dot a "l") "+" 1])) (prop "i" (infix [(dot a "i") "/" 2]))]))
        (infix [size "+=" (call bytes [(call (dot this "text") [parent])]) "-" (call bytes [(call (dot this "text") [a])]) "-" (call bytes [(call (dot this "text") [b])])])
        (call (dot view "splice") [best 2 parent])
        (infix [merged "=" true])
      ]))
      (infix [(dot limits "draining") "=" false])
      (return merged)
    ]))
    blank
    (method "layout" (typed [] void) [
      (infix [(dot this "view") "=" (array [])])
      (infix [(dot this "small") "=" (array [])])
      (infix [(dot this "big.draining") "=" false])
      (infix [(dot this "little.draining") "=" false])
      ({i}: (for (let' i 0) (infix [i "<" (dot this "msgs.length")]) (inc i) [
        (call (dot this "view.push") [(obj [(prop "l" 0) i])])
        (call (dot this "small.push") [(obj [(prop "l" 0) i])])
        (call (dot this "fit") [(infix [i "+" 1])])
      ]))
    ])
    blank
    ({
      levels,
      view,
      at,
      down,
    }: (method "restore" (typed [(typed levels (readonly (arrayOf number)))] boolean) [
      (const (typed view (arrayOf Part)) (array []))
      (let' at 0)
      ({l}: (forOf l levels [
        (if' (infix [(not (call (dot Number "isInteger") [l])) "||" l "<" 0 "||" at "%" 2 "**" l "!==" 0 "||" at "+" 2 "**" l ">" (dot this "msgs.length")]) (return false))
        (call (dot view "push") [(obj [l (prop "i" (infix [at "/" 2 "**" l]))])])
        (infix [at "+=" 2 "**" l])
      ]))
      (for null (infix [at "<" (dot this "msgs.length")]) (inc at) (call (dot view "push") [(obj [(prop "l" 0) (prop "i" at)])]))
      (const down ({p}: (arrow (typed [(typed p Part)] (arrayOf Part)) (below (ternary (infix [(dot p "l") "===" 0 "||" (call (dot this "built") [p])]) (below (array [p])) (below (call (dot (array (rows [
        (obj [(prop "l" (infix [(dot p "l") "-" 1])) (prop "i" (infix [2 "*" (dot p "i")]))])
        (obj [(prop "l" (infix [(dot p "l") "-" 1])) (prop "i" (infix [2 "*" (dot p "i") "+" 1]))])
      ])) "flatMap") [down])))))))
      (infix [(dot this "view") "=" (call (dot view "flatMap") [down])])
      (infix [(dot this "small") "=" (array [(spread (dot this "view"))])])
      (infix [(dot this "little.draining") "=" true])
      (call (dot this "fit") [(dot this "msgs.length")])
      (return true)
    ]))
    blank
    (method "first" (typed [] number) [
      ({p}: (forOf p (dot this "view") (if' (not (call (dot this "built") [p])) (return (call start [p])))))
      (return (dot this "msgs.length"))
    ])
    blank
    ({
      skip,
      ahead,
      first,
      out,
    }: (method "ready" (typed [(typed skip ({p}: (arrow [(typed p Part)] boolean))) (typed ahead number)] (arrayOf Part)) [
      (const first (call (dot this "first") []))
      (const (typed out (arrayOf Part)) (array []))
      ({
        l,
        level,
      }: (for (let' l 0) (infix [l "<" (dot this "nodes.length")]) (inc l) [
        (const level (idx (dot this "nodes") l))
        ({
          i,
          p,
        }: (for (let' i 0) (infix [i "<" (dot level "length")]) (inc i) [
          (if' (infix [(idx level i) "!==" (str "")]) continue)
          (const p (obj [l i]))
          (if' (infix [l ">" 0 "&&" [(not (call (dot this "built") [(obj [(prop "l" (infix [l "-" 1])) (prop "i" (infix [2 "*" i]))])])) "||" (not (call (dot this "built") [(obj [(prop "l" (infix [l "-" 1])) (prop "i" (infix [2 "*" i "+" 1]))])]))]]) continue)
          (if' (infix [(call start [p]) "<" first "+" ahead "&&" (not (call skip [p]))]) (call (dot out "push") [p]))
        ]))
      ]))
      (return out)
    ]))
    blank
    (method "levels" (typed [] (arrayOf number)) [
      (return (call (dot this "view.map") [({p}: (arrow [p] (dot p "l")))]))
    ])
    blank
    ({
      levels,
      upto,
      out,
      at,
    }: (method "render" (typed [(typed levels (readonly (arrayOf number))) (typed upto number)] string) [
      (if' (infix [upto "===" 0]) (return EMPTY_VIEW))
      (let' out (str "<chat>\\n"))
      (let' at 0)
      ({
        l,
        p,
      }: (forOf l levels [
        (const p (obj [l (prop "i" (infix [at "/" 2 "**" l]))]))
        (if' (infix [(not (call (dot this "has") [p])) "||" at "%" 2 "**" l "!==" 0 "||" (call end [p]) ">" upto]) [
          (throw' (new Error [(tpl ["optchat: view does not tile messages 0-" (sub upto)])]))
        ])
        (infix [out "+=" (tpl [(sub (call start [p])) "+" (sub (infix [2 "**" l])) "|" (sub (call flat [(call (dot this "text") [p])])) "\\n"])])
        (infix [at "=" (call end [p])])
      ]))
      (if' (infix [at "!==" upto]) (throw' (new Error [(tpl ["optchat: view covers " (sub at) " of " (sub upto) " messages"])])))
      (return (tpl [(sub out) "</chat>"]))
    ]))
    blank
    ({
      upto,
      levels,
      at,
    }: (method "upTo" (typed [(typed upto number)] string) [
      (const (typed levels (arrayOf number)) (array []))
      (let' at 0)
      ({p}: (forOf p (dot this "small") [
        (if' (infix [(call end [p]) ">" upto "||" (not (call (dot this "built") [p]))]) break)
        (call (dot levels "push") [(dot p "l")])
        (infix [at "=" (call end [p])])
      ]))
      (return (call (dot this "render") [levels at]))
    ]))
  ]))
])
