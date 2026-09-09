# Isolated Finix Zellij profile preview

From the existing Finix checkout:

```sh
cd ~/finix
nix run path:.#ekko-zellij-preview
```

This is a development preview of the partial profile. Ctrl-p opens Pane mode;
`r`/`d` split right/down, `h`/`j`/`k`/`l` focus, `z` toggles frames, `f` toggles
fullscreen, and `c` renames. Ctrl-h enters Move mode. Ctrl-o enters Session;
`d` detaches and Ctrl-q quits outside Locked mode. The full Zellij mode/bar/tab,
floating, plugin, session, CLI, and other surface requirements remain open.

The launch prints a private configuration path and exact Attach, Stop and reload
commands for
that session. Edit the copied Lisp files there and run the printed reload
command; the runtime does not rebuild and the pane applications keep their
PIDs. Closing the viewer ends this disposable preview and cleans only its
private runtime. The printed Stop command also ends only this preview.

To test detach/reattach while retaining the children, use:

```sh
nix run path:.#ekko-zellij-preview -- --keep-session
```

After Ctrl-o then d, use the printed Attach command to return to the same
session. The printed Stop command ends it. Its private directory remains
available for reviewing the copied configuration; remove that printed directory
when finished. Without `--keep-session`, closing the viewer cleans the preview.

The existing custom menu remains separately selectable:

```sh
EKKO_CONFIG="$PWD/modules/shell/ekko/init.lisp" nix run path:.#ekko-zellij-preview
```

To choose the child explicitly, append `-- /bin/sh -i`. To build and verify:

```sh
nix build --no-link path:.#ekko-zellij-preview
nix build --no-link path:.#nixosConfigurations.y0usaf-desktop.config.system.build.toplevel
```

The preview is a regular feature module, exposed by the root flake. Its separate
`ekko-zellij-preview` input retains the pinned isolated parity worktree
`~/dev/maintaining/ekko-zellij-parity` revision in the root lock. It does not change
Finix's main Ekko input, system configuration, deployed menu, or running sessions.
The shared runtime now includes the existing generic overlay, graphics clipping,
copy-input and scrollback fixes, with wire version 11. This preview needs no
additional runtime patch. The original custom menu passes its integration test
and private Kitty visual checks against the shared runtime. The live
`modules/shell/ekko/runtime.patch` remains untouched.

Frames, modes, bindings and geometry choices are replaceable Lisp. Generic
runtime actions validate contributions, enforce ownership, resize PTYs, and clip
graphics. Zellij is used only as the pinned independent test oracle. The
[frame evidence](/home/y0usaf/dev/maintaining/ekko-zellij-parity/docs/evidence/zellij/frame-toggle/README.md) includes screenshots
of the actual Finix patched binary. A useful preview does not pass the full
acceptance gate in GOAL.md.

[Shared runtime and native cell evidence](/home/y0usaf/dev/maintaining/ekko-zellij-parity/docs/evidence/zellij/shared-overlays/README.md).

Pinned local source: `a9a129c6ee99a4b725b9cdf465726c763ece7e17`.

The shared runtime also provides transactional Lisp initialization. This mechanism does not yet implement release notes or persistent plugin state.
