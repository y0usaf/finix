{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.ui.nur;
  bar = cfg.bar-overlay;
  inherit (lib.types) bool;
in {
  options.user.ui.nur = {
    enable = lib.mkOption {
      type = bool;
      default = false;
      description = "Enable Nur GPU-accelerated Lua-scriptable Wayland shell";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = flakeInputs.nur.packages."${pkgs.stdenv.hostPlatform.system}".nur;
      defaultText = lib.literalExpression ''flakeInputs.nur.packages."${pkgs.stdenv.hostPlatform.system}".nur'';
      description = "Nur package to install and run.";
    };

    config = lib.mkOption {
      type = lib.types.lines;
      default = ''
        -- Resolve the system monospace font so GPUI gets the real family name.
        local _nur_font = @FONT_FAMILY@
        if _nur_font == "" then _nur_font = "monospace" end

        local ok, BarOverlay = pcall(require, "nur.widgets.bar_overlay")
        if not ok then
            BarOverlay = dofile(os.getenv("HOME") .. "/.config/nur/bar_overlay.lua")
        end

        BarOverlay.open({
            modules = @MODULES@,
            exclusive = @EXCLUSIVE@,
            font_family = _nur_font,
            -- Keep tray width stable. Reopening all layer-shell popup surfaces when
            -- tray icons settle can trip Blade/Vulkan on Wayland.
            tray_width = 160,
            relayout_interval = false,
        })
      '';
      description = "Lua config written to ~/.config/nur/init.lua.";
    };

    bar-overlay = {
      enable = lib.mkOption {
        type = bool;
        default = true;
        description = "Generate a local fallback Nur bar overlay module.";
      };

      modules = lib.mkOption {
        type = lib.types.listOf (lib.types.enum ["time" "date" "tray" "battery"]);
        default = ["time" "date" "tray"];
        description = "Bar overlay modules to render.";
      };

      exclusive = lib.mkOption {
        type = bool;
        default = false;
        description = "Whether the bar overlay reserves layer-shell exclusive space. Keep false for a pure overlay.";
      };

      font-family = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Font family for bar overlay labels. null = resolve system monospace via fc-match.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    manzil.users."${config.user.name}".files =
      {
        ".config/nur/init.lua".text =
          builtins.replaceStrings
          ["@MODULES@" "@EXCLUSIVE@" "@FONT_FAMILY@"]
          [
            ((values: "{ " + lib.concatMapStringsSep ", " builtins.toJSON values + " }") bar.modules)
            ((value:
              if value
              then "true"
              else "false")
            bar.exclusive)
            (
              if bar.font-family != null
              then builtins.toJSON bar.font-family
              else ''shell.exec("fc-match monospace --format='%{family}'")''
            )
          ]
          cfg.config;
      }
      // lib.optionalAttrs bar.enable {
        ".config/nur/bar_overlay.lua".text = ''
          -- ~/.config/nur/bar_overlay.lua
          -- Local bar overlay config.
          --
          -- Uses one compositor-centered layer-shell surface per edge. Module blocks
          -- render inside that fixed-width centered surface, so positioning is delegated
          -- to the compositor instead of computed from an assumed display width.

          local Wallust = require("nur.wallust")
          local SystemTray = require("nur.widgets.system_tray")
          local theme = require("nur.theme")

          local M = _G.__nur_widgets_bar_overlay or {}
          _G.__nur_widgets_bar_overlay = M
          M._layout_generation = M._layout_generation or 0
          M._font_family = M._font_family or "monospace"

          local DEFAULT_MODULES = { "time", "date", "tray" }

          local function contains(list, value)
              for _, item in ipairs(list or {}) do
                  if item == value then return true end
              end
              return false
          end

          local function label(text)
              Wallust.version:get()
              return ui.text({
                  content = tostring(text or ""),
                  color = Wallust.color("fg", theme.text),
                  weight = "bold",
                  size = 14,
                  font_family = M._font_family,
              })
          end

          local function block(children, opts)
              opts = opts or {}
              Wallust.version:get()

              return ui.hbox({
                  width = opts.width,
                  height = opts.height,
                  gap = opts.gap or 0,
                  bg = Wallust.color("bg", theme.base),
                  border = opts.border or 0.7,
                  border_color = Wallust.color("accent", theme.accent),
                  padding_top = opts.padding_top or opts.padding_y or 2.1, -- 0.15em
                  padding_bottom = opts.padding_bottom or opts.padding_y or 2.1,
                  padding_left = opts.padding_left or opts.padding_x or 4.2, -- 0.3em
                  padding_right = opts.padding_right or opts.padding_x or 4.2,
                  children = children or {},
              })
          end

          local function clock_state(format, interval_ms)
              local state = shell.state(os.date(format))
              shell.interval(interval_ms, function()
                  state:set(os.date(format))
              end)
              return state
          end

          local function close_existing(name)
              local old = shell.get_window(name)
              if old then old:close() end
          end



          local function tray_item_count()
              local tray = shell.services.systemtray:get()
              local seen = {}
              local count = 0
              for _, item in ipairs(tray.items or {}) do
                  local key = ((item.icon_name or "") .. "|" .. (item.title or ""))
                  if key == "|" then key = item.id end
                  if not seen[key] then
                      seen[key] = true
                      count = count + 1
                  end
              end
              return count
          end

          function M.new(opts)
              opts = opts or {}

              local self = {
                  modules = opts.modules or DEFAULT_MODULES,
                  time = opts.time_state or clock_state(opts.time_format or "%H:%M:%S", opts.time_interval or 1000),
                  date = opts.date_state or clock_state(opts.date_format or "%d/%m/%y", opts.date_interval or 30000),
                  tray = opts.tray or SystemTray.new({
                      icon_size = opts.tray_icon_size or 16,
                      item_padding = opts.tray_item_padding or 2.1,
                      gap = opts.tray_gap or 2,
                      hover_bg = opts.tray_hover_bg,
                      show_passive = opts.show_passive_tray_items ~= false,
                  }),
              }

              function self:battery_block(width, height)
                  local battery = shell.services.battery:get()
                  local percent = battery.percent or 0
                  local arrow = battery.charging and "↑" or "↓"

                  return block({
                      label(percent .. "%"),
                      label(arrow),
                  }, { width = width, height = height, gap = 4 })
              end

              function self:time_block(width, height)
                  return block({ label(self.time:get()) }, { width = width, height = height })
              end

              function self:date_block(width, height)
                  return block({ label(self.date:get()) }, { width = width, height = height })
              end

              function self:tray_block(width, height)
                  Wallust.version:get()
                  return block({ self.tray:render() }, {
                      width = width,
                      height = height,
                      gap = 2,
                      padding_x = 2.1,
                      padding_y = 2.1,
                  })
              end

              function self:render_module(name, width, height)
                  if name == "battery" then return self:battery_block(width, height) end
                  if name == "time" then return self:time_block(width, height) end
                  if name == "date" then return self:date_block(width, height) end
                  if name == "tray" then return self:tray_block(width, height) end
                  return ui.hbox({ width = width, height = height, children = {} })
              end

              return self
          end

          local function module_widths(opts)
              opts = opts or {}
              local count = tray_item_count()
              local dynamic_tray_width = count * 22 + math.max(0, count - 1) * 2 + 6
              return {
                  battery = opts.battery_width or 58,
                  time = opts.time_width or 74,
                  date = opts.date_width or 74,
                  tray = opts.tray_width or math.max(opts.min_tray_width or 160, dynamic_tray_width),
              }
          end

          local function render_edge(content, items, total_width, height, spacing)
              local children = {}
              for _, item in ipairs(items) do
                  children[#children + 1] = content:render_module(item.name, item.width, height)
              end

              return ui.hbox({
                  width = total_width,
                  height = height,
                  gap = spacing or 0,
                  children = children,
              })
          end

          local function open_edge(edge, content, items, total_width, opts)
              local height = opts.height or 24
              local fg = Wallust.hex(Wallust.color("fg", theme.text))
              local name = opts.name or ((opts.name_prefix or "bar-overlay") .. "-" .. edge)

              -- Close windows created by older per-module versions of this widget.
              for _, item in ipairs(items) do
                  close_existing((opts.name_prefix or "bar-overlay") .. "-" .. edge .. "-" .. item.name)
              end
              close_existing(name)

              local win = shell.window({
                  name = name,
                  anchor = edge == "top" and "top-center" or "bottom-center",
                  popup_width = total_width,
                  height = height,
                  margin_top = edge == "top" and (opts.margin_top or 0) or 0,
                  margin_bottom = edge == "bottom" and (opts.margin_bottom or 0) or 0,
                  layer = "overlay",
                  exclusive = opts.exclusive == true,
                  bg = "transparent",
                  fg = fg,
                  font_size = 14,
                  font_family = M._font_family,
              })

              local render_fn = function()
                  return render_edge(content, items, total_width, height, opts.spacing or 8)
              end
              win:render(render_fn)

              -- Until the runtime has fine-grained Lua dependency tracking, refresh
              -- these tiny module windows directly so clock/date/tray repaint exactly
              -- when their backing state changes.
              shell.interval(opts.refresh_interval or 1000, function()
                  if opts.layout_generation and opts.layout_generation ~= M._layout_generation then return end
                  win:render(render_fn)
              end)

              for _, item in ipairs(items) do
                  item.window = win
              end
              return win
          end

          function M.open(opts)
              opts = opts or {}
              if opts.font_family then M._font_family = opts.font_family end
              M._layout_generation = M._layout_generation + 1
              local layout_generation = M._layout_generation
              Wallust.watch(opts.wallust_path)

              -- Close the older single-surface names too, in case the previous version
              -- of this module is still running before restart/reload.
              close_existing(opts.top_name or "bar-overlay-top")
              close_existing(opts.bottom_name or "bar-overlay-bottom")

              local modules = opts.modules or DEFAULT_MODULES
              local widths = module_widths(opts)
              local height = opts.height or 24
              local spacing = opts.spacing or 8

              local items = {}
              for _, name in ipairs(modules) do
                  if widths[name] then
                      items[#items + 1] = { name = name, width = widths[name] }
                  end
              end

              local total = 0
              for i, item in ipairs(items) do
                  total = total + item.width
                  if i > 1 then total = total + spacing end
              end

              local time = clock_state(opts.time_format or "%H:%M:%S", opts.time_interval or 1000)
              local date = clock_state(opts.date_format or "%d/%m/%y", opts.date_interval or 30000)
              local tray = SystemTray.new({
                  icon_size = opts.tray_icon_size or 16,
                  item_padding = opts.tray_item_padding or 2.1,
                  gap = opts.tray_gap or 2,
                  hover_bg = opts.tray_hover_bg,
                  show_passive = opts.show_passive_tray_items ~= false,
              })

              local top_content = M.new({
                  modules = modules,
                  time_state = time,
                  date_state = date,
                  tray = tray,
              })
              local bottom_content = M.new({
                  modules = modules,
                  time_state = time,
                  date_state = date,
                  tray = tray,
              })

              local top_window = open_edge("top", top_content, items, total, {
                  name = opts.top_name or "bar-overlay-top",
                  height = height,
                  spacing = spacing,
                  name_prefix = opts.name_prefix,
                  margin_top = opts.margin_top,
                  exclusive = opts.exclusive,
                  refresh_interval = opts.refresh_interval,
                  layout_generation = layout_generation,
              })
              local bottom_window = open_edge("bottom", bottom_content, items, total, {
                  name = opts.bottom_name or "bar-overlay-bottom",
                  height = height,
                  spacing = spacing,
                  name_prefix = opts.name_prefix,
                  margin_bottom = opts.margin_bottom,
                  exclusive = opts.exclusive,
                  refresh_interval = opts.refresh_interval,
                  layout_generation = layout_generation,
              })

              -- Reopening all popup surfaces while tray icons are still settling can
              -- trip Blade/Vulkan on Wayland. Keep this opt-in; a stable tray_width is
              -- safer for the normal bar.
              if contains(modules, "tray") and opts.relayout_interval ~= false then
                  local last_width = module_widths(opts).tray
                  shell.interval(opts.relayout_interval or 1000, function()
                      if layout_generation ~= M._layout_generation then return end

                      local width = module_widths(opts).tray
                      if width ~= last_width then
                          local again = {}
                          for k, v in pairs(opts) do again[k] = v end
                          M.open(again)
                      end
                  end)
              end

              return {
                  top_content = top_content,
                  bottom_content = bottom_content,
                  top_window = top_window,
                  bottom_window = bottom_window,
                  items = items,
              }
          end

          return M
        '';
      };
  };
}
