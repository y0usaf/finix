{lib}: {
  # Convert preference value to JSON
  prefValue = pref:
    builtins.toJSON (
      if builtins.isBool pref || builtins.isInt pref || builtins.isString pref
      then pref
      else builtins.toString pref
    );

  # Convert attributes to lines with custom formatter
  attrsToLines = f: attrs: lib.concatMapAttrsStringSep "\n" f attrs;
}
