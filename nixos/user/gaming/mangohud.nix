{
  config,
  lib,
  ...
}: let
  cfg = config.user.gaming.mangohud;
in {
  options.user.gaming.mangohud = {
    enable = lib.mkEnableOption "MangoHud user configuration";
    enableSessionWide = lib.mkEnableOption "MangoHud for all Vulkan apps";
    refreshRate = lib.mkOption {
      type = lib.types.int;
      default = 170;
      description = "Target refresh rate for FPS limiting";
    };
  };

  config = lib.mkIf cfg.enable {
    usr = {
      xdg.config.files."MangoHud/MangoHud.conf".text = ''
        blacklist=mpv
        font_size=20
        text_outline_thickness=1
        cellpadding_y=-0.2
        fps_limit=${toString cfg.refreshRate},0
        vsync=1
        gl_vsync=0
        preset=0,1,2
        toggle_hud=Shift_R+F12
        toggle_hud_position=Shift_R+F11
        toggle_preset=Shift_R+F10
      '';

      xdg.config.files."MangoHud/presets.conf".text = ''
        [preset 0]
        fps_only
        background_alpha=0
        hud_no_margin

        [preset 1]
        background_alpha=0.33
        hud_no_margin
        gpu_text=GPU
        gpu_stats
        gpu_core_clock
        gpu_mem_clock
        gpu_temp
        gpu_power
        vram
        fps
        frame_timing
        cpu_text=CPU
        cpu_stats
        cpu_mhz
        cpu_temp
        cpu_power
        ram

        [preset 2]
        background_alpha=0.33
        hud_no_margin
        gpu_text=GPU
        gpu_stats
        gpu_core_clock
        gpu_mem_clock
        gpu_temp
        gpu_power
        vram
        fps
        frame_timing
        cpu_text=CPU
        cpu_stats
        core_load
        cpu_temp
        cpu_power
        ram
        winesync
      '';
    };
  };
}
