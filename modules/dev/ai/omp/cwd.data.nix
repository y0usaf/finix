{
  String,
  arrow,
  async,
  blank,
  call,
  const,
  default,
  dot,
  export,
  fn,
  import',
  infix,
  obj,
  optIdx,
  prop,
  regex,
  return,
  rows,
  str,
  sub,
  ternary,
  tpl,
  undefined,
  ...
}: ({
  buildDirectoryArgumentCompletions,
  cwd,
}: [
  (import' [buildDirectoryArgumentCompletions] (str "@oh-my-pi/pi-coding-agent/slash-commands/builtin-completions"))
  blank
  (export (default ({pi}: (fn cwd [pi] [
    (call (dot pi "setLabel") [(str "Working directory")])
    blank
    (call (dot pi "on") [
      (str "input")
      (async ({
        event,
        dir,
      }: (arrow event [
        (const dir (optIdx (call (dot (regex "^\\/cwd\\s+(\\S[\\s\\S]*)$" "") "exec") [(call (dot (call String [(infix [(dot event "text") "??" (str "")])]) "trim") [])]) 1))
        (return (ternary dir (obj [(prop "text" (tpl ["/move " (sub dir)]))]) undefined))
      ])))
    ])
    blank
    (call (dot pi "registerCommand") [
      (str "cwd")
      (obj (rows [
        (prop "description" (str "Show the working directory; /cwd DIR moves the session there, as /move does"))
        (prop "getArgumentCompletions" (call buildDirectoryArgumentCompletions []))
        (prop "handler" (async ({
          _args,
          ctx,
        }: (arrow [_args ctx] [
          (call (dot ctx "ui.notify") [(call (dot ctx "sessionManager.getCwd") []) (str "info")])
        ]))))
      ]))
    ])
  ]))))
])
