local column = {}
local visible = {}

local ratios = { 0.5, 21/32, 11/32 }
local ratio_idx = 1
local ratio = ratios[1]

local function vis()
  visible[wm.active] = visible[wm.active] or {}
  return visible[wm.active]
end

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
        v[prev] = old[(i % #old) + 1]:id()
        break
      end
    end
  end
  column[id] = side
  v[side] = id
  wm.arrange()
end

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

tomoe.bind("Mod+1", function() tomoe.spawn("cursor") end)
tomoe.bind("Mod+2", function() tomoe.spawn("librewolf") end)
tomoe.bind("Mod+3", function() tomoe.spawn("discord") end)
tomoe.bind("Mod+4", function() tomoe.spawn("steam") end)
tomoe.bind("Mod+5", function() tomoe.spawn("obs") end)
