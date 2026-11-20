local STATE_ROOT = tern.getenv("OMP_BOT_STATE")
	or ((tern.getenv("XDG_STATE_HOME") or ((tern.getenv("HOME") or "") .. "/.local/state")) .. "/omp-bot")
local ROSTER_PATH = STATE_ROOT .. "/bots.json"
local ROSTER_TTL_MS = 10000
local INSPECTOR_KIND = "right-rail.inspector"
local INSPECTOR_RATIO = 0.21

local inspector_pane = nil
local last_target_pane = nil
local last_encoded = ""
local sync_seq = 0
local debounce_timer = nil
local roster_cache = {}
local roster_at = 0

local function expand_home(p)
	if type(p) ~= "string" then
		return ""
	end
	local home = tern.getenv("HOME") or ""
	if p == "~" then
		return home
	end
	if p:sub(1, 2) == "~/" then
		return home .. p:sub(2)
	end
	return p
end

local function load_roster(force)
	local now = tern.now()
	if not force and roster_at > 0 and (now - roster_at) < ROSTER_TTL_MS then
		return roster_cache
	end
	roster_at = now
	local map = {}
	if tern.fs.exists(ROSTER_PATH) then
		local ok_r, raw = pcall(tern.fs.read, ROSTER_PATH, 262144)
		if ok_r and type(raw) == "string" and raw ~= "" then
			local ok_d, list = pcall(tern.json.decode, raw)
			if ok_d and type(list) == "table" then
				for _, bot in ipairs(list) do
					if type(bot) == "table" and type(bot.name) == "string" and bot.name ~= "" then
						map[bot.name] = {
							name = bot.name,
							tint = bot.tint,
							cwd = expand_home(bot.cwd or "~"),
							box = bot.box == true,
						}
					end
				end
			end
		end
	end
	roster_cache = map
	return roster_cache
end

local function is_inspector_pane_info(info)
	if type(info) ~= "table" then
		return false
	end
	if inspector_pane ~= nil and info.pane == inspector_pane then
		return true
	end
	if info.kind == "plugin" and type(info.title) == "string" then
		if info.title == "Inspector" or info.title:sub(-12) == "· Inspector" then
			return true
		end
	end
	return false
end

local function find_inspector(cx)
	if inspector_pane ~= nil then
		local info = cx.session:pane(inspector_pane)
		if info then
			return inspector_pane
		end
		inspector_pane = nil
	end
	for _, p in ipairs(cx.session:panes()) do
		if is_inspector_pane_info(p) then
			inspector_pane = p.pane
			return inspector_pane
		end
	end
	return nil
end

local function resolve_target_pane(cx)
	local focused = cx.session:focused()
	if focused then
		local info = cx.session:pane(focused)
		if info and not is_inspector_pane_info(info) then
			last_target_pane = focused
			return focused
		end
	end
	if last_target_pane then
		local info = cx.session:pane(last_target_pane)
		if info and not is_inspector_pane_info(info) then
			return last_target_pane
		end
	end
	for _, p in ipairs(cx.session:panes()) do
		if not is_inspector_pane_info(p) then
			last_target_pane = p.pane
			return p.pane
		end
	end
	return nil
end

local function build_snapshot(cx, target_id)
	local roster = load_roster(false)
	local info = target_id and cx.session:pane(target_id) or nil
	local tab_id = target_id and cx.session:tab_of(target_id) or nil
	local tabs_raw = cx.session:tabs()
	local tab_info = nil
	local tabs_out = {}

	for _, t in ipairs(tabs_raw) do
		if t.id == tab_id then
			tab_info = t
		end
		local is_bot = t.name ~= nil and roster[t.name] ~= nil
		tabs_out[#tabs_out + 1] = {
			id = t.id,
			pane = t.pane,
			name = t.name or "",
			program = t.program or "",
			cwd = t.cwd or "",
			busy = t.busy == true,
			active = t.id == tab_id,
			is_bot = is_bot,
		}
	end

	local bot_entry = nil
	if tab_info and tab_info.name and roster[tab_info.name] then
		bot_entry = roster[tab_info.name]
	elseif info and info.kind == "agent" and type(info.title) == "string" and roster[info.title] then
		bot_entry = roster[info.title]
	end

	local cwd = (info and info.cwd and info.cwd ~= "" and info.cwd)
		or (tab_info and tab_info.cwd and tab_info.cwd ~= "" and tab_info.cwd)
		or (bot_entry and bot_entry.cwd)
		or ""

	return {
		mode = bot_entry and "bot" or "terminal",
		bot = bot_entry and bot_entry.name or "",
		bot_tint = bot_entry and bot_entry.tint or "",
		bot_box = bot_entry and bot_entry.box == true or false,
		pane = target_id or 0,
		tab = tab_id or 0,
		tab_name = tab_info and tab_info.name or "",
		title = info and info.title or "",
		program = (info and info.program) or (tab_info and tab_info.program) or "",
		kind = info and info.kind or "terminal",
		cwd = cwd,
		busy = (info and info.busy == true) or (tab_info and tab_info.busy == true),
		tabs = tabs_out,
	}
end

local function push_context(cx, force)
	local target = resolve_target_pane(cx)
	local snap = build_snapshot(cx, target)
	local encoded = tern.json.encode(snap)
	if force or encoded ~= last_encoded then
		last_encoded = encoded
		sync_seq = sync_seq + 1
		snap.seq = sync_seq
		pcall(tern.kv.set, "context", snap)
		local pane_id = find_inspector(cx)
		if pane_id then
			pcall(function()
				cx.session:event(pane_id, { ev = "action", id = "sync", act = "sync" })
			end)
		end
	end
end

local function schedule_sync(cx, force)
	if debounce_timer then
		debounce_timer:cancel()
		debounce_timer = nil
	end
	if force then
		push_context(cx, true)
		return
	end
	debounce_timer = tern.timer(90, function(cx2)
		debounce_timer = nil
		if cx2 then
			push_context(cx2, false)
		end
	end)
end

local function follow_tab(cx, target_tab)
	local pane_id = find_inspector(cx)
	if not pane_id or not target_tab then
		return
	end
	local insp_tab = cx.session:tab_of(pane_id)
	if insp_tab and insp_tab ~= target_tab then
		pcall(function()
			cx.layout:move_to_tab(pane_id, target_tab, { focus = false })
		end)
	end
end

local function toggle_inspector(cx)
	local existing = find_inspector(cx)
	if existing then
		inspector_pane = nil
		pcall(function()
			cx.layout:close(existing)
		end)
		tern.chrome.refresh()
		return
	end
	local target = resolve_target_pane(cx)
	if not target then
		cx:toast("error", "Right Inspector: no active pane to inspect")
		return
	end
	push_context(cx, true)
	local created = cx:new_block(INSPECTOR_KIND, {}, "beside", {
		focus = false,
		target = target,
		dir = "right",
		ratio = INSPECTOR_RATIO,
	})
	if not created then
		cx:toast("error", "Right Inspector: could not open inspector block")
		return
	end
	inspector_pane = created
	push_context(cx, true)
	tern.chrome.refresh()
end

tern.chrome.widget("inspector", {
	name = "Inspector",
	description = "Toggle the Grokbot-style right inspector pane",
	icon = "dock-right",
	styles = { "text" },
	render = function(_pane)
		local open = inspector_pane ~= nil
		return {
			text = open and "Inspector" or "Inspect",
			icon = "dock-right",
			tone = open and "accent" or "muted",
			title = open and "Hide Right Inspector (Ctrl+Alt+I)" or "Show Right Inspector (Ctrl+Alt+I)",
			command = "plugin.right-rail.toggle",
		}
	end,
})

tern.chrome.status(function(_pane)
	local open = inspector_pane ~= nil
	return {
		{
			text = open and "Inspector" or "Inspect",
			icon = "dock-right",
			tone = open and "accent" or "muted",
			command = "plugin.right-rail.toggle",
		},
	}
end)

tern.command({
	id = "toggle",
	title = "Toggle Right Inspector",
	icon = "dock-right",
	keys = { "ctrl+alt+i" },
	run = function(cx)
		toggle_inspector(cx)
	end,
})

tern.command({
	id = "refresh",
	title = "Refresh Right Inspector",
	icon = "fetch",
	run = function(cx)
		load_roster(true)
		push_context(cx, true)
		local pane_id = find_inspector(cx)
		if pane_id then
			pcall(function()
				cx.session:event(pane_id, { ev = "action", id = "refresh", act = "refresh" })
			end)
		end
	end,
})

tern.bind("ctrl+alt+i", "plugin.right-rail.toggle")

tern.on("window_start", function(cx)
	load_roster(true)
	find_inspector(cx)
	push_context(cx, true)
	tern.chrome.refresh()
end)

tern.on("focus", function(ev, cx)
	local info = ev and ev.pane and cx.session:pane(ev.pane) or nil
	if info and is_inspector_pane_info(info) then
		inspector_pane = ev.pane
		return
	end
	if ev and ev.pane then
		last_target_pane = ev.pane
	end
	if ev and ev.tab then
		follow_tab(cx, ev.tab)
	end
	if find_inspector(cx) then
		schedule_sync(cx, false)
	end
end)

tern.on("cwd", function(_ev, cx)
	if find_inspector(cx) then
		schedule_sync(cx, false)
	end
end)

tern.on("title", function(_ev, cx)
	if find_inspector(cx) then
		schedule_sync(cx, false)
	end
end)

tern.on("agent_state", function(_ev, cx)
	if find_inspector(cx) then
		schedule_sync(cx, false)
	end
end)

tern.on("agent_finished", function(_ev, cx)
	if find_inspector(cx) then
		schedule_sync(cx, true)
	end
end)

tern.on("command_finished", function(_ev, cx)
	if find_inspector(cx) then
		schedule_sync(cx, false)
	end
end)

tern.on("tab_created", function(_ev, cx)
	if find_inspector(cx) then
		schedule_sync(cx, false)
	end
end)

tern.on("tab_closed", function(_ev, cx)
	if find_inspector(cx) then
		schedule_sync(cx, false)
	end
end)

tern.on("pane_closed", function(ev, cx)
	if ev and ev.pane and inspector_pane == ev.pane then
		inspector_pane = nil
		tern.chrome.refresh()
		return
	end
	if ev and ev.pane and last_target_pane == ev.pane then
		last_target_pane = nil
	end
	if find_inspector(cx) then
		schedule_sync(cx, false)
	end
end)

tern.on("unload", function()
	if debounce_timer then
		debounce_timer:cancel()
		debounce_timer = nil
	end
	inspector_pane = nil
	last_target_pane = nil
	pcall(tern.chrome.widget, "inspector", nil)
end)
