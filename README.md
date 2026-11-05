# Repository layout

This repository configures y0usaf's machines on finix: it owns system integration and user configuration, not application implementations. Headlong operations live in `~/dev/developing/headlong-ops`. A project that stays external comes in as a flake input. Keep runners, application patches, reusable skills and their tests with the module or project that owns them. Runtime state and credentials stay outside the source tree and the Nix store. Don't create root-level `nix/`, `tests/` or `previews/` directories.

`flake.nix` is the whole configuration: `strictix merge . --entry flake.nix --out flake.nix --expand nixFiles` collapsed the tree into it, one let binding per file under its `outputs`, named by the fewest trailing parts of its path that no other binding and no identifier in the code shares (`bar_data` for `modules/desktop/session/tomoe/lisp/bar.data.nix`, `core_packages` for `modules/core/packages.nix`, since the code says `packages`), with `merge_manifest` recording each binding's path and the expanded `nixFiles` calls. The paths below are those manifest paths; `strictix split . --merged flake.nix` writes the tree back byte for byte, and `nix run .#lint` lints each binding at its path. `modules/outputs.nix` builds every output with let bindings and plain functions. No module system runs at flake level.

A host is a list of modules, and the `hosts` attrset in `modules/outputs.nix` holds each host's list. Every host loads `modules/finix/common.nix`, `diagnostics.nix` and `sudo.nix`: the settings all hosts share, boot diagnostics and sudo. The graphical hosts load every `.nix` file under the graphical roots (`core`, `desktop`, `dev`, `gaming`, `shell`, `tools`, `user-services` and `hosts/common`), so each of those files is a module; the server names its modules one by one: its role in `modules/server/`, its host files and a few program modules. `modules/hosts/common/` is the graphical role. Its system layer, `modules/finix/desktop/`, is imported from `graphical.nix` instead of loaded as a root. Roots load in path order, and a list option merges in load order, so moving a module moves its packages, kernel modules and udev rules within those lists and changes the build.

Loading a module turns it on. A module declares an option only when the hosts that load it need different values, or when three or more modules read the value. Anything else is written where it is used, and a helper one module uses is a let binding in that module.

A program's module owns its packages, settings, dotfiles and persisted paths, and decides from hardware facts such as `hardware.nvidia.enable`, never from the hostname. A program that needs only its package is a line in its category's package list: `core/packages.nix`, `desktop/packages.nix`, `dev/packages.nix`, `tools/packages.nix`, `gaming/core.nix` or `server/packages.nix`. `tools/tmux.nix` stays a module of its own because the server loads it by name. Persisted paths no module owns go in `modules/hosts/common/persist.nix` when both graphical hosts keep them, and in the host's `config.nix` when only that host does. A module writes the user's dotfiles as `user.files."<path under home>"` and the home paths it keeps as `user.persist.directories` (and `.files`, `.directorySources`); `finix/common.nix` passes every definition on, in module order, to `manzil.users.<user>.files` and `finix.persistence.allowlist.users.<user>`, which no other module defines.

`dev/ai/pi/default.nix` holds the shared model catalog. Omp uses `ompThinkingLevel = "auto"` and the DeepSeek V4.1 Flash 1017 Fast `judgeModel` for per-prompt effort selection. `dev/ai/omp/default.nix` applies these on the host, and `dev/ai/omp/box.nix` applies them in the microVM. Pi keeps its separate `defaultThinkingLevel = "xhigh"`; the advisor stays Sol at high. Boar (`dev/ai/boar.nix`) takes a gateway model's id, name, inputs, reasoning flag and cost from the catalog and sets its own context window and output limit.

Each host directory under `modules/hosts/` holds what is true of that machine alone, in two files beside its keys and other data. `hardware-config.nix` holds facts about the machine: disks, btrfs subvolumes and mount options, boot, kernel and initrd modules, firmware, GPU and displays. `config.nix` holds the host's choices: hostname, open ports, host-only persisted paths, services, and where it departs from its role. `modules/hosts/shared.nix` holds the machinery the hosts share, a btrfs mount builder, the file systems every host has (a tmpfs root, the vfat ESP and, given its size, a tmpfs `/tmp`, around the host's own mounts) and the nftables ruleset, which each host calls with its own values; hosts import it, and no host list loads it. `modules/hosts/android-phone/` is the nix-on-droid phone.

`modules/hosts/steam-frame/` is the Steam Frame, which runs NixOS, not finix. The external steam-frame-nixos project supplies the Frame itself as `nixosModules.default`, pinned as the non-flake input `steam-frame-nixos`; `nix flake update steam-frame-nixos` moves it, and `FRAME_REPO=<checkout>` deploys a local checkout instead. Everything personal about the Frame lives here. `config.nix` holds the host's choices: the SSH keys, the storage pool's UUID, the project's optional WiVRn client and framecorder, Stremio in Steam's FHS environment, the Beat Saber mods, `tools/git.nix` and `tools/tmux.nix`, and files linked with manzil; `bolo.nix` runs bolo on the CPU and fetches its speech model at boot into the big home partition, out of the small root (the model's address and file hashes and bolo's vocabulary are those of `desktop/apps/bolo.data.nix`, which the desktop module reads too); `mado.nix` runs mado-view whenever SteamVR runs, so the headset shows the PC's mado stream. `deploy.nix` builds `finix-frame-deploy`, which builds a NixOS system from the project's nixpkgs and module, manzil's NixOS module, `config.nix`, manzil's static aarch64 linker (cross-built on this machine) and bolo's and mado's aarch64 packages (`--impure`), then copies and switches the Frame over ssh. The rest of the closure builds under the qemu aarch64 binfmt handler; `finix-frame-deploy` names the command that registers it when it is missing.

`omarchy.nix` runs the desktop layer of Omarchy 4.0.4 (Hyprland and its QuickShell shell) as a SteamVR overlay: a nested Hyprland is a client of a second gamescope (`--backend openvr --expose-wayland`), and Aquamarine needs the three fixes in `omarchy/aquamarine-gamescope.patch`. Nothing starts it: `systemctl --user start omarchy` over SSH does, and it stops whenever SteamVR restarts. Its `ExecStopPost` removes what Hyprland and Quickshell leave in `$XDG_RUNTIME_DIR`; Omarchy's own state stays in the home. Its menu actions act on the host's services. Quickshell 0.3.1 ignores a NetworkManager profile without `mode=infrastructure`, which steam-frame-nixos's `tools/wifi-from-nm.py` writes. On the Frame it drew its bar, menu and a terminal and ran 15 minutes on the live session without an error; how it looks in the headset, shortcut keys, theme switching and the audio, Bluetooth and power actions are unverified, and screen recording, the screensaver and the lock screen are unavailable.

`beat-saber.nix` installs BeatMods mods into Beat Saber by name, from `frame.beatSaber.mods` in `config.nix`; BSIPA and each mod's dependencies come along. `beat-saber/beatmods.data.nix` pins every verified mod for one game version with hashes; `nix run .#beat-saber-lock -- <game version>` prints a fresh lock as Nix data to replace it with, and a name not in it fails the build. BeatMods has mods for 1.44.1, so the game needs Steam's `1.44.1_legacy` branch, and its launch options must be `/run/current-system/sw/bin/beat-saber-mods %command%`. Each launch copies the declared set into the game folder, deletes files of the previous set, and starts the game with `WINEDLLOVERRIDES=winhttp=n,b` and `--no-yeet`. `.nix-mods/` in the game folder holds the unpatched `UnityEngine.CoreModule.dll` BSIPA patches and the installed file list; a file of yours a mod replaces is kept there too and comes back when the mod goes. An empty list, or a game version the mods aren't for, restores the game on the next launch, keeping `UserData`, `Logs` and your own files. Problems go to Steam's journal (`journalctl --user -u steam | grep beat-saber-mods`). Under Proton 11.0 (ARM64) the mods load and BeatSaverDownloader downloads songs, but starting any song fails: InvalidCastExceptions in Zenject injection and MonoMod's struct-return glue freeze the level.

`modules/finix/sudo.nix` configures sudo itself and takes only the privileges provider from finix's sudo module. Leave `programs.sudo.enable` off: it also installs the non-setuid sudo binary, which shadowed the `/run/wrappers/bin/sudo` wrapper on PATH (c9a60e8c).

`modules/finix/tailscale.nix` runs tailscaled on the server and, through `graphical.nix`, on the graphical hosts. It makes openresolv the owner of `/etc/resolv.conf` so that tailscaled (openresolv mode), dhcpcd and NetworkManager share it: tailscaled goes first with MagicDNS, DHCP servers follow and public servers come last with a one-second timeout, so DNS survives tailscaled being down. tailscaled starts after the `resolvconf` task because it picks its DNS mode from the header that task writes. Hosts name each other by MagicDNS. `tailnet.addresses` keeps the addresses of the places that need one: the `rescue` and `rescue-root` ssh hosts, which must work when DNS is broken, paseo's listen bind and the server's hosts aliases.

The configuration reads no file but Nix, except the lockfiles npm and Cargo write (`desktop/apps/stremio-Cargo.lock`, `dev/work/vercel/package-lock.json` and firstmate's five `*-axi.package-lock.json`), which stay files at their paths beside `flake.nix`, where merge leaves them, so `npm install` and `cargo update` rewrite them in place. Data a module reads lives in a `.data.nix` beside it and is rendered by a generator in `modules/generators.nix`, byte-identical to the file it replaced (GLSL, read for meaning, renders a reformatted file of the same program; below). Data formats are structured: JSON values (an object lists its key order in `__keys` only when that differs from `builtins.attrNames`), TOML groups, INI and `key=value` groups, an XML element tree, SSH key fields, PEM base64 blocks and gitignore patterns. Lisp, shell, Luau, VBScript, patches, markdown, GLSL, Lua, Python, JavaScript and TypeScript are syntax trees (below). Eleven files are text instead, a `.data.nix` holding the file as one Nix string, rendered as it is: tomoe's seven shaders (`desktop/session/tomoe/shaders/`), whose syntax trees render a reformatted program and so other bytes (they stay on the `lean/rules` branch), and four files the importers refuse, the secrets extension's `omp-secret.ts`, `secrets.ts` and `store.ts` (`strictix import ts` stops at a prefix increment, a tuple type and a generic function) and Agent Tabs' `window.luau` (`strictix import luau` stops at a `local` without a value). A file passed by path comes from `generators.sourceFile`, whose store path is the one the file had; `generators.sourceDir` builds the optchat directory from its files.

### Code as syntax trees

`generators.doc` is a Wadler/Leijen pretty-printer. A document is a string (text; it may hold newlines, which reset the column), a list (concatenation), `line` (a space, or a newline when its group breaks), `softline` (nothing, or a newline), `hardline`, `nest n d` (d's newlines indent n further), `align d` (d's newlines indent to the current column) or `group d` (d flat when it fits the width, else broken). `doc.render width d` lays it out; a `null` width never breaks a group; `doc.renderWith unit width d` writes each column of indentation as `unit` (a tab for TypeScript) instead of a space. Layout is a `builtins.genericClosure` stack machine, one step per document node with the column forced at each step, so neither recursion depth nor thunk chains grow with the file; indentation is written lazily, so blank lines carry no trailing spaces. Columns count bytes. Tomoe's `deck.lisp` (400 lines, 20 KB, the largest converted file) renders in 0.03 s and 12 MB of allocation; 4000 lines take 0.27 s and 130 MB. Tomoe's `hex-spiral.glsl` (165 lines, 5.5 KB) renders in 0.04 s and 18 MB.

A language is `generators.<language>`: constructor functions and `render`, a function from a list of top-level nodes to text, built on `generators.doc`. Nodes are Nix values: a plain list or string where the language's own shape is a list of words (a Lisp list, a shell command or word), otherwise a one-attribute set made by a constructor (`str "x"` is `{str = "x";}`), so a printer dispatches on the node's kind. Comments and blank lines are nodes (`comment`, `blank`); nothing in a file is lost, except in GLSL, whose tree keeps meaning only (below). The printer owns the layout the language's style decides; the tree records only what it cannot decide, with names every language shares: `rows` (written over several lines), `inline` (written on one line), `at n` (an indent the rules do not give) and `blank`; `wrap` asks for a width-aware layout instead. A data file is a function of the constructors it uses, rendered with `generators.<language>.render (import ./x.data.nix generators.<language>)`.

Lisp (`generators.lisp`): a list is a Nix list and every name a Nix variable. A form that binds names is a lambda whose formals are exactly the names it binds: the file (its `defun`, `defmacro`, `defvar`, `defparameter` and `defconstant` names); `defun`, `defmacro`, `lambda` and `define-extension` parameters and a local function's; `let`, `let*`, `flet`, `labels`, `macrolet`, `destructuring-bind`, `multiple-value-bind`, `dolist`, `dotimes` and the `with-open-file` and string streams; a `loop`'s `for`, `as`, `with` and `into` variables. `render` calls it with name nodes and throws when a formal is not bound by its form. Every other symbol is an attribute of `generators.lisp`, from fixed lists of the Common Lisp symbols, the `loop` keywords, tomoe's and ekko's API and the names one tomoe file or the Nix around it defines for another (`hud--c`, `+gap+`), taken as a data-file formal, so a misspelt name is an evaluation error. A name that is a Nix keyword, a constructor or such a global is spelled with a trailing `'` (`let'`, `char'`, a variable `list'` beside the function `list`), as is a rebinding its own initializer reads (`(let ((m (copy-list m))) ...)` binds `m'`); `render` drops it. `+x+` and `*x*` are `constant x` and `special x`; `&key`, `&optional`, `&rest` and a dotted list's `.` are `and-key`, `and-optional`, `and-rest` and `dot`; the operators no Nix name can spell (`+`, `1-`, `<=`, `char=`, `let*`, `list*`, `string=` and the rest of `operators`) are strings, the only bare strings a tree holds. A keyword is `kw "name"`, `#:name` is `uninterned "name"`, a character `char "Space"`; integers and floats are Nix numbers, `1/2` is `ratio 1 2`, `1d0` `double 1` and `#xF00ED` `hex 983277`; `str` is a string literal, and `quote`, `quasi`, `unquote`, `splice` and `function` the reader prefixes `'`, `` ` ``, `,`, `,@` and `#'`. A list without `rows` prints on one line. `rows [ ... ]` holds one row per source line: a list of the items on that line, or one item that is not a plain list. Rows after the first indent by Emacs' Common Lisp rules: the body of `defun`, `let`, `when` and the other forms in `bodies` by 2 and their distinguished arguments by 4, the local functions of `flet`, `labels` and `macrolet` like a `defun`, a call's arguments under its first argument, `cond` clauses by 2, anything else under the head. From `tomoe/lisp/deck.data.nix`, abridged:

```nix
{and, cdr, constant, defparameter, defun, getf, kw, let', quote, rows, str, ...}: ({
  deck--entry,
  deck--fronts,
  deck--side-of,
  deck--column-commands,
}: [
  ({state}: [defun deck--fronts [state] [getf state (kw "fronts")]])
  ({
    state,
    id,
  }:
    rows [
      [defun deck--side-of [state id]]
      ({entry}: [let' [[entry [deck--entry [getf state (kw "columns")] id]]] [and entry [cdr entry]]])
    ])
  (rows [
    [defparameter (constant deck--column-commands)]
    (quote [(str "focus-left") (str "focus-right") (str "swap-columns")])
  ])
])
```

`strictix import lisp` prints this form, resolving a list's head in the function namespace and other symbols as variables first, so a variable and a function of one name stay two bindings, and refuses a symbol nothing binds that is no global, a name Nix cannot spell, a package-qualified symbol and reader syntax the printer does not write.

Shell (`generators.shell`): a data file is a function of the constructors and shell globals it uses whose value is the script, a lambda of the names the script declares (a plain list when it declares none). Bash scopes a name to the script or to a function, so those are the only lambdas: the script's binds its function names and every variable it sets (`assign`, `for`, `read`) outside a function or inside one without `local`, and a function body is a lambda of the names it declares `local` (`fn covers ({base}: inline [ ... ])`); the generator calls each with name nodes and throws when a formal is not declared in its block. A name written as a word is the name (`local x`, `read -r path mode`, a call of the script's own function); its value is `var x` (`$x`, braced only where the next character would join it), and `default x w`, `required x w`, `dropPrefix`, `dropLongestPrefix`, `dropSuffix`, `dropLongestSuffix` and `elements x` are `${x:-w}`, `${x:?w}`, `${x#w}`, `${x##w}`, `${x%w}`, `${x%%w}` and `${x[@]}`. `var 1` is a positional parameter; `args`, `argsJoined`, `argCount` and `exitStatus` are `$@`, `$*`, `$#` and `$?`; the environment variables a script reads (`HOME`, `IFS`, `PATH`, `XDG_STATE_HOME`, from a fixed list) are attributes of `generators.shell`, so a misspelt name is a missing argument. A name that is a Nix keyword or an attribute of `generators.shell` ends in `'` (`for'`), as does a local named like a script-level name, which Nix would shadow (`cmd_reconcile`'s `f'`); the printer drops it. A command is a list of words, the language's own shape. A word is a string written as it is (a program, an option, a glob; a `$`, quote, blank or operator character in it throws), a Nix integer, a name, or a node: `dq` (a double-quoted string of unescaped text and `var`, `sub` and expansion nodes), `sq`, `ansic` (`$'...'`, unescaped), `sub` (`$(...)`), `word` (parts written together), `array`, `assign name value`, `redir op target` (spaced before a quoted target) or `heredoc delimiter body` (`<<'EOF'`). A statement is a command, `assign`, `test` (`[ ... ]` of a unary test, `nonEmpty`, `isEmpty`, `exists`, `isDir` or `isFile`, or a `[left "=" right]` comparison), `pipe`, `chain [a "&&" b]`, `fn name body`, `braces`, `if' test body`, `ifElse test body otherwise`, `for name words body`, `while test body`, `case subject [(arm patterns body)]`, `comment` or `shebang`. A body is a list of statements, one per line two spaces in, or `inline [ ... ]` on one line; `rows` breaks a pipe or chain after each operator. Code another program runs (a `trap` handler, an `sh -c` script, a jq program) is the text of its `sq`. From `omp-box/omp-box.data.nix`, abridged:

```nix
{IFS, ansic, argsJoined, assign, blank, chain, default, dq, fn, if', inline, nonEmpty, redir, sq, test, var, ...}: ({grants, up, fail, unmount_guest, cmd_rm, ...}: [
  (fn fail (inline [["printf" (sq "omp-box: %s\\n") (dq (var argsJoined)) (redir ">&" 2)] ["exit" 1]]))
  blank
  (fn cmd_rm ({name, path, mode}: [
    ["local" (assign name (default 1 ""))]
    (chain [(test (nonEmpty (dq (var name)))) "||" [fail (dq "rm needs a name")]])
    ["local" path mode]
    [(assign IFS (ansic "\t")) "read" "-r" path mode (redir "<" (dq [(var grants) "/" (var name)]))]
    (if' [up] (inline [[unmount_guest (dq (var path))]]))
  ]))
])
```

Luau (`generators.luau`) binds its names in Nix. A data file is a function of the constructors and of the Luau and Tern globals and builtin types it uses (`tern`, `string`, `table'`, `pcall`, `number`, `WindowCx`, ...; each an attribute of `generators.luau`), returning the file's block. A local, local function or type alias is a Nix binding: a block that declares names (the file, a function body, an `if` branch, a loop body) is a lambda whose formals are exactly those names, `({last, note}: [ ... ])`, and a block declaring nothing is a list. A function's parameters and a loop's variables are listed in order as one-attribute sets of their type, `[{cx = WindowCx;} {id = null;}]` (`null` when unannotated), and bound by the body's lambda. `render` calls each lambda with the names of its formals and throws on a formal its block does not declare or a declaration its block does not bind, so no identifier is a string and a typo is an undefined variable at evaluation. A name that is a Nix keyword or an attribute of `generators.luau` is spelled with a trailing `'` (`type'` is Luau's `type`, `table'` its `table`). A call is a Nix list, its function first; `dot base "session:focused"` is a field path, the method after `:`, on any expression. Literals are `str` (in the quote StyLua picks, its parts strings and `unicode "2061"` escapes), `long` (`[[...]]`), Nix integers, floats and booleans, `hex 57344` (`0xE000`) and `nil`. Operators are `infix [a "and" b "or" c]`, parsed by Luau precedence (`..` and `^` right associative), so a nested `infix` is a grouping the precedence does not give and the printer writes the parentheses it needs, those StyLua keeps around an `if` expression or a cast operand, and no others; `paren` is a parenthesis the printer would not write, one truncating a call to one value or one StyLua keeps around a binary expression precedence already groups (`rail.luau`'s `(first >= 0xE000 and first <= 0xF8FF) or ...`). `not`, `neg` and `len` are `not`, `-` and `#`. `table` holds values, `field name value` and `pair key value`; `fn params body`, `ifExpr [test value ... otherwise]`, `idx`, `cast`, `tuple` (an expression list or a tuple type) and `typed x type` (a local's annotation or, around a parameter list, a function's return type) are the rest. A type is a name, `nil`, `opt`, `table` or `tuple`. A statement is a call, `return` (alone, a bare `return`), `local`, `assign`, `update "+=" target value`, `localFunction`, `if'`, `ifElse` (whose `otherwise` is an `elseif` when it is itself an `if'` or `ifElse`), `for`, `forRange`, `while`, `type` or `trailing statement comment`; a body is written one statement per line a tab in. `rows` writes a call (one argument per line), a table (one entry per line, with `blank` and `comment` entries), an `infix` run of one operator (a line per operator), a method `dot` (on its own line) or an `ifExpr` (then a list of the rows of its parts) over several lines, the way StyLua breaks them. `tuturu/src/window.luau` passes an undeclared `proproblems` (a typo for `problems`) to `table.insert`; it is listed among the globals so the file renders as before. From `tern/config/plugins/tab-order/window.data.nix`, abridged:

```nix
{WindowCx, assign, blank, dot, fn, if', infix, local, localFunction, nil, not, number, opt, return, str, tern, tuple, typed, ...}: ({
  last,
  previous,
  note,
  focused_tab,
  tab_info,
  place,
}: [
  (local (typed last (opt number)) nil)
  blank
  (localFunction place [{cx = WindowCx;} {id = number;} {anchor = opt number;}] ({
    cx,
    id,
    anchor,
    info,
    at,
  }: [
    (if' (infix [(not anchor) "or" anchor "==" id]) [
      return
    ])
    (local info [tab_info cx id])
    (local at [tab_info cx anchor])
    (if' (infix [(dot info "position") ">" (dot at "position") "+" 1]) [
      [(dot cx "layout:order_tab") id (infix [(dot at "position") "+" 1])]
    ])
  ]))
  blank
  [
    (dot tern "on")
    (str "window_start")
    (fn [{cx = WindowCx;}] ({cx}: [
      (assign [last previous] (tuple [nil nil]))
      [note [focused_tab cx]]
    ]))
  ]
])
```


VBScript (`generators.vbs`) is a function of the generator (its constructors and the VBScript and WScript globals the script uses, `CreateObject`, `Err`, `Replace`, `WScript`, `Nothing` and the rest of `globals`) whose names are Nix bindings: the script, and each `sub name parameters body` or `function name parameters body`, is a lambda whose formals are the names it declares (`dim [a b]` anywhere in it, an `If` branch included, since VBScript scopes a `Dim` to its script or procedure; its procedures; a procedure's parameters, listed in order as `[{who = null;} {n = byVal;}]`), and the generator throws when a formal is not declared. A name the generator or Nix already uses is spelled with a trailing `'` (`str'`), which the printer drops. A member is `dot base "Arguments.Count"`, a call `call function [arguments]`, written `f(a, b)` in an expression and `f a, b` as a statement; `str` is a string literal (its quotes doubled on output), integers and booleans are Nix values, `not` and `neg` the unary operators, and the binary ones an infix list parsed by VBScript's precedence (`^`, `*` `/`, `\`, `Mod`, `+` `-`, `&`, the comparisons, `And`, `Or`, `Xor`, `Eqv`, `Imp`, all left associative), so a nested list is a grouping the precedence does not give and the printer writes the parentheses it needs and no others. A string where an expression is expected throws. The statements are `optionExplicit`, `onErrorResumeNext`, `onErrorGoTo0`, `dim`, `assign target value`, `set target value`, a `call`, `if' test body` and `ifElse test body otherwise`, bodies one tab in; `comment "text"` is `' text`. From `tern/config/plugins/tuturu/scripts/play.data.nix`, abridged:

```nix
{CreateObject, Err, WScript, assign, call, dim, dot, if', set, str, ...}: ({sh, cmd, code}: [
  (dim [sh cmd])
  (set sh (call CreateObject [(str "WScript.Shell")]))
  (if' [(dot Err "Number") "<>" 0] [
    (call (dot WScript "Quit") [1])
  ])
  (dim [code])
  (assign code (call (dot sh "Run") [cmd 0 true]))
  (call (dot WScript "Quit") [code])
])
```

Patches (`generators.patch`): a patch is a list of files, `file path hunks` (`--- a/path`, `+++ b/path`) or `git path index hunks`, which adds the `diff --git` and `index` lines. A hunk is `hunk start lines` or `section start heading lines` (the text after `@@`), `start` the old file's first line. A context line is a string, a changed line `add` or `del`. The printer counts each hunk's lines and derives its new start from the hunks before it, so the `@@` header is never written by hand. From `shell/rush/login-command.data.nix`, abridged:

```nix
{add, file, hunk, ...}: [
  (file "src/shell/invocation.zig" [
    (hunk 37 [
      "    positionals: []const []const u8 = &.{},"
      (add "    login: bool = false,")
      "};"
    ])
  ])
]
```

Markdown (`generators.markdown`): a paragraph is a string or a list of inlines, `wrap` a paragraph filled to 78 columns, `heading level text`, `bullets [ ... ]` a tight `- ` list of paragraphs, `table header rows` a `| a | b |` table, its header row over a `|---|` row and every row as wide as the header, and `comment` an HTML comment. An inline is text (a string), `code`, `strong`, `em` or `link text url`. Text is only literal: the printer throws on a string holding what would read as markup (`` ` ``, `*`, `\`, `<`, `&`, `~~`, `](`, `][`, `![`, an `_` at the edge of a word), so markup is always a constructor, and brackets that are no link (`[349,0,2174,1388]`) stay text. From `tern/config/plugins/tuturu/README.data.nix`, abridged:

```nix
{blank, code, heading, table, wrap, ...}: [
  (heading 2 "Sounds")
  blank
  (wrap [(code "~/finix/modules/tools/tern/default.nix") " builds the three sounds and writes " (code "~/.local/state/tern/plugin-data/tuturu/sounds.toml") " to name them:"])
  blank
  (table ["Trigger" "Sound"] [
    [[(code "yield") ": an omp agent finished its turn"] "Tuturu, at the right ear"]
  ])
]
```

GLSL (`generators.glsl`) is code Nix evaluates. A shader is a function of the generator (its constructors, GLSL's builtins and types, tomoe's prelude uniforms `iResolution`, `iTime`, `iFrame`, `iMouse` and `iChannel0`) and of itself: `{fn, vec2, mix, ...}: self: let inherit (self) PAL hash; in {defines, consts, fns}`. `render` passes the shader its own globals, so a constant, function or define is a Nix variable wherever it is used, and a parameter or local is a Nix binding: a function's body is a lambda whose formals are its parameters (listed in order, `[{fragColor = out vec4;} {fragCoord = in' vec2;}]`) and the locals its block declares, and any block that declares names (an `if` branch, a `for`, which also binds its loop variable) is a lambda of them. `local v uvec2 value` declares a bound name with its type, at its place in the block. No identifier is a string: a typo is an undefined variable at evaluation. Every value carries its GLSL type and has exactly the swizzles its type has, in all three letter sets, as attributes (`c.x`, `p.yx`, `(vec3 p 1.0).bgr`, `(index PAL i).rgb`; a `vec2` has no `.z`, a `float` none); an infix list is Nix data, so `(a + b).xy` has no tree. The types are checked as GLSL ES 3.00 does, with no implicit conversion: arithmetic is componentwise on equal types or a scalar with a vector or matrix of its base type, `*` of a matrix and a vector or matrix is the linear-algebra product (`vec2 * mat2` is a `vec2`, `mat3x2 * vec3` a `vec2`), `%` and the bitwise and shift operators take integers, `<` and its kin scalars of one type, `&&`, `||` and `^^` booleans, `neg`, `not` and `bitNot` their operand types, and a `local` or `set` value, an `update`, a condition and both arms of `cond` must agree, so `vec3 + vec2`, `int + float`, `int + uint`, `p < q` of vectors or a `float` local given a `vec2` throws. Numbers and booleans are native Nix values, so a constant may be computed: `math.round 8 (math.sqrt 3.0 / 2.0)` is hex-spiral's `S3`, and `rgb ozette.lavender` is `vec3(0.776, 0.651, 0.949)`, each channel of the hex colour over 255 rounded to three places. The Ozette palette is one attribute set of hex colours, `modules/desktop/session/theme/ozette.data.nix`, passed to the eight Ozette shaders as `ozette`. Arithmetic is an infix list alternating operands and operators, `[a "*" b "+" 1.0]`, parsed by GLSL precedence (left associative), so a nested list is a grouping the precedence does not give and the printer writes the parentheses that grouping needs and no others. A float prints as its shortest round-trip form (`builtins.toJSON`) with a decimal point always present (`1e-05` is `1.0e-5`). The printer derives the order GLSL needs: `#define`s by name, then constants, then functions, each after what it references, ties by name, and a cycle is an error. A constant's type is its value's, by those rules (`CENTER = vec2 0.4 0.58;` is `const vec2 CENTER`, `[2.0 "*" PI]` a `float`); `typed float value` is only for a value whose type is unknown, a macro's result, and throws if it is not its value's. A define is a value or `macro ({c}: body)`, written in parentheses with its parameter parenthesized. The statements are `local`, `set target value`, `update target "+=" value`, `return`, `break`, `continue`, `if' test body`, `ifElse test body otherwise`, `for`, `while test body`, `comment` and an expression; `commented "text" declaration` keeps a comment above a declaration. A branch of one simple statement is written on the `if` line, any other body braced, four spaces in; an infix expression too long for 100 columns breaks before its loosest operator. Blank lines, spacing, redundant parentheses, a literal's spelling and declarator lists are not kept. From `tomoe/shaders/glass-mound.data.nix`, abridged:

```nix
{cos, float, fn, local, mat2, neg, normalize, return, sin, vec2, vec3, ...}: self: let
  inherit (self) SINK map rot;
in {
  consts = {
    IOR = 1.33;
    SINK = -1.0;
  };
  fns = {
    rot = fn mat2 [{a = float;}] ({a, c, s}: [
      (local c float (cos a))
      (local s float (sin a))
      (return (mat2 c (neg s) s c))
    ]);
    normal = fn vec3 [{p = vec3;} {t = float;}] ({p, t, e}: [
      (local e vec2 (vec2 0.002 0.0))
      (return (normalize (vec3
        [(map [p "+" e.xyy] t) "-" (map [p "-" e.xyy] t)]
        [(map [p "+" e.yxy] t) "-" (map [p "-" e.yxy] t)]
        [(map [p "+" e.yyx] t) "-" (map [p "-" e.yyx] t)])))
    ]);
  };
}
```

Lua (`generators.lua`) binds names as GLSL does and keeps layout as Luau does. A data file is a function of the constructors and of the Lua globals it uses, `{local, pcall, pg, table', ...}: ({INTERVAL, log, ...}: [ ... ])`: the generator's globals are a fixed list, Lua's standard ones with LuaJIT's `bit` and `jit`, Aniimo's `CS`, `pg` and `Vector3` and Hyprland's `hl`, so a misspelt global is a missing argument and a misspelt local an undefined variable at evaluation. A block that declares names (the chunk, a function body, a loop, a branch, `do`) is a lambda whose formals are exactly the names its `local` and `localFunction` statements, parameters or loop variables declare, and `render` throws on a formal its block does not declare; since a lambda's formals have no order, a function with parameters is `fn ({self, held}: {params = [self vararg]; body = [ ... ];})`, a generic loop `forIn ({_, p}: {names = [_ p]; values = [[ipairs paths]]; body = ...;})` and a numeric one `forNum ({i}: {name = i; range = [1 n]; body = ...;})`. A name that is a Nix keyword, a constructor or a global is primed and printed without the prime: the global `table` is `table'`, `assert` is `assert'`, a local `field` is `field'`. The only strings are literal contents (`str`, `sq`), operators, field paths and table keys: `dot pg "me.space"` is `pg.me.space`, `[(method helper "canForceLock")]` a method call, `index t k` an index, `field "n" v` and `key k v` table fields, `apply f (table ...)` the call `f{...}`; a bare string where an expression belongs throws. A call is a Nix list, its function first; a list whose second item is a string is an infix expression, parsed by Lua's precedence with `..` and `^` to the right, nested exactly where the file writes parentheses, which the printer writes back (Aniimo's mods also group what precedence already groups, `(a and b) and c or d` and `x or (a .. b)`, so a nested list is always parenthesized). The printer adds the parentheses a unary operand, the unary base of `^` and a non-prefix expression before `.`, `:`, `[` or `(` need, and `paren` is only the parentheses that keep a call's or `...`'s first value (`return (tostring(v):gsub(...))`). `not`, `neg`, `len` and `bnot` are the unary operators, `nil`, `vararg`, `break` and `semicolon` values, and numbers and booleans Nix's own. The other statements are a call, `assign targets values`, `return values`, `if' test body`, `ifElse test body otherwise` (an `if` node as `otherwise` is `elseif`), `while test body` and `do body`. A body is a list of statements, one per line two spaces in, or `inline [ ... ]` on the keyword's line; `rows` puts each row of a table's fields on its own line and, as an expression, breaks an infix list before each later row's first operator, two spaces in. From `aniimo/catch-lua.data.nix`, abridged:

```nix
(localFunction need ({owner, name}: {
  params = [owner name];
  body = [
    [assert' [owner "and" [type (index owner name)] "==" (str "function")] [name ".." (str " missing")]]
  ];
}))
blank
(localFunction safely ({fn', self, ok, err}: {
  params = [fn' self];
  body = [
    (if' off (inline [(return [])]))
    (local [ok err] [[pcall fn' self]])
    (if' (not ok) (inline [[disable err]]))
  ];
}))
```

Python (`generators.python`) is code Nix binds. A file is a function of the constructors it uses and of the Python builtins it names (`print`, `len`, `Exception`, `__name__`, `None`; a builtin spelled like a constructor takes a `'`: `str'`, `list'`, `set'`, `bytes'`), returning its module: a lambda whose formals are the names the module binds, `({os, Path, main}: [ ... ])`. Every scope Python has is such a lambda: a `def`'s is `({a, b, x}: {params = [a (default b None)]; body = [ ... ];})`, its parameters and the names its body binds; a `class` body, a `lambda` (`{params; body}` too) and a comprehension (`listComp ({k}: [(index x k) (compFor k keys) (compIf k)])`, also `setComp`, `dictComp` and `gen`, which is written bare as a call's only argument) are the others, and an `if`, `for`, `while`, `with` or `try` body is a plain list, since Python scopes nothing there. A name is bound where Python binds it (imports, assignment, `for`, `with ... as` and `except ... as` targets, `:=` in an `if` or `while` test, `def` and `class`), so every name in a tree is a Nix variable and a typo is an undefined variable; the generator throws when a formal is not bound in its scope. A name that is a Nix keyword, a constructor or a builtin takes a `'` (`index'`), dropped on output. Statements are `import' os`, `from "pathlib" [Path]`, `assign target value`, `augAssign target "+=" value`, `return` and `raise` (`null` for none), `pass`, `break`, `continue`, `del`, `global`, `nonlocal`, `assert'`, `def`, `class name bases body`, `if'`, `ifElse` (`otherwise` a body for `else:` or an `if` for `elif`), `for`, `while`, `with' items body`, `try body [(except caught body) (finally body)]`, `async` around any of them, `comment` and an expression. Expressions are `call f args`, `dot x "environ.get"` (an attribute path is a string: a property, not a binding), `index x key`, `slice lower upper`, `list`, `tuple`, `set`, `dict` of `pair k v`, `commas` (a tuple without brackets), `kw "flush" true` (a keyword argument), `star`, `starstar`, `not`, `neg`, `invert`, `await`, `ternary value test otherwise`, `walrus`, `lambda` and `as`; an operator chain is an infix list, `[a "+" b "*" c]` (with `in`, `not in`, `is`, `is not`, `and` and `or` among the operators), parsed by Python's precedence (`**` right associative, comparisons chained), so a nested list is a grouping the precedence does not give and the printer writes the parentheses it needs and no others. `true` and `false` are Nix booleans, an integer a Nix integer (`octal 448` is `0o700`), and `@name@` substitution placeholders are `placeholder "name"`. String literals keep their source body: `str` (`"..."`), `sq` (`'...'`) and `triple` (`"""..."""`), with `raw` and `bytes` for the `r` and `b` prefixes; a body that is a list is an f-string of text, `field x` and `spec x "03d"`, and `strings [a b]` is implicit concatenation. Layout is data: brackets hold a list of items on one line, `rows` hanging one row a line four spaces in with the closing bracket on its own line and a trailing comma when there are several rows (black's layout), or `aligned` with the rows after the first under the first item; `rows` of an infix list, of `strings` or of a comprehension's parts breaks it between rows, under its bracket or, at statement level, after a backslash four spaces in; `hang x` and `aligned [ ... ]` around an expression are the parentheses black or the author wrote only to break lines. From `codex/apply-reasoning-policy.data.nix`, abridged:

```nix
{assign, call, commas, def, dot, if', import', index, kw, raw, return, slice, sq, ternary, ...}: ({re, apply}: [
  (import' re)
  (def apply ({path, text, header, end, root, rest, result}: {
    params = [path];
    body = [
      (assign text (ternary (call (dot path "read_text") []) (call (dot path "exists") []) (sq "")))
      (assign header (call (dot re "search") [(raw (sq "^\\s*\\[")) text (kw "flags" (dot re "MULTILINE"))]))
      (assign (commas [root rest]) (commas [(index text (slice null end)) (index text (slice end null))]))
      (assign result [root "+" rest])
      (if' [result "==" text] [
        (return null)
      ])
    ];
  }))
])
```

JavaScript (`generators.javascript`): a name is a Nix variable. A block that declares names (the file, a function, a braced body, a `catch`) is a lambda whose formals are exactly the names it declares, `({line, msg}: [ ... ])`; a function or arrow is a lambda of its parameters and its body's names returning `{params = [...]; body = ...;}` (a list, `inline`, or an expression for an arrow), a `catch (e)` one returning `{param = e; body = ...;}`; one that declares nothing is the plain list or record. The generator calls each lambda with name nodes and throws when a formal is not declared in its block. Node's globals (`console`, `JSON`, `process`, `fetch`, `Error`, `Promise`, `URL`, `setTimeout`, `undefined`, ...) and `null'` (JavaScript's `null`) are attributes of the generator, taken as data-file formals, so a typo is a missing argument; a name that is a Nix keyword or an attribute of the generator is spelled with a trailing `'` (`obj'`), which the printer drops. Integers, floats spelled as Nix spells them, and booleans are Nix values, `number "0x1f"` any other spelling; strings appear only as literal contents (`str`), property paths (`dot process "env.KEY"`, `optional params "name"` for `params?.name`), object keys (`["key" value]`, or `[(str "q-r") value]` when quoted; a shorthand entry is a name) and operators. `call f [args]`, `new Error [args]`, `not`, `neg`, `typeof`, `await` and `async` are constructors; a list alternates operands and operators and is parsed by JavaScript's precedence and associativity, a nested list is a grouping precedence does not give, and the printer writes the parentheses the tree needs plus prettier's (`(a && b) || c`, `(a % b) + c`, `a | (b & c)`, `-(-a)`, `a ** (b ** c)`). A statement is an expression, `const target value` and `let' target value` (`null` for none; the target a name, or an `obj` or `array` of them), `import' [names] source`, `function name definition`, `if'`, `ifElse`, `while`, `try' body handler`, `return value` (`null` for `return;`), `throw'` or `continue`. A body is a list of statements in braces, one per line two spaces in, `inline [ ... ]` on one line, or a single statement that is not an operation, written without braces. `obj` and `array` are on one line unless `rows`, one entry per line; `rows [a "+" b]` breaks after each operator, two spaces in; an object on one line whose last value is broken closes without its space (`{ id, result: {` ... `}}`). From `dev/ai/jev-mcp.data.nix`, abridged:

```nix
{Error, JSON, async, await, call, const, dot, fetch, function, if', inline, let', new, not, obj, rows, str, throw', try', ...}: ({ENDPOINT, MODEL, API_KEY, callSystemOne, ...}: [
  (async (function callSystemOne ({state, questions, res, text}: {
    params = [state questions];
    body = [
      (if' (not API_KEY) (throw' (new Error [(str "TYPESAFE_API_KEY not set")])))
      (const res (await (call fetch [
        ENDPOINT
        (obj (rows [
          ["method" (str "POST")]
          ["body" (call (dot JSON "stringify") [(obj [["model" MODEL] state questions])])]
        ]))
      ])))
      (if' (not (dot res "ok")) ({detail}: [
        (let' detail text)
        (try' ({j}: inline [(const j (call (dot JSON "parse") [text])) [detail "=" (call (dot JSON "stringify") [[(dot j "detail") "||" j]])]]) (inline []))
      ]))
    ];
  })))
])
```

TypeScript (`generators.ts`) keeps prettier's layout and binds every name. A data file is a function of the constructors and globals it uses and returns the file's top-level block: `{call, dot, string, ...}: ({toolRenderers, failed, ...}: [ ... ])`. Every identifier and type name is a Nix variable. A block that declares names is a lambda whose formals are exactly those names (the file, a block of an `if`, `while`, `try` or `case`, a `switch`), and so is a function, `fn`, `arrow` or `method`, of its parameters and its body's declarations (`({cell}: arrow cell ...)`), a `for` of its binding and body and a `catch` of its parameter and body; the generator calls the lambda with name nodes and throws when a formal is declared nowhere in it. JavaScript, Node and Bun globals and the builtin types (`JSON`, `Promise`, `Map`, `process`, `Bun`, `undefined`, `this`, `string`, `number`, `void`, `Record`, ...) are attributes of `generators.ts`, so a typo is a missing argument at evaluation; TypeScript's `null` and `as const`'s `const` are `null'` and `const'`, and a name a constructor or Nix already uses is spelled with a trailing `'` (`call'`; the printer drops it). Strings are text only: `str` and `sq` literals as written, `tpl` with `sub`, `regex`, `num` for a number Nix would spell differently (an integer is a Nix integer, `true` and `false` Nix booleans), member and property names (`dot x "a?.b"`, `prop "key" value`, `typed "key" T` and `field "key" value` in a class, an interface or a `shape`, `method "key" params body`), operator symbols and comments; a bare string where a value belongs throws. `infix [a "&&" b "||" c]` alternates operands and operators and is parsed by JavaScript's precedence (assignment and `**` to the right), a nested list is a grouping that precedence does not give, and the printer writes the parentheses that grouping needs plus those prettier adds (around `&&` inside `||`, `??` mixed with either, `%` next to `*` or `/`, an operand of a bitwise operator, `as` inside an operand or a ternary branch, `??` in a ternary branch, a ternary or object literal as an arrow's body on its line, a binary, ternary or `await` under a unary operator or member access, a function or union type inside `[]`). Unary operators and keywords are constructors: `not`, `neg`, `typeof`, `delete`, `await`, `spread`, `inc` and `dec` (postfix `++`, `--`), `nonNull`, `async`, `readonly`, `export`, `default`, `typeOnly` and `namespace` (`* as`). The rest are `call`, `optCall`, `new`, `generic`, `idx`, `optIdx`, `obj`, `array`, `arrayOf`, `union`, `intersection`, `is`, `opt`, `computed`, `ternary`, `extends`, `class`, `interface` and `type`; statements are `const`, `let'`, `return`, `throw'`, `if'`, `ifElse`, `for`, `forOf`, `forIn`, `forAwait`, `while`, `switch` of `case`, `try` with `catch` and `finally`, `import'`, and any expression (written with its `;`). The tree keeps only the breaks the printer cannot choose: `rows` for a list, an argument list or the loosest operator chain one item per line, `below x` for `x` on the next line one level in (after `=`, `:`, `=>`, `?` and `:` of a ternary, inside `(`; a broken `return` value is parenthesized), and `chain x` for a member chain broken before each call group, the groups prettier forms. A file indented by spaces is `spaces 2 ...`. From `omp/compact-eval.data.nix`, abridged:

```nix
{String, array, arrow, call, chain, const, dot, fn, forOf, if', infix, obj, prop, return, str, undefined, ...}: ({failed, summary, ...}: [
  ({result}: (fn failed [result] [
    (if' (infix [(dot result "?.isError") "||" (dot result "?.details?.isError")]) (return true))
    (return (call (dot (infix [(dot result "?.details?.cells") "??" (array [])]) "some") [({cell}: (arrow cell (infix [(dot cell "status") "===" (str "error")])))]))
  ]))
  ({cells}: (fn summary [cells] [
    ({cell, code, line}: (forOf cell cells [
      (const code (call String [(infix [(dot cell "?.code") "??" (str "")])]))
      (const line (chain (call (dot (call (dot code "split") [(str "\\n")]) "map") [({row}: (arrow row (call (dot row "trim") [])))])))
      (if' line (return (array [(obj [(prop "t" line) (prop "s" (str "code"))])])))
    ]))
    (return undefined)
  ]))
])
```

Converting is mechanical: `strictix import <language> FILE` parses the file with the language's tree-sitter grammar and prints its tree, and refuses layout the printer would not give back (a double space, a trailing comment). In `modules/lint.nix`, a codec `<id> = {extensions = []; generator = "<language>Source";};` makes strictix flag `generators.<language>Source (import ./x.data.nix)`, and `nix run .#lint -- fix` runs the import, rewrites the data file and the call, and keeps the change only when `generators.<id>.render` returns the line list's text byte for byte. Lint fix edits files, so it runs on a split tree (`strictix split . --merged flake.nix`, then `strictix merge . --entry flake.nix --out flake.nix --expand nixFiles`). A template that interpolates Nix values (`theme/templates/osc.data.nix`) is converted in place by `strictix import`, which keeps the interpolations inside the tree's strings. Once a language has no line lists left, its `<language>Source` generator and its codec go.

The flake formatter is alejandra at upstream commit 97ca3d24 (a flake input), which memoizes trial formats; 4.0.0 is exponential in nested constructor applications and takes minutes on a deep TypeScript tree. It formats every other file byte for byte as 4.0.0 does; swap to a release once one includes it.

Every converted file passed its gate. A language whose printer can reproduce its files gates on bytes at conversion; one that cannot gates on its official formatter's output for both sides; GLSL, whose tree keeps meaning and not layout, gates on formatter equality after canonicalization and on rendered pixels. `checks.codegen` (`modules/lint.nix`) then runs each language's own check on every rendered tree, listed in its `trees`:

| Language | Gate at conversion | `checks.codegen` |
| --- | --- | --- |
| Lisp (15 files; tomoe's probe and sounds forms, rendered inline, gated on bytes too) | bytes | SBCL's reader, the one tomoe and ekko run |
| shell (3 files) | bytes; binding names as Nix variables changed no rendered byte (`beat-saber-lock`, `omp-box` and both colour schemes' `osc.sh`) | `bash -n`, `shellcheck -S warning` |
| Luau (8 files; Agent Tabs' `window.luau` is text, checked the same way) | bytes, at conversion and again when its names became Nix bindings | `luau-analyze` reports no syntax error (its type errors need Tern's `tern.d.luau` definitions, which the repo does not hold) |
| VBScript (1 file) | bytes, again after its names became Nix bindings and its operators infix lists | `strictix import vbs`, a parse by tree-sitter-VB6-VBA-VBS (no VBScript checker runs on Linux) |
| patches (3 files) | bytes | `git apply --check` against the source each patches |
| markdown (7 files) | bytes, again after text became only literal and a table's header typed | comrak (CommonMark and GFM tables): the rendered file's AST equals the AST of comrak's own CommonMark rendering of it |
| GLSL (8 files; tomoe's seven shaders are text, checked the same way) | `nix run .#glsl-gate -- ORIGINAL GENERATED ...`: both sides, canonicalized (top-level declarations sorted, every operator parenthesized, literals as their values, one declarator per declaration, every branch braced) and run through clang-format 21 with a pinned style, are equal; both pass glslangValidator; four 640×360 frames of each, rendered by llvmpipe into float32 targets, are bit-identical | `glslangValidator -S frag` on each shader inside tomoe's ES 3.00 prelude and `main` |
| Lua (3 files) | bytes, at conversion and again when names became Nix bindings (the bound trees render the word-list trees' bytes) | `luajit -bl` for Aniimo's two LuaJIT mods, `luac -p` (Lua 5.5, Hyprland's) for `hyprland.lua` |
| Python (5 files) | bytes, again after re-import to bound typed trees | `python -m py_compile` (vercel's `wrapper.py` with `@owners@` filled); `ruff check` is not clean today (4 of 5 files fail its defaults) |
| JavaScript (1 file) | bytes, every name a Nix binding of its block or a generator global | `node --check` |
| TypeScript (12 files; the secrets extension's three are text, checked the same way) | bytes, at conversion and again when re-imported with every name bound | `tsc --noEmit` (TypeScript 7) with an ambient stub of the omp, pi and Node modules they import; `work-fold.ts`, `compact-eval.ts`, `chat-look.ts` and the secrets extension's `omp-secret.ts`, untyped as written, get `--noCheck` (syntax and imports only) |

### GLSL before and after

This records the conversion on the `lean/rules` branch. The seven tomoe shaders it describes are text here again, byte-identical to the files tomoe had, because their evaluated code renders the same frames from other bytes; the eight Ozette wallpapers stay evaluated code.

The seven tomoe shaders went from word lists, which kept every byte, to evaluated code, by `strictix import glsl` on each rendered file; the eight Ozette wallpapers (`~/dev/developing/ozette-shaders`, in `checks.codegen` and the gate, not in tomoe's rotation) were imported from their sources and their colour constants then read from the palette. A shader file holds only what is its own: `ozette-prelude.data.nix` has the hash, noise and fbm functions, the grid and colours all eight wallpapers use and each theme's `paper` palette; each scene (`ozette.data.nix`, `ozette-fields`, `ozette-lilies` and `ozette-pond`) adds its functions and the constants its two themes share; a wallpaper's file (`ozette-pond-dark.data.nix`) merges its theme's constants on top. `cassette-led` and `cassette-squares` take their common constants and functions from `cassette.data.nix`. A file passes the file it imports the constructors and `self` it was given, so the merged attribute set renders the bytes the single file did. The rendered text changes where the tree no longer records it: declaration order (derived), blank lines, redundant parentheses (`(0.3 / CONTRAST) * COLOR_1` is `0.3 / CONTRAST * COLOR_1`), literal spelling (`1.000` is `1.0`, `0.86602540` is `0.8660254`, `0xde443b` is `14566459`), declarator lists and line breaks. The grouping the parser sees is unchanged, each literal denotes the same double (a computed constant is rounded to the digits its source had, so `math.round 8 (2.0 * math.pi)` is `6.28318531`), and every one of the fifteen shaders passes `nix run .#glsl-gate` with all four frames bit-identical. Binding names as Nix variables changed no rendered byte of the seven, whose store paths are those of the keyed form (the strictix pin moves the desktop hosts):

| Shader | Before | After |
| --- | --- | --- |
| `balatro.glsl` | `wqqd8rsq4p8hpjldfc6hkqsd9g4d8anv` | `cbkwq5xm5flwhiwp4fk15h4zsyrz6lv6` |
| `cassette-led.glsl` | `xj1ncvj97cnkfkyn797wizyyjca177bs` | `vi7w2rj7rvb70ylswxpx3h4bd6nwxz84` |
| `cassette-squares.glsl` | `wh2pnzy25420m6kpk2wa11619b6lr706` | `l38m45qbymnlkc168j9dzwbnn2vns26c` |
| `dot-corridor.glsl` | `xr7d0nwww7609kwl2p170mnsh8j18lrh` | `yz5giznzzjp098ispsqhpd3fvpw5pbsn` |
| `glass-mound.glsl` | `v24vp2yq9fw938f555i747kas83bcgb5` | `hfmndx9c9mxh220mga1r39rw859pldjf` |
| `hex-spiral.glsl` | `04yg5rvi5vg69cymp0cwmsi4l1a2iccc` | `18f1yk28zmp46digxbakp1081kyfy3wj` |
| `su-ei.glsl` | `yq0qiqac5yg6b8igk4fpwmzpf32rf1jg` | `9sl74yc2grlzfpvxq812qskhvyggc57r` |

and with them, and with the strictix input pinned to the importer's commit, the system derivations of the two desktop hosts (`y0usaf-server` is unchanged):

| Check | Before | After |
| --- | --- | --- |
| `y0usaf-desktop` | `w6yqzw2vj5r57mv401qyl8g5pi1vn0l4-finix-system.drv` | `m2fgqd2pibmjm3cfl5xvzc7h56zcdyy7-finix-system.drv` |
| `y0usaf-framework` | `xh9xnlvricwg56b9n3489ak1xzhq3y3b-finix-system.drv` | `pdz78slkfpb2snyw49xc886xjfb3p8c2-finix-system.drv` |

The Ozette shaders' store paths are new:

| Shader | Path |
| --- | --- |
| `ozette-dark.glsl` | `kj5qrq7vm1rhra85rpik4gcakb1cyxx6` |
| `ozette-fields-dark.glsl` | `y3gzrcxpsjlyf4niqvfvn30f3iyrp0d8` |
| `ozette-fields-light.glsl` | `qn9myrbzjgf37zirdxnyvqwmgwvnxsa9` |
| `ozette-light.glsl` | `vk4lrax6l1wilpf44h06y3fb519g1prv` |
| `ozette-lilies-dark.glsl` | `8cymh32d9k2h7yg1aqcj2j2g6alk80h3` |
| `ozette-lilies-light.glsl` | `f6li3b5nbqwmgzzqwsc8y8fald5j956p` |
| `ozette-pond-dark.glsl` | `3z6nwvnb4k50y03p7516j7pdpvxr5y79` |
| `ozette-pond-light.glsl` | `qaaqq2pw7dbkgp4rgzxak0dkhs6lzhk6` |

`balatro.glsl`, the smallest:

<table>
<tr><th>Before: words</th><th>After: evaluated code</th></tr>
<tr>
<td valign="top">

<pre>
{
  blank,
  call,
  define,
  fn,
  for,
  rows,
  ...
}: [
  (define (call "HEX" ["c"]) [[(call "vec3" [[[["c"] "&gt;&gt;" 16] "&amp;" "0xff"] [[["c"] "&gt;&gt;" 8] "&amp;" "0xff"] [["c"] "&amp;" "0xff"]]) "/" "255.0"]])
  (define "COLOR_1" (call "HEX" ["0xde443b"]))
  (define "COLOR_2" (call "HEX" ["0x006bb4"]))
  (define "COLOR_3" (call "HEX" ["0x162325"]))
  (define "CONTRAST" "3.5")
  (define "LIGHTING" "0.4")
  (define "SPIN_AMOUNT" "0.25")
  (define "SPIN_ROTATION" "-2.0")
  (define "SPEED" "7.0")
  blank
  (fn ["void" (call "mainImage" [["out" "vec4" "fragColor"] ["in" "vec2" "fragCoord"]])] [
    ["float" "diagonal" "=" (call "length" ["iResolution.xy"])]
    ["vec2" "uv" "=" ["fragCoord" "-" "0.5" "*" "iResolution.xy"] "/" "diagonal"]
    ["float" "radius" "=" (call "length" ["uv"])]
    (rows [
      ["float" "angle" "=" (call "atan" ["uv.y" "uv.x"]) "+" "302.2" "+" "0.2" "*" "SPIN_ROTATION"]
      ["-" "20.0" "*" ["SPIN_AMOUNT" "*" "radius" "+" "1.0" "-" "SPIN_AMOUNT"]]
    ])
    ["uv" "=" "radius" "*" (call "vec2" [(call "cos" ["angle"]) (call "sin" ["angle"])]) "*" "30.0"]
    ["float" "t" "=" "iTime" "*" "SPEED"]
    ["vec2" "uv2" "=" (call "vec2" [["uv.x" "+" "uv.y"]])]
    (for ["int" "i" "=" 0] ["i" "&lt;" 5] "i++" [
      ["uv2" "+=" (call "sin" [(call "max" ["uv.x" "uv.y"])]) "+" "uv"]
      ["uv" "+=" "0.5" "*" (call "vec2" [(call "cos" [["5.1123314" "+" "0.353" "*" "uv2.y" "+" "t" "*" "0.131121"]]) (call "sin" [["uv2.x" "-" "0.113" "*" "t"]])])]
      ["uv" "-=" (call "cos" [["uv.x" "+" "uv.y"]]) "-" (call "sin" [["uv.x" "*" "0.711" "-" "uv.y"]])]
    ])
    ["float" "contrast" "=" "0.25" "*" "CONTRAST" "+" "0.5" "*" "SPIN_AMOUNT" "+" "1.2"]
    ["float" "paint" "=" (call "clamp" [[(call "length" ["uv"]) "*" "0.035" "*" "contrast"] "0.0" "2.0"])]
    ["float" "c1" "=" (call "max" ["0.0" ["1.0" "-" "contrast" "*" (call "abs" [["1.0" "-" "paint"]])]])]
    ["float" "c2" "=" (call "max" ["0.0" ["1.0" "-" "contrast" "*" (call "abs" ["paint"])]])]
    ["float" "c3" "=" "1.0" "-" (call "min" ["1.0" ["c1" "+" "c2"]])]
    ["float" "light" "=" ["LIGHTING" "-" "0.2"] "*" (call "max" [["c1" "*" "5.0" "-" "4.0"] "0.0"]) "+" "LIGHTING" "*" (call "max" [["c2" "*" "5.0" "-" "4.0"] "0.0"])]
    (rows [
      ["vec3" "color" "=" ["0.3" "/" "CONTRAST"] "*" "COLOR_1"]
      ["+" ["1.0" "-" "0.3" "/" "CONTRAST"] "*" ["COLOR_1" "*" "c1" "+" "COLOR_2" "*" "c2" "+" "COLOR_3" "*" "c3"] "+" "light"]
    ])
    ["fragColor" "=" (call "vec4" ["color" "1.0"])]
  ])
]
</pre>

</td>
<td valign="top">

<pre>
{
  abs,
  atan2,
  clamp,
  cos,
  float,
  fn,
  for,
  iResolution,
  iTime,
  in',
  inc,
  int,
  length,
  local,
  macro,
  max,
  min,
  out,
  set,
  sin,
  update,
  vec2,
  vec3,
  vec4,
  void,
  ...
}: self: let
  inherit (self) COLOR_1 COLOR_2 COLOR_3 CONTRAST HEX LIGHTING SPEED SPIN_AMOUNT SPIN_ROTATION;
in {
  defines = {
    COLOR_1 = HEX 14566459;
    COLOR_2 = HEX 27572;
    COLOR_3 = HEX 1450789;
    CONTRAST = 3.5;
    HEX = macro ({c}: [(vec3 [c "&gt;&gt;" 16 "&amp;" 255] [c "&gt;&gt;" 8 "&amp;" 255] [c "&amp;" 255]) "/" 255.0]);
    LIGHTING = 0.4;
    SPEED = 7.0;
    SPIN_AMOUNT = 0.25;
    SPIN_ROTATION = -2.0;
  };
  fns = {
    mainImage = fn void [{fragColor = out vec4;} {fragCoord = in' vec2;}] ({
      fragColor,
      fragCoord,
      diagonal,
      uv,
      radius,
      angle,
      t,
      uv2,
      contrast,
      paint,
      c1,
      c2,
      c3,
      light,
      color,
    }: [
      (local diagonal float (length iResolution.xy))
      (local uv vec2 [[fragCoord "-" 0.5 "*" iResolution.xy] "/" diagonal])
      (local radius float (length uv))
      (local angle float [(atan2 uv.y uv.x) "+" 302.2 "+" 0.2 "*" SPIN_ROTATION "-" 20.0 "*" [SPIN_AMOUNT "*" radius "+" 1.0 "-" SPIN_AMOUNT]])
      (set uv [radius "*" (vec2 (cos angle) (sin angle)) "*" 30.0])
      (local t float [iTime "*" SPEED])
      (local uv2 vec2 (vec2 [uv.x "+" uv.y]))
      (for ({i}: {
        init = local i int 0;
        test = [i "&lt;" 5];
        step = inc i;
        body = [
          (update uv2 "+=" [(sin (max uv.x uv.y)) "+" uv])
          (update uv "+=" [0.5 "*" (vec2 (cos [5.1123314 "+" 0.353 "*" uv2.y "+" t "*" 0.131121]) (sin [uv2.x "-" 0.113 "*" t]))])
          (update uv "-=" [(cos [uv.x "+" uv.y]) "-" (sin [uv.x "*" 0.711 "-" uv.y])])
        ];
      }))
      (local contrast float [0.25 "*" CONTRAST "+" 0.5 "*" SPIN_AMOUNT "+" 1.2])
      (local paint float (clamp [(length uv) "*" 0.035 "*" contrast] 0.0 2.0))
      (local c1 float (max 0.0 [1.0 "-" contrast "*" (abs [1.0 "-" paint])]))
      (local c2 float (max 0.0 [1.0 "-" contrast "*" (abs paint)]))
      (local c3 float [1.0 "-" (min 1.0 [c1 "+" c2])])
      (local light float [[LIGHTING "-" 0.2] "*" (max [c1 "*" 5.0 "-" 4.0] 0.0) "+" LIGHTING "*" (max [c2 "*" 5.0 "-" 4.0] 0.0)])
      (local color vec3 [0.3 "/" CONTRAST "*" COLOR_1 "+" [1.0 "-" 0.3 "/" CONTRAST] "*" [COLOR_1 "*" c1 "+" COLOR_2 "*" c2 "+" COLOR_3 "*" c3] "+" light])
      (set fragColor (vec4 color 1.0))
    ]);
  };
}
</pre>

</td>
</tr>
</table>

`hex-spiral.glsl`:

<details>
<summary>hex-spiral, before and after</summary>

<table>
<tr><th>Before: words</th><th>After: evaluated code</th></tr>
<tr>
<td valign="top">

<pre>
{
  bare,
  blank,
  call,
  fn,
  for,
  if',
  ifElse,
  index,
  rows,
  unary,
  ...
}: [
  ["const" "float" "PI" "=" "3.14159265"]
  ["const" "float" "TAU" "=" "6.28318531"]
  ["const" "float" "S3" "=" "0.86602540"]
  ["const" "vec2" "CENTER" "=" (call "vec2" ["0.4" "0.58"])]
  ["const" "int" "M" "=" 29]
  ["const" "int" "N" "=" 13]
  ["const" "int" "ARM" "=" 4]
  ["const" "int" "LOOP" "=" 52]
  ["const" "float" "HEX_SPEED" "=" "0.7"]
  ["const" "int" "STREAK_K" "=" 176]
  ["const" "float" "STREAK_STEP" "=" "0.057"]
  ["const" "int" "STREAK_N" "=" 132]
  ["const" "int" "STREAK_LOOP" "=" 160]
  ["const" "float" "STREAK_SPEED" "=" "0.32"]
  ["const" "float" "CYCLE" "=" "1.8"]
  blank
  [
    "const"
    "vec3"
    (index "PAL" 10)
    "="
    (call (index "vec3" 10) (rows [
      []
      [(call "vec3" ["1.000" "0.824" "0.122"]) (call "vec3" ["1.000" "0.604" "0.122"]) (call "vec3" ["1.000" "0.420" "0.369"])]
      [(call "vec3" ["1.000" "0.361" "0.784"]) (call "vec3" ["0.706" "0.420" "1.000"]) (call "vec3" ["0.184" "0.420" "1.000"])]
      [(call "vec3" ["0.122" "0.722" "1.000"]) (call "vec3" ["0.122" "0.839" "0.706"]) (call "vec3" ["0.482" "0.878" "0.165"])]
      [(call "vec3" ["0.957" "0.957" "0.957"])]
    ]))
  ]
  blank
  [
    "const"
    "ivec2"
    (index "NEAR" 7)
    "="
    (call (index "ivec2" 7) (rows [
      []
      [(call "ivec2" [0 0]) (call "ivec2" [1 0]) (call "ivec2" [(-1) 0]) (call "ivec2" [0 1]) (call "ivec2" [0 (-1)]) (call "ivec2" [1 (-1)]) (call "ivec2" [(-1) 1])]
    ]))
  ]
  blank
  (fn ["float" (call "hash" [["ivec2" "c"]])] [
    ["uvec2" "v" "=" (call "uvec2" ["c"]) "*" (call "uvec2" ["1597334673u" "3812015801u"])]
    ["uint" "n" "=" ["v.x" "^" "v.y"] "*" "1597334673u"]
    ["n" "^=" "n" "&gt;&gt;" 16]
    ["n" "*=" "2246822519u"]
    ["n" "^=" "n" "&gt;&gt;" 13]
    ["return" (call "float" ["n"]) "*" ["1.0" "/" "4294967296.0"]]
  ])
  blank
  (fn ["int" (call "fdiv" [["int" "a"] ["int" "b"]])] [
    ["return" (call "int" [(call "floor" [[(call "float" ["a"]) "/" (call "float" ["b"])]])])]
  ])
  blank
  (fn ["int" (call "pmod" [["int" "a"] ["int" "b"]])] [
    ["return" "a" "-" "b" "*" (call "fdiv" ["a" "b"])]
  ])
  blank
  (fn ["vec3" (call "cycle" [["float" "f"]])] [
    ["int" "a" "=" (call "pmod" [(call "int" [(call "floor" ["f"])]) 9])]
    ["return" (call "mix" [(index "PAL" "a") (index "PAL" (call "pmod" [["a" "+" 1] 9])) (call "fract" ["f"])])]
  ])
  blank
  (fn ["vec2" (call "rot" [["vec2" "v"] ["float" "a"]])] [
    ["float" "c" "=" (call "cos" ["a"]) "," "s" "=" (call "sin" ["a"])]
    ["return" (call "vec2" [["c" "*" "v.x" "-" "s" "*" "v.y"] ["s" "*" "v.x" "+" "c" "*" "v.y"]])]
  ])
  blank
  (fn ["vec2" (call "cart" [["ivec2" "a"]])] [
    ["return" (call "vec2" [[(call "float" ["a.x"]) "+" "0.5" "*" (call "float" ["a.y"])] ["S3" "*" (call "float" ["a.y"])]])]
  ])
  blank
  (fn ["ivec2" (call "nearest" [["vec2" "h"]])] [
    ["float" "y" "=" "h.y" "/" "S3"]
    ["vec3" "c" "=" (call "vec3" [["h.x" "-" "0.5" "*" "y"] "y" ["-h.x" "-" "0.5" "*" "y"]])]
    ["vec3" "r" "=" (call "floor" [["c" "+" "0.5"]])]
    ["vec3" "d" "=" (call "abs" [["r" "-" "c"]])]
    (ifElse ["d.x" "&gt;" "d.y" "&amp;&amp;" "d.x" "&gt;" "d.z"] (bare ["r.x" "=" "-r.y" "-" "r.z"]) (if' ["d.y" "&gt;" "d.z"] (bare ["r.y" "=" "-r.x" "-" "r.z"])))
    ["return" (call "ivec2" ["r.xy"])]
  ])
  blank
  (fn ["float" (call "hexDist" [["vec2" "q"]])] [
    ["return" (call "max" [(call "abs" ["q.x"]) (call "max" [(call "abs" [["0.5" "*" "q.x" "+" "S3" "*" "q.y"]]) (call "abs" [["-0.5" "*" "q.x" "+" "S3" "*" "q.y"]])])])]
  ])
  blank
  (fn ["void" (call "mainImage" [["out" "vec4" "fragColor"] ["in" "vec2" "fragCoord"]])] [
    ["float" "px" "=" "1.0" "/" "iResolution.y"]
    ["vec2" "p" "=" ["fragCoord" "-" "CENTER" "*" "iResolution.xy"] "*" "px"]
    ["float" "r" "=" (call "max" [(call "length" ["p"]) "1e-5"])]
    ["vec2" "w" "=" (call "vec2" [(call "log" ["r"]) (call "atan" ["p.y" "p.x"])])]
    blank
    ["vec2" "vc" "=" (call "cart" [(call "ivec2" ["M" "N"])])]
    ["float" "k" "=" "TAU" "/" (call "length" ["vc"])]
    ["float" "rho" "=" "0.5" "*" "PI" "-" (call "atan" ["vc.y" "vc.x"])]
    ["vec2" "drift" "=" (call "cart" [(call "ivec2" [1 (-1)])])]
    ["float" "tt" "=" (call "mod" [["iTime" "*" "HEX_SPEED"] (call "float" ["LOOP"])])]
    ["vec2" "hw" "=" (call "rot" ["w" "-rho"]) "/" "k" "-" "tt" "*" "drift"]
    ["ivec2" "base" "=" (call "nearest" ["hw"])]
    blank
    ["float" "jr" "=" (call "mod" [["hw.y" "/" "S3" "+" "0.5"] (call "float" ["N"])])]
    ["float" "band" "=" (call "smoothstep" [[(call "float" ["ARM"]) "+" "1.5"] [(call "float" ["ARM"]) "+" "4.0"] "jr"]) "*" ["1.0" "-" (call "smoothstep" [[(call "float" ["N"]) "-" "1.2"] (call "float" ["N"]) "jr"])]]
    blank
    ["vec3" "col" "=" (call "vec3" ["0.0"])]
    ["float" "phase" "=" (call "mod" ["iTime" "CYCLE"]) "*" "9.0" "/" "CYCLE"]
    blank
    ["float" "c" "=" (call "float" ["STREAK_K"]) "*" "STREAK_STEP" "/" "TAU"]
    ["float" "ct" "=" (call "sqrt" [["1.0" "+" "c" "*" "c"]])]
    ["float" "dth" "=" "TAU" "/" (call "float" ["STREAK_N"])]
    ["float" "ts" "=" (call "mod" [["iTime" "*" "STREAK_SPEED"] [(call "float" ["STREAK_LOOP"]) "*" "STREAK_STEP"]])]
    ["float" "sig" "=" "w.x" "-" "ts" "-" "c" "*" "w.y"]
    ["int" "is0" "=" (call "int" [(call "floor" [["sig" "/" "STREAK_STEP"]])])]
    ["int" "it0" "=" (call "int" [(call "floor" [["w.y" "/" "dth"]])])]
    (for ["int" "o" "=" 0] ["o" "&lt;" 9] "o++" [
      ["int" "it" "=" "it0" "+" "o" "%" 3 "-" 1]
      ["int" "is" "=" "is0" "+" "o" "/" 3 "-" 1]
      ["int" "q" "=" (call "fdiv" ["it" "STREAK_N"])]
      ["ivec2" "id" "=" (call "ivec2" [(call "pmod" [["is" "+" "STREAK_K" "*" "q"] "STREAK_LOOP"]) ["it" "-" "q" "*" "STREAK_N"]])]
      ["float" "h0" "=" (call "hash" ["id"])]
      ["float" "h1" "=" (call "hash" [["id" "+" (call "ivec2" [7 131])]])]
      ["float" "h2" "=" (call "hash" [["id" "+" (call "ivec2" [53 17])]])]
      (if' ["h0" "&gt;" "0.8"] (bare "continue"))
      ["float" "sm" "=" [(call "float" ["is"]) "+" "0.5" "+" "0.8" "*" ["h1" "-" "0.5"]] "*" "STREAK_STEP"]
      ["vec2" "dir" "=" (call "rot" [[(call "vec2" ["c" "1.0"]) "/" "ct"] ["0.6" "*" ["h2" "-" "0.5"]]])]
      ["float" "tc" "=" [(call "float" ["it"]) "+" "0.5" "+" "0.6" "*" ["h2" "-" "0.5"]] "*" "dth"]
      ["vec2" "d" "=" (call "vec2" [["sig" "-" "sm" "+" "c" "*" ["w.y" "-" "tc"]] ["w.y" "-" "tc"]])]
      ["float" "len" "=" ["0.22" "+" "0.22" "*" "h1"] "*" "dth" "*" "ct"]
      ["float" "th" "=" ["0.2" "+" "0.08" "*" "h2"] "*" "STREAK_STEP" "/" "ct"]
      ["float" "a" "=" (call "clamp" [(call "dot" ["d" "dir"]) "-len" "len"])]
      ["float" "dist" "=" [(call "length" [["d" "-" "dir" "*" "a"]]) "-" "th"] "*" "r" "/" "px"]
      ["float" "cover" "=" (call "clamp" [["0.5" "-" "dist"] "0.0" "1.0"]) "*" (call "smoothstep" ["0.6" "2.0" ["th" "*" "r" "/" "px"]])]
      ["int" "pick" "=" (call "int" [["h0" "*" "16.0"]]) "%" 13]
      ["vec3" "sc" "=" "pick" "&gt;" 8 "?" (index "PAL" 9) ":" (call "cycle" [[(call "float" ["pick"]) "-" "phase"]])]
      ["col" "=" (call "mix" ["col" ["sc" "*" ["0.7" "+" "0.3" "*" "h2"]] ["cover" "*" "band"]])]
    ])
    blank
    ["float" (index "key" 7)]
    ["int" (index "ord" 7)]
    ["vec2" "outward" "=" (call "rot" [(call "vec2" ["1.0" "0.0"]) "-rho"])]
    (for ["int" "i" "=" 0] ["i" "&lt;" 7] "i++" [
      [(index "key" "i") "=" (call "dot" [(call "cart" [(index "NEAR" "i")]) "outward"])]
      [(index "ord" "i") "=" "i"]
    ])
    (for ["int" "i" "=" 1] ["i" "&lt;" 7] "i++" [
      (for ["int" "j" "=" "i"] ["j" "&gt;" 0 "&amp;&amp;" (index "key" (index "ord" ["j" "-" 1])) "&gt;" (index "key" (index "ord" "j"))] "j--" [
        ["int" "t" "=" (index "ord" "j")]
        [(index "ord" "j") "=" (index "ord" ["j" "-" 1])]
        [(index "ord" ["j" "-" 1]) "=" "t"]
      ])
    ])
    blank
    ["int" "wrap" "=" ["M" "+" "N"] "*" "LOOP"]
    (for ["int" "i" "=" 0] ["i" "&lt;" 7] "i++" [
      ["ivec2" "cell" "=" "base" "+" (index "NEAR" (index "ord" "i"))]
      (if' [(call "pmod" ["cell.y" "N"]) "&gt;=" "ARM"] (bare "continue"))
      ["int" "id" "=" (call "pmod" [["cell.x" "*" "N" "-" "cell.y" "*" "M"] "wrap"])]
      ["float" "h0" "=" (call "hash" [(call "ivec2" ["id" 911])])]
      ["float" "h1" "=" (call "hash" [(call "ivec2" ["id" 37])])]
      ["vec2" "wc" "=" (call "rot" [[(call "cart" ["cell"]) "+" "tt" "*" "drift"] "rho"]) "*" "k"]
      ["float" "rc" "=" (call "exp" ["wc.x"])]
      ["vec2" "sc" "=" "rc" "*" (call "vec2" [(call "cos" ["wc.y"]) (call "sin" ["wc.y"])])]
      ["float" "scale" "=" "k" "*" "rc"]
      ["vec2" "q" "=" (call "rot" [["p" "-" "sc"] (unary "-" ["wc.y" "+" "rho"])]) "/" "scale"]
      ["float" "size" "=" "0.5" "*" ["0.88" "+" "0.36" "*" "h1"]]
      ["float" "dist" "=" [(call "hexDist" ["q"]) "-" "size"] "*" "scale" "/" "px"]
      ["float" "fade" "=" (call "smoothstep" ["3.0" "9.0" ["size" "*" "scale" "/" "px"]])]
      ["float" "cover" "=" (call "clamp" [["0.5" "-" "dist"] "0.0" "1.0"]) "*" "fade"]
      ["float" "rim" "=" (call "clamp" [["0.5" "-" "dist" "-" (call "max" ["1.0" ["0.03" "*" "size" "*" "scale" "/" "px"]])] "0.0" "1.0"])]
      ["vec3" "hc" "=" (call "cycle" [["h0" "*" "9.0" "-" "phase"]])]
      ["col" "=" (call "mix" ["col" ["hc" "*" "rim"] "cover"])]
    ])
    blank
    ["fragColor" "=" (call "vec4" ["col" "1.0"])]
  ])
]
</pre>

</td>
<td valign="top">

<pre>
{
  abs,
  array,
  atan2,
  clamp,
  cond,
  continue,
  cos,
  dec,
  dot,
  exp,
  float,
  floor,
  fn,
  for,
  fract,
  iResolution,
  iTime,
  if',
  ifElse,
  in',
  inc,
  index,
  int,
  ivec2,
  length,
  local,
  log,
  math,
  max,
  mix,
  mod,
  neg,
  out,
  return,
  set,
  sin,
  sized,
  smoothstep,
  sqrt,
  uint,
  unsigned,
  update,
  uvec2,
  vec2,
  vec3,
  vec4,
  void,
  ...
}: self: let
  inherit (self) ARM CENTER CYCLE HEX_SPEED LOOP M N NEAR PAL PI S3 STREAK_K STREAK_LOOP STREAK_N STREAK_SPEED STREAK_STEP TAU cart cycle fdiv hash hexDist nearest pmod rot;
in {
  consts = {
    ARM = 4;
    CENTER = vec2 0.4 0.58;
    CYCLE = 1.8;
    HEX_SPEED = 0.7;
    LOOP = 52;
    M = 29;
    N = 13;
    NEAR = array ivec2 [(ivec2 0 0) (ivec2 1 0) (ivec2 (-1) 0) (ivec2 0 1) (ivec2 0 (-1)) (ivec2 1 (-1)) (ivec2 (-1) 1)];
    PAL = array vec3 [(vec3 1.0 0.824 0.122) (vec3 1.0 0.604 0.122) (vec3 1.0 0.42 0.369) (vec3 1.0 0.361 0.784) (vec3 0.706 0.42 1.0) (vec3 0.184 0.42 1.0) (vec3 0.122 0.722 1.0) (vec3 0.122 0.839 0.706) (vec3 0.482 0.878 0.165) (vec3 0.957 0.957 0.957)];
    PI = math.round 8 math.pi;
    S3 = math.round 8 (math.sqrt 3.0 / 2.0);
    STREAK_K = 176;
    STREAK_LOOP = 160;
    STREAK_N = 132;
    STREAK_SPEED = 0.32;
    STREAK_STEP = 0.057;
    TAU = math.round 8 (2.0 * math.pi);
  };
  fns = {
    cart = fn vec2 [{a = ivec2;}] ({a}: [
      (return (vec2 [(float a.x) "+" 0.5 "*" (float a.y)] [S3 "*" (float a.y)]))
    ]);
    cycle = fn vec3 [{f = float;}] ({
      f,
      a,
    }: [
      (local a int (pmod (int (floor f)) 9))
      (return (mix (index PAL a) (index PAL (pmod [a "+" 1] 9)) (fract f)))
    ]);
    fdiv = fn int [{a = int;} {b = int;}] ({
      a,
      b,
    }: [
      (return (int (floor [(float a) "/" (float b)])))
    ]);
    hash = fn float [{c = ivec2;}] ({
      c,
      v,
      n,
    }: [
      (local v uvec2 [(uvec2 c) "*" (uvec2 (unsigned 1597334673) (unsigned 3812015801))])
      (local n uint [[v.x "^" v.y] "*" (unsigned 1597334673)])
      (update n "^=" [n "&gt;&gt;" 16])
      (update n "*=" (unsigned 2246822519))
      (update n "^=" [n "&gt;&gt;" 13])
      (return [(float n) "*" [1.0 "/" 4294967296.0]])
    ]);
    hexDist = fn float [{q = vec2;}] ({q}: [
      (return (max (abs q.x) (max (abs [0.5 "*" q.x "+" S3 "*" q.y]) (abs [(-0.5) "*" q.x "+" S3 "*" q.y]))))
    ]);
    mainImage = fn void [{fragColor = out vec4;} {fragCoord = in' vec2;}] ({
      fragColor,
      fragCoord,
      px,
      p,
      r,
      w,
      vc,
      k,
      rho,
      drift,
      tt,
      hw,
      base,
      jr,
      band,
      col,
      phase,
      c,
      ct,
      dth,
      ts,
      sig,
      is0,
      it0,
      key,
      ord,
      outward,
      wrap,
    }: [
      (local px float [1.0 "/" iResolution.y])
      (local p vec2 [[fragCoord "-" CENTER "*" iResolution.xy] "*" px])
      (local r float (max (length p) 1.0e-5))
      (local w vec2 (vec2 (log r) (atan2 p.y p.x)))
      (local vc vec2 (cart (ivec2 M N)))
      (local k float [TAU "/" (length vc)])
      (local rho float [0.5 "*" PI "-" (atan2 vc.y vc.x)])
      (local drift vec2 (cart (ivec2 1 (-1))))
      (local tt float (mod [iTime "*" HEX_SPEED] (float LOOP)))
      (local hw vec2 [(rot w (neg rho)) "/" k "-" tt "*" drift])
      (local base ivec2 (nearest hw))
      (local jr float (mod [hw.y "/" S3 "+" 0.5] (float N)))
      (local band float [(smoothstep [(float ARM) "+" 1.5] [(float ARM) "+" 4.0] jr) "*" [1.0 "-" (smoothstep [(float N) "-" 1.2] (float N) jr)]])
      (local col vec3 (vec3 0.0))
      (local phase float [(mod iTime CYCLE) "*" 9.0 "/" CYCLE])
      (local c float [(float STREAK_K) "*" STREAK_STEP "/" TAU])
      (local ct float (sqrt [1.0 "+" c "*" c]))
      (local dth float [TAU "/" (float STREAK_N)])
      (local ts float (mod [iTime "*" STREAK_SPEED] [(float STREAK_LOOP) "*" STREAK_STEP]))
      (local sig float [w.x "-" ts "-" c "*" w.y])
      (local is0 int (int (floor [sig "/" STREAK_STEP])))
      (local it0 int (int (floor [w.y "/" dth])))
      (for ({
        o,
        it,
        is,
        q,
        id,
        h0,
        h1,
        h2,
        sm,
        dir,
        tc,
        d,
        len,
        th,
        a,
        dist,
        cover,
        pick,
        sc,
      }: {
        init = local o int 0;
        test = [o "&lt;" 9];
        step = inc o;
        body = [
          (local it int [it0 "+" o "%" 3 "-" 1])
          (local is int [is0 "+" o "/" 3 "-" 1])
          (local q int (fdiv it STREAK_N))
          (local id ivec2 (ivec2 (pmod [is "+" STREAK_K "*" q] STREAK_LOOP) [it "-" q "*" STREAK_N]))
          (local h0 float (hash id))
          (local h1 float (hash [id "+" (ivec2 7 131)]))
          (local h2 float (hash [id "+" (ivec2 53 17)]))
          (if' [h0 "&gt;" 0.8] [
            continue
          ])
          (local sm float [[(float is) "+" 0.5 "+" 0.8 "*" [h1 "-" 0.5]] "*" STREAK_STEP])
          (local dir vec2 (rot [(vec2 c 1.0) "/" ct] [0.6 "*" [h2 "-" 0.5]]))
          (local tc float [[(float it) "+" 0.5 "+" 0.6 "*" [h2 "-" 0.5]] "*" dth])
          (local d vec2 (vec2 [sig "-" sm "+" c "*" [w.y "-" tc]] [w.y "-" tc]))
          (local len float [[0.22 "+" 0.22 "*" h1] "*" dth "*" ct])
          (local th float [[0.2 "+" 0.08 "*" h2] "*" STREAK_STEP "/" ct])
          (local a float (clamp (dot d dir) (neg len) len))
          (local dist float [[(length [d "-" dir "*" a]) "-" th] "*" r "/" px])
          (local cover float [(clamp [0.5 "-" dist] 0.0 1.0) "*" (smoothstep 0.6 2.0 [th "*" r "/" px])])
          (local pick int [(int [h0 "*" 16.0]) "%" 13])
          (local sc vec3 (cond [pick "&gt;" 8] (index PAL 9) (cycle [(float pick) "-" phase])))
          (set col (mix col [sc "*" [0.7 "+" 0.3 "*" h2]] [cover "*" band]))
        ];
      }))
      (local key (sized float 7) null)
      (local ord (sized int 7) null)
      (local outward vec2 (rot (vec2 1.0 0.0) (neg rho)))
      (for ({i}: {
        init = local i int 0;
        test = [i "&lt;" 7];
        step = inc i;
        body = [
          (set (index key i) (dot (cart (index NEAR i)) outward))
          (set (index ord i) i)
        ];
      }))
      (for ({i}: {
        init = local i int 1;
        test = [i "&lt;" 7];
        step = inc i;
        body = [
          (for ({
            j,
            t,
          }: {
            init = local j int i;
            test = [j "&gt;" 0 "&amp;&amp;" (index key (index ord [j "-" 1])) "&gt;" (index key (index ord j))];
            step = dec j;
            body = [
              (local t int (index ord j))
              (set (index ord j) (index ord [j "-" 1]))
              (set (index ord [j "-" 1]) t)
            ];
          }))
        ];
      }))
      (local wrap int [[M "+" N] "*" LOOP])
      (for ({
        i,
        cell,
        id,
        h0,
        h1,
        wc,
        rc,
        sc,
        scale,
        q,
        size,
        dist,
        fade,
        cover,
        rim,
        hc,
      }: {
        init = local i int 0;
        test = [i "&lt;" 7];
        step = inc i;
        body = [
          (local cell ivec2 [base "+" (index NEAR (index ord i))])
          (if' [(pmod cell.y N) "&gt;=" ARM] [
            continue
          ])
          (local id int (pmod [cell.x "*" N "-" cell.y "*" M] wrap))
          (local h0 float (hash (ivec2 id 911)))
          (local h1 float (hash (ivec2 id 37)))
          (local wc vec2 [(rot [(cart cell) "+" tt "*" drift] rho) "*" k])
          (local rc float (exp wc.x))
          (local sc vec2 [rc "*" (vec2 (cos wc.y) (sin wc.y))])
          (local scale float [k "*" rc])
          (local q vec2 [(rot [p "-" sc] (neg [wc.y "+" rho])) "/" scale])
          (local size float [0.5 "*" [0.88 "+" 0.36 "*" h1]])
          (local dist float [[(hexDist q) "-" size] "*" scale "/" px])
          (local fade float (smoothstep 3.0 9.0 [size "*" scale "/" px]))
          (local cover float [(clamp [0.5 "-" dist] 0.0 1.0) "*" fade])
          (local rim float (clamp [0.5 "-" dist "-" (max 1.0 [0.03 "*" size "*" scale "/" px])] 0.0 1.0))
          (local hc vec3 (cycle [h0 "*" 9.0 "-" phase]))
          (set col (mix col [hc "*" rim] cover))
        ];
      }))
      (set fragColor (vec4 col 1.0))
    ]);
    nearest = fn ivec2 [{h = vec2;}] ({
      h,
      y,
      c,
      r,
      d,
    }: [
      (local y float [h.y "/" S3])
      (local c vec3 (vec3 [h.x "-" 0.5 "*" y] y [(neg h.x) "-" 0.5 "*" y]))
      (local r vec3 (floor [c "+" 0.5]))
      (local d vec3 (abs [r "-" c]))
      (ifElse [d.x "&gt;" d.y "&amp;&amp;" d.x "&gt;" d.z] [
          (set r.x [(neg r.y) "-" r.z])
        ] (if' [d.y "&gt;" d.z] [
          (set r.y [(neg r.x) "-" r.z])
        ]))
      (return (ivec2 r.xy))
    ]);
    pmod = fn int [{a = int;} {b = int;}] ({
      a,
      b,
    }: [
      (return [a "-" b "*" (fdiv a b)])
    ]);
    rot = fn vec2 [{v = vec2;} {a = float;}] ({
      v,
      a,
      c,
      s,
    }: [
      (local c float (cos a))
      (local s float (sin a))
      (return (vec2 [c "*" v.x "-" s "*" v.y] [s "*" v.x "+" c "*" v.y]))
    ]);
  };
}
</pre>

</td>
</tr>
</table>

</details>

A directory holds a category or one module's assets. No file exists only to import others or to set values another module owns, except `modules/finix/desktop/default.nix`, whose import keeps the graphical role's system layer at its place in that merge order. This file is the only document: a module's notes are a section below, under its directory, and each paragraph and list item is one line.

Validate with `nix build --no-link`, so no result link lands in the repo.

### omp transcript presentation (`dev/ai/omp/`)

In Tern, omp's transcript gives each thing one level of attention:

- **The answer** that ends a turn sits in a bubble on the left, opposite your messages on the right.
- **Work** folds into one row per stretch of steps. A row leads with the sentence the model wrote before those steps, then the step count and time; a row with no such sentence reads **Worked for …**. It stays open while it runs and folds when the next sentence or the answer arrives. Folded, the sentence is cut to one line; open, it wraps in full with its links. Open the row for the model's reasoning, any further paragraphs and each step; open a step for its code and output.
- **Turn stats** (time, tokens, cost under each answer) are hidden by **hide turn stats** in Tern's UI options block; untick it to bring them back.
- **Chat looks** are three ticks in the **omp chat** group of Tern's UI options: **Grok chat** (unboxed 15/22 px answers, your message capped at 560 px, thinking and the composer's usage hidden, advisor notes as one dim "Advisor · …" line), **frosted bubbles** (your message and the composer frosted with a hairline) and **no streaming** (an answer shows once it is written). They style the `omp.chat.msg`, `omp.chat.dock` and `omp.chat.advice` blocks from [chat-look.ts](modules/dev/ai/omp/chat-look.ts), so they reach every omp chat, bots included. They inherit the rest from the Tern base sheet (`min.css` in tern-scratch): its tokens, column, fonts and hairlines, with Tern's own variables as the fallback without it.
- **Failures** show as a red count on their row. A failed step stays listed under the folded row only when the turn ended on it.
- **Notices** from omp and extensions keep their own small rows, inside a work row when they land mid-work.

The pieces:

- [code-mode.ts](modules/dev/ai/omp/code-mode.ts) asks for a short title on every eval cell, which becomes the step's name.
- [compact-eval.ts](modules/dev/ai/omp/compact-eval.ts) folds eval steps to their title, drops language badges, and names untitled steps after the tool they call or their first line.
- [work-fold.ts](modules/dev/ai/omp/work-fold.ts) builds the rows. Your messages, skill and collab prompts, `!`/`$` commands and compaction markers start a new stretch.
- [chat-look.ts](modules/dev/ai/omp/chat-look.ts) wraps each of your messages and the model's in an `omp.chat.msg` block, advisor notes in `omp.chat.advice` and the composer area in `omp.chat.dock`, for the chat looks to style. With tool activity hidden it tells the model so, to say in words what it found and ran. omp-bot loads it and `work-fold.ts` into every bot.
- The answer bubble, the quieter sentences, the rail under an open row and the chat looks are tweaks in the [UI Menu](modules/tools/tern/config/plugins/ui-menu/window.luau) Tern plugin.

omp is pinned by Nix, so its startup update check is off.

Restart existing omp sessions after changing the extensions; `tern plugin reload` picks up the stylesheet. They use omp's exported UI internals and Tern's Reader classes; after upgrading either, check a running turn, a finished turn, an opened row, a notice between two steps and a success → failure → success turn.

### OptChat memory (`dev/ai/omp/`)

Every omp chat, on the host and in the box, shares one memory built the way Victor Taelin's OptChat describes: an append-only log of messages, a binary tree of summaries of at most 512 bytes, and a view of 64–128 KB that covers the whole log, detailed for recent messages and coarse for old ones.

- [optchat/extension.ts](modules/dev/ai/omp/optchat/extension.ts) logs the user's messages and the agent's replies of each main chat (TUI or RPC mode, with a session file) to `~/.local/state/optchat/log/<session>.jsonl`, one writer per file. Tool calls, print-mode runs, subagents and the advisor are not logged, nor are turns from before a chat loaded the extension. The user's answers to `ask` questions are logged as the user's words, with the question. A chat gets the view ahead of its first message and keeps it frozen, so the prompt cache holds. omp still compacts the chat with its own summary, which keeps its tool work and older turns, and the extension then takes a fresh view. The `zoom`, `date` and `recent` tools read the memory.
- [optchat/service.ts](modules/dev/ai/omp/optchat/service.ts) runs as the `optchat` finit service, a headless omp. It merges the session logs into `main/`, has Luna 6 (`openai-codex/gpt-6-luna`, through the omp-box proxy so Crest picks the login) write the summaries into `tree.jsonl`, and writes `view.txt`. Every summariser call is a line in `spend.jsonl`; `optchat-spend` totals them per day at list price.
- The service shares `~/.local/state/optchat` with the box through `omp-box add`. The box reads its omp config at boot, so box chats join after the box restarts.
- `OPTCHAT_DIR` picks the store for both the extension and the service; without it they use `~/.local/state/optchat`, so the same code serves the shared store and every bot store.
- With `OPTCHAT_BOT` set, the store is one bot's own memory, used by omp-bot (`~/dev/developing/omp-bot`) for every bot. The memory is the bot's whole context: each model call gets the rules in `OPTCHAT_RULES` word for word, then the view, then the latest turns raw, tool calls included. The current run, from the user message being answered on, always stays raw; the turns before it fill up to `OPTCHAT_RAW` bytes (128 KB), cut back to half and re-viewed when they outgrow it. Sizes count each image as 4,800 bytes, not its base64 length. When a request would pass the model's context window less its output reserve (the smaller of its max tokens and a quarter of the window), measured by the last reply's reported usage or else at four bytes a token, the run is folded at an assistant reply, the oldest that leaves half that room or else the latest that fits, and the folded part's user message and `ask` answers go ahead of the raw turns; if even that does not fit, the turn is aborted with an error rather than sent. A bot's first start logs the conversation it already has; its `pin_rule` tool appends a standing rule to the rules file. With `OPTCHAT_BOTS`, the folder holding each bot's `NAME/optchat`, `zoom`, `date` and `recent` take an optional `bot` to read another bot's memory read-only, and `memories` lists the bots that keep one. The service tells the summariser it writes one bot's memory. [dev/ai/omp-bot.nix](modules/dev/ai/omp-bot.nix) points omp-bot at this directory with `OMP_BOT_OPTCHAT`; it is the same store path as the extension in the omp config, so a bot that loads your extensions loads it once.

### /cwd (`dev/ai/omp/`)

[cwd.ts](modules/dev/ai/omp/cwd.ts) adds `/cwd` to every omp chat: `/cwd` alone shows the working directory as a notice, and `/cwd DIR` moves the chat there by running omp's `/move DIR`, with the same directory completion. Moving works in the TUI only, as `/move` does.

### Secrets (`dev/ai/omp/`)

[secrets/secrets.ts](modules/dev/ai/omp/secrets/secrets.ts) lets every omp chat use a secret (an API key, a token) without the value reaching the model, the session file or OptChat.

- The chat asks with its `secret` tool, naming the secret, saying why and optionally how long it should last (`30m`, `12h`, `7d` or `never`; default 24 hours). In a terminal chat (omp's TUI, which Tern draws natively) the tool opens a masked box in place of the composer: the terminal draws, and Tern is sent, one bullet per character, Enter stores the value the way `omp-secret` does and Esc closes it, leaving the ask open; the box also closes when the turn stops or the secret is set elsewhere. The value goes from the box to age and nowhere else, so neither the model, the session file nor OptChat sees it. A chat without the TUI (a headless bot, RPC) waits up to 10 minutes, its tool card saying the box opens when the chat is open in a terminal, and a bot's asks still open when its tab opens show the same box there; `omp-secret` alone lists every open ask and the secrets set.
- The chat's own request is the only way in: by default it stores the secret for that bot (or, outside a bot, shared); `shared` true, for when you ask for it, stores it shared with every bot instead. A boxed bot can't add a shared one, since its store holds only a copy of them.
- `omp-secret NAME [--bot BOT | --user] [--ttl TTL]` reads the value with the typing hidden (or from stdin when it isn't a terminal) and stores it for whoever asked; `list` shows names, scopes and expiry, never values, and `forget NAME` deletes one. The chat's `secret` tool can list and forget its own too.
- The chat uses a secret by writing `$SECRET_NAME` in a bash command. The `tool_call` hook reruns the command, unchanged, through `omp-secret run` as a heredoc: that decrypts only the secrets the command names, sets them for that one command (run with `bash -c`, so a `cd` in it doesn't last) and replaces each value in its output with `[SECRET_NAME]` as it streams. A command naming a secret the chat doesn't hold is blocked and told to ask. Every tool result is also scrubbed of every value the chat holds (or held earlier in the run) in the `tool_result` hook, before it reaches the model, the session file or OptChat, and the `context` hook scrubs what the model is sent. Live progress of a command that prints a value without naming it is not scrubbed while it streams; its result is. omp runs as you, so a chat could still smuggle a value out in another form (base64, say); redaction catches the exact value only.
- Secrets live in `~/.local/state/omp-secrets`, persisted across reboots: each one age-encrypted to `secrets.key` (mode 600, made on first use) with its expiry and reason beside it. A chat started by omp-bot (`OMP_BOT_NAME` set) keeps its secrets in `bots/NAME/`, so a bot can't use another bot's by name. `user/` holds the shared ones: every other chat uses them, and a bot reads one when it holds no copy of its own under that name (its own wins). A boxed bot's store is its own folder, `secrets/` in its omp-bot folder (`OMP_SECRETS_DIR`, shared into the box), with a key of its own; from the host, `omp-secret` and the extension resolve a bot whose bots.json entry has `"box": true` to that store, and keep a copy of every shared secret in its `user/`, sealed with its key: on store and forget, and through `omp-secret sync --bot BOT`, which omp-bot-box runs before the bot starts. That is a boundary against mistakes, not an attack: everything runs as you and can read the key.
- age rather than the kernel keyring because secrets should outlive a reboot, and the keyring a service-run bot reaches isn't reliably the one your terminal stored into.
- omp-bot loads this and [cwd.ts](modules/dev/ai/omp/cwd.ts) into every bot through `OMP_BOT_CWD_EXTENSION` and `OMP_BOT_SECRETS_EXTENSION` in `~/.config/omp-bot/env`, even when the bot's own extensions are off. omp-box chats don't load it.

### Dated overlays (`dev/ai/omp/`)

`omp-until DIR OMP [ARGS...]` runs `OMP ARGS...` with each `DIR/config.until-DATE.yml` whose DATE (as `date -d` reads it, such as `2026-11-04T13:00`) is still ahead added as a `--config` overlay after the other arguments, so it wins over every earlier overlay, and an expired one is skipped. `OMP_UNTIL` tells omp and its extensions when the earliest of them ends, in epoch milliseconds, empty when none applies; omp itself doesn't drop an overlay mid-run, so whoever needs that restarts on it. `omp-until ~/.omp/agent omp` gives a plain chat dated overlays next to its config; omp-bot runs every bot through it on the bot's state folder, and a bot restarts once idle after its overlay ends.

### omp-bot persistence and boxed bots (`dev/ai/omp-bot.nix`, `omp-box/`)

- A bot's `persist` folders (its roster entry, see omp-bot's README) are persisted with no allowlist line of their own: `user.persist.directorySources` takes programs that print more home-relative directories, and the omp-bot module gives it `omp-bot-persist-paths`, which reads every bot's `persist` from the persisted roster (`/persist/home/<user>/.local/state/omp-bot/bots.json`). `persist-user-binds` mounts them at boot after the static allowlist, skipping an entry that is absolute, holds `.` or `..`, or resolves outside home; a bad entry is logged and never fails the boot.
- `OMP_BOT_PERSIST` in `~/.config/omp-bot/env` is `omp-bot-persist`: `mount PATH` copies a folder into `/persist/home/<user>` the first time and binds it over itself with sudo, so a bot declared while the machine runs is persistent at once; `purge PATH` unmounts it and deletes both copies, run only by `omp-bot-remove NAME --purge`. Removing a bot leaves its persisted data where it is; it is just not mounted from the next boot.
- `~/.config/omp-bot/box.env` is read for a bot with `"box": true`: it points `OMP_BOT_BOX_SSH_CONFIG` at an ssh config for the box (the omp-box key, port 22422) and unsets Crest auth, the secrets extension and `OMPD_SERVICE`, which are the host's.
- `omp-box add PATH --name NAME` names a grant instead of using PATH's folder name, so `bots/baobao` and `~/.local/state/baobao` can both be shared.
- The box has bun (ompd and `omp-bot-ctl` for boxed bots) and Noto Sans CJK, so Chinese pages render in its Chromium, and makes `~/.omp`, `~/.cache`, `~/.config`, `~/.local`, `~/.local/share` and `~/.local/state` the user's at boot, before shares mounted with sudo would leave them root-owned. Each entry of the box's `browsers` (in `ai_omp_box`) is a `browser-NAME` service in the box running headless Chromium on its profile, with DevTools on `127.0.0.1:PORT` inside the box and a Chrome user agent instead of HeadlessChrome; it restarts every 5 s until the profile's folder is a share, and clears the profile's stale singleton lock first. `browsers.baobao` keeps baobao's Taobao profile in `~/.local/state/baobao/chromium` on port 9222. Changing the box's packages or services needs `omp-box` restarted.

### Vercel accounts (`dev/work/vercel/`)

The module installs three executable commands, including in noninteractive agent shells: `vercel`, `vercel-personal`, and `vercel-work`.

Plain `vercel` selects a login in this order:

1. `VERCEL_ACCOUNT=personal` or `VERCEL_ACCOUNT=work`.
2. The GitHub `origin` owner: `y0usaf` routes to personal; no work owner is configured.

Unknown contexts fail with instructions. `--cwd` participates in routing. `--scope` and `vercel switch` select a team within that login. They do not change accounts. The repository's `.vercel/project.json` still selects the project. Explicit upstream `--global-config` and `--token` flags bypass account routing.

Authenticate each profile once with `vercel-personal login` and `vercel-work login`. Select the corresponding browser account during each login, then confirm using `vercel-personal whoami` and `vercel-work whoami`. Existing default credentials are not copied to either profile.

Credentials live in `$XDG_DATA_HOME/com.vercel.cli/profiles/{personal,work}`, falling back to `~/.local/share/com.vercel.cli/profiles/{personal,work}`. The default location is already persisted on the desktop and Framework hosts.

For agents: use plain `vercel` inside a recognized repository. If routing fails, use repository context to choose `vercel-personal`/`vercel-work`, or ask the user when ownership is unclear. Use `whoami` to inspect the selected identity. Do not retry a failed deployment under another account without establishing ownership. `vercel --help` also explains routing.

The router remains a Python runtime program because account selection depends on live arguments, working directory, environment and Git remotes. Native Nix renders its static owner map but cannot perform those runtime decisions. Local routing test outputs are retired; verify the system build without activation:

```sh
nix build --no-link path:.#nixosConfigurations.y0usaf-desktop.config.system.build.toplevel
```

### Persona 4 Golden Community Enhancement Pack (`gaming/p4g/`)

The desktop enables `user.gaming.p4g.enable`. `p4g-setup` pins CEP 13.99.4's full offline archive, Reloaded II 1.30.3, Windows Desktop Runtime 9.0.20 (x64 and x86), and the Visual C++ redistributables. It preserves CEP's bundled mod selection, order, and user settings; `enabledMods` in the module's settings takes an ordered list of mod IDs to override that selection.

```sh
nix build --no-link .#p4g-setup
nix run .#p4g-setup -- prepare  # safe while playing; prepares files outside Steam
nix run .#p4g-setup -- status
# Save and close P4G before this step:
nix run .#p4g-setup -- install
```

Setup must run as the Steam user. Steam must already have installed the game and created its Proton prefix by launching it once. Installation refuses to run while `P4G.exe` is active and does not stop Steam, OBS, or the desktop session. Keep P4G closed until installation finishes. For a nonstandard Steam layout, change `gameDirectory` and `prefixDirectory` in the module's settings. System activation does not run the setup helper automatically.

The writable loader lives in `~/Games/P4G-CEP/generations`; `Games` is already persisted on the desktop. Changing the module's `stateDirectory` requires arranging persistence for its new location. Each payload/configuration has its own generation. Runtime caches and logs are writable; old generations remain for rollback. Preparation reuses existing generations without overwriting their runtime settings.

Installation backs up the entire P4G prefix and any managed game files under `~/Games/P4G-CEP/backups/<timestamp>`, with installer output in `setup.log`. It records installed runtime hashes inside the prefix, installs the x64 ASI loader as `version.dll`, and adds the Reloaded bootstrapper. An application specific Wine registry override enables it on the normal Steam entry, so no Steam launch-option edits or Steam restart are needed. Foreign files at these destinations are never overwritten. The pack expects the 64-bit game with English text.

To return to vanilla P4G, save and close the game, then run:

```sh
nix run .#p4g-setup -- disable
```

This removes the two managed injection files. Saves, runtime installations, mod settings and backups remain. A full prefix restore is a separate recovery operation: copying an old prefix over a newer one can replace newer saves.

The upstream CEP guide specifies Proton 8.0-5. This integration preserves the game's selected Proton version. On 2026-09-10, Proton Experimental successfully initialized the loader and bound 4,809 modded files; P4G's opening rendered in the live OBS capture. A Nix build alone does not establish game compatibility. The desktop needed its open-file limit raised from 4,096 to 524,288. After an interrupted first asset build, the generated `Mods/p5rpc.modloader/Cache` and `Mods/crifs.v2.hook/Bind` directories were moved aside and rebuilt successfully. The module raises Finit's hard limit and declares the user's soft/hard limit in `/etc/security/limits.conf` for subsequent logins. During installation, the running Steam process's limit was raised with `prlimit` without restarting Steam. The built desktop has not been activated during the stream; apply it normally afterward to persist the login policy.

Sources: [CEP](https://gamebanana.com/mods/50961), [CEP installation guide](https://p4g-deck.cep.one/install/download-and-prepare), [Reloaded 1.30.3 ASI deployment](https://github.com/Reloaded-Project/Reloaded-II/blob/1.30.3/source/Reloaded.Mod.Launcher.Lib/Utility/AsiLoaderDeployer.cs), [Reloaded injection methods](https://reloaded-project.github.io/Reloaded-II/InjectionMethods/).
