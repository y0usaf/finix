{
  Buffer,
  Date,
  Intl,
  JSON,
  Map,
  Math,
  Record,
  String,
  array,
  arrayOf,
  arrow,
  blank,
  boolean,
  break,
  call,
  catch,
  class,
  const,
  dot,
  export,
  extends,
  field,
  finally,
  fn,
  for,
  generic,
  idx,
  if',
  import',
  inc,
  infix,
  interface,
  let',
  method,
  namespace,
  new,
  not,
  number,
  obj,
  process,
  prop,
  readonly,
  return,
  return',
  rows,
  shape,
  str,
  string,
  sub,
  ternary,
  this,
  tpl,
  try,
  typed,
  undefined,
  union,
  void,
  ...
}: ({
  fs,
  os,
  path,
  DIR,
  CHUNK,
  NODE,
  PLACEHOLDER,
  EMPTY_VIEW,
  Entry,
  Message,
  NodeLine,
  ViewState,
  Store,
  open,
  STORE,
  chunkPath,
  line,
  bytes,
  flat,
  key,
  when,
  writeAtomic,
  readState,
  readView,
  Tail,
  Messages,
}: [
  (import' (namespace fs) (str "node:fs"))
  (import' (namespace os) (str "node:os"))
  (import' (namespace path) (str "node:path"))
  blank
  (export (const DIR (infix [(dot process "env.OPTCHAT_DIR") "||" (call (dot path "join") [(call (dot os "homedir") []) (str ".local/state/optchat")])])))
  (export (const CHUNK 1024))
  (export (const NODE 512))
  (export (const PLACEHOLDER (str "(not summarized yet: zoom it)")))
  (export (const EMPTY_VIEW (str "<chat>\\n</chat>")))
  blank
  (export (interface Entry [
    (typed "kind" string)
    (typed "text" string)
    (typed "time" number)
    (typed "name" string)
  ]))
  blank
  (export (interface (extends Message Entry) [
    (typed "i" number)
    (typed "session" string)
    (typed "src" number)
  ]))
  blank
  (export (interface NodeLine [
    (typed "l" number)
    (typed "i" number)
    (typed "text" string)
  ]))
  blank
  (export (interface ViewState [
    (typed "messages" number)
    (typed "levels" (arrayOf number))
    (typed "seen" (generic Record [string number]))
    (typed "built" boolean)
  ]))
  blank
  (export (interface Store [
    (typed "dir" string)
    (typed "log" string)
    (typed "main" string)
    (typed "tree" string)
    (typed "view" string)
    (typed "viewText" string)
    (typed "spend" string)
  ]))
  blank
  (export ({dir}: (fn open (typed [(typed dir string)] Store) [
    (return (obj (rows [
      dir
      (prop "log" (call (dot path "join") [dir (str "log")]))
      (prop "main" (call (dot path "join") [dir (str "main")]))
      (prop "tree" (call (dot path "join") [dir (str "tree.jsonl")]))
      (prop "view" (call (dot path "join") [dir (str "view.json")]))
      (prop "viewText" (call (dot path "join") [dir (str "view.txt")]))
      (prop "spend" (call (dot path "join") [dir (str "spend.jsonl")]))
    ])))
  ])))
  blank
  (export (const STORE (call open [DIR])))
  blank
  (export (const chunkPath ({
    store,
    k,
  }: (arrow [(typed store Store) (typed k number)] (call (dot path "join") [(dot store "main") (tpl [(sub (call (dot (call String [k]) "padStart") [6 (str "0")])) ".jsonl"])])))))
  (export (const line ({m}: (arrow [(typed m Entry)] (tpl [(sub (dot m "kind")) "[" (sub (dot m "name")) "]: " (sub (dot m "text"))])))))
  (export (const bytes ({text}: (arrow [(typed text string)] (call (dot Buffer "byteLength") [text (str "utf8")])))))
  (export (const flat ({text}: (arrow [(typed text string)] (call (dot text "replaceAll") [(str "\\n") (str " ")])))))
  (export (const key ({
    l,
    i,
  }: (arrow [(typed l number) (typed i number)] (tpl [(sub l) "," (sub i)])))))
  blank
  (export ({
    time,
    date,
    pad,
    weekday,
    zone,
  }: (fn when (typed [(typed time number)] string) [
    (const date (new Date [time]))
    (const pad ({n}: (arrow [(typed n number)] (call (dot (call String [n]) "padStart") [2 (str "0")]))))
    (const weekday (call (dot date "toLocaleDateString") [(str "en-US") (obj [(prop "weekday" (str "long"))])]))
    (const zone (dot (call (dot (call (dot Intl "DateTimeFormat") []) "resolvedOptions") []) "timeZone"))
    (return (tpl [(sub weekday) " " (sub (call (dot date "getFullYear") [])) "-" (sub (call pad [(infix [(call (dot date "getMonth") []) "+" 1])])) "-" (sub (call pad [(call (dot date "getDate") [])])) " " (sub (call pad [(call (dot date "getHours") [])])) ":" (sub (call pad [(call (dot date "getMinutes") [])])) ":" (sub (call pad [(call (dot date "getSeconds") [])])) " " (sub zone)]))
  ])))
  blank
  (export ({
    file,
    text,
    temp,
  }: (fn writeAtomic (typed [(typed file string) (typed text string)] void) [
    (const temp (tpl [(sub file) "." (sub (dot process "pid")) ".tmp"]))
    (call (dot fs "writeFileSync") [temp text])
    (call (dot fs "renameSync") [temp file])
  ])))
  blank
  (export ({store}: (fn readState (typed [(typed store Store)] (union [ViewState undefined])) [
    (try [
        (return (infix [(call (dot JSON "parse") [(call (dot fs "readFileSync") [(dot store "view") (str "utf8")])]) "as" ViewState]))
      ] [
        (catch null [
          (return undefined)
        ])
      ])
  ])))
  blank
  (export ({store}: (fn readView (typed [(typed store Store)] string) [
    (try [
        (return (call (dot fs "readFileSync") [(dot store "viewText") (str "utf8")]))
      ] [
        (catch null [
          (return EMPTY_VIEW)
        ])
      ])
  ])))
  blank
  (export (class Tail [
    (field "offset" 0)
    blank
    ({file}: (method "constructor" [(readonly (typed file string))] []))
    blank
    ({fd}: (method "read" (typed [] (arrayOf string)) [
      (let' (typed fd number) null)
      (try [
          (infix [fd "=" (call (dot fs "openSync") [(dot this "file") (str "r")])])
        ] [
          (catch null [
            (return (array []))
          ])
        ])
      (try ({
          size,
          buffer,
          got,
          end,
        }: [
          (const size (dot (call (dot fs "fstatSync") [fd]) "size"))
          (if' (infix [size "<=" (dot this "offset")]) (return (array [])))
          (const buffer (call (dot Buffer "alloc") [(infix [size "-" (dot this "offset")])]))
          (const got (call (dot fs "readSync") [fd buffer 0 (dot buffer "length") (dot this "offset")]))
          (const end (call (dot (call (dot buffer "subarray") [0 got]) "lastIndexOf") [10]))
          (if' (infix [end "<" 0]) (return (array [])))
          (infix [(dot this "offset") "+=" end "+" 1])
          (return (call (dot (call (dot (call (dot buffer "subarray") [0 end]) "toString") [(str "utf8")]) "split") [(str "\\n")]))
        ]) [
          (finally [
            (call (dot fs "closeSync") [fd])
          ])
        ])
    ]))
    blank
    ({
      lines,
      data,
      at,
    }: (method "skip" (typed [(typed lines number)] void) [
      (let' (typed data Buffer) null)
      (try [
          (infix [data "=" (call (dot fs "readFileSync") [(dot this "file")])])
        ] [
          (catch null [
            return'
          ])
        ])
      (let' at 0)
      ({
        n,
        next,
      }: (for (let' n 0) (infix [n "<" lines]) (inc n) [
        (const next (call (dot data "indexOf") [10 at]))
        (if' (infix [next "<" 0]) break)
        (infix [at "=" next "+" 1])
      ]))
      (infix [(dot this "offset") "=" at])
    ]))
  ]))
  blank
  (export (class Messages [
    (field "#cache" (new (generic Map [number (shape [(typed "size" number) (typed "rows" (arrayOf string))])]) []))
    blank
    ({store}: (method "constructor" [(readonly (typed store Store))] []))
    blank
    ({
      i,
      k,
      file,
      size,
      chunk,
      row,
      message,
    }: (method "get" (typed [(typed i number)] (union [Message undefined])) [
      (const k (call (dot Math "floor") [(infix [i "/" CHUNK])]))
      (const file (call chunkPath [(dot this "store") k]))
      (let' (typed size number) null)
      (try [
          (infix [size "=" (dot (call (dot fs "statSync") [file]) "size")])
        ] [
          (catch null [
            (return undefined)
          ])
        ])
      (let' chunk (call (dot this "#cache.get") [k]))
      (if' (infix [(dot chunk "?.size") "!==" size]) [
        (infix [chunk "=" (obj [size (prop "rows" (call (dot (call (dot fs "readFileSync") [file (str "utf8")]) "split") [(str "\\n")]))])])
        (call (dot this "#cache.set") [k chunk])
      ])
      (const row (idx (dot chunk "rows") (infix [i "%" CHUNK])))
      (if' (not row) (return undefined))
      (const message (infix [(call (dot JSON "parse") [row]) "as" Message]))
      (return (ternary (infix [(dot message "i") "===" i]) message undefined))
    ]))
  ]))
])
