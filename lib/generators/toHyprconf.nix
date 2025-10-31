lib: let
  toHyprconf = {
    attrs,
    indentLevel ? 0,
    importantPrefixes ? ["$"],
  }: let
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

    initialIndent = concatStrings (replicate indentLevel "  ");

    toHyprconf' = indent: attrs: let
      sections = filterAttrs (_: v: isAttrs v || (isList v && all isAttrs v)) attrs;

      mkSection = n: attrs:
        if lib.isList attrs
        then (concatMapStringsSep "\n" (a: mkSection n a) attrs)
        else ''
          ${indent}${n} {
          ${toHyprconf' "  ${indent}" attrs}${indent}}
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

      importantFields = filterAttrs isImportantField allFields;

      fields = removeAttrs allFields (mapAttrsToList (n: _: n) importantFields);
    in
      mkFields importantFields
      + concatStringsSep "\n" (mapAttrsToList mkSection sections)
      + mkFields fields;
  in
    toHyprconf' initialIndent attrs;

  pluginsToHyprconf = plugins: importantPrefixes:
    toHyprconf {
      attrs = {
        plugin = let
          mkEntry = entry:
            if lib.types.package.check entry
            then "${entry}/lib/lib${entry.pname}.so"
            else entry;
        in
          map mkEntry plugins;
      };
      inherit importantPrefixes;
    };
in {
  inherit toHyprconf pluginsToHyprconf;
}
