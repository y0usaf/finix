{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.ui.moonshell;
  bar = cfg.bar-overlay;
  inherit (lib.types) bool;
  toLua = lib.generators.toLua {};
  luaInline = lib.generators.mkLuaInline;
  # nur's bar-overlay defaults, minus the tray: moonshell has no SNI
  # service yet (moonshell PLAN.md M3). Tray comes back once
  # shell.services.systemtray lands.
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
    };
    battery = {
      gap = 4;
    };
  };
in {
  options.user.ui.moonshell = {
    enable = lib.mkOption {
      type = bool;
      default = false;
      description = "Enable moonshell, the GPU-free Lua-scriptable Wayland shell (nur's successor).";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = flakeInputs.moonshell.packages."${pkgs.stdenv.hostPlatform.system}".moonshell;
      defaultText = lib.literalExpression ''flakeInputs.moonshell.packages."''${pkgs.stdenv.hostPlatform.system}".moonshell'';
      description = "moonshell package to install and run.";
    };

    config = lib.mkOption {
      type = lib.types.lines;
      default = ''
        -- Resolve the system monospace font so cosmic-text gets the real family name.
        local _ms_font = @FONT_FAMILY@
        if _ms_font == "" then _ms_font = @FONT_FAMILY_FALLBACK@ end

        local BarOverlay = dofile(os.getenv("HOME") .. "/.config/moonshell/bar_overlay.lua")

        BarOverlay.open(@BAR_OPEN_OPTIONS@)
      '';
      description = "Lua config written to ~/.config/moonshell/init.lua.";
    };

    bar-overlay = {
      enable = lib.mkOption {
        type = bool;
        default = true;
        description = "Generate the local moonshell bar overlay module.";
      };

      modules = lib.mkOption {
        # No "tray": moonshell has no SNI service yet (PLAN.md M3).
        type = lib.types.listOf (lib.types.enum ["time" "date" "battery"]);
        default = ["time" "date"];
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
        ".config/moonshell/init.lua".text =
          builtins.replaceStrings
          ["@FONT_FAMILY@" "@FONT_FAMILY_FALLBACK@" "@BAR_OPEN_OPTIONS@"]
          [
            (
              if bar.font-family != null
              then toLua bar.font-family
              else toLua (luaInline ''shell.exec("fc-match monospace --format='%{family}'")'')
            )
            (toLua barOverlayDefaults.font_family)
            (toLua {
              inherit (bar) modules exclusive;
              font_family = luaInline "_ms_font";
            })
          ]
          cfg.config;
      }
      // lib.optionalAttrs bar.enable {
        # Live Wallust -> theme bridge. Ported verbatim from nur's
        # lua/nur/wallust.lua (moonshell doesn't bundle it yet); its only
        # host dependencies — shell.state/exec/watch_file and
        # moonshell.theme:set — all exist since moonshell M2.
        ".config/moonshell/wallust.lua".text = ''
          -- ~/.config/moonshell/wallust.lua
          -- Live Wallust -> moonshell.theme bridge (port of nur.wallust).
          --
          -- Reads ~/.cache/wallust/gtk-colors.css, applies the GTK color tokens,
          -- and exposes a reactive version state so widgets repaint when Wallust
          -- regenerates colors.

          local theme = require("moonshell.theme")

          local M = {}

          M.path = os.getenv("WALLUST_GTK_COLORS")
              or ((os.getenv("HOME") or "/home/${config.user.name}") .. "/.cache/wallust/gtk-colors.css")

          M.version = shell.state(0)

          M.colors = {
              bg = theme.base,
              fg = theme.text,
              accent = theme.accent,
              black = theme.crust or 0x000000,
          }

          local function shquote(s)
              s = tostring(s or "")
              -- Built from string.char(39) = single-quote to dodge nix
              -- indented-string escapes; esc is the POSIX quote-escape
              -- sequence: quote, backslash-quote, quote.
              local q = string.char(39)
              local esc = q .. "\\" .. q .. q
              return q .. s:gsub(q, esc) .. q
          end

          local function hex_to_int(value)
              if not value then return nil end
              local s = tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
              local hex = s:match("#([%x]+)") or s:match("^([%x]+)$")
              if not hex or #hex < 6 then return nil end
              hex = hex:sub(1, 6)
              return tonumber(hex, 16)
          end

          local function resolve_value(name, raw, seen)
              seen = seen or {}
              if not name or seen[name] then return nil end
              seen[name] = true

              local value = raw[name]
              if not value then return nil end

              local direct = hex_to_int(value)
              if direct then return direct end

              local ref = tostring(value):match("^@([%w_%-]+)$")
              if ref then return resolve_value(ref, raw, seen) end

              return nil
          end

          local function parse_css(css)
              css = css or ""
              local raw = {}

              -- Wallust GTK syntax: @define-color bg #rrggbb;
              for name, value in css:gmatch("@define%-color%s+([%w_%-]+)%s+([^;%s]+)") do
                  raw[name] = value
              end

              -- Also accept CSS custom property syntax: --bg: #rrggbb;
              for name, value in css:gmatch("%-%-([%w_%-]+)%s*:%s*([^;%s]+)") do
                  raw[name] = value
              end

              local out = {}
              for name, _ in pairs(raw) do
                  out[name] = resolve_value(name, raw)
              end

              out.bg = out.bg or out.background or out.color0
              out.fg = out.fg or out.foreground or out.color15 or out.color7
              out.accent = out.accent or out.color4 or out.color5 or out.color6 or out.fg
              out.black = out.black or out.color0 or out.background or 0x000000

              return out
          end

          local function channel(color, shift)
              return math.floor(color / (2 ^ shift)) % 256
          end

          function M.mix(a, b, amount)
              amount = math.max(0, math.min(1, amount or 0.5))
              local ar, ag, ab = channel(a, 16), channel(a, 8), channel(a, 0)
              local br, bg, bb = channel(b, 16), channel(b, 8), channel(b, 0)
              local r = math.floor(ar + (br - ar) * amount + 0.5)
              local g = math.floor(ag + (bg - ag) * amount + 0.5)
              local bl = math.floor(ab + (bb - ab) * amount + 0.5)
              return r * 0x10000 + g * 0x100 + bl
          end

          function M.hex(color)
              return string.format("#%06x", color or 0)
          end

          function M.color(name, fallback)
              return M.colors[name] or fallback
          end

          function M.apply_css(css)
              local parsed = parse_css(css or "")

              M.colors.bg = parsed.bg or M.colors.bg
              M.colors.fg = parsed.fg or M.colors.fg
              M.colors.accent = parsed.accent or M.colors.accent
              M.colors.black = parsed.black or M.colors.black

              for name, value in pairs(parsed) do
                  if value then M.colors[name] = value end
              end

              local hover = M.mix(M.colors.bg, M.colors.fg, 0.10)

              theme:set({
                  base = M.colors.bg,
                  mantle = M.colors.bg,
                  crust = M.colors.black,
                  surface0 = M.colors.bg,
                  surface1 = hover,
                  surface2 = M.colors.accent,

                  text = M.colors.fg,
                  subtext1 = M.colors.fg,
                  subtext0 = M.colors.fg,

                  accent = M.colors.accent,
                  blue = M.colors.accent,
                  sapphire = M.colors.accent,

                  black = M.colors.black,
                  font_size = 14,
                  font_family = "monospace",
                  bar_height = 24,
                  widget_gap = 8,
                  bar_padding = 0,
              })

              M.version:set(M.version:get() + 1)
          end

          function M.load(path)
              if path then M.path = path end
              local q = shquote(M.path)
              local css = shell.exec("if [ -r " .. q .. " ]; then cat " .. q .. "; fi")
              M.apply_css(css)
          end

          function M.watch(path)
              if path then M.path = path end
              M.load(M.path)

              if M._watched_path ~= M.path then
                  M._watched_path = M.path
                  shell.watch_file(M.path, function(css)
                      M.apply_css(css)
                  end)
              end
          end

          return M
        '';

        ".config/moonshell/bar_overlay.lua".text = ''
          -- ~/.config/moonshell/bar_overlay.lua
          -- Local bar overlay config (nur's bar_overlay, tray stripped:
          -- moonshell has no SNI service yet — tray returns with M3).
          --
          -- Uses one compositor-centered layer-shell surface per edge. Module blocks
          -- render inside that fixed-width centered surface, so positioning is delegated
          -- to the compositor instead of computed from an assumed display width.

          local Wallust = _G.__moonshell_wallust
              or dofile(os.getenv("HOME") .. "/.config/moonshell/wallust.lua")
          _G.__moonshell_wallust = Wallust
          local theme = require("moonshell.theme")

          local DEFAULTS = ${toLua barOverlayDefaults}

          local M = _G.__moonshell_widgets_bar_overlay or {}
          _G.__moonshell_widgets_bar_overlay = M
          M._layout_generation = M._layout_generation or 0
          M._font_family = M._font_family or DEFAULTS.font_family

          local DEFAULT_MODULES = DEFAULTS.modules

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
              -- moonshell window handles don't expose :close yet (PLAN M4);
              -- hot reload swaps the whole VM (windows included), so this
              -- only matters for same-VM re-open — pcall keeps it safe.
              local old = shell.get_window(name)
              if old then pcall(function() old:close() end) end
          end

          function M.new(opts)
              opts = opts or {}

              local self = {
                  modules = opts.modules or DEFAULT_MODULES,
                  time = opts.time_state or clock_state(opts.time_format or DEFAULTS.time.format, opts.time_interval or DEFAULTS.time.interval),
                  date = opts.date_state or clock_state(opts.date_format or DEFAULTS.date.format, opts.date_interval or DEFAULTS.date.interval),
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

              function self:render_module(name, width, height)
                  if name == "battery" then return self:battery_block(width, height) end
                  if name == "time" then return self:time_block(width, height) end
                  if name == "date" then return self:date_block(width, height) end
                  return ui.hbox({ width = width, height = height, children = {} })
              end

              return self
          end

          local function module_widths(opts)
              opts = opts or {}
              return {
                  battery = opts.battery_width or DEFAULTS.module_widths.battery,
                  time = opts.time_width or DEFAULTS.module_widths.time,
                  date = opts.date_width or DEFAULTS.module_widths.date,
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
              -- these tiny module windows directly so clock/date repaint exactly
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

              local top_content = M.new({
                  modules = modules,
                  time_state = time,
                  date_state = date,
              })
              local bottom_content = M.new({
                  modules = modules,
                  time_state = time,
                  date_state = date,
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
