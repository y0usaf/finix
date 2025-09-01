lib: let
  inherit
    (lib)
    assertMsg
    attrNames
    concatStrings
    concatStringsSep
    filter
    isAttrs
    isBool
    isDerivation
    isFloat
    isInt
    isList
    isPath
    isString
    mapAttrsToList
    match
    typeOf
    ;
  inherit (lib.strings) toJSON;
  inherit (lib.debug) toPretty;

  /**
  Convert a Nix value to Lua code.

  # Inputs

  Options:
  - multiline: whether to format multiline (default: true)
  - indent: current indentation level (default: "")
  - asBindings: whether to generate variable bindings (default: false)

  Value: the Nix value to convert
  */
  toLua = {
    multiline ? true,
    indent ? "",
    asBindings ? false,
  } @ args: v: let
    innerIndent = "${indent}  ";
    introSpace =
      if multiline
      then "\n${innerIndent}"
      else " ";
    outroSpace =
      if multiline
      then "\n${indent}"
      else " ";
    innerArgs =
      args
      // {
        indent =
          if asBindings
          then indent
          else innerIndent;
        asBindings = false;
      };
    concatItems = concatStringsSep ",${introSpace}";

    isLuaInline = {_type ? null, ...}: _type == "lua-inline";

    generatedBindings = assert assertMsg (badVarNames == []) "Bad Lua var names: ${toPretty {} badVarNames}";
      concatStrings (mapAttrsToList (key: value: "${indent}${key} = ${toLua innerArgs value}\n") v);

    # Lua variable name validation
    matchVarName = match "[[:alpha:]_][[:alnum:]_]*(\\.[[:alpha:]_][[:alnum:]_]*)*";
    badVarNames = filter (name: matchVarName name == null) (attrNames v);
  in
    if asBindings
    then generatedBindings
    else if v == null
    then "nil"
    else if isInt v || isFloat v || isString v || isBool v
    then toJSON v
    else if isPath v || isDerivation v
    then toJSON "${v}"
    else if isList v
    then
      if v == []
      then "{}"
      else "{${introSpace}${concatItems (map (value: "${toLua innerArgs value}") v)}${outroSpace}}"
    else if isAttrs v
    then
      if isLuaInline v
      then "(${v.expr})"
      else if v == {}
      then "{}"
      else "{${introSpace}${
        concatItems (mapAttrsToList (key: value: "[${toJSON key}] = ${toLua innerArgs value}") v)
      }${outroSpace}}"
    else abort "generators.toLua: type ${typeOf v} is unsupported";

  /**
  Mark string as Lua expression to be inlined when processed by toLua.
  */
  mkLuaInline = expr: {
    _type = "lua-inline";
    inherit expr;
  };
in {
  inherit toLua mkLuaInline;
}
