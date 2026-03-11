lib: let
  inherit (builtins) isList hasAttr;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.strings) concatStringsSep concatMapStringsSep;
in {
  toNiriconf = attrs:
    lib.concatStringsSep "\n\n" (
      lib.filter (s: s != "") [
        ((import ./toKDL.nix {inherit lib;}).toKDL (
          lib.filterAttrs (k: _: !lib.elem k ["output" "spawn-at-startup" "_extraConfig"]) attrs
        ))
        (
          if hasAttr "output" attrs
          then
            concatStringsSep "\n" (mapAttrsToList (name: config: ''              output "${name}" {
                      ${concatStringsSep "\n" (lib.filter (s: s != "") ([
                  (
                    if hasAttr "position" config
                    then "\tposition x=${toString config.position.x} y=${toString config.position.y}"
                    else ""
                  )
                  (
                    if hasAttr "mode" config
                    then "\tmode \"${toString config.mode}\""
                    else ""
                  )
                ]
                ++ (mapAttrsToList (key: value: "\t${key} \"${toString value}\"") (lib.filterAttrs (k: _: k != "position" && k != "mode") config))))}
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
            attrs.spawn-at-startup)
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
