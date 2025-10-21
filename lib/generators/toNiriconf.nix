lib: let
  inherit (builtins) isList hasAttr;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.strings) concatStringsSep concatMapStringsSep;

  # Convert Nix attributes to KDL format specifically for niri
  toNiriconf = attrs: let
    kdlGenerator = import ./toKDL.nix {inherit lib;};

    # Format output nodes: output "name" { ... }
    formatOutput = name: config: let
      position =
        if hasAttr "position" config
        then "\tposition x=${toString config.position.x} y=${toString config.position.y}"
        else "";
      mode =
        if hasAttr "mode" config
        then "\tmode \"${toString config.mode}\""
        else "";
      otherConfig = lib.filterAttrs (k: _: k != "position" && k != "mode") config;
      otherLines = mapAttrsToList (key: value: "\t${key} \"${toString value}\"") otherConfig;
      content = lib.filter (s: s != "") ([position mode] ++ otherLines);
    in ''      output "${name}" {
              ${concatStringsSep "\n" content}
              }'';

    outputNodes =
      if hasAttr "output" attrs
      then concatStringsSep "\n" (mapAttrsToList formatOutput attrs.output)
      else "";

    # Format spawn-at-startup: spawn-at-startup "arg1" "arg2" ...
    formatSpawnCmd = cmd:
      "spawn-at-startup "
      + concatMapStringsSep " " (arg: "\"${toString arg}\"") (
        if isList cmd
        then cmd
        else [cmd]
      );

    spawnAtStartupNodes =
      if hasAttr "spawn-at-startup" attrs
      then concatStringsSep "\n" (map formatSpawnCmd attrs.spawn-at-startup)
      else "";

    # Main config without special attrs
    specialAttrs = ["output" "spawn-at-startup" "_extraConfig"];
    mainAttrs = lib.filterAttrs (k: _: !lib.elem k specialAttrs) attrs;
    mainConfig = kdlGenerator.toKDL mainAttrs;

    # Extra config appended as-is
    extraConfig =
      if hasAttr "_extraConfig" attrs
      then attrs._extraConfig
      else "";
  in
    lib.concatStringsSep "\n\n" (
      lib.filter (s: s != "") [mainConfig outputNodes spawnAtStartupNodes extraConfig]
    );
in {
  inherit toNiriconf;
}
