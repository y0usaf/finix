{lib, ...}: {
  options.user.ui.tomoe = {
    enable = lib.mkEnableOption "tomoe Wayland compositor";

    displays = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Per-output display settings, keyed by output name. Serialized to
        the `tomoe.settings { displays = ... }` table via toLua. Each value
        may set `resolution` ("<preferred|max|WxH>[@<Hz|max]>"), `position`
        `{ x, y }` (physical pixels), `mirror`, `disabled`, `vrr`. An empty
        attrset means tomoe uses EDID-preferred modes for every output.
      '';
      example = lib.literalExpression ''
        {
          "DP-1" = { resolution = "max@max"; position = { x = 0; y = 0; }; vrr = true; };
          "eDP-1" = { disabled = true; };
        }
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra Lua appended to the generated ~/.config/tomoe/init.lua.";
    };
  };
}
