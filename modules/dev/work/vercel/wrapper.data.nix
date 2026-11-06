{
  aligned,
  any,
  assign,
  blank,
  break,
  call,
  commas,
  compFor,
  def,
  default,
  dot,
  enumerate,
  field,
  for,
  from,
  gen,
  if',
  ifElse,
  import',
  index,
  kw,
  len,
  list,
  not,
  octal,
  placeholder,
  print,
  return,
  rows,
  slice,
  sq,
  star,
  str',
  strings,
  ternary,
  tuple,
  ...
}: ({
  os,
  subprocess,
  sys,
  Path,
  args,
  cli,
  fail,
  run_cli,
  cwd,
  index',
  arg,
  git,
  account,
  origin,
  prefix,
  owner,
  profile,
}: [
  (import' os)
  (import' subprocess)
  (import' sys)
  (from "pathlib" [Path])
  blank
  (assign args (index (dot sys "argv") (slice 1 null)))
  (assign cli (sq "@vercel@/bin/vercel"))
  blank
  blank
  (def fail ({message}: {
    params = [message];
    body = [
      (call (dot sys "exit") [(sq ["vercel: " (field message)])])
    ];
  }))
  blank
  blank
  (def run_cli ({extra}: {
    params = [(default extra (tuple []))];
    body = [
      (call (dot os "execv") [cli (list [cli (star extra) (star args)])])
    ];
  }))
  blank
  blank
  (if' (call any [(gen ({arg}: [(rows [[arg "in" (tuple [(sq "--token") (sq "-t") (sq "--global-config") (sq "-Q")]) "or"] (call (dot arg "startswith") [(tuple [(sq "--token=") (sq "--global-config=")])])]) (compFor arg args)]))]) [
    (call run_cli [])
  ])
  blank
  (if' [(sq "--help") "in" args "or" (sq "-h") "in" args "or" (not args)] [
    (call print [(strings (rows [(sq "Account routing: VERCEL_ACCOUNT=personal|work, then ") (sq "recognized GitHub origin owner.\\n") (sq "Use vercel-personal login or vercel-work login to authenticate.\\n") (sq "Inspect the selected login with vercel whoami.")])) (kw "flush" true)])
    (if' args [
      (call run_cli [])
    ])
  ])
  blank
  (assign cwd (call (dot os "getcwd") []))
  (for (commas [index' arg]) (call enumerate [args]) [
    (ifElse [arg "==" (sq "--cwd")] [
        (if' [index' "+" 1 "==" (call len [args])] [
          (call fail [(sq "--cwd requires a directory")])
        ])
        (assign cwd (index args [index' "+" 1]))
      ] (if' (call (dot arg "startswith") [(sq "--cwd=")]) [
        (assign cwd (index (call (dot arg "split") [(sq "=") 1]) 1))
      ]))
  ])
  (if' (not (call (dot (call Path [cwd]) "is_dir") [])) [
    (call fail [(sq ["directory does not exist: " (field cwd)])])
  ])
  blank
  blank
  (def git ({
    arguments,
    result,
  }: {
    params = [(star arguments)];
    body = [
      (assign result (call (dot subprocess "run") (aligned [(list [(sq "@git@/bin/git") (sq "-C") cwd (star arguments)]) [(kw "capture_output" true) (kw "text" true)]])))
      (return (ternary (call (dot result "stdout.strip") []) [(dot result "returncode") "==" 0] (sq "")))
    ];
  }))
  blank
  blank
  (assign account (call (dot os "environ.get") [(sq "VERCEL_ACCOUNT")]))
  (if' (not account) [
    (assign origin (call git [(sq "remote") (sq "get-url") (sq "origin")]))
    (for prefix (tuple [(sq "git@github.com:") (sq "https://github.com/") (sq "ssh://git@github.com/")]) [
      (if' (call (dot origin "startswith") [prefix]) [
        (assign owner (call (dot (index (call (dot (call (dot origin "removeprefix") [prefix]) "split") [(sq "/")]) 0) "lower") []))
        (assign account (call (dot (placeholder "owners") "get") [owner (sq "")]))
        break
      ])
    ])
  ])
  (if' [account "not in" (tuple [(sq "personal") (sq "work")])] [
    (call fail [(sq "use vercel-personal/vercel-work or set VERCEL_ACCOUNT=personal|work")])
  ])
  blank
  (assign profile (rows [(call Path [(call (dot os "environ.get") [(sq "XDG_DATA_HOME") (call str' [[(call (dot Path "home") []) "/" (sq ".local/share")]])])]) ["/" (sq "com.vercel.cli") "/" (sq "profiles") "/" account]]))
  (call (dot profile "mkdir") [(kw "parents" true) (kw "exist_ok" true) (kw "mode" (octal 448))])
  (call run_cli [(list [(sq "--global-config") (call str' [profile])])])
])
