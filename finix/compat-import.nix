# compat-import: import the NixOS modules/ tree into the finix module
# system through a whitelist filter.
#
# WHY: the desktop's package list + manzil dotfile declarations live in
# modules/ beside NixOS-only config (systemd units, boot, services). finix
# needs the data (user.* options + guards, manzil.users.*.files,
# environment.systemPackages, fonts, services.udev.packages) and must never
# merge the rest. A shim wraps each module: `options` pass through whole
# (harmless — defaults apply, guards evaluate), `config` is filtered
# recursively through mkIf/mkMerge/mkOverride nodes, keeping only:
#
#   user, manzil, environment, fonts   (whole subtrees)
#   services.udev.packages             (nested pick)
#
# Everything else — boot, fileSystems, systemd, programs, networking,
# nixpkgs, security, … — is DROPPED. That is deliberate: finix implements
# those subsystems natively (see finix/hosts/*). If a desktop feature seems
# missing on finix, check this whitelist BEFORE debugging the module.
#
# `imports` are shimmed recursively; non-path imports (flake input modules)
# are dropped — finix wires its own (manzil.finixModules, etc.).
{lib}: let
  inherit (builtins) isAttrs isFunction isPath head tail;

  # Config-node combinators the module system produces, recursed through so
  # mkIf/mkMerge/mkDefault structure survives filtering — with one crucial
  # refinement: an mkIf whose content has NO surviving keys is pruned to {}
  # WITHOUT forcing its condition. NixOS-side guards like
  # `mkIf config.services.mediamtx.enable { systemd = …; services = …; }`
  # wrap only dropped config; forcing their conditions would demand stubs
  # for every nixpkgs option they reference. Keys are read shallowly (WHNF
  # only — no config values forced).

  survives = c:
    if !isAttrs c
    then false
    else if c._type or "" != ""
    then true # nested node: conservative — keep, recurse decides
    else
      (builtins.any (k: c ? "${k}") ["user" "manzil" "fonts" "lib"])
      || (c ? environment)
      || (c ? services && (isAttrs c.services && (c.services._type or "" != "" || c.services ? udev)));

  filterNode = pick: c:
    if !isAttrs c
    then c
    else if c._type or "" == "if"
    then
      if survives c.content
      then c // {content = filterNode pick c.content;}
      else {}
    else if c._type or "" == "merge"
    then c // {contents = map (filterNode pick) (builtins.filter survives c.contents);}
    else if c._type or "" == "override"
    then
      if survives c.content
      then c // {content = filterNode pick c.content;}
      else {}
    else pick c;

  # Keep only path = [k1 k2 …] from a plain (or node-wrapped) subtree.
  pickPath = path:
    filterNode (c:
      if path == [] || !isAttrs c
      then c
      else let
        k = head path;
      in
        lib.optionalAttrs (c ? "${k}") {
          "${k}" = pickPath (tail path) c."${k}";
        });

  # environment: finix supports a subset only (no extraInit; NixOS's
  # sessionVariables is environment.variables in finix). Keep supported
  # keys, remap the name.
  # Packages the bridge era deliberately filtered out of the desktop:
  # finix runs dhcpcd (not NetworkManager) and docker is deferred wholesale
  # (podman ships via hosts/…/finix/materialized-packages.nix instead).

  # fonts: finix supports fonts.packages + fonts.fontconfig only; NixOS's
  # fontDir/enableDefaultPackages/conf/dtd are dropped. (User font config
  # rides the user.* namespace, untouched here.)

  # Option subtrees our modules declare but finix ALSO declares — passing
  # them through would error "already declared". Everything else passes
  # whole (real declarations + defaults, so guards in kept config evaluate
  # exactly as NixOS-side).

  dropPath = path: c:
    if path == [] || !isAttrs c
    then c
    else let
      k = head path;
    in
      if !(c ? "${k}")
      then c
      else if tail path == []
      then builtins.removeAttrs c [k]
      else c // {"${k}" = dropPath (tail path) c."${k}";}; # non-function (flake input modules): dropped by design

  shimPath = path:
    (module:
      if isFunction module
      # NB: finix matches module args by function signature, so the shim must
      # NAME every arg the wrapped modules use (lib/config/pkgs/flakeInputs/
      # modulesPath) — a bare `args:` form receives none of them.
      then
        {
          config,
          lib,
          pkgs,
          flakeInputs,
          modulesPath,
          ...
        } @ args: let
          raw = module args;
        in
          if !isAttrs raw
          then {}
          else let
            # NixOS module shorthand: top-level keys other than imports/options/
            # config ARE config ({ imports = […]; user.ui.gtk.scale = 1.5; }).
            shorthand = builtins.removeAttrs raw ["imports" "options" "config"];
            configPart =
              if raw ? config && shorthand != {}
              then throw "compat-import: module mixes bare config keys with an explicit config attrset"
              else raw.config or shorthand;
          in
            {
              imports = map shimPath (builtins.filter isPath (raw.imports or []));
            }
            # options pass through whole (real declarations + defaults) minus
            # paths finix itself declares (dropOptionPaths above).
            // (lib.optionalAttrs (raw ? options) {
              options = (c:
                builtins.foldl' (acc: p: dropPath p acc) c [
                  ["hardware" "nvidia"]
                ])
              raw.options;
            })
            // (lib.optionalAttrs (configPart != {}) {
              config = (filterNode (c:
                (lib.filterAttrs (n: _: builtins.elem n ["user" "manzil" "lib"]) c)
                // (lib.optionalAttrs (c ? environment) {
                  environment = (filterNode (c: let
                    merged = lib.recursiveUpdate (lib.filterAttrs (n: _: builtins.elem n ["systemPackages" "etc" "variables" "shells" "binsh"]) c) (lib.optionalAttrs (c ? sessionVariables) {variables = c.sessionVariables;});
                  in
                    if merged ? systemPackages
                    then merged // {systemPackages = builtins.filter (p: !(builtins.elem ((p: p.pname or (builtins.parseDrvName (p.name or "?")).name) p) ["networkmanager" "docker" "docker-compose"])) merged.systemPackages;}
                    else merged))
                  c.environment;
                })
                // (lib.optionalAttrs (c ? fonts) {
                  fonts = (filterNode (c:
                      lib.filterAttrs (n: _: builtins.elem n ["packages" "fontconfig"]) c))
                  c.fonts;
                })
                // (lib.optionalAttrs (c ? services) {services = pickPath ["udev" "packages"] c.services;})))
              configPart;
            })
      else {}) (import path);
in
  shimPath
