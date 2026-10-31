local TWEAKS = {
	{
		id = "sessions",
		label = "sessions",
		css = ".tn-session-tab{display:none !important}",
		on = true,
	},
	{
		id = "account",
		label = "account",
		css = ".tn-peers{display:none !important}",
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
}

local on = {}

for _, t in ipairs(TWEAKS) do
	on[t.id] = t.on
end

local function paint(t)
	tern.css("ui-menu-" .. t.id, on[t.id] and t.css or "")
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
			tern.chrome.refresh()
		end,
	})
end

tern.chrome.status(function(pane)
	local out = {}
	for _, t in ipairs(TWEAKS) do
		out[#out + 1] = {
			text = (on[t.id] and "−" or "+") .. t.label,
			tone = "muted",
			command = "plugin.ui-menu.toggle-" .. t.id,
		}
	end
	return out
end)

paint_all()
