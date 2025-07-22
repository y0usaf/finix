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
  sectionOrderingRules = {
    animations = ["bezier" "animation"];
  };
  toHyprconf = {
    attrs,
    indentLevel ? 0,
    importantPrefixes ? ["$"],
  }: let
    initialIndent = concatStrings (replicate indentLevel "  ");
    toHyprconf' = indent: attrs: let
      sections = filterAttrs (_: v: isAttrs v || (isList v && all isAttrs v)) attrs;
      mkSection = n: attrs:
        if isList attrs
        then (concatMapStringsSep "\n" (a: mkSection n a) attrs)
        else let
          hasOrderingRules = builtins.hasAttr n sectionOrderingRules;
          processedAttrs =
            if hasOrderingRules
            then let
              orderingRule = sectionOrderingRules.${n};
              allKeys = builtins.attrNames attrs;
              orderedKeys = builtins.filter (key: builtins.elem key orderingRule) allKeys;
              unorderedKeys = builtins.filter (key: !(builtins.elem key orderingRule)) allKeys;
              sortedOrderedKeys = builtins.filter (ruleKey: builtins.elem ruleKey orderedKeys) orderingRule;
              finalKeyOrder = sortedOrderedKeys ++ unorderedKeys;
              orderedAttrs = lib.listToAttrs (map (key: {
                  name = key;
                  value = attrs.${key};
                })
                finalKeyOrder);
            in
              orderedAttrs
            else attrs;
        in ''
          ${indent}${n} {
          ${toHyprconf' "  ${indent}" processedAttrs}${indent}}
        '';
      mkFields = toKeyValue {
        listsAsDuplicateKeys = true;
        inherit indent;
      };
      allFields = filterAttrs (_: v: !(isAttrs v || (isList v && all isAttrs v))) attrs;
      isImportantField = n: _:
        foldl (acc: prev:
          if hasPrefix prev n
          then true
          else acc)
        false
        importantPrefixes;
      isEarlyField = n: _: n == "bezier";
      importantFields = filterAttrs isImportantField allFields;
      earlyFields = filterAttrs isEarlyField (removeAttrs allFields (mapAttrsToList (n: _: n) importantFields));
      regularFields = removeAttrs allFields (mapAttrsToList (n: _: n) (importantFields // earlyFields));
    in
      mkFields importantFields
      + mkFields earlyFields
      + concatStringsSep "\n" (mapAttrsToList mkSection sections)
      + mkFields regularFields;
  in
    toHyprconf' initialIndent attrs;
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
  toHyprconfAdvanced = {
    attrs,
    indentLevel ? 0,
    importantPrefixes ? ["$"],
    validateConfig ? false,
    sortSections ? true,
  }: let
    validateAttrs = attrs:
      if validateConfig
      then attrs
      else attrs;
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
  mergeHyprconfigs = configs:
    lib.foldl lib.recursiveUpdate {} configs;
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
