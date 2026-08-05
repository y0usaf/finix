# transpose: dendritic-lite (denful "aspect" pattern adapted to finix).
# A .nix file that returns { compat ? module; finix ? module; hosts ?
# ["desktop" "server"]; } is an ASPECT: one file carries both module
# universes, and host membership is declared in the feature file instead
# of the central lists in default.nix. `compat` is NixOS-dialect and goes
# through the compat-import whitelist shim; `finix` is finix-native and is
# passed through untouched. Any other file keeps legacy semantics exactly:
# compat-shimmed, desktop-only.
{lib}: let
  shim = import ./modules/finix/compat-import.nix {inherit lib;};
in
  host: paths:
    builtins.concatMap (
      p: let
        v = import p;
      in
        if !(builtins.isAttrs v && (v ? compat || v ? finix))
        then lib.optional (host == "desktop") (shim v)
        else if !(builtins.elem host (v.hosts or ["desktop" "server"]))
        then []
        else lib.optional (v ? compat) (shim v.compat) ++ lib.optional (v ? finix) v.finix
    )
    paths
