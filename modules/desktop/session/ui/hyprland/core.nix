{
  config,
  lib,
  ...
}: let
  inherit (config.user) appearance;
  inherit (appearance) cursorColor cursorTheme;

  cursorSize = toString appearance.cursorSize;
  colorCap = (lib.toUpper (builtins.substring 0 1 cursorColor)) + (builtins.substring 1 (-1) cursorColor);

  activeColour = "ffffffff";
  inactiveColour = "333333ff";

  hyprcursorTheme =
    if cursorTheme == "popucom"
    then "Popucom-${colorCap}-hypr"
    else if cursorTheme == "deepin"
    then "DeepinDarkV20-hypr"
    else "Earendil-Dark-hypr";

  xcursorTheme =
    if cursorTheme == "popucom"
    then "Popucom-${colorCap}-x11"
    else if cursorTheme == "deepin"
    then "DeepinDarkV20-x11"
    else "Earendil-Dark-x11";

  envLines =
    [
      "env = HYPRCURSOR_THEME,${hyprcursorTheme}"
      "env = HYPRCURSOR_SIZE,${cursorSize}"
      "env = XCURSOR_THEME,${xcursorTheme}"
      "env = XCURSOR_SIZE,${cursorSize}"
    ]
    ++ lib.optionals config.hardware.nvidia.enable [
      "env = LIBVA_DRIVER_NAME,nvidia"
      "env = GBM_BACKEND,nvidia-drm"
      "env = __GLX_VENDOR_LIBRARY_NAME,nvidia"
    ];
in {
  config =
    lib.mkIf config.user.ui.hyprland.enable {
      manzil.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
        text =
          lib.mkAfter ''
            bezier = in_out,0.65,0.01,0,0.95
            bezier = woa,0,0,0,1

            general {
              gaps_in = 10
              gaps_out = 5
              border_size = 1
              col.active_border = rgba(${activeColour})
              col.inactive_border = rgba(${inactiveColour})
              col.nogroup_border = rgba(${inactiveColour})
              col.nogroup_border_active = rgba(${activeColour})
              layout = scrolling
            }

            input {
              kb_layout = us
              follow_mouse = 1
              sensitivity = -1.0
              force_no_accel = true
              mouse_refocus = false
            }

            decoration {
              rounding = 0
              blur {
                enabled = true
                size = 10
                passes = 3
                ignore_opacity = true
                popups = true
              }
            }

            render {
              cm_enabled = 0
            }

            animations {
              enabled = ${
              if appearance.animations.enable
              then "1"
              else "0"
            }
              animation = windows,1,2,woa,popin
              animation = border,1,10,default
              animation = fade,1,10,default
              animation = workspaces,1,5,in_out,slide
            }

            misc {
              disable_hyprland_logo = true
              disable_splash_rendering = true
            }

            debug {
              disable_logs = false
            }

            ${lib.concatStringsSep "
" envLines}

            binds {
              movefocus_cycles_groupfirst = true
            }

            scrolling {
              column_width = 0.5
              explicit_column_widths = 0.33333,0.5,0.66667
            }

            group {
              auto_group = true
              group_on_movetoworkspace = true
              col.border_active = rgba(${activeColour})
              col.border_inactive = rgba(${inactiveColour})
              col.border_locked_active = rgba(${activeColour})
              col.border_locked_inactive = rgba(${inactiveColour})

              groupbar {
                enabled = true
                gradients = false
                render_titles = false
                height = 8
                indicator_height = 2
                rounding = 0
                gradient_rounding = 0
                gaps_out = 0
                keep_upper_gap = false
                col.active = rgba(${activeColour})
                col.inactive = rgba(${inactiveColour})
                col.locked_active = rgba(${activeColour})
                col.locked_inactive = rgba(${inactiveColour})
              }
            }
          '';
      };
    };
}
