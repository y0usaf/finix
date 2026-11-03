{
  inputs,
  lib,
  pkgs,
  hosts,
  droid,
}: let
  strictix = lib.getExe' inputs.strictix.packages.${pkgs.stdenv.hostPlatform.system}.default "strictix";

  schema = name: docs:
    pkgs.writeText "${name}-options.json" (builtins.toJSON {
      options = builtins.listToAttrs (map (o: {
          inherit (o) name;
          value.type = o.type or "";
        })
        docs);
    });

  codecs = {
    json = {
      extensions = ["json"];
      parse = builtins.fromJSON;
      render = lib.generators.toJSON {};
    };
    toml = {
      extensions = ["toml"];
      parse = builtins.fromTOML;
      render = v: builtins.readFile ((pkgs.formats.toml {}).generate "x.toml" v);
    };
  };

  convert = c: let
    codec = codecs.${c.id};
    value = codec.parse c.text;
    nix = lib.generators.toPretty {multiline = true;} value;
    generate = name: v: "(pkgs.formats.${c.id} {}).generate ${lib.strings.escapeNixString (baseNameOf name)} (${v})";
    forms = {
      json = "(builtins.toJSON (${nix}))";
      toml = "(builtins.readFile (${generate c.entry nix}))";
      import = "import ${c.data}";
      source = "(${generate c.target "import ${c.data}"})";
    };
    form =
      if c.kind == "text"
      then c.id
      else c.loader;
    failures = imported: [
      {
        failed = !(c.pkgs || builtins.elem form ["json" "import"]);
        reason = "pkgs is not in scope";
      }
      {
        failed = imported != value;
        reason = "toPretty does not reproduce the value";
      }
      {
        failed = codec.parse (codec.render imported) != value;
        reason = "rendering the Nix value does not parse back to the original";
      }
    ];
  in {
    inherit nix;
    replacement = forms.${form};
    reason = imported: (lib.findFirst (f: f.failed) {reason = null;} (failures imported)).reason;
  };

  runner = pkgs.writeText "codec-runner.nix" ''
    candidate: let
      pkgs = import ${pkgs.path} {system = "${pkgs.stdenv.hostPlatform.system}";};
      lint = import ${./lint.nix} {
        inherit pkgs;
        inherit (pkgs) lib;
        inputs = {};
        hosts = {};
        droid = {};
      };
      result = lint.convert (builtins.fromJSON (builtins.readFile candidate));
    in
      result // {reason = result.reason (import (builtins.toFile "data.nix" result.nix));}
  '';

  jq = lib.getExe pkgs.jq;

  config = (pkgs.formats.toml {}).generate "strictix.toml" {
    codecs = lib.mapAttrs (_: c: {inherit (c) extensions;}) codecs;
    lint = {
      schema = schema "finix" (lib.concatMap (host: lib.optionAttrSetToDocList host.options) (builtins.attrValues hosts));
      enabled = ["unused-option" "never-enabled-option"];
      generated = ["modules/hosts/steam-frame/beat-saber/beatmods.json"];
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
  inherit convert;

  app = pkgs.writeShellScriptBin "lint" ''
    command=''${1:-check}
    [ $# -gt 0 ] && shift
    [ "$command" = fix ] || exec ${strictix} "$command" "$@" --config ${config}
    set -euo pipefail
    scope=()
    dry=
    for arg in "$@"; do
      if [ "$arg" = --dry-run ]; then dry=1; else scope+=("$arg"); fi
    done
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    diagnose() {
      ${strictix} check --format json "''${scope[@]}" --config ${config} > "$work/diags.json" 2> "$work/err" || true
      if ! ${jq} -e .files "$work/diags.json" > /dev/null 2>&1; then
        cat "$work/err" >&2
        exit 2
      fi
    }
    diagnose
    ${strictix} fix "$@" --config ${config} || true
    [ -z "$dry" ] || exit 0
    diagnose
    ${jq} -c '.files[] | .path as $file | .diagnostics[] | select(.code == "codec-candidate") | .codec + {file: $file}' "$work/diags.json" > "$work/candidates"
    n=0
    touched=()
    while IFS= read -r c; do
      n=$((n + 1))
      get() { ${jq} -r ".$1 // empty" <<<"$c"; }
      file=$(get file)
      start=$(get replace.start)
      end=$(get replace.end)
      label="$file:$start $(get id) $(get kind)"
      data=
      target=
      datafile=
      if [ "$(get kind)" = text ]; then
        tail -c +$((start + 1)) "$file" | head -c $((end - start)) > "$work/$n.slice.nix"
        if ! nix eval --impure --raw --file "$work/$n.slice.nix" > "$work/$n.txt" 2> "$work/$n.err"; then
          echo "withheld $label: $(grep -m1 'error:' "$work/$n.err")"
          continue
        fi
      else
        target=$(get target)
        cp "$target" "$work/$n.txt"
        name=$(basename "$target")
        datafile=$(dirname "$target")/''${name%.*}.data.nix
        data=$(realpath -m --relative-to="$(dirname "$file")" "$datafile")
        case $data in ../*) ;; *) data=./$data ;; esac
        label="$label $target"
        if [ -e "$datafile" ]; then
          echo "withheld $label: $datafile already exists"
          continue
        fi
        touch "$work/claims"
        claimed=$(${jq} -Rr --arg d "$datafile" 'split("\t") | select(.[0] == $d) | .[1]' "$work/claims" | head -n1)
        if [ -n "$claimed" ] && [ "$claimed" != "$target" ]; then
          echo "withheld $label: $datafile is also the destination for $claimed"
          continue
        fi
      fi
      ${jq} --rawfile text "$work/$n.txt" --arg data "$data" '. + {text: $text, data: $data}' <<<"$c" > "$work/$n.json"
      if ! nix eval --impure --json --expr "import ${runner} $work/$n.json" > "$work/$n.out" 2> "$work/$n.err"; then
        echo "withheld $label: $(grep -m1 'error:' "$work/$n.err")"
        continue
      fi
      reason=$(${jq} -r '.reason // empty' "$work/$n.out")
      if [ -n "$reason" ]; then
        echo "withheld $label: $reason"
        continue
      fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$file" "$start" "$end" "$n" "''${target:-}" "''${datafile:-}" >> "$work/accepted"
      [ -n "$datafile" ] && printf '%s\t%s\n' "$datafile" "$target" >> "$work/claims"
      echo "converted $label"
    done < "$work/candidates"
    if [ -s "$work/accepted" ]; then
      while IFS=$'\t' read -r file start end n target datafile; do
        if [ -n "$datafile" ]; then
          ${jq} -j .nix "$work/$n.out" > "$datafile"
          printf '%s\n' "$target" >> "$work/sources"
          touched+=("$datafile")
        fi
        { head -c "$start" "$file"; ${jq} -j .replacement "$work/$n.out"; tail -c +$((end + 1)) "$file"; } > "$work/splice"
        cat "$work/splice" > "$file"
        touched+=("$file")
      done < <(sort -t$'\t' -k1,1 -k2,2nr "$work/accepted")
      nix fmt -- "''${touched[@]}"
      if [ -s "$work/sources" ]; then
        sort -u "$work/sources" | while read -r target; do
          users=$(grep -rIlF --exclude-dir=.git -e "$(basename "$target")" . | grep -vxF "./$target" || true)
          if [ -n "$users" ]; then
            echo "kept $target: still referenced by $(echo $users)"
          else
            rm -f "$target"
          fi
        done
      fi
    fi
    exec ${strictix} check "''${scope[@]}" --config ${config}
  '';

  check = pkgs.runCommand "strictix" {} ''
    cd ${inputs.self}
    ${strictix} check . --config ${config}
    touch $out
  '';
}
