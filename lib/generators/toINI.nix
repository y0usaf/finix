{lib}: {
  # INI configuration generator
  toINI = _: let
    inherit (lib) concatStringsSep mapAttrsToList;
    inherit (builtins) typeOf toString;

    renderValue = value:
      if typeOf value == "bool"
      then
        if value
        then "true"
        else "false"
      else if typeOf value == "string"
      then value
      else toString value;

    renderSection = name: attrs:
      "[${name}]\n" + (concatStringsSep "\n" (mapAttrsToList (key: value: "  ${key} = ${renderValue value}") attrs));
  in
    config: concatStringsSep "\n\n" (mapAttrsToList renderSection config);
}
