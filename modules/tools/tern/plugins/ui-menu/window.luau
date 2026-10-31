local TWEAKS = {
	{
		id = "sessions",
		label = "sessions",
		css = [[.tn-session-tab{display:none !important}]],
		on = true,
	},
	{
		id = "account",
		label = "account",
		css = [[.tn-peers{display:none !important}]],
		on = true,
	},
	{
		id = "frost",
		label = "modal frost",
		css = [[html.tn-themed .cmdk,
html.tn-themed .dlg-card,
html.tn-themed .mdl,
html.tn-themed .pk-sheet,
html.tn-themed .sf-overlay.modal > .sf-ov-card,
html.tn-themed .sf-prefs .pf-editor > .sf-col,
html.tn-themed .tn-hd,
html.tn-themed .tn-sc {
	-webkit-backdrop-filter: blur(40px) saturate(190%) !important;
	backdrop-filter: blur(40px) saturate(190%) !important;
}]],
		on = true,
	},
	{
		id = "width",
		label = "rail width",
		css = [[html.tabs-v {
	--vt-w: 252px;
}
html.lay-rail.tabs-h #tabbar {
	width: 236px !important;
}
html.lay-rail.tabs-h #panel {
	left: calc(236px * var(--tn-zoom, 1)) !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "spacing",
		label = "rail spacing",
		css = [[html.tabs-v #sidebar {
	padding: 54px 8px 12px 10px !important;
	gap: 1px !important;
}
html.tabs-v #sidebar .nav-group {
	gap: 1px !important;
	margin-bottom: 10px !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "heads",
		label = "section heads",
		css = [[html.tabs-v #sidebar .nav-head {
	height: 24px !important;
	padding: 0 8px !important;
	font-size: 11px !important;
	font-weight: 600 !important;
	letter-spacing: 0.03em !important;
	text-transform: uppercase !important;
	color: var(--t4) !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "rows",
		label = "rail rows",
		css = [[html.tabs-v #sidebar .nav-row {
	height: 34px !important;
	padding: 0 8px !important;
	gap: 9px !important;
	border-radius: 9px !important;
	font-size: 13px !important;
	color: var(--t2) !important;
	transition:
		background-color 0.13s var(--ease),
		color 0.13s var(--ease),
		box-shadow 0.13s var(--ease) !important;
}
html.tabs-v #sidebar .nav-row:hover {
	background: rgb(from var(--t1) r g b / 6%) !important;
	color: var(--t1) !important;
}
html.tabs-v #sidebar .nav-row.on,
html.tabs-v #sidebar .nav-row.sel,
html.tabs-v #sidebar .nav-row.focused {
	background: rgb(from var(--accent) r g b / 13%) !important;
	color: var(--t1) !important;
	box-shadow: inset 2px 0 0 var(--accent) !important;
}
html.tabs-v #sidebar .nav-row .ico {
	color: inherit !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "keys",
		label = "key hints",
		css = [[html.tabs-v #sidebar .nav-row .meta.keys {
	opacity: 0 !important;
	transition: opacity 0.13s var(--ease) !important;
}
html.tabs-v #sidebar .nav-row:hover .meta.keys {
	opacity: 1 !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "colours",
		label = "tab colours",
		css = [[html.tabs-v #sidebar .nav-row[data-tc] .tn-tc {
	width: 8px !important;
	height: 8px !important;
}
html.tabs-v #sidebar .nav-row[data-tc] .lbl {
	font-weight: 550 !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "find",
		label = "rail find",
		css = [[html.tabs-v .tn-vt-find {
	height: 30px !important;
	margin: 0 2px 8px !important;
	border-radius: 9px !important;
	background: var(--l1) !important;
	box-shadow: inset 0 0 0 1px var(--l2) !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "chips",
		label = "session chips",
		css = [[html.tabs-v #tabbar .tn-session-tab {
	height: 26px !important;
	padding: 0 9px !important;
	border-radius: 8px !important;
	font-size: 12px !important;
	color: var(--t2) !important;
	transition: background-color 0.13s var(--ease), color 0.13s var(--ease) !important;
}
html.tabs-v #tabbar .tn-session-tab:hover {
	background: var(--l1) !important;
	color: var(--t1) !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "tabs",
		label = "tab rows",
		css = [[html.lay-rail.tabs-h .tt {
	height: 38px !important;
	margin: 0 4px !important;
	padding: 0 10px !important;
	border-radius: 10px !important;
	transition: background-color 0.13s var(--ease), color 0.13s var(--ease) !important;
}
html.lay-rail.tabs-h .tt:hover {
	background: var(--l1) !important;
}
html.lay-rail.tabs-h .tt.on {
	background: var(--panel) !important;
	box-shadow: inset 2px 0 0 var(--accent) !important;
}
html.lay-rail.tabs-h .tt.on::before,
html.lay-rail.tabs-h .tt.on::after {
	display: none !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "buttons",
		label = "rail buttons",
		css = [[html.lay-rail.tabs-h .tb-row {
	height: 28px !important;
	margin: 2px 6px 0 !important;
	padding: 0 10px !important;
	border-radius: 9px !important;
}
html.lay-rail.tabs-h .tb-add {
	margin: 4px 6px 0 !important;
	border-radius: 9px !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "centering",
		label = "rail centering",
		css = [[html.tabs-v #sidebar > nav.tn-vt {
	display: flex !important;
	flex-direction: column !important;
	justify-content: center !important;
	align-items: stretch !important;
}
html.tabs-v #sidebar > nav.tn-vt > .nav-group:first-child {
	margin-top: auto !important;
}
html.tabs-v #sidebar > nav.tn-vt > .nav-group:last-child {
	margin-bottom: auto !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "bottom",
		label = "rail bottom",
		css = [[html.lay-rail.tabs-h #tabbar > .tb-in > .tn-peers {
	order: 1 !important;
	margin-top: 0 !important;
}
html.lay-rail.tabs-h #tabbar {
	overflow-y: auto !important;
}
html.lay-rail.tabs-h #tabbar > .tb-in {
	flex: none !important;
	min-height: 100% !important;
}
html.lay-rail.tabs-h #tabbar > .tb-in > .tb-tabs {
	flex: none !important;
	margin: 0 !important;
	overflow: visible !important;
}
html.lay-rail.tabs-h #tabbar > .tb-in > .tb-add {
	margin-top: auto !important;
}]],
		on = true,
		quiet = true,
	},
	{
		id = "lock",
		label = "rail lock",
		on = true,
	},
}

local on = {}

for _, t in ipairs(TWEAKS) do
	on[t.id] = t.on
end

local LOCKED = {
	"layout:float",
	"layout:tiles",
	"layout:studio",
	"next_layout",
	"toggle_tab_orientation",
	"tabs:vertical",
}

local function rail(cx)
	pcall(function()
		cx:action("layout:rail")
	end)
	pcall(function()
		cx:action("tabs:horizontal")
	end)
end

for _, id in ipairs(LOCKED) do
	pcall(function()
		tern.override(id, function(cx)
			if not on.lock then
				return false
			end
			cx:toast("info", "The rail is locked")
			return true
		end)
	end)
end

tern.on("window_start", function(cx)
	if on.lock then
		rail(cx)
	end
end)

local function paint(t)
	if t.css then
		tern.css("ui-menu-" .. t.id, on[t.id] and t.css or "")
	end
end

local function paint_all()
	for _, t in ipairs(TWEAKS) do
		paint(t)
	end
end

for _, t in ipairs(TWEAKS) do
	tern.command({
		id = "toggle-" .. t.id,
		group = "UI",
		title = "UI: show or hide the " .. t.label,
		run = function(cx)
			on[t.id] = not on[t.id]
			paint(t)
			if t.id == "lock" and on.lock then
				rail(cx)
			end
			tern.chrome.refresh()
		end,
	})
end

tern.chrome.status(function(pane)
	local out = {}
	for _, t in ipairs(TWEAKS) do
		if not t.quiet then
			out[#out + 1] = {
				text = (on[t.id] and "−" or "+") .. t.label,
				tone = "muted",
				command = "plugin.ui-menu.toggle-" .. t.id,
			}
		end
	end
	return out
end)

paint_all()
