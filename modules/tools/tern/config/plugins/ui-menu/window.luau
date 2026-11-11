local Rail = require("./rail")
tern.css("ui-menu-base", tern.fs.read(tern.plugin.dir .. "/snippets/rail.css") .. tern.fs.read(tern.plugin.dir .. "/snippets/settings.css"))

local TWEAKS = {
	{
		id = "mini",
		label = "Mini",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "ozette",
		label = "Ozette",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "ozette-motion",
		label = "Ozette motion",
		parent = "ozette",
		default = false,
		layer = true,
		requires = { "ozette" },
	},
	{
		id = "ozette-cmus",
		label = "Ozette cmus player",
		parent = "ozette",
		default = false,
		layer = true,
		requires = { "ozette" },
	},
	{
		id = "ozette-answer-bubbles",
		requires = { "ozette", "answer-bubbles" },
	},
	{
		id = "ozette-bot-you",
		requires = { "ozette", "bot-you" },
	},
	{
		id = "yorha",
		label = "YoRHa",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "bot-yorha-labels",
		label = "YoRHa labels",
		parent = "yorha",
		requires = { "yorha" },
	},
	{
		id = "grok",
		label = "Grok",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "departure",
		label = "Departure",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "automata",
		label = "Automata",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "botanical",
		label = "Botanical",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "braun",
		label = "Braun",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "folio",
		label = "Folio",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "blueprint",
		label = "Blueprint",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "eink",
		label = "Eink",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "phosphor",
		label = "Phosphor",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "scratch",
		label = "Unset all",
		group = "Look layers",
		default = false,
		layer = true,
	},
	{
		id = "attention",
		label = "status dot attention colours",
		group = "Chrome",
	},
	{
		id = "grips",
		label = "hide window buttons and pane grips",
		group = "Chrome",
	},
	{
		id = "dividers",
		label = "invisible pane dividers",
		group = "Chrome",
	},
	{
		id = "transparent",
		label = "transparent window",
		group = "Glass",
		default = false,
	},
	{
		id = "single",
		label = "Single session",
		group = "Chrome",
	},
	{
		id = "account",
		label = "hide account and peers",
		group = "Chrome",
	},
	{
		id = "files",
		label = "hide files",
		group = "Chrome",
	},
	{
		id = "roomy",
		label = "tall pickers",
		group = "Chrome",
	},
	{
		id = "inbox",
		label = "centred inbox",
		group = "Chrome",
	},
	{
		id = "pane-borders",
		label = "Ekko pane borders",
		group = "Chrome",
		default = false,
	},
	{
		id = "frost",
		label = "modal frost",
		group = "Glass",
	},
	{
		id = "user-frost",
		label = "frosted your messages",
		parent = "frost",
		requires = { "frost" },
	},
	{
		id = "composer-frost",
		label = "frosted composer",
		group = "Glass",
		parent = "frost",
		requires = { "frost" },
	},
	{
		id = "bot-you-frost",
		requires = { "frost", "bot-you" },
	},
	{
		id = "reply-frost",
		label = "frosted replies",
		parent = "frost",
		requires = { "frost" },
	},
	{
		id = "answer-frost",
		requires = { "reply-frost", "answer-bubbles" },
	},
	{
		id = "bot-answer-frost",
		requires = { "reply-frost", "bot-answer-bubbles" },
	},
	{
		id = "width",
		label = "rail width",
		group = "Rail",
	},
	{
		id = "tabs",
		label = "tab rows",
		group = "Rail",
	},
	{
		id = "buttons",
		label = "rail buttons",
		group = "Rail",
	},
	{
		id = "centering",
		label = "rail centering",
		group = "Rail",
	},
	{
		id = "bottom",
		label = "rail bottom",
		group = "Rail",
	},
	{
		id = "lock",
		label = "lock the rail layout",
		group = "Layout",
	},
	{
		id = "answer-bubbles",
		label = "answer bubbles",
		group = "omp",
	},
	{
		id = "work-rail",
		label = "work steps on a rail",
		group = "omp",
	},
	{
		id = "row-keys",
		label = "hide rail row shortcuts",
		group = "Rail",
	},
	{
		id = "turn-stats",
		label = "hide turn stats",
		group = "omp",
	},
	{
		id = "chat-still",
		label = "no streaming",
		group = "omp",
	},
	{
		id = "bot-answer-bubbles",
		label = "answer bubbles",
		group = "omp bots",
	},
	{
		id = "bot-turn-stats",
		label = "hide the working timer",
		group = "omp bots",
	},
	{
		id = "bot-tints",
		label = "tint colours and font",
		group = "omp bots",
	},
	{
		id = "bot-layout",
		label = "header, hero and placeholders",
		group = "omp bots",
	},
	{
		id = "bot-spacing",
		label = "tight message spacing",
		group = "omp bots",
	},
	{
		id = "bot-you",
		label = "your message bubbles",
		group = "omp bots",
	},
	{
		id = "bot-text",
		label = "message text spacing",
		group = "omp bots",
	},
	{
		id = "bot-dock",
		label = "hide composer meters",
		group = "omp bots",
	},
	{
		id = "bot-time",
		label = "timestamps",
		group = "omp bots",
	},
	{
		id = "bot-events",
		label = "event rows",
		group = "omp bots",
	},
	{
		id = "bot-ask",
		label = "question cards",
		group = "omp bots",
	},
	{
		id = "bot-names",
		label = "names and status line",
		group = "omp bots",
	},
	{
		id = "bot-stop",
		label = "stop button",
		group = "omp bots",
	},
	{
		id = "bot-rail",
		label = "roster tabs in the rail",
		group = "omp bots",
	},
	{
		id = "bot-jobs",
		label = "hide job notices",
		group = "omp bots",
	},
	{
		id = "yorha-answer-bubbles",
		requires = { "yorha", "answer-bubbles" },
	},
	{
		id = "yorha-bot-answer-bubbles",
		requires = { "yorha", "bot-answer-bubbles" },
	},
	{
		id = "yorha-bot-you",
		requires = { "yorha", "bot-you" },
	},
	{
		id = "grok-answer-bubbles",
		requires = { "grok", "answer-bubbles" },
	},
	{
		id = "grok-user-bubbles",
		requires = { "grok" },
	},
	{
		id = "grok-bot-answer-bubbles",
		requires = { "grok", "bot-answer-bubbles" },
	},
	{
		id = "grok-bot-you",
		requires = { "grok", "bot-you" },
	},
	{
		id = "bubbles",
		label = false,
		default = false,
		layer = true,
	},
}

for _, t in ipairs(Rail.tweaks) do
	table.insert(TWEAKS, t)
end

local saved = tern.kv.get("on")
local on = {}
local by_id = {}
for _, t in ipairs(TWEAKS) do
	local ok, css = pcall(tern.fs.read, tern.plugin.dir .. "/snippets/" .. t.id .. ".css")
	if ok then
		t.css = css
	end
	on[t.id] = if type(saved) == "table" and saved[t.id] ~= nil then saved[t.id] == true else t.default ~= false
	by_id[t.id] = t
end
local CARBON = { "departure", "automata", "botanical", "braun", "folio", "blueprint", "eink", "phosphor" }
local carbon = false
for _, id in ipairs(CARBON) do
	carbon = carbon or on[id] == true
end
on.bubbles = carbon
local function save()
	local diff = {}
	for _, t in ipairs(TWEAKS) do
		if on[t.id] ~= (t.default ~= false) then
			diff[t.id] = on[t.id]
		end
	end
	tern.kv.set("on", diff)
end

local children = {}
for _, t in ipairs(TWEAKS) do
	for _, id in ipairs(t.requires or {}) do
		if not by_id[id] then
			error("ui-menu: " .. t.id .. " requires unknown option " .. id)
		end
	end
	if t.parent then
		if not by_id[t.parent] then
			error("ui-menu: " .. t.id .. " has unknown parent " .. t.parent)
		end
		if not children[t.parent] then
			children[t.parent] = {}
		end
		table.insert(children[t.parent], t)
	end
end

local function walk(t, path)
	if path[t.id] then
		error("ui-menu: requirement cycle through " .. t.id)
	end
	path[t.id] = true
	for _, id in ipairs(t.requires or {}) do
		walk(by_id[id], path)
	end
	path[t.id] = nil
end

for _, t in ipairs(TWEAKS) do
	walk(t, {})
end
tern.kv.set("menu", nil)

Rail.bind(on)

local pinned = nil
local folding = false
local function single(cx)
	local key = cx:window_key()
	local pins = tern.kv.get("single-pins") or {}
	if not on.single then
		pinned = nil
		if pins[key] ~= nil then
			pins[key] = nil
			tern.kv.set("single-pins", pins)
		end
		return
	end
	if folding then
		return
	end
	folding = true
	local ok, err = pcall(function()
		local sessions = cx.sessions:list()
		local anchor = nil
		local result, reason = nil, nil
		pinned = pinned or pins[key]
		for _, session in ipairs(sessions) do
			if session.id == pinned then
				anchor = session
			end
		end
		if not anchor then
			anchor = cx.sessions:current()
			pinned = anchor.id
			pins[key] = pinned
			tern.kv.set("single-pins", pins)
		end
		if cx.sessions:current().id ~= pinned then
			cx.sessions:switch(pinned)
		end
		if anchor.locked then
			cx.sessions:unlock(pinned)
		end
		local sources = {}
		local sourceTabs = {}
		local count = 0
		for _, session in ipairs(sessions) do
			if session.id ~= pinned and session.host == anchor.host then
				sources[session.id] = true
				count = count + 1
			end
		end
		if count == 0 then
			return
		end
		for _, session in ipairs(cx.session:sessions()) do
			if sources[session.id] then
				for _, tab in ipairs(session.tabs) do
					sourceTabs[tab] = true
				end
			end
		end
		local panes = cx.session:panes()
		local groups = {}
		for _, tab in ipairs(cx.session:tabs()) do
			local blocks = {}
			if tab.session == pinned then
				table.insert(groups, { tab = tab.id, blocks = {} })
			end
			if sourceTabs[tab.id] then
				for _, pane in ipairs(panes) do
					if pane.tab == tab.id then
						table.insert(blocks, pane.pane)
					end
				end
				if #blocks > 0 then
					table.insert(groups, { name = tab.name, color = tab.color, blocks = blocks })
				end
			end
		end
		local parked = {}
		local hostPanes = {}
		for _, host in ipairs(cx.hosts:list()) do
			if host.id == anchor.host then
				for _, pane in ipairs(host.panes) do
					hostPanes[pane] = true
				end
			end
		end
		for _, pane in ipairs(panes) do
			if pane.parked and hostPanes[pane.pane] then
				table.insert(parked, pane.pane)
				table.insert(groups, { blocks = { pane.pane } })
			end
		end
		if #groups > 0 then
			result, reason = cx.layout:arrange({ session = pinned, tabs = groups })
			if not result then
				error(reason)
			end
			for _, pane in ipairs(parked) do
				cx.layout:park(pane)
			end
		end
		for _, session in ipairs(sessions) do
			if sources[session.id] then
				cx.sessions:close(session.id)
			end
		end
	end)
	folding = false
	if not ok then
		tern.log.error("Single session: " .. tostring(err))
		cx:toast("error", "Single session: " .. tostring(err))
	end
end
for _, event in ipairs({ "focus", "pane_created", "tab_created", "session_ended" }) do
	tern.on(event, function(ev, cx)
		single(cx)
	end)
end

local function rail(cx)
	pcall(function()
		cx:action("layout:rail")
	end)
	pcall(function()
		cx:action("tabs:horizontal")
	end)
end

local function guard(ids, id, message)
	for _, command in ipairs(ids) do
		pcall(function()
			tern.override(command, function(cx)
				if id and not on[id] then
					return false
				end
				cx:toast("info", message)
				return true
			end)
		end)
	end
end

guard({ "layout:float", "layout:tiles", "layout:studio", "next_layout", "toggle_tab_orientation", "tabs:vertical" }, "lock", "The rail is locked")
guard({ "pane_headers:never", "pane_headers:split", "pane_headers:always", "status_bar", "interface_style" }, nil, "This config fixes the chrome")
guard({ "files", "focus_files", "reveal_active_file" }, "files", "Files are off")
guard({ "new_session", "new_session_on_host", "switch_session", "rename_session", "close_session", "lock_session", "move_session_up", "move_session_down", "move_pane_to_session", "collapse_all_sessions", "expand_all_sessions" }, "single", "Tabs only: one pinned session")

tern.on("window_start", function(cx)
	pcall(function()
		cx.settings:set_many({
			layout = "Rail",
			tabs = "Horizontal",
			pane_headers = "Never",
			density = "Compact",
			status_bar = true,
			material = "Glass",
		})
	end)
	if on.lock then
		rail(cx)
	end
	single(cx)
end)

for _, ms in ipairs({ 0, 300, 1200 }) do
	tern.timer(ms, function(cx)
		if cx and on.lock then
			rail(cx)
		end
		if cx then
			single(cx)
		end
	end)
end

local function live(t)
	if not on[t.id] then
		return false
	end
	for _, id in ipairs(t.requires or {}) do
		if not live(by_id[id]) then
			return false
		end
	end
	return true
end

local shown = {}
local function paint()
	for _, t in ipairs(TWEAKS) do
		local yes = live(t)
		if t.css and shown[t.id] ~= yes then
			shown[t.id] = yes
			tern.css("ui-menu-" .. t.id, if yes then t.css else "")
		end
	end
end

paint()

local LOOKS = {
	{ label = "Mini", layers = { "mini" } },
	{ label = "Ozette", layers = { "ozette", "ozette-motion", "ozette-cmus" } },
	{ label = "YoRHa", layers = { "yorha" } },
	{ label = "Grok", layers = { "grok" } },
	{ label = "Departure", layers = { "departure", "bubbles" } },
	{ label = "Automata", layers = { "automata", "bubbles" } },
	{ label = "Botanical", layers = { "botanical", "bubbles" } },
	{ label = "Braun", layers = { "braun", "bubbles" } },
	{ label = "Folio", layers = { "folio", "bubbles" } },
	{ label = "Blueprint", layers = { "blueprint", "bubbles" } },
	{ label = "Eink", layers = { "eink", "bubbles" } },
	{ label = "Phosphor", layers = { "phosphor", "bubbles" } },
	{ label = "Unset all", layers = { "scratch" } },
	{ label = "None", layers = {} },
}

local function plugins(): { [string]: string }
	local root = tern.plugin.dir .. "/.."
	local found = {}
	for _, entry in ipairs(tern.fs.list(root)) do
		local dir = root .. "/" .. entry
		if entry:match("%.path$") then
			dir = (tern.fs.read(dir):gsub("%s+$", ""))
		end
		local ok, manifest = pcall(tern.fs.read, dir .. "/plugin.toml")
		if ok then
			manifest = "\n" .. manifest
			local id, name = manifest:match('\nid%s*=%s*"([^"]+)"'), manifest:match('\nname%s*=%s*"([^"]+)"')
			if id then
				found[id] = name or id
			end
		end
	end
	return found
end

local function want(layers)
	local set = {}
	for _, t in ipairs(TWEAKS) do
		if t.layer then
			set[t.id] = false
		end
	end
	for _, id in ipairs(layers) do
		set[id] = true
	end
	return set
end

local function wears(layers)
	for id, yes in want(layers) do
		if on[id] ~= yes then
			return false
		end
	end
	return true
end

local function pick(layers)
	for id, yes in want(layers) do
		on[id] = yes
	end
	save()
	paint()
end

local function toggle(cx, t)
	on[t.id] = not on[t.id]
	if on[t.id] and t.excludes then
		for _, id in ipairs(t.excludes) do
			on[id] = false
		end
	end
	for _, id in ipairs(CARBON) do
		if id == t.id then
			local any = false
			for _, other in ipairs(CARBON) do
				any = any or on[other] == true
			end
			on.bubbles = any
		end
	end
	save()
	paint()
	if t.apply then
		t.apply(cx)
	end
	if t.id == "lock" and on.lock then
		rail(cx)
	end
	if t.id == "single" then
		single(cx)
	end
	tern.chrome.refresh()
end

local function menu(cx)
	local disabled = cx.settings:get("plugins_disabled") or {}
	local off = {}
	for _, id in ipairs(disabled) do
		off[id] = true
	end
	local installed = plugins()
	local items = {}
	local function add(item, state: boolean?)
		if state ~= nil then
			item.detail = if state then "on" else "off"
			item.current = state
		end
		items[#items + 1] = item
	end
	for i, l in ipairs(LOOKS) do
		add({ label = l.label, group = "Look", icon = "palette", look = i, current = wears(l.layers) })
	end
	local ids = {}
	for id in installed do
		if id ~= tern.plugin.id then
			ids[#ids + 1] = id
		end
	end
	table.sort(ids, function(a, b)
		return installed[a]:lower() < installed[b]:lower()
	end)
	for _, id in ipairs(ids) do
		add({ label = installed[id], group = "Plugins", icon = "puzzle", plugin = id }, not off[id])
	end
	local groups = {}
	for _, t in ipairs(TWEAKS) do
		if t.label and not t.parent then
			if not groups[t.group] then
				groups[t.group] = {}
				groups[#groups + 1] = t.group
			end
			table.insert(groups[t.group], t)
		end
	end
	local function row(t, group, depth)
		local label = string.rep("\u{2003}", depth) .. t.label
		local need = nil
		for _, id in ipairs(t.requires or {}) do
			if not need and not live(by_id[id]) then
				need = by_id[id].label or id
			end
		end
		if need then
			add({ label = label, group = group, tweak = t.id, need = need, detail = "needs " .. need })
		else
			add({ label = label, group = group, tweak = t.id }, on[t.id])
		end
		for _, c in ipairs(children[t.id] or {}) do
			if c.label then
				row(c, group, depth + 1)
			end
		end
	end
	for _, group in ipairs(groups) do
		for _, t in ipairs(groups[group]) do
			row(t, group, 0)
		end
	end
	cx:pick({ items = items, placeholder = "Settings", icon = "sliders", action = "toggle" }):next(function(item, _, again)
		if not item or not again then
			return
		end
		if item.need then
			again:toast("info", "Turn on " .. item.need .. " first")
			return menu(again)
		end
		if item.tweak then
			toggle(again, by_id[item.tweak])
			return menu(again)
		end
		if item.look then
			pick(LOOKS[item.look].layers)
			return menu(again)
		end
		off[item.plugin] = not off[item.plugin]
		local list = {}
		for id, yes in off do
			if yes and id ~= tern.plugin.id then
				list[#list + 1] = id
			end
		end
		table.sort(list)
		tern.kv.set("reopen", { at = os.time(), window = again:window_key() })
		again.settings:set("plugins_disabled", tern.json.array(list))
	end)
end

tern.command({
	id = "menu",
	title = "Settings menu: look, plugins and UI tweaks",
	icon = "sliders",
	keys = { "ctrl+alt+," },
	run = function(cx)
		menu(cx)
	end,
})

tern.timer(0, function(cx)
	local asked = tern.kv.get("reopen")
	if cx and type(asked) == "table" and asked.window == cx:window_key() then
		tern.kv.set("reopen", nil)
		if os.time() - asked.at <= 5 then
			menu(cx)
		end
	end
end)
