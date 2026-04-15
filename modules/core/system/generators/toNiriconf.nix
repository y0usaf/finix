{
  config,
  lib,
  ...
}: let
  inherit (builtins) isList hasAttr;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.strings) concatStringsSep concatMapStringsSep;
  filterNonEmpty = lib.filter (s: s != "");
  inherit (lib) filterAttrs;
in {
  config.lib.generators.toNiriconf = attrs:
    lib.concatStringsSep "\n\n" (
      filterNonEmpty [
        (config.lib.generators.toKDL (filterAttrs (k: _: !lib.elem k ["output" "spawn-at-startup" "_extraConfig"]) attrs))
        (
          if hasAttr "output" attrs
          then
            concatStringsSep "\n" (mapAttrsToList (name: config: let
              pos = config.position;
            in ''              output "${name}" {
                      ${concatStringsSep "\n" (filterNonEmpty ([
                  (
                    if hasAttr "position" config
                    then "\tposition x=${toString pos.x} y=${toString pos.y}"
                    else ""
                  )
                  (
                    if hasAttr "mode" config
                    then "\tmode \"${toString config.mode}\""
                    else ""
                  )
                ]
                ++ (mapAttrsToList (key: value: "\t${key} \"${toString value}\"") (filterAttrs (k: _: k != "position" && k != "mode") config))))}
                      }'')
            attrs.output)
          else ""
        )
        (
          if hasAttr "spawn-at-startup" attrs
          then
            concatStringsSep "\n" (map (cmd:
              "spawn-at-startup "
              + concatMapStringsSep " " (arg: "\"${toString arg}\"") (
                if isList cmd
                then cmd
                else [cmd]
              ))
            attrs."spawn-at-startup")
          else ""
        )
        (
          if hasAttr "_extraConfig" attrs
          then attrs._extraConfig
          else ""
        )
      ]
    );
}
