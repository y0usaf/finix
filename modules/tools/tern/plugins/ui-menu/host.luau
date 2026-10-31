local function model(): { any }
	local saved = tern.kv.get("menu")
	if type(saved) ~= "table" then
		return {}
	end
	return saved
end

local function state(): { [string]: boolean }
	local saved = tern.kv.get("on")
	local out = {}
	if type(saved) == "table" then
		for k, v in pairs(saved) do
			if type(k) == "string" then
				out[k] = v == true
			end
		end
	end
	return out
end

local function snapshot(): { [string]: boolean }
	local out = {}
	for _, row in ipairs(model()) do
		if type(row) == "table" and type(row.id) == "string" then
			out[row.id] = state()[row.id] == true
		end
	end
	return out
end

local function same(a, b): boolean
	for k, v in pairs(b) do
		if a[k] ~= v then
			return false
		end
	end
	for k in pairs(a) do
		if b[k] == nil then
			return false
		end
	end
	return true
end

local function watch(cx, state_now)
	tern.timer(250, function()
		if not cx then
			return
		end
		local next_now = snapshot()
		if not same(state_now, next_now) then
			for k, v in pairs(next_now) do
				state_now[k] = v
			end
			cx:render()
		end
		watch(cx, state_now)
	end)
end

tern.block.define("options", {
	init = function(cx, _args, _saved)
		local now = snapshot()
		watch(cx, now)
		return now
	end,
	title = function()
		return "UI options"
	end,
	view = function(_state_now, _cx)
		local on = state()
		local nodes = {}
		local group = nil
		for _, row in ipairs(model()) do
			if type(row) == "table" and type(row.id) == "string" then
				local g = tostring(row.group or "Tweaks")
				if g ~= group then
					group = g
					nodes[#nodes + 1] = tern.ui.el("div", { class = "uo-group", text = g })
				end
				nodes[#nodes + 1] = tern.ui.el("label", { class = "uo-row" }, {
					tern.ui.el("input", { type = "checkbox", name = row.id, checked = on[row.id] == true }),
					tern.ui.el("span", { class = "uo-name", text = tostring(row.label or row.id) }),
				})
			end
		end
		return { main = tern.ui.col({ tern.ui.el("div", { class = "uo-list" }, nodes) }) }
	end,
	event = function(_state_now, ev, _cx)
		if ev.ev == "change" and type(ev.name) == "string" then
			local next_on = state()
			next_on[ev.name] = ev.checked == true
			tern.kv.set("on", next_on)
		end
	end,
})
