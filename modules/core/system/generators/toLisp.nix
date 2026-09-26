{lib, ...}: let
  inherit
    (lib)
    concatStringsSep
    filterAttrs
    isAttrs
    isList
    isString
    mapAttrsToList
    replaceStrings
    toUpper
    unique
    ;
  inherit (builtins) attrNames length match typeOf;

  quoteStr = s: ''"${replaceStrings ["\\" "\""] ["\\\\" "\\\""] s}"'';

  floatStr = f: let
    json = builtins.toJSON f;
  in
    if json == "null"
    then throw "toLisp: cannot serialize a non-finite float"
    else if match ".*[eE].*" json != null
    then replaceStrings ["e" "E"] ["d" "d"] json
    else "${json}d0";

  keywordStr = k: ":|${replaceStrings ["\\" "|"] ["\\\\" "\\|"] (toUpper k)}|";

  isInlineText = form: isString form && match "[[:space:]]*" form == null;

  mkLispInline = form:
    if isInlineText form
    then {__toLispInline = form;}
    else throw "mkLispInline: expected a nonblank string";

  isInline = v: isAttrs v && v ? __toLispInline;

  inlineStr = v:
    if attrNames v == ["__toLispInline"] && isInlineText v.__toLispInline
    then v.__toLispInline
    else throw "toLisp: inline wrapper must contain only __toLispInline, a nonblank string";

  listStr = vs:
    if vs == []
    then "nil"
    else "(list ${concatStringsSep " " (map valStr vs)})";

  entry = k: v: "${keywordStr k} ${valStr v}";

  attrsStr = v: let
    present = filterAttrs (_: x: x != null) v;
    names = map toUpper (attrNames present);
    entries = mapAttrsToList entry present;
  in
    if length names != length (unique names)
    then throw "toLisp: keys collide after ASCII uppercasing"
    else if entries == []
    then "nil"
    else "(list ${concatStringsSep " " entries})";

  atoms = {
    "null" = _: "nil";
    bool = v:
      if v
      then "t"
      else "nil";
    float = floatStr;
    int = toString;
    path = v: quoteStr "${v}";
    string = quoteStr;
  };

  atomStr = v:
    (atoms.${typeOf v} or (throw "toLisp: cannot serialize ${typeOf v}")) v;

  valStr = v:
    if isInline v
    then inlineStr v
    else if isAttrs v
    then attrsStr v
    else if isList v
    then listStr v
    else atomStr v;
in {
  config.lib.generators.mkLispInline = mkLispInline;
  config.lib.generators.toLisp = valStr;
}
