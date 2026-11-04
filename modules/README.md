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
byte-identical to the file it replaced (GLSL, read for meaning, renders a
reformatted file of the same program; below). Data formats are structured: JSON values
(an object lists its key order in `__keys` only when that differs from
`builtins.attrNames`), TOML groups, Cargo.lock packages, INI and `key=value`
groups, an XML element tree, SSH key fields, PEM base64 blocks and gitignore
patterns. Lisp, shell, Luau, VBScript, patches, markdown, GLSL, Lua, Python,
JavaScript and TypeScript are syntax trees (below). A file passed by path comes
from `generators.sourceFile`, whose store path is the one the file had;
`generators.sourceDir` builds the optchat directory from its files.

### Code as syntax trees

`generators.doc` is a Wadler/Leijen pretty-printer. A document is a string
(text; it may hold newlines, which reset the column), a list (concatenation),
`line` (a space, or a newline when its group breaks), `softline` (nothing, or a
newline), `hardline`, `nest n d` (d's newlines indent n further), `align d`
(d's newlines indent to the current column) or `group d` (d flat when it fits
the width, else broken). `doc.render width d` lays it out; a `null` width
never breaks a group; `doc.renderWith unit width d` writes each column of
indentation as `unit` (a tab for TypeScript) instead of a space. Layout is a `builtins.genericClosure` stack machine, one
step per document node with the column forced at each step, so neither
recursion depth nor thunk chains grow with the file; indentation is written
lazily, so blank lines carry no trailing spaces. Columns count bytes. Tomoe's
`deck.lisp` (400 lines, 20 KB, the largest converted file) renders in 0.03 s
and 12 MB of allocation; 4000 lines take 0.27 s and 130 MB. Tomoe's `hex-spiral.glsl` (165 lines, 5.5 KB) renders
in 0.04 s and 18 MB.

A language is `generators.<language>`: constructor functions and `render`, a
function from a list of top-level nodes to text, built on `generators.doc`.
Nodes are Nix values: a plain list or string where the language's own shape is
a list of words (a Lisp list or symbol, a shell command or word), otherwise a
one-attribute set made by a constructor (`str "x"` is `{str = "x";}`), so a
printer dispatches on the node's kind. Comments and blank lines are nodes
(`comment`, `blank`); nothing in a file is lost, except in GLSL, whose tree
keeps meaning only (below). The printer owns the layout
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

GLSL (`generators.glsl`) is code Nix evaluates. A shader is a function of
the generator (its constructors, GLSL's builtins and types, tomoe's prelude
uniforms `iResolution`, `iTime`, `iFrame`, `iMouse` and `iChannel0`) and of
itself: `{fn, vec2, mix, ...}: self: let inherit (self) PAL hash; in
{defines, consts, fns}`. `render` passes the shader its own globals, so a
constant, function or define is a Nix variable wherever it is used, and a
parameter or local is a Nix binding: a function's body is a lambda whose
formals are its parameters (listed in order, `[{fragColor = out vec4;}
{fragCoord = in' vec2;}]`) and the locals its block declares, and any block
that declares names (an `if` branch, a `for`, which also binds its loop
variable) is a lambda of them. `local v uvec2 value` declares a bound name
with its type, at its place in the block. No identifier is a string: a typo is
an undefined variable at evaluation. Every value carries its GLSL type, so a
swizzle is an attribute (`c.x`, `p.yx`; `swizzle value "rgb"` for the other
letter sets or an operand that is an infix list or a constructor call), and
evaluation throws on what GLSL rejects where the types say so cheaply (`vec3 +
vec2`, a `vec2`'s `.z`, a `float` local given a `vec2`). Numbers and booleans
are native Nix values, so a constant may be computed: `math.round 8
(math.sqrt 3.0 / 2.0)` is hex-spiral's `S3`, and `rgb ozette.lavender` is
`vec3(0.776, 0.651, 0.949)`, each channel of the hex colour over 255 rounded to
three places. The Ozette palette is one attribute set of hex colours,
`modules/desktop/session/theme/ozette.data.nix`, passed to the eight Ozette
shaders as `ozette`. Arithmetic is an infix list alternating operands and
operators, `[a "*" b "+" 1.0]`, parsed by GLSL precedence (left associative),
so a nested list is a grouping the precedence does not give and the printer
writes the parentheses that grouping needs and no others. A float prints as its
shortest round-trip form (`builtins.toJSON`) with a decimal point always
present (`1e-05` is `1.0e-5`). The printer derives the order GLSL needs:
`#define`s by name, then constants, then functions, each after what it
references, ties by name, and a cycle is an error. A constant's type is its
value's (`CENTER = vec2 0.4 0.58;` is `const vec2 CENTER`), else `typed float
[ ... ]`. A define is a value or `macro ({c}: body)`, written in parentheses
with its parameter parenthesized. The statements are `local`, `set target
value`, `update target "+=" value`, `return`, `break`, `continue`, `if' test
body`, `ifElse test body otherwise`, `for`, `while test body`, `comment` and an
expression; `commented "text" declaration` keeps a comment above a
declaration. A branch of one simple statement is written on the `if` line, any
other body braced, four spaces in; an infix expression too long for 100 columns
breaks before its loosest operator. Blank lines, spacing, redundant
parentheses, a literal's spelling and declarator lists are not kept. From
`tomoe/shaders/glass-mound.data.nix`, abridged:

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

Python (`generators.python`): a statement is a Nix list of words (`["import"
"os"]`, `["x" "=" y]`, `["return" a "if" b "else" c]`) or a string (`"pass"`),
an expression on its own, or `def name params body`, `class name bases body`,
`if' test body`, `ifElse test body otherwise` (`otherwise` a body for `else:`,
or an `if` node for `elif`), `for target iter body`, `while test body`,
`with' items body`, `try body [(except caught body) (finally body)]` and
`async` around any of them; a body is a list of statements, four spaces in.
A name, dotted name or number is a string (an integer may be a Nix integer);
a list of words is an expression written with single spaces, its operators and
keywords words of their own. The rest is constructors: `call f args`, `dot x
name`, `index x key`, `slice lower upper` (spaced around `:` when a bound is not
a name or number, as black does), `list`, `tuple`, `set`, `dict` with `pair k
v`, `paren`, `commas` (a tuple without brackets), `kw name value`, `star`,
`starstar`, `neg`, `invert`, `lambda params body` and `as value name`. String
literals keep their source body: `str` (`"..."`), `sq` (`'...'`) and `triple`
(`"""..."""`), with `raw` and `bytes` for the `r` and `b` prefixes; a body that
is a list is an f-string of text, `field x` and `spec x "03d"`. Brackets lay
out by their contents: a list of items on one line, `rows` hanging one row a
line four spaces in with the closing bracket on its own line and a trailing
comma when there are several rows (black's layout), `aligned` with the rows
after the first under the first item; `hang x` is a parenthesis hanging its
expression. An expression of words broken over lines is `rows` too: inside a
bracket its lines align with the bracket's contents, at statement level they
end in a backslash and continue four spaces in. `@name@` placeholders for
`replaceVars` are names. From `codex/apply-reasoning-policy.data.nix`,
abridged:

```nix
{as, blank, call, commas, def, dot, if', index, kw, raw, slice, sq, triple, ...}: [
  (triple "Reconcile only Codex's root reasoning setting, preserving other config.")
  ["import" "os"]
  ["from" "pathlib" "import" "Path"]
  blank
  (def "apply" ["path"] [
    ["path" "=" (call (dot (call (dot (call "Path" ["path"]) "expanduser") []) "resolve") [])]
    ["text" "=" (call "path.read_text" []) "if" (call "path.exists" []) "else" (sq "")]
    ["header" "=" (call "re.search" [(raw (sq "^\\s*\\[")) "text" (kw "flags" "re.MULTILINE")])]
    [(commas ["root" "rest"]) "=" (commas [(index "text" (slice null "end")) (index "text" (slice "end" null))])]
    (if' ["not" "count"] [
      ["root" "=" (sq "model_reasoning_effort = \"low\"\\n") "+" "root"]
    ])
  ])
]
```

JavaScript (`generators.javascript`): a call is a Nix list, its callee
first; an identifier, member path (`process.env.KEY`, `params?.name`) or
number is a string (an integer may be a Nix integer); `str` is a string
literal, `obj` an object whose entries are a shorthand name or a `[key value]`
list, `array` an array, `op [a "+" b]` operands and the operators between
them (assignment too), `paren`, `dot` (a property of something that is not a
path), `not`, `typeof`, `await`, `new`, `async` and `arrow params body`. A
statement is an expression, `const name value`, `let' name value` (`null`
for none), `import' names source`, `function name params body`, `if'`,
`ifElse`, `while`, `try' body param handler` (`null` for `catch {`),
`return value` (`null` for `return;`), `throw'` or `continue`. A body is a
list of statements in braces, one per line two spaces in, `inline [ ... ]`
on one line, or a single statement that is not an expression, written
without braces. `obj` and `array` are on one line unless `rows`, one entry
per line; `op (rows ...)` breaks after each operator, two spaces in; an
object on one line whose last value is broken closes without its space
(`{ id, result: {` ... `}}`). From `dev/ai/jev-mcp.data.nix`, abridged:

```nix
(const "API_KEY" ["resolveKey"])
(async (function "callSystemOne" ["state" "questions"] [
  (if' (not "API_KEY") (throw' (new ["Error" (str "TYPESAFE_API_KEY not set")])))
  (const "res" (await ["fetch" "ENDPOINT" (obj (rows [
    ["method" (str "POST")]
    ["body" ["JSON.stringify" (obj [["model" "MODEL"] "state" "questions"])]]
  ]))]))
  (try' (inline [(op ["detail" "=" ["JSON.stringify" (op ["j.detail" "||" "j"])]])]) null (inline []))
]))
```

TypeScript (`generators.ts`) keeps prettier's layout and binds every name.
A data file is a function of the constructors and globals it uses and returns
the file's top-level block: `{call, dot, string, ...}: ({toolRenderers,
failed, ...}: [ ... ])`. Every identifier and type name is a Nix variable. A
block that declares names is a lambda whose formals are exactly those names
(the file, a block of an `if`, `while`, `try` or `case`, a `switch`), and so
is a function, `fn`, `arrow` or `method`, of its parameters and its body's
declarations (`({cell}: arrow cell ...)`), a `for` of its binding and body and
a `catch` of its parameter and body; the generator calls the lambda with name
nodes and throws when a formal is declared nowhere in it. JavaScript, Node
and Bun globals and the builtin types (`JSON`, `Promise`, `Map`, `process`,
`Bun`, `undefined`, `this`, `string`, `number`, `void`, `Record`, ...) are
attributes of `generators.ts`, so a typo is a missing argument at evaluation;
TypeScript's `null` and `as const`'s `const` are `null'` and `const'`, and a
name a constructor or Nix already uses is spelled with a trailing `'`
(`call'`; the printer drops it). Strings are text only: `str` and `sq`
literals as written, `tpl` with `sub`, `regex`, `num` for a number Nix would
spell differently (an integer is a Nix integer, `true` and `false` Nix
booleans), member and property names (`dot x "a?.b"`, `prop "key" value`,
`typed "key" T` and `field "key" value` in a class, an interface or a
`shape`, `method "key" params body`), operator symbols and comments; a bare
string where a value belongs throws. `infix [a "&&" b "||" c]` alternates
operands and operators and is parsed by JavaScript's precedence (assignment
and `**` to the right), a nested list is a grouping that precedence does not
give, and the printer writes the parentheses that grouping needs plus those
prettier adds (around `&&` inside `||`, `??` mixed with either, `%` next to
`*` or `/`, an operand of a bitwise operator, `as` inside an operand or a
ternary branch, `??` in a ternary branch, a ternary or object literal as an
arrow's body on its line, a binary, ternary or `await` under a unary operator
or member access, a function or union type inside `[]`). Unary operators and
keywords are constructors: `not`, `neg`, `typeof`, `delete`, `await`,
`spread`, `inc` and `dec` (postfix `++`, `--`), `nonNull`, `async`,
`readonly`, `export`, `default`, `typeOnly` and `namespace` (`* as`). The
rest are `call`, `optCall`, `new`, `generic`, `idx`, `optIdx`, `obj`, `array`,
`arrayOf`, `union`, `intersection`, `is`, `opt`, `computed`, `ternary`,
`extends`, `class`, `interface` and `type`; statements are `const`, `let'`,
`return`, `throw'`, `if'`, `ifElse`, `for`, `forOf`, `forIn`, `forAwait`,
`while`, `switch` of `case`, `try` with `catch` and `finally`, `import'`, and
any expression (written with its `;`). The tree keeps only the breaks the
printer cannot choose: `rows` for a list, an argument list or the loosest
operator chain one item per line, `below x` for `x` on the next line one level
in (after `=`, `:`, `=>`, `?` and `:` of a ternary, inside `(`; a broken
`return` value is parenthesized), and `chain x` for a member chain broken
before each call group, the groups prettier forms. A file indented by spaces is
`spaces 2 ...`. From `omp/compact-eval.data.nix`, abridged:

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

The flake formatter is alejandra at upstream commit 97ca3d24 (a flake input),
which memoizes trial formats; 4.0.0 is exponential in nested constructor
applications and takes minutes on a deep TypeScript tree. It formats every
other file byte for byte as 4.0.0 does; swap to a release once one includes
it.

Every converted file passed its gate. A language whose printer can reproduce
its files gates on bytes at conversion; one that cannot gates on its official
formatter's output for both sides; GLSL, whose tree keeps meaning and not
layout, gates on formatter equality after canonicalization and on rendered
pixels. `checks.codegen` (`modules/lint.nix`)
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
| GLSL (15 files) | `nix run .#glsl-gate -- ORIGINAL GENERATED ...`: both sides, canonicalized (top-level declarations sorted, every operator parenthesized, literals as their values, one declarator per declaration, every branch braced) and run through clang-format 21 with a pinned style, are equal; both pass glslangValidator; four 640×360 frames of each, rendered by llvmpipe into float32 targets, are bit-identical | `glslangValidator -S frag` on each shader inside tomoe's ES 3.00 prelude and `main` |
| Lua (3 files) | bytes | `luajit -bl` for Aniimo's two LuaJIT mods, `luac -p` (Lua 5.5, Hyprland's) for `hyprland.lua` |
| Python (5 files) | bytes | `python -m py_compile` (vercel's `wrapper.py` with `@owners@` filled); `ruff check` is not clean today (4 of 5 files fail its defaults) |
| JavaScript (1 file) | bytes | `node --check` |
| TypeScript (10 files) | bytes, at conversion and again when re-imported with every name bound | `tsc --noEmit` (TypeScript 7) with an ambient stub of the omp, pi and Node modules they import; `work-fold.ts` and `compact-eval.ts`, untyped as written, get `--noCheck` (syntax and imports only) |

### GLSL before and after

The seven tomoe shaders went from word lists, which kept every byte, to
evaluated code, by `strictix import glsl` on each rendered file; the eight
Ozette wallpapers (`~/dev/developing/ozette-shaders`, in `checks.codegen` and
the gate, not in tomoe's rotation) were imported from their sources and their
colour constants then read from the palette. The rendered text changes where
the tree no longer records it: declaration order (derived), blank lines,
redundant parentheses (`(0.3 / CONTRAST) * COLOR_1` is `0.3 / CONTRAST *
COLOR_1`), literal spelling (`1.000` is `1.0`, `0.86602540` is `0.8660254`,
`0xde443b` is `14566459`), declarator lists and line breaks. The grouping the
parser sees is unchanged, each literal denotes the same double (a computed
constant is rounded to the digits its source had, so `math.round 8 (2.0 *
math.pi)` is `6.28318531`), and every one of the fifteen shaders passes `nix run
.#glsl-gate` with all four frames bit-identical. Binding names as Nix variables
changed no rendered byte of the seven, whose store paths are those of the
keyed form (the strictix pin moves the desktop hosts):

| Shader | Before | After |
| --- | --- | --- |
| `balatro.glsl` | `wqqd8rsq4p8hpjldfc6hkqsd9g4d8anv` | `cbkwq5xm5flwhiwp4fk15h4zsyrz6lv6` |
| `cassette-led.glsl` | `xj1ncvj97cnkfkyn797wizyyjca177bs` | `vi7w2rj7rvb70ylswxpx3h4bd6nwxz84` |
| `cassette-squares.glsl` | `wh2pnzy25420m6kpk2wa11619b6lr706` | `l38m45qbymnlkc168j9dzwbnn2vns26c` |
| `dot-corridor.glsl` | `xr7d0nwww7609kwl2p170mnsh8j18lrh` | `yz5giznzzjp098ispsqhpd3fvpw5pbsn` |
| `glass-mound.glsl` | `v24vp2yq9fw938f555i747kas83bcgb5` | `hfmndx9c9mxh220mga1r39rw859pldjf` |
| `hex-spiral.glsl` | `04yg5rvi5vg69cymp0cwmsi4l1a2iccc` | `18f1yk28zmp46digxbakp1081kyfy3wj` |
| `su-ei.glsl` | `yq0qiqac5yg6b8igk4fpwmzpf32rf1jg` | `9sl74yc2grlzfpvxq812qskhvyggc57r` |

and with them, and with the strictix input pinned to the importer's commit, the
system derivations of the two desktop hosts (`y0usaf-server` is unchanged):

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

A directory holds a category or one module's assets. No file exists only to
import others or to set values another module owns, except
`modules/finix/desktop/default.nix`, whose import keeps the graphical role's
system layer at its place in that merge order.

Validate with `nix build --no-link`, so no result link lands in the repo.
