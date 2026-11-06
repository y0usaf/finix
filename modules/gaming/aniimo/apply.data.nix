{
  None,
  OSError,
  __name__,
  as,
  assign,
  augAssign,
  blank,
  bytearray,
  bytes,
  bytes',
  call,
  commas,
  compFor,
  continue,
  def,
  dict,
  dictComp,
  dot,
  except,
  field,
  for,
  from,
  gen,
  hang,
  if',
  ifElse,
  import',
  index,
  kw,
  lambda,
  len,
  list,
  listComp,
  not,
  pair,
  pass,
  print,
  return,
  rows,
  slice,
  sorted,
  spec,
  sq,
  str,
  ternary,
  try,
  tuple,
  while,
  with',
  ...
}: ({
  hashlib,
  json,
  os,
  shutil,
  struct,
  subprocess,
  sys,
  tempfile,
  zlib,
  Path,
  LUA_DIRS,
  FILES,
  md5,
  die,
  read_dir,
  heal,
  entry_bytes,
  lua_bytes,
  wrap,
  patched_entries,
  rebuild,
  write_atomic,
  install,
  main,
}: [
  (import' hashlib)
  (import' json)
  (import' os)
  (import' shutil)
  (import' struct)
  (import' subprocess)
  (import' sys)
  (import' tempfile)
  (import' zlib)
  (from "pathlib" [Path])
  blank
  (assign LUA_DIRS (list [(str "Aniimo_Data/StreamingAssets/cvs/res/lua") (str "Aniimo_Data/cvs/res/lua")]))
  (assign FILES (list [(str "LuaScripts.xdf") (str "LuaScripts.xdt") (str "LuaCacheVer.txt")]))
  blank
  blank
  (def md5 ({b}: {
    params = [b];
    body = [
      (return (call (dot (call (dot hashlib "md5") [b]) "hexdigest") []))
    ];
  }))
  blank
  blank
  (def die ({msg}: {
    params = [msg];
    body = [
      (call (dot sys "exit") [(str ["aniimo-mods: " (field msg)])])
    ];
  }))
  blank
  blank
  (def read_dir ({
    d,
    xdf,
    xdt_raw,
    xdt,
  }: {
    params = [d];
    body = [
      (assign xdf (call (dot [d "/" (str "LuaScripts.xdf")] "read_bytes") []))
      (assign xdt_raw (call (dot [d "/" (str "LuaScripts.xdt")] "read_bytes") []))
      (assign xdt (call (dot json "loads") [xdt_raw]))
      (if' [(call (dot (call (dot json "dumps") [xdt (kw "indent" 4)]) "encode") []) "!=" xdt_raw] [
        (call die [(str [(field d) "/LuaScripts.xdt does not round-trip; unknown format"])])
      ])
      (if' [(call md5 [xdf]) "!=" (index xdt (str "CMDataMD5"))] [
        (call die [(str [(field d) "/LuaScripts.xdf does not match its xdt; verify game files"])])
      ])
      (return (commas [xdf xdt (call md5 [xdt_raw])]))
    ];
  }))
  blank
  blank
  (def heal ({
    d,
    backup,
    xdf,
    old,
    want,
  }: {
    params = [d backup];
    body = [
      (assign xdf [d "/" (str "LuaScripts.xdf")])
      (assign old [backup "/" (str "LuaScripts.xdf")])
      (assign want (index (call (dot json "loads") [(call (dot [d "/" (str "LuaScripts.xdt")] "read_bytes") [])]) (str "CMDataMD5")))
      (if' [(call (dot old "exists") []) "and" (call md5 [(call (dot xdf "read_bytes") [])]) "!=" want "and" (call md5 [(call (dot old "read_bytes") [])]) "==" want] [
        (call write_atomic [xdf (call (dot old "read_bytes") [])])
      ])
    ];
  }))
  blank
  blank
  (def entry_bytes ({
    xdf,
    e,
    raw',
  }: {
    params = [xdf e];
    body = [
      (assign raw' (index xdf (slice (index e (str "CEOffset")) [(index e (str "CEOffset")) "+" (index e (str "CECSize"))])))
      (if' [(index e (str "CECSize")) "!=" (index e (str "CESize"))] [
        (call die [(str [(field (index e (sq "CEName"))) " is compressed; only stored entries can be modded"])])
      ])
      (return raw')
    ];
  }))
  blank
  blank
  (def lua_bytes ({b}: {
    params = [b];
    body = [
      (return [(sq "\"") "+" (call (dot (str "") "join") [(gen ({c}: [(str ["\\\\" (spec c "03d")]) (compFor c b)]))]) "+" (sq "\"")])
    ];
  }))
  blank
  blank
  (def wrap ({
    luajit,
    entry,
    orig,
    wrapper,
    src,
    t,
    name,
  }: {
    params = [luajit entry orig wrapper];
    body = [
      (assign src (hang (rows [(str "return (function(...)\\n") ["+" (call (dot (call Path [wrapper]) "read_text") [])] ["+" (str ["\\nend)(assert(load(" (field (call lua_bytes [orig])) ", " (field (call lua_bytes [(call (dot [(sq "@") "+" entry] "encode") [])])) ")), ...)\\n"])]])))
      (with' [(as (call (dot tempfile "TemporaryDirectory") []) t)] [
        (assign name (dot (call Path [entry]) "name"))
        (call (dot [(call Path [t]) "/" name] "write_text") [src])
        (call (dot subprocess "run") [(list [luajit (str "-b") (str "-g") name (str "out.luac")]) (kw "cwd" t) (kw "check" true)])
        (return (call (dot [(call Path [t]) "/" (str "out.luac")] "read_bytes") []))
      ])
    ];
  }))
  blank
  blank
  (def patched_entries ({
    xdf,
    xdt,
    mods,
    luajit,
    by_name,
    out,
    m,
    e,
    data,
    ed,
    old,
    new,
    off,
  }: {
    params = [xdf xdt mods luajit];
    body = [
      (assign by_name (dictComp ({e}: [(pair (index e (str "CEName")) e) (compFor e (index xdt (str "CMList")))])))
      (assign out (dict []))
      (for m mods [
        (assign e (call (dot by_name "get") [(index m (str "entry"))]))
        (if' [e "is" None] [
          (call die [(str [(field (index m (sq "name"))) ": entry " (field (index m (sq "entry"))) " missing; game updated, re-pin"])])
        ])
        (assign data [(call (dot out "get") [(index m (str "entry"))]) "or" (call entry_bytes [xdf e])])
        (if' [(index m (str "entry")) "not in" out "and" (call md5 [data]) "!=" (index m (str "entryMD5"))] [
          (call die [(str [(field (index m (sq "name"))) ": " (field (index m (sq "entry"))) " changed (md5 " (field (call md5 [data])) "); game updated, re-pin"])])
        ])
        (ifElse [(str "wrapper") "in" m] [
            (assign data (call wrap [luajit (index m (str "entry")) data (index m (str "wrapper"))]))
          ] [
            (assign data (call bytearray [data]))
            (for ed (index m (str "edits")) [
              (assign (commas [old new off]) (commas [(call (dot bytes' "fromhex") [(index ed (str "old"))]) (call (dot bytes' "fromhex") [(index ed (str "new"))]) (index ed (str "offset"))]))
              (if' [(call len [old]) "!=" (call len [new]) "or" (index data (slice off [off "+" (call len [old])])) "!=" old] [
                (call die [(str [(field (index m (sq "name"))) ": bytes at " (field (index m (sq "entry"))) "+" (field off) " differ from pin"])])
              ])
              (assign (index data (slice off [off "+" (call len [old])])) new)
            ])
            (assign data (call bytes' [data]))
          ])
        (assign (index out (index m (str "entry"))) data)
      ])
      (return out)
    ];
  }))
  blank
  blank
  (def rebuild ({
    xdf,
    xdt,
    repl,
    eocd,
    n,
    cd_size,
    cd_off,
    cd,
    out,
    new_off,
    meta,
    p,
    nl,
    el,
    cl,
    name,
    lho,
    _,
    f,
    csize,
    start,
    data,
    new_cd,
    ln,
    r,
    cd_start,
    tail,
    new_xdt,
    e,
  }: {
    params = [xdf xdt repl];
    body = [
      (assign eocd (call (dot xdf "rfind") [(bytes (str "PK\\x05\\x06"))]))
      (assign (commas [n cd_size cd_off]) (call (dot struct "unpack") [(str "<HII") (index xdf (slice [eocd "+" 10] [eocd "+" 20]))]))
      (assign cd (index xdf (slice cd_off [cd_off "+" cd_size])))
      (assign out (call bytearray []))
      (assign new_off (dict []))
      (assign meta (dict []))
      (assign p 0)
      (while [p "<" (call len [cd])] [
        (assign (commas [nl el cl]) (call (dot struct "unpack") [(str "<HHH") (index cd (slice [p "+" 28] [p "+" 34]))]))
        (assign name (call (dot (index cd (slice [p "+" 46] [p "+" 46 "+" nl])) "decode") []))
        (assign lho (index (call (dot struct "unpack") [(str "<I") (index cd (slice [p "+" 42] [p "+" 46]))]) 0))
        (assign (index meta name) (tuple [p [46 "+" nl "+" el "+" cl] lho]))
        (augAssign p "+=" [46 "+" nl "+" el "+" cl])
      ])
      (if' [(call len [meta]) "!=" n] [
        (call die [(str "zip central directory count mismatch")])
      ])
      (for (commas [name (tuple [_ _ lho])]) (call sorted [
          (call (dot meta "items") [])
          (kw "key" (lambda ({kv}: {
            params = [kv];
            body = index (index kv 1) 2;
          })))
        ]) [
          (assign f (call bytearray [(index xdf (slice lho [lho "+" 30]))]))
          (assign (commas [nl el]) (call (dot struct "unpack") [(str "<HH") (index f (slice 26 30))]))
          (assign csize (index (call (dot struct "unpack") [(str "<I") (index f (slice 18 22))]) 0))
          (assign start [lho "+" 30 "+" nl "+" el])
          (assign data (index xdf (slice start [start "+" csize])))
          (if' [name "in" repl] [
            (assign data (index repl name))
            (call (dot struct "pack_into") [(str "<III") f 14 (call (dot zlib "crc32") [data]) (call len [data]) (call len [data])])
          ])
          (assign (index new_off name) (tuple [(call len [out]) [(call len [out]) "+" 30 "+" nl "+" el] f]))
          (augAssign out "+=" [f "+" (index xdf (slice [lho "+" 30] start)) "+" data])
        ])
      (assign new_cd (call bytearray []))
      (for (commas [name (tuple [p ln _])]) (call sorted [
          (call (dot meta "items") [])
          (kw "key" (lambda ({kv}: {
            params = [kv];
            body = index (index kv 1) 0;
          })))
        ]) [
          (assign r (call bytearray [(index cd (slice p [p "+" ln]))]))
          (assign (index r (slice 16 28)) (index (index (index new_off name) 2) (slice 14 26)))
          (call (dot struct "pack_into") [(str "<I") r 42 (index (index new_off name) 0)])
          (augAssign new_cd "+=" r)
        ])
      (assign cd_start (call len [out]))
      (augAssign out "+=" new_cd)
      (assign tail (call bytearray [(index xdf (slice eocd null))]))
      (call (dot struct "pack_into") [(str "<II") tail 12 (call len [new_cd]) cd_start])
      (augAssign out "+=" tail)
      (assign out (call bytes' [out]))
      (assign new_xdt (call (dot json "loads") [(call (dot json "dumps") [xdt])]))
      (for e (index new_xdt (str "CMList")) [
        (assign (index e (str "CEOffset")) (index (index new_off (index e (str "CEName"))) 1))
        (if' [(index e (str "CEName")) "in" repl] [
          (assign data (index repl (index e (str "CEName"))))
          (assign (commas [(index e (str "CEMD5")) (index e (str "CESize")) (index e (str "CECSize"))]) (commas [(call md5 [data]) (call len [data]) (call len [data])]))
        ])
      ])
      (assign (index new_xdt (str "CMDataLen")) (call len [out]))
      (assign (index new_xdt (str "CMDataMD5")) (call md5 [out]))
      (return (commas [out (call (dot (call (dot json "dumps") [new_xdt (kw "indent" 4)]) "encode") [])]))
    ];
  }))
  blank
  blank
  (def write_atomic ({
    path,
    data,
    tmp,
  }: {
    params = [path data];
    body = [
      (assign tmp (call (dot path "with_name") [[(dot path "name") "+" (str ".finix-tmp")]]))
      (call (dot tmp "write_bytes") [data])
      (if' (call (dot path "exists") []) [
        (call (dot shutil "copymode") [path tmp])
      ])
      (call (dot os "replace") [tmp path])
    ];
  }))
  blank
  blank
  (def install ({
    d,
    xdf,
    xdt_raw,
    ver,
    prefix,
  }: {
    params = [d xdf xdt_raw];
    body = [
      (call write_atomic [[d "/" (str "LuaScripts.xdf")] xdf])
      (call write_atomic [[d "/" (str "LuaScripts.xdt")] xdt_raw])
      (assign ver [d "/" (str "LuaCacheVer.txt")])
      (if' (call (dot ver "exists") []) [
        (assign prefix (index (call (dot (call (dot ver "read_text") []) "split") [(str ",")]) 0))
        (call write_atomic [ver (call (dot (str [(field prefix) "," (field (call len [xdt_raw])) "," (field (call md5 [xdt_raw]))]) "encode") [])])
      ])
    ];
  }))
  blank
  blank
  (def main ({
    settings,
    mods,
    game,
    state_dir,
    cmdline,
    state_file,
    state,
    changed,
    rel,
    d,
    backup,
    _,
    cur_xdt_md5,
    ours,
    f,
    xdf,
    xdt,
    new_xdf,
    new_xdt,
  }: {
    params = [];
    body = [
      (assign settings (call (dot json "loads") [(call (dot (call Path [(index (dot sys "argv") 1)]) "read_text") [])]))
      (assign mods (index settings (str "mods")))
      (assign game (call Path [(index settings (str "gameDirectory"))]))
      (assign state_dir [game "/" (str ".finix-aniimo")])
      (if' (not (call (dot [game "/" (str "Aniimo.exe")] "exists") [])) [
        (if' [mods "or" (call (dot state_dir "exists") [])] [
          (call die [(str [(field game) " has no Aniimo.exe; skipped"])])
        ])
        (return null)
      ])
      (for cmdline (call (dot (call Path [(str "/proc")]) "glob") [(str "[0-9]*/cmdline")]) [
        (try [
            (if' [(bytes (str "Aniimo.exe")) "in" (call (dot cmdline "read_bytes") [])] [
              (call die [(str "Aniimo is running; skipped")])
            ])
          ] [
            (except OSError [
              pass
            ])
          ])
      ])
      (assign state_file [state_dir "/" (str "state.json")])
      (assign state (ternary (call (dot json "loads") [(call (dot state_file "read_text") [])]) (call (dot state_file "exists") []) (dict [])))
      (assign changed (dict []))
      (for rel LUA_DIRS [
        (assign d [game "/" rel])
        (if' (not (call (dot [d "/" (str "LuaScripts.xdt")] "exists") [])) [
          continue
        ])
        (assign backup [state_dir "/" (call (dot rel "replace") [(str "/") (str "_")])])
        (call heal [d backup])
        (assign (commas [_ _ cur_xdt_md5]) (call read_dir [d]))
        (assign ours [(call (dot state "get") [rel]) "==" cur_xdt_md5])
        (if' (not mods) [
          (if' ours [
            (for f FILES [
              (if' (call (dot [backup "/" f] "exists") []) [
                (call write_atomic [[d "/" f] (call (dot [backup "/" f] "read_bytes") [])])
              ])
            ])
            (assign (index changed rel) (str "vanilla"))
          ])
          (call (dot state "pop") [rel None])
          continue
        ])
        (if' (not ours) [
          (call (dot shutil "rmtree") [backup (kw "ignore_errors" true)])
          (call (dot backup "mkdir") [(kw "parents" true)])
          (for f FILES [
            (if' (call (dot [d "/" f] "exists") []) [
              (call (dot shutil "copy2") [[d "/" f] [backup "/" f]])
            ])
          ])
        ])
        (assign (commas [xdf xdt _]) (call read_dir [backup]))
        (assign (commas [new_xdf new_xdt]) (call rebuild [xdf xdt (call patched_entries [xdf xdt mods (call (dot settings "get") [(str "luajit")])])]))
        (if' [(call md5 [new_xdt]) "!=" cur_xdt_md5] [
          (call install [d new_xdf new_xdt])
          (assign (index changed rel) (listComp ({m}: [(index m (str "name")) (compFor m mods)])))
        ])
        (assign (index state rel) (call md5 [new_xdt]))
      ])
      (ifElse state [
          (call (dot state_dir "mkdir") [(kw "exist_ok" true)])
          (call write_atomic [state_file (call (dot (call (dot json "dumps") [state (kw "indent" 2)]) "encode") [])])
        ] [
          (call (dot shutil "rmtree") [state_dir (kw "ignore_errors" true)])
        ])
      (if' changed [
        (call print [(call (dot json "dumps") [(dict [(pair (str "aniimo") changed)])])])
      ])
    ];
  }))
  blank
  blank
  (if' [__name__ "==" (str "__main__")] [
    (call main [])
  ])
])
