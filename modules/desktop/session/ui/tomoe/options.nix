{lib, ...}: {
  options.user.ui.tomoe = {
    layout = lib.mkOption {
      type = lib.types.enum ["deck" "sway"];
      default = "deck";
      description = ''
        Window-management layout generated into ~/.config/tomoe/init.lisp:
        "deck" = two 16:9 deck columns (the original ultrawide layout);
        "sway" = manual h/v split trees over numbered workspaces
        (Alt+J/K scroll workspaces, Alt+H/L focus left/right).
      '';
    };

    displays = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = {};
      description = ''
        Per-output configure-output keywords, keyed by output name: `mode`
        ([W H] or [W H Hz]), `refresh`, `scale`, `position` ([X Y] physical
        pixels), `disabled`, `mirror`, `vrr`, `icc` (an ICC profile path). An
        empty attrset means tomoe uses EDID-preferred modes for every output.
      '';
      example = lib.literalExpression ''
        {
          "DP-1" = { mode = [5120 1440]; position = [0 0]; vrr = true; };
          "eDP-1".disabled = true;
        }
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra Common Lisp appended to the generated ~/.config/tomoe/init.lisp.";
    };
  };
}
