###############################################################################
# Hyprland Window Manager Module
# Configures the Hyprland Wayland compositor with:
# - Core settings and plugins (hy3)
# - Customizable keybindings and window rules
# - NVIDIA compatibility options
# - XDG portal integration
###############################################################################
{
  config,
  pkgs,
  lib,
  inputs,
  profile,
  ...
}: let
  cfg = config.modules.ui.hyprland;
in {
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];

  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.ui.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";
    flake = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to use Hyprland from flake inputs instead of nixpkgs";
      };
    };
    hy3 = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable the hy3 tiling layout plugin";
      };
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = [
      pkgs.hyprwayland-scanner # Tool associated with Hyprland
    ];

    ###########################################################################
    # XDG Portal Configuration
    ###########################################################################
    xdg.portal = {
      xdgOpenUsePortal = true;
      configPackages = [
        (
          if cfg.flake.enable
          then inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
          else pkgs.xdg-desktop-portal-hyprland
        )
      ];
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = "*";
    };

    ###########################################################################
    # Environment Variables
    ###########################################################################
    home.sessionVariables = {
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };

    ###########################################################################
    # Hyprland Configuration
    ###########################################################################
    wayland.windowManager.hyprland = {
      # Core Activation and System Settings
      enable = true;
      xwayland.enable = true;
      systemd = {
        enable = true;
        variables = ["--all"];
      };

      # Add AGS autostart if the feature is enabled
      extraConfig = ''
        exec-once = ags
      '';

      # Package Definitions
      package =
        if cfg.flake.enable
        then inputs.hyprland.packages.${pkgs.system}.hyprland
        else pkgs.hyprland;
      portalPackage =
        if cfg.flake.enable
        then inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
        else pkgs.xdg-desktop-portal-hyprland;
      plugins = lib.mkIf cfg.hy3.enable [
        # Always use hy3 from flake inputs since it's not available in nixpkgs
        inputs.hy3.packages.${pkgs.system}.hy3
      ];

      # Settings Configuration
      settings = {
        # Monitor & Display Settings
        monitor = [
          "DP-4,highres@highrr,0x0,1"
          "DP-3,highres@highrr,0x0,1"
          "DP-2,5120x1440@239.76,0x0,1"
        ];

        # General User Interface Settings
        general = {
          gaps_in = 10;
          gaps_out = 5;
          border_size = 1;
          "col.active_border" = "rgba($active_colour)";
          "col.inactive_border" = "rgba($inactive_colour)";
          layout =
            if cfg.hy3.enable
            then "hy3"
            else "dwindle";
        };

        # Input Settings (keyboard & mouse)
        input = {
          kb_layout = "us";
          follow_mouse = 1;
          sensitivity = -1.0;
          force_no_accel = true;
          mouse_refocus = false;
        };

        # Theme & Colors
        "$active_colour" = "ffffffff";
        "$transparent" = "ffffff00";
        "$inactive_colour" = "333333ff";

        # Window Decoration & Effects
        decoration = {
          rounding = 0;
          blur = {
            enabled = true;
            size = 3;
            passes = 3;
            ignore_opacity = true;
            popups = true;
          };
        };

        # Animation Settings
        animations = {
          enabled = 0;
          bezier = [
            "in-out,.65,-0.01,0,.95"
            "woa,0,0,0,1"
          ];
          animation = [
            "windows,1,2,woa,popin"
            "border,1,10,default"
            "fade,1,10,default"
            "workspaces,1,5,in-out,slide"
          ];
        };

        # Application Shortcut Variables
        "$mod" = "SUPER";
        "$mod2" = "ALT";
        "$term" = profile.modules.defaults.terminal.command;
        "$filemanager" = profile.modules.defaults.fileManager.command;
        "$browser" = profile.modules.defaults.browser.command;
        "$discord" = profile.modules.defaults.discord.command;
        "$launcher" = profile.modules.defaults.launcher.command;
        "$ide" = profile.modules.defaults.ide.command;
        "$obs" = "obs";

        # Window Management Rules
        windowrulev2 = [
          "float, center, size 300 600, class:^(launcher)"
          "float, mouse, size 300 300, title:^(Smile)"
          "float, center, class:^(hyprland-share-picker)"
          "float, class:^(ags)$ title:^(system-stats)$"
          "center, class:^(ags)$ title:^(system-stats)$"
        ];

        layerrule = [
          "blur, notifications"
          "blur, fabric"
        ];

        # Keybindings Configuration
        bind = lib.lists.flatten [
          # -- Essential Controls --
          [
            "$mod, Q, killactive"
            "$mod, M, exit"
            "$mod, F, fullscreen"
            "$mod2, TAB, layoutmsg, swapnext"
            "$mod, TAB, layoutmsg, orientationnext"
            "$mod, space, togglefloating"
            "$mod, P, pseudo"
            "$mod, W, exec, ags -r 'showStats()'"
          ]

          # -- Primary Applications --
          [
            "$mod, D, exec, $term"
            "$mod, E, exec, $filemanager"
            "$mod, R, exec, $launcher"
            "$mod, O, exec, $notepad"
            "$mod2, 1, exec, $ide"
            "$mod2, 2, exec, $browser"
            "$mod2, 3, exec, $discord"
            "$mod2, 4, exec, steam"
            "$mod2, 5, exec, $obs"
          ]

          # -- Monitor Management --
          [
            "$mod SHIFT, S, swapactiveworkspaces, DP-4 HDMI-A-2"
            "$mod, S, movecurrentworkspacetomonitor, +1"
          ]

          # -- Window Movement (WASD keys) --
          (lib.lists.forEach ["w" "a" "s" "d"] (key: let
            direction =
              {
                "w" = "u";
                "a" = "l";
                "s" = "d";
                "d" = "r";
              }
              .${key};
          in [
            "$mod2, ${key}, movefocus, ${direction}"
            "$mod2 SHIFT, ${key}, movewindow, ${direction}"
          ]))

          # -- Workspace Management (1-9) --
          (lib.lists.forEach (lib.range 1 9) (i: let
            num = toString i;
          in [
            "$mod, ${num}, workspace, ${num}"
            "$mod SHIFT, ${num}, movetoworkspacesilent, ${num}"
          ]))

          # -- System Controls --
          [
            "Ctrl$mod2,Delete, exec, gnome-system-monitor"
            "$mod Shift, M, exec, shutdown now"
            "Ctrl$mod2Shift, M, exec, reboot"
            "Ctrl,Period,exec,smile"
          ]

          # -- Utility Commands --
          [
            "$mod, G, exec, grim -g \"$(slurp -d)\" - | wl-copy -t image/png"
            "$mod SHIFT, G, exec, grim - | wl-copy -t image/png"
            "$mod, GRAVE, exec, hyprpicker | wl-copy"
          ]

          # -- Special Commands --
          [
            "$mod SHIFT, C, exec, hyprctl hyprpaper wallpaper DP-4,\"${profile.modules.directories.wallpapers.static.path}\""
          ]
        ];

        # Additional Mouse Bindings
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        # Single-Line Binding for Toggling Stats
        bindr = "$mod, W, exec, ags -r 'hideStats()'";

        # System & Debug Settings
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };

        debug.disable_logs = false;

        # Add NVIDIA-specific environment settings
        env = lib.mkIf (profile.modules.core.nvidia.enable) [
          "LIBVA_DRIVER_NAME,nvidia"
          "GBM_BACKEND,nvidia-drm"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        ];
      };
    };

    ###########################################################################
    # Shell Environment Configuration
    ###########################################################################
    programs.zsh = {
      envExtra = lib.mkIf (profile.modules.core.nvidia.enable) ''
        # Hyprland NVIDIA environment variables
        export LIBVA_DRIVER_NAME=nvidia
        export XDG_SESSION_TYPE=wayland
        export GBM_BACKEND=nvidia-drm
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export WLR_NO_HARDWARE_CURSORS=1
        export XCURSOR_SIZE=${toString profile.modules.appearance.cursorSize}
        export NIXOS_OZONE_WL=1
      '';
    };
  };
}
