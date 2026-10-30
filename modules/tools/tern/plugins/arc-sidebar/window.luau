local COLORS = { "red", "orange", "yellow", "green", "teal", "blue", "purple", "pink" }
local SHELLS = { zsh = true, bash = true, fish = true, nu = true, sh = true, dash = true, ksh = true }
local PIN_COLOR = "teal"

local color_at = 0
local tab_count = 0
local pinned = 0
local space_name = ""

local function set_pref(cx, key, word: string): boolean
	local spelled = word:sub(1, 1):upper() .. word:sub(2)
	for _, value in ipairs({ word, spelled }) do
		if pcall(function()
			cx.settings:set(key, value)
		end) then
			local read, now = pcall(function()
				return cx.settings:get(key)
			end)
			if read and type(now) == "string" and now:lower() == word then
				return true
			end
		end
	end
	return false
end

local function arc(cx): boolean
	local layout = set_pref(cx, "layout", "rail")
		or pcall(function()
			cx:command("layout:rail")
		end)
	local tabs = set_pref(cx, "tabs", "vertical")
		or pcall(function()
			cx:command("tabs:vertical")
		end)
	return layout and tabs
end

local function pinned_list(): { number }
	local saved = tern.kv.get("pins")
	if type(saved) ~= "table" then
		return {}
	end
	local list = {}
	for _, id in ipairs(saved) do
		if type(id) == "number" then
			list[#list + 1] = id
		end
	end
	return list
end

local function save_pins(list: { number })
	tern.kv.set("pins", tern.json.array(list))
end

local function is_pinned(list, id: number): boolean
	for _, pinned_id in ipairs(list) do
		if pinned_id == id then
			return true
		end
	end
	return false
end

local function promote(cx, list)
	local set = {}
	for _, id in ipairs(list) do
		set[id] = true
	end
	local seen = {}
	local position = 0
	for _, tab in ipairs(cx.session:tabs()) do
		if set[tab.id] then
			position += 1
			seen[tab.id] = true
			cx.layout:order_tab(tab.id, position)
		end
	end
	local kept = {}
	for _, id in ipairs(list) do
		if seen[id] then
			kept[#kept + 1] = id
		end
	end
	if #kept ~= #list then
		save_pins(kept)
	end
	pinned = #kept
	return kept
end

local function recount(cx)
	tab_count = #cx.session:tabs()
	local current = cx.sessions:current()
	space_name = current and current.name or ""
	tern.chrome.refresh()
end

tern.on("window_start", function(cx)
	arc(cx)
	local list = pinned_list()
	if #list > 0 then
		promote(cx, list)
	end
	recount(cx)
end)

tern.on("tab_created", function(_, cx)
	local list = pinned_list()
	if #list > 0 then
		promote(cx, list)
	end
	recount(cx)
end)

tern.on("tab_closed", function(_, cx)
	recount(cx)
end)

tern.chrome.tab_title(function(tab)
	if tab.name and tab.name ~= "" then
		return nil
	end
	local title = tab.title or ""
	if SHELLS[tab.program] then
		title = title:gsub("^[^%s:]+@[^%s:]+:%s*", "")
	end
	if title == "" then
		local cwd = tab.cwd or ""
		title = cwd:match("([^/]+)/*$") or cwd
	end
	if title == "" then
		return nil
	end
	return title
end)

tern.chrome.status(function(_pane)
	local parts = {}
	if space_name ~= "" then
		parts[#parts + 1] = space_name
	end
	if tab_count > 0 then
		parts[#parts + 1] = tab_count .. (tab_count == 1 and " tab" or " tabs")
	end
	if pinned > 0 then
		parts[#parts + 1] = pinned .. " pinned"
	end
	if #parts == 0 then
		return nil
	end
	return { { text = table.concat(parts, " · "), tone = "muted" } }
end)

tern.command({
	id = "arc",
	title = "Sidebar: Arc mode",
	icon = "layout",
	run = function(cx)
		if arc(cx) then
			cx:toast("success", "Arc sidebar")
		else
			cx:toast("error", "Could not switch to the rail layout")
		end
		recount(cx)
	end,
})

tern.command({
	id = "autohide",
	title = "Sidebar: Toggle auto-hide",
	icon = "sidebar",
	run = function(cx)
		local hidden = not cx.settings:get("tabs_autohide")
		cx.settings:set("tabs_autohide", hidden)
		cx:toast("info", hidden and "Sidebar tucks away" or "Sidebar stays open")
	end,
})

tern.command({
	id = "pin",
	title = "Sidebar: Pin or unpin this tab",
	icon = "pin",
	run = function(cx)
		local pane = cx.session:focused()
		local tab = pane and cx.session:tab_of(pane)
		if not tab then
			return
		end
		local list = pinned_list()
		if is_pinned(list, tab) then
			local kept = {}
			for _, id in ipairs(list) do
				if id ~= tab then
					kept[#kept + 1] = id
				end
			end
			save_pins(kept)
			cx.layout:color_tab(tab, nil)
			pinned = #kept
			cx:toast("info", "Unpinned")
		else
			list[#list + 1] = tab
			save_pins(list)
			cx.layout:color_tab(tab, PIN_COLOR)
			promote(cx, list)
			cx:toast("success", "Pinned to the top")
		end
		tern.chrome.refresh()
	end,
})

tern.command({
	id = "unpin-all",
	title = "Sidebar: Unpin every tab",
	icon = "pin",
	run = function(cx)
		local list = pinned_list()
		for _, id in ipairs(list) do
			pcall(function()
				cx.layout:color_tab(id, nil)
			end)
		end
		save_pins({})
		pinned = 0
		cx:toast("info", "No pinned tabs")
		tern.chrome.refresh()
	end,
})

tern.command({
	id = "colour",
	title = "Sidebar: Colour this tab",
	icon = "palette",
	run = function(cx)
		local pane = cx.session:focused()
		local tab = pane and cx.session:tab_of(pane)
		if not tab then
			return
		end
		color_at = color_at % #COLORS + 1
		cx.layout:color_tab(tab, COLORS[color_at])
	end,
})

tern.bind("ctrl+alt+p", "plugin.arc-sidebar.pin")
tern.bind("ctrl+alt+j", "next_tab")
tern.bind("ctrl+alt+k", "previous_tab")
tern.bind("ctrl+alt+f", "focus_tabs")
