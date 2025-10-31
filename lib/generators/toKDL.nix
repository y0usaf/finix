{lib}: {
  toKDL = let
    inherit
      (lib)
      concatStringsSep
      mapAttrsToList
      any
      ;
    inherit (builtins) typeOf replaceStrings elem;

    indentStrings = let
      unlines = lib.splitString "\n";
      lines = lib.concatStringsSep "\n";
      indentAll = lines: concatStringsSep "\n" (map (x: "	" + x) lines);
    in
      stringsWithNewlines: indentAll (unlines (lines stringsWithNewlines));

    sanitizeString = replaceStrings ["\n" ''"''] ["\\n" ''\"''];

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

    convertListOfFlatAttrsToKDL = name: list: "${name} ${concatStringsSep " " (map literalValueToString list)}";

    convertListOfNonFlatAttrsToKDL = name: list: ''
      ${name} {
      ${indentStrings (map (x: convertAttributeToKDL "-" x) list)}
      }'';

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
