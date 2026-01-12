{lib}: let
  inherit (builtins) toJSON isBool isInt isString toString;
in {
  # Convert preference value to JSON
  prefValue = pref:
    toJSON (
      if isBool pref || isInt pref || isString pref
      then pref
      else toString pref
    );

  # Convert attributes to lines with custom formatter
  attrsToLines = f: attrs: lib.concatMapAttrsStringSep "\n" f attrs;
}
