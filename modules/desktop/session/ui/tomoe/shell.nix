{
  config,
  lib,
  ...
}: let
  cfg = config.user.ui.tomoe;
  inherit (cfg) bar;
  inherit (config.lib.generators) toLua;
  # nur's bar-overlay defaults. User-facing overrides ride the open() call
  # serialized into init.lua (config.nix); these are the fallbacks the
  # overlay module itself reads. The SNI tray service exists since the
  # fusion (shell.services.tray, tomoe FUSION.md F3); this overlay doesn't
  # render a tray widget yet.
in {
  options.user.ui.tomoe.bar = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the widget-bar overlay in tomoe's Lua VM (folded in from the retired standalone moonshell client).";
    };

    modules = lib.mkOption {
      # shell.services.tray exists since the fusion (F3); a tray
      # widget for this overlay is still to be written. cpu/memory/gpu
      # ride the sysinfo facade, which upstream declares but never
      # pushes — lua/sysinfo.lua supplies the push side in-VM.
      type = lib.types.listOf (lib.types.enum ["time" "date" "battery" "network" "cpu" "memory" "gpu"]);
      default = ["time" "date"];
      description = "Bar overlay modules to render.";
    };

    center-between = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = ["time" "date"];
      example = ["cpu" "memory"];
      description = ''
        Two adjacent module names whose shared boundary is pinned to screen center. The bar surface is padded to twice its wider half, so the seam sits at the surface midpoint and layer-shell's centering puts that midpoint on the output's center — the clock stays put while stats grow outward. null, or a pair that is not adjacent in `modules`, falls back to centering the whole row as one block.
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

      # CPU/memory/GPU sampler: pushes snapshots into the sysinfo service
      # facade the bar overlay reads. Deployed unconditionally; it only
      # registers timers when a cpu/memory/gpu module is on the bar.
      ".config/tomoe/shell/sysinfo.lua".text = builtins.readFile ./lua/sysinfo.lua;

      ".config/tomoe/shell/bar_overlay.lua".text =
        builtins.replaceStrings ["@DEFAULTS@"] [
          (toLua {
            inherit (bar) modules;
            center_between = bar.center-between;
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
              cpu = 104;
              memory = 84;
              gpu = 150;
            };
            battery = {
              gap = 4;
            };
            sysinfo = {
              cpu_interval = bar.sysinfo.cpu-interval;
              memory_interval = bar.sysinfo.memory-interval;
              gpu_interval = bar.sysinfo.gpu-interval;
              gpu_prefer = bar.sysinfo.gpu-backend;
              gpu_card = bar.sysinfo.gpu-card;
              memory_style = bar.sysinfo.memory-style;
              show_cpu_temp = bar.sysinfo.show-cpu-temp;
              show_gpu_temp = bar.sysinfo.show-gpu-temp;
              show_gpu_vram = bar.sysinfo.show-gpu-vram;
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
          })
        ]
        (builtins.readFile ./lua/bar_overlay.lua);
    };
  };
}
