--!strict

local last: number? = nil
local previous: number? = nil

local function note(id: number?)
	if id and id ~= last then
		previous = last
		last = id
	end
end

local function focused_tab(cx: WindowCx): number?
	local pane = cx.session:focused()
	return pane and cx.session:tab_of(pane) or nil
end

local function tab_info(cx: WindowCx, id: number): TabInfo?
	for _, info in ipairs(cx.session:tabs()) do
		if info.id == id then
			return info
		end
	end
	return nil
end

local function place(cx: WindowCx, id: number, anchor: number?)
	if not anchor or anchor == id then
		return
	end
	local info = tab_info(cx, id)
	local at = tab_info(cx, anchor)
	if not info or not at or info.session ~= at.session then
		return
	end
	if info.position > at.position + 1 then
		cx.layout:order_tab(id, at.position + 1)
	end
end

tern.on("window_start", function(cx: WindowCx)
	last, previous = nil, nil
	note(focused_tab(cx))
end)

tern.on("focus", function(ev: FocusEvent)
	note(ev.tab)
end)

tern.timer(0, function(cx: WindowCx?)
	note(cx and focused_tab(cx))
end)

tern.on("tab_created", function(ev: TabEvent, cx: WindowCx)
	if focused_tab(cx) ~= ev.tab then
		return
	end
	place(cx, ev.tab, last == ev.tab and previous or last)
end)
