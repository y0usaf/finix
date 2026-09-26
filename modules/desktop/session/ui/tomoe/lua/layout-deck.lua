-- ─── Layout: two 16:9 deck columns ───────────────────────────────────────────
-- The screen splits into a left and a right half-column; on 32:9 each
-- half is exactly 16:9. Each column is a deck: its front window fills
-- the half and the rest stay mapped one slot above/below it, so J/K can
-- animate the whole stack vertically instead of hide/show swapping.
-- wm's event hooks call arrange through the module table, so
-- reassigning wm.arrange swaps the layout everywhere.
local column = {} -- window id -> "left" | "right", persists across workspaces
local visible = {} -- workspace -> { left = id, right = id }: each deck's front

-- Mod+r cycles the column split: 16:9+16:9 → 21:9+11:9 → 11:9+21:9.
-- On the 32:9 screen, these are fractions of the total usable width:
-- 21/32 = 0.65625, 11/32 = 0.34375.
local ratios = { 0.5, 21/32, 11/32 }
local ratio_idx = 1
local ratio = ratios[1]

local function vis()
  visible[wm.active] = visible[wm.active] or {}
  return visible[wm.active]
end

-- Partition a workspace's tiled windows into ordered column lists,
-- assigning any new window to the focused window's column so a newly
-- spawned window stacks in the deck you're working in, not the opposite
-- one. With no tiled focused window, fall back to the emptier column
-- (tie: left). A new window jumps to the front of its deck (wm focuses
-- it on open).
local function split_columns(wins)
  local left, right = {}, {}
  local f = tomoe.focused_window()
  local fside = f and column[f:id()]
  for _, win in ipairs(wins) do
    local id = win:id()
    if not column[id] then
      if fside == "left" or fside == "right" then
        column[id] = fside
      elseif #left ~= #right then
        column[id] = #left < #right and "left" or "right"
      else
        column[id] = "left"
      end
      vis()[column[id]] = id
    end
    table.insert(column[id] == "left" and left or right, win)
  end
  return left, right
end

local function tiled_windows()
  local wins, full, floats = {}, {}, {}
  for _, win in ipairs(wm.workspaces[wm.active]) do
    local id = win:id()
    local rules = tomoe.rules_for(win)
    -- Classify rule-floated windows before split_columns sees them:
    -- briefly tiling then removing a transient corrupts the deck's
    -- visible id and makes that column jump back to its first window.
    if rules.floating then
      floating[id] = true
    end
    if wm.fullscreen[id] then
      table.insert(full, win)
    elseif floating[id] then
      table.insert(floats, win)
    else
      table.insert(wins, win)
    end
  end
  return wins, full, floats
end

-- Floating windows stay above the tiled deck; fullscreen stays above both.
local function raise_untiled(floats, full)
  for _, win in ipairs(floats) do
    win:show()
    win:raise()
  end
  for _, win in ipairs(full) do
    win:show()
    win:raise()
  end
end

-- Alt+O toggles a flat grid: every tiled window on the workspace shown
-- at once, equal-sized, gaps preserved (no 16:9 letterboxing, no deck
-- hiding). Off again on the next press. wm.arrange reads this flag, so
-- the layout follows focus/workspace switches until it's toggled back.
wm.grid = false

function wm.arrange()
  local area = tomoe.usable_area()
  local wins, full, floats = tiled_windows()
  local g = wm.gaps
  local x, y = area.x + g, area.y + g
  local w, h = area.w - 2 * g, area.h - 2 * g
  if wm.grid then
    local n = #wins
    if n == 0 then
      raise_untiled(floats, full)
      return
    end
    -- Fit n windows into the nearest-square grid (cols >= rows), each
    -- cell equal-sized. ceil(n/cols) rows so the last row never spills.
    local cols = math.ceil(math.sqrt(n))
    local rows = math.ceil(n / cols)
    local cw = math.floor((w - (cols - 1) * g) / cols)
    local ch = math.floor((h - (rows - 1) * g) / rows)
    for i, win in ipairs(wins) do
      local idx = i - 1
      local r = math.floor(idx / cols)
      local c = idx % cols
      win:set_geometry(
        x + c * (cw + g),
        y + r * (ch + g),
        cw, ch
      )
      win:show()
    end
    raise_untiled(floats, full)
    return
  end
  local left_cw = math.floor((w - g) * ratio)
  local right_cw = w - g - left_cw
  local left, right = split_columns(wins)
  local v = vis()
  local function place(col, side, cx, cw)
    if #col == 0 then
      v[side] = nil
      return
    end
    local front_idx = 1
    for i, win in ipairs(col) do
      if win:id() == v[side] then
        front_idx = i
        break
      end
    end
    local front = col[front_idx]
    local stride = h + g
    v[side] = front:id()
    for i, win in ipairs(col) do
      win:set_geometry(
        cx,
        y + (i - front_idx) * stride,
        cw, h
      )
      win:show()
    end
    front:raise()
  end
  place(left, "left", x, left_cw)
  place(right, "right", x + left_cw + g, right_cw)
  raise_untiled(floats, full)
end

-- H/L: focus the left/right deck's front window.
local function focus_column(side)
  local left, right = split_columns(tiled_windows())
  local col = side == "left" and left or right
  local id = vis()[side]
  for _, win in ipairs(col) do
    if win:id() == id then
      win:focus()
      return
    end
  end
  if col[1] then
    col[1]:focus()
  end
end

-- J/K: scroll the focused deck down/up (wraps), revealing and focusing
-- the next window in the column.
local function focus_vert(dir)
  local f = tomoe.focused_window()
  local side = f and column[f:id()]
  if not side then
    return
  end
  local left, right = split_columns(tiled_windows())
  local col = side == "right" and right or left
  for i, win in ipairs(col) do
    if win:id() == vis()[side] then
      local target = col[((i - 1 + dir) % #col) + 1]
      vis()[side] = target:id()
      wm.arrange()
      target:focus()
      return
    end
  end
end

-- Shift+J/K: move the focused window down/up within its deck's scroll
-- order, by swapping with its column neighbor in the workspace order.
local function move_vert(dir)
  local f = tomoe.focused_window()
  local side = f and column[f:id()]
  if not side then
    return
  end
  local wins = wm.workspaces[wm.active]
  local idxs, mine = {}, nil
  for i, win in ipairs(wins) do
    if column[win:id()] == side and not wm.fullscreen[win:id()] then
      table.insert(idxs, i)
      if win:id() == f:id() then
        mine = #idxs
      end
    end
  end
  local other = mine and mine + dir
  if not other or other < 1 or other > #idxs then
    return
  end
  local a, b = idxs[mine], idxs[other]
  wins[a], wins[b] = wins[b], wins[a]
  wm.arrange()
end

-- Shift+H/L: swap the two columns wholesale (deck fronts included).
local function swap_columns()
  for _, win in ipairs(wm.workspaces[wm.active]) do
    local id = win:id()
    if column[id] then
      column[id] = column[id] == "left" and "right" or "left"
    end
  end
  local v = vis()
  v.left, v.right = v.right, v.left
  wm.arrange()
end

-- [ / ]: send the focused window to the left/right column, where it
-- becomes the deck front. If it was the old deck's front, reveal the
-- next window in that deck rather than resetting to its first entry.
local function move_to_column(side)
  local f = tomoe.focused_window()
  if not f or wm.fullscreen[f:id()] or floating[f:id()] then
    return
  end
  local id = f:id()
  local v = vis()
  local prev = column[id]
  if prev and prev ~= side and v[prev] == id then
    local left, right = split_columns(tiled_windows())
    local old = prev == "left" and left or right
    v[prev] = nil
    for i, win in ipairs(old) do
      if win:id() == id and #old > 1 then
        -- Deck navigation wraps, so popping the bottom window reveals
        -- the top one just as focus_vert(1) would.
        v[prev] = old[(i % #old) + 1]:id()
        break
      end
    end
  end
  column[id] = side
  v[side] = id
  wm.arrange()
end

-- Click-to-focus or wm's close-refocus can land on a deck-offscreen
-- window; bring it to the front of its deck. Untiled windows (the
-- floating launcher) are skipped. Also keep a one-step focus history:
-- the close hook below needs to know who was focused before wm's
-- close-refocus already moved focus.
local last_focus = {}
local function find_tiled(id)
  if floating[id] then
    return
  end
  for _, win in ipairs(wm.workspaces[wm.active]) do
    if win:id() == id then
      return win
    end
  end
end
tomoe.on_focus_change(function(win)
  if not win then
    return
  end
  local id = win:id()
  if id ~= last_focus.cur then
    last_focus.prev, last_focus.cur = last_focus.cur, id
  end
  local side = column[id]
  if side and not wm.fullscreen[id] and find_tiled(id) and vis()[side] ~= id then
    vis()[side] = id
    wm.arrange()
  end
end)

-- wm's close hook (runs first) refocuses the flat-list-last window,
-- which may sit in the other deck. If the closed window was the focused
-- deck front, pull focus back to whatever that deck revealed instead.
-- Also drop the column assignment so reused ids start fresh.
tomoe.on_window_close(function(win)
  local id = win:id()
  local side = column[id]
  column[id] = nil
  floating[id] = nil
  if side and id == last_focus.prev then
    local front = vis()[side] and find_tiled(vis()[side])
    if front then
      front:focus()
    end
  end
end)

-- ─── Deck binds (HJKL over the two columns) ────────────────────────────────
tomoe.bind("Mod+h", function() focus_column("left") end, "Focus Left Column")
tomoe.bind("Mod+l", function() focus_column("right") end, "Focus Right Column")
tomoe.bind("Mod+j", function() focus_vert(1) end, "Scroll Deck Down")
tomoe.bind("Mod+k", function() focus_vert(-1) end, "Scroll Deck Up")
tomoe.bind("Mod+Shift+h", swap_columns, "Swap Columns")
tomoe.bind("Mod+Shift+l", swap_columns)
tomoe.bind("Mod+Shift+j", function() move_vert(1) end, "Move Window Down")
tomoe.bind("Mod+Shift+k", function() move_vert(-1) end, "Move Window Up")
tomoe.bind("Mod+bracketleft", function() move_to_column("left") end, "Move Window to Left Column")
tomoe.bind("Mod+bracketright", function() move_to_column("right") end, "Move Window to Right Column")
tomoe.bind("Mod+o", function() wm.grid = not wm.grid; wm.arrange() end, "Toggle Even Grid")
tomoe.bind("Mod+r", function()
  ratio_idx = ratio_idx % #ratios + 1
  ratio = ratios[ratio_idx]
  wm.arrange()
end, "Cycle Column Split (16:9+16:9 / 21:9+11:9 / 11:9+21:9)")

-- ─── Apps ───────────────────────────────────────────────────────────────────
tomoe.bind("Mod+1", function() tomoe.spawn("cursor") end)
tomoe.bind("Mod+2", function() tomoe.spawn("librewolf") end)
tomoe.bind("Mod+3", function() tomoe.spawn("discord") end)
tomoe.bind("Mod+4", function() tomoe.spawn("steam") end)
tomoe.bind("Mod+5", function() tomoe.spawn("obs") end)
