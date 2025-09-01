lib: let
  inherit
    (lib)
    concatStringsSep
    splitString
    mapAttrsToList
    any
    ;
  inherit (builtins) typeOf replaceStrings elem;

  /**
  Convert a Nix value to KDL (KubeConfig Document Language) format.

  KDL is a document language with a node-based structure that's designed to be
  both human-readable and machine-parseable. It's used by tools like Zellij and Niri.

  # Inputs

  Options:
  - Currently no options, but structured for future extensibility

  Value: the Nix value to convert

  # Type

  ```
  toKDL :: AttrSet -> Any -> String
  ```

  # Examples
  :::{.example}
  ## `lib.generators.toKDL` usage example

  ```nix
  generators.toKDL {} {
    input = {
      keyboard = {
        xkb = {
          layout = "us";
        };
      };
      mouse = {
        accel-speed = 0.0;
      };
    };
  }
  ->
  input {
  	keyboard {
  		xkb {
  			layout "us"
  		}
  	}
  	mouse {
  		accel-speed 0.0
  	}
  }
  ```

  The generator supports special attributes for advanced KDL features:
  - `_args`: List of positional arguments
  - `_props`: Attribute set of properties (key=value format)
  - `_children`: List of child nodes (for explicit ordering)

  ```nix
  generators.toKDL {} {
    tab = {
      _props = {
        name = "Project";
        focus = true;
      };
      _children = [
        {
          pane = {
            command = "nvim";
          };
        }
      ];
    };
  }
  ->
  tab focus=true name="Project" {
  	pane {
  		command "nvim"
  	}
  }
  ```

  :::
  */
  toKDL = {} @ args: let
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
        else if element == false
        then "false"
        else if element == true
        then "true"
        else if typeOf element == "string"
        then ''"${sanitizeString element}"''
        else toString element
      );

    # Attrset Conversion
    # String -> AttrsOf Anything -> String
    convertAttrsToKDL = name: attrs: let
      optArgs = map literalValueToString (attrs._args or []);
      optProps = lib.mapAttrsToList (name: value: "${name}=${literalValueToString value}") (
        attrs._props or {}
      );

      orderedChildren = lib.pipe (attrs._children or []) [
        (map (child: mapAttrsToList convertAttributeToKDL child))
        lib.flatten
      ];
      unorderedChildren = lib.pipe attrs [
        (lib.filterAttrs (name: _:
          !(elem name [
            "_args"
            "_props"
            "_children"
          ])))
        (mapAttrsToList convertAttributeToKDL)
      ];
      children = orderedChildren ++ unorderedChildren;
      optChildren = lib.optional (children != []) ''
        {
        ${indentStrings children}
        }'';
    in
      lib.concatStringsSep " " ([name] ++ optArgs ++ optProps ++ optChildren);

    # List Conversion
    # String -> ListOf (OneOf [Int Float String Bool Null]) -> String
    convertListOfFlatAttrsToKDL = name: list: let
      flatElements = map literalValueToString list;
    in "${name} ${concatStringsSep " " flatElements}";

    # String -> ListOf Anything -> String
    convertListOfNonFlatAttrsToKDL = name: list: ''
      ${name} {
      ${indentStrings (map (x: convertAttributeToKDL "-" x) list)}
      }'';

    # String -> ListOf Anything -> String
    convertListToKDL = name: list: let
      elementsAreFlat =
        !any (el:
          elem (typeOf el) [
            "list"
            "set"
          ])
        list;
    in
      if elementsAreFlat
      then convertListOfFlatAttrsToKDL name list
      else convertListOfNonFlatAttrsToKDL name list;

    # Combined Conversion
    # String -> Anything -> String
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

  /**
  Mark string as KDL inline expression.

  This is useful for inserting raw KDL that should not be processed by the generator.

  # Inputs

  `expr`: The raw KDL string to inline

  # Type

  ```
  mkKDLInline :: String -> AttrSet
  ```

  # Examples
  :::{.example}
  ## `lib.generators.mkKDLInline` usage example

  ```nix
  generators.toKDL {} {
    some-complex-node = generators.mkKDLInline ''
      custom-syntax "with" "special" {
        formatting
      }
    '';
  }
  ```

  :::
  */
  mkKDLInline = expr: {
    _type = "kdl-inline";
    inherit expr;
  };
in {
  inherit toKDL mkKDLInline;
}
