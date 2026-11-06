{
  Math,
  String,
  Symbol,
  WeakMap,
  WeakSet,
  array,
  arrow,
  async,
  below,
  blank,
  call,
  chain,
  class,
  const,
  default,
  dot,
  export,
  fn,
  forOf,
  globalThis,
  idx,
  if',
  ifElse,
  import',
  infix,
  let',
  method,
  new,
  not,
  obj,
  optCall,
  performance,
  prop,
  regex,
  return,
  rows,
  spread,
  str,
  sub,
  ternary,
  this,
  tpl,
  typeof,
  undefined,
  ...
}: ({
  AssistantMessageComponent,
  BashExecutionComponent,
  chatTranscriptDisplayPreferences,
  CollabPromptMessageComponent,
  BranchSummaryMessageComponent,
  CompactionSummaryMessageComponent,
  HandoffSummaryMessageComponent,
  EvalExecutionComponent,
  ReadToolGroupComponent,
  SkillMessageComponent,
  ToolExecutionComponent,
  CollapsedSyntheticMessageComponent,
  UserMessageComponent,
  TranscriptContainer,
  col,
  elapsed,
  node,
  span,
  text,
  isNativeSettled,
  settleNative,
  STATE,
  TOOLS,
  INITIATORS,
  isTool,
  isInitiator,
  isComponent,
  isThinking,
  duration,
  same,
  INLINE,
  headline,
  install,
  workFold,
}: [
  (import' [AssistantMessageComponent] (str "@oh-my-pi/pi-tui/chat/assistant-message"))
  (import' [BashExecutionComponent] (str "@oh-my-pi/pi-tui/chat/bash-execution"))
  (import' [chatTranscriptDisplayPreferences] (str "@oh-my-pi/pi-tui/chat/display-preferences"))
  (import' [CollabPromptMessageComponent] (str "@oh-my-pi/pi-tui/chat/collab-prompt-message"))
  (import' (rows [
    BranchSummaryMessageComponent
    CompactionSummaryMessageComponent
    HandoffSummaryMessageComponent
  ]) (str "@oh-my-pi/pi-tui/chat/compaction-summary-message"))
  (import' [EvalExecutionComponent] (str "@oh-my-pi/pi-tui/chat/eval-execution"))
  (import' [ReadToolGroupComponent] (str "@oh-my-pi/pi-tui/chat/read-tool-group"))
  (import' [SkillMessageComponent] (str "@oh-my-pi/pi-tui/chat/skill-message"))
  (import' [ToolExecutionComponent] (str "@oh-my-pi/pi-tui/chat/tool-execution"))
  (import' [CollapsedSyntheticMessageComponent UserMessageComponent] (str "@oh-my-pi/pi-tui/chat/user-message"))
  (import' [TranscriptContainer] (str "@oh-my-pi/pi-tui/chrome"))
  (import' [col elapsed node span text] (str "@oh-my-pi/pi-tui/native/describe"))
  (import' [isNativeSettled settleNative] (str "@oh-my-pi/pi-tui/native/settle"))
  blank
  (const STATE (call (dot Symbol "for") [(str "finix.omp-work-fold.state")]))
  blank
  (const TOOLS (array [ToolExecutionComponent ReadToolGroupComponent]))
  (const INITIATORS (array (rows [
    UserMessageComponent
    CollapsedSyntheticMessageComponent
    SkillMessageComponent
    CollabPromptMessageComponent
    BashExecutionComponent
    EvalExecutionComponent
    CompactionSummaryMessageComponent
    HandoffSummaryMessageComponent
    BranchSummaryMessageComponent
  ])))
  blank
  ({block}: (fn isTool [block] [
    (return (call (dot TOOLS "some") [({kind}: (arrow kind (infix [block "instanceof" kind])))]))
  ]))
  blank
  ({block}: (fn isInitiator [block] [
    (return (call (dot INITIATORS "some") [({kind}: (arrow kind (infix [block "instanceof" kind])))]))
  ]))
  blank
  ({child}: (fn isComponent [child] [
    (return (infix [(typeof (dot child "?.render")) "===" (str "function")]))
  ]))
  blank
  ({child}: (fn isThinking [child] [
    (return (infix [(not (call isComponent [child])) "&&" (dot child "?.k") "===" (str "section") "&&" (call (dot (call String [(infix [(dot child "p?.role") "??" (str "")])]) "startsWith") [(str "omp.thinking")])]))
  ]))
  blank
  ({
    ms,
    seconds,
    minutes,
  }: (fn duration [ms] [
    (const seconds (infix [ms "/" 1000]))
    (if' (infix [seconds "<" 10]) (return (tpl [(sub (call (dot (call (dot Math "max") [0 seconds]) "toFixed") [1])) "s"])))
    (if' (infix [seconds "<" 60]) (return (tpl [(sub (call (dot Math "round") [seconds])) "s"])))
    (const minutes (call (dot Math "floor") [(infix [seconds "/" 60])]))
    (if' (infix [minutes "<" 60]) (return (tpl [(sub minutes) "m " (sub (call (dot (call String [(call (dot Math "round") [(infix [seconds "%" 60])])]) "padStart") [2 (str "0")])) "s"])))
    (return (tpl [(sub (call (dot Math "floor") [(infix [minutes "/" 60])])) "h " (sub (call (dot (call String [(infix [minutes "%" 60])]) "padStart") [2 (str "0")])) "m"]))
  ]))
  blank
  ({
    a,
    b,
  }: (fn same [a b] [
    (return (infix [
      (dot a "length")
      "==="
      (dot b "length")
      "&&"
      (call (dot a "every") [
        ({
          item,
          i,
        }: (arrow [item i] (infix [item "===" (idx b i)])))
      ])
    ]))
  ]))
  blank
  (const INLINE (regex "`([^`]+)`|\\[([^\\]]+)\\]\\(([^)\\s]+)[^)]*\\)" "g"))
  blank
  ({
    markdown,
    line,
    spans,
    at,
  }: (fn headline [markdown] [
    (const line (below (infix [(chain (call (dot (call (dot (call (dot (call String [(infix [markdown "??" (str "")])]) "split") [(str "\\n")]) "map") [({row}: (arrow row (call (dot (call (dot row "replace") [(regex "^\\s*(?:#{1,6}\\s+|>\\s*|[-*+]\\s+|\\d+[.)]\\s+)" "") (str "")]) "trim") [])))]) "find") [({row}: (arrow row (infix [(dot row "length") ">" 0 "&&" (not (call (dot row "startsWith") [(str "```")]))])))])) "??" (str "")])))
    (const spans (array []))
    (let' at 0)
    ({match}: (forOf match (call (dot line "matchAll") [INLINE]) [
      (if' (infix [(dot match "index") ">" at]) (call (dot spans "push") [(call span [(call (dot (call (dot line "slice") [at (dot match "index")]) "replace") [(regex "(\\*\\*|__|~~)" "g") (str "")])])]))
      (call (dot spans "push") [(ternary (infix [(idx match 1) "!==" undefined]) (call span [(idx match 1) (str "code")]) (call span [(idx match 2) (str "link") (obj [(prop "href" (idx match 3))])]))])
      (infix [at "=" (dot match "index") "+" (dot (idx match 0) "length")])
    ]))
    (if' (infix [at "<" (dot line "length")]) (call (dot spans "push") [(call span [(call (dot (call (dot line "slice") [at]) "replace") [(regex "(\\*\\*|__|~~)" "g") (str "")])])]))
    (return spans)
  ]))
  blank
  ({
    state,
    transcript,
    assistant,
    describeAssistant,
    setTurnUsage,
    nativeBlocks,
    ends,
    groups,
    voices,
    failures,
    shownBy,
    nodeBy,
    describe,
    speaks,
    thinks,
    Voice,
    voice,
    answer,
    Folded,
    folded,
    spent,
    Work,
    group,
  }: (fn install [state] [
    (const transcript (dot TranscriptContainer "prototype"))
    (const assistant (dot AssistantMessageComponent "prototype"))
    (const describeAssistant (dot assistant "describe"))
    (const setTurnUsage (dot assistant "setTurnUsage"))
    (const nativeBlocks (dot transcript "nativeBlocks"))
    (const ends (new WeakSet []))
    (const groups (new WeakMap []))
    (const voices (new WeakMap []))
    (const failures (new WeakMap []))
    (const shownBy (new WeakMap []))
    (const nodeBy (new WeakMap []))
    blank
    (const describe ({block}: (arrow block (call (dot block "describe") [(dot state "cx")]))))
    blank
    (infix [
      (dot assistant "describe")
      "="
      ({cx}: (fn null [cx] [
        (if' cx (infix [(dot state "cx") "=" cx]))
        (return (call (dot describeAssistant "call") [this cx]))
      ]))
    ])
    blank
    (infix [
      (dot assistant "setTurnUsage")
      "="
      ({summary}: (fn null [summary] [
        (ifElse summary (call (dot ends "add") [this]) (call (dot ends "delete") [this]))
        (return (call (dot setTurnUsage "call") [this summary]))
      ]))
    ])
    blank
    ({block}: (fn speaks [block] [
      (if' (not (infix [block "instanceof" AssistantMessageComponent])) (return false))
      (return (call (dot (infix [(dot (call describe [block]) "?.c") "??" (array [])]) "some") [({child}: (arrow child (infix [(not (call isComponent [child])) "&&" [(dot child "k") "===" (str "md") "||" (dot child "key") "===" (str "error")]])))]))
    ]))
    blank
    ({block}: (fn thinks [block] [
      (return (call (dot (infix [(dot (call describe [block]) "?.c") "??" (array [])]) "some") [isThinking]))
    ]))
    blank
    (class Voice [
      ({
        source,
        mode,
      }: (method "constructor" [source mode] [
        (infix [(dot this "source") "=" source])
        (infix [(dot this "mode") "=" mode])
      ]))
      (method "render" [] [
        (return (array []))
      ])
      (method "invalidate" [] [])
      ({event}: (method "handleNativeEvent" [event] [
        (optCall (dot this "source.handleNativeEvent") [event])
      ]))
      ({
        cx,
        whole,
        thinking,
        children,
        p,
      }: (method "describe" [cx] [
        (if' cx (infix [(dot state "cx") "=" cx]))
        (const whole (call (dot this "source.describe") [cx]))
        (if' (infix [whole "===" (dot this "whole")]) (return (dot this "node")))
        (infix [(dot this "whole") "=" whole])
        (const thinking (infix [(dot this "mode") "===" (str "thinking")]))
        (const children (call (dot (infix [(dot whole "?.c") "??" (array [])]) "filter") [({child}: (arrow child (infix [(call isThinking [child]) "===" thinking])))]))
        (const p (ternary (infix [(dot this "mode") "===" (str "note")]) (obj [(spread (dot whole "?.p")) (prop "role" (str "omp.assistant.note"))]) (dot whole "?.p")))
        (infix [(dot this "node") "=" (obj [(spread whole) p (prop "c" children)])])
        (return (dot this "node"))
      ]))
    ])
    blank
    ({
      source,
      mode,
      modes,
      chosen,
    }: (fn voice [source mode] [
      (let' modes (call (dot voices "get") [source]))
      (if' (not modes) [
        (infix [modes "=" (obj [])])
        (call (dot voices "set") [source modes])
      ])
      (infix [(idx modes mode) "??=" (new Voice [source mode])])
      (const chosen (idx modes mode))
      (if' (infix [(call isNativeSettled [source]) "&&" (not (call isNativeSettled [chosen]))]) (call settleNative [chosen]))
      (return chosen)
    ]))
    blank
    ({block}: (fn answer [block] [
      (return (ternary (call thinks [block]) (call voice [block (str "prose")]) block))
    ]))
    blank
    (class Folded [
      ({source}: (method "constructor" [source] [
        (infix [(dot this "source") "=" source])
        (infix [(dot this "opened") "=" false])
      ]))
      (method "render" [] [
        (return (array []))
      ])
      (method "invalidate" [] [])
      ({event}: (method "handleNativeEvent" [event] [
        (if' (infix [(dot event "type") "===" (str "toggle") "&&" (dot event "key") "===" (str "")]) (infix [(dot this "opened") "=" (not (dot event "collapsed"))]))
        (optCall (dot this "source.handleNativeEvent") [event])
      ]))
      ({
        cx,
        whole,
      }: (method "describe" [cx] [
        (if' cx (infix [(dot state "cx") "=" cx]))
        (const whole (call (dot this "source.describe") [cx]))
        (if' (infix [(dot this "opened") "||" (not (dot whole "?.p"))]) (return whole))
        (if' (infix [whole "===" (dot this "whole")]) (return (dot this "node")))
        (infix [(dot this "whole") "=" whole])
        (infix [(dot this "node") "=" (obj [(spread whole) (prop "p" (obj [(spread (dot whole "p")) (prop "collapsed" true)]))])])
        (return (dot this "node"))
      ]))
    ])
    blank
    ({
      source,
      wrapper,
    }: (fn folded [source] [
      (let' wrapper (call (dot failures "get") [source]))
      (if' (not wrapper) [
        (infix [wrapper "=" (new Folded [source])])
        (call (dot failures "set") [source wrapper])
      ])
      (return wrapper)
    ]))
    blank
    ({
      blocks,
      cx,
      total,
    }: (fn spent [blocks cx] [
      (let' total 0)
      ({
        block,
        described,
      }: (forOf block blocks [
        (const described (call (dot block "describe") [cx]))
        (ifElse (call isTool [block]) (infix [total "+=" (dot described "?.p?.took") "??" 0]) ({child}: (forOf child (infix [(dot described "?.c") "??" (array [])]) (if' (call isThinking [child]) (infix [total "+=" (dot child "p?.took") "??" 0])))))
      ]))
      (return (ternary (infix [total ">=" 1000]) total undefined))
    ]))
    blank
    (class Work [
      (method "constructor" [] [
        (infix [(dot this "blocks") "=" (array [])])
        (infix [(dot this "live") "=" false])
        (infix [(dot this "ended") "=" false])
      ])
      (method "render" [] [
        (return (array []))
      ])
      (method "invalidate" [] [])
      ({event}: (method "handleNativeEvent" [event] [
        (if' (infix [(dot event "type") "===" (str "toggle") "&&" (dot event "key") "===" (str "work")]) (infix [(dot this "toggled") "=" (dot event "collapsed")]))
      ]))
      ({
        lead,
        blocks,
        live,
        ended,
      }: (method "update" [lead blocks live ended] [
        (if' (infix [live "&&" (dot this "startedAt") "===" undefined]) (infix [(dot this "startedAt") "=" (call (dot performance "now") [])]))
        (if' (infix [(not live) "&&" (dot this "live")]) (infix [(dot this "endedAt") "=" (call (dot performance "now") [])]))
        (infix [(dot this "lead") "=" lead])
        (infix [(dot this "blocks") "=" blocks])
        (infix [(dot this "live") "=" live])
        (infix [(dot this "ended") "=" ended])
      ]))
      ({
        cx,
        note,
        thought,
        said,
        failed,
        collapsed,
        wall,
        time,
        shown,
        key,
        steps,
        count,
        prose,
        lead,
        whole,
        label,
        meta,
        head,
        body,
      }: (method "describe" [cx] [
        (if' cx (infix [(dot state "cx") "=" cx]))
        (const note (infix [(dot this "lead") "&&" (call voice [(dot this "lead.prose") (str "note")])]))
        (const thought (dot this "lead?.thought"))
        (const said (ternary note (call (dot note "describe") [cx]) undefined))
        (const failed (call (dot this "blocks.filter") [({block}: (arrow block (infix [(call isTool [block]) "&&" (dot (call (dot block "describe") [cx]) "?.p?.status") "===" (str "error")])))]))
        (const collapsed (infix [(dot this "toggled") "??" (not (dot this "live"))]))
        (const wall (below (ternary (infix [(dot this "startedAt") "!==" undefined "&&" (dot this "endedAt") "!==" undefined]) (infix [(dot this "endedAt") "-" (dot this "startedAt")]) undefined)))
        (const time (ternary (dot this "live") undefined (infix [wall "??" (call spent [(dot this "blocks") cx])])))
        (const shown (ternary (infix [collapsed "&&" (dot this "ended")]) failed (array [])))
        (const key (array [said thought (spread (dot this "blocks")) (spread failed) collapsed (dot this "live") (dot this "ended") time]))
        (if' (infix [(dot this "key") "&&" (call same [(dot this "key") key])]) (return (dot this "node")))
        (infix [(dot this "key") "=" key])
        (const steps (dot (call (dot this "blocks.filter") [isTool]) "length"))
        (const count (tpl [(sub steps) " " (sub (ternary (infix [steps "===" 1]) (str "step") (str "steps")))]))
        (const prose (call (dot (call String [(infix [(dot (call (dot said "?.c?.find") [({child}: (arrow child (infix [(not (call isComponent [child])) "&&" (dot child "k") "===" (str "md")])))]) "?.p?.text") "??" (str "")])]) "trim") []))
        (const lead (ternary note (call headline [prose]) (array [])))
        (const whole (infix [(dot (call (dot (call (dot prose "split") [(str "\\n")]) "filter") [({line}: (arrow line (infix [(dot (call (dot line "trim") []) "length") ">" 0])))]) "length") "<=" 1]))
        (const label (array []))
        (ifElse (infix [(dot lead "length") ">" 0]) ({fit}: [
            (const fit (ternary collapsed (obj [(prop "lines" 1) (prop "truncate" (str "end")) (prop "title" prose)]) (obj [(prop "wrap" (str "word"))])))
            (call (dot label "push") [(call text [lead (obj [(spread fit) (prop "shrink" 1)])])])
          ]) [
            (call (dot label "push") [(call text [(array [(call span [(ternary (dot this "live") (str "Working") (ternary (infix [time "===" undefined]) (str "Worked") (tpl ["Worked for " (sub (call duration [time]))])))])])])])
          ])
        (if' (dot this "live") (call (dot label "push") [(call elapsed [(infix [(call (dot performance "now") []) "-" (dot this "startedAt")])])]))
        (const meta (ternary (infix [(dot lead "length") ">" 0 "&&" time "!==" undefined]) (tpl [(sub count) " · " (sub (call duration [time]))]) count))
        (call (dot label "push") [(call text [(array [(call span [meta (str "dim")])]) (obj [(prop "basis" (str "content"))])])])
        (if' (infix [(dot failed "length") ">" 0]) (call (dot label "push") [(call node [(str "badge") (obj [(prop "text" (tpl [(sub (dot failed "length")) " failed"])) (prop "tone" (str "error"))])])]))
        (const head (call node [(str "row") (obj [(prop "gap" (str "sm")) (prop "align" (ternary collapsed (str "center") (str "baseline")))]) label (str "head")]))
        (const body (array (rows [
          (spread (ternary thought (array [thought]) (array [])))
          (spread (ternary (infix [note "&&" (not whole)]) (array [note]) (array [])))
          (spread (call (dot this "blocks.filter") [({block}: (arrow block (not (call (dot shown "includes") [block]))))]))
        ])))
        (infix [
          (dot this "node")
          "="
          (call col (rows [
            (array (rows [
              (call node [(str "section") (obj [(prop "role" (str "omp.notice.work")) (prop "collapsible" true) collapsed]) (array [head (spread body)]) (str "work")])
              (spread (call (dot shown "map") [folded]))
            ]))
            (obj [(prop "gap" (str "sm"))])
          ]))
        ])
        (return (dot this "node"))
      ]))
    ])
    blank
    ({
      first,
      work,
    }: (fn group [first] [
      (let' work (call (dot groups "get") [first]))
      (if' (not work) [
        (infix [work "=" (new Work [])])
        (call (dot groups "set") [first work])
      ])
      (return work)
    ]))
    blank
    (infix [
      (dot transcript "nativeBlocks")
      "="
      ({
        blocks,
        shown,
        pending,
        open,
        emit,
        close,
        previous,
      }: (fn null [] [
        (const blocks (call (dot nativeBlocks "call") [this]))
        (if' (dot chatTranscriptDisplayPreferences "hideToolActivity") (return blocks))
        (const shown (array []))
        (let' pending null)
        (let' open (array []))
        (const emit ({asAnswer}: (arrow asAnswer [
          (if' (dot pending "thought") (call (dot shown "push") [(dot pending "thought")]))
          (call (dot shown "push") [(ternary asAnswer (call answer [(dot pending "prose")]) (call voice [(dot pending "prose") (str "note")]))])
          (infix [pending "=" undefined])
        ])))
        (const close ({
          ended,
          last,
        }: (arrow [ended last] [
          (ifElse (call (dot open "some") [isTool]) ({work}: [
              (const work (call group [(infix [(dot pending "?.prose") "??" (idx open 0)])]))
              (call (dot work "update") [pending open (infix [last "&&" (dot state "running")]) ended])
              (call (dot shown "push") [work])
              (infix [pending "=" undefined])
            ]) [
              (if' pending (call emit [ended]))
              (call (dot shown "push") [(spread open)])
            ])
          (infix [open "=" (array [])])
        ])))
        ({block}: (forOf block blocks [
          (ifElse (call isInitiator [block]) [
              (ifElse (infix [(dot open "length") ">" 0]) (call close [true false]) (if' pending (call emit [true])))
              (call (dot shown "push") [block])
            ] (ifElse (call speaks [block]) ({thought}: [
                (const thought (ternary (call thinks [block]) (call voice [block (str "thinking")]) undefined))
                (ifElse (infix [(dot open "length") ">" 0]) [
                    (if' thought (call (dot open "push") [thought]))
                    (call close [false false])
                    (infix [pending "=" (obj [(prop "prose" block)])])
                  ] [
                    (if' pending (call emit [false]))
                    (infix [pending "=" (obj [(prop "prose" block) thought])])
                  ])
                (if' (call (dot ends "has") [block]) (call emit [true]))
              ]) (ifElse (infix [(call isTool [block]) "||" block "instanceof" AssistantMessageComponent "||" (dot open "length") ">" 0 "||" pending]) [
                  (call (dot open "push") [block])
                ] [
                  (call (dot shown "push") [block])
                ])))
        ]))
        (ifElse (infix [(dot open "length") ">" 0]) (call close [(not (dot state "running")) true]) (if' pending (call emit [(not (dot state "running"))])))
        (const previous (call (dot shownBy "get") [this]))
        (if' (infix [previous "&&" (call same [previous shown])]) (return previous))
        (call (dot shownBy "set") [this shown])
        (return shown)
      ]))
    ])
    blank
    (infix [
      (dot transcript "describe")
      "="
      ({
        blocks,
        cached,
        described,
      }: (fn null [] [
        (const blocks (call (dot this "nativeBlocks") []))
        (const cached (call (dot nodeBy "get") [this]))
        (if' (infix [(dot cached "?.blocks") "===" blocks]) (return (dot cached "node")))
        (const described (call col [blocks (obj [(prop "role" (str "omp.transcript"))])]))
        (call (dot nodeBy "set") [this (obj [blocks (prop "node" described)])])
        (return described)
      ]))
    ])
  ]))
  blank
  (export (default ({
    pi,
    state,
  }: (fn workFold [pi] [
    (let' state (idx globalThis STATE))
    (if' (not state) [
      (infix [state "=" (obj [(prop "running" false) (prop "cx" undefined)])])
      (infix [(idx globalThis STATE) "=" state])
      (call install [state])
    ])
    (call (dot pi "on") [
      (str "agent_start")
      (async ({
        _event,
        ctx,
      }: (arrow [_event ctx] [
        (if' (dot ctx "hasUI") (infix [(dot state "running") "=" true]))
      ])))
    ])
    (call (dot pi "on") [
      (str "agent_end")
      (async ({
        _event,
        ctx,
      }: (arrow [_event ctx] [
        (if' (dot ctx "hasUI") (infix [(dot state "running") "=" false]))
      ])))
    ])
  ]))))
])
