# Repository layout

This repository owns system integration and user configuration, not standalone
application implementations. Headlong operations live in
`~/dev/developing/headlong-ops`. Where a project remains external, consume its
source through flake inputs. Keep runners, application patches, reusable skills,
and their tests with the module or project that owns them. Runtime state and
credentials stay outside the source tree and the Nix store.

Finix-owned integration and build definitions belong under `modules/`, alongside
the feature that owns them. Small activation helpers and system-specific checks
can live beside that wiring. Do not use this rule to move an application's code
into Finix. Do not create root-level `nix/`, `tests/`, or `previews/` directories.

The repository root retains flake inputs and lock metadata, licensing, and tool configuration. Its `flake.nix` delegates output construction to `modules/outputs.nix`; do not add derivation builders to the root flake.

`recursivelyImport.nix` remains at the repository root and recursively collects `.nix` module paths without exclusions. Pass those paths directly to `lib.evalModules`: do not pre-import them or filter out helpers. Path imports retain source locations and let the module system deduplicate shared imports.

Every `.nix` file under `modules/` is a module, including package builders and data providers. Export shared values through declared options and consume `config`, rather than importing files as functions or data.

A host directory under `modules/hosts/` holds only facts about that machine: hardware, displays, disks and boot, network identity, keys, and which roles it takes. Everything else is general. A program's module owns its install, settings and persisted paths (`finix.persistence.allowlist`), keyed off roles or hardware facts such as `hardware.nvidia.enable`, never off a hostname. `modules/hosts/common/` is the graphical role; every graphical host loads it with the other graphical roots, and persisted paths no module owns go in `hosts/common/persist.nix`. `modules/finix/default.nix` picks each host's modules: the framework adds the laptop role in `modules/finix/laptop.nix`, and the server lists its modules explicitly, including those under `modules/server/`.

`modules/outputs.nix` and `modules/finix/` compose the flake-level module graph. Feature packages and previews are exposed through the root flake's `packages`, `apps`, and `checks`; there are no nested preview flakes.

Prefer `nix build --no-link` for validation to avoid build-result links in the repository root.
