{
  FileNotFoundError,
  None,
  OSError,
  PermissionError,
  ProcessLookupError,
  RuntimeError,
  __doc__,
  __name__,
  aligned,
  all,
  as,
  assign,
  blank,
  call,
  commas,
  compFor,
  compIf,
  continue,
  def,
  default,
  dict,
  dictComp,
  dot,
  except,
  field,
  finally,
  for,
  from,
  gen,
  if',
  import',
  index,
  kw,
  list,
  list',
  listComp,
  not,
  pair,
  pass,
  print,
  raise,
  raw,
  return,
  reversed,
  rows,
  set',
  slice,
  sorted,
  sq,
  star,
  str,
  str',
  ternary,
  triple,
  try,
  tuple,
  while,
  with',
  ...
}: ({
  argparse,
  fcntl,
  hashlib,
  json,
  os,
  Path,
  shlex,
  shutil,
  subprocess,
  sys,
  tempfile,
  datetime,
  timezone,
  read_json,
  write_json,
  windows_path,
  digest,
  game_running,
  require_stopped,
  configure_loader,
  prepare,
  wine,
  install,
  disable,
  main,
  exc,
}: [
  (triple "Materialize pinned P4G mods; touch the Proton prefix only on explicit install.")
  blank
  (import' argparse)
  (import' fcntl)
  (import' hashlib)
  (import' json)
  (import' os)
  (from "pathlib" [Path])
  (import' shlex)
  (import' shutil)
  (import' subprocess)
  (import' sys)
  (import' tempfile)
  (from "datetime" [datetime timezone])
  blank
  (def read_json ({path}: {
    params = [path];
    body = [
      (return (call (dot json "loads") [(call (dot path "read_text") [(kw "encoding" (str "utf-8-sig"))])]))
    ];
  }))
  blank
  (def write_json ({
    path,
    data,
    temporary,
  }: {
    params = [path data];
    body = [
      (call (dot path "parent.mkdir") [(kw "parents" true) (kw "exist_ok" true)])
      (assign temporary (call (dot path "with_name") [[(dot path "name") "+" (str ".finix-new")]]))
      (call (dot temporary "write_text") [[(call (dot json "dumps") [data (kw "indent" 2)]) "+" (str "\\n")]])
      (call (dot temporary "replace") [path])
    ];
  }))
  blank
  (def windows_path ({path}: {
    params = [path];
    body = [
      (return [(str "Z:") "+" (call (dot (call str' [path]) "replace") [(str "/") (str "\\\\")])])
    ];
  }))
  blank
  (def digest ({
    path,
    source,
  }: {
    params = [path];
    body = [
      (with' [(as (call (dot path "open") [(str "rb")]) source)] [
        (return (call (dot (call (dot hashlib "file_digest") [source (str "sha256")]) "hexdigest") []))
      ])
    ];
  }))
  blank
  (def game_running ({process}: {
    params = [];
    body = [
      (for process (call (dot (call Path [(str "/proc")]) "glob") [(str "[0-9]*/comm")]) [
        (try [
            (if' [(call (dot (call (dot (call (dot process "read_text") []) "strip") []) "lower") []) "==" (str "p4g.exe")] [
              (return true)
            ])
          ] [
            (except (tuple [FileNotFoundError ProcessLookupError PermissionError]) [
              pass
            ])
          ])
      ])
      (return false)
    ];
  }))
  blank
  (def require_stopped {
    params = [];
    body = [
      (if' (call game_running []) [
        (raise (call RuntimeError [(str "P4G is running. Save and close it before installing or disabling mods.")]))
      ])
    ];
  })
  blank
  (def configure_loader ({
    root,
    game,
    enabled,
    final_root,
    app_file,
    app,
    mods,
    pending,
    checked,
    name,
  }: {
    params = [root game enabled (default final_root None)];
    body = [
      (assign app_file [root "/" (str "Apps/p4g.exe/AppConfig.json")])
      (assign app (call read_json [app_file]))
      (call (dot app "update") (aligned [(kw "AppLocation" (call windows_path [[game "/" (str "P4G.exe")]])) [(kw "WorkingDirectory" (call windows_path [game])) (kw "AutoInject" false) (kw "DontInject" false)]]))
      (if' [enabled "is not" None] [
        (assign (index app (str "EnabledMods")) enabled)
        (assign (index app (str "SortedMods")) [enabled "+" (listComp ({name}: [name (compFor name (call (dot app "get") [(str "SortedMods") (list [])])) (compIf [name "not in" enabled])]))])
      ])
      (assign mods (dictComp ({p}: (rows [(pair (index (call read_json [p]) (str "ModId")) (call read_json [p])) (compFor p (call (dot [root "/" (str "Mods")] "glob") [(str "*/ModConfig.json")]))]))))
      (assign (commas [pending checked]) (commas [(call list' [(index app (str "EnabledMods"))]) (call set' [])]))
      (while pending [
        (assign name (call (dot pending "pop") []))
        (if' [name "in" checked] [
          continue
        ])
        (if' [name "not in" mods] [
          (raise (call RuntimeError [(str ["Enabled mod or dependency absent from pinned pack: " (field name)])]))
        ])
        (call (dot checked "add") [name])
        (call (dot pending "extend") [(call (dot (index mods name) "get") [(str "ModDependencies") (list [])])])
      ])
      (call write_json [app_file app])
      (assign root [final_root "or" root])
      (return (dict (rows [(pair (str "LoaderPath64") (call windows_path [[root "/" (str "Loader/X64/Reloaded.Mod.Loader.dll")]])) (pair (str "LoaderPath32") (call windows_path [[root "/" (str "Loader/X86/Reloaded.Mod.Loader.dll")]])) (pair (str "LauncherPath") (call windows_path [[root "/" (str "Reloaded-II.exe")]])) (pair (str "Bootstrapper64Path") (call windows_path [[root "/" (str "Loader/X64/Bootstrapper/Reloaded.Mod.Loader.Bootstrapper.dll")]])) (pair (str "Bootstrapper32Path") (call windows_path [[root "/" (str "Loader/X86/Bootstrapper/Reloaded.Mod.Loader.Bootstrapper.dll")]])) (pair (str "ApplicationConfigDirectory") (call windows_path [[root "/" (str "Apps")]])) (pair (str "ModConfigDirectory") (call windows_path [[root "/" (str "Mods")]])) (pair (str "ModUserConfigDirectory") (call windows_path [[root "/" (str "User/Mods")]])) (pair (str "MiscConfigDirectory") (call windows_path [[root "/" (str "User/Misc")]])) (pair (str "PluginConfigDirectory") (call windows_path [[root "/" (str "Plugins")]])) (pair (str "UsePortableMode") true) (pair (str "FirstLaunch") false) (pair (str "ShowConsole") false) (pair (str "SkipWineLaunchWarning") true)])))
    ];
  }))
  blank
  (def prepare ({
    settings,
    state,
    payload,
    game,
    generation_settings,
    key,
    root,
    temporary,
    loader_config,
  }: {
    params = [settings state payload game];
    body = [
      (assign generation_settings (dictComp ({
        k,
        v,
      }: [(pair k v) (compFor (commas [k v]) (call (dot settings "items") [])) (compIf [k "!=" (str "prefixDirectory")])])))
      (assign key (index (call (dot (call (dot hashlib "sha256") [(call (dot (call (dot json "dumps") [generation_settings (kw "sort_keys" true)]) "encode") [])]) "hexdigest") []) (slice null 16)))
      (assign root [state "/" (str "generations") "/" key])
      (if' (not (call (dot root "exists") [])) [
        (call (dot root "parent.mkdir") [(kw "parents" true) (kw "exist_ok" true)])
        (assign temporary (call Path [(call (dot tempfile "mkdtemp") [(kw "prefix" (str ".prepare-")) (kw "dir" (dot root "parent"))])]))
        (try [
            (call (dot subprocess "run") [(list [(str "cp") (str "-r") (str "--reflink=auto") [(call str' [[payload "/" (str "Reloaded")]]) "+" (str "/.")] (call str' [temporary])]) (kw "check" true)])
            (call (dot subprocess "run") [(list [(str "chmod") (str "-R") (str "u+w") (call str' [temporary])]) (kw "check" true)])
            (assign loader_config (call configure_loader [temporary game (index settings (str "enabledMods")) (kw "final_root" root)]))
            (call write_json [[temporary "/" (str "ReloadedII.json")] loader_config])
            (call (dot [temporary "/" (str "portable.txt")] "touch") [])
            (call (dot temporary "rename") [root])
          ] [
            (finally [
              (if' (call (dot temporary "exists") []) [
                (call (dot shutil "rmtree") [temporary])
              ])
            ])
          ])
      ])
      (assign loader_config (call read_json [[root "/" (str "ReloadedII.json")]]))
      (call print [(str ["Prepared CEP 13.99.4 + Reloaded II 1.30.3: " (field root)]) (kw "flush" true)])
      (return (commas [root loader_config]))
    ];
  }))
  blank
  (def wine ({
    settings,
    arguments,
    log,
    env,
    command,
    result,
  }: {
    params = [settings arguments log];
    body = [
      (assign env [(dot os "environ") "|" (dict [(pair (str "STEAM_DIR") (index settings (str "steamDirectory"))) (pair (str "WINEDEBUG") (str "-all"))])])
      (assign command (aligned [[(sq "test \"$WINEPREFIX\" -ef ") "+" (call (dot shlex "quote") [(index settings (str "prefixDirectory"))])] ["+" (sq " || { echo \"Protontricks selected a different prefix\" >&2; exit 1; }; ")] ["+" (sq "\"$WINE\" ") "+" (call (dot shlex "join") [(gen ({arg}: [(call str' [arg]) (compFor arg arguments)]))])]]))
      (assign result (call (dot subprocess "run") (aligned [(list [(str "protontricks") (str "-c") command (str "1113000")]) [(kw "env" env) (kw "stdout" log) (kw "stderr" (dot subprocess "STDOUT"))]])))
      (if' [(dot result "returncode") "not in" (tuple [0 194])] [
        (raise (call RuntimeError [(str ["Proton setup exited " (field (dot result "returncode")) "; see " (field (dot log "name"))])]))
      ])
    ];
  }))
  blank
  (def install ({
    settings,
    state,
    payload,
    game,
    prefix,
    root,
    loader_config,
    manifest_path,
    previous,
    files,
    name,
    source,
    target,
    timestamp,
    backup,
    marker,
    runtime_files,
    wanted,
    installed,
    dotnet_present,
    log_path,
    log,
    installer,
    config_path,
    existing,
    key,
    dll,
    pending_manifest,
    temporary,
  }: {
    params = [settings state payload game prefix root loader_config];
    body = [
      (call require_stopped [])
      (assign manifest_path [game "/" (str ".finix-p4g.json")])
      (assign previous (ternary (call read_json [manifest_path]) (call (dot manifest_path "exists") []) (dict [(pair (str "files") (dict []))])))
      (assign files (dict (rows [(pair (str "version.dll") [payload "/" (str "Asi/ASILoader64.dll")]) (pair (str "Reloaded.Mod.Loader.Bootstrapper.asi") [root "/" (str "Loader/X64/Bootstrapper/Reloaded.Mod.Loader.Bootstrapper.dll")])])))
      (for (commas [name source]) (call (dot files "items") []) [
        (assign target [game "/" name])
        (if' [(call (dot target "exists") []) "and" (call digest [target]) "not in" (tuple [(call digest [source]) (call (dot (index previous (str "files")) "get") [name])])] [
          (raise (call RuntimeError [(str ["Refusing to replace an unmanaged or modified file: " (field target)])]))
        ])
      ])
      (assign timestamp (call (dot (call (dot datetime "now") [(dot timezone "utc")]) "strftime") [(str "%Y%m%dT%H%M%S.%fZ")]))
      (assign backup [state "/" (str "backups") "/" timestamp])
      (call (dot backup "mkdir") [(kw "parents" true)])
      (call print [(str ["Backing up Proton prefix to " (field [backup "/" (sq "pfx")])]) (kw "flush" true)])
      (call (dot subprocess "run") [(list [(str "cp") (str "-a") (str "--reflink=auto") (call str' [prefix]) (call str' [[backup "/" (str "pfx")]])]) (kw "check" true)])
      (for name (list [(star files) (str ".finix-p4g.json")]) [
        (assign source [game "/" name])
        (if' (call (dot source "exists") []) [
          (assign target [backup "/" (str "game") "/" name])
          (call (dot target "parent.mkdir") [(kw "parents" true) (kw "exist_ok" true)])
          (call (dot shutil "copy2") [source target])
        ])
      ])
      (assign marker [prefix "/" (str ".finix-p4g-runtimes.json")])
      (assign runtime_files (call sorted [(call (dot [payload "/" (str "Setup")] "glob") [(str "*.exe")])]))
      (assign wanted (dictComp ({p}: [(pair (dot p "name") (call digest [p])) (compFor p runtime_files)])))
      (assign installed (ternary (call read_json [marker]) (call (dot marker "exists") []) None))
      (assign dotnet_present (call all [(gen ({directory}: (rows [(call (dot (rows [[prefix "/" (str "drive_c") "/" directory "/"] (str "dotnet/shared/Microsoft.WindowsDesktop.App/9.0.20")]) "is_dir") []) (compFor directory (tuple [(str "Program Files") (str "Program Files (x86)")]))])))]))
      (assign log_path [backup "/" (str "setup.log")])
      (with' [(as (call (dot log_path "open") [(str "w")]) log)] [
        (if' [installed "!=" wanted "or" (not dotnet_present)] [
          (for installer runtime_files [
            (call require_stopped [])
            (call print [(str ["Installing " (field (dot installer "name")) " (log: " (field log_path) ")"]) (kw "flush" true)])
            (call wine [settings (list [(call str' [installer]) (str "/install") (str "/quiet") (str "/norestart")]) log])
          ])
          (call write_json [marker wanted])
        ])
        (call require_stopped [])
        (assign config_path [prefix "/" (str "drive_c/users/steamuser/AppData/Roaming/Reloaded-Mod-Loader-II/ReloadedII.json")])
        (assign existing (ternary (call read_json [config_path]) (call (dot config_path "exists") []) (dict [])))
        (call write_json [config_path [existing "|" loader_config]])
        (assign key (raw (str "HKCU\\Software\\Wine\\AppDefaults\\P4G.exe\\DllOverrides")))
        (for dll (tuple [(str "version") (str "msvcp140") (str "msvcp140_1") (str "msvcp140_2") (str "vcruntime140") (str "vcruntime140_1")]) [
          (call wine [settings (list [(str "reg") (str "add") key (str "/v") dll (str "/t") (str "REG_SZ") (str "/d") (str "native,builtin") (str "/f")]) log])
        ])
      ])
      (call require_stopped [])
      (assign pending_manifest [game "/" (str ".finix-p4g.pending.json")])
      (call write_json [
        pending_manifest
        (dict (aligned [
          (pair (str "files") (dictComp ({
            n,
            p,
          }: [(pair n (call digest [p])) (compFor (commas [n p]) (call (dot files "items") []))])))
          [(pair (str "generation") (call str' [root])) (pair (str "backup") (call str' [backup]))]
        ]))
      ])
      (for name (call reversed [files]) [
        (assign target [game "/" name])
        (call (dot target "parent.mkdir") [(kw "parents" true) (kw "exist_ok" true)])
        (assign temporary (call (dot target "with_name") [[(dot target "name") "+" (str ".finix-new")]]))
        (call (dot shutil "copyfile") [(index files name) temporary])
        (call (dot temporary "replace") [target])
      ])
      (call (dot pending_manifest "replace") [manifest_path])
      (call print [(str "Installed. Launch Persona 4 Golden through its normal Steam entry.")])
    ];
  }))
  blank
  (def disable ({
    game,
    path,
    manifest,
    name,
    expected,
    target,
  }: {
    params = [game];
    body = [
      (call require_stopped [])
      (assign path [game "/" (str ".finix-p4g.json")])
      (if' (not (call (dot path "exists") [])) [
        (raise (call RuntimeError [(str "No finix-managed P4G installation found.")]))
      ])
      (assign manifest (call read_json [path]))
      (for (commas [name expected]) (call (dot (index manifest (str "files")) "items") []) [
        (assign target [game "/" name])
        (if' [(call (dot target "exists") []) "and" (call digest [target]) "!=" expected] [
          (raise (call RuntimeError [(str ["Refusing to remove a modified file: " (field target)])]))
        ])
      ])
      (for name (index manifest (str "files")) [
        (call (dot [game "/" name] "unlink") [(kw "missing_ok" true)])
      ])
      (call (dot path "unlink") [])
      (call print [(str "Mod injection disabled. Steam will launch vanilla P4G; backups and mod settings are retained.")])
    ];
  }))
  blank
  (def main ({
    parser,
    args,
    settings,
    state,
    payload,
    game,
    prefix,
    lock,
    root,
    loader_config,
  }: {
    params = [];
    body = [
      (assign parser (call (dot argparse "ArgumentParser") [(kw "description" __doc__)]))
      (call (dot parser "add_argument") [(str "settings") (kw "type" Path)])
      (call (dot parser "add_argument") [(str "action") (kw "choices" (list [(str "prepare") (str "install") (str "disable") (str "status")])) (kw "nargs" (str "?")) (kw "default" (str "install"))])
      (assign args (call (dot parser "parse_args") []))
      (assign settings (call read_json [(dot args "settings")]))
      (assign (commas [state payload game]) (gen ({k}: [(call Path [(index settings k)]) (compFor k (tuple [(str "stateDirectory") (str "payload") (str "gameDirectory")]))])))
      (assign prefix (call Path [(index settings (str "prefixDirectory"))]))
      (if' [(dot args "action") "==" (str "status")] [
        (call print [(call (dot json "dumps") [(dict (aligned [[(pair (str "running") (call game_running [])) (pair (str "installed") (call (dot [game "/" (sq ".finix-p4g.json")] "exists") []))] [(pair (str "state") (call str' [state])) (pair (str "prefix") (call str' [prefix]))]])) (kw "indent" 2)])])
        (return null)
      ])
      (if' [(call (dot os "geteuid") []) "==" 0] [
        (raise (call RuntimeError [(str "Run p4g-setup as your Steam user, without sudo.")]))
      ])
      (if' [(dot args "action") "in" (tuple [(str "install") (str "disable")])] [
        (call require_stopped [])
      ])
      (if' [(not (call (dot [game "/" (str "P4G.exe")] "is_file") [])) "or" (not (call (dot [prefix "/" (str "system.reg")] "is_file") []))] [
        (raise (call RuntimeError [(str "Install P4G in Steam and launch it once before setup.")]))
      ])
      (call (dot state "mkdir") [(kw "parents" true) (kw "exist_ok" true)])
      (with' [(as (call (dot [state "/" (str ".setup.lock")] "open") [(str "w")]) lock)] [
        (call (dot fcntl "flock") [lock [(dot fcntl "LOCK_EX") "|" (dot fcntl "LOCK_NB")]])
        (if' [(dot args "action") "==" (str "disable")] [
          (call disable [game])
          (return null)
        ])
        (assign (commas [root loader_config]) (call prepare [settings state payload game]))
        (if' [(dot args "action") "==" (str "install")] [
          (call install [settings state payload game prefix root loader_config])
        ])
      ])
    ];
  }))
  blank
  (if' [__name__ "==" (str "__main__")] [
    (try [
        (call main [])
      ] [
        (except (as (tuple [RuntimeError OSError (dot json "JSONDecodeError") (dot subprocess "CalledProcessError")]) exc) [
          (call (dot sys "exit") [(str ["p4g-setup: " (field exc)])])
        ])
      ])
  ])
])
