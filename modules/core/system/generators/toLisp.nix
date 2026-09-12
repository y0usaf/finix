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

  # Serialize a Nix value to a Common Lisp form. Like toLua this is a *value
  # serializer*, not a whole-config generator: it renders an expression to
  # splice into hand-written Lisp (e.g. `(getf ${toLisp {...}} :border)`).
  # Ekko's own sources are the target dialect (CL, keyword plists, getf).
  #
  # Values render as expressions for evaluated positions, not quoted literals.
  # Inside backquote, use ,${toLisp v} for one value, or ,@${toLisp xs} inside
  # a list to splice a list-valued result. Without a comma, generated forms
  # are template data rather than evaluated expressions.
  #
  # - null       → nil
  # - bool       → t / nil
  # - int        → bare integer
  # - float      → CL double-float literal (3.14d0, 1d-7); Nix floats are
  #                binary64, so a single-float literal loses precision.
  #                Non-finite values throw.
  # - str        → double-quoted, escaping \ and ". CL reads \n as n,
  #                not a newline, so real newlines are emitted literally
  # - path       → double-quoted store path; interpolation copies it into the
  #                store, where builtins.toString leaves a checkout-local ref
  # - list       → (list a b c); empty → nil; null elements become nil,
  #                preserving their positions
  # - attrs      → keyword plist; null-valued attributes are omitted
  # - keys       → ASCII-uppercase, then always :|escaped|; non-ASCII
  #                characters remain unchanged. Reject normalized-name
  #                collisions among retained attributes in each plist.
  #
  # Attribute null means absent; false emits explicit nil, which overrides a
  # getf default. Null list elements are never omitted.
  #
  # Nix strings cannot express the code/value distinction Lisp makes, so
  # symbols and raw forms enter through mkLispInline. mkLispInline accepts
  # trusted, nonblank strings; the caller must supply exactly one Lisp
  # expression, whose syntax is not parsed or sandboxed. foo references a
  # variable, 'foo yields symbol data, :foo self-evaluates. __toLispInline is
  # reserved for exact singleton wrappers, and malformed wrappers throw; the
  # marker is namespaced, not unforgeable.
  quoteStr = s: ''"${replaceStrings ["\\" "\""] ["\\\\" "\\\""] s}"'';

  # builtins.toString rounds floats to six decimal places. builtins.toJSON
  # preserves round-trip precision; d forces a CL double-float literal.
  # JSON encodes non-finite floats as null; CL has no portable literal for them.
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

  # Leaf values render as expressions rather than lists. Keyed by
  # builtins.typeOf: every scalar the serializer accepts is listed here, and
  # atomStr throws for the rest (lambdas, functions). A path interpolates into
  # the store, so the literal names a store path rather than a checkout-local
  # file.
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
