{
  inputs,
  lib,
  pkgs,
  hosts,
  droid,
}: let
  strictix = lib.getExe inputs.strictix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  schema = name: docs:
    pkgs.writeText "${name}-options.json" (builtins.toJSON {
      options = builtins.listToAttrs (map (o: {
          inherit (o) name;
          value.type = o.type or "";
        })
        docs);
    });

  config = (pkgs.formats.toml {}).generate "strictix.toml" {
    lint = {
      schema = schema "finix" (lib.concatMap (host: lib.optionAttrSetToDocList host.options) (builtins.attrValues hosts));
      enabled = ["unused-option" "never-enabled-option"];
    };
    schemas = {
      "modules/hosts/android-phone" = schema "droid" (lib.optionAttrSetToDocList droid.options);
      "modules/hosts/steam-frame" = "";
      "modules/hosts/shared.nix" = "";
      "omp-box" = "";
      "modules/lint.nix" = "";
    };
  };
in {
  app = pkgs.writeShellScriptBin "lint" ''
    command=''${1:-check}
    [ $# -gt 0 ] && shift
    exec ${strictix} "$command" "$@" --config ${config}
  '';

  check = pkgs.runCommand "strictix" {} ''
    cd ${inputs.self}
    ${strictix} check . --config ${config}
    touch $out
  '';
}
