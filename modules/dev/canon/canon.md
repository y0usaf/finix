# ~/Dev — design canon

Applies to my personal projects only. Not work repos (`Cookunity*`), not
forks or upstream code (Whisp, zap's inherited Warp code, hyprland-wiki),
not vendored `ref/` trees — those follow upstream convention.

Rules have stable slugs (`[[canon:least-code]]`). Use one to point at a rule
from a commit, a comment, or the DESIGN.md line that records a divergence.
A slug is a name, not a registry entry — nothing walks `~/Dev` collecting
them, so don't write as if something does.

Every rule has a **Check**, labelled either **run** (a command with a
pass/fail result) or **judge** (a question only a person answers). Only
say a run-check passed if you ran it. Never claim a judge-check as done.

Several run-checks only become mechanical once the project's DESIGN.md
names the specifics — which module is the extension boundary, which state
the daemon owns. That naming is the point: the judgment is made once, in
writing, and everything after it is a command.

---

## Prime directive

### `[[canon:least-code]]` — write less code

The best code is no code. The second best is code that is easy to delete.
Prefer deleting to adding. Don't build an abstraction until the third
thing that needs it exists.

**Why it outranks everything else:** less code is less to review, less to
hold in your head, and less to break. A smaller diff is a smaller thing a
human or an agent must understand before touching it. Every other rule
here is worth having only because it makes the code smaller or the
understanding cheaper.

**Scope of its authority:** it decides *design* questions — build this or
not, one mechanism or three, abstract now or later. It is **not** a reason
to skip tests, verification, or documentation. "Less code" never means
"less checking".

**Check (judge):** name the smaller thing you rejected and why. If you
can't name one, you didn't look for it.

---

## Doctrines

### `[[canon:least-power]]` — say what, not how

Store knowledge as data, not as code paths. The ladder orders forms by how
much you can learn **without running them**:

| Rung | Form | What you know by reading it |
|---|---|---|
| 1 | a constant | the value |
| 2 | a table of data | every case that exists |
| 3 | a config file | every case, and a user can change it without a rebuild |
| 4 | a pure function — input in, value out, no I/O | the output for any input you try |
| 5 | code with I/O and state | nothing; you must run it |

This is about how one thing is written, not which language you picked. A
keybind table beats an if-chain **in the same language**.

**Check (judge):** name the rung this sits on, then say why the rung below
does not work. "It just doesn't" is a failure.

### `[[canon:no-privileged-path]]` — nothing we ship gets a shortcut

If a feature can be an extension, make it one. Our own features use the
exact same public API a stranger would use, and live in a `*-builtins`
layer. If there is no public API, every unit of a kind — every lint, every
command, every layout — still gets declared the same way. Nothing
hand-wired, least of all the things we ship.

**Check (run):** skip this if DESIGN.md marks this rule `n/a`. Otherwise:
build with the builtins removed and confirm it still starts and does the
thing DESIGN.md says a bare build does. This is a CI job, not a manual
step.

**Not when:** the program has no plugin story and shouldn't (rudo, Whisp —
tight core loop, replaceability is not a goal); the API would be bigger
than the feature set; fewer than three units of the kind exist yet. Taking
any of these outs means writing it in DESIGN.md, with the condition that
would reverse it.

### `[[canon:functional-core]]` — functional core, imperative shell

Extension code never touches host state directly. It reads an immutable
snapshot taken before it was called, and returns actions the host applies
after it returns. One write path. One place invariants live.

Every dispatch runs under a watchdog — a timeout or instruction budget
that kills a runaway handler instead of hanging the host.

**Check (run):** DESIGN.md names the module that is the extension
boundary. Search that module for handles to mutable host state — in Rust,
`&mut` on a host type. One hit is a failure. If DESIGN.md does not name
the boundary, that is the failure.

**Not when:** there is no extension surface. A hot-path exemption must name
what it skips, bound what it may touch, and state the condition that ends
it — "until a scripting bridge exists", not "for now".

### `[[canon:daemon-thin-client]]` — state outlives the viewer

State that must survive its viewer lives in a daemon. Clients attach,
render, detach. They talk over a small wire protocol carrying one integer
version, bumped on every wire change. Additive changes keep old clients
working; breaking changes reject old clients with a clear error, never a
silent misparse.

**Check (run):** DESIGN.md names the state the daemon owns. Kill the
client, restart it, and confirm that named state is intact. If nothing
named survives, it should not be a daemon.

**Not when:** the tool runs, applies, and exits; the app has one viewer for
one lifetime. A daemon is justified by state outliving the invocation, not
by wanting an API.

### `[[canon:unix]]` — the rules that still bind

Stated plainly, because a rule you have to translate is a rule you skip.

**Check (judge):** walk these eight rows against whatever you just
touched. Any row whose fail condition is true gets fixed, or gets written
into DESIGN.md as a divergence with a reason.

| Rule | Fails when |
|---|---|
| Keep decisions out of machinery | the code that picks *what* to do and the code that does it are in the same file |
| Small parts, narrow interfaces | a module's public surface can't be listed on one screen |
| Be usable by other programs | there is no machine-readable output mode, only formatted text |
| Make state observable without a debugger | there is no dump, log, or inspect path for live state |
| Fail loudly on the first bad input | bad input silently falls back to a default |
| Say nothing when nothing went wrong | it prints on success |
| Generate what you'd hand-maintain | a file is edited by hand that a script could emit |
| Work, then measure, then optimize | an optimization landed with no benchmark before it |

---

## Working rules

### `[[canon:nix-verify]]` — verification goes through Nix

`nix build`, `nix flake check`, `nix run`. `cargo build` fills `target/`,
a different tree than the Nix store, so the next `nix run` rebuilds
everything from scratch. `cargo fmt` and `cargo clippy` are exceptions and
run natively; Nix formats with `nix fmt`. Native fallbacks (Meson, plain
cargo) are a courtesy for non-Nix contributors and CI never depends on
them. Forks keep upstream's build system.

**Check (run):** "tests pass" is only true if a Nix command exited zero.
Quote the command.

### `[[canon:design-doc]]` — every project states its own shape

A new project or a new subsystem gets a DESIGN.md before its code. Small
fixes, single-file changes, scratch trees, and per-task worktrees do not.
Divergence from this canon is fine; undocumented divergence is drift. When
a project's DESIGN.md conflicts with this file, the project wins locally —
and tell me about the conflict.

The file records **decisions**, not **status**. A decision and its reason
stay true after the code moves; a status line stops being true the moment
either the code or this file's wording changes, and nothing announces that
it stopped. So: no conformance table, and no restating a rule that already
lives here.

**Check (run):** `rg '^## (Locked decisions|Architecture|Deferred|Roadmap)'
DESIGN.md` returns four hits. The facts other rules' run-checks need from
this file — the extension boundary module, the state the daemon owns, an
`n/a` and what reverses it — are those rules' checks to make, not this one's.

### `[[canon:amend]]` — this file changes by proposal only

When a rule loses the same argument twice for the same reason, the rule is
wrong. Say so and propose the edit. Never edit this file as a side effect
of another task.


**Check (judge):** did I change this file because it was asked for, or
because a rule was inconvenient right now?

## DESIGN.md shape

Four sections, all required:

- **Locked decisions** — the choice and why, so it isn't relitigated by
  accident. Date each one.
- **Architecture** — a module map marking each module decision-making or
  machinery.
- **Deferred** — what was left out, and the reason.
- **Roadmap** — every phase with a criterion you can check.

Anything else is optional. Where another rule's check sends a fact here —
which module is the extension boundary, which state the daemon owns, which
rule is `n/a` and what would reverse it — write it as a sentence in the
section it belongs to.
