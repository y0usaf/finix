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
      lines = lib.concatStringsSep "\n";
    in
      stringsWithNewlines: (lines: concatStringsSep "\n" (map (x: "	" + x) lines)) ((lib.splitString "\n") (lines stringsWithNewlines));

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
        then ''"${replaceStrings ["\n" ''"''] ["\\n" ''\"''] element}"''
        else toString element
      );

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
      then let
        children =
          (lib.pipe (value._children or []) [
            (map (child: mapAttrsToList convertAttributeToKDL child))
            lib.flatten
          ])
          ++ (lib.pipe value [
            (lib.filterAttrs (
              childName: _:
                !(elem childName [
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
          ++ map literalValueToString (value._args or [])
          ++ lib.mapAttrsToList (propName: propValue: "${propName}=${literalValueToString propValue}") (value._props or {})
          ++ lib.optional (children != []) ''
            {
            ${indentStrings children}
            }''
        )
      else if vType == "list"
      then
        if
          !any (
            el:
              elem (typeOf el) [
                "list"
                "set"
              ]
          )
          value
        then "${name} ${concatStringsSep " " (map literalValueToString value)}"
        else ''
          ${name} {
          ${indentStrings (map (x: convertAttributeToKDL "-" x) value)}
          }''
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
