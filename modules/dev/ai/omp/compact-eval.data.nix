{
  Array,
  Boolean,
  String,
  Symbol,
  array,
  arrow,
  blank,
  call,
  chain,
  computed,
  const,
  default,
  dot,
  export,
  fn,
  forOf,
  idx,
  if',
  ifElse,
  import',
  infix,
  method,
  not,
  obj,
  optIdx,
  prop,
  regex,
  return,
  return',
  rows,
  spread,
  str,
  sub,
  ternary,
  tpl,
  typeof,
  undefined,
  ...
}: ({
  toolRenderers,
  NATIVE,
  LANGUAGES,
  failed,
  cellsOf,
  titles,
  TOOL_CALL,
  summary,
  tidy,
  compactEval,
}: [
  (import' [toolRenderers] (str "@oh-my-pi/pi-tui/tools"))
  blank
  (const NATIVE (call (dot Symbol "for") [(str "finix.omp-compact-eval.native")]))
  (const LANGUAGES (obj [(prop "python" true) (prop "js" true)]))
  blank
  ({result}: (fn failed [result] [
    (if' (infix [(dot result "?.isError") "||" (dot result "?.details?.isError")]) (return true))
    (return (call (dot (infix [(dot result "?.details?.cells") "??" (array [])]) "some") [({cell}: (arrow cell (infix [(dot cell "status") "===" (str "error")])))]))
  ]))
  blank
  ({args}: (fn cellsOf [args] [
    (if' (call (dot Array "isArray") [(dot args "?.cells")]) (return (dot args "cells")))
    (return (ternary (infix [(typeof (dot args "?.code")) "===" (str "string")]) (array [args]) (array [])))
  ]))
  blank
  ({cells}: (fn titles [cells] [
    (return (call (dot (call (dot cells "map") [({cell}: (arrow cell (ternary (infix [(typeof (dot cell "?.title")) "===" (str "string")]) (call (dot cell "title.trim") []) (str ""))))]) "filter") [Boolean]))
  ]))
  blank
  (const TOOL_CALL (regex "tool\\.(\\w+)\\(\\s*\\{?\\s*(?:[\"']?\\w+[\"']?\\s*[:=]\\s*)?[\"'`]([^\"'`\\n]+)" ""))
  blank
  ({cells}: (fn summary [cells] [
    ({
      cell,
      code,
      call',
      line,
    }: (forOf cell cells [
      (const code (call String [(infix [(dot cell "?.code") "??" (str "")])]))
      (const call' (call (dot TOOL_CALL "exec") [code]))
      (if' call' (return (array [(obj [(prop "t" (idx call' 1))]) (obj [(prop "t" (tpl [" " (sub (call (dot (idx call' 2) "trim") []))])) (prop "s" (str "code"))])])))
      (const line (chain (call (dot (call (dot (call (dot code "split") [(str "\\n")]) "map") [({row}: (arrow row (call (dot row "trim") [])))]) "find") [({row}: (arrow row (infix [(dot row "length") ">" 0 "&&" (not (call (dot row "startsWith") [(str "#")])) "&&" (not (call (dot row "startsWith") [(str "//")]))])))])))
      (if' line (return (array [(obj [(prop "t" line) (prop "s" (str "code"))])])))
    ]))
    (return undefined)
  ]))
  blank
  ({
    view,
    cells,
    extra,
    tool,
  }: (fn tidy [view cells extra] [
    (if' (not view) (return view))
    (const tool (infix [(dot view "tool") "&&" (obj [(spread (dot view "tool"))])]))
    (if' tool ({
      badges,
      named,
    }: [
      (const badges (call (dot (infix [(dot tool "badges") "??" (array [])]) "filter") [({badge}: (arrow badge (infix [(idx LANGUAGES (dot badge "text")) "!==" true])))]))
      (infix [(dot tool "badges") "=" (ternary (infix [(dot badges "length") ">" 0]) badges undefined)])
      (const named (call titles [cells]))
      (if' (infix [(not (dot tool "title")) "||" (dot tool "title") "===" (str "Eval")]) ({fallback}: [
        (const fallback (call summary [cells]))
        (ifElse (infix [(dot named "length") ">" 0]) (infix [(dot tool "title") "=" (idx named 0)]) (if' fallback (infix [(dot tool "title") "=" fallback])))
      ]))
    ]))
    (return (obj [(spread view) tool (prop "preview" (str "none")) (spread extra)]))
  ]))
  blank
  (export (default ({
    current,
    native,
  }: (fn compactEval [] [
    (const current (dot toolRenderers "eval"))
    (const native (infix [(optIdx current NATIVE) "??" current]))
    (if' (infix [(not (dot native "?.describeCall")) "||" (not (dot native "describeResult"))]) return')
    (infix [
      (dot toolRenderers "eval")
      "="
      (obj (rows [
        (spread native)
        (prop (computed NATIVE) native)
        ({
          args,
          options,
        }: (method "describeCall" [args options] [
          (return (call tidy [(call (dot native "describeCall") [args options]) (call cellsOf [args])]))
        ]))
        ({
          result,
          options,
          args,
          cells,
        }: (method "describeResult" [result options args] [
          (const cells (ternary (dot result "?.details?.cells?.length") (dot result "details.cells") (call cellsOf [args])))
          (return (call tidy [(call (dot native "describeResult") [result options args]) cells (obj [(prop "open" (infix [(call failed [result]) "||" undefined]))])]))
        ]))
      ]))
    ])
  ]))))
])
