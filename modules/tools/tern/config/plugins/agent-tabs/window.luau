--!strict

local KEY = "agent-tabs"
local RELAUNCH = 76
local SHELLS = { sh = true, bash = true, zsh = true, fish = true, dash = true, nu = true, rush = true }
local GONE_MS = 10000
local SETTLE_MS = 15000

type Agent = { command: string, tint: string?, cwd: string? }

local function entries(path: string): { [string]: Agent }
	local agents = {}
	if not tern.fs.exists(path) then
		return agents
	end
	local ok, kv = pcall(function()
		return tern.json.decode(tern.fs.read(path))
	end)
	local found = ok and type(kv) == "table" and kv[KEY]
	if type(found) == "table" then
		for name, agent in pairs(found) do
			if type(name) == "string" and type(agent) == "table" and type(agent.command) == "string" then
				agents[name] = agent
			end
		end
	end
	return agents
end

local function registered(): { [string]: Agent }
	local root = tern.plugin.data .. "/.."
	local agents = {}
	if not tern.fs.exists(root) then
		return agents
	end
	for _, dir in ipairs(tern.fs.list(root)) do
		for name, agent in pairs(entries(root .. "/" .. dir .. "/kv.json")) do
			agents[name] = agent
		end
	end
	return agents
end

local function launch(agent: Agent): Launch
	return { command = agent.command, cwd = agent.cwd }
end

local function session_names(cx: WindowCx): { [number]: string }
	local names = {}
	for _, s in ipairs(cx.session:sessions()) do
		names[s.id] = s.name
	end
	return names
end

local function idle_shell(pane: PaneInfo?): boolean
	if not pane or pane.kind ~= "terminal" or pane.busy or pane.running or pane.exited ~= nil then
		return false
	end
	local program = (pane.program or ""):gsub("^%-", ""):match("[^/]*$")
	return pane.at_prompt == true or SHELLS[program] == true
end

local last: { [string]: number } = {}
local COOLDOWN_MS = 5000

local function relaunchable(pane: PaneInfo?): boolean
	if not pane then
		return false
	end
	return pane.exited == RELAUNCH or idle_shell(pane)
end

local function relaunch(cx: WindowCx, pane: number, name: string, agent: Agent)
	local now = tern.now()
	if last[name] and now - last[name] < COOLDOWN_MS then
		return
	end
	last[name] = now
	local new = cx.layout:split(pane, "right", launch(agent))
	if not new then
		cx:toast("error", "Could not reopen " .. name)
		return
	end
	cx.layout:close(pane)
	local tab = cx.session:tab_of(new)
	if tab and agent.tint then
		cx.layout:color_tab(tab, agent.tint :: any)
	end
end

local function restore(cx: WindowCx, reopen: boolean)
	local saved = tern.kv.get("open") or {}
	local agents = registered()
	for _, s in ipairs(cx.session:sessions()) do
		local want = saved[s.name]
		if want then
			local tabs = {}
			for _, tab in ipairs(cx.session:tabs()) do
				if tab.session == s.id and tab.name then
					tabs[tab.name] = tab
				end
			end
			local order = {}
			for name, position in pairs(want) do
				if agents[name] then
					order[#order + 1] = { name = name, position = position }
				end
			end
			table.sort(order, function(a, b)
				return a.position < b.position
			end)
			for _, entry in ipairs(order) do
				local agent = agents[entry.name]
				local tab = tabs[entry.name]
				if tab then
					if tab.panes == 1 and relaunchable(cx.session:pane(tab.pane)) then
						relaunch(cx, tab.pane, entry.name, agent)
					end
				elseif reopen and s.current then
					local id = cx.layout:new_tab(launch(agent), { focus = false })
					local new = id and (cx.session:tab_of(id) or id)
					if new then
						cx.layout:name_tab(new, entry.name)
						if agent.tint then
							cx.layout:color_tab(new, agent.tint :: any)
						end
						cx.layout:order_tab(new, entry.position)
					end
				end
			end
		end
	end
end

local gone: { [string]: number } = {}
local seen: WindowCx? = nil

local function remember(cx: WindowCx)
	local agents = registered()
	local sessions = session_names(cx)
	local present = {}
	for _, tab in ipairs(cx.session:tabs()) do
		local session = sessions[tab.session]
		if session and tab.name and agents[tab.name] then
			present[session] = present[session] or {}
			present[session][tab.name] = tab.position
		end
	end
	local saved = tern.kv.get("open") or {}
	local changed = false
	local now = tern.now()
	for _, session in pairs(sessions) do
		local want = saved[session] or {}
		local have = present[session] or {}
		for name, position in pairs(have) do
			gone[session .. "/" .. name] = nil
			if want[name] ~= position then
				want[name] = position
				changed = true
			end
		end
		for name in pairs(want) do
			local key = session .. "/" .. name
			if not have[name] then
				gone[key] = gone[key] or now
				if now - gone[key] >= GONE_MS then
					want[name] = nil
					gone[key] = nil
					changed = true
				end
			end
		end
		saved[session] = next(want) and want or nil
	end
	if changed then
		tern.kv.set("open", saved)
	end
end

local function relaunch_exited(cx: WindowCx)
	local agents = registered()
	local names = {}
	for _, tab in ipairs(cx.session:tabs()) do
		names[tab.id] = tab.name
	end
	for _, pane in ipairs(cx.session:panes()) do
		local name = pane.exited == RELAUNCH and pane.tab and names[pane.tab]
		if name and agents[name] then
			relaunch(cx, pane.pane, name, agents[name])
		end
	end
end

local started = 0

local function sync(_ev: any, cx: WindowCx)
	seen = cx
	relaunch_exited(cx)
	if tern.now() - started < SETTLE_MS then
		restore(cx, false)
	end
	remember(cx)
end

local function keep(cx: WindowCx)
	local focused = cx.session:focused()
	local pane = focused and cx.session:pane(focused)
	local id = focused and cx.session:tab_of(focused)
	local tab
	for _, t in ipairs(cx.session:tabs()) do
		if t.id == id then
			tab = t
		end
	end
	if not (pane and tab and tab.name) then
		cx:toast("error", "Name the tab first, then keep it")
		return
	end
	local name = tab.name
	local guess = pane.running and pane.running.line or pane.program or ""
	cx:prompt({ value = guess, placeholder = "Command that starts " .. name, icon = "sparkle", action = "keep" }):next(function(line, _, cx2)
		line = line and line:match("^%s*(.-)%s*$")
		if not line or line == "" or not cx2 then
			return
		end
		local own = tern.kv.get(KEY) or {}
		own[name] = { command = line, tint = tab.color, cwd = pane.cwd ~= "" and pane.cwd or nil }
		tern.kv.set(KEY, own)
		remember(cx2)
		cx2:toast("info", "Keeping " .. name)
	end)
end

local function forget(cx: WindowCx)
	local items = {}
	for name, agent in pairs(tern.kv.get(KEY) or {}) do
		items[#items + 1] = { label = name, detail = agent.command, icon = "trash", name = name }
	end
	if #items == 0 then
		cx:toast("info", "No tabs kept here; plugins that register their own tabs manage them")
		return
	end
	cx:pick({ items = items, placeholder = "Forget which tab?", icon = "trash", action = "forget" }):next(function(item, _, cx2)
		if not item or not cx2 then
			return
		end
		local own = tern.kv.get(KEY) or {}
		own[item.name] = nil
		tern.kv.set(KEY, own)
		cx2:toast("info", "Forgot " .. item.name)
	end)
end

tern.command({ id = "keep", title = "Agent tabs: Keep this tab", icon = "sparkle", run = keep })
tern.command({ id = "forget", title = "Agent tabs: Forget a tab", icon = "trash", run = forget })

for _, event in ipairs({ "focus", "pane_created", "pane_closed", "tab_created", "tab_closed", "title", "agent_state", "cwd", "command_finished", "agent_finished" }) do
	tern.on(event, sync)
end

local POLL_MS = 2000

local function tick(cx: WindowCx?)
	seen = cx or seen
	tern.timer(POLL_MS, tick)
	if seen then
		pcall(sync, nil, seen)
	end
end

tern.timer(0, tick)

tern.on("window_start", function(cx: WindowCx)
	started = tern.now()
	restore(cx, true)
	remember(cx)
end)
