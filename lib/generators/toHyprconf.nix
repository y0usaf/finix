# Sophisticated Hyprland configuration generator
# Based on Home Manager's implementation with additional enhancements
lib: let
  inherit
    (builtins)
    all
    isAttrs
    isList
    removeAttrs
    ;
  inherit (lib.attrsets) filterAttrs mapAttrsToList;
  inherit (lib.generators) toKeyValue;
  inherit (lib.lists) foldl replicate;
  inherit
    (lib.strings)
    concatStrings
    concatStringsSep
    concatMapStringsSep
    hasPrefix
    ;
  inherit (lib.types) package;

  # Core Hyprland configuration generator
  toHyprconf = {
    attrs,
    indentLevel ? 0,
    importantPrefixes ? ["$"],
  }: let
    initialIndent = concatStrings (replicate indentLevel "  ");

    toHyprconf' = indent: attrs: let
      # Separate sections (nested attribute sets or lists of attribute sets)
      sections = filterAttrs (_: v: isAttrs v || (isList v && all isAttrs v)) attrs;

      # Generate section configuration
      mkSection = n: attrs:
        if isList attrs
        then (concatMapStringsSep "\n" (a: mkSection n a) attrs)
        else ''
          ${indent}${n} {
          ${toHyprconf' "  ${indent}" attrs}${indent}}
        '';

      # Generate key-value fields
      mkFields = toKeyValue {
        listsAsDuplicateKeys = true;
        inherit indent;
      };

      # All non-section fields
      allFields = filterAttrs (_: v: !(isAttrs v || (isList v && all isAttrs v))) attrs;

      # Check if field name has important prefix (like $ for variables)
      isImportantField = n: _:
        foldl (acc: prev:
          if hasPrefix prev n
          then true
          else acc)
        false
        importantPrefixes;

      # Separate important fields (variables, etc.) to be placed first
      importantFields = filterAttrs isImportantField allFields;
      regularFields = removeAttrs allFields (mapAttrsToList (n: _: n) importantFields);
    in
      # Order: important fields first, then sections, then regular fields
      mkFields importantFields
      + concatStringsSep "\n" (mapAttrsToList mkSection sections)
      + mkFields regularFields;
  in
    toHyprconf' initialIndent attrs;

  # Plugin configuration generator for Hyprland
  # Handles both package derivations and string paths
  pluginsToHyprconf = plugins: importantPrefixes:
    toHyprconf {
      attrs = {
        plugin = let
          mkEntry = entry:
            if package.check entry
            then "${entry}/lib/lib${entry.pname}.so"
            else entry;
        in
          map mkEntry plugins;
      };
      inherit importantPrefixes;
    };

  # Advanced configuration generator with validation
  toHyprconfAdvanced = {
    attrs,
    indentLevel ? 0,
    importantPrefixes ? ["$"],
    validateConfig ? false,
    sortSections ? true,
  }: let
    # Optional validation for common Hyprland configuration issues
    validateAttrs = attrs:
      if validateConfig
      then
        # Add validation logic here if needed
        # For now, just pass through
        attrs
      else attrs;

    # Optional section sorting for consistent output
    sortedAttrs =
      if sortSections
      then let
        sortedKeys = builtins.sort (a: b: a < b) (builtins.attrNames attrs);
      in
        lib.genAttrs sortedKeys (key: attrs.${key})
      else attrs;

    processedAttrs = validateAttrs sortedAttrs;
  in
    toHyprconf {
      inherit indentLevel importantPrefixes;
      attrs = processedAttrs;
    };

  # Utility function to merge multiple Hyprland configurations
  mergeHyprconfigs = configs:
    lib.foldl lib.recursiveUpdate {} configs;

  # Generate configuration with common Hyprland structure
  mkHyprlandConfig = {
    general ? {},
    decoration ? {},
    animations ? {},
    input ? {},
    gestures ? {},
    misc ? {},
    binds ? {},
    windowrule ? [],
    windowrulev2 ? [],
    layerrule ? [],
    workspace ? [],
    monitor ? [],
    exec-once ? [],
    exec ? [],
    env ? [],
    plugins ? [],
    source ? [],
    ...
  } @ config: let
    # Remove known sections from passthrough
    knownSections = [
      "general"
      "decoration"
      "animations"
      "input"
      "gestures"
      "misc"
      "binds"
      "windowrule"
      "windowrulev2"
      "layerrule"
      "workspace"
      "monitor"
      "exec-once"
      "exec"
      "env"
      "plugins"
      "source"
    ];
    extraConfig = removeAttrs config knownSections;

    baseConfig =
      {
        inherit general decoration animations input gestures misc binds;
        inherit windowrule windowrulev2 layerrule workspace monitor;
        "exec-once" = exec-once;
        inherit exec env source;
      }
      // extraConfig;
  in
    toHyprconf {
      attrs = baseConfig;
      importantPrefixes = ["$" "exec" "source"];
    }
    + (
      if plugins != []
      then "\n" + pluginsToHyprconf plugins ["$"]
      else ""
    );
in {
  inherit
    toHyprconf
    pluginsToHyprconf
    toHyprconfAdvanced
    mergeHyprconfigs
    mkHyprlandConfig
    ;
}
