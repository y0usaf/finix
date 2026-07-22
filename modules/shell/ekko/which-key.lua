-- Zellij-style one-line status bar (mode ribbon + Ctrl+ tiles +
-- per-mode key hints that transform with the mode, powerline chevrons)
-- + session-list overlay + vim-style leader navigation, NO leader panel.
--
-- Drop in ~/.config/ekko/extensions/which-key.lua. Ekko's builtin leader
-- extension (ekko-builtins.leader) draws a bordered which-key panel the
-- instant ctrl+b enters leader mode, and that panel is drawn after every
-- surface (scene.rs), so no surface can hide it. Ekko still does not expose
-- a per-mode "disable the render" knob, and re-registering the "leader" mode
-- from Lua fails loudly (builtins register first; a name clash is an error),
-- so the only way to make ctrl+b show the hint bar instead of the panel is
-- to disable the builtin leader entirely (config.toml) and rebuild the
-- leader here in Lua with NO render — just the chord, the mode, the stock
-- map, and the hjkl/x navigation entries. The bottom-docked hint bar (the
-- surface below) and the leader-attached session-list overlay are the only
-- chrome in leader mode.
--
-- Status bar layout (zellij's one-line UI, single bottom row):
--   left: mode ribbon — ` NORMAL ` on the mode colour, powerline
--     chevron, then the shared-modifier tile strip
--     ` Ctrl + <b> LEADER  <p> PANE  <q> DETACH `; the active mode's
--     tile becomes a full coloured powerline segment.
--   right of the tiles the bar transforms with the mode (zellij's
--     one_line_ui): normal shows the leader map, any other mode shows a
--     chevron group separator then that mode's own keybinds — ctrl+p
--     flips the strip to the pane binds live. Session name right-aligned.
--   Chevrons are the nerd-font private-use glyph  (SEP below; swap for
--     ">" without arrow fonts, same fallback zellij makes).
--
-- Session-list overlay: a leader-attached overlay (`attach_mode = "leader"`)
-- opens the instant leader mode is entered and closes the instant it exits —
-- no wiring needed. It pops out as a centred floating panel: a bordered box
-- (`surface_raised` fill, `border` frame) sized to the widest session name
-- and centred on the frame (`col = floor((cols - width)/2)`, `row =
-- floor((rows - height)/2)`), mirroring the builtin help overlay's centring
-- math. A bold "sessions" title sits on the top border row; below it, one
-- row per session in sidebar order as "● name" — the current session in
-- `accent` with a filled bullet, the rest in `muted` with a hollow bullet.
-- Names are truncated on a codepoint boundary (with "…") so nothing
-- overflows the panel. It is render-only — input keeps flowing to the leader
-- mode, so the j/k session steps and the h/l project hops update the filled
-- bullet live while you hold the leader.
--
-- The navigation entries (h/j/k/l) are *sticky* (no "exit_mode"): hold the
-- leader, page through sessions/projects, then Esc out. The stock entries
-- (c/s/n/d/?) and the kill entry (x) are non-sticky: they run their action
-- and exit leader mode. Esc exits quietly; any other unbound printable
-- exits with a "leader: '<key>' is unbound" note.
--
-- NOTE: because the builtin leader is disabled, the `[keybinds] leader` and
-- `leader.*` config entries are no longer read by anything — the chord and
-- the stock-map keys live here. Rebind them by editing this file.

local ext = {
  id = "user.which-key",
  name = "which-key nav",
  version = "0.12.0",
  description = "vim-style hjkl nav + x kill-session + stock leader map + zellij-style one-line status bar (mode ribbon, Ctrl+ tile strip, per-mode key hints that transform with the mode, powerline chevrons), plus a leader-attached centred session-list panel that pops out on ctrl+b (no leader panel)",
}

-- 1-based wrap-around index: move `i` by `delta` within `n` elements,
-- wrapping in either direction. Shared by step_session, kill_session, and
-- adjacent_project so the modulo arithmetic lives in one place.
local function wrap(i, delta, n)
  return ((i - 1 + delta) % n + n) % n + 1
end

-- Status note matching the builtin's noop TTL (2 000 ms).
local NOTE_TTL_MS = 2000

local function note(text)
  return { set_status_note = { text = text, kind = "info", ttl_ms = NOTE_TTL_MS } }
end

-- Flatten the sidebar order: project -> session, across all projects.
local function session_names(snapshot)
  local names = {}
  for _, project in ipairs(snapshot.projects) do
    for _, session in ipairs(project.sessions) do
      names[#names + 1] = session.name
    end
  end
  return names
end

-- Index of the current session in the flattened list (1-based), or nil.
local function current_index(names, current)
  for i, name in ipairs(names) do
    if name == current then
      return i
    end
  end
  return nil
end

-- Next/prev session, wrapping around. Returns a switch_session action, or a
-- status note when there is nothing to switch to.
local function step_session(snapshot, delta)
  local names = session_names(snapshot)
  if #names < 2 then
    return { note("no other session") }
  end
  local i = current_index(names, snapshot.session_name) or 1
  local n = #names
  return { { switch_session = names[wrap(i, delta, n)] } }
end

-- First session of the adjacent project (wrapping), or a status note.
local function adjacent_project(snapshot, forward)
  local projects = snapshot.projects
  if #projects < 2 then
    return { note("no other project") }
  end
  -- Find the current session's project index (first match, matching the
  -- builtin's project_index_of which uses .position()).
  local cur = nil
  for pi, project in ipairs(projects) do
    for _, session in ipairs(project.sessions) do
      if session.name == snapshot.session_name then
        cur = pi
        break
      end
    end
    if cur then break end
  end
  cur = cur or 1
  local n = #projects
  local delta = forward and 1 or -1
  local idx = cur
  for _ = 1, n do
    idx = wrap(idx, delta, n)
    local first = projects[idx].sessions[1]
    if first then
      return { { switch_session = first.name } }
    end
    if idx == cur then
      break
    end
  end
  return { note("no other project") }
end

-- Kill the current session, then land on the next session in sidebar order
-- (wrapping). Mirrors the stock kill handler: kill first, switch to a
-- neighbor so you don't exit with the corpse. Non-sticky — exits leader mode.
local function kill_session(snapshot)
  local actions = { "kill_current_session" }
  local names = session_names(snapshot)
  if #names >= 2 then
    local i = current_index(names, snapshot.session_name) or 1
    local n = #names
    table.insert(actions, { switch_session = names[wrap(i, 1, n)] })
  end
  table.insert(actions, "exit_mode")
  return actions
end

-- ── session-list overlay ─────────────────────────────────────────────────

-- Truncate `text` to `max` display cells, appending an ellipsis when it
-- does not fit. The Lua bridge exposes no display_cell_width, so cells are
-- approximated as one per *codepoint* (good for ASCII; avoids slicing a
-- multi-byte UTF-8 sequence in half on non-ASCII session names). `max` is
-- a cell budget; the cut always lands on a codepoint boundary.
local function truncate(text, max)
  if max <= 0 then return "" end
  local ncells = 0
  for _ in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    ncells = ncells + 1
  end
  if ncells <= max then return text end
  if max <= 1 then return "\u{2026}" end
  local out, count = {}, 0
  for ch in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    count = count + 1
    if count >= max then break end
    out[#out + 1] = ch
  end
  return table.concat(out) .. "\u{2026}"
end

-- Count codepoints in `text` — the Lua bridge exposes no display-cell
-- width, so cells are approximated as one per codepoint (good for ASCII;
-- avoids counting bytes for multi-byte UTF-8). Used to size the panel to
-- its widest session name.
local function cp_width(text)
  local n = 0
  for _ in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    n = n + 1
  end
  return n
end

-- Render the session-list overlay as a centred floating panel that pops out
-- of the normal chrome on leader entry. The panel is a bordered box
-- (`draw_box` → box-drawing chars + `surface_raised` fill) sized to the
-- widest session name and centred on the frame: `col = floor((cols -
-- width)/2)`, `row = floor((rows - height)/2)`, mirroring the builtin help
-- overlay's centring math. A bold "sessions" title sits on the top border
-- row (overwriting the middle ─ chars, corners stay). Below it, one row per
-- session in sidebar order: "● name" — the current session gets a filled
-- bullet (U+25CF) in `accent`, every other session a hollow bullet (U+25CB)
-- in `muted`; names are truncated on a codepoint boundary (with "…") so
-- nothing overflows the panel. The overlay is `attach_mode = "leader"` so
-- the host opens it the instant leader mode is entered and closes it on
-- exit; it is render-only, so input keeps flowing to the leader mode — the
-- j/k session steps and the h/l project hops move the filled bullet live
-- while you hold the leader.
local function render_session_overlay(ctx, _state, snapshot)
  local cols, rows = ctx.size()
  if cols < 12 or rows < 5 then
    return
  end

  local names = session_names(snapshot)
  local cur = snapshot.session_name

  -- Inner content width: the widest "● name" row, or the title, whichever
  -- is larger. "● name" is bullet(1) + space(1) + name.
  local inner = cp_width("sessions")
  for _, name in ipairs(names) do
    local w = 2 + cp_width(name)
    if w > inner then inner = w end
  end
  if #names == 0 and cp_width("no sessions") > inner then
    inner = cp_width("no sessions")
  end

  -- Panel geometry: inner + 4 (2-col padding inside the border each side),
  -- clamped to the frame and a sensible floor.
  local width = math.max(12, math.min(inner + 4, cols))
  local n = #names
  if n == 0 then n = 1 end
  -- height: title row + one row per session + 1 bottom padding, clamped.
  local height = math.max(4, math.min(n + 2, rows))

  -- Centre on the frame.
  local col = math.floor((cols - width) / 2)
  local row = math.floor((rows - height) / 2)

  local bg = "surface_raised"
  local border = "border"

  -- Bordered box: fills with the raised surface and draws box-drawing chars.
  ctx.draw_box(col, row, width, height, "text", bg, border)

  -- Title on the top border row (overwrites the middle ─ chars; corners
  -- and the first/last 2 cols of the border remain).
  ctx.put_text_bold(col + 2, row, width - 4, "heading", bg, "sessions")

  if #names == 0 then
    ctx.put_text(col + 2, row + 1, width - 4, "muted", bg, "no sessions")
    return
  end

  -- One row per session, left-padded 2 inside the border. Stop before the
  -- bottom border row.
  local avail = width - 4
  local max_name = avail - 2
  for i, name in ipairs(names) do
    local r = row + i
    if r >= row + height - 1 then
      break
    end
    local is_current = name == cur
    local bullet = is_current and "\u{25CF}" or "\u{25CB}"   -- ● / ○
    local bullet_fg = is_current and "accent" or "muted"
    local name_fg = is_current and "accent" or "muted"
    ctx.put_text(col + 2, r, 1, bullet_fg, bg, bullet)
    local display = truncate(name, max_name)
    ctx.put_text(col + 4, r, max_name, name_fg, bg, display)
  end
end

-- ── zellij-style status bar ────────────────────────────────────────────

-- Powerline separator, zellij's ARROW_SEPARATOR (nerd-font private-use
-- glyph ). Set to ">" (or "") when the terminal font has no nerd-font
-- glyphs — the same fallback zellij makes without arrow fonts.
local SEP = "\u{e0b0}"

-- Left mode ribbon colours, one per mode (zellij: green NORMAL, orange
-- PANE, ...). Unknown modes fall back to status_bg.
local MODE_BG = {
  normal = "success",
  leader = "accent",
  pane = "warning",
  scroll = "accent_2",
  command = "accent_2",
}

-- Mode tiles, zellij's `<p> PANE  <t> TAB ...` strip. Every entry
-- is a real global ctrl chord: b and p are registered by this extension,
-- ctrl+q (detach) is stock. `mode` marks the tile that lights up while
-- its mode is active; DETACH is an action, never current, so it never
-- highlights.
local TILES = {
  { key = "b", name = "LEADER", mode = "leader" },
  { key = "p", name = "PANE", mode = "pane" },
  { key = "q", name = "DETACH", mode = nil },
}

-- The hints for the trailing segment: every binding scoped to the
-- active mode, straight from the snapshot's keybinding list, so a new
-- extension appears here automatically (stock scroll/command modes
-- included). Idle (normal mode) shows the leader map, mirroring zellij
-- showing its global shortcuts on the NORMAL line. The chord-repeat
-- "close panel" binding is filtered out — same thing as the leader hint.
-- Duplicate descriptions (hjkl + arrows for the same focus move) show
-- once, with their first chord.
local function hint_entries(snapshot)
  local mode = snapshot.mode
  if mode == "normal" then
    mode = "leader"
  end
  local entries = {}
  local seen = {}
  for _, b in ipairs(snapshot.keybindings) do
    if b.mode == mode and b.description ~= "close panel" and not seen[b.description] then
      seen[b.description] = true
      -- Multi-chord bindings show only their primary chord.
      local chord = (b.chord_text or ""):gsub("%s*/.*", "")
      entries[#entries + 1] = { key = chord, desc = b.description }
    end
  end
  return entries
end

-- Bar, left segment: the active mode's ribbon — ` NORMAL ` on the mode
-- colour, closed by a powerline chevron. Returns the next free column.
local function draw_ribbon(ctx, cols, mode)
  local label = " " .. mode:upper() .. " "
  local bg = MODE_BG[mode] or "status_bg"
  ctx.put_text_bold(0, 0, #label, "status_fg", bg, label)
  ctx.put_text(#label, 0, 1, bg, "surface", SEP)
  return #label + 1
end

-- Bar, after the ribbon: ` Ctrl + <b> LEADER  <p> PANE  <q> DETACH `,
-- zellij's shared-modifier tile strip. Unselected tiles: muted `<>` and
-- name, `text`-bold key, `border`-coloured chevron separators. The tile
-- of the active mode becomes a full powerline segment in the mode colour
-- — the bar visibly flips when ctrl+p / ctrl+b land. Returns the next
-- free column.
local function draw_tiles(ctx, cols, col, mode)
  local mod = " Ctrl +"
  ctx.put_text(col, 0, cols - col, "muted", "surface", mod)
  col = col + #mod
  for _, tile in ipairs(TILES) do
    local left = " <" .. tile.key .. ">"
    local right = " " .. tile.name .. " "
    if tile.mode == mode then
      local bg = MODE_BG[mode] or "status_bg"
      ctx.put_text(col, 0, 1, bg, "surface", SEP)
      ctx.put_text_bold(col + 1, 0, #left + #right, "status_fg", bg, left .. right)
      ctx.put_text(col + 1 + #left + #right, 0, 1, bg, "surface", SEP)
      col = col + #left + #right + 2
    else
      ctx.put_text(col, 0, 2, "muted", "surface", " <")
      ctx.put_text_bold(col + 2, 0, #tile.key, "text", "surface", tile.key)
      ctx.put_text(col + 2 + #tile.key, 0, 1, "muted", "surface", ">")
      ctx.put_text(col + 3 + #tile.key, 0, #right, "muted", "surface", right)
      col = col + #left + #right
      ctx.put_text(col, 0, 1, "border", "surface", SEP)
      col = col + 1
    end
  end
  return col
end

-- Trailing segment: the key hints, zellij one_line_ui's transforming
-- part. Normal mode shows the leader map straight after the tiles
-- (zellij shows its secondary info there); any other mode gets a chevron
-- group separator first, then that mode's own keybinds — ctrl+p flips
-- the strip to the pane binds live. ` <key> action` pairs, the key in
-- `accent` bold, the action in `text`. The session name sits at the
-- right edge in `muted` when it fits clear of the hints.
local function draw_hints(ctx, row, col, cols, snapshot)
  if snapshot.mode ~= "normal" then
    ctx.put_text(col, row, 1, "border", "surface", SEP)
    col = col + 1
  end
  for _, e in ipairs(hint_entries(snapshot)) do
    local key = " <" .. e.key .. ">"
    if col + #key + #e.desc + 1 >= cols then
      break
    end
    ctx.put_text_bold(col, row, #key, "accent", "surface", key)
    ctx.put_text(col + #key, row, #e.desc + 1, "text", "surface", " " .. e.desc)
    col = col + #key + #e.desc + 2
  end
  local name = snapshot.session_name
  local w = cp_width(name)
  if col + w + 2 < cols then
    ctx.put_text(cols - w - 1, row, w, "muted", "surface", name)
  end
end

-- Surface draw: the single-row zellij bar. Left is the mode ribbon +
-- Ctrl+ tiles; the rest of the line transforms with `snapshot.mode`
-- (every frame carries it): leader-map hints in normal, the mode's own
-- binds in any other mode. The builtin leader panel is gone (disabled in
-- config.toml) and this extension registers the leader mode with no
-- render, so on ctrl+b the ribbon flips to LEADER AND the
-- leader-attached session-list overlay pops out over the frame — no
-- builtin leader box.
local function draw_surface_bar(ctx, snapshot)
  local cols, rows = ctx.size()
  if cols < 4 or rows < 1 then
    return
  end
  -- The surface's context is clipped to its 1-row bottom rect.
  ctx.fill_rect(0, 0, cols, rows, "surface", "surface")
  local col = draw_ribbon(ctx, cols, snapshot.mode)
  col = draw_tiles(ctx, cols, col, snapshot.mode)
  draw_hints(ctx, 0, col, cols, snapshot)
end
-- ── leader mode (no render) ──────────────────────────────────────────────

-- Leader mode fallback for keys no registered leader binding matched (the
-- host tries mode-scoped registry bindings first). Mirrors the builtin
-- leader's on_key: unbound printables exit with a note, Esc exits quietly,
-- everything else (the chord autorepeating, ctrl-held chords, mouse reports,
-- stray escape sequences) is swallowed — exiting on those made autorepeat
-- parity toggle the mode.
local function leader_on_key(_state, bytes)
  -- Esc: exit quietly.
  if bytes == "\x1b" then
    return "exit"
  end
  -- A single non-control printable: exit with an "unbound" note.
  local ch = bytes
  if #ch == 1 then
    local code = string.byte(ch)
    -- 0x20..0x7e is the printable ASCII range; controls fall through to
    -- "continue" so the chord can autorepeat without closing the mode.
    if code >= 0x20 and code <= 0x7e then
      return { "exit", note(("leader: '%s' is unbound"):format(ch)) }
    end
  end
  -- Swallow everything else (chord autorepeat, ctrl-held chords, arrows,
  -- mouse reports) so the mode does not toggle on autorepeat parity.
  return nil
end

-- ── pane mode (zellij-style, no render) ──────────────────────────────────

-- Pane mode fallback. Unlike the leader, pane mode is MODAL (zellij's
-- `Ctrl p`): unbound keys are swallowed so the mode stays active for
-- repeated splits/focus moves; only Esc exits (`q` exits via its binding).
local function pane_on_key(_state, bytes)
  if bytes == "\x1b" then
    return "exit"
  end
  return nil
end

-- The leader chord (ctrl+b by default) and the stock leader map. The
-- builtin leader is disabled in config.toml, so these live here. Keys are
-- pinned to match the user's config; rebind by editing this table.
local LEADER_CHORD = "ctrl+b"
local STOCK_MAP = {
  { chord = "c", desc = "command mode", actions = { { enter_mode = "command" } } },
  { chord = "s", desc = "scroll",        actions = { { enter_mode = "scroll" } } },
  { chord = "n", desc = "new session",   actions = { "exit_mode", "new_session" } },
  { chord = "d", desc = "detach",        actions = { "exit_mode", "detach" } },
  { chord = "?", desc = "help",          actions = { "exit_mode", { open_overlay = "ekko:help" } } },
}

function ext.register(ekko)
  -- Leader chord: enter leader mode. Registered in normal mode (mode nil).
  ekko.register_keybinding({
    chord = LEADER_CHORD,
    mode = nil,
    description = "leader",
    handler = function(_snapshot)
      return { enter_mode = "leader" }
    end,
  })

  -- Pressing the chord again inside leader mode exits it (the builtin's
  -- "close panel" behaviour, minus the panel). The description is "close
  -- panel" so hint_entries filters it out — it is the same thing as the
  -- leader hint, so showing both is redundant. Non-sticky.
  ekko.register_keybinding({
    chord = LEADER_CHORD,
    mode = "leader",
    description = "close panel",
    handler = function(_snapshot)
      return { "exit_mode" }
    end,
  })

  -- Leader mode: a mode with NO render, so ctrl+b lights up the hint bar
  -- and the session-list overlay pops out its centred panel over the frame
  -- — no builtin leader panel. Input dispatches through the mode-scoped
  -- bindings above (and below) before falling to leader_on_key.
  ekko.register_mode({
    name = "leader",
    on_key = leader_on_key,
  })

  -- Stock leader map (non-sticky: act then exit leader mode).
  for _, entry in ipairs(STOCK_MAP) do
    local actions = entry.actions
    ekko.register_keybinding({
      chord = entry.chord,
      mode = "leader",
      description = entry.desc,
      handler = function(_snapshot)
        return actions
      end,
    })
  end

  -- h/l project hops removed: project navigation intentionally unbound.

  -- j: next session (sticky).
  ekko.register_keybinding({
    mode = "leader",
    chord = "j",
    description = "next session",
    handler = function(snapshot)
      return step_session(snapshot, 1)
    end,
  })

  -- k: previous session (sticky).
  ekko.register_keybinding({
    mode = "leader",
    chord = "k",
    description = "prev session",
    handler = function(snapshot)
      return step_session(snapshot, -1)
    end,
  })


  -- x: kill the current session (non-sticky — exits leader mode after kill).
  ekko.register_keybinding({
    mode = "leader",
    chord = "x",
    description = "kill session",
    handler = function(snapshot)
      return kill_session(snapshot)
    end,
  })

  -- Pane management (stock ekko-builtins.panes is disabled: its leader
  -- j/k/x collide with this map). Commands keep their stock names so
  -- `:split`/`:pane-focus`/`:pane-close` still work; leader keys use the
  -- chords this map leaves free: | and - to split, h/l to focus
  -- left/right, X to close (j/k stay session steps, x stays kill-session).
  -- Mouse click focuses a pane; :pane-focus up|down covers the rest.
  ekko.register_command({
    name = "split",
    args_hint = "right|down",
    description = "split the focused pane",
    handler = function(args)
      if args == "right" then
        return "split_right"
      elseif args == "down" then
        return "split_down"
      else
        return { { set_status_note = { text = "usage: split right|down", kind = "error" } } }
      end
    end,
  })
  ekko.register_command({
    name = "pane-focus",
    args_hint = "left|right|up|down",
    description = "focus the neighboring pane in a direction",
    handler = function(args)
      return { focus_direction = args }
    end,
  })
  ekko.register_command({
    name = "pane-close",
    description = "close the focused pane",
    handler = function()
      return "close_focused_pane"
    end,
  })
  local PANE_MAP = {
    { chord = "|", desc = "split right", actions = { "exit_mode", "split_right" } },
    { chord = "-", desc = "split down",  actions = { "exit_mode", "split_down" } },
    { chord = "h", desc = "focus left",  actions = { "exit_mode", { focus_direction = "left" } } },
    { chord = "l", desc = "focus right", actions = { "exit_mode", { focus_direction = "right" } } },
    { chord = "X", desc = "close pane",  actions = { "exit_mode", "close_focused_pane" } },
  }
  for _, entry in ipairs(PANE_MAP) do
    local actions = entry.actions
    ekko.register_keybinding({
      mode = "leader",
      chord = entry.chord,
      description = entry.desc,
      handler = function(_snapshot)
        return actions
      end,
    })
  end

  -- Zellij-style pane mode: `ctrl+p` enters a modal pane layer (keys stay
  -- active until q/Esc), matching zellij's `Ctrl p`. The hint bar switches
  -- to the pane map while it's active.
  ekko.register_keybinding({
    chord = "ctrl+p",
    mode = nil,
    description = "pane",
    handler = function(_snapshot)
      return { enter_mode = "pane" }
    end,
  })
  ekko.register_mode({
    name = "pane",
    on_key = pane_on_key,
  })
  local PANE_MODE_MAP = {
    { chord = "n", desc = "new pane",     actions = { "split_down" } },
    { chord = "r", desc = "split right",  actions = { "split_right" } },
    { chord = "d", desc = "split down",   actions = { "split_down" } },
    { chord = "x", desc = "close pane",   actions = { "close_focused_pane" } },
    { chord = "q", desc = "exit pane",    actions = { "exit_mode" } },
  }
  local FOCUS_MAP = {
    { chord = "h",     dir = "left" },
    { chord = "left",  dir = "left" },
    { chord = "j",     dir = "down" },
    { chord = "down",  dir = "down" },
    { chord = "k",     dir = "up" },
    { chord = "up",    dir = "up" },
    { chord = "l",     dir = "right" },
    { chord = "right", dir = "right" },
  }
  for _, entry in ipairs(PANE_MODE_MAP) do
    local actions = entry.actions
    ekko.register_keybinding({
      mode = "pane",
      chord = entry.chord,
      description = entry.desc,
      handler = function(_snapshot)
        return actions
      end,
    })
  end
  for _, entry in ipairs(FOCUS_MAP) do
    local dir = entry.dir
    ekko.register_keybinding({
      mode = "pane",
      chord = entry.chord,
      description = "focus " .. dir,
      handler = function(_snapshot)
        return { focus_direction = dir }
      end,
    })
  end

  -- Status bar: a one-line bottom-docked surface, always visible,
  -- redraws on every frame. Replaces the stock statusbar (disabled in
  -- config.toml). Render-only — input stays with the host (it dispatches
  -- the leader entries above).
  ekko.register_surface({
    name = "user.which-key:hints",
    dock = "bottom",
    priority = 0,
    size = 1,
    draw = draw_surface_bar,
  })

  -- Session-list overlay: leader-attached (`attach_mode = "leader"`), so the
  -- host opens it the instant leader mode is entered and closes it the
  -- instant it exits — no open/close wiring needed. Render-only (attached
  -- overlays never receive keys), so input keeps flowing to the leader mode;
  -- the j/k session steps and the h/l project hops move the filled bullet
  -- live while you hold the leader. Draws a centred bordered panel
  -- (`surface_raised` + `border`) over the frame, sized to the widest
  -- session name.
  ekko.register_overlay({
    name = "user.which-key:sessions",
    description = "session list, tied to leader mode",
    attach_mode = "leader",
    render = render_session_overlay,
  })
end

return ext
