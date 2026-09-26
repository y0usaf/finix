{lib, ...}: let
  inherit
    (lib)
    concatStringsSep
    filterAttrs
    isAttrs
    isDerivation
    isList
    isString
    mapAttrsToList
    replaceStrings
    ;
  inherit (builtins) attrNames elem match typeOf;

  quoteStr = s: ''"${replaceStrings ["\\" "\"" "\n" "\r"] ["\\\\" "\\\"" "\\n" "\\r"] s}"'';

  floatStr = f: let
    json = builtins.toJSON f;
  in
    if json == "null"
    then throw "toLua: cannot serialize a non-finite float"
    else json;

  reservedWords = [
    "and"
    "break"
    "do"
    "else"
    "elseif"
    "end"
    "false"
    "for"
    "function"
    "goto"
    "if"
    "in"
    "local"
    "nil"
    "not"
    "or"
    "repeat"
    "return"
    "then"
    "true"
    "until"
    "while"
  ];

  keyStr = k:
    if match "[A-Za-z_][A-Za-z0-9_]*" k != null && !elem k reservedWords
    then k
    else "[${quoteStr k}]";

  isInlineText = form: isString form && match "[[:space:]]*" form == null;

  mkLuaInline = expr:
    if isInlineText expr
    then {
      _type = "lua-inline";
      inherit expr;
    }
    else throw "mkLuaInline: expected a nonblank string";

  isInline = v: isAttrs v && (v._type or null) == "lua-inline";

  inlineStr = v:
    if attrNames v == ["_type" "expr"] && isInlineText v.expr
    then "(${v.expr})"
    else throw "toLua: inline wrapper must contain only _type and expr, a nonblank string";

  listStr = vs:
    if vs == []
    then "{}"
    else "{ ${concatStringsSep ", " (map valStr vs)} }";

  attrsStr = v: let
    present = filterAttrs (_: x: x != null) v;
    entries = mapAttrsToList (k: x: "${keyStr k} = ${valStr x}") present;
  in
    if entries == []
    then "{}"
    else "{ ${concatStringsSep ", " entries} }";

  atoms = {
    "null" = _: "nil";
    bool = v:
      if v
      then "true"
      else "false";
    float = floatStr;
    int = toString;
    path = v: quoteStr "${v}";
    string = quoteStr;
  };

  atomStr = v:
    (atoms.${typeOf v} or (throw "toLua: cannot serialize ${typeOf v}")) v;

  valStr = v:
    if isInline v
    then inlineStr v
    else if isDerivation v
    then quoteStr "${v}"
    else if isAttrs v
    then attrsStr v
    else if isList v
    then listStr v
    else atomStr v;
in {
  config.lib.generators.mkLuaInline = mkLuaInline;
  config.lib.generators.toLua = valStr;
}
