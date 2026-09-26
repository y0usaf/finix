{lib, ...}: {
  options.user.ui.tomoe.bar = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Draw the widget bar as tomoe shell surfaces.";
    };

    modules = lib.mkOption {
      type = lib.types.listOf (lib.types.enum ["time" "date" "battery" "network" "cpu" "memory" "gpu"]);
      default = ["time" "date"];
      description = "Bar overlay modules to render.";
    };

    center-between = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = ["time" "date"];
      example = ["cpu" "memory"];
      description = ''
        Two adjacent module names whose shared boundary is pinned to screen center. The bar spans the output as two equal halves that meet at that seam, so the clock stays put while stats grow outward. null, or a pair that is not adjacent in `modules`, falls back to centering the whole row as one block.
      '';
    };

    sysinfo = {
      cpu-interval = lib.mkOption {
        type = lib.types.ints.between 100 60000;
        default = 1000;
        description = "Milliseconds between /proc/stat samples. CPU percent is a delta between two samples, so the first tick after start always reads 0.";
      };

      memory-interval = lib.mkOption {
        type = lib.types.ints.between 100 60000;
        default = 2000;
        description = "Milliseconds between /proc/meminfo samples.";
      };

      gpu-interval = lib.mkOption {
        type = lib.types.ints.between 250 60000;
        default = 2000;
        description = "Milliseconds between GPU samples. On NVIDIA each sample is one async nvidia-smi run (~30ms off-thread), so keep this above ~1000.";
      };

      gpu-backend = lib.mkOption {
        type = lib.types.enum ["auto" "nvidia" "amd" "none"];
        default = "auto";
        description = ''
          Which GPU counter source to probe. auto prefers NVIDIA (detected by /proc/driver/nvidia/version) and falls back to the amdgpu sysfs busy counter, because on a hybrid box the AMD iGPU reads ~0% while the discrete card does the work. No source found = the gpu module renders an empty slot.
        '';
      };

      gpu-card = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "card1";
        description = "DRM card hint for the amdgpu sysfs backend (/sys/class/drm/<card>/device/gpu_busy_percent). null = first card exposing the counter.";
      };

      memory-style = lib.mkOption {
        type = lib.types.enum ["percent" "absolute"];
        default = "percent";
        description = "RAM readout: percent of MemTotal, or absolute gigabytes used.";
      };

      show-cpu-temp = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Append CPU die temperature (k10temp Tctl / coretemp Package id 0) to the cpu module.";
      };

      show-gpu-temp = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Append GPU temperature to the gpu module.";
      };

      show-gpu-vram = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Append VRAM used (gigabytes) to the gpu module.";
      };
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

    font-family = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Font family for bar labels. null = the fontconfig monospace alias.";
    };

    bongo-cat = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Render bongo cat in a bottom-center overlay that taps along with keyboard activity.";
      };
      height = lib.mkOption {
        type = lib.types.ints.between 10 200;
        default = 80;
        description = "Bongo cat image height in logical pixels.";
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
}
