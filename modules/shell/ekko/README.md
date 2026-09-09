# Ekko desktop

Finix uses the pinned upstream Ekko package and its desktop defaults directly.
The managed `init.lisp` intentionally adds no overrides. The old Finix keyboard
menu and runtime patch are no longer applied.

- Click taskbar entries to focus, minimize or restore windows.
- Right-click titlebars or the taskbar for menus.
- Drag titlebars to exchange tiles or snap beside a window.
- Float windows from their menu; drag their borders to resize.
- Ctrl-P opens pane controls; Ctrl-O opens session controls; Ctrl-G locks input.

`package.nix` provides the same package to the system and `ekko-preview` output.
To build it without activating the system:

```sh
nix build --no-link .#ekko-preview
```

After updating the system, new sessions use the new runtime and defaults.
Already-running daemons retain their runtime until their sessions end.
