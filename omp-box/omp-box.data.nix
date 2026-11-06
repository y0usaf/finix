{
  HOME,
  IFS,
  XDG_STATE_HOME,
  ansic,
  argCount,
  args,
  argsJoined,
  arm,
  array,
  assign,
  blank,
  case,
  chain,
  default,
  dq,
  dropSuffix,
  elements,
  exists,
  fn,
  for,
  heredoc,
  if',
  inline,
  isDir,
  nonEmpty,
  pipe,
  redir,
  required,
  shebang,
  sq,
  sub,
  test,
  var,
  while,
  word,
  ...
}: ({
  state,
  grants,
  shares,
  key,
  port,
  target,
  ssh,
  usage,
  up,
  fail,
  covers,
  mount_guest,
  unmount_guest,
  apply_host,
  drop_host,
  cmd_add,
  cmd_rm,
  cmd_list,
  f,
  cmd_reconcile,
  cmd_retry,
}: [
  (shebang "/usr/bin/env bash")
  ["set" "-euo" "pipefail"]
  blank
  (assign state (dq [(default XDG_STATE_HOME (word [(var HOME) "/.local/state"])) "/omp-box"]))
  (assign grants (dq [(var state) "/grants"]))
  (assign shares (dq [(var state) "/shares"]))
  (assign key (dq [(var state) "/ssh-key"]))
  (assign port 22422)
  (assign target "y0usaf@127.0.0.1")
  (assign ssh (array ["ssh" "-q" "-p" (dq (var port)) "-i" (dq (var key)) "-o" "LogLevel=ERROR" "-o" "UserKnownHostsFile=/dev/null" "-o" "StrictHostKeyChecking=no" "-o" "BatchMode=yes" "-o" "ConnectTimeout=2" "-o" "ServerAliveInterval=2" "-o" "ServerAliveCountMax=1"]))
  blank
  (fn usage [
    [
      "cat"
      (heredoc "EOF" ''
        usage: omp-box <command>

          list [--json]        granted folders
          add PATH [--copy | --ro] [--name NAME]
                               share PATH into the box at the same path, as grant NAME
                               (default: PATH's folder name); --copy shares a copy,
                               --ro shares it read-only
          rm NAME              revoke a grant
          reconcile            re-apply every grant (after a box restart)
          retry                start the box again after omp-box-run gave up on it
      '')
    ]
  ])
  blank
  (fn up (inline [[(dq (elements ssh)) (dq (var target)) "true" (redir "2>" "/dev/null")]]))
  blank
  (fn fail (inline [["printf" (sq "omp-box: %s\\n") (dq (var argsJoined)) (redir ">&" 2)] ["exit" 1]]))
  blank
  (fn covers ({base}: inline [["local" (assign base (dropSuffix 1 "/"))] (case (dq [(var 2) "/"]) (inline [(arm (word [(dq (var base)) "/*"]) (inline [["return" 0]])) (arm "*" (inline [["return" 1]]))]))]))
  blank
  (fn mount_guest ({
    name,
    path,
  }: [
    ["local" (assign name (var 1)) (assign path (var 2))]
    [
      (dq (elements ssh))
      (dq (var target))
      (dq [
        ''
          set -e
              p=''
        (sub [["printf" "%q" (dq (var path))]])
        "\n    /run/wrappers/bin/sudo mkdir -p \"$(dirname \"$p\")\" \"$p\"\n    /run/wrappers/bin/sudo mountpoint -q \"$p\" || /run/wrappers/bin/sudo mount --bind "
        (sub [["printf" "%q" (dq ["/mnt/shares/" (var name)])]])
        " \"$p\""
      ])
    ]
  ]))
  blank
  (fn unmount_guest ({path}: [
    ["local" (assign path (var 1))]
    (chain [[(dq (elements ssh)) (dq (var target)) (dq ["/run/wrappers/bin/sudo mountpoint -q " (sub [["printf" "%q" (dq (var path))]]) " && /run/wrappers/bin/sudo umount " (sub [["printf" "%q" (dq (var path))]]) " || true"]) (redir "2>" "/dev/null")] "||" ["true"]])
  ]))
  blank
  (fn apply_host ({
    name,
    path,
    mode,
  }: [
    ["local" (assign name (var 1)) (assign path (var 2)) (assign mode (var 3))]
    ["mkdir" "-p" (dq [(var shares) "/" (var name)])]
    (let
      share = dq [(var shares) "/" (var name)];
      bind = chain [["findmnt" "-n" "-o" "TARGET" share (redir ">" "/dev/null") (redir "2>&" 1)] "||" ["/run/wrappers/bin/sudo" "-n" "mount" "--bind" (dq (var path)) share]];
    in
      case (var mode) [
        (arm "copy" (inline [["cp" "-au" (dq [(var path) "/."]) (dq [(var shares) "/" (var name) "/"])]]))
        (arm "bind" (inline [bind]))
        (arm "ro" (inline [bind (if' ["test" "-w" share] (inline [["/run/wrappers/bin/sudo" "-n" "mount" "-o" "remount,bind,ro" share]]))]))
      ])
  ]))
  blank
  (fn drop_host ({
    name,
    mode,
  }: [
    ["local" (assign name (var 1)) (assign mode (var 2))]
    (if' (test [(dq (var mode)) "!=" "copy"]) [
      (if' ["findmnt" "-n" "-o" "TARGET" (dq [(var shares) "/" (var name)]) (redir ">" "/dev/null") (redir "2>&" 1)] (inline [(chain [["/run/wrappers/bin/sudo" "-n" "umount" (dq [(var shares) "/" (var name)])] "||" [fail (dq ["could not unmount " (var shares) "/" (var name) ", so the grant stays"])]])]))
    ])
    (chain [["findmnt" "-n" "-o" "TARGET" (dq [(var shares) "/" (var name)]) (redir ">" "/dev/null") (redir "2>&" 1)] "||" ["rm" "-rf" (dq [(required shares "") "/" (required name "")])]])
  ]))
  blank
  (fn cmd_add ({
    path,
    mode,
    name,
  }: [
    ["local" (assign path (dq "")) (assign mode "bind") (assign name (dq ""))]
    (while (test [(var argCount) "-gt" 0]) [
      (case (var 1) [(arm "--copy" (inline [(assign mode "copy")])) (arm "--ro" (inline [(assign mode "ro")])) (arm "--name" (inline [(assign name (default 2 "")) ["shift"]])) (arm "*" (inline [(assign path (var 1))]))])
      ["shift"]
    ])
    (chain [(test (nonEmpty (dq (var path)))) "||" [fail (dq "add needs a path")]])
    (assign path (sub [["realpath" "-e" "--" (dq (var path))]]))
    (chain [(test (isDir (dq (var path)))) "||" [fail (dq [(var path) " is not a directory"])]])
    (if' [covers (dq (var path)) (dq (sub [["realpath" "-m" "--" (dq (var state))]]))] (inline [[fail (dq [(var path) " holds the share directory itself, so sharing it loops"])]]))
    (if' [covers (dq (var path)) (dq (var HOME))] (inline [[fail (dq [(var path) " covers " (var HOME) ", where the box keeps its own state; share a folder inside it"])]]))
    (chain [(test (nonEmpty (dq (var name)))) "||" (assign name (sub [["basename" "--" (dq (var path))]]))])
    (assign name (sub [(pipe [["printf" "%s" (dq (var name))] ["tr" "-cd" (sq "A-Za-z0-9._-")]])]))
    (chain [(test (nonEmpty (dq (var name)))) "||" [fail (dq "the grant needs a name of letters, digits, '.', '_' or '-'")]])
    (chain [(test (exists (dq [(var grants) "/" (var name)]))) "&&" [fail (dq ["grant '" (var name) "' already exists (rm it first)"])]])
    ["mkdir" "-p" (dq (var grants)) (dq (var shares))]
    [apply_host (dq (var name)) (dq (var path)) (dq (var mode))]
    ["printf" (sq "%s\\t%s\\n") (dq (var path)) (dq (var mode)) (redir ">" (dq [(var grants) "/" (var name)]))]
    (if' [up] (inline [(chain [[mount_guest (dq (var name)) (dq (var path))] "||" [fail (dq "granted on the host, but the box did not take it")]])]))
    ["printf" (sq "%s  %s  %s\\n") (dq (var name)) (dq (var mode)) (dq (var path))]
  ]))
  blank
  (fn cmd_rm ({
    name,
    path,
    mode,
  }: [
    ["local" (assign name (default 1 ""))]
    (chain [(test (nonEmpty (dq (var name)))) "||" [fail (dq "rm needs a name")]])
    (chain [(test (exists (dq [(var grants) "/" (var name)]))) "||" [fail (dq ["no grant '" (var name) "'"])]])
    ["local" path mode]
    [(assign IFS (ansic "\t")) "read" "-r" path mode (redir "<" (dq [(var grants) "/" (var name)]))]
    (if' [up] (inline [[unmount_guest (dq (var path))]]))
    [drop_host (dq (var name)) (dq (var mode))]
    ["rm" "-f" (dq [(var grants) "/" (var name)])]
    ["printf" (sq "removed %s\\n") (dq (var name))]
  ]))
  blank
  (fn cmd_list ({
    json,
    first,
    name,
    path,
    mode,
  }: [
    ["local" (assign json 0)]
    (chain [(test [(dq (default 1 "")) "=" "--json"]) "&&" (assign json 1)])
    (if' (test [(dq (var json)) "=" 1]) [
      ["printf" (sq "[")]
      ["local" (assign first 1) name path mode]
      (for f [(word [(dq (var grants)) "/*"])] [
        (chain [(test (exists (dq (var f)))) "||" ["continue"]])
        [(assign IFS (ansic "\t")) "read" "-r" path mode (redir "<" (dq (var f)))]
        (assign name (sub [["basename" "--" (dq (var f))]]))
        (chain [(test [(dq (var first)) "=" 1]) "||" ["printf" (sq ",")]])
        (assign first 0)
        ["printf" (sq "{\"name\":\"%s\",\"path\":\"%s\",\"mode\":\"%s\"}") (dq (var name)) (dq (var path)) (dq (var mode))]
      ])
      ["printf" (sq "]\\n")]
      ["return"]
    ])
    ["local" name]
    (for f [(word [(dq (var grants)) "/*"])] [
      (chain [(test (exists (dq (var f)))) "||" ["continue"]])
      ["local" path mode]
      [(assign IFS (ansic "\t")) "read" "-r" path mode (redir "<" (dq (var f)))]
      (assign name (sub [["basename" "--" (dq (var f))]]))
      ["printf" (sq "%-16s %-5s %s\\n") (dq (var name)) (dq (var mode)) (dq (var path))]
    ])
  ]))
  blank
  (fn cmd_reconcile ({
    f',
    path,
    mode,
    name,
    failed,
  }: [
    (chain [(test (isDir (dq (var grants)))) "||" ["return" 0]])
    ["local" f' path mode name (assign failed 0)]
    (for f' [(word [(dq (var grants)) "/*"])] [
      (chain [(test (exists (dq (var f')))) "||" ["continue"]])
      [(assign IFS (ansic "\t")) "read" "-r" path mode (redir "<" (dq (var f')))]
      (chain [(test (isDir (dq (var path)))) "||" ["continue"]])
      (assign name (sub [["basename" "--" (dq (var f'))]]))
      (if' (chain [[apply_host (dq (var name)) (dq (var path)) (dq (var mode))] "&&" [mount_guest (dq (var name)) (dq (var path))]]) [
        ["continue"]
      ])
      ["printf" (sq "omp-box: grant %s (%s) did not apply\\n") (dq (var name)) (dq (var path)) (redir ">&" 2)]
      (assign failed 1)
    ])
    ["return" (dq (var failed))]
  ]))
  blank
  (fn cmd_retry ({file}: [
    ["local" (assign file (dq [(var state) "/status.json"]))]
    (chain [(test (exists (dq (var file)))) "||" [fail (dq ["the box is not waiting on a failure (no " (var file) ")"])]])
    (chain [["jq" "-e" (sq ".state == \"failed\"") (dq (var file)) (redir ">" "/dev/null")] "||" [fail (dq ["the box is not failed: " (var file) " says " (sub [["jq" "-r" ".state" (dq (var file))]])])]])
    ["rm" "-f" (dq (var file))]
    ["printf" (sq "cleared %s, so omp-box-run starts the box again\\n") (dq (var file))]
  ]))
  blank
  (case (default 1 "") [(arm "list" (inline [["shift"] [cmd_list (dq (var args))]])) (arm "add" (inline [["shift"] [cmd_add (dq (var args))]])) (arm "rm" (inline [["shift"] [cmd_rm (dq (var args))]])) (arm "reconcile" (inline [[cmd_reconcile]])) (arm "retry" (inline [[cmd_retry]])) (arm "*" (inline [[usage] ["exit" 2]]))])
])
