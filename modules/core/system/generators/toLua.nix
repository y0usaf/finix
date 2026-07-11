{lib, ...}: {
  # Serialize a Nix value to a Lua table literal. Unlike toKDL/toNiriconf,
  # tomoe's config is a real Lua program (init.lua); toLua is a *value
  # serializer*, not a whole-config generator — it renders inline attrsets
  # embedded in the hand-written Lua body (e.g. `tomoe.settings { border =
  # ${toLua {...}} }`).
  #
  # - null  → key omitted (unset fields cleanly drop; reload-undoes-edit)
  # - bool  → true / false;  int/float → bare number
  # - str   → double-quoted, with \ " \n \r escaped
  # - list  → { a, b, c } brace sequence
  # - attrs → { k = v, } table; recursive
  # - keys matching ^[A-Za-z_][A-Za-z0-9_]*$ emit bare (`mod = "super"`);
  #   keys with dashes/space/digits-at-start/etc. emit quoted
  #   (["DP-1"] = ...), so connector names like DP-4 / HDMI-A-2 work.
  # No trailing newline: it interpolates mid-line.
  config.lib.generators.toLua = let
    inherit
      (lib)
      concatStringsSep
      boolToString
      isAttrs
      isList
      isString
      isBool
      isInt
      isFloat
      replaceStrings
      filterAttrs
      filter
      mapAttrsToList
      ;
    inherit (builtins) match typeOf;

    # Quote a string for Lua, mirroring toKDL's literalValueToString.
    quoteStr = s: ''"${(replaceStrings ["\\" "\"" "\n" "\r"] ["\\\\" "\\\"" "\\n" "\\r"]) s}"'';

    valStr = v:
      if isAttrs v
      then
        "{ "
        + concatStringsSep ", " (filter (s: s != "") (mapAttrsToList entry (filterAttrs (_: x: x != null) v)))
        + " }"
      else if isList v
      then "{ " + concatStringsSep ", " (map valStr (filter (x: x != null) v)) + " }"
      else if isString v
      then quoteStr v
      else if isBool v
      then boolToString v
      else if isInt v || isFloat v
      then toString v
      else if v == null
      then "nil"
      else throw "toLua: cannot serialize ${typeOf v}";

    entry = k: v:
      if v == null
      then ""
      else "${(k:
        if isString k && (s: match "[A-Za-z_][A-Za-z0-9_]*" s != null) k
        then k
        else if isString k
        then "[${quoteStr k}]"
        else "[${toString k}]")
      k} = ${valStr v}";
  in
    value:
      if isAttrs value
      then
        "{ "
        + concatStringsSep ", " (lib.filter (s: s != "") (lib.mapAttrsToList entry (lib.filterAttrs (_: x: x != null) value)))
        + " }"
      else valStr value;
}
