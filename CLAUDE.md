# NixOS Configuration

## Multi-System Setup

This repo manages both Darwin (nix-darwin + home-manager) and NixOS systems.
Always work from `~/nixos` root directory.

### Configuration Philosophy
- Aim for cohesive configuration across systems
- Avoid unnecessary differentiation
- Only differentiate when required (Darwin-specific CLI tools, NixOS system packages)
- Different syntaxes (Hjem vs home-manager): aim for configuration similarity, not code sharing
- Check `flake.nix` for inputs and shared configuration strategies

## Directory Structure

### lib/
System-agnostic option definitions and reusable modules shared across Darwin and NixOS.
- Examples: zsh, zellij, shell functions
- Rule: Use if the tool/concept exists identically on both systems

### nixos/user/
NixOS user-level implementations using hjem syntax.
- Examples: zsh config specific to NixOS, user environment setup

### nixos/system/
NixOS system-level configuration.
- System packages and kernel-level configuration
- Examples: niri (Wayland compositor, Linux-only), system services

### darwin/user/
Darwin user-level implementations using home-manager syntax.
- Examples: zsh config specific to Darwin, user environment setup

### darwin/system/
Darwin system-level configuration using nix-darwin.
- System packages and macOS-specific setup
- Examples: raycast (macOS spotlight alternative, macOS-only)

### What NOT to put in lib/
- raycast: Darwin-only macOS app, goes in darwin/system
- niri: Linux-only Wayland compositor, goes in nixos/system
- Anything with system-specific syscalls or platform-only binaries

## Conventions

### default.nix Files
`default.nix` files should be **import-only**. They should only contain imports of other modules, no inline configuration.

```nix
# CORRECT - import only
{
  foo = import ./foo.nix;
  bar = import ./bar.nix;
}

# WRONG - inline configuration
{
  foo = import ./foo.nix;
  someOption = "value";  # Don't do this
}
```

## Workflows

### Darwin
Uses nix-darwin and home-manager.
```
git add → alejandra . → nh darwin switch → TEST → git commit && push
```
**CRITICAL:** Only commit after successful switch and user testing.

### NixOS
Uses hjem. Clone external repos to `~/nixos/tmp/`.
**IMPORTANT:** All packages are system-level (`environment.systemPackages`), NOT user-level.
```
git add → alejandra . → nh os switch --dry → nh os switch → TEST → git commit && push
```
**CRITICAL:** Only commit after successful switch and user testing.

## Hjem Syntax

```nix
files."path" = { generator = lib.generators.toFormat {}; value = {}; };
```

`usr` is aliased to `hjem.users.${config.user.name}` (defined in `nixos/user/core/user-config.nix:9`).
Use `usr.files = { ... }` as shorthand instead of `hjem.users.${name}.files = { ... }`.

## Failure Modes

### Committing code that doesn't build
**NEVER** attempt git commit until:
- `alejandra .` completes without errors
- `nh os switch --dry` succeeds (NixOS) OR `nh darwin switch` succeeds (Darwin)
- `nh os switch` succeeds (NixOS only, after dry run passes)
- Manual testing confirms expected behavior

If any step fails, fix the issue before committing.
