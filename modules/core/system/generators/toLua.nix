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
      replaceStrings
      filterAttrs
      filter
      mapAttrsToList
      ;
    inherit (builtins) match typeOf;

    # Quote a string for Lua, mirroring toKDL's literalValueToString.
    quoteStr = s: ''"${(replaceStrings ["\\" "\"" "\n" "\r"] ["\\\\" "\\\"" "\\n" "\\r"]) s}"'';

    # Scalar values dispatch on builtins.typeOf; anything unhandled throws.
    atomRenderers = {
      bool = boolToString;
      float = toString;
      int = toString;
      string = quoteStr;
      "null" = _v: "nil";
    };

    atomStr = v: let
      renderer = atomRenderers.${typeOf v} or null;
    in
      if renderer == null
      then throw "toLua: cannot serialize ${typeOf v}"
      else renderer v;

    listStr = vs: "{ " + concatStringsSep ", " (map valStr (filter (x: x != null) vs)) + " }";

    attrsetStr = v:
      "{ "
      + concatStringsSep ", " (filter (s: s != "") (mapAttrsToList entry (filterAttrs (_: x: x != null) v)))
      + " }";

    valStr = v:
      if isAttrs v
      then attrsetStr v
      else if isList v
      then listStr v
      else atomStr v;

    # Keys matching ^[A-Za-z_][A-Za-z0-9_]*$ emit bare; anything else emits
    # quoted (["DP-1"] = ...), so connector names like DP-4 / HDMI-A-2 work.
    keyStr = k:
      if isString k && match "[A-Za-z_][A-Za-z0-9_]*" k != null
      then k
      else if isString k
      then "[${quoteStr k}]"
      else "[${toString k}]";

    entry = k: v:
      if v == null
      then ""
      else "${keyStr k} = ${valStr v}";
  in
    valStr;
}
