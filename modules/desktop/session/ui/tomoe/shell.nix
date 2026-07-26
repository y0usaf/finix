{
  config,
  lib,
  ...
}: let
  cfg = config.user.ui.tomoe;
  bar = cfg.bar;
  inherit (config.lib.generators) toLua;
  # nur's bar-overlay defaults. User-facing overrides ride the open() call
  # serialized into init.lua (config.nix); these are the fallbacks the
  # overlay module itself reads. The SNI tray service exists since the
  # fusion (shell.services.tray, tomoe FUSION.md F3); this overlay doesn't
  # render a tray widget yet.
  barOverlayDefaults = {
    inherit (bar) modules;
    edges = ["top" "bottom"];
    indent = 0;
    font_family = "monospace";
    name_prefix = "bar-overlay";
    top_name = "bar-overlay-top";
    bottom_name = "bar-overlay-bottom";
    height = 24;
    spacing = 8;
    margin_top = 0;
    margin_bottom = 0;
    refresh_interval = 1000;
    layer = "overlay";
    bg = "transparent";
    font_size = 14;
    anchors = {
      top = "top-center";
      bottom = "bottom-center";
    };
    label = {
      weight = "bold";
      size = 14;
    };
    block = {
      gap = 0;
      border = 0.7;
      padding_y = 2.1;
      padding_x = 4.2;
    };
    time = {
      format = "%H:%M:%S";
      interval = 1000;
    };
    date = {
      format = "%d/%m/%y";
      interval = 30000;
    };
    module_widths = {
      battery = 58;
      time = 74;
      date = 74;
      network = 96;
    };
    battery = {
      gap = 4;
    };
    bongo_cat = {
      inherit (bar.bongo-cat) enable;
      asset_dir = "${./assets/bongo-cat}";
      name = "bongo-cat";
      inherit (bar.bongo-cat) height;
      margin_bottom = bar.bongo-cat.margin-bottom;
      x_offset = bar.bongo-cat.x-offset;
      keypress_duration = bar.bongo-cat.keypress-duration;
      layer = "overlay";
    };
  };
in {
  options.user.ui.tomoe.bar = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the widget-bar overlay in tomoe's Lua VM (folded in from the retired standalone moonshell client).";
    };

    modules = lib.mkOption {
      # shell.services.tray exists since the fusion (F3); a tray
      # widget for this overlay is still to be written. sysinfo is a
      # placeholder facade upstream (nothing pushes it), so no module.
      type = lib.types.listOf (lib.types.enum ["time" "date" "battery" "network"]);
      default = ["time" "date"];
      description = "Bar overlay modules to render.";
    };

    edges = lib.mkOption {
      type = lib.types.listOf (lib.types.enum ["top" "bottom"]);
      default = ["top" "bottom"];
      description = "Screen edges that get a module bar. Single edge = no duplicated widgets.";
    };

    indent = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 0;
      description = "Exclusive bars: lift the widget row this many px off the screen edge. Baked into the bar thickness so the exclusive zone covers it — windows never overlap the gap.";
    };

    exclusive = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the bar overlay reserves layer-shell exclusive space. Keep false for a pure overlay.";
    };

    font-family = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Font family for bar overlay labels. null = resolve system monospace via fc-match.";
    };

    bongo-cat = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Render bongo cat in bottom-center overlay and react to keyboard activity (in-VM shell.services.keyboard feed since the fusion).";
      };
      height = lib.mkOption {
        type = lib.types.ints.between 10 200;
        default = 80;
        description = "Bongo cat image height in physical pixels.";
      };
      margin-bottom = lib.mkOption {
        type = lib.types.int;
        default = 6;
        description = "Bottom margin. Smaller than the bar height so the paws overlap the widget row — the cat taps the widgets.";
      };
      x-offset = lib.mkOption {
        type = lib.types.int;
        default = -24;
        description = "Horizontal offset from center, so each paw lands over one of the two bottom widget blocks.";
      };
      keypress-duration = lib.mkOption {
        type = lib.types.ints.between 10 5000;
        default = 100;
        description = "Milliseconds each paw stays down after a key press.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && bar.enable) {
    manzil.users."${config.user.name}".files = {
      # Live Wallust -> theme bridge, read by the bar overlay and the
      # notification popup styling in init.lua.
      ".config/tomoe/shell/wallust.lua".text =
        builtins.replaceStrings ["@USER@"] [config.user.name]
        (builtins.readFile ./lua/wallust.lua);

      ".config/tomoe/shell/bar_overlay.lua".text =
        builtins.replaceStrings ["@DEFAULTS@"] [(toLua barOverlayDefaults)]
        (builtins.readFile ./lua/bar_overlay.lua);
    };
  };
}
