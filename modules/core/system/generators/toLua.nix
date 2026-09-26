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

  # Serialize a Nix value to a Lua expression. Like toLisp this is a *value
  # serializer*, not a whole-config generator: Nix renders the data a Lua
  # program needs (`local nix = ${toLua {...}}`), and the program itself lives
  # in a real .lua file read in after it.
  #
  # - null       → nil
  # - bool       → true / false
  # - int        → bare integer
  # - float      → shortest round-trip literal (0.1, 1e-07); toString would
  #                round to six decimals. Non-finite values throw.
  # - str        → double-quoted, escaping \ " and CR/LF (Lua rejects raw
  #                newlines inside a quoted string)
  # - path       → double-quoted store path; interpolation copies it into the
  #                store, where builtins.toString leaves a checkout-local ref
  # - derivation → double-quoted output path, not its attribute set
  # - list       → { a, b, c }; empty → {}; null elements become nil,
  #                preserving the positions of the elements after them
  # - attrs      → { k = v, ["k-2"] = v } table; null-valued attributes are
  #                omitted. Keys are always strings: identifier-shaped keys
  #                that are not Lua reserved words emit bare, the rest emit
  #                ["quoted"]. Entries render in attribute-name order.
  #
  # Attribute null means absent; false emits an explicit false.
  #
  # Nix values cannot express Lua code, so function references and calls enter
  # through mkLuaInline. It takes a trusted, nonblank string holding exactly
  # one Lua expression, whose syntax is not parsed or sandboxed; the form is
  # wrapped in parentheses, which also truncates a multi-value call to its
  # first value. The wrapper shares nixpkgs' shape ({ _type = "lua-inline";
  # expr; }), so lib.generators.mkLuaInline values render here too; wrappers
  # with any other attributes throw.
  quoteStr = s: ''"${replaceStrings ["\\" "\"" "\n" "\r"] ["\\\\" "\\\"" "\\n" "\\r"] s}"'';

  # builtins.toJSON preserves round-trip precision and its number syntax is
  # valid Lua. JSON encodes non-finite floats as null; Lua has no literal.
  floatStr = f: let
    json = builtins.toJSON f;
  in
    if json == "null"
    then throw "toLua: cannot serialize a non-finite float"
    else json;

  # Lua 5.4 reserved words; a bare `end = 1` inside a table is a syntax error.
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

  # Leaf values render as expressions. Keyed by builtins.typeOf: every scalar
  # the serializer accepts is listed here, and atomStr throws for the rest
  # (lambdas, functions).
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
