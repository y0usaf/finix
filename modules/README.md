# Repository layout

This repository owns system integration and user configuration, not standalone
application implementations. Headlong operations live in
`~/dev/developing/headlong-ops`; Hermes tooling lives in
`~/dev/developing/hermes-tools`. Consume project source through flake inputs.
Keep runners, application patches, reusable skills, and their tests with the
project that owns them. Runtime state and credentials stay outside both source
repositories and the Nix store.

Finix-owned integration and build definitions belong under `modules/`, alongside
the feature that owns them. Small activation helpers and system-specific checks
can live beside that wiring. Do not use this rule to move an application's code
into Finix. Do not create root-level `nix/`, `tests/`, or `previews/` directories.

The repository root retains flake inputs and lock metadata, licensing, and tool configuration. Its `flake.nix` delegates output construction to `modules/outputs.nix`; do not add derivation builders to the root flake.

`recursivelyImport.nix` remains at the repository root and recursively collects `.nix` module paths without exclusions. Pass those paths directly to `lib.evalModules`: do not pre-import them or filter out helpers. Path imports retain source locations and let the module system deduplicate shared imports.

Every `.nix` file under `modules/` is a module, including package builders and data providers. Export shared values through declared options and consume `config`, rather than importing files as functions or data. Select directory roots for the relevant graph (flake outputs, shared system features, or host-specific features); keep host-only modules in that host's directory.

`modules/outputs.nix` and `modules/finix/` compose the flake-level module graph. Feature packages and previews are exposed through the root flake's `packages`, `apps`, and `checks`; there are no nested preview flakes.

Prefer `nix build --no-link` for validation to avoid build-result links in the repository root.
