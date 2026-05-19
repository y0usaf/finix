{
  config,
  lib,
  pkgs,
  ...
}: let
  userUi = config.user.ui;
  inherit (config.user) appearance;
  inherit (appearance) hyprcursorSize xcursorSize;
  cursorPackage = userUi.cursor.package;
  hyprcursorThemeName = cursorPackage.hyprcursorThemeName or null;

  activeColour = "ffffffff";
  inactiveColour = "333333ff";
in {
  config = lib.mkIf userUi.hyprland.enable {
    manzil.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
      text = lib.mkAfter ''
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

        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "env = ${name},${value}") (cursorPackage.mkCursorSessionVariables {
            inherit xcursorSize hyprcursorSize;
          })
          ++ lib.optionals config.hardware.nvidia.enable [
            "env = LIBVA_DRIVER_NAME,nvidia"
            "env = GBM_BACKEND,nvidia-drm"
            "env = __GLX_VENDOR_LIBRARY_NAME,nvidia"
          ])}
        ${lib.optionalString (hyprcursorThemeName != null) "exec-once = ${pkgs.lua5_4}/bin/lua ${pkgs.writeText "hypr-adaptive-hyprcursor.lua" ''
          local config = ${lib.generators.toLua {} {
            theme = hyprcursorThemeName;
            baseDpi = appearance.dpi;
            baseSize = hyprcursorSize;
            minSize = 16;
            maxSize = 128;
            settleSeconds = 0.2;
            modelDpi = {
              LS49AG95 = 109;
            };
            commands = {
              hyprctl = "${pkgs.hyprland}/bin/hyprctl";
              jq = "${pkgs.jq}/bin/jq";
              sleep = "${pkgs.coreutils}/bin/sleep";
              socat = "${pkgs.socat}/bin/socat";
            };
          }}
          local commands = config.commands or {}
          local model_dpi = config.modelDpi or {}
          local last_size = nil

          local function log(message)
              io.stderr:write("hypr-adaptive-hyprcursor: " .. tostring(message) .. "\n")
          end

          local function trim(value)
              return (tostring(value):gsub("^%s+", ""):gsub("%s+$", ""))
          end

          local function sh_quote(value)
              return "'" .. tostring(value):gsub("'", [['"'"']]) .. "'"
          end

          local function run(...)
              local parts = {}
              for _, arg in ipairs({ ... }) do
                  parts[#parts + 1] = sh_quote(arg)
              end

              local ok, _, code = os.execute(table.concat(parts, " "))
              if ok == true or ok == 0 then return 0 end
              return tonumber(code) or 1
          end

          local function read_lines(command)
              local handle = io.popen(command)
              if not handle then return {} end

              local lines = {}
              for line in handle:lines() do
                  line = trim(line)
                  if line ~= "" and line ~= "null" then
                      lines[#lines + 1] = line
                  end
              end
              handle:close()
              return lines
          end

          local function split_tsv(line)
              local fields = {}
              for field in (line .. "\t"):gmatch("(.-)\t") do
                  fields[#fields + 1] = field
              end
              return fields
          end

          local function clamp(value, min_value, max_value)
              if min_value and value < min_value then return min_value end
              if max_value and value > max_value then return max_value end
              return value
          end

          local function round(value)
              return math.floor(value + 0.5)
          end

          local function focused_monitor()
              local jq_filter = [[.[] | select(.focused == true) | [.name, (.model // ""), ((.width // 0) | tostring), ((.height // 0) | tostring), ((.physicalWidth // 0) | tostring), ((.physicalHeight // 0) | tostring)] | @tsv]]
              local query = table.concat({
                  sh_quote(commands.hyprctl or "hyprctl"),
                  "monitors all -j 2>/dev/null |",
                  sh_quote(commands.jq or "jq"),
                  "-r",
                  sh_quote(jq_filter),
                  "2>/dev/null",
              }, " ")

              local lines = read_lines(query)
              local fields = split_tsv(lines[1] or "")
              if not fields[1] then return nil end

              return {
                  name = fields[1],
                  model = fields[2],
                  width = tonumber(fields[3]) or 0,
                  height = tonumber(fields[4]) or 0,
                  physicalWidth = tonumber(fields[5]) or 0,
                  physicalHeight = tonumber(fields[6]) or 0,
              }
          end

          local function monitor_dpi(monitor)
              if not monitor then return config.baseDpi end
              if monitor.model and model_dpi[monitor.model] then
                  return model_dpi[monitor.model]
              end

              if monitor.width > 0 and monitor.height > 0 and monitor.physicalWidth > 0 and monitor.physicalHeight > 0 then
                  local diagonal_px = math.sqrt(monitor.width * monitor.width + monitor.height * monitor.height)
                  local diagonal_in = math.sqrt(monitor.physicalWidth * monitor.physicalWidth + monitor.physicalHeight * monitor.physicalHeight) / 25.4
                  if diagonal_in > 0 then
                      return diagonal_px / diagonal_in
                  end
              end

              return config.baseDpi
          end

          local function cursor_size_for_dpi(dpi)
              local size = round((config.baseSize or 24) * (dpi or config.baseDpi or 96) / (config.baseDpi or 96))
              return clamp(size, config.minSize, config.maxSize)
          end

          local function apply(force)
              local monitor = focused_monitor()
              local dpi = monitor_dpi(monitor)
              local size = cursor_size_for_dpi(dpi)

              if force or size ~= last_size then
                  last_size = size
                  log("setting " .. tostring(config.theme) .. " size " .. tostring(size) .. " for " .. tostring(monitor and monitor.name or "unknown") .. " at " .. tostring(round(dpi)) .. " DPI")
                  run(commands.hyprctl or "hyprctl", "setcursor", config.theme, tostring(size))
              end
          end

          local function socket2_path()
              local runtime = os.getenv("XDG_RUNTIME_DIR")
              local signature = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
              if not runtime or not signature then return nil end
              return runtime .. "/hypr/" .. signature .. "/.socket2.sock"
          end

          local function sleep(seconds)
              run(commands.sleep or "sleep", tostring(seconds))
          end

          local function watch()
              apply(true)

              while true do
                  local socket = socket2_path()
                  if not socket then
                      log("HYPRLAND_INSTANCE_SIGNATURE is unavailable; retrying")
                      sleep(1)
                  else
                      local command = table.concat({
                          sh_quote(commands.socat or "socat"),
                          "-U -",
                          sh_quote("UNIX-CONNECT:" .. socket),
                          "2>/dev/null",
                      }, " ")
                      local handle = io.popen(command)
                      if handle then
                          for event in handle:lines() do
                              if event:match("^focusedmon") or event:match("^monitor") then
                                  sleep(config.settleSeconds or 0.2)
                                  apply(false)
                              end
                          end
                          handle:close()
                      end
                      sleep(1)
                  end
              end
          end

          watch()
        ''}"}

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
