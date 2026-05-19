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
  toLua = lib.generators.toLua {};
  luaInline = lib.generators.mkLuaInline;
  barOverlayDefaults = {
    inherit (bar) modules;
    font_family = "monospace";
    name_prefix = "bar-overlay";
    top_name = "bar-overlay-top";
    bottom_name = "bar-overlay-bottom";
    height = 24;
    spacing = 8;
    margin_top = 0;
    margin_bottom = 0;
    refresh_interval = 1000;
    relayout_interval = 1000;
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
    tray = {
      name = "tray";
      icon_size = 16;
      item_padding = 2.1;
      gap = 2;
      show_passive = true;
      item_width = 22;
      base_width = 6;
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
      tray = 160;
      min_tray = 160;
    };
    battery = {
      gap = 4;
    };
  };
  barOverlayDefaultsLua = toLua barOverlayDefaults;
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
        if _nur_font == "" then _nur_font = @FONT_FAMILY_FALLBACK@ end

        local ok, BarOverlay = pcall(require, "nur.widgets.bar_overlay")
        if not ok then
            BarOverlay = dofile(os.getenv("HOME") .. "/.config/nur/bar_overlay.lua")
        end

        BarOverlay.open(@BAR_OPEN_OPTIONS@)
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
          ["@MODULES@" "@EXCLUSIVE@" "@FONT_FAMILY@" "@FONT_FAMILY_FALLBACK@" "@BAR_OPEN_OPTIONS@" "@BAR_OVERLAY_DEFAULTS@"]
          [
            (toLua bar.modules)
            (toLua bar.exclusive)
            (
              if bar.font-family != null
              then toLua bar.font-family
              else toLua (luaInline ''shell.exec("fc-match monospace --format='%{family}'")'')
            )
            (toLua barOverlayDefaults.font_family)
            (toLua {
              inherit (bar) modules exclusive;
              font_family = luaInline "_nur_font";
              tray_width = barOverlayDefaults.module_widths.tray;
              relayout_interval = false;
            })
            barOverlayDefaultsLua
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

          local DEFAULTS = ${barOverlayDefaultsLua}

          local M = _G.__nur_widgets_bar_overlay or {}
          _G.__nur_widgets_bar_overlay = M
          M._layout_generation = M._layout_generation or 0
          M._font_family = M._font_family or DEFAULTS.font_family

          local DEFAULT_MODULES = DEFAULTS.modules

          local function contains(list, value)
              for _, item in ipairs(list or {}) do
                  if item == value then return true end
              end
              return false
          end

          local function default_bool(value, fallback)
              if value == nil then return fallback end
              return value
          end

          local function label(text)
              Wallust.version:get()
              return ui.text({
                  content = tostring(text or ""),
                  color = Wallust.color("fg", theme.text),
                  weight = DEFAULTS.label.weight,
                  size = DEFAULTS.label.size,
                  font_family = M._font_family,
              })
          end

          local function block(children, opts)
              opts = opts or {}
              Wallust.version:get()

              return ui.hbox({
                  width = opts.width,
                  height = opts.height,
                  gap = opts.gap or DEFAULTS.block.gap,
                  bg = Wallust.color("bg", theme.base),
                  border = opts.border or DEFAULTS.block.border,
                  border_color = Wallust.color("accent", theme.accent),
                  padding_top = opts.padding_top or opts.padding_y or DEFAULTS.block.padding_y, -- 0.15em
                  padding_bottom = opts.padding_bottom or opts.padding_y or DEFAULTS.block.padding_y,
                  padding_left = opts.padding_left or opts.padding_x or DEFAULTS.block.padding_x, -- 0.3em
                  padding_right = opts.padding_right or opts.padding_x or DEFAULTS.block.padding_x,
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
                  time = opts.time_state or clock_state(opts.time_format or DEFAULTS.time.format, opts.time_interval or DEFAULTS.time.interval),
                  date = opts.date_state or clock_state(opts.date_format or DEFAULTS.date.format, opts.date_interval or DEFAULTS.date.interval),
                  tray = opts.tray or SystemTray.new({
                      icon_size = opts.tray_icon_size or DEFAULTS.tray.icon_size,
                      item_padding = opts.tray_item_padding or DEFAULTS.tray.item_padding,
                      gap = opts.tray_gap or DEFAULTS.tray.gap,
                      hover_bg = opts.tray_hover_bg,
                      show_passive = default_bool(opts.show_passive_tray_items, DEFAULTS.tray.show_passive),
                  }),
              }

              function self:battery_block(width, height)
                  local battery = shell.services.battery:get()
                  local percent = battery.percent or 0
                  local arrow = battery.charging and "↑" or "↓"

                  return block({
                      label(percent .. "%"),
                      label(arrow),
                  }, { width = width, height = height, gap = DEFAULTS.battery.gap })
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
                      gap = DEFAULTS.tray.gap,
                      padding_x = DEFAULTS.tray.item_padding,
                      padding_y = DEFAULTS.tray.item_padding,
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
              local dynamic_tray_width = count * DEFAULTS.tray.item_width + math.max(0, count - 1) * DEFAULTS.tray.gap + DEFAULTS.tray.base_width
              return {
                  battery = opts.battery_width or DEFAULTS.module_widths.battery,
                  time = opts.time_width or DEFAULTS.module_widths.time,
                  date = opts.date_width or DEFAULTS.module_widths.date,
                  tray = opts.tray_width or math.max(opts.min_tray_width or DEFAULTS.module_widths.min_tray, dynamic_tray_width),
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
                  gap = spacing or DEFAULTS.block.gap,
                  children = children,
              })
          end

          local function open_edge(edge, content, items, total_width, opts)
              local height = opts.height or DEFAULTS.height
              local fg = Wallust.hex(Wallust.color("fg", theme.text))
              local name = opts.name or ((opts.name_prefix or DEFAULTS.name_prefix) .. "-" .. edge)

              -- Close windows created by older per-module versions of this widget.
              for _, item in ipairs(items) do
                  close_existing((opts.name_prefix or DEFAULTS.name_prefix) .. "-" .. edge .. "-" .. item.name)
              end
              close_existing(name)

              local win = shell.window({
                  name = name,
                  anchor = DEFAULTS.anchors[edge],
                  popup_width = total_width,
                  height = height,
                  margin_top = edge == "top" and (opts.margin_top or DEFAULTS.margin_top) or DEFAULTS.margin_top,
                  margin_bottom = edge == "bottom" and (opts.margin_bottom or DEFAULTS.margin_bottom) or DEFAULTS.margin_bottom,
                  layer = opts.layer or DEFAULTS.layer,
                  exclusive = opts.exclusive == true,
                  bg = opts.bg or DEFAULTS.bg,
                  fg = fg,
                  font_size = opts.font_size or DEFAULTS.font_size,
                  font_family = M._font_family,
              })

              local render_fn = function()
                  return render_edge(content, items, total_width, height, opts.spacing or DEFAULTS.spacing)
              end
              win:render(render_fn)

              -- Until the runtime has fine-grained Lua dependency tracking, refresh
              -- these tiny module windows directly so clock/date/tray repaint exactly
              -- when their backing state changes.
              shell.interval(opts.refresh_interval or DEFAULTS.refresh_interval, function()
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
              close_existing(opts.top_name or DEFAULTS.top_name)
              close_existing(opts.bottom_name or DEFAULTS.bottom_name)

              local modules = opts.modules or DEFAULT_MODULES
              local widths = module_widths(opts)
              local height = opts.height or DEFAULTS.height
              local spacing = opts.spacing or DEFAULTS.spacing

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

              local time = clock_state(opts.time_format or DEFAULTS.time.format, opts.time_interval or DEFAULTS.time.interval)
              local date = clock_state(opts.date_format or DEFAULTS.date.format, opts.date_interval or DEFAULTS.date.interval)
              local tray = SystemTray.new({
                  icon_size = opts.tray_icon_size or DEFAULTS.tray.icon_size,
                  item_padding = opts.tray_item_padding or DEFAULTS.tray.item_padding,
                  gap = opts.tray_gap or DEFAULTS.tray.gap,
                  hover_bg = opts.tray_hover_bg,
                  show_passive = default_bool(opts.show_passive_tray_items, DEFAULTS.tray.show_passive),
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
                  name = opts.top_name or DEFAULTS.top_name,
                  height = height,
                  spacing = spacing,
                  name_prefix = opts.name_prefix,
                  margin_top = opts.margin_top,
                  exclusive = opts.exclusive,
                  refresh_interval = opts.refresh_interval,
                  layout_generation = layout_generation,
              })
              local bottom_window = open_edge("bottom", bottom_content, items, total, {
                  name = opts.bottom_name or DEFAULTS.bottom_name,
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
              if contains(modules, DEFAULTS.tray.name) and opts.relayout_interval ~= false then
                  local last_width = module_widths(opts).tray
                  shell.interval(opts.relayout_interval or DEFAULTS.relayout_interval, function()
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
