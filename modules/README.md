# Repository layout

This repository configures y0usaf's machines on finix: it owns system
integration and user configuration, not application implementations.
Headlong operations live in `~/dev/developing/headlong-ops`. A project that
stays external comes in as a flake input. Keep runners, application patches,
reusable skills and their tests with the module or project that owns them.
Runtime state and credentials stay outside the source tree and the Nix store.
Don't create root-level `nix/`, `tests/` or `previews/` directories.

`flake.nix` is the whole configuration: `strictix merge . --entry flake.nix
--out flake.nix --expand nixFiles` collapsed the tree into it, one let binding
per file under its `outputs`, named after the file's path, with
`merge_manifest` recording each binding's path and the expanded `nixFiles`
calls. The paths below are those manifest paths; `strictix split . --merged
flake.nix` writes the tree back byte for byte, and `nix run .#lint` lints each
binding at its path. `modules/outputs.nix` builds every output with let
bindings and plain functions. No module system runs at flake level.

A host is a list of modules, and the `hosts` attrset in `modules/outputs.nix`
holds each host's list. Every host loads `modules/finix/common.nix`,
`diagnostics.nix` and `sudo.nix`: the settings all hosts share, boot
diagnostics and sudo. The graphical hosts load every `.nix` file under the
graphical roots (`core`, `desktop`, `dev`, `gaming`, `shell`, `tools`,
`user-services` and `hosts/common`), so each of those files is a module; the
server names its modules one by one: its role in `modules/server/`, its host
files and a few program modules.
`modules/hosts/common/` is the graphical role. Its system layer,
`modules/finix/desktop/`, is imported from `graphical.nix` instead of loaded
as a root. Roots load in path order, and a list option merges in load order,
so moving a module moves its packages, kernel modules and udev rules within
those lists and changes the build.

Loading a module turns it on. A module declares an option only when the hosts
that load it need different values, or when three or more modules read the
value. Anything else is written where it is used, and a helper one module
uses is a let binding in that module.

A program's module owns its packages, settings, dotfiles and persisted paths,
and decides from hardware facts such as `hardware.nvidia.enable`, never from
the hostname. A program that needs only its package is a line in its
category's package list: `core/packages.nix`, `desktop/packages.nix`,
`dev/packages.nix`, `tools/packages.nix`, `gaming/core.nix` or
`server/packages.nix`. `tools/tmux.nix` stays a module of its own because the
server loads it by name. Persisted paths no module owns go in
`modules/hosts/common/persist.nix` when both graphical hosts keep them, and in
the host's `config.nix` when only that host does.

`dev/ai/pi/default.nix` holds the shared model catalog. Omp uses
`ompThinkingLevel = "auto"` and the DeepSeek V4.1 Flash 1017 Fast
`judgeModel` for per-prompt effort selection. `dev/ai/omp/default.nix` applies these
on the host, and `dev/ai/omp/box.nix` applies them in the microVM. Pi keeps
its separate `defaultThinkingLevel = "xhigh"`; the advisor stays Sol at high.

Each host directory under `modules/hosts/` holds what is true of that machine
alone, in two files beside its keys and other data.
`hardware-config.nix` holds facts about the machine: disks, btrfs subvolumes
and mount options, boot, kernel and initrd modules, firmware, GPU and
displays. `config.nix` holds the host's choices: hostname, open ports,
host-only persisted paths, services, and where it departs from its role.
`modules/hosts/shared.nix` holds the machinery the hosts share, a btrfs mount
builder and the nftables ruleset, which each host calls with its own values;
hosts import it, and no host list loads it. `modules/hosts/android-phone/` is
the nix-on-droid phone.

`modules/hosts/steam-frame/` is the Steam Frame, which runs NixOS, not finix.
The external steam-frame-nixos project supplies the Frame itself as
`nixosModules.default`, pinned as the non-flake input `steam-frame-nixos`;
`nix flake update steam-frame-nixos` moves it, and `FRAME_REPO=<checkout>`
deploys a local checkout instead. Everything personal about the Frame lives
here. `config.nix` holds the host's choices: the SSH keys, the storage pool's
UUID, the project's optional WiVRn client and framecorder, Stremio in Steam's
FHS environment, the Beat Saber mods, `tools/git.nix` and `tools/tmux.nix`,
and files linked with manzil; `bolo.nix` runs bolo on the CPU and fetches its
speech model at boot into the big home partition, out of the small root;
`mado.nix` runs mado-view whenever SteamVR runs, so the headset shows the PC's
mado stream. `deploy.nix` builds `finix-frame-deploy`, which builds a NixOS
system from the project's nixpkgs and module, manzil's NixOS module,
`config.nix`, manzil's static aarch64 linker (cross-built on this machine) and
bolo's and mado's aarch64 packages (`--impure`), then copies and switches the
Frame over ssh. The rest of the closure builds under the qemu aarch64 binfmt
handler; `finix-frame-deploy` names the command that registers it when it is
missing.

`omarchy.nix` runs the desktop layer of Omarchy 4.0.4 (Hyprland and its
QuickShell shell) as a SteamVR overlay: a nested Hyprland is a client of a
second gamescope (`--backend openvr --expose-wayland`), and Aquamarine needs
the three fixes in `omarchy/aquamarine-gamescope.patch`. Nothing starts it:
`systemctl --user start omarchy` over SSH does, and it stops whenever SteamVR
restarts. Its `ExecStopPost` removes what Hyprland and Quickshell leave in
`$XDG_RUNTIME_DIR`; Omarchy's own state stays in the home. Its menu actions
act on the host's services. Quickshell 0.3.1 ignores a NetworkManager profile
without `mode=infrastructure`, which steam-frame-nixos's
`tools/wifi-from-nm.py` writes. On the Frame it drew its bar, menu and a
terminal and ran 15 minutes on the live session without an error; how it looks
in the headset, shortcut keys, theme switching and the audio, Bluetooth and
power actions are unverified, and screen recording, the screensaver and the
lock screen are unavailable.

`beat-saber.nix` installs BeatMods mods into Beat Saber by name, from
`frame.beatSaber.mods` in `config.nix`; BSIPA and each mod's dependencies come
along. `beat-saber/beatmods.data.nix` pins every verified mod for one game version
with hashes; `nix run .#beat-saber-lock -- <game version>` prints a fresh lock as
Nix data to replace it with, and a name not in it fails the build. BeatMods has mods for 1.44.1, so the game needs
Steam's `1.44.1_legacy` branch, and its launch options must be
`/run/current-system/sw/bin/beat-saber-mods %command%`. Each launch copies the
declared set into the game folder, deletes files of the previous set, and
starts the game with `WINEDLLOVERRIDES=winhttp=n,b` and `--no-yeet`.
`.nix-mods/` in the game folder holds the unpatched
`UnityEngine.CoreModule.dll` BSIPA patches and the installed file list; a file
of yours a mod replaces is kept there too and comes back when the mod goes. An
empty list, or a game version the mods aren't for, restores the game on the
next launch, keeping `UserData`, `Logs` and your own files. Problems go to
Steam's journal (`journalctl --user -u steam | grep beat-saber-mods`). Under
Proton 11.0 (ARM64) the mods load and BeatSaverDownloader downloads songs, but
starting any song fails: InvalidCastExceptions in Zenject injection and
MonoMod's struct-return glue freeze the level.

`modules/finix/sudo.nix` configures sudo itself and takes only the privileges
provider from finix's sudo module. Leave `programs.sudo.enable` off: it also
installs the non-setuid sudo binary, which shadowed the
`/run/wrappers/bin/sudo` wrapper on PATH (c9a60e8c).

`modules/finix/tailscale.nix` runs tailscaled on the server and, through
`graphical.nix`, on the graphical hosts. It makes openresolv the owner of
`/etc/resolv.conf` so that tailscaled (openresolv mode), dhcpcd and
NetworkManager share it: tailscaled goes first with MagicDNS, DHCP servers
follow and public servers come last with a one-second timeout, so DNS survives
tailscaled being down. tailscaled starts after the `resolvconf` task because
it picks its DNS mode from the header that task writes. Hosts name each other
by MagicDNS. `tailnet.addresses` keeps the addresses of the places that need
one: the `rescue` and `rescue-root` ssh hosts, which must work when DNS is
broken, paseo's listen bind and the server's hosts aliases.

The configuration reads no file but Nix. Data a module reads lives in a
`.data.nix` beside it and is rendered by a generator in `modules/generators.nix`,
byte-identical to the file it replaced. Data formats are structured: JSON values
(an object lists its key order in `__keys` only when that differs from
`builtins.attrNames`), TOML groups, Cargo.lock packages, INI and `key=value`
groups, an XML element tree, SSH key fields and PEM base64 blocks. Lisp, shell,
Luau, VBScript, patches, markdown, GLSL and Lua are syntax trees (below). The
other code and prose (TypeScript, JavaScript and Python) are still line lists,
one string per line, whose `<language>Source` generators only join the lines. A
file passed by path comes from `generators.sourceFile`, whose store path is the
one the file had; `generators.sourceDir` builds the optchat directory from its
files.

### Code as syntax trees

`generators.doc` is a Wadler/Leijen pretty-printer. A document is a string
(text; it may hold newlines, which reset the column), a list (concatenation),
`line` (a space, or a newline when its group breaks), `softline` (nothing, or a
newline), `hardline`, `nest n d` (d's newlines indent n further), `align d`
(d's newlines indent to the current column) or `group d` (d flat when it fits
the width, else broken). `doc.render width d` lays it out; a `null` width
never breaks a group. Layout is a `builtins.genericClosure` stack machine, one
step per document node with the column forced at each step, so neither
recursion depth nor thunk chains grow with the file; indentation is written
lazily, so blank lines carry no trailing spaces. Columns count bytes. Tomoe's
`deck.lisp` (400 lines, 20 KB, the largest converted file) renders in 0.03 s
and 12 MB of allocation; 4000 lines take 0.27 s and 130 MB. GLSL breaks a file into more nodes: tomoe's
`hex-spiral.glsl` (160 lines, 5.4 KB) renders in 0.13 s and 40 MB.

A language is `generators.<language>`: constructor functions and `render`, a
function from a list of top-level nodes to text, built on `generators.doc`.
Nodes are Nix values: a plain list or string where the language's own shape is
a list of words (a Lisp list or symbol, a shell command or word), otherwise a
one-attribute set made by a constructor (`str "x"` is `{str = "x";}`), so a
printer dispatches on the node's kind. Comments and blank lines are nodes
(`comment`, `blank`); nothing in a file is lost. The printer owns the layout
the language's style decides; the tree records only what it cannot decide,
with names every language shares: `rows` (written over several lines),
`inline` (written on one line), `at n` (an indent the rules do not give) and
`blank`; `wrap` asks for a width-aware layout instead. A data file is a
function of the constructors it uses, rendered with
`generators.<language>.render (import ./x.data.nix generators.<language>)`.

Lisp (`generators.lisp`): a list is a Nix list, a symbol or number a string
(an integer may be a Nix integer), `str` a string literal, and `quote`,
`quasi`, `unquote`, `splice` and `function` the reader prefixes `'`, `` ` ``,
`,`, `,@` and `#'`. A list without `rows` prints on one line. `rows [ ... ]`
holds one row per source line: a list of the items on that line, or one item
that is not a plain list. Rows after the first indent by Emacs' Common Lisp
rules: the body of `defun`, `let`, `when` and the other forms in `bodies` by
2 and their distinguished arguments by 4, the local functions of `flet`,
`labels` and `macrolet` like a `defun`, a call's arguments under its first
argument, `cond` clauses by 2, anything else under the head. From
`tomoe/lisp/deck.data.nix`, abridged:

```nix
{blank, function, quote, rows, str, ...}: [
  ["in-package" "#:tomoe-user"]
  blank
  ["defun" "deck--fronts" ["state"] ["getf" "state" ":fronts"]]
  (rows [
    ["defun" "deck--side-of" ["state" "id"]]
    [["let" [["entry" ["deck--entry" ["getf" "state" ":columns"] "id"]]] ["and" "entry" ["cdr" "entry"]]]]
  ])
  (rows [
    ["defparameter" "+deck--column-commands+"]
    (quote [(str "focus-left") (str "focus-right") (str "swap-columns")])
  ])
]
```

Shell (`generators.shell`): a command is a Nix list of words. A word is a
string (written as it is), `dq` (a double-quoted string, its parts strings
and `sub`), `sq`, `ansic` (`$'...'`), `sub` (`$(...)`), `word` (parts written
together), `array`, `assign name value`, `redir op target` (spaced before a
quoted target) or `heredoc start body`. A statement is a command, `assign`,
`pipe`, `chain [a "&&" b]`, `fn name body`, `braces`, `if' test body`,
`ifElse test body otherwise`, `for name words body`, `while test body` or
`case subject [(arm patterns body)]`. A body is a list of statements, one per
line two spaces in, or `inline [ ... ]` on one line; `rows` breaks a pipe or
chain after each operator. From `omp-box/omp-box.data.nix`, abridged:

```nix
(fn "fail" (inline [["printf" (sq "omp-box: %s\\n") (dq "$*") (redir ">&" "2")] ["exit" "1"]]))
blank
(fn "cmd_rm" [
  ["local" (assign "name" "\${1:-}")]
  (chain [["[" "-n" (dq "$name") "]"] "||" ["fail" (dq "rm needs a name")]])
  ["local" "path" "mode"]
  [(assign "IFS" (ansic "\\t")) "read" "-r" "path" "mode" (redir "<" (dq "$grants/$name"))]
  (if' ["up"] (inline [["unmount_guest" (dq "$path")]]))
])
```

Luau (`generators.luau`): a call is a Nix list, its function first. A name,
a dotted path (`cx.session`, or `cx.session:focused` heading a call), a number
or `nil`, `true` and `false` is a string (an integer may be a Nix integer).
`str` is a quoted string, in the quote StyLua picks, whose parts may include
`unicode "2061"` escapes; `long` is a `[[...]]` string. `table` holds values,
`field name value` and `pair key value`; `infix [a ".." b ".." c]` is a run of
one operator (another operator is a nested `infix`); `unary`, `paren`, `dot`,
`colon`, `idx`, `fn params body`, `ifExpr [test value ... otherwise]` and
`cast` are the rest, `tuple` is an expression list (or a tuple type) and
`typed x type` annotates a name or, around a parameter list, gives a function's
return type. A type is a name, `opt`, `table` or `tuple`. A statement is a
call, a keyword (`"return"`, `"break"`), `local`, `assign`, `update "+=" target
value`, `return`, `function`, `localFunction`, `if'`, `ifElse` (whose
`otherwise` is an `elseif` when it is itself an `if'` or `ifElse`), `for`,
`forRange`, `while`, `type` or `trailing statement comment`; a body is a list
of statements, one per line a tab in. `rows` writes a call (one argument per
line), a table (one entry per line, with `blank` and `comment` entries), an
`infix` run (a line per operator), a `colon` (on its own line) or an `ifExpr`
(then a list of the rows of its parts) over several lines, the way StyLua
breaks them. From `tern/config/plugins/tab-order/window.data.nix`, abridged:

```nix
{assign, blank, fn, if', infix, localFunction, opt, str, tuple, typed, unary, ...}: [
  (localFunction "place" [(typed "cx" "WindowCx") (typed "id" "number") (typed "anchor" (opt "number"))] [
    (if' (infix [(unary "not" "anchor") "or" (infix ["anchor" "==" "id"])]) [
      "return"
    ])
    (if' (infix ["info.position" ">" (infix ["at.position" "+" 1])]) [
      ["cx.layout:order_tab" "id" (infix ["at.position" "+" 1])]
    ])
  ])
  blank
  ["tern.on" (str "window_start") (fn [(typed "cx" "WindowCx")] [
    (assign ["last" "previous"] (tuple ["nil" "nil"]))
    ["note" ["focused_tab" "cx"]]
  ])]
]
```

VBScript (`generators.vbs`): a statement that is a Nix list is an invocation
(`["WScript.Quit" "1"]`, `WScript.Quit 1`), and a list inside an expression a
call (`["sh.Run" "cmd" "0" "True"]`); an identifier, number or member path is a
string, `str` a string literal (its quotes doubled on output) and `op` operands
and operators written spaced. Statements are `option`, `onError`, `dim names`,
`assign name value`, `set name value`, `if' test body` and
`ifElse test body otherwise`, bodies one tab in.

Patches (`generators.patch`): a patch is a list of files, `file path hunks`
(`--- a/path`, `+++ b/path`) or `git path index hunks`, which adds the
`diff --git` and `index` lines. A hunk is `hunk start lines` or `section start
heading lines` (the text after `@@`), `start` the old file's first line. A
context line is a string, a changed line `add` or `del`. The printer counts
each hunk's lines and derives its new start from the hunks before it, so the
`@@` header is never written by hand. From
`shell/rush/login-command.data.nix`, abridged:

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

Markdown (`generators.markdown`): a paragraph is a string or a list of
inlines, `wrap` a paragraph filled to 78 columns, `heading level text`,
`bullets [ ... ]` a tight `- ` list of paragraphs, `table [header rows...]` a
`| a | b |` table under a `|---|` row, and `comment` an HTML comment. An
inline is a string, `code`, `strong`, `em` or `link text url`. From
`tern/config/plugins/tuturu/README.data.nix`, abridged:

```nix
{blank, code, heading, table, wrap, ...}: [
  (heading 2 "Sounds")
  blank
  (wrap [(code "~/finix/modules/tools/tern/default.nix") " builds the three sounds and writes " (code "~/.local/state/tern/plugin-data/tuturu/sounds.toml") " to name them:"])
  blank
  (table [
    ["Trigger" "Sound"]
    [[(code "yield") ": an omp agent finished its turn"] "Tuturu, at the right ear"]
  ])
]
```

GLSL (`generators.glsl`): a statement or expression is a Nix list of words,
written spaced (no space before `,`), and ends in `;` as a statement; a list
among the words is a parenthesis. A word is a string (a name, a number, a
field like `uv.x` or a prefix like `-q.y`; an integer may be a Nix integer) or
`call f args`, `index base at`, `field base name` and `unary op operand` where
the base or operand is not a word. A statement is also `fn signature body`,
`define name value` (`#define`), `if' test body`, `ifElse test body otherwise`
(an `if'` as `otherwise` is `else if`), `for init test step body` or
`while test body`. A body is a list of statements, one per line four spaces
in, `inline [ ... ]` (`{ a; b; }`) or `bare s` (unbraced). `rows` breaks a
statement's words over lines, each row after the first under the first
assignment operator unless `at n`; `rows` as `call`'s arguments puts each row
under the first argument, or, when the first row is empty, four spaces in
with `)` on its own line. The importer parses `float(x)` and the other scalar
constructors as calls, since tree-sitter-glsl reads `(float(x) + y)` as a
broken cast. From `tomoe/shaders/glass-mound.data.nix`, abridged:

```nix
{call, fn, for, if', inline, rows, ...}: [
  ["const" "float" "IOR" "=" "1.33"]
  (fn ["vec3" (call "normal" [["vec3" "p"] ["float" "t"]])] [
    ["vec2" "e" "=" (call "vec2" ["0.002" "0.0"])]
    ["return" (call "normalize" [(call "vec3" (rows [
      [[(call "map" [["p" "+" "e.xyy"] "t"]) "-" (call "map" [["p" "-" "e.xyy"] "t"])]]
      [[(call "map" [["p" "+" "e.yxy"] "t"]) "-" (call "map" [["p" "-" "e.yxy"] "t"])]]
    ]))])]
  ])
  (fn ["void" (call "mainImage" [["out" "vec4" "fragColor"] ["in" "vec2" "fragCoord"]])] [
    (for ["int" "i" "=" 0] ["i" "<" 110] "i++" [
      (if' ["d" "<" "near"] (inline [["near" "=" "d"] ["at" "=" "s"]]))
    ])
  ])
]
```

Lua (`generators.lua`): a call is a Nix list, its head first; a name, a
dotted path (`pg.me:getPosition` as a call's head), a number or `...` is a
string, an integer may be a Nix integer, and `null`, `true` and `false` are
`nil`, `true` and `false`. `str` and `sq` are string literals, `table` a table
of positional values, `field name value` and `key k v`, `fn params body` a
function, `op [a "and" b]` a run of one binary operator, `not`, `neg`, `len`
and `bnot` the unary ones, and `dot`, `method`, `index`, `paren` and `apply`
(`f{...}`) the rest. A statement is a call, `"break"`, `";"`, `local names
values`, `assign targets values`, `function` or `localFunction name params
body`, `return values`, `if' test body`, `ifElse test body otherwise` (an
`if` node as `otherwise` is `elseif`), `forIn`, `forNum`, `while`, `repeat` or
`do`. A body is a list of statements, one per line two spaces in, or `inline [
... ]` on the keyword's line; `rows` puts each row of a table's fields on its
own line, and breaks an `op` before a row's first operator, two spaces in.
From `aniimo/catch-lua.data.nix`, abridged:

```nix
(localFunction "safely" ["fn" "self"] [
  (if' "off" (inline [(return [])]))
  (local ["ok" "err"] [["pcall" "fn" "self"]])
  (if' (not "ok") (inline [["disable" "err"]]))
])
```

Converting is mechanical: `strictix import <language> FILE` parses the file
with the language's tree-sitter grammar and prints its tree, and refuses
layout the printer would not give back (a double space, a trailing comment).
In `modules/lint.nix`, a codec `<id> = {extensions = []; generator =
"<language>Source";};` makes strictix flag `generators.<language>Source
(import ./x.data.nix)`, and `nix run .#lint -- fix` runs the import, rewrites
the data file and the call, and keeps the change only when
`generators.<id>.render` returns the line list's text byte for byte. Lint fix
edits files, so it runs on a split tree (`strictix split . --merged
flake.nix`, then `strictix merge . --entry flake.nix --out flake.nix --expand
nixFiles`). A template that interpolates Nix values
(`theme/templates/osc.data.nix`) is converted in place by `strictix import`,
which keeps the interpolations inside the tree's strings. Once a language has
no line lists left, its `<language>Source` generator and its codec go.

Every converted file passed its gate. A language whose printer can reproduce
its files gates on bytes at conversion; one that cannot gates on its official
formatter's output for both sides. `checks.codegen` (`modules/lint.nix`)
then runs each language's own check on every rendered tree, listed in its
`trees`:

| Language | Gate at conversion | `checks.codegen` |
| --- | --- | --- |
| Lisp (15 files) | bytes | SBCL's reader, the one tomoe and ekko run |
| shell (3 files) | bytes | `bash -n`, `shellcheck -S warning` |
| Luau (8 files) | bytes | `luau-analyze` reports no syntax error (its type errors need Tern's `tern.d.luau` definitions, which the repo does not hold) |
| VBScript (1 file) | bytes | `strictix import vbs`, a parse by tree-sitter-VB6-VBA-VBS (no VBScript checker runs on Linux) |
| patches (3 files) | bytes | `git apply --check` against the source each patches |
| markdown (7 files) | bytes | comrak (CommonMark and GFM tables): the rendered file's AST equals the AST of comrak's own CommonMark rendering of it |
| GLSL (7 files) | bytes | `glslangValidator -S frag` on each shader inside tomoe's ES 3.00 prelude and `main` |
| Lua (3 files) | bytes | `luajit -bl` for Aniimo's two LuaJIT mods, `luac -p` (Lua 5.5, Hyprland's) for `hyprland.lua` |
| TypeScript, JavaScript, Python | line lists, not converted yet | none |

A directory holds a category or one module's assets. No file exists only to
import others or to set values another module owns, except
`modules/finix/desktop/default.nix`, whose import keeps the graphical role's
system layer at its place in that merge order.

Validate with `nix build --no-link`, so no result link lands in the repo.
