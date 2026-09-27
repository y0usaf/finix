# Repository layout

This repository configures y0usaf's machines on finix: it owns system
integration and user configuration, not application implementations.
Headlong operations live in `~/dev/developing/headlong-ops`. A project that
stays external comes in as a flake input. Keep runners, application patches,
reusable skills and their tests with the module or project that owns them.
Runtime state and credentials stay outside the source tree and the Nix store.
Don't create root-level `nix/`, `tests/` or `previews/` directories.

`flake.nix` holds the inputs and hands them to `modules/outputs.nix`, which
builds every output with let bindings and plain functions. No module system
runs at flake level.

A host is a list of modules. The graphical hosts load every `.nix` file under
the graphical roots, so each of those files is a module; the server names its
modules one by one. `modules/hosts/common/` is the graphical role.

Loading a module turns it on. A module declares an option only when the hosts
that load it need different values, or when three or more modules read the
value. Anything else is written where it is used, and a helper one module
uses is a let binding in that module.

A program's module owns its packages, settings, dotfiles and persisted paths,
and decides from hardware facts such as `hardware.nvidia.enable`, never from
the hostname. A program that needs only its package is a line in its
category's package list. A host directory under `modules/hosts/` holds what
is true of that machine alone: hardware, displays, disks and boot, network
identity, keys, and where it departs from its role.

A directory holds a category or one module's assets. No file exists only to
import others or to set values another module owns.

Validate with `nix build --no-link`, so no result link lands in the repo.
