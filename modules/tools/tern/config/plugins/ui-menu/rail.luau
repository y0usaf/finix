local on: { [string]: boolean } = {}

local MARKED = { "rail_sections", "rail_status", "rail_ages", "rail_compact" }

local function enabled(): boolean
	for _, id in ipairs(MARKED) do
		if on[id] then
			return true
		end
	end
	return false
end

local COLORS = { "red", "orange", "yellow", "green", "teal", "blue", "purple", "pink" }
local SHELLS = { zsh = true, bash = true, fish = true, nu = true, sh = true, dash = true, ksh = true }
local SECTIONS = { "pinned", "needs", "working", "idle" }
local SECTION_MARK = { pinned = "\u{2061}", needs = "\u{2062}", working = "\u{2063}", idle = "\u{2064}" }
local STATUS_MARK = {
	working = "\u{206A}",
	input = "\u{206B}",
	completed = "\u{206C}",
	failed = "\u{206D}",
	idle = "\u{206E}",
}
local AGE_BASE = 0xE0100
local AGE_TICK_MS = 30000


local color_at = 0
local agent_state: { [number]: string } = {}
local unseen: { [number]: string } = {}
local since: { [number]: number } = {}
local marks: { [number]: string } = {}

local function age_slots(): { string }
	local labels = { "now" }
	for m = 1, 59 do
		labels[#labels + 1] = m .. "m"
	end
	for h = 1, 23 do
		labels[#labels + 1] = h .. "h"
	end
	for d = 1, 30 do
		labels[#labels + 1] = d .. "d"
	end
	return labels
end

local AGES = age_slots()

local function age_index(seconds: number): number
	local minutes = math.floor(seconds / 60)
	if minutes < 60 then
		return minutes
	end
	local hours = math.floor(minutes / 60)
	if hours < 24 then
		return 59 + hours
	end
	return 82 + math.min(math.floor(hours / 24), 30)
end

local function age_css(): string
	local rules = {}
	local row = "html.lay-rail.tabs-h .tb-tabs .tt"
	for i, label in ipairs(AGES) do
		local mark = '[title*="\\' .. string.format("%X", AGE_BASE + i - 1) .. '"]'
		rules[#rules + 1] = row .. '[title*="\\206A"]' .. mark .. ' .sub::before { content: "Working · ' .. label .. '" !important; }'
		rules[#rules + 1] = row .. ':not([title*="\\206A"])' .. mark .. ' .mk::before { content: "' .. label .. '" !important; }'
	end
	return table.concat(rules, "\n")
end

local function id_list(key: string): { number }
	local saved = tern.kv.get(key)
	local list = {}
	if type(saved) == "table" then
		for _, id in ipairs(saved) do
			if type(id) == "number" then
				list[#list + 1] = id
			end
		end
	end
	return list
end

local function toggle(key: string, id: number): boolean
	local kept = {}
	local had = false
	for _, other in ipairs(id_list(key)) do
		if other == id then
			had = true
		else
			kept[#kept + 1] = other
		end
	end
	if not had then
		kept[#kept + 1] = id
	end
	tern.kv.set(key, tern.json.array(kept))
	return not had
end

local function save_map(key: string, map: { [number]: any })
	local saved = {}
	for pane, value in map do
		saved[tostring(pane)] = value
	end
	tern.kv.set(key, saved)
end

local function load_map(key: string, kind: string): { [number]: any }
	local map = {}
	local saved = tern.kv.get(key)
	if type(saved) == "table" then
		for pane, value in saved do
			local id = tonumber(pane)
			if id and type(value) == kind then
				map[id] = value
			end
		end
	end
	return map
end

local function focused_tab(cx): number?
	local pane = cx.session:focused()
	return pane and cx.session:tab_of(pane) or nil
end

local function load(cx)
	unseen = load_map("rail_unseen", "string")
	since = load_map("rail_since", "number")
	agent_state = {}
	local ok, list = pcall(function()
		return cx.agents:list()
	end)
	if ok then
		for _, agent in ipairs(list) do
			agent_state[agent.pane] = agent.state
		end
	end
end

local function prune(cx)
	local focused = focused_tab(cx)
	local live = {}
	for _, pane in ipairs(cx.session:panes()) do
		live[pane.pane] = pane.tab
	end
	local changed = false
	for pane in unseen do
		if live[pane] == nil or live[pane] == focused then
			unseen[pane] = nil
			changed = true
		end
	end
	if changed then
		save_map("rail_unseen", unseen)
	end
	changed = false
	for pane in since do
		if live[pane] == nil then
			since[pane] = nil
			changed = true
		end
	end
	if changed then
		save_map("rail_since", since)
	end
	local tabs = {}
	for _, tab in ipairs(cx.session:tabs()) do
		tabs[tab.id] = true
	end
	local pins = id_list("rail_pins")
	local kept = {}
	for _, id in ipairs(pins) do
		if tabs[id] then
			kept[#kept + 1] = id
		end
	end
	if #kept ~= #pins then
		tern.kv.set("rail_pins", tern.json.array(kept))
	end
end

local function tab_view(cx, tab: TabInfo): (string, number?)
	local working, input, completed, failed = tab.busy, false, false, false
	local stamp: number? = nil
	for _, pane in ipairs(cx.session:panes()) do
		if pane.tab == tab.id then
			local state = agent_state[pane.pane]
			if state == "working" then
				working = true
			elseif state == "waiting_input" then
				input = true
			end
			if unseen[pane.pane] == "failed" then
				failed = true
			elseif unseen[pane.pane] == "done" then
				completed = true
			end
			local at = since[pane.pane]
			if at and (not stamp or at > stamp) then
				stamp = at
			end
		end
	end
	local status = if input
		then "input"
		elseif working then "working"
		elseif failed then "failed"
		elseif completed then "completed"
		else "idle"
	return status, stamp
end

local function arrange(cx)
	prune(cx)
	local pins = {}
	for _, id in ipairs(id_list("rail_pins")) do
		pins[id] = true
	end
	local rank = {}
	for i, name in ipairs(SECTIONS) do
		rank[name] = i
	end
	local now = os.time()
	local sessions: { [number]: { { tab: TabInfo, section: string } } } = {}
	marks = {}
	for _, tab in ipairs(cx.session:tabs()) do
		local status, stamp = tab_view(cx, tab)
		local section = if not on.rail_sections
			then "idle"
			elseif pins[tab.id]
			then "pinned"
			elseif status == "input" then "needs"
			elseif status == "working" then "working"
			else "idle"
		local age = if stamp then utf8.char(AGE_BASE + age_index(math.max(0, now - stamp))) else ""
		marks[tab.id] = SECTION_MARK[section] .. STATUS_MARK[if on.rail_status then status else "idle"] .. age
		local list = sessions[tab.session] or {}
		sessions[tab.session] = list
		list[#list + 1] = { tab = tab, section = section }
	end
	for _, list in sessions do
		table.sort(list, function(a, b)
			if a.section ~= b.section then
				return rank[a.section] < rank[b.section]
			end
			return a.tab.position < b.tab.position
		end)
		if on.rail_sections then
			for position, entry in ipairs(list) do
				if entry.tab.position ~= position then
					cx.layout:order_tab(entry.tab.id, position)
				end
			end
		end
	end
	tern.chrome.refresh()
end

local function tick(cx)
	if cx and enabled() then
		arrange(cx)
	end
	tern.timer(AGE_TICK_MS, tick)
end

local function apply(cx)
	if enabled() then
		load(cx)
		arrange(cx)
	else
		marks = {}
		tern.chrome.refresh()
	end
end

tern.on("window_start", function(cx)
	apply(cx)
end)

tern.timer(0, function(cx)
	if cx and enabled() then
		load(cx)
	end
	tick(cx)
end)

for _, name in ipairs({ "tab_created", "tab_closed", "pane_closed", "command_started", "command_finished", "focus" }) do
	tern.on(name, function(_, cx)
		if enabled() then
			arrange(cx)
		end
	end)
end

tern.on("agent_state", function(ev: AgentStateEvent, cx)
	if not enabled() then
		return
	end
	agent_state[ev.pane] = ev.new
	if ev.old ~= ev.new then
		since[ev.pane] = os.time()
		save_map("rail_since", since)
	end
	if ev.new == "working" and unseen[ev.pane] then
		unseen[ev.pane] = nil
		save_map("rail_unseen", unseen)
	end
	arrange(cx)
end)

tern.on("agent_finished", function(ev: AgentFinishedEvent, cx)
	if not enabled() then
		return
	end
	if ev.result == "closed" or ev.result == "exited" then
		unseen[ev.pane] = nil
		agent_state[ev.pane] = nil
	elseif cx.session:tab_of(ev.pane) ~= focused_tab(cx) then
		unseen[ev.pane] = ev.result
	end
	since[ev.pane] = os.time()
	save_map("rail_since", since)
	save_map("rail_unseen", unseen)
	arrange(cx)
end)

local function strip_icon(title: string): string
	local ok, first = pcall(utf8.codepoint, title, 1)
	if ok and first and ((first >= 0xE000 and first <= 0xF8FF) or first >= 0xF0000) then
		local rest = utf8.offset(title, 2) or #title + 1
		return (title:sub(rest):gsub("^%s+", ""))
	end
	return title
end

tern.chrome.tab_title(function(tab)
	if not enabled() then
		return nil
	end
	local title = tab.name
	if not title or title == "" then
		title = strip_icon(tab.title or "")
		if SHELLS[tab.program] then
			title = title:gsub("^[^%s:]+@[^%s:]+:%s*", "")
		end
		if title == "" then
			local cwd = tab.cwd or ""
			title = cwd:match("([^/]+)/*$") or cwd
		end
	end
	return (marks[tab.id] or "") .. title
end)

tern.command({
	id = "pin",
	title = "Sidebar: Pin or unpin this tab",
	icon = "pin",
	run = function(cx)
		local tab = focused_tab(cx)
		if tab and on.rail_sections then
			cx:toast("info", toggle("rail_pins", tab) and "Pinned" or "Unpinned")
			arrange(cx)
		end
	end,
})

tern.command({
	id = "colour",
	title = "Sidebar: Colour this tab",
	icon = "palette",
	run = function(cx)
		local tab = focused_tab(cx)
		if tab then
			color_at = color_at % #COLORS + 1
			cx.layout:color_tab(tab, COLORS[color_at])
		end
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

tern.bind("ctrl+alt+p", "plugin.ui-menu.pin")
tern.bind("ctrl+alt+j", "next_tab")
tern.bind("ctrl+alt+k", "previous_tab")
tern.bind("ctrl+alt+f", "focus_tabs")

return {
	tweaks = {
		{
			id = "rail_sections",
			label = "sections: pinned, needs you, working, idle",
			group = "Rail",
			css = [[
html.lay-rail.tabs-h .tb-tabs .tt {
	position: relative;
	overflow: visible !important;
}

html.lay-rail.tabs-h .tb-tabs .tt::before,
html.lay-rail.tabs-h .tb-tabs .tt::after {
	display: none !important;
}

html.lay-rail.tabs-h .tb-tabs .tt[title^="\2061"]:first-child,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2061"]) + .tt[title^="\2061"],
html.lay-rail.tabs-h .tb-tabs .tt[title^="\2062"]:first-child,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2062"]) + .tt[title^="\2062"],
html.lay-rail.tabs-h .tb-tabs .tt[title^="\2063"]:first-child,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2063"]) + .tt[title^="\2063"],
html.lay-rail.tabs-h .tb-tabs .tt[title^="\2064"]:first-child,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2064"]) + .tt[title^="\2064"] {
	margin-top: 34px !important;
}

html.lay-rail.tabs-h .tb-tabs .tt[title^="\2061"]:first-child::after,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2061"]) + .tt[title^="\2061"]::after,
html.lay-rail.tabs-h .tb-tabs .tt[title^="\2062"]:first-child::after,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2062"]) + .tt[title^="\2062"]::after,
html.lay-rail.tabs-h .tb-tabs .tt[title^="\2063"]:first-child::after,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2063"]) + .tt[title^="\2063"]::after,
html.lay-rail.tabs-h .tb-tabs .tt[title^="\2064"]:first-child::after,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2064"]) + .tt[title^="\2064"]::after {
	display: block !important;
	position: absolute;
	left: 10px;
	top: -26px;
	width: auto;
	height: auto;
	background: none;
	box-shadow: none;
	font-size: 11px;
	font-weight: 600;
	letter-spacing: 0.06em;
	text-transform: uppercase;
	color: var(--t4);
	pointer-events: none;
}

html.lay-rail.tabs-h .tb-tabs .tt[title^="\2061"]:first-child::after,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2061"]) + .tt[title^="\2061"]::after {
	content: "Pinned";
}

html.lay-rail.tabs-h .tb-tabs .tt[title^="\2062"]:first-child::after,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2062"]) + .tt[title^="\2062"]::after {
	content: "Needs you";
}

html.lay-rail.tabs-h .tb-tabs .tt[title^="\2063"]:first-child::after,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2063"]) + .tt[title^="\2063"]::after {
	content: "Working";
}

html.lay-rail.tabs-h .tb-tabs .tt[title^="\2064"]:first-child::after,
html.lay-rail.tabs-h .tb-tabs .tt:not([title^="\2064"]) + .tt[title^="\2064"]::after {
	content: "Idle";
}
]],
			apply = apply,
			on = true,
		},
		{
			id = "rail_status",
			label = "status rings and lines",
			group = "Rail",
			css = [[
html.lay-rail.tabs-h .tb-tabs .tt .tn-dk::before,
html.lay-rail.tabs-h .tb-tabs .tt .tn-dk::after {
	display: none !important;
}

html.lay-rail.tabs-h .tb-tabs .tt .tn-dk-c {
	position: relative;
	overflow: visible !important;
}

html.lay-rail.tabs-h .tb-tabs .tt:is([title*="\206A"], [title*="\206B"], [title*="\206C"], [title*="\206D"]) .tn-dk-c::before {
	content: "";
	position: absolute;
	box-sizing: border-box;
	border-radius: 50%;
	pointer-events: none;
}

html.lay-rail.tabs-h .tb-tabs .tt[title*="\206A"] .tn-dk-c::before {
	left: -4px;
	top: -4px;
	width: calc(100% + 8px);
	height: calc(100% + 8px);
	border: 2px dashed var(--pill);
	animation: arc-spin 2.4s linear infinite;
}

html.lay-rail.tabs-h .tb-tabs .tt:is([title*="\206B"], [title*="\206C"], [title*="\206D"]) .tn-dk-c::before {
	right: -3px;
	bottom: -3px;
	width: 10px;
	height: 10px;
	background: var(--pill);
	box-shadow: 0 0 0 2px var(--panel);
}

html.lay-rail.tabs-h .tb-tabs .tt:is([title*="\206A"], [title*="\206B"], [title*="\206C"], [title*="\206D"]) .sub {
	font-size: 0 !important;
}

html.lay-rail.tabs-h .tb-tabs .tt:is([title*="\206A"], [title*="\206B"], [title*="\206C"], [title*="\206D"]) .sub::before {
	font-size: 12px;
	font-weight: 500;
	font-family: Geist, system-ui, sans-serif;
	color: var(--pill);
}

html.lay-rail.tabs-h .tb-tabs .tt[title*="\206A"] {
	--pill: light-dark(#0f766e, #5eead4);
}

html.lay-rail.tabs-h .tb-tabs .tt[title*="\206A"] .sub::before {
	content: "Working";
}

html.lay-rail.tabs-h .tb-tabs .tt[title*="\206B"] {
	--pill: light-dark(#b45309, #fbbf24);
}

html.lay-rail.tabs-h .tb-tabs .tt[title*="\206B"] .sub::before {
	content: "Awaiting input";
}

html.lay-rail.tabs-h .tb-tabs .tt[title*="\206C"] {
	--pill: light-dark(#15803d, #4ade80);
}

html.lay-rail.tabs-h .tb-tabs .tt[title*="\206C"] .sub::before {
	content: "Done · unseen";
}

html.lay-rail.tabs-h .tb-tabs .tt[title*="\206D"] {
	--pill: light-dark(#b91c1c, #f87171);
}

html.lay-rail.tabs-h .tb-tabs .tt[title*="\206D"] .sub::before {
	content: "Failed · unseen";
}

@keyframes arc-spin {
	from {
		transform: rotate(0deg);
	}
	to {
		transform: rotate(360deg);
	}
}

html.lay-rail.tabs-h .tb-tabs .tt .tn-dk-c::after {
	display: none !important;
}

html.lay-rail.tabs-h .tb-tabs .tt:is([title*="\206A"], [title*="\206B"], [title*="\206C"], [title*="\206D"]) .sub > * {
	display: none !important;
}

html.lay-rail.tabs-h .tb-tabs .tt .sub::after {
	display: none !important;
}
]],
			apply = apply,
			on = true,
		},
		{
			id = "rail_ages",
			label = "ages",
			group = "Rail",
			css = [[
html.lay-rail.tabs-h .tb-tabs .tt .mk .hint {
	display: none !important;
}

html.lay-rail.tabs-h .tb-tabs .tt .mk {
	flex: none !important;
}

html.lay-rail.tabs-h .tb-tabs .tt .mk::before {
	font-size: 11px;
	color: var(--t4);
	font-family: Geist, system-ui, sans-serif;
}
]] .. "\n" .. age_css(),
			apply = apply,
			on = true,
		},
		{
			id = "rail_compact",
			label = "one-line idle rows",
			group = "Rail",
			css = [[
html.lay-rail.tabs-h .tb-tabs .tt {
	height: 38px !important;
}

html.lay-rail.tabs-h .tb-tabs .tt[title*="\206E"] {
	height: 20px !important;
}

html.lay-rail.tabs-h .tb-tabs .tt[title*="\206E"] .sub {
	display: none !important;
}
]],
			apply = apply,
			on = true,
		},
		{
			id = "rail_card",
			label = "selected tab card",
			group = "Rail",
			css = [[
html.lay-rail.tabs-h .tb-tabs .tt {
	border-radius: 8px !important;
	box-shadow: none !important;
	color: var(--t3) !important;
}

html.lay-rail.tabs-h .tb-tabs .tt:hover {
	background: color-mix(in srgb, var(--t1) 6%, transparent) !important;
}

html.lay-rail.tabs-h .tb-tabs .tt.on {
	background: var(--panel) !important;
	box-shadow: inset 0 0 0 1px var(--l2) !important;
	color: var(--t1) !important;
}

html.lay-rail.tabs-h .tb-tabs .tt.on .nm {
	font-weight: 600;
}

html.lay-rail.tabs-h .tb-tabs .tt.on::before,
html.lay-rail.tabs-h .tb-tabs .tt.on::after {
	display: none !important;
}
]],
			on = true,
		},
		{
			id = "rail_header",
			label = "+ and bell in the header",
			group = "Rail",
			css = [[
html.lay-rail.tabs-h #tabbar .tb-in {
	position: relative !important;
}

html.lay-rail.tabs-h #tabbar .tb-in > .tb-add,
html.lay-rail.tabs-h #tabbar .tb-in > .tn-ib-badge {
	position: absolute !important;
	top: 4px !important;
	width: 28px !important;
	height: 26px !important;
	margin: 0 !important;
	padding: 0 !important;
	justify-content: center !important;
	gap: 0 !important;
	border-radius: 7px !important;
}

html.lay-rail.tabs-h #tabbar .tb-in > .tb-add {
	right: 40px !important;
}

html.lay-rail.tabs-h #tabbar .tb-in > .tn-ib-badge {
	right: 8px !important;
}

html.lay-rail.tabs-h #tabbar .tb-in > :is(.tb-add, .tn-ib-badge) :is(.lbl, .kbds) {
	display: none !important;
}

html.lay-rail.tabs-h #tabbar .tb-in > .tn-ib-badge .tn-ib-pip {
	position: absolute !important;
	top: 1px !important;
	right: 1px !important;
	margin: 0 !important;
	transform: scale(0.8);
}
]],
			on = true,
		},
	},
	bind = function(state: { [string]: boolean })
		on = state
	end,
}
