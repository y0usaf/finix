{
  ValueError,
  __name__,
  as,
  assert',
  assign,
  blank,
  call,
  commas,
  def,
  dict,
  dot,
  finally,
  from,
  if',
  import',
  index,
  kw,
  len,
  not,
  octal,
  pair,
  raise,
  raw,
  return,
  slice,
  sq,
  starstar,
  ternary,
  triple,
  try,
  with',
  ...
}: ({
  os,
  Path,
  re,
  stat,
  sys,
  tempfile,
  tomllib,
  apply,
}: [
  (triple "Reconcile only Codex's root reasoning setting, preserving other config.")
  (import' os)
  (from "pathlib" [Path])
  (import' re)
  (import' stat)
  (import' sys)
  (import' tempfile)
  (import' tomllib)
  blank
  (def apply ({
    path,
    text,
    before,
    header,
    end,
    root,
    rest,
    pattern,
    count,
    result,
    expected,
    mode,
    fd,
    tmp,
    stream,
  }: {
    params = [path];
    body = [
      (assign path (call (dot (call (dot (call Path [path]) "expanduser") []) "resolve") []))
      (assign text (ternary (call (dot path "read_text") []) (call (dot path "exists") []) (sq "")))
      (assign before (call (dot tomllib "loads") [text]))
      (assign header (call (dot re "search") [(raw (sq "^\\s*\\[")) text (kw "flags" (dot re "MULTILINE"))]))
      (assign end (ternary (call (dot header "start") []) header (call len [text])))
      (assign (commas [root rest]) (commas [(index text (slice null end)) (index text (slice end null))]))
      (assign pattern (raw (sq "^(?:model_reasoning_effort|\"model_reasoning_effort\"|\\'model_reasoning_effort\\')\\s*=.*$")))
      (assign (commas [root count]) (call (dot re "subn") [pattern (sq "model_reasoning_effort = \"low\"") root (kw "flags" (dot re "MULTILINE"))]))
      (if' (not count) [
        (assign root [(sq "model_reasoning_effort = \"low\"\\n") "+" root])
      ])
      (assign result [root "+" rest])
      (assign expected (dict [(starstar before) (pair (sq "model_reasoning_effort") (sq "low"))]))
      (if' [(call (dot tomllib "loads") [result]) "!=" expected] [
        (raise (call ValueError [(sq "Refusing to change unrelated Codex settings")]))
      ])
      (if' [result "==" text] [
        (return null)
      ])
      (call (dot path "parent.mkdir") [(kw "parents" true) (kw "exist_ok" true)])
      (assign mode (ternary (call (dot stat "S_IMODE") [(dot (call (dot path "stat") []) "st_mode")]) (call (dot path "exists") []) (octal 384)))
      (assign (commas [fd tmp]) (call (dot tempfile "mkstemp") [(kw "dir" (dot path "parent")) (kw "prefix" (sq ".reasoning-policy-"))]))
      (try [
          (with' [(as (call (dot os "fdopen") [fd (sq "w")]) stream)] [
            (call (dot stream "write") [result])
            (call (dot os "fchmod") [(call (dot stream "fileno") []) mode])
          ])
          (call (dot os "replace") [tmp path])
        ] [
          (finally [
            (if' (call (dot os "path.exists") [tmp]) [
              (call (dot os "unlink") [tmp])
            ])
          ])
        ])
      (assert' [(call (dot tomllib "loads") [(call (dot path "read_text") [])]) "==" expected])
    ];
  }))
  blank
  (if' [__name__ "==" (sq "__main__")] [
    (call apply [(index (dot sys "argv") 1)])
  ])
])
