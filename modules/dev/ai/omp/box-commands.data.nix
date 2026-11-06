{
  Boolean,
  Bun,
  Promise,
  Response,
  String,
  array,
  arrow,
  async,
  await,
  blank,
  call,
  const,
  default,
  dot,
  export,
  fn,
  idx,
  if',
  import',
  infix,
  new,
  not,
  obj,
  prop,
  regex,
  return,
  return',
  rows,
  spaces,
  spread,
  str,
  sub,
  ternary,
  tpl,
  ...
}: (spaces 2 ({
  homedir,
  usage,
  expand,
  ompBox,
  boxCommands,
}: [
  (import' [homedir] (str "node:os"))
  blank
  (const usage (str "usage: /box [list | add PATH [--copy] | rm NAME | reconcile]"))
  blank
  ({value}: (fn expand [value] [
    (if' (infix [value "===" (str "~")]) (return (call homedir [])))
    (if' (call (dot value "startsWith") [(str "~/")]) (return (tpl [(sub (call homedir [])) "/" (sub (call (dot value "slice") [2]))])))
    (return value)
  ]))
  blank
  (async ({
    args,
    proc,
    stdout,
    stderr,
    code,
  }: (fn ompBox [args] [
    (const proc (call (dot Bun "spawn") [(array [(str "omp-box") (spread args)]) (obj [(prop "stdout" (str "pipe")) (prop "stderr" (str "pipe"))])]))
    (const (array [stdout stderr code]) (await (call (dot Promise "all") [
      (array (rows [
        (call (dot (new Response [(dot proc "stdout")]) "text") [])
        (call (dot (new Response [(dot proc "stderr")]) "text") [])
        (dot proc "exited")
      ]))
    ])))
    (return (obj [(prop "ok" (infix [code "===" 0])) (prop "text" (call (dot (ternary (infix [code "===" 0]) stdout (infix [stderr "||" stdout])) "trim") []))]))
  ])))
  blank
  (export (default ({pi}: (fn boxCommands [pi] [
    (call (dot pi "setLabel") [(str "Box access")])
    blank
    (call (dot pi "registerCommand") [
      (str "box")
      (obj (rows [
        (prop "description" (str "Manage what omp-box shares: list, add, copy, remove, reconcile"))
        (prop "handler" (async ({
          args,
          ctx,
          action,
          rest,
        }: (arrow [args ctx] [
          (const (array [action (spread rest)]) (call (dot (call (dot (call (dot (call String [(infix [args "??" (str "")])]) "trim") []) "split") [(regex "\\s+" "")]) "filter") [Boolean]))
          blank
          (if' (infix [(not action) "||" action "===" (str "list")]) ({result}: [
            (const result (await (call ompBox [(array [(str "list")])])))
            (call (dot ctx "ui.notify") [(infix [(dot result "text") "||" (str "no grants")]) (ternary (dot result "ok") (str "info") (str "error"))])
            return'
          ]))
          blank
          (if' (infix [action "===" (str "add")]) ({
            copy,
            path,
            boxArgs,
            result,
          }: [
            (const copy (call (dot rest "includes") [(str "--copy")]))
            (const path (call (dot rest "find") [({value}: (arrow value (infix [value "!==" (str "--copy")])))]))
            (if' (not path) [
              (call (dot ctx "ui.notify") [usage (str "info")])
              return'
            ])
            (const boxArgs (array [(str "add") (call expand [path])]))
            (if' copy (call (dot boxArgs "push") [(str "--copy")]))
            (const result (await (call ompBox [boxArgs])))
            (call (dot ctx "ui.notify") [(infix [(dot result "text") "||" usage]) (ternary (dot result "ok") (str "info") (str "error"))])
            return'
          ]))
          blank
          (if' (infix [action "===" (str "rm")]) ({
            name,
            result,
          }: [
            (const name (idx rest 0))
            (if' (not name) [
              (call (dot ctx "ui.notify") [usage (str "info")])
              return'
            ])
            (const result (await (call ompBox [(array [(str "rm") name])])))
            (call (dot ctx "ui.notify") [(infix [(dot result "text") "||" usage]) (ternary (dot result "ok") (str "info") (str "error"))])
            return'
          ]))
          blank
          (if' (infix [action "===" (str "reconcile")]) ({result}: [
            (const result (await (call ompBox [(array [(str "reconcile")])])))
            (call (dot ctx "ui.notify") [(infix [(dot result "text") "||" (str "grants reconciled")]) (ternary (dot result "ok") (str "info") (str "error"))])
            return'
          ]))
          blank
          (call (dot ctx "ui.notify") [usage (str "info")])
        ]))))
      ]))
    ])
  ]))))
]))
