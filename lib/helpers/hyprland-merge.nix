###############################################################################
# Hyprland Configuration Merge Helper
# Properly merges multiple Hyprland configuration modules by concatenating
# list-based attributes instead of replacing them
###############################################################################

lib: let
  # Attributes that should have their lists concatenated instead of replaced
  listAttributes = [
    "bind"
    "bindm" 
    "exec-once"
    "windowrule"
    "windowrulev2"
    "layerrule"
    "env"
  ];

  # Check if an attribute should be treated as a concatenatable list
  isListAttribute = name: builtins.elem name listAttributes;

  # Merge two configuration objects with proper list handling
  mergeConfigs = left: right: let
    # Get all attribute names from both configs
    allNames = lib.unique (builtins.attrNames left ++ builtins.attrNames right);
    
    # Merge each attribute appropriately
    mergedAttrs = lib.genAttrs allNames (name: let
      leftVal = left.${name} or [];
      rightVal = right.${name} or [];
      leftExists = builtins.hasAttr name left;
      rightExists = builtins.hasAttr name right;
    in
      if isListAttribute name then
        # Concatenate lists for list attributes
        (if leftExists then leftVal else []) ++ (if rightExists then rightVal else [])
      else if leftExists && rightExists then
        # For non-list attributes, use recursiveUpdate if both are attrs, otherwise right wins
        if builtins.isAttrs leftVal && builtins.isAttrs rightVal then
          lib.recursiveUpdate leftVal rightVal
        else
          rightVal
      else if leftExists then
        leftVal
      else
        rightVal
    );
  in
    mergedAttrs;

  # Merge multiple configuration objects
  mergeMultipleConfigs = configs: 
    lib.foldl mergeConfigs {} configs;

in {
  inherit mergeConfigs mergeMultipleConfigs;
}