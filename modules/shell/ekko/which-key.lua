local ext = {
  id = "user.which-key",
  name = "which-key nav",
  version = "0.13.0",
  description = "vim-style hjkl nav + x kill-session + stock leader map + zellij-style session tab strip on top, tmux-style solid green hint bar on the bottom, plus a leader-attached centred session-list panel that pops out on ctrl+b (no leader panel)",
}

-- 1-based wrap-around index: move `i` by `delta` within `n` elements,
-- wrapping in either direction. Shared by step_session and kill_session.
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

-- Alive sessions only (state == "Alive"): resurrectable manifests have no
-- daemon to switch to.
local function alive_session_names(snapshot)
  local names = {}
  for _, project in ipairs(snapshot.projects) do
    for _, session in ipairs(project.sessions) do
      -- The Lua bridge serializes SessionState lowercase ("alive"/"gone").
      if session.state == "alive" then
        names[#names + 1] = session.name
      end
    end
  end
  return names
end

-- Close-focused-pane, gated by the finix close-to-nearest-session option
-- (prologue local FINIX_CLOSE_TO_SESSION): when the focused pane is the
-- session's last and other alive sessions exist, close it but land on the
-- next session in sidebar order instead of exiting the terminal. The close
-- message is queued before the switch action, so the daemon tears the
-- emptied session down while the client reconnects; the stale Exit frame
-- from the old connection is dropped by generation filtering.
local function close_pane_actions(snapshot)
  if FINIX_CLOSE_TO_SESSION and #snapshot.panes <= 1 then
    local names = alive_session_names(snapshot)
    if #names >= 2 then
      local i = current_index(names, snapshot.session_name) or 1
      return { "close_focused_pane", { switch_session = names[wrap(i, 1, #names)] } }
    end
  end
  return { "close_focused_pane" }
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

local function styled(ctx, col, row, width, fg, bg, text, reverse, bold)
  ctx.put_text_styled(col, row, width, fg, bg, text, reverse, bold)
end

-- ── compact bottom bar ───────────────────────────────────────────────────
-- Rust's display_cell_width is not bridged to Lua, so this approximation is deliberate.
local function codepoint_width(cp)
  if (cp >= 0x0300 and cp <= 0x036F) or (cp >= 0x1AB0 and cp <= 0x1AFF)
      or (cp >= 0x1DC0 and cp <= 0x1DFF) or (cp >= 0x20D0 and cp <= 0x20FF)
      or (cp >= 0xFE00 and cp <= 0xFE0F) then
    return 0
  end
  if (cp >= 0x1100 and cp <= 0x115F) or (cp >= 0x2329 and cp <= 0x232A)
      or (cp >= 0x2E80 and cp <= 0xA4CF) or (cp >= 0xAC00 and cp <= 0xD7A3)
      or (cp >= 0xF900 and cp <= 0xFAFF) or (cp >= 0xFE10 and cp <= 0xFE6F)
      or (cp >= 0xFF00 and cp <= 0xFF60) or (cp >= 0x1F000 and cp <= 0x1FAFF) then
    return 2
  end
  return 1
end

local function utf8_codepoint(ch)
  local b1, b2, b3, b4 = string.byte(ch, 1, 4)
  if b1 < 0x80 then return b1 end
  if b1 < 0xE0 then return (b1 - 0xC0) * 0x40 + b2 - 0x80 end
  if b1 < 0xF0 then return (b1 - 0xE0) * 0x1000 + (b2 - 0x80) * 0x40 + b3 - 0x80 end
  return (b1 - 0xF0) * 0x40000 + (b2 - 0x80) * 0x1000 + (b3 - 0x80) * 0x40 + b4 - 0x80
end

local function display_width(text)
  local n = 0
  for ch in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    n = n + codepoint_width(utf8_codepoint(ch))
  end
  return n
end

local function truncate(text, max)
  if max <= 0 then return "" end
  if display_width(text) <= max then return text end
  if max == 1 then return "…" end
  local out, width = {}, 0
  local ellipsis_width = display_width("…")
  for ch in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    local cw = codepoint_width(utf8_codepoint(ch))
    if width + cw + ellipsis_width > max then break end
    out[#out + 1], width = ch, width + cw
  end
  return table.concat(out) .. "…"
end

local MODE_BG = { normal = "success", leader = "accent", pane = "warning", scroll = "accent_2", command = "accent_2" }
local SEP_LEFT, SEP_RIGHT = "", ""
local NOTE_SETTLE, MODE_SETTLE = 2000, 240
local last_note_text, last_note_ms, last_mode, mode_flip_ms
local FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function emphasis(snapshot)
  if last_mode ~= snapshot.mode then last_mode, mode_flip_ms = snapshot.mode, snapshot.now_ms end
  local age = mode_flip_ms and snapshot.now_ms - mode_flip_ms or MODE_SETTLE
  if age < 80 then return true, false elseif age < MODE_SETTLE then return false, true end
  return false, false
end

local function note_content(snapshot)
  local n = snapshot.status_note
  if not n then return nil end
  if last_note_text ~= n.text then last_note_text, last_note_ms = n.text, snapshot.now_ms end
  local fg = n.kind == "error" and "error" or n.kind == "ok" and "success" or "accent"
  return " " .. n.text .. " ", fg, last_note_ms and snapshot.now_ms - last_note_ms < NOTE_SETTLE
end

local function draw_mode(ctx, start, mode, reverse, bold, solid_bg)
  local label = " " .. mode:upper() .. " "
  local w = display_width(label)
  if solid_bg then
    styled(ctx, start, 0, w, "status_fg", solid_bg, label, reverse, bold)
    return w
  end
  if mode == "normal" then
    styled(ctx, start, 0, w, "success", "transparent", label, reverse, bold)
    return w
  end
  local bg = MODE_BG[mode] or "status_bg"
  styled(ctx, start, 0, w, "status_fg", bg, label, reverse, bold)
  if start + w < ctx.size() then ctx.put_text(start + w, 0, 1, bg, "transparent", SEP_RIGHT) end
  return w + 1
end

local function chord_tokens(chord)
  local primary = (chord or ""):gsub("%s*/.*", "")
  local modifier, key = primary:match("^([%a]+)%+(.+)$")
  if modifier then return modifier, key end
  return nil, primary
end

local function hint_entries(snapshot)
  local out, seen = {}, {}
  for _, binding in ipairs(snapshot.keybindings or {}) do
    local eligible = snapshot.mode == "normal" and binding.mode == nil
      or snapshot.mode ~= "normal" and binding.mode == snapshot.mode
    if eligible and binding.description ~= "close panel" and not seen[binding.description] then
      seen[binding.description] = true
      out[#out + 1] = { chord = binding.chord_text or "", desc = binding.description or "" }
    end
  end
  return out
end

local function token_width(entry, with_desc)
  local modifier, key = chord_tokens(entry.chord)
  local tokens = modifier and ("[" .. modifier:gsub("^%l", string.upper) .. "] [" .. key .. "]") or ("[" .. key .. "]")
  return display_width(tokens .. (with_desc and (" " .. entry.desc) or "")), modifier, key, tokens
end

-- ── zellij-style tab strip (top) ─────────────────────────────────────────
-- One tab per session; the current session's tab is highlighted with the
-- accent background, exactly zellij's tab-name strip.

local TAB_MAX = 24

local function tab_label(index, max)
  return " " .. truncate(tostring(index), max) .. " "
end

local function draw_top(ctx, snapshot)
  local cols, rows = ctx.size(); if cols < 1 or rows < 1 then return end
  ctx.fill_rect(0, 0, cols, rows, "transparent", "transparent")
  local reverse, bold = emphasis(snapshot)
  -- Left edge: the mode indicator, like zellij's mode ribbon.
  local chip_w = display_width(" " .. snapshot.mode:upper() .. " ") + (snapshot.mode == "normal" and 0 or 1)
  local x = 0
  if chip_w <= cols then x = draw_mode(ctx, 0, snapshot.mode, reverse, bold) end
  -- Spinner sits right after the chip when scrollback is open.
  if (snapshot.scrollback > 0 or snapshot.mode == "scroll") and x + 1 < cols then
    ctx.put_text(x + 1, 0, 1, "accent", "transparent", FRAMES[(math.floor(snapshot.now_ms / 80) % #FRAMES) + 1])
  end
  -- Right edge: a transient note wins; otherwise the session name (dim).
  local text, fg, fresh = note_content(snapshot)
  local value = text or snapshot.session_name or ""
  local shown = truncate(value, math.floor(cols / 3))
  local right_w = display_width(shown)
  if right_w > 0 then styled(ctx, cols - right_w, 0, right_w, text and fg or "muted", "transparent", shown, false, text and fresh or false) end
  -- Center: the tab strip, clipped to the space between chip and name.
  local names = session_names(snapshot)
  local left_limit = x + 2
  local right_limit = cols - right_w - 2
  if #names == 0 or right_limit - left_limit < 6 then return end
  -- Halve the per-tab label budget until the whole strip fits.
  local labels, strip_w, max_w = {}, 0, TAB_MAX
  for _ = 1, 8 do
    labels, strip_w = {}, 0
    for i in ipairs(names) do
      local label = tab_label(i, max_w)
      strip_w = strip_w + display_width(label) + 1
      labels[#labels + 1] = label
    end
    strip_w = strip_w - 1
    if strip_w <= right_limit - left_limit or max_w <= 3 then break end
    max_w = math.max(3, math.floor(max_w / 2))
  end
  local cur = current_index(names, snapshot.session_name) or 1
  local tx = left_limit + math.floor((right_limit - left_limit - strip_w) / 2)
  for i, label in ipairs(labels) do
    local lw = display_width(label)
    if tx + lw > right_limit then break end
    if i == cur then
      styled(ctx, tx, 0, lw, "status_fg", "accent", label, false, true)
    else
      styled(ctx, tx, 0, lw, "muted", "transparent", label, false, false)
    end
    tx = tx + lw + 1
  end
end

-- ── tmux-style colored strip (bottom) ────────────────────────────────────
-- The whole row is one solid colored bar (tmux's default green), with the
-- mode chip on the left, centered key hints, and the session name on the
-- right — all drawn in the strip's own colors.

local function draw_bottom(ctx, snapshot)
  local cols, rows = ctx.size(); if cols < 1 or rows < 1 then return end
  ctx.fill_rect(0, 0, cols, rows, "status_fg", "success")
  draw_mode(ctx, 0, snapshot.mode, false, false, "accent")
  local name = " " .. (snapshot.session_name or "") .. " "
  local nw = display_width(name)
  if nw < cols then styled(ctx, cols - nw, 0, nw, "status_fg", "success", name, false, true) end
  local entries = hint_entries(snapshot)
  local function measure(with_desc)
    local total, count = 0, 0
    for _, entry in ipairs(entries) do
      local w = token_width(entry, with_desc)
      local add = w + (count > 0 and 2 or 0)
      if total + add > cols then break end
      total, count = total + add, count + 1
    end
    return total, count
  end
  local row_w, count, with_desc
  row_w, count = measure(true)
  if count < #entries then row_w, count = measure(false); with_desc = false else with_desc = true end
  if count == 0 then return end
  local x = math.max(0, math.floor((cols - row_w) / 2))
  for i = 1, count do
    local entry = entries[i]
    local _, modifier, key = token_width(entry, with_desc)
    if modifier then
      local mt = "[" .. modifier:gsub("^%l", string.upper) .. "] "
      local mw = display_width(mt)
      styled(ctx, x, 0, mw, "status_fg", "success", mt, false, false); x = x + mw
    end
    local kt = "[" .. key .. "]"
    local kw = display_width(kt)
    styled(ctx, x, 0, kw, "status_fg", "success", kt, false, true); x = x + kw
    if with_desc then
      local d = " " .. entry.desc
      local dw = display_width(d)
      styled(ctx, x, 0, dw, "status_fg", "success", d, false, false); x = x + dw
    end
    if i < count then x = x + 2 end
  end
end

local function draw_sessions(ctx, _state, snapshot)
  local cols, rows = ctx.size()
  if cols < 12 or rows < 5 then return end
  local names = session_names(snapshot)
  local count = #names
  local longest = 0
  for i = 1, count do longest = math.max(longest, display_width(names[i] or "")) end
  local name_w = math.max(1, longest)
  local width = math.min(cols, name_w + 5)
  name_w = math.max(1, width - 5)
  local capacity = math.max(1, rows - 2)
  local vis = math.min(capacity, math.max(1, count))
  local height = vis + 2
  local col, row = math.floor((cols - width) / 2), math.floor((rows - height) / 3)
  ctx.draw_box(col, row, width, height, "surface_raised", "surface_raised", "border")
  styled(ctx, col + 2, row, math.min(9, width - 2), "heading", "surface_raised", " sessions ", false, true)
  if count == 0 then
    styled(ctx, col + 3, row + 1, name_w, "muted", "surface_raised", truncate("no sessions", name_w), false, false)
    return
  end
  local cur = current_index(names, snapshot.session_name) or 1
  local from_top = math.max(0, math.min(cur - math.floor(vis / 2) - 1, count - vis))
  for offset = 0, vis - 1 do
    local index = from_top + offset + 1
    local name = names[index]
    if name ~= nil then
      -- Numbered like the top strip's tabs; the accent color marks the current one.
      local marker = index < 10 and tostring(index) or "·"
      ctx.put_text(col + 1, row + 1 + offset, 1, index == cur and "accent" or "muted", "surface_raised", marker)
      styled(ctx, col + 3, row + 1 + offset, name_w, index == cur and "text" or "muted", "surface_raised", truncate(name, name_w), false, false)
    end
  end
  if count > vis then
    ctx.render_scrollbar{col = col + width - 1, row = row + 1, rows = vis, visible = vis, total = count, from_top = from_top, fg = "border", bg = "surface_raised", thumb_fg = "accent", track = "│", thumb = "┃"}
  end
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
-- builtin leader is disabled in init.lua, so these live here. Keys are
-- pinned to match the user's config; rebind by editing this table.
local LEADER_CHORD = "ctrl+b"
local STOCK_MAP = {
  { chord = "n", desc = "new session",   actions = { "exit_mode", "new_session" } },
  { chord = "d", desc = "detach",        actions = { "exit_mode", "detach" } },
  { chord = "?", desc = "help",          actions = { "exit_mode", { open_overlay = "ekko:help" } } },
  { chord = "s", desc = "scroll",         actions = { { enter_mode = "scroll" } } },
  { chord = "c", desc = "command mode",   actions = { { enter_mode = "command" } } },
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
  -- panel" so the duplicate close-panel hint is avoided — it is the same thing as the
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


  -- 1..9: jump to the Nth session in tab-strip order (same flattened
  -- project -> session order the top bar numbers its tabs with).
  for i = 1, 9 do
    local target = i
    ekko.register_keybinding({
      mode = "leader",
      chord = tostring(target),
      description = "session " .. target,
      handler = function(snapshot)
        local names = session_names(snapshot)
        if target > #names then
          return { note(("no session %d"):format(target)) }
        end
        return { "exit_mode", { switch_session = names[target] } }
      end,
    })
  end

  -- Alt+Right / Alt+Left cycle sessions without leaving normal mode.
  -- (Previously Ctrl+Tab / Ctrl+Shift+Tab, which ekko 0.1.0's chord parser
  -- rejects at registration time — "unparseable chord" — and because this
  -- config disables every builtin extension, that single bad chord killed
  -- the whole extension runtime: no keybinds, no bars, at launch.)
  for _, step in ipairs({ { chord = "alt+right", delta = 1, desc = "next session" },
                          { chord = "alt+left", delta = -1, desc = "prev session" } }) do
    local delta = step.delta
    ekko.register_keybinding({
      mode = nil,
      chord = step.chord,
      description = step.desc,
      handler = function(snapshot)
        return step_session(snapshot, delta)
      end,
    })
  end

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
  -- j/k/x collide with this map). Equal-area layout ignores the split axis;
  -- pane creation is exposed as a no-argument command. Mouse click focuses a
  -- pane; :pane-focus up|down covers the rest.
  ekko.register_command({
    name = "pane-new",
    description = "open a new pane",
    handler = function(_raw_args)
      return "split_down"
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
  -- Zellij-style pane mode: `ctrl+p` enters a modal pane layer (keys stay
  -- active until q/Esc), matching zellij's `Ctrl p` — except n (new pane),
  -- which splits and auto-exits pane mode, mirroring new session in leader mode.
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
    { chord = "n", desc = "new pane",     actions = { "exit_mode", "split_down" } },
    -- x goes through close_pane_actions (close-to-nearest-session option);
    -- the :pane-close command cannot: command handlers see no snapshot.
    { chord = "x", desc = "close pane",   gated = true },
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
      handler = entry.gated
        and function(snapshot)
          local gated = close_pane_actions(snapshot)
          table.insert(gated, 1, "exit_mode")
          return gated
        end
        or function(_snapshot)
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

  -- Two docked surfaces deliberately cost the PTY two rows of grid.
  ekko.register_surface({
    name = "user.which-key:top",
    dock = "top", priority = 0, size = 1,
    wants_tick = function(snapshot)
      local note_fresh = snapshot.status_note and (last_note_text ~= snapshot.status_note.text or not last_note_ms or snapshot.now_ms - last_note_ms < NOTE_SETTLE)
      local mode_fresh = mode_flip_ms and snapshot.now_ms - mode_flip_ms < MODE_SETTLE
      local active = snapshot.scrollback > 0 or snapshot.mode == "scroll"
      return not not (note_fresh or mode_fresh or active)
    end,
    draw = draw_top,
  })
  ekko.register_surface({
    name = "user.which-key:bottom",
    dock = "bottom", priority = 0, size = 1,
    draw = draw_bottom,
  })

  ekko.register_overlay({
    name = "user.which-key:sessions",
    attach_mode = "leader",
    render = draw_sessions,
  })

-- The extension registers a bottom status surface and a leader-attached
-- session-list overlay, plus navigation callbacks above.

end

return ext
