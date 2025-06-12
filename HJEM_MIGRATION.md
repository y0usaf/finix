# Hjem Migration Status

This document tracks the migration of Home Manager modules from `home/` to `hjem/`.

## Legend
- **Migration**: Module has been created in hjem
- **Parity**: Module functionality matches or exceeds the original

---

## Core Modules

### packages.nix
- [x] Migration (→ `hjem/core/packages.nix`)
- [ ] Parity

### system.nix
- [ ] Migration (← `home/core/system.nix`)
- [ ] Parity

---

## Development Modules

### claude-code.nix
- [x] Migration (→ `hjem/dev/claude-code.nix`)
- [x] Parity

### dev-fhs.nix
- [x] Migration (→ `hjem/dev/dev-fhs.nix`)
- [ ] Parity

### docker.nix
- [x] Migration (→ `hjem/dev/docker.nix`)
- [x] Parity

### latex.nix
- [x] Migration (→ `hjem/dev/latex.nix`)
- [x] Parity

### npm.nix
- [x] Migration (→ `hjem/dev/npm.nix`)
- [ ] Parity

### nvim.nix
- [ ] Migration (← `home/dev/nvim.nix`)
- [ ] Parity

---

## Programs Modules

### android.nix
- [ ] Migration (← `home/programs/android.nix`)
- [ ] Parity

### bluetooth.nix
- [x] Migration (→ `hjem/programs/bluetooth.nix`)
- [ ] Parity

### discord.nix
- [x] Migration (→ `hjem/programs/discord.nix`)
- [ ] Parity

### firefox.nix
- [x] Migration (→ `hjem/programs/firefox.nix`)
- [ ] Parity

### music.nix
- [ ] Migration (← `home/programs/music.nix`)
- [ ] Parity

### sway-launcher-desktop.nix
- [x] Migration (→ `hjem/programs/sway-launcher-desktop.nix`)
- [ ] Parity

---

## Session Modules

### ssh.nix
- [ ] Migration (← `home/session/ssh.nix`)
- [ ] Parity

### systemd.nix
- [x] Migration (→ `system/services/format-nix.nix` + `system/services/polkit-gnome.nix`)
- [ ] Parity

### xdg.nix
- [x] Migration (→ `hjem/core/xdg.nix`)
- [ ] Parity

---

## UI Modules

### cursor.nix
- [x] Migration (→ `hjem/dev/cursor-ide.nix`)
- [ ] Parity

### fonts.nix
- [ ] Migration (← `home/ui/fonts.nix`)
- [ ] Parity

### kitty.nix
- [ ] Migration (← `home/ui/kitty.nix`)
- [ ] Parity

### mako.nix
- [ ] Migration (← `home/ui/mako.nix`)
- [ ] Parity

### wallust.nix
- [x] Migration (→ `hjem/ui/wallust.nix`)
- [ ] Parity