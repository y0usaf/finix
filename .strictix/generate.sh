#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

emit() {
  nix eval --impure --json --expr "
    let
      f = builtins.getFlake (toString ./.);
      lib = f.inputs.nixpkgs.lib;
      docs = $1;
    in {
      options = builtins.listToAttrs (map (o: {
        inherit (o) name;
        value.type = o.type or \"\";
      }) docs);
    }" >"$2"
}

emit 'lib.concatMap (h: lib.optionAttrSetToDocList f.finixConfigurations.${h}.options)
        (builtins.attrNames f.finixConfigurations)' .strictix/hosts.json
emit 'lib.optionAttrSetToDocList (lib.evalModules {
        specialArgs = { inherit (f) inputs; system = "x86_64-linux"; };
        modules = [ ./modules/outputs.nix ];
      }).options' .strictix/flake.json
emit 'lib.optionAttrSetToDocList f.nixOnDroidConfigurations.default.options' .strictix/droid.json
