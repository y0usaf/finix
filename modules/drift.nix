{
  lib,
  pkgs,
  hosts,
}: let
  unquote = s: lib.concatStrings (lib.splitString "\"" s);

  enabled = host: prefix: let
    names = map (o: unquote o.name) (lib.optionAttrSetToDocList host.options);
    hits = builtins.filter (n: lib.hasInfix "enab" n && lib.hasPrefix prefix n && !(lib.hasInfix "<" n)) names;
    on = n: let v = builtins.tryEval (lib.getAttrFromPath (lib.splitString "." n) host.config); in v.success && builtins.isBool v.value && v.value;
  in
    builtins.filter on hits;

  dump = host: let
    c = host.config;
    names = map (p: p.pname or p.name or "?") c.environment.systemPackages;
    uid = c.users.users.${c.user.name}.uid or null;
    paths = c.finix.persistence.allowlist.users.${c.user.name}.directories ++ c.finix.persistence.allowlist.directories;
    lines =
      map (n: "package " + n) names
      ++ map (n: "service " + n) (enabled host "services.")
      ++ map (n: "program " + n) (enabled host "programs.")
      ++ map (n: "option " + n) (enabled host "user.")
      ++ map (p: "persist " + p) paths
      ++ lib.optional (uid != null) ("uid " + toString uid);
  in
    lib.concatStringsSep "\n" (lib.sort lib.lessThan lines) + "\n";

  dumps = lib.mapAttrs (name: host: pkgs.writeText ("drift-" + name) (dump host)) hosts;
  hostNames = lib.concatStringsSep " " (builtins.attrNames dumps);
  arms = lib.concatStrings (lib.mapAttrsToList (name: path: "      " + name + ") f=" + path + " ;;\n") dumps);
in
  pkgs.writeShellScriptBin "drift" ''
        set -eu
        case "''${1:-}" in
          "")
            echo "hosts: ${hostNames}"
            echo "usage: drift <host> [other-host]"
            exit 0
            ;;
    ${arms}      *)
            echo "drift: unknown host; one of: ${hostNames}" >&2
            exit 2
            ;;
        esac
        f1="$f"
        if [ "$#" = 1 ]; then
          cat "$f1"
          exit 0
        fi
        case "$2" in
    ${arms}      *)
            echo "drift: unknown host; one of: ${hostNames}" >&2
            exit 2
            ;;
        esac
        exec ${pkgs.diffutils}/bin/diff -u --label "$1" --label "$2" "$f1" "$f" || true
  ''
