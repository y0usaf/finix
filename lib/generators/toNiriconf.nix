lib: let
  inherit
    (builtins)
    all
    isAttrs
    isList
    hasAttr
    attrNames
    elem
    filter
    mapAttrs
    ;
  inherit (lib.attrsets) filterAttrs mapAttrsToList;
  inherit (lib.lists) concatMap;
  inherit
    (lib.strings)
    concatStringsSep
    concatMapStringsSep
    ;

  # Convert Nix attributes to KDL format specifically for niri
  toNiriconf = attrs: let
    # Handle special output nodes that need string arguments
    outputNodes = 
      if hasAttr "output" attrs
      then
        concatStringsSep "\n" (mapAttrsToList (name: config:
          ''output "${name}" {'' + "\n"
          + concatStringsSep "\n" (mapAttrsToList (key: value:
              if key == "position"
              then "\tposition x=${toString value.x} y=${toString value.y}"
              else "\t${key} \"${toString value}\""
            ) config)
          + "\n}"
        ) attrs.output)
      else "";

    # Extract extraConfig if present
    extraConfig = 
      if hasAttr "_extraConfig" attrs
      then attrs._extraConfig
      else "";

    # Remove output and _extraConfig from main config since we handle them separately
    mainAttrs = builtins.removeAttrs attrs (
      (if hasAttr "output" attrs then ["output"] else [])
      ++ (if hasAttr "_extraConfig" attrs then ["_extraConfig"] else [])
    );

    # Import the KDL generator directly
    kdlGenerator = (import ./toKDL.nix { inherit lib; });
    
    # Generate main config using KDL generator
    mainConfig = kdlGenerator.toKDL {} mainAttrs;

  in
    mainConfig
    + (if outputNodes != "" then "\n\n" + outputNodes else "")
    + (if extraConfig != "" then "\n\n" + extraConfig else "");

in {
  inherit toNiriconf;
}