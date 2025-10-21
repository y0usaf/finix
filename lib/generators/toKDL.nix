{lib}: {
  toKDL = let
    inherit
      (lib)
      concatStringsSep
      mapAttrsToList
      any
      ;
    inherit (builtins) typeOf replaceStrings elem;

    # ListOf String -> String
    indentStrings = let
      # Although the input of this function is a list of strings,
      # the strings themselves *will* contain newlines, so you need
      # to normalize the list by joining and resplitting them.
      unlines = lib.splitString "\n";
      lines = lib.concatStringsSep "\n";
      indentAll = lines: concatStringsSep "\n" (map (x: "	" + x) lines);
    in
      stringsWithNewlines: indentAll (unlines (lines stringsWithNewlines));

    # String -> String
    sanitizeString = replaceStrings ["\n" ''"''] ["\\n" ''\"''];

    # OneOf [Int Float String Bool Null] -> String
    literalValueToString = element:
      lib.throwIfNot
      (elem (typeOf element) [
        "int"
        "float"
        "string"
        "bool"
        "null"
      ])
      "Cannot convert value of type ${typeOf element} to KDL literal."
      (
        if typeOf element == "null"
        then "null"
        else if typeOf element == "bool"
        then
          if element
          then "true"
          else "false"
        else if typeOf element == "string"
        then ''"${sanitizeString element}"''
        else toString element
      );

    # Attrset Conversion
    # String -> AttrsOf Anything -> String
    convertAttrsToKDL = name: attrs: let
      children =
        (lib.pipe (attrs._children or []) [
          (map (child: mapAttrsToList convertAttributeToKDL child))
          lib.flatten
        ])
        ++ (lib.pipe attrs [
          (lib.filterAttrs (
            name: _:
              !(elem name [
                "_args"
                "_props"
                "_children"
              ])
          ))
          (mapAttrsToList convertAttributeToKDL)
        ]);
    in
      lib.concatStringsSep " " (
        [name]
        ++ map literalValueToString (attrs._args or [])
        ++ lib.mapAttrsToList (name: value: "${name}=${literalValueToString value}") (attrs._props or {})
        ++ lib.optional (children != []) ''
          {
          ${indentStrings children}
          }''
      );

    # List Conversion
    # String -> ListOf (OneOf [Int Float String Bool Null])  -> String
    convertListOfFlatAttrsToKDL = name: list: "${name} ${concatStringsSep " " (map literalValueToString list)}";

    # String -> ListOf Anything -> String
    convertListOfNonFlatAttrsToKDL = name: list: ''
      ${name} {
      ${indentStrings (map (x: convertAttributeToKDL "-" x) list)}
      }'';

    # String -> ListOf Anything  -> String
    convertListToKDL = name: list:
      if
        !any (
          el:
            elem (typeOf el) [
              "list"
              "set"
            ]
        )
        list
      then convertListOfFlatAttrsToKDL name list
      else convertListOfNonFlatAttrsToKDL name list;

    # Combined Conversion
    # String -> Anything  -> String
    convertAttributeToKDL = name: value: let
      vType = typeOf value;
    in
      if
        elem vType [
          "int"
          "float"
          "bool"
          "null"
          "string"
        ]
      then "${name} ${literalValueToString value}"
      else if vType == "set"
      then convertAttrsToKDL name value
      else if vType == "list"
      then convertListToKDL name value
      else
        throw ''
          Cannot convert type `(${typeOf value})` to KDL:
            ${name} = ${toString value}
        '';
  in
    attrs: ''
      ${concatStringsSep "\n" (mapAttrsToList convertAttributeToKDL attrs)}
    '';
}
