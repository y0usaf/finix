lib: let
  inherit
    (builtins)
    all
    isAttrs
    isBool
    isList
    isString
    isInt
    isFloat
    removeAttrs
    ;
  inherit (lib.attrsets) filterAttrs mapAttrsToList;
  inherit (lib.lists) foldl replicate;
  inherit
    (lib.strings)
    concatStrings
    concatStringsSep
    concatMapStringsSep
    hasPrefix
    escapeShellArg
    ;

  # KDL-specific value formatting
  formatKdlValue = value:
    if isBool value
    then
      if value
      then "#true"
      else "#false"
    else if value == null
    then "#null"
    else if isString value
    then
      # Check if string needs quoting
      if needsQuoting value
      then escapeShellArg value
      else value
    else if isInt value || isFloat value
    then toString value
    else toString value;

  # Check if a string needs quoting in KDL
  needsQuoting = str: let
    # KDL keywords that must be quoted
    keywords = ["true" "false" "null" "inf" "-inf" "nan"];
    # Characters that require quoting
    specialChars = ["(" ")" "{" "}" "[" "]" "/" "\\" "\"" "#" ";" "=" " " "\t" "\n" ":"];
    hasSpecialChar = lib.any (char: lib.hasInfix char str) specialChars;
    isKeyword = lib.elem str keywords;
    startsWithDigit =
      lib.hasPrefix "0" str
      || lib.hasPrefix "1" str
      || lib.hasPrefix "2" str
      || lib.hasPrefix "3" str
      || lib.hasPrefix "4" str
      || lib.hasPrefix "5" str
      || lib.hasPrefix "6" str
      || lib.hasPrefix "7" str
      || lib.hasPrefix "8" str
      || lib.hasPrefix "9" str;
    startsWithSign = lib.hasPrefix "+" str || lib.hasPrefix "-" str;
  in
    hasSpecialChar || isKeyword || startsWithDigit || (startsWithSign && builtins.stringLength str > 1);

  # Main KDL generator function following lib.generators pattern
  toKDL = attrs: toKDLWithOptions {} attrs;

  # KDL generator with options (like toINIWithGlobalSection)
  toKDLWithOptions = {
    indentLevel ? 0,
    addComments ? false,
    sortSections ? false,
  }: attrs: let
    initialIndent = concatStrings (replicate indentLevel "    ");

    toKdl' = indent: attrs: let
      # Check if a field should be treated as properties first
      isPropertiesField = name: value:
        isAttrs value
        && (name
          == "position"
          || name == "offset"
          || name == "size"
          || (builtins.all (v: !isAttrs v && !isList v) (builtins.attrValues value)
            && builtins.length (builtins.attrNames value) <= 4));

      # Separate properties fields from other attrs
      propertiesFields = filterAttrs isPropertiesField attrs;
      remainingAttrs = removeAttrs attrs (mapAttrsToList (n: _: n) propertiesFields);

      # Separate sections (nested attrs/lists) from simple key-value pairs
      sections = filterAttrs (_: v: isAttrs v || (isList v && all isAttrs v)) remainingAttrs;

      # Handle simple fields (non-nested values)
      simpleFields = filterAttrs (_: v: !(isAttrs v || (isList v && all isAttrs v))) remainingAttrs;

      # Format a section (nested structure)
      mkSection = name: value:
        if isList value
        then
          # Handle lists of attribute sets (like multiple window-rule entries)
          concatMapStringsSep "\n" (item: mkSection name item) value
        else if isAttrs value
        then
          # Handle nested attribute sets
          let
            hasContent = builtins.length (builtins.attrNames value) > 0;
            content = toKdl' "    ${indent}" value;
          in
            if hasContent
            then ''
              ${indent}${name} {
              ${content}
              ${indent}}''
            else "${indent}${name} {}" # Empty sections become empty braces
        else
          # Handle simple values as arguments to the node
          "${indent}${name} ${formatKdlValue value}";

      # Format simple fields
      mkSimpleField = name: value:
        if isList value
        then
          # Handle lists as multiple nodes with the same name (for things like preset-column-widths)
          if all isAttrs value
          then
            # List of attribute sets - each becomes a separate node
            concatMapStringsSep "\n" (
              item: let
                itemContent = toKdl' "    ${indent}" item;
              in
                if itemContent != ""
                then ''
                  ${indent}${name} {
                  ${itemContent}
                  ${indent}}''
                else "${indent}${name} {}"
            )
            value
          else
            # List of simple values
            concatMapStringsSep "\n" (item: "${indent}${name} ${formatKdlValue item}") value
        else if isBool value && value
        then
          # Handle boolean flags (true values become just the node name)
          "${indent}${name}"
        else if isBool value && !value
        then
          # Handle false boolean values (comment them out)
          "${indent}// ${name}"
        else
          # Handle regular key-value pairs
          "${indent}${name} ${formatKdlValue value}";

      # Format key-value properties (like position x=1280 y=0)
      mkProperties = name: props:
        if isAttrs props
        then let
          propList = mapAttrsToList (k: v: "${k}=${formatKdlValue v}") props;
          propString = concatStringsSep " " propList;
        in "${indent}${name} ${propString}"
        else mkSimpleField name props;

      # regularSimpleFields are the remaining simple fields after properties are removed
      regularSimpleFields = simpleFields;

      # Generate the output
      propertiesOutput =
        if propertiesFields == {}
        then ""
        else concatStringsSep "\n" (mapAttrsToList mkProperties propertiesFields);
      simpleOutput =
        if regularSimpleFields == {}
        then ""
        else concatStringsSep "\n" (mapAttrsToList mkSimpleField regularSimpleFields);
      sectionsOutput =
        if sections == {}
        then ""
        else concatStringsSep "\n" (mapAttrsToList mkSection sections);

      # Combine all outputs with proper spacing
      allOutputs = builtins.filter (s: s != "") [propertiesOutput simpleOutput sectionsOutput];
    in
      if allOutputs == []
      then ""
      else concatStringsSep "\n" allOutputs;
  in
    toKdl' initialIndent attrs;

  # Legacy function for backward compatibility
  toKdl = {
    attrs,
    indentLevel ? 0,
  }:
    toKDLWithOptions {inherit indentLevel;} attrs;

  # Merge multiple KDL configurations
  mergeKDLConfigs = configs:
    lib.foldl lib.recursiveUpdate {} configs;

  # Legacy alias
  mergeKdlConfigs = mergeKDLConfigs;

  # Create a Niri-specific configuration builder
  mkNiriConfig = {
    input ? {},
    output ? {},
    layout ? {},
    binds ? {},
    animations ? {},
    window-rule ? [],
    environment ? {},
    spawn-at-startup ? [],
    prefer-no-csd ? false,
    hotkey-overlay ? {},
    switch-events ? {},
    debug ? {},
    ...
  } @ config: let
    # Known Niri sections
    knownSections = [
      "input"
      "output"
      "layout"
      "binds"
      "animations"
      "window-rule"
      "environment"
      "spawn-at-startup"
      "prefer-no-csd"
      "hotkey-overlay"
      "switch-events"
      "debug"
    ];

    # Extract extra configuration
    extraConfig = removeAttrs config knownSections;

    # Build base configuration, filtering out empty sections
    baseConfig =
      lib.filterAttrs (
        n: v:
          if isAttrs v
          then v != {}
          else if isList v
          then v != []
          else if isBool v
          then v # Keep boolean values as-is
          else true
      ) ({
          inherit input layout binds animations environment;
          inherit hotkey-overlay switch-events debug;
        }
        // (
          if output != {}
          then {inherit output;}
          else {}
        )
        // (
          if window-rule != []
          then {"window-rule" = window-rule;}
          else {}
        )
        // (
          if spawn-at-startup != []
          then {"spawn-at-startup" = spawn-at-startup;}
          else {}
        )
        // (
          if prefer-no-csd
          then {"prefer-no-csd" = true;}
          else {}
        )
        // extraConfig);
  in
    toKDLWithOptions {
      addComments = true;
      sortSections = false;
    }
    baseConfig;
in {
  # Standard lib.generators pattern
  inherit toKDL toKDLWithOptions mergeKDLConfigs;

  # Niri-specific helpers
  inherit mkNiriConfig formatKdlValue;

  # Legacy aliases for backward compatibility
  inherit toKdl mergeKdlConfigs;
}
