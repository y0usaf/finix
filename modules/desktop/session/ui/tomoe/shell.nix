{lib, ...}: {
  options.user.ui.tomoe.bar = {
    modules = lib.mkOption {
      type = lib.types.listOf (lib.types.enum ["time" "date" "battery" "network" "cpu" "memory" "gpu"]);
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
      description = "Whether the bar reserves exclusive space that windows tile around. Keep false for a pure overlay.";
    };
  };
}
