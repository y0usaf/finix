local ui = tern.ui

local STATE_ROOT = tern.getenv("OMP_BOT_STATE")
	or ((tern.getenv("XDG_STATE_HOME") or ((tern.getenv("HOME") or "") .. "/.local/state")) .. "/omp-bot")

local GIT_COOLDOWN_MS = 1500
local BOT_COOLDOWN_MS = 1500

local active_states = {}

local function with(node, props)
	local p = node.p or {}
	for k, v in pairs(props) do
		p[k] = v
	end
	node.p = p
	return node
end

local function trim(s)
	if type(s) ~= "string" then
		return ""
	end
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function clip(s, max_len)
	local clean = trim((tostring(s or "")):gsub("%s+", " "))
	if #clean <= max_len then
		return clean
	end
	local cut = max_len - 1
	while cut > 0 do
		local b = clean:byte(cut + 1)
		if not b or b < 128 or b >= 192 then
			break
		end
		cut = cut - 1
	end
	return clean:sub(1, cut) .. "…"
end

local function short_path(p)
	if type(p) ~= "string" or p == "" then
		return ""
	end
	local home = tern.getenv("HOME") or ""
	if home ~= "" and p == home then
		return "~"
	end
	if home ~= "" and p:sub(1, #home + 1) == home .. "/" then
		return "~/" .. p:sub(#home + 2)
	end
	return p
end

local function safe_read_json(path, max_bytes)
	if not tern.fs.exists(path) then
		return nil
	end
	local ok_r, raw = pcall(tern.fs.read, path, max_bytes)
	if not ok_r or type(raw) ~= "string" or raw == "" then
		return nil
	end
	local ok_d, val = pcall(tern.json.decode, raw)
	if not ok_d then
		return nil
	end
	return val
end

local function extract_text(content)
	if type(content) == "string" then
		return content
	end
	if type(content) ~= "table" then
		return ""
	end
	local parts = {}
	for _, block in ipairs(content) do
		if type(block) == "table" then
			if block.type == "text" and type(block.text) == "string" and block.text ~= "" then
				parts[#parts + 1] = block.text
			elseif block.type == "toolCall" and type(block.name) == "string" then
				parts[#parts + 1] = "[" .. block.name .. "]"
			end
		end
	end
	return table.concat(parts, " ")
end

local function parse_turns_jsonl(raw, limit)
	local turns = {}
	if type(raw) ~= "string" or raw == "" then
		return turns
	end
	for line in raw:gmatch("[^\r\n]+") do
		local ok, rec = pcall(tern.json.decode, line)
		if ok and type(rec) == "table" and rec.type == "message" and type(rec.message) == "table" then
			local role = rec.message.role
			if role == "user" or role == "assistant" then
				local txt = extract_text(rec.message.content)
				txt = clip(txt, 140)
				if txt ~= "" then
					local ts = type(rec.timestamp) == "string" and #rec.timestamp >= 16 and rec.timestamp:sub(12, 16) or ""
					turns[#turns + 1] = { role = role, text = txt, time = ts }
				end
			end
		end
	end
	if #turns <= limit then
		return turns
	end
	local sliced = {}
	for i = #turns - limit + 1, #turns do
		sliced[#sliced + 1] = turns[i]
	end
	return sliced
end

local function extract_plain_text(content)
	if type(content) == "string" then
		return content
	end
	if type(content) ~= "table" then
		return ""
	end
	local parts = {}
	for _, block in ipairs(content) do
		if type(block) == "table" and block.type == "text" and type(block.text) == "string" and block.text ~= "" then
			parts[#parts + 1] = block.text
		end
	end
	return table.concat(parts, " ")
end

local function parse_advisor_from_session(raw, limit)
	local notes = {}
	if type(raw) ~= "string" or raw == "" then
		return notes
	end
	for line in raw:gmatch("[^\r\n]+") do
		local ok, rec = pcall(tern.json.decode, line)
		if ok and type(rec) == "table" then
			local txt = ""
			local tag = "advisor"
			local ct = type(rec.customType) == "string" and rec.customType:lower() or ""
			if rec.type == "custom_message" and ct:find("advisor", 1, true) then
				txt = extract_plain_text(rec.content)
			elseif rec.type == "custom" and ct:find("advisor", 1, true) and type(rec.data) == "table" then
				txt = tostring(rec.data.text or rec.data.summary or rec.data.note or rec.data.message or "")
			elseif rec.type == "message" and type(rec.message) == "table" then
				local mct = type(rec.message.customType) == "string" and rec.message.customType:lower() or ""
				if rec.message.role == "advisor" or mct:find("advisor", 1, true) then
					txt = extract_plain_text(rec.message.content)
					if type(rec.message.model) == "string" and rec.message.model ~= "" then
						tag = rec.message.model:match("([^/]+)$") or rec.message.model
					end
				end
			end
			txt = clip(txt, 200)
			if txt ~= "" then
				local ts = type(rec.timestamp) == "string" and #rec.timestamp >= 16 and rec.timestamp:sub(12, 16) or ""
				notes[#notes + 1] = { tag = tag, text = txt, time = ts, full_ts = type(rec.timestamp) == "string" and rec.timestamp or "" }
			end
		end
	end
	if #notes <= limit then
		return notes
	end
	local sliced = {}
	for i = #notes - limit + 1, #notes do
		sliced[#sliced + 1] = notes[i]
	end
	return sliced
end

local function parse_advisor_jsonl(raw, limit)
	local notes = {}
	if type(raw) ~= "string" or raw == "" then
		return notes
	end
	for line in raw:gmatch("[^\r\n]+") do
		local ok, rec = pcall(tern.json.decode, line)
		if ok and type(rec) == "table" and rec.type == "message" and type(rec.message) == "table" and rec.message.role == "assistant" then
			local txt = clip(extract_plain_text(rec.message.content), 200)
			if txt ~= "" then
				local ts = type(rec.timestamp) == "string" and #rec.timestamp >= 16 and rec.timestamp:sub(12, 16) or ""
				local model = type(rec.message.model) == "string" and rec.message.model ~= "" and (rec.message.model:match("([^/]+)$") or rec.message.model) or "advisor"
				notes[#notes + 1] = { tag = model, text = txt, time = ts, full_ts = type(rec.timestamp) == "string" and rec.timestamp or "" }
			end
		end
	end
	if #notes <= limit then
		return notes
	end
	local sliced = {}
	for i = #notes - limit + 1, #notes do
		sliced[#sliced + 1] = notes[i]
	end
	return sliced
end

local function merge_advisor_notes(a, b, limit)
	local combined = {}
	local seen = {}
	for _, list in ipairs({ a or {}, b or {} }) do
		for _, item in ipairs(list) do
			local key = (item.time or "") .. "|" .. (item.text or "")
			if not seen[key] then
				seen[key] = true
				combined[#combined + 1] = item
			end
		end
	end
	table.sort(combined, function(x, y)
		return (x.full_ts or "") < (y.full_ts or "")
	end)
	if #combined <= limit then
		return combined
	end
	local sliced = {}
	for i = #combined - limit + 1, #combined do
		sliced[#sliced + 1] = combined[i]
	end
	return sliced
end

local function parse_peek_jsonl(raw)
	local lines = {}
	if type(raw) ~= "string" or raw == "" then
		return lines
	end
	for line in raw:gmatch("[^\r\n]+") do
		local ok, rec = pcall(tern.json.decode, line)
		if ok and type(rec) == "table" and rec.type == "message" and type(rec.message) == "table" then
			local role = rec.message.role
			local ts = type(rec.timestamp) == "string" and #rec.timestamp >= 16 and rec.timestamp:sub(12, 16) or ""
			if role == "user" or role == "assistant" then
				local txt = clip(extract_text(rec.message.content), 220)
				if txt ~= "" then
					lines[#lines + 1] = { role = role, text = txt, time = ts }
				end
			elseif role == "toolResult" and type(rec.message.toolName) == "string" then
				local err = rec.message.isError == true
				lines[#lines + 1] = {
					role = "tool",
					text = rec.message.toolName .. (err and " (error)" or " (ok)"),
					time = ts,
					err = err,
				}
			end
		end
	end
	if #lines > 18 then
		local out = {}
		for i = #lines - 17, #lines do
			out[#out + 1] = lines[i]
		end
		return out
	end
	return lines
end

local function load_work_items(bot_dir)
	local out = {}
	local data = safe_read_json(bot_dir .. "/work.json", 262144)
	if type(data) ~= "table" then
		return out
	end
	for title, entry in pairs(data) do
		if type(title) == "string" and type(entry) == "table" then
			local since = tonumber(entry.since) or 0
			local line = type(entry.line) == "string" and entry.line or title
			local kind = line:match("^(%S+)") or "task"
			out[#out + 1] = { title = title, kind = kind, line = line, since = since }
		end
	end
	table.sort(out, function(a, b)
		return a.since > b.since
	end)
	if #out > 10 then
		local trimmed = {}
		for i = 1, 10 do
			trimmed[i] = out[i]
		end
		return trimmed
	end
	return out
end

local function load_helpers(bot_dir)
	local out = {}
	local hdir = bot_dir .. "/helpers"
	if not tern.fs.exists(hdir) then
		return out
	end
	local ok_l, entries = pcall(tern.fs.list, hdir)
	if not ok_l or type(entries) ~= "table" then
		return out
	end
	for _, name in ipairs(entries) do
		if name:sub(-5) == ".json" then
			local item = safe_read_json(hdir .. "/" .. name, 16384)
			if type(item) == "table" and type(item.id) == "string" then
				out[#out + 1] = {
					id = item.id,
					agent = type(item.agent) == "string" and item.agent or "task",
					transcript = type(item.transcript) == "string" and item.transcript or "",
					since = tonumber(item.since) or 0,
				}
			end
		end
	end
	table.sort(out, function(a, b)
		return a.since > b.since
	end)
	if #out > 14 then
		local trimmed = {}
		for i = 1, 14 do
			trimmed[i] = out[i]
		end
		return trimmed
	end
	return out
end

local function latest_session_path(bot_dir)
	local sdir = bot_dir .. "/sessions"
	if not tern.fs.exists(sdir) then
		return nil
	end
	local ok_l, entries = pcall(tern.fs.list, sdir)
	if not ok_l or type(entries) ~= "table" then
		return nil
	end
	local best = nil
	for _, name in ipairs(entries) do
		if name:sub(-6) == ".jsonl" then
			if best == nil or name > best then
				best = name
			end
		end
	end
	if not best then
		return nil
	end
	return sdir .. "/" .. best
end

local function parse_git_status(out)
	local info = {
		is_repo = true,
		branch = "detached",
		ahead = 0,
		behind = 0,
		staged = 0,
		modified = 0,
		untracked = 0,
		files = {},
	}
	local first = true
	for line in (out or ""):gmatch("[^\r\n]+") do
		if first and line:sub(1, 3) == "## " then
			first = false
			local rest = line:sub(4)
			local unborn = rest:match("^No commits yet on (%S+)") or rest:match("^Initial commit on (%S+)")
			local head = unborn or rest:match("^(.-)%.%.%.") or rest:match("^(%S+)") or rest
			info.branch = head
			local a = rest:match("ahead (%d+)")
			local b = rest:match("behind (%d+)")
			info.ahead = tonumber(a) or 0
			info.behind = tonumber(b) or 0
		elseif #line >= 4 then
			first = false
			local x = line:sub(1, 1)
			local y = line:sub(2, 2)
			local file = line:sub(4)
			local renamed = file:match(" -> (.+)$")
			if renamed then
				file = renamed
			end
			local code = trim(x .. y)
			if x == "?" and y == "?" then
				info.untracked = info.untracked + 1
				code = "?"
			else
				if x ~= " " and x ~= "?" then
					info.staged = info.staged + 1
				end
				if y ~= " " then
					info.modified = info.modified + 1
				end
			end
			if #info.files < 24 then
				info.files[#info.files + 1] = { code = code, path = file }
			end
		end
	end
	return info
end

local function refresh_git(state, force)
	local cwd = state.ctx and state.ctx.cwd or ""
	if cwd == "" then
		state.git = { is_repo = false, cwd = "", files = {} }
		return
	end
	local now = tern.now()
	if not force and state.git_cwd == cwd and (now - state.git_at) < GIT_COOLDOWN_MS then
		return
	end
	if state.git_busy then
		return
	end
	state.git_busy = true
	state.git_cwd = cwd
	state.git_at = now
	tern.process.run(
		{ "git", "-C", cwd, "status", "--porcelain=v1", "-b" },
		{ timeout_ms = 2000 },
		function(r)
			state.git_busy = false
			if not state.alive then
				return
			end
			if (state.ctx and state.ctx.cwd or "") ~= cwd then
				refresh_git(state, true)
				return
			end
			if r.status == 0 then
				local parsed = parse_git_status(r.stdout)
				parsed.cwd = cwd
				state.git = parsed
			else
				state.git = { is_repo = false, cwd = cwd, files = {} }
			end
			if state.cx then
				state.cx:render()
			end
		end
	)
end

local function refresh_bot(state, force)
	local bot = state.ctx and state.ctx.bot or nil
	if not bot or bot == "" then
		state.bot_name = nil
		state.work = {}
		state.helpers = {}
		state.turns = {}
		state.session_advisor = {}
		state.file_advisor = {}
		state.done_items = {}
		return
	end
	local now = tern.now()
	if not force and state.bot_name == bot and (now - state.bot_at) < BOT_COOLDOWN_MS then
		return
	end
	if state.bot_name ~= bot then
		state.turns = {}
		state.session_advisor = {}
		state.file_advisor = {}
		state.done_items = {}
	end
	state.bot_name = bot
	state.bot_at = now
	local bot_dir = STATE_ROOT .. "/bots/" .. bot
	state.work = load_work_items(bot_dir)
	state.helpers = load_helpers(bot_dir)
	local req_bot = bot
	local session_path = latest_session_path(bot_dir)
	if session_path and not state.session_busy then
		state.session_busy = true
		tern.process.run({ "tail", "-n", "120", session_path }, { timeout_ms = 1500 }, function(r)
			state.session_busy = false
			if not state.alive then
				return
			end
			if state.bot_name ~= req_bot then
				refresh_bot(state, true)
				return
			end
			if r.status == 0 then
				state.turns = parse_turns_jsonl(r.stdout, 10)
				state.session_advisor = parse_advisor_from_session(r.stdout, 12)
			else
				state.turns = {}
				state.session_advisor = {}
			end
			if state.cx then
				state.cx:render()
			end
		end)
	elseif not session_path then
		state.turns = {}
		state.session_advisor = {}
	end
	local advisor_path = session_path and (session_path:gsub("%.jsonl$", "") .. "/__advisor.jsonl") or nil
	if advisor_path and tern.fs.exists(advisor_path) and not state.advisor_busy then
		state.advisor_busy = true
		tern.process.run({ "tail", "-n", "120", advisor_path }, { timeout_ms = 1500 }, function(r)
			state.advisor_busy = false
			if not state.alive then
				return
			end
			if state.bot_name ~= req_bot then
				refresh_bot(state, true)
				return
			end
			if r.status == 0 then
				state.file_advisor = parse_advisor_jsonl(r.stdout, 12)
			else
				state.file_advisor = {}
			end
			if state.cx then
				state.cx:render()
			end
		end)
	elseif not advisor_path or not tern.fs.exists(advisor_path) then
		state.file_advisor = {}
	end
	local done_path = bot_dir .. "/done.log"
	if tern.fs.exists(done_path) and not state.done_busy then
		state.done_busy = true
		tern.process.run({ "tail", "-n", "8", done_path }, { timeout_ms = 1500 }, function(r)
			state.done_busy = false
			if not state.alive then
				return
			end
			if state.bot_name ~= req_bot then
				refresh_bot(state, true)
				return
			end
			local items = {}
			if r.status == 0 then
				for line in (r.stdout or ""):gmatch("[^\r\n]+") do
					local ok, rec = pcall(tern.json.decode, line)
					if ok and type(rec) == "table" and type(rec.ask) == "string" then
						items[#items + 1] = {
							ask = clip(rec.ask, 90),
							exit = tonumber(rec.exit),
							time = type(rec.time) == "string" and #rec.time >= 16 and rec.time:sub(12, 16) or "",
						}
					end
				end
			end
			local rev = {}
			for i = #items, 1, -1 do
				rev[#rev + 1] = items[i]
			end
			state.done_items = rev
			if state.cx then
				state.cx:render()
			end
		end)
	elseif not tern.fs.exists(done_path) then
		state.done_items = {}
	end
end

local function load_peek(state, helper_id)
	local found = nil
	for _, h in ipairs(state.helpers) do
		if h.id == helper_id then
			found = h
			break
		end
	end
	if not found then
		state.peek = nil
		return
	end
	state.peek = {
		id = found.id,
		agent = found.agent,
		transcript = found.transcript,
		loading = true,
		entries = {},
	}
	if found.transcript == "" or not tern.fs.exists(found.transcript) then
		state.peek.loading = false
		return
	end
	tern.process.run({ "tail", "-n", "60", found.transcript }, { timeout_ms = 1500 }, function(r)
		if not state.alive or not state.peek or state.peek.id ~= found.id then
			return
		end
		state.peek.loading = false
		if r.status == 0 then
			state.peek.entries = parse_peek_jsonl(r.stdout)
		end
		if state.cx then
			state.cx:render()
		end
	end)
end

local function sync_context(state, force)
	local ok, ctx = pcall(tern.kv.get, "context")
	if ok and type(ctx) == "table" then
		local prev_bot = state.ctx and state.ctx.bot or nil
		local prev_mode = state.ctx and state.ctx.mode or nil
		state.ctx = ctx
		if prev_mode == nil then
			local valid
			if ctx.mode == "bot" then
				valid = state.tab == "outline" or state.tab == "jobs" or state.tab == "advisor" or state.tab == "workspace"
			else
				valid = state.tab == "workspace" or state.tab == "sessions"
			end
			if not valid then
				state.tab = ctx.mode == "bot" and "outline" or "workspace"
			end
		elseif ctx.mode ~= prev_mode then
			state.peek = nil
			state.tab = ctx.mode == "bot" and "outline" or "workspace"
		elseif ctx.bot ~= prev_bot then
			state.peek = nil
		end
	end
	refresh_git(state, force)
	refresh_bot(state, force)
end

local function view_workspace(state)
	local ctx = state.ctx or {}
	local cwd = ctx.cwd or ""
	local nodes = {}
	local info_rows = {
		{ "Directory", ui.span(short_path(cwd ~= "" and cwd or "(unknown)"), "path") },
	}
	if ctx.program and ctx.program ~= "" then
		info_rows[#info_rows + 1] = { "Program", ui.span(ctx.program, "mono") }
	end
	if ctx.mode == "bot" and ctx.bot_box then
		info_rows[#info_rows + 1] = { "Sandbox", ui.span("omp-box VM", "dim") }
	end
	local git = state.git and state.git.cwd == cwd and state.git or nil
	if git and git.is_repo then
		local branch_txt = git.branch or "HEAD"
		if (git.ahead or 0) > 0 then
			branch_txt = branch_txt .. " ↑" .. tostring(git.ahead)
		end
		if (git.behind or 0) > 0 then
			branch_txt = branch_txt .. " ↓" .. tostring(git.behind)
		end
		info_rows[#info_rows + 1] = { "Branch", ui.span(branch_txt, "mono") }
	end
	nodes[#nodes + 1] = with(ui.card("Context", { ui.kv(info_rows) }, { icon = "folder" }), { role = "rr.card.ctx" })

	if git and git.is_repo then
		local files = git.files or {}
		local summary = string.format(
			"%d staged · %d mod · %d new",
			git.staged or 0,
			git.modified or 0,
			git.untracked or 0
		)
		local fchildren = {}
		if #files == 0 then
			fchildren[#fchildren + 1] = with(ui.text(ui.span("Working tree clean", "dim")), { role = "rr.empty" })
		else
			for _, f in ipairs(files) do
				local tone = f.code == "?" and "muted" or (f.code:find("D") and "error" or "warn")
				fchildren[#fchildren + 1] = with(
					ui.row({
						ui.badge(f.code, tone),
						ui.text(ui.path(f.path, cwd)),
					}),
					{ role = "rr.file.row" }
				)
			end
		end
		nodes[#nodes + 1] = with(
			ui.card("Changes", fchildren, { icon = "branch", meta = summary }),
			{ role = "rr.card.git" }
		)
	else
		local msg = (git == nil and state.git_busy) and "Loading…" or "Not a git repository"
		nodes[#nodes + 1] = with(
			ui.card("Changes", {
				with(ui.text(ui.span(msg, "dim")), { role = "rr.empty" }),
			}, { icon = "branch" }),
			{ role = "rr.card.git" }
		)
	end
	return nodes
end

local function view_outline(state)
	local nodes = {}
	local turn_children = {}
	if #state.turns == 0 then
		turn_children[#turn_children + 1] = with(ui.text(ui.span("No recent turns recorded", "dim")), { role = "rr.empty" })
	else
		for i = #state.turns, 1, -1 do
			local t = state.turns[i]
			local badge_label = t.role == "user" and "You" or (state.ctx and state.ctx.bot or "Bot")
			local badge_tone = t.role == "user" and "accent" or "muted"
			turn_children[#turn_children + 1] = with(
				ui.col({
					ui.row({
						ui.badge(badge_label, badge_tone),
						ui.text(ui.span(t.time, "dim")),
					}),
					ui.text(t.text),
				}),
				{ role = "rr.turn.row" }
			)
		end
	end
	nodes[#nodes + 1] = with(
		ui.card("Recent Turns", turn_children, { icon = "list-ordered", meta = tostring(#state.turns) }),
		{ role = "rr.card.turns" }
	)

	local work_children = {}
	if #state.work == 0 then
		work_children[#work_children + 1] = with(ui.text(ui.span("No open tracked tasks", "dim")), { role = "rr.empty" })
	else
		for _, w in ipairs(state.work) do
			local tone = w.kind == "wait" and "warn" or "accent"
			work_children[#work_children + 1] = with(
				ui.row({
					ui.badge(w.kind, tone),
					ui.text(clip(w.title, 76)),
				}),
				{ role = "rr.job.row" }
			)
		end
	end
	nodes[#nodes + 1] = with(
		ui.card("Tracked Tasks", work_children, { icon = "list-checks", meta = tostring(#state.work) }),
		{ role = "rr.card.work" }
	)
	return nodes
end

local function view_jobs(state)
	local nodes = {}
	local hchildren = {}
	if #state.helpers == 0 then
		hchildren[#hchildren + 1] = with(ui.text(ui.span("No helpers recorded", "dim")), { role = "rr.empty" })
	else
		for _, h in ipairs(state.helpers) do
			hchildren[#hchildren + 1] = with(
				ui.row({
					ui.badge(h.agent, "muted"),
					ui.text(clip(h.id, 30)),
					ui.button("Peek", {
						icon = "eye",
						variant = "quiet",
						size = "sm",
						actions = { click = "peek=" .. h.id },
					}),
				}),
				{ role = "rr.job.row" }
			)
		end
	end
	nodes[#nodes + 1] = with(
		ui.card("Helpers", hchildren, { icon = "cpu", meta = tostring(#state.helpers) }),
		{ role = "rr.card.helpers" }
	)

	local dchildren = {}
	if #state.done_items == 0 then
		dchildren[#dchildren + 1] = with(ui.text(ui.span("No completed checks yet", "dim")), { role = "rr.empty" })
	else
		for _, d in ipairs(state.done_items) do
			local ok_exit = d.exit == 0 or d.exit == nil
			dchildren[#dchildren + 1] = with(
				ui.col({
					ui.row({
						ui.badge(ok_exit and "done" or ("exit " .. tostring(d.exit)), ok_exit and "ok" or "error"),
						ui.text(ui.span(d.time, "dim")),
					}),
					ui.text(d.ask),
				}),
				{ role = "rr.turn.row" }
			)
		end
	end
	nodes[#nodes + 1] = with(
		ui.card("Completed", dchildren, { icon = "check", meta = tostring(#state.done_items) }),
		{ role = "rr.card.done" }
	)
	return nodes
end

local function view_advisor(state)
	local notes = merge_advisor_notes(state.session_advisor, state.file_advisor, 12)
	local children = {}
	if #notes == 0 then
		children[#children + 1] = with(ui.text(ui.span("No advisor notes recorded", "dim")), { role = "rr.empty" })
	else
		for i = #notes, 1, -1 do
			local n = notes[i]
			children[#children + 1] = with(
				ui.col({
					ui.row({
						ui.badge(clip(n.tag or "advisor", 20), "accent"),
						ui.text(ui.span(n.time or "", "dim")),
					}),
					ui.text(n.text),
				}),
				{ role = "rr.advisor.row" }
			)
		end
	end
	return {
		with(ui.card("Advisor Notes", children, { icon = "eye", meta = tostring(#notes) }), { role = "rr.card.advisor" }),
	}
end

local function view_sessions(state)
	local tabs = (state.ctx and state.ctx.tabs) or {}
	local children = {}
	if #tabs == 0 then
		children[#children + 1] = with(ui.text(ui.span("No open tabs", "dim")), { role = "rr.empty" })
	else
		for _, t in ipairs(tabs) do
			local label = t.name and t.name ~= "" and t.name or (t.program ~= "" and t.program or "shell")
			local tone = t.busy and "warn" or (t.is_bot and "accent" or "muted")
			local kind_tag = t.busy and "busy" or (t.is_bot and "bot" or "term")
			children[#children + 1] = with(
				ui.row({
					ui.badge(kind_tag, tone),
					ui.text({
						ui.span(clip(label, 24), t.active and "bold" or nil),
						ui.span(t.cwd and t.cwd ~= "" and ("  " .. short_path(t.cwd)) or "", "dim"),
					}),
				}),
				{ role = t.active and "rr.tab.row.active" or "rr.tab.row" }
			)
		end
	end
	return {
		with(ui.card("Open Tabs", children, { icon = "layers", meta = tostring(#tabs) }), { role = "rr.card.tabs" }),
	}
end

local function view_peek(state)
	local p = state.peek
	local head = with(
		ui.row({
			ui.button("", { icon = "arrow-left", variant = "quiet", size = "sm", title = "Back", actions = { click = "back" } }),
			with(ui.text(clip(p.id, 34)), { role = "rr.title" }),
			ui.badge(p.agent, "muted"),
			ui.button("", { icon = "fetch", variant = "quiet", size = "sm", title = "Refresh", actions = { click = "peek=" .. p.id } }),
		}),
		{ role = "rr.head" }
	)
	local body_nodes = {}
	if p.loading then
		body_nodes[#body_nodes + 1] = with(ui.text(ui.span("Loading transcript tail…", "dim")), { role = "rr.empty" })
	elseif #p.entries == 0 then
		body_nodes[#body_nodes + 1] = with(ui.text(ui.span("No transcript entries yet", "dim")), { role = "rr.empty" })
	else
		for i = #p.entries, 1, -1 do
			local e = p.entries[i]
			local tone = e.role == "user" and "accent" or (e.role == "tool" and (e.err and "error" or "ok") or "muted")
			body_nodes[#body_nodes + 1] = with(
				ui.col({
					ui.row({
						ui.badge(e.role, tone),
						ui.text(ui.span(e.time, "dim")),
					}),
					ui.text(e.text),
				}),
				{ role = "rr.turn.row" }
			)
		end
	end
	return {
		main = with(
			ui.col({
				head,
				with(ui.col(body_nodes), { role = "rr.peek" }),
			}),
			{ role = "rr.root" }
		),
	}
end

local function render_view(state, _cx)
	if state.peek then
		return view_peek(state)
	end
	local ctx = state.ctx or {}
	local is_bot = ctx.mode == "bot"
	local title = is_bot and (ctx.bot or "Bot")
		or ((ctx.tab_name and ctx.tab_name ~= "" and ctx.tab_name) or (ctx.program and ctx.program ~= "" and ctx.program) or "Terminal")
	local status_label = ctx.busy and "Working" or (is_bot and "Bot" or "Shell")
	local status_tone = ctx.busy and "warn" or (is_bot and "accent" or "muted")

	local head = with(
		ui.row({
			with(ui.text(clip(title, 30)), { role = "rr.title" }),
			ui.badge(status_label, status_tone),
			ui.button("", {
				icon = "fetch",
				variant = "quiet",
				size = "sm",
				title = "Refresh inspector",
				actions = { click = "refresh" },
			}),
		}),
		{ role = "rr.head" }
	)

	local tab_defs = is_bot
		and {
			{ id = "outline", label = "Outline" },
			{ id = "jobs", label = "Jobs" },
			{ id = "advisor", label = "Advisor" },
			{ id = "workspace", label = "Workspace" },
		}
		or {
			{ id = "workspace", label = "Workspace" },
			{ id = "sessions", label = "Sessions" },
		}

	local tab_buttons = {}
	for _, td in ipairs(tab_defs) do
		tab_buttons[#tab_buttons + 1] = ui.button(td.label, {
			variant = "quiet",
			size = "sm",
			on = state.tab == td.id,
			actions = { click = "tab=" .. td.id },
		})
	end
	local tab_strip = with(ui.row(tab_buttons), { role = "rr.tabs" })

	local body_nodes
	if is_bot then
		if state.tab == "jobs" then
			body_nodes = view_jobs(state)
		elseif state.tab == "advisor" then
			body_nodes = view_advisor(state)
		elseif state.tab == "workspace" then
			body_nodes = view_workspace(state)
		else
			body_nodes = view_outline(state)
		end
	else
		if state.tab == "sessions" then
			body_nodes = view_sessions(state)
		else
			body_nodes = view_workspace(state)
		end
	end

	return {
		main = with(
			ui.col({
				head,
				tab_strip,
				with(ui.col(body_nodes), { role = "rr.body" }),
			}),
			{ role = "rr.root" }
		),
	}
end

tern.on("unload", function()
	for s in pairs(active_states) do
		s.alive = false
		s.cx = nil
	end
	active_states = {}
end)

tern.block.define("inspector", {
	mode = "screen",
	font = "sans",
	init = function(cx, _args, saved)
		local state = {
			cx = cx,
			alive = true,
			ctx = nil,
			tab = type(saved) == "table" and type(saved.tab) == "string" and saved.tab or "outline",
			git = nil,
			git_cwd = "",
			git_at = 0,
			git_busy = false,
			bot_name = nil,
			bot_at = 0,
			session_busy = false,
			advisor_busy = false,
			done_busy = false,
			work = {},
			helpers = {},
			turns = {},
			session_advisor = {},
			file_advisor = {},
			done_items = {},
			peek = nil,
		}
		active_states[state] = true
		sync_context(state, true)
		return state
	end,
	title = function(state)
		local ctx = state.ctx
		if ctx and ctx.mode == "bot" and ctx.bot then
			return ctx.bot .. " · Inspector"
		end
		return "Inspector"
	end,
	view = render_view,
	key = function(state, key, cx)
		local name = key.name
		local is_bot = state.ctx and state.ctx.mode == "bot"
		if name == "1" then
			state.peek = nil
			state.tab = is_bot and "outline" or "workspace"
			return true
		elseif name == "2" then
			state.peek = nil
			state.tab = is_bot and "jobs" or "sessions"
			return true
		elseif name == "3" and is_bot then
			state.peek = nil
			state.tab = "advisor"
			return true
		elseif name == "4" and is_bot then
			state.peek = nil
			state.tab = "workspace"
			return true
		elseif name == "r" then
			if state.peek then
				load_peek(state, state.peek.id)
			else
				sync_context(state, true)
			end
			return true
		elseif name == "escape" or name == "backspace" then
			if state.peek then
				state.peek = nil
				return true
			end
			return false
		elseif name == "q" then
			state.alive = false
			active_states[state] = nil
			cx:exit(0)
			return true
		end
		return false
	end,
	event = function(state, ev, _cx)
		if ev.ev ~= "action" then
			return
		end
		local act = ev.act or ""
		if act == "sync" then
			sync_context(state, false)
		elseif act == "refresh" then
			sync_context(state, true)
		elseif act == "tab" and type(ev.value) == "string" then
			state.peek = nil
			state.tab = ev.value
		elseif act == "peek" and type(ev.value) == "string" then
			load_peek(state, ev.value)
		elseif act == "back" then
			state.peek = nil
		end
	end,
	save = function(state)
		return { tab = state.tab }
	end,
})
