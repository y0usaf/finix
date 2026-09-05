# Ekko V2 in Finix

Each new interactive terminal starts a session named `terminal-TIMESTAMP-PID`.
The status bar shows its name. Closing the terminal or detaching keeps its
applications running; stopping the session or closing its final pane ends them.
Sessions do not survive reboot. There is no implicit session switching or window
activation helper: the compositor opens terminals, and Ekko manages their panes.

| Keys (after Ctrl-b) | Action |
| --- | --- |
| `v` / `h` | Split into columns / rows |
| Tab / `1`–`9` | Focus a pane |
| `x` | Close the focused pane |
| `z` | Zoom |
| `[` / `]` | Copy mode / paste Ekko buffer |
| `r` / `?` | Reload config / show bindings |
| `d` / `q` | Detach / stop session |

Copy mode: arrows or j/k move, Space marks, Enter copies whole lines, `/` searches,
`n` finds the next match, and q exits. Host clipboard integration remains separate.

To reconnect, launch your terminal with `-e ekko attach SESSION` (for example,
`monstar -e ekko attach terminal-1788631381-20452`). To start an intentionally
named session, use `-e ekko run --session work "$SHELL" -i` instead. `ekko status
SESSION` and `ekko inspect SESSION` return JSON. V1 and V2 sessions use different
protocols; existing V1 processes keep running their old executable.

The small managed `init.lisp` keeps the builtins and adds split aliases plus a
session-aware status line. Change it here and deploy through Finix, then run
`ekko config reload SESSION`. Extra local Lisp can be loaded explicitly from it.
Old Lua configuration and which-key surfaces are no longer installed. Legacy
cache persistence remains for rollback, not V2 reboot recovery.

Autostart skips existing Ekko, tmux, screen, SSH, virtual-console, and non-terminal
contexts. V2 sets `EKKO_SESSION_NAME` in initial and newly split pane processes.
The pinned package includes this fix; do not pin an earlier V2 build with autostart.

Verification: `nix build .#checks.x86_64-linux.ekko-startup` exercises the rendered
startup fragment on real PTYs with both Bash and Rush, including nested-shell
protection and new splits. Build the desktop with
`nix build .#nixosConfigurations.y0usaf-desktop.config.system.topLevel`.
