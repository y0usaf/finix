{lib, ...}: let
  toHyprconf = {
    attrs,
    importantPrefixes ? ["$"],
    indentLevel ? 0,
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

    toHyprconf' = indent: attrs: let
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

      importantFields = filterAttrs (n: _:
        foldl (acc: prev:
          if hasPrefix prev n
          then true
          else acc)
        false
        importantPrefixes)
      allFields;
    in
      mkFields importantFields
      + concatStringsSep "\n" (mapAttrsToList mkSection (filterAttrs (_: v: isAttrs v || (isList v && all isAttrs v)) attrs))
      + mkFields (removeAttrs allFields (mapAttrsToList (n: _: n) importantFields));
  in
    toHyprconf' (concatStrings (replicate indentLevel "  ")) attrs;
in {
  config.lib.generators.toHyprconf = toHyprconf;
}
