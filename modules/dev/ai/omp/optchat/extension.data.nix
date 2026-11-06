{
  Array,
  Boolean,
  Buffer,
  Date,
  Error,
  Extract,
  JSON,
  Map,
  Math,
  Number,
  Set,
  array,
  arrayOf,
  arrow,
  async,
  below,
  blank,
  boolean,
  break,
  call,
  catch,
  chain,
  class,
  const,
  const',
  continue,
  dec,
  default,
  dot,
  export,
  extends,
  field,
  fn,
  for,
  forOf,
  generic,
  idx,
  if',
  import',
  inc,
  infix,
  interface,
  is,
  let',
  method,
  namespace,
  new,
  not,
  null',
  num,
  number,
  obj,
  opt,
  optIdx,
  process,
  prop,
  readonly,
  regex,
  return,
  return',
  rows,
  shape,
  spread,
  str,
  string,
  sub,
  ternary,
  this,
  throw',
  tpl,
  try,
  typeOnly,
  typed,
  typeof,
  undefined,
  union,
  unknown,
  void,
  while,
  ...
}: ({
  ExtensionAPI,
  ExtensionContext,
  fs,
  path,
  Entry,
  Messages,
  PLACEHOLDER,
  STORE,
  Store,
  Tail,
  bytes,
  flat,
  key,
  line,
  open,
  readState,
  readView,
  when,
  PIN,
  CAP,
  RECENT,
  ROW,
  BOT,
  RULES,
  BOTS,
  RAW,
  IMAGE,
  INTRO,
  BOT_INTRO,
  RULES_INTRO,
  Pin,
  Snapshot,
  Block,
  Logged,
  joinText,
  capText,
  askText,
  entriesOf,
  chatName,
  pins,
  take,
  recent,
  rowsOf,
  countLines,
  rules,
  sized,
  blocks,
  turnStart,
  turnMark,
  tokensOf,
  Reader,
  optchat,
}: [
  (import' (typeOnly [ExtensionAPI ExtensionContext]) (str "@oh-my-pi/pi-coding-agent"))
  (import' (namespace fs) (str "node:fs"))
  (import' (namespace path) (str "node:path"))
  (import' (rows [
    (typeOnly Entry)
    Messages
    PLACEHOLDER
    STORE
    (typeOnly Store)
    Tail
    bytes
    flat
    key
    line
    open
    readState
    readView
    when
  ]) (str "./store.ts"))
  blank
  (const PIN (str "optchat-pin"))
  (const CAP (num "30_000"))
  (const RECENT (num "64_000"))
  (const ROW (regex "^(\\d+)\\+(\\d+)\\|" ""))
  (const BOT (dot process "env.OPTCHAT_BOT"))
  (const RULES (dot process "env.OPTCHAT_RULES"))
  (const BOTS (dot process "env.OPTCHAT_BOTS"))
  (const RAW (infix [(call Number [(dot process "env.OPTCHAT_RAW")]) "||" (num "128_000")]))
  (const IMAGE (num "4_800"))
  blank
  (const INTRO (tpl [
    ''
      # Shared memory

      Every omp chat on this computer, on the host and in the box, logs the
      user's messages and the agent's replies into one shared memory. Below is
      its view, taken when this chat started or was last compacted: everything
      logged before then, oldest first, inside <chat> tags, as one-line
      summaries. Each line is

        id+n|text   the n messages from id on, summarized (newlines shown as spaces)

      Each item is tagged with its kind and, in brackets, the chat it came from,
      as talk[Chat]: user (the user's words in that chat), work (text an agent
      or tool sent in the user's place), talk (the agent's replies). Tool calls
      and their results are not logged, so say in your replies what you learned
      that will matter later. Recent lines cover one message each; the older
      the messages, the more a line covers. A message not summarized yet shows
      as "''
    (sub PLACEHOLDER)
    ''
      ". Read other chats' lines as what else is
      going on and answer only this chat's messages; this chat's own turns
      follow in full, or as omp's summary once it has compacted them.

      The zoom, date and recent tools read the memory. zoom(id, n) opens line
      id+n into the two lines of n/2 messages it was made from; zoom(id, 1)
      gives message id in full. Zoom whenever a summary only mentions something
      you need, such as a decision, a past attempt or where a file is, before
      you act, guess or ask. date(id) gives the date and time of message id.
      recent() shows what every chat logged after this view was taken.''
  ]))
  blank
  (const BOT_INTRO (tpl [
    ''
      # Your memory

      Your conversation lives in OptChat memory, not in this context. Every
      message you receive (the user typing live, background tasks, answers
      from other bots) and every reply you write is logged into it. Below is
      its view: everything logged before your latest turns, oldest first,
      inside <chat> tags, as one-line summaries. Each line is

        id+n|text   the n messages from id on, summarized (newlines shown as spaces)

      Each item is tagged with its kind: user (what you received), work (text
      a tool sent in the user's place), talk (your replies). Recent lines
      cover one message each; the older the messages, the more a line covers.
      A message not summarized yet shows as "''
    (sub PLACEHOLDER)
    ''
      ". Your latest
      turns follow in full, tool calls and results included; older turns exist
      only as these lines, and their tool calls and results are gone, so say in
      your replies what you learned that will matter later.

      The zoom, date and recent tools read the memory. zoom(id, n) opens line
      id+n into the two lines of n/2 messages it was made from; zoom(id, 1)
      gives message id in full. Zoom whenever a summary only mentions something
      you need, such as a decision, a past attempt or where a file is, before
      you act, guess or ask. date(id) gives the date and time of message id.
      recent() shows what was logged after this view was taken. Give any of
      them a bot name to read that bot's memory instead, read-only; memories()
      lists the bots that keep one.''
  ]))
  blank
  (const RULES_INTRO (tpl [
    ''
      # Standing rules

      The rules the user set you, kept word for word and never summarized.
      They hold until the user changes them. When the user sets you a new
      standing rule, pin_rule adds it here.''
  ]))
  blank
  blank
  (interface Pin [
    (typed "view" string)
    (typed "upto" number)
    (typed "time" number)
  ])
  blank
  (interface (extends Snapshot Pin) [
    (typed "anchor" number)
    (typed "turn" number)
  ])
  blank
  (interface Block [
    (typed "type" string)
    (typed (opt "text") string)
  ])
  blank
  (interface Logged [
    (typed "role" string)
    (typed (opt "content") unknown)
    (typed (opt "attribution") string)
    (typed (opt "stopReason") string)
    (typed (opt "toolName") string)
    (typed (opt "details") (shape [(typed (opt "question") unknown)]))
    (typed (opt "usage") (shape [(typed (opt "totalTokens") number)]))
    (typed (opt "timestamp") number)
  ])
  blank
  ({content}: (fn joinText (typed [(typed content unknown)] string) [
    (if' (infix [(typeof content) "===" (str "string")]) (return content))
    (if' (not (call (dot Array "isArray") [content])) (return (str "")))
    (return (chain (call (dot (call (dot (call (dot content "map") [({block}: (arrow [(typed block Block)] (ternary (infix [(dot block "?.type") "===" (str "text")]) (infix [(dot block "text") "??" (str "")]) (ternary (infix [(dot block "?.type") "===" (str "image")]) (str "[image]") (str "")))))]) "filter") [Boolean]) "join") [(str "\\n")])))
  ]))
  blank
  ({
    text,
    chars,
    half,
  }: (fn capText (typed [(typed text string)] string) [
    (const chars (array [(spread text)]))
    (if' (infix [(dot chars "length") "<=" CAP]) (return text))
    (const half (infix [CAP "/" 2]))
    (return (tpl [(sub (call (dot (call (dot chars "slice") [0 half]) "join") [(str "")])) "\\n\\n[" (sub (infix [(dot chars "length") "-" CAP])) " characters cut]\\n\\n" (sub (call (dot (call (dot chars "slice") [(infix [(dot chars "length") "-" half])]) "join") [(str "")]))]))
  ]))
  blank
  ({
    message,
    answer,
    question,
  }: (fn askText (typed [(typed message Logged)] string) [
    (if' (infix [(dot message "role") "!==" (str "toolResult") "||" (dot message "toolName") "!==" (str "ask")]) (return (str "")))
    (const answer (call (dot (call joinText [(dot message "content")]) "trim") []))
    (const question (dot message "details?.question"))
    (return (ternary (infix [answer "&&" (typeof question) "===" (str "string")]) (tpl ["Asked: " (sub question) "\\n" (sub answer)]) answer))
  ]))
  blank
  ({
    message,
    answer,
  }: (fn entriesOf (typed [(typed message Logged)] (arrayOf (shape [(typed "kind" string) (typed "text" string)]))) [
    (if' (infix [(dot message "role") "===" (str "user")]) ({text}: [
      (const text (call (dot (call joinText [(dot message "content")]) "trim") []))
      (return (ternary text (array [(obj [(prop "kind" (ternary (infix [(dot message "attribution") "===" (str "agent")]) (str "work") (str "user"))) text])]) (array [])))
    ]))
    (if' (infix [(dot message "role") "===" (str "assistant") "&&" (dot message "stopReason") "!==" (str "error") "&&" (dot message "stopReason") "!==" (str "aborted")]) ({
      content,
      text,
    }: [
      (const content (ternary (call (dot Array "isArray") [(dot message "content")]) (infix [(dot message "content") "as" (arrayOf Block)]) (array [])))
      (const text (chain (call (dot (call (dot (call (dot (call (dot content "filter") [({block}: (arrow [block] (infix [(dot block "type") "===" (str "text")])))]) "map") [({block}: (arrow [block] (infix [(dot block "text") "??" (str "")])))]) "join") [(str "\\n\\n")]) "trim") [])))
      (return (ternary text (array [(obj [(prop "kind" (str "talk")) text])]) (array [])))
    ]))
    (const answer (call askText [message]))
    (return (ternary answer (array [(obj [(prop "kind" (str "user")) (prop "text" answer)])]) (array [])))
  ]))
  blank
  ({
    title,
    session,
    plain,
    code,
  }: (fn chatName (typed [(typed title (union [string undefined])) (typed session string)] string) [
    (const plain (call (dot (call (dot (infix [title "??" (str "")]) "replace") [(regex "[^\\x20-\\x7e]" "g") (str "")]) "trim") []))
    (const code (optIdx (call (dot (regex "^([A-Z0-9][A-Z0-9_-]{1,11}):\\s" "") "exec") [plain]) 1))
    (if' code (return code))
    (if' plain (return (call (dot (call (dot plain "slice") [0 32]) "trimEnd") [])))
    (return (tpl ["chat " (sub (call (dot session "slice") [(-6)]))]))
  ]))
  blank
  ({ctx}: (fn pins (typed [(typed ctx ExtensionContext)] (arrayOf Pin)) [
    (return (chain (call (dot (call (dot (call (dot (call (dot ctx "sessionManager.getBranch") []) "filter") [({entry}: (arrow [entry] (infix [(dot entry "type") "===" (str "custom") "&&" (dot entry "customType") "===" PIN])))]) "map") [({entry}: (arrow [entry] (dot (infix [entry "as" (shape [(typed (opt "data") Pin)])]) "data")))]) "filter") [({pin}: (arrow (typed [pin] (is pin Pin)) (infix [(typeof (dot pin "?.view")) "===" (str "string") "&&" (typeof (dot pin "upto")) "===" (str "number")])))])))
  ]))
  blank
  (fn take (typed [] Pin) [
    (return (obj [(prop "view" (call readView [STORE])) (prop "upto" (infix [(dot (call readState [STORE]) "?.messages") "??" 0])) (prop "time" (call (dot Date "now") []))]))
  ])
  blank
  ({
    store,
    since,
    empty,
    rows',
    kept,
    size,
  }: (fn recent (typed [(typed store Store) (typed since number) (typed empty string)] string) [
    (const rows' (chain (call (dot (call (dot (call readView [store]) "split") [(str "\\n")]) "filter") [
      ({
        row,
        match,
      }: (arrow [row] [
        (const match (call (dot ROW "exec") [row]))
        (return (infix [match "!==" null' "&&" (call Number [(idx match 1)]) "+" (call Number [(idx match 2)]) ">" since]))
      ]))
    ])))
    (if' (not (dot rows' "length")) (return empty))
    (const (typed kept (arrayOf string)) (array []))
    (let' size 0)
    ({k}: (for (let' k (infix [(dot rows' "length") "-" 1])) (infix [k ">=" 0 "&&" size "<" RECENT]) (dec k) [
      (call (dot kept "unshift") [(idx rows' k)])
      (infix [size "+=" (call bytes [(idx rows' k)]) "+" 1])
    ]))
    (return (tpl ["<chat>\\n" (sub (call (dot kept "join") [(str "\\n")])) "\\n</chat>"]))
  ]))
  blank
  ({
    message,
    name,
    time,
  }: (fn rowsOf (typed [(typed message Logged) (typed name string)] (arrayOf string)) [
    (const time (ternary (infix [(typeof (dot message "timestamp")) "===" (str "number")]) (dot message "timestamp") (call (dot Date "now") [])))
    (return (call (dot (call entriesOf [message]) "map") (rows [
      ({
        kind,
        text,
      }: (arrow [(obj [kind text])] (tpl [(sub (call (dot JSON "stringify") [(infix [(obj [kind (prop "text" (call capText [text])) time name]) "satisfies" Entry])])) "\\n"])))
    ])))
  ]))
  blank
  ({
    file,
    data,
    n,
  }: (fn countLines (typed [(typed file string)] number) [
    (let' (typed data Buffer) null)
    (try [
        (infix [data "=" (call (dot fs "readFileSync") [file])])
      ] [
        (catch null [
          (return 0)
        ])
      ])
    (let' n 0)
    ({at}: (for (let' at (call (dot data "indexOf") [10])) (infix [at ">=" 0]) (infix [at "=" (call (dot data "indexOf") [10 (infix [at "+" 1])])]) (inc n)))
    (return n)
  ]))
  blank
  ({text}: (fn rules (typed [] string) [
    (let' text (str ""))
    (try [
      (infix [text "=" (call (dot (call (dot fs "readFileSync") [(infix [RULES "as" string]) (str "utf8")]) "trim") [])])
    ] [(catch null [])])
    (return (tpl [(sub RULES_INTRO) "\\n\\n<rules>\\n" (sub (infix [text "||" (str "None yet.")])) "\\n</rules>"]))
  ]))
  blank
  ({
    message,
    images,
    json,
  }: (fn sized (typed [(typed message unknown)] number) [
    (let' images 0)
    (const json (call (dot JSON "stringify") [
      message
      ({
        _key,
        value,
      }: (arrow [_key value] [
        (if' (infix [(dot value "?.type") "!==" (str "image") "||" (typeof (dot value "data")) "!==" (str "string")]) (return value))
        (inc images)
        (return undefined)
      ]))
    ]))
    (return (infix [(call bytes [json]) "+" images "*" IMAGE]))
  ]))
  blank
  (const blocks ({content}: (arrow [(typed content unknown)] (ternary (infix [(typeof content) "===" (str "string")]) (array [(obj [(prop "type" (str "text")) (prop "text" content)])]) (infix [content "as" (arrayOf Block)])))))
  blank
  (const turnStart ({messages}: (arrow [(typed messages (arrayOf Logged))] (call (dot messages "findLastIndex") [({message}: (arrow [message] (infix [(dot message "role") "===" (str "user")])))]))))
  blank
  ({
    messages,
    turn,
  }: (fn turnMark (typed [(typed messages (arrayOf Logged))] number) [
    (const turn (call turnStart [messages]))
    (return (ternary (infix [turn "<" 0]) 0 (infix [(dot (idx messages turn) "timestamp") "??" 0])))
  ]))
  blank
  (const tokensOf ({message}: (arrow [(typed message unknown)] (call (dot Math "ceil") [(infix [(call sized [message]) "/" 4])]))))
  blank
  (class Reader [
    (readonly (typed "messages" Messages))
    (readonly (typed "tree" Tail))
    (readonly (field "nodes" (new (generic Map [string string]) [])))
    blank
    ({store}: (method "constructor" [(readonly (typed store Store))] [
      (infix [(dot this "messages") "=" (new Messages [store])])
      (infix [(dot this "tree") "=" (new Tail [(dot store "tree")])])
    ]))
    blank
    ({
      l,
      i,
    }: (method "node" (typed [(typed l number) (typed i number)] (union [string undefined])) [
      ({row}: (forOf row (call (dot this "tree.read") []) [
        (if' (not row) continue)
        (try ({parsed}: [
          (const parsed (infix [(call (dot JSON "parse") [row]) "as" (shape [(typed "l" number) (typed "i" number) (typed "text" string)])]))
          (call (dot this "nodes.set") [(call key [(dot parsed "l") (dot parsed "i")]) (dot parsed "text")])
        ]) [(catch null [])])
      ]))
      (return (call (dot this "nodes.get") [(call key [l i])]))
    ]))
    blank
    ({
      id,
      n,
      total,
      half,
      l,
    }: (method "zoom" (typed [(typed id number) (typed n number)] string) [
      (const total (infix [(dot (call readState [(dot this "store")]) "?.messages") "??" 0]))
      (if' (below (infix (rows [
          (not (call (dot Number "isSafeInteger") [id]))
          "||"
          (not (call (dot Number "isSafeInteger") [n]))
          "||"
          n
          "<"
          1
          "||"
          n
          ">"
          2
          "**"
          30
          "||"
          [n "&" n "-" 1]
          "!=="
          0
          "||"
          id
          "<"
          0
          "||"
          id
          "%"
          n
          "!=="
          0
          "||"
          id
          "+"
          n
          ">"
          total
        ]))) [
          (return (tpl ["No line " (sub id) "+" (sub n) "."]))
        ])
      (if' (infix [n "===" 1]) ({message}: [
        (const message (call (dot this "messages.get") [id]))
        (return (ternary message (tpl [(sub id) "+1|" (sub (call line [message]))]) (tpl ["No message " (sub id) "."])))
      ]))
      (const half (infix [n "/" 2]))
      (const l (call (dot Math "log2") [half]))
      (return (call (dot (call (dot (array [id (infix [id "+" half])]) "map") [({at}: (arrow [at] (tpl [(sub at) "+" (sub half) "|" (sub (call flat [(infix [(call (dot this "node") [l (infix [at "/" half])]) "??" PLACEHOLDER])]))])))]) "join") [(str "\\n")]))
    ]))
    blank
    ({
      id,
      message,
    }: (method "date" (typed [(typed id number)] string) [
      (const message (call (dot this "messages.get") [id]))
      (return (ternary message (call when [(dot message "time")]) (tpl ["No message " (sub id) "."])))
    ]))
  ])
  blank
  (export (default ({
    pi,
    z,
    own,
    readers,
    enabled,
    snap,
    saved,
    active,
    result,
    which,
    whose,
    reader,
    read,
    backfill,
    stored,
    repin,
    window,
    frame,
    tokens,
    bot,
    start,
  }: (fn optchat (typed [(typed pi ExtensionAPI)] void) [
    (const z (dot pi "zod"))
    (const own (new Reader [STORE]))
    (const readers (new (generic Map [string Reader]) []))
    (let' enabled false)
    (let' (typed snap (union [Snapshot undefined])) null)
    (const saved (new (generic Set [number]) []))
    blank
    (const active ({ctx}: (arrow [(typed ctx ExtensionContext)] (infix [enabled "&&" (dot ctx "agent?.kind") "===" (str "main")]))))
    (const result ({text}: (arrow [(typed text string)] (obj [(prop "content" (array [(obj [(prop "type" (infix [(str "text") "as" const'])) text])]))]))))
    (const which (ternary BOTS (obj [(prop "bot" (call (dot (call (dot z "string") []) "optional") []))]) (obj [])))
    (const whose (ternary BOTS (str "; with bot, that bot's memory, read-only") (str "")))
    blank
    ({
      bot,
      dir,
      found,
    }: (fn reader (typed [(typed bot (union [string undefined]))] (union [Reader string])) [
      (if' (infix [(not bot) "||" bot "===" BOT]) (return own))
      (const dir (ternary (infix [BOTS "&&" (not (call (dot bot "startsWith") [(str ".")])) "&&" (not (call (dot bot "includes") [(str "/")]))]) (call (dot path "join") [BOTS bot (str "optchat")]) undefined))
      (if' (infix [dir "===" undefined "||" (not (call (dot fs "existsSync") [(call (dot path "join") [dir (str "view.json")])]))]) (return (tpl ["No bot named " (sub bot) " keeps a memory."])))
      (let' found (call (dot readers "get") [dir]))
      (if' (infix [found "===" undefined]) [
        (infix [found "=" (new Reader [(call open [dir])])])
        (call (dot readers "set") [dir found])
      ])
      (return found)
    ]))
    blank
    ({
      bot,
      run,
      memory,
    }: (fn read [(typed bot (union [string undefined])) (typed run ({memory}: (arrow [(typed memory Reader)] string)))] [
      (const memory (call reader [bot]))
      (return (call result [(ternary (infix [(typeof memory) "===" (str "string")]) memory (call run [memory]))]))
    ]))
    blank
    (call (dot pi "registerTool") [
      (obj (rows [
        (prop "name" (str "zoom"))
        (prop "label" (str "Zoom memory"))
        (prop "description" (tpl ["Open the line id+n of the memory view into the two lines of n/2 messages under it; n = 1 gives message id whole" (sub whose) "."]))
        (prop "parameters" (call (dot z "object") [(obj [(prop "id" (call (dot z "number") [])) (prop "n" (call (dot z "number") [])) (spread which)])]))
        (async ({
          _toolCallId,
          params,
        }: (method "execute" [_toolCallId params] [
          (return (call read [(dot (infix [params "as" (shape [(typed (opt "bot") string)])]) "bot") ({memory}: (arrow [memory] (call (dot memory "zoom") [(dot params "id") (dot params "n")])))]))
        ])))
      ]))
    ])
    (call (dot pi "registerTool") [
      (obj (rows [
        (prop "name" (str "date"))
        (prop "label" (str "Memory date"))
        (prop "description" (tpl ["The date and time of memory message id" (sub whose) "."]))
        (prop "parameters" (call (dot z "object") [(obj [(prop "id" (call (dot z "number") [])) (spread which)])]))
        (async ({
          _toolCallId,
          params,
        }: (method "execute" [_toolCallId params] [
          (return (call read [(dot (infix [params "as" (shape [(typed (opt "bot") string)])]) "bot") ({memory}: (arrow [memory] (call (dot memory "date") [(dot params "id")])))]))
        ])))
      ]))
    ])
    (call (dot pi "registerTool") [
      (obj (rows [
        (prop "name" (str "recent"))
        (prop "label" (str "Recent memory"))
        (prop "description" (tpl ["The memory lines logged after this chat's view was taken" (sub (ternary BOTS (str "; with bot, that bot's latest lines, read-only") (str ""))) "."]))
        (prop "parameters" (call (dot z "object") [(obj [(spread which)])]))
        (async ({
          _toolCallId,
          params,
          _signal,
          _onUpdate,
          ctx,
          bot,
        }: (method "execute" [_toolCallId params _signal _onUpdate ctx] [
          (const bot (dot (infix [params "as" (shape [(typed (opt "bot") string)])]) "bot"))
          (return (call read [bot ({memory}: (arrow [memory] (below (ternary (infix [memory "===" own]) (below (call recent [(dot own "store") (ternary BOT (infix [(dot snap "?.upto") "??" 0]) (infix [(dot (call (dot (call pins [ctx]) "at") [(-1)]) "?.upto") "??" 0])) (str "Nothing was logged after this chat's view was taken.")])) (below (call recent [(dot memory "store") 0 (tpl [(sub bot) " has logged nothing yet."])]))))))]))
        ])))
      ]))
    ])
    (if' BOTS [
      (call (dot pi "registerTool") [
        (obj (rows [
          (prop "name" (str "memories"))
          (prop "label" (str "Bot memories"))
          (prop "description" (str "The bots that keep a memory, with how many messages each holds; pass a name as bot to zoom, date or recent."))
          (prop "parameters" (call (dot z "object") [(obj [])]))
          (async ({
            rows',
            names,
          }: (method "execute" [] [
            (const (typed rows' (arrayOf string)) (array []))
            (let' (typed names (arrayOf string)) (array []))
            (try [
              (infix [names "=" (call (dot (call (dot fs "readdirSync") [BOTS]) "sort") [])])
            ] [(catch null [])])
            ({
              name,
              state,
            }: (forOf name names [
              (const state (call readState [(call open [(call (dot path "join") [BOTS name (str "optchat")])])]))
              (if' (infix [state "!==" undefined]) (call (dot rows' "push") [(tpl [(sub name) ": " (sub (dot state "messages")) " messages" (sub (ternary (infix [name "===" BOT]) (str " (you)") (str "")))])]))
            ]))
            (return (call result [(ternary (dot rows' "length") (call (dot rows' "join") [(str "\\n")]) (str "No bot keeps a memory yet."))]))
          ])))
        ]))
      ])
    ])
    (if' (infix [BOT "&&" RULES]) [
      (call (dot pi "registerTool") [
        (obj (rows [
          (prop "name" (str "pin_rule"))
          (prop "label" (str "Pin rule"))
          (prop "description" (below (str "Add a standing rule the user just set you to your pinned rules, in their words, so it stays in your context word for word and is never summarized. Only for rules the user gave.")))
          (prop "parameters" (call (dot z "object") [(obj [(prop "rule" (call (dot z "string") []))])]))
          (async ({
            _toolCallId,
            params,
            rule,
          }: (method "execute" [_toolCallId params] [
            (const rule (call (dot (call (dot params "rule.trim") []) "replace") [(regex "\\s*\\n\\s*" "g") (str " ")]))
            (if' (not rule) (return (call result [(str "No rule given.")])))
            (call (dot fs "mkdirSync") [(call (dot path "dirname") [RULES]) (obj [(prop "recursive" true)])])
            (call (dot fs "appendFileSync") [RULES (tpl ["- " (sub rule) "\\n"])])
            (return (call result [(tpl ["Pinned: " (sub rule)])]))
          ])))
        ]))
      ])
    ])
    blank
    ({
      ctx,
      file,
    }: (fn backfill (typed [(typed ctx ExtensionContext)] void) [
      (const file (call (dot path "join") [(dot STORE "log") (tpl [(sub (call (dot ctx "sessionManager.getSessionId") [])) ".jsonl"])]))
      (if' (not (call (dot fs "existsSync") [file])) ({rows'}: [
        (const rows' (chain (call (dot (call (dot ctx "sessionManager.getBranch") []) "flatMap") [({entry}: (arrow [entry] (ternary (infix [(dot entry "type") "===" (str "message")]) (call rowsOf [(infix [(dot entry "message") "as" Logged]) (infix [BOT "as" string])]) (array []))))])))
        (call (dot fs "writeFileSync") [file (call (dot rows' "join") [(str "")])])
      ]))
      (call (dot saved "clear") [])
      ({row}: (forOf row (call (dot (call (dot fs "readFileSync") [file (str "utf8")]) "split") [(str "\\n")]) [
        (try [
          (call (dot saved "add") [(dot (infix [(call (dot JSON "parse") [row]) "as" Entry]) "time")])
        ] [(catch null [])])
      ]))
    ]))
    blank
    ({message}: (fn stored (typed [(typed message Logged)] boolean) [
      (return (infix [(dot (call entriesOf [message]) "length") ">" 0 "&&" [(typeof (dot message "timestamp")) "!==" (str "number") "||" (call (dot saved "has") [(dot message "timestamp")])]]))
    ]))
    blank
    ({
      messages,
      session,
      floor,
      state,
      view,
      rows',
      last,
      match,
      upto,
      lag,
      pick,
      pickNeed,
      pickLogged,
      need,
      logged,
      size,
      cut,
      kept,
      turn,
    }: (fn repin (typed [(typed messages (arrayOf Logged)) (typed session string) (typed floor number)] number) [
      (const state (call readState [STORE]))
      (const view (call readView [STORE]))
      (const rows' (call (dot view "split") [(str "\\n")]))
      (const last (call (dot rows' "findLast") [({row}: (arrow [row] (call (dot ROW "test") [row])))]))
      (const match (ternary (infix [last "===" undefined]) null' (call (dot ROW "exec") [last])))
      (const upto (ternary (infix [match "===" null']) 0 (infix [(call Number [(idx match 1)]) "+" (call Number [(idx match 2)])])))
      (const lag (call (dot Math "max") [0 (infix [(call countLines [(call (dot path "join") [(dot STORE "log") (tpl [(sub session) ".jsonl"])])]) "-" [(optIdx (dot state "?.seen") session) "??" 0]])]))
      (let' pick (-1))
      (let' pickNeed 0)
      (let' pickLogged 0)
      (let' need lag)
      (let' logged 0)
      (let' size 0)
      (const turn (call turnStart [messages]))
      ({k}: (for (let' k (infix [(dot messages "length") "-" 1])) (infix [k ">=" floor]) (dec k) [
        (infix [size "+=" (call sized [(idx messages k)])])
        (if' (call stored [(idx messages k)]) [
          (dec need)
          (inc logged)
        ])
        (if' (infix [(dot (idx messages k) "role") "===" (str "toolResult")]) continue)
        (if' (infix [pick ">=" 0 "&&" pickNeed "<=" 0 "&&" k "<" turn "&&" size ">" RAW "/" 2]) break)
        (infix [pick "=" k])
        (infix [pickNeed "=" need])
        (infix [pickLogged "=" logged])
      ]))
      (let' cut upto)
      ({left}: (for (let' left (infix [pickLogged "-" lag])) (infix [left ">" 0 "&&" cut ">" 0 "&&" (dot (call (dot own "messages.get") [(infix [cut "-" 1])]) "?.session") "===" session]) (dec left) (dec cut)))
      (const kept (call (dot rows' "filter") [
        ({
          row,
          at,
        }: (arrow [row] [
          (const at (call (dot ROW "exec") [row]))
          (return (infix [at "===" null' "||" (call Number [(idx at 1)]) "<" cut]))
        ]))
      ]))
      (infix [snap "=" (obj [(prop "view" (call (dot kept "join") [(str "\\n")])) upto (prop "time" (call (dot Date "now") [])) (prop "anchor" (ternary (infix [pick "<" 0]) 0 (infix [(dot (idx messages pick) "timestamp") "??" 0]))) (prop "turn" (call turnMark [messages]))])])
      (return (ternary (infix [pick "<" 0]) 0 pick))
    ]))
    blank
    ({
      messages,
      at,
      mark,
    }: (fn window (typed [(typed messages (arrayOf Logged))] number) [
      (if' (infix [snap "===" undefined]) (return (-1)))
      (let' at (dot messages "length"))
      (while (infix [at ">" 0 "&&" [(dot (idx messages (infix [at "-" 1])) "timestamp") "??" 0] ">=" (dot snap "anchor")]) (dec at))
      (while (infix [at "<" (dot messages "length") "&&" (dot (idx messages at) "role") "===" (str "toolResult")]) (inc at))
      (if' (infix [at "===" (dot messages "length")]) (return (-1)))
      (const mark (call turnMark [messages]))
      (if' (infix [mark "!==" (dot snap "turn") "&&" at "<" (call turnStart [messages])]) ({size}: [
        (let' size 0)
        ({k}: (for (let' k at) (infix [k "<" (dot messages "length")]) (inc k) (infix [size "+=" (call sized [(idx messages k)])])))
        (if' (infix [size ">" RAW]) (return (-1)))
      ]))
      (infix [(dot snap "turn") "=" mark])
      (return at)
    ]))
    blank
    ({
      messages,
      at,
      pinned,
      head,
      turn,
      recentTurns,
      first,
    }: (fn frame (typed [(typed messages (arrayOf Logged)) (typed at number)] (arrayOf Logged)) [
      (const pinned (infix [snap "as" Snapshot]))
      (const head (array (rows [
        (spread (ternary RULES (array [(obj [(prop "type" (str "text")) (prop "text" (call rules []))])]) (array [])))
        (obj [(prop "type" (str "text")) (prop "text" (tpl [(sub BOT_INTRO) "\\n\\n" (sub (dot pinned "view"))]))])
      ])))
      (const turn (call turnStart [messages]))
      (const recentTurns (call (dot messages "slice") [at]))
      (if' (infix [turn ">=" 0 "&&" turn "<" at]) ({asks}: [
        (const asks (chain (call (dot (call (dot (call (dot (call (dot messages "slice") [turn at]) "map") [askText]) "filter") [Boolean]) "map") [({text}: (arrow [text] (obj [(prop "type" (str "text")) text])))])))
        (call (dot recentTurns "unshift") [(obj [(spread (idx messages turn)) (prop "content" (array [(spread (call blocks [(dot (idx messages turn) "content")])) (spread asks)]))])])
      ]))
      (const first (idx recentTurns 0))
      (if' (infix [(dot first "?.role") "!==" (str "user")]) (return (array [(obj [(prop "role" (str "user")) (prop "content" head) (prop "timestamp" (dot pinned "time"))]) (spread recentTurns)])))
      (return (array [(obj [(spread first) (prop "content" (array [(spread head) (spread (call blocks [(dot first "content")]))]))]) (spread (call (dot recentTurns "slice") [1]))]))
    ]))
    blank
    ({
      out,
      system,
      total,
    }: (fn tokens (typed [(typed out (arrayOf Logged)) (typed system number)] number) [
      (let' total 0)
      ({
        k,
        used,
      }: (for (let' k (infix [(dot out "length") "-" 1])) (infix [k ">=" 0]) (dec k) [
        (const used (ternary (infix [(dot (idx out k) "role") "===" (str "assistant") "&&" [(dot (idx out k) "timestamp") "??" 0] ">" (dot (infix [snap "as" Snapshot]) "time")]) (infix [(dot (idx out k) "usage?.totalTokens") "??" 0]) 0))
        (if' (infix [used ">" 0]) (return (infix [total "+" used])))
        (infix [total "+=" (call tokensOf [(idx out k)])])
      ]))
      (return (infix [total "+" system]))
    ]))
    blank
    ({
      messages,
      session,
      ctx,
      at,
      span,
      limit,
      system,
      out,
      need,
      floor,
      fold,
      rest,
    }: (fn bot (typed [(typed messages (arrayOf Logged)) (typed session string) (typed ctx ExtensionContext)] (arrayOf Logged)) [
      (let' at (call window [messages]))
      (if' (infix [at "<" 0]) (infix [at "=" (call repin [messages session 0])]))
      (const span (infix [(dot ctx "model?.contextWindow") "??" 0]))
      (if' (infix [span "<=" 0]) (return (call frame [messages at])))
      (const limit (infix [span "-" (call (dot Math "min") [(infix [(dot ctx "model.maxTokens") "??" span]) (infix [span "/" 4])])]))
      (const system (call tokensOf [(infix [(call (dot ctx "getSystemPrompt") []) "??" (str "")])]))
      (let' out (call frame [messages at]))
      (let' need (call tokens [out system]))
      (if' (infix [need "<=" limit]) (return out))
      (const floor (call (dot Math "max") [at (call turnStart [messages])]))
      (let' fold (-1))
      (let' rest (infix [system "+" (call tokensOf [(idx (call frame [messages (dot messages "length")]) 0)])]))
      ({k}: (for (let' k (infix [(dot messages "length") "-" 1])) (infix [k ">" floor]) (dec k) [
        (infix [rest "+=" (call tokensOf [(idx messages k)])])
        (if' (infix [rest ">" limit]) break)
        (if' (infix [(dot (idx messages k) "role") "===" (str "assistant") "&&" [fold "<" 0 "||" rest "<=" limit "/" 2]]) (infix [fold "=" k]))
      ]))
      (if' (infix [fold ">=" 0]) [
        (infix [out "=" (call frame [messages (call repin [messages session fold])])])
        (infix [need "=" (call tokens [out system])])
        (if' (infix [need "<=" limit]) (return out))
      ])
      (call (dot ctx "abort") [])
      (throw' (new Error [(tpl ["optchat: " (sub BOT) " would send about " (sub need) " tokens to " (sub (dot ctx "model.provider")) "/" (sub (dot ctx "model.id")) ", past the " (sub limit) " its context window leaves after its output, even with its current run folded"])]))
    ]))
    blank
    ({ctx}: (fn start (typed [(typed ctx ExtensionContext)] void) [
      (infix [snap "=" undefined])
      (infix [
        enabled
        "="
        (below (infix (rows [
          (dot ctx "agent?.kind")
          "==="
          (str "main")
          "&&"
          [(dot ctx "mode") "===" (str "tui") "||" (dot ctx "mode") "===" (str "rpc")]
          "&&"
          (call (dot ctx "sessionManager.getSessionFile") [])
          "!=="
          undefined
          "&&"
          [BOT "!==" undefined "||" (call (dot fs "existsSync") [(dot STORE "main")])]
        ])))
      ])
      (if' (infix [(not enabled) "||" BOT "===" undefined]) return')
      (call (dot fs "mkdirSync") [(dot STORE "log") (obj [(prop "recursive" true)])])
      (call backfill [ctx])
    ]))
    blank
    (call (dot pi "on") [
      (str "session_start")
      (async ({
        _event,
        ctx,
      }: (arrow [_event ctx] (call start [ctx]))))
    ])
    (call (dot pi "on") [
      (str "session_switch")
      (async ({
        _event,
        ctx,
      }: (arrow [_event ctx] (call start [ctx]))))
    ])
    blank
    (call (dot pi "on") [
      (str "message_end")
      (async ({
        event,
        ctx,
        session,
        rows',
      }: (arrow [event ctx] [
        (if' (not (call active [ctx])) return')
        (const session (call (dot ctx "sessionManager.getSessionId") []))
        (const rows' (call rowsOf [(infix [(dot event "message") "as" Logged]) (infix [BOT "??" (call chatName [(call (dot pi "getSessionName") []) session])])]))
        (if' (dot rows' "length") [
          (call (dot fs "appendFileSync") [(call (dot path "join") [(dot STORE "log") (tpl [(sub session) ".jsonl"])]) (call (dot rows' "join") [(str "")])])
          (call (dot saved "add") [(dot (infix [(dot event "message") "as" Logged]) "timestamp")])
        ])
      ])))
    ])
    blank
    (call (dot pi "on") [
      (str "context")
      (async ({
        event,
        ctx,
        pin,
        block,
        at,
        first,
        content,
      }: (arrow [event ctx] [
        (if' (not (call active [ctx])) (return undefined))
        (if' BOT ({messages}: [
          (const messages (call bot [(infix [(dot event "messages") "as" (arrayOf Logged)]) (call (dot ctx "sessionManager.getSessionId") []) ctx]))
          (return (obj [(prop "messages" (infix [messages "as" (typeof (dot event "messages"))]))]))
        ]))
        (let' pin (call (dot (call pins [ctx]) "at") [(-1)]))
        (if' (infix [pin "===" undefined]) [
          (infix [pin "=" (call take [])])
          (call (dot pi "appendEntry") [PIN pin])
        ])
        (const block (obj [(prop "type" (infix [(str "text") "as" const'])) (prop "text" (tpl [(sub INTRO) "\\n\\n" (sub (dot pin "view"))]))]))
        (const at (call (dot event "messages.findIndex") [({message}: (arrow [message] (infix [(dot message "role") "===" (str "user")])))]))
        (if' (infix [at "<" 0]) (return (obj [(prop "messages" (array [(obj [(prop "role" (str "user")) (prop "content" (array [block])) (prop "timestamp" (dot pin "time"))]) (spread (dot event "messages"))]))])))
        (const first (infix [(idx (dot event "messages") at) "as" (generic Extract [(idx (typeof (dot event "messages")) number) (shape [(typed "role" (str "user"))])])]))
        (const content (ternary (infix [(typeof (dot first "content")) "===" (str "string")]) (array [(obj [(prop "type" (infix [(str "text") "as" const'])) (prop "text" (dot first "content"))])]) (dot first "content")))
        (return (obj [(prop "messages" (call (dot event "messages.with") [at (obj [(spread first) (prop "content" (array [block (spread content)]))])]))]))
      ])))
    ])
    blank
    (call (dot pi "on") [
      (str "session_compact")
      (async ({
        _event,
        ctx,
      }: (arrow [_event ctx] [
        (if' (infix [(call active [ctx]) "&&" (not BOT)]) (call (dot pi "appendEntry") [PIN (call take [])]))
      ])))
    ])
  ]))))
])
