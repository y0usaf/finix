tomoe.settings { animations = false }

local trees = {}
local split_pref = {}
local focus_hist = {}

local function is_leaf(node)
  return node ~= nil and node.win ~= nil
end

local function find_leaf(node, id)
  if not node then
    return nil
  end
  if is_leaf(node) then
    return node.win == id and node or nil
  end
  for _, kid in ipairs(node.kids) do
    local hit = find_leaf(kid, id)
    if hit then
      return hit
    end
  end
  return nil
end

local function last_leaf(node)
  if is_leaf(node) then
    return node.win
  end
  return node and last_leaf(node.kids[#node.kids]) or nil
end

local function insert_leaf(node, target_id, new_id, dir)
  if is_leaf(node) then
    if node.win == target_id then
      return { dir = dir, kids = { { win = target_id }, { win = new_id } } }
    end
    return node
  end
  if node.dir == dir then
    for i, kid in ipairs(node.kids) do
      if is_leaf(kid) and kid.win == target_id then
        table.insert(node.kids, i + 1, { win = new_id })
        return node
      end
    end
  end
  for i, kid in ipairs(node.kids) do
    if find_leaf(kid, target_id) then
      node.kids[i] = insert_leaf(kid, target_id, new_id, dir)
      return node
    end
  end
  return node
end

local function prune(node, keep)
  if not node then
    return nil
  end
  if is_leaf(node) then
    return keep[node.win] and node or nil
  end
  local kids = {}
  for _, kid in ipairs(node.kids) do
    local k = prune(kid, keep)
    if k then
      kids[#kids + 1] = k
    end
  end
  if #kids == 0 then
    return nil
  end
  if #kids == 1 then
    return kids[1]
  end
  node.kids = kids
  return node
end

local function render(node, x, y, w, h, g)
  if is_leaf(node) then
    local win = tomoe.window(node.win)
    if win then
      win:set_geometry(x, y, w, h)
      win:show()
    end
    return
  end
  local n = #node.kids
  if node.dir == "h" then
    local pos = x
    local step = math.floor((w - (n - 1) * g) / n)
    for i, kid in ipairs(node.kids) do
      local kw = i == n and (x + w - pos) or step
      render(kid, pos, y, kw, h, g)
      pos = pos + kw + g
    end
  else
    local pos = y
    local step = math.floor((h - (n - 1) * g) / n)
    for i, kid in ipairs(node.kids) do
      local kh = i == n and (y + h - pos) or step
      render(kid, x, pos, w, kh, g)
      pos = pos + kh + g
    end
  end
end

function wm.arrange()
  local area = tomoe.usable_area()
  local g = wm.gaps
  local wins, full, floats = {}, {}, {}
  local keep = {}
  for _, win in ipairs(wm.workspaces[wm.active]) do
    local id = win:id()
    if tomoe.rules_for(win).floating then
      floating[id] = true
    end
    if wm.fullscreen[id] then
      full[#full + 1] = win
    elseif floating[id] then
      floats[#floats + 1] = win
    else
      wins[#wins + 1] = win
      keep[id] = true
    end
  end
  local root = prune(trees[wm.active], keep)
  for _, win in ipairs(wins) do
    local id = win:id()
    if not find_leaf(root, id) then
      if not root then
        root = { win = id }
      else
        local target = (focus_hist.prev and keep[focus_hist.prev])
          and focus_hist.prev or last_leaf(root)
        local dir = split_pref[target]
        split_pref[target] = nil
        if not dir then
          local twin = tomoe.window(target)
          local geo = twin and twin:geometry()
          dir = (geo and geo.h > geo.w) and "v" or "h"
        end
        root = insert_leaf(root, target, id, dir)
      end
    end
  end
  trees[wm.active] = root
  if root then
    render(root, area.x + g, area.y + g, area.w - 2 * g, area.h - 2 * g, g)
  end
  for _, win in ipairs(floats) do
    win:show()
    win:raise()
  end
  for _, win in ipairs(full) do
    win:show()
    win:raise()
  end
end

local function focus_dir(dx, dy)
  local f = tomoe.focused_window()
  local fg = f and f:geometry()
  if not fg then
    return
  end
  local fx, fy = fg.x + fg.w / 2, fg.y + fg.h / 2
  local best, best_d
  for _, win in ipairs(wm.workspaces[wm.active]) do
    local id = win:id()
    if id ~= f:id() and not floating[id] and not wm.fullscreen[id] then
      local geo = win:geometry()
      if geo then
        local cx, cy = geo.x + geo.w / 2, geo.y + geo.h / 2
        local ddx, ddy = cx - fx, cy - fy
        local dom = dx ~= 0 and ddx or ddy
        local cross = dx ~= 0 and ddy or ddx
        if (dom > 0) == (dx + dy > 0) and math.abs(dom) > math.abs(cross) then
          local d = math.abs(ddx) + math.abs(ddy)
          if not best_d or d < best_d then
            best, best_d = win, d
          end
        end
      end
    end
  end
  if best then
    best:focus()
  end
end

local function ws_step(dir)
  wm.switch(((wm.active - 1 + dir) % wm.workspace_count) + 1)
end

local function ws_move_step(dir)
  local win = tomoe.focused_window()
  if not win then
    return
  end
  local n = ((wm.active - 1 + dir) % wm.workspace_count) + 1
  local source = wm.workspaces[wm.active]
  for i, candidate in ipairs(source) do
    if candidate:id() == win:id() then
      table.remove(source, i)
      table.insert(wm.workspaces[n], win)
      wm.switch(n)
      return
    end
  end
end

local function leaf_ids(node, out)
  if not node then
    return out
  end
  if is_leaf(node) then
    out[#out + 1] = node.win
    return out
  end
  for _, kid in ipairs(node.kids) do
    leaf_ids(kid, out)
  end
  return out
end

local function swap_leaf(node, a, b)
  if not node then
    return
  end
  if is_leaf(node) then
    if node.win == a then
      node.win = b
    elseif node.win == b then
      node.win = a
    end
    return
  end
  for _, kid in ipairs(node.kids) do
    swap_leaf(kid, a, b)
  end
end

local function move_swap(dir)
  local f = tomoe.focused_window()
  local root = trees[wm.active]
  if not f or not root then
    return
  end
  local ids = leaf_ids(root, {})
  for i, id in ipairs(ids) do
    if id == f:id() then
      local j = i + dir
      if j < 1 or j > #ids then
        return
      end
      swap_leaf(root, id, ids[j])
      wm.arrange()
      return
    end
  end
end

tomoe.on_focus_change(function(win)
  if not win then
    return
  end
  local id = win:id()
  if id ~= focus_hist.cur then
    focus_hist.prev, focus_hist.cur = focus_hist.cur, id
  end
end)

tomoe.on_window_close(function(win)
  local id = win:id()
  split_pref[id] = nil
  floating[id] = nil
  if focus_hist.prev == id then
    focus_hist.prev = nil
  end
end)

tomoe.on_reload("sway", function()
  return trees
end, function(saved)
  local function valid(node)
    if is_leaf(node) then
      return tomoe.window(node.win) ~= nil
    end
    local kids = {}
    for _, kid in ipairs(node.kids or {}) do
      if valid(kid) then
        kids[#kids + 1] = kid
      end
    end
    node.kids = kids
    return #kids > 0
  end
  trees = {}
  for ws, root in pairs(saved or {}) do
    if type(root) == "table" and valid(root) then
      trees[tonumber(ws) or ws] = root
    end
  end
  wm.arrange()
end)

tomoe.bind("Mod+h", function() focus_dir(-1, 0) end, "Focus Left")
tomoe.bind("Mod+l", function() focus_dir(1, 0) end, "Focus Right")
tomoe.bind("Mod+Ctrl+j", function() focus_dir(0, 1) end, "Focus Down")
tomoe.bind("Mod+Ctrl+k", function() focus_dir(0, -1) end, "Focus Up")
tomoe.bind("Mod+j", function() ws_step(1) end, "Next Workspace")
tomoe.bind("Mod+k", function() ws_step(-1) end, "Previous Workspace")
tomoe.bind("Mod+Shift+j", function() ws_move_step(1) end, "Move Window to Next Workspace")
tomoe.bind("Mod+Shift+k", function() ws_move_step(-1) end, "Move Window to Previous Workspace")
tomoe.bind("Mod+Shift+h", function() move_swap(-1) end, "Swap with Previous Window")
tomoe.bind("Mod+Shift+l", function() move_swap(1) end, "Swap with Next Window")
tomoe.bind("Mod+b", function()
  local f = tomoe.focused_window()
  if f then
    split_pref[f:id()] = "h"
  end
end, "Split Next Horizontally")
tomoe.bind("Mod+v", function()
  local f = tomoe.focused_window()
  if f then
    split_pref[f:id()] = "v"
  end
end, "Split Next Vertically")
tomoe.bind("Mod+1", function() tomoe.spawn("cursor") end)
tomoe.bind("Mod+2", function() tomoe.spawn("librewolf") end)
tomoe.bind("Mod+3", function() tomoe.spawn("discord") end)
tomoe.bind("Mod+4", function() tomoe.spawn("steam") end)
tomoe.bind("Mod+5", function() tomoe.spawn("obs") end)
