local function rows(): { any }
	local saved = tern.kv.get("menu")
	if type(saved) ~= "table" then
		return {}
	end
	return saved
end

local function states(): { [string]: boolean }
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

local function mode(): string
	local m = tern.kv.get("mode")
	return if type(m) == "string" then m else "rail"
end

local function shown(row, on, m): boolean
	if type(row) ~= "table" or type(row.id) ~= "string" then
		return false
	end
	if type(row.mode) == "string" and row.mode ~= m then
		return false
	end
	if type(row.needs) == "string" and on[row.needs] ~= true then
		return false
	end
	return true
end

local function signature(): string
	return mode() .. "|" .. tern.json.encode(states())
end

local function watch(cx, last)
	tern.timer(250, function()
		if not cx then
			return
		end
		local now = signature()
		if now ~= last then
			cx:render()
			last = now
		end
		watch(cx, last)
	end)
end

tern.block.define("options", {
	init = function(cx, _args, _saved)
		watch(cx, signature())
		return {}
	end,
	title = function()
		return "UI options"
	end,
	view = function(_state, _cx)
		local on = states()
		local m = mode()
		local nodes = {}
		local group = nil
		for _, row in ipairs(rows()) do
			if shown(row, on, m) then
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
	event = function(_state, ev, _cx)
		if ev.ev == "change" and type(ev.name) == "string" then
			local on = states()
			on[ev.name] = ev.checked == true
			tern.kv.set("on", on)
		end
	end,
})
