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
    pluginsSuffix ? "",
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
    toHyprconf' initialIndent attrs + pluginsSuffix;
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
in {
  inherit
    toHyprconf
    pluginsToHyprconf
    ;
}
