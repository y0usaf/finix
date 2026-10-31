--!strict

local blocks = {
	{ label = "Terminal", detail = "shell block", icon = "terminal", action = "new_shell_block" },
	{ label = "Browser", detail = "web page", icon = "globe", action = "new_browser_block" },
	{ label = "Git", detail = "status, commits", icon = "branch", action = "new_git_block" },
	{ label = "Board", detail = "lanes and cards", icon = "kanban", action = "new_board_block" },
	{ label = "Canvas", detail = "shapes and notes", icon = "canvas", action = "new_canvas_block" },
	{ label = "Task manager", detail = "processes", icon = "list-checks", action = "new_task_manager_block" },
	{ label = "Screen", detail = "remote display", icon = "monitor", action = "new_screen_block" },
}

local agents = {
	{ label = "omp", icon = "app-omp", command = "omp" },
	{ label = "Claude Code", icon = "app-claude", command = "tern acp claude" },
	{ label = "Codex", icon = "app-codex", command = "tern acp codex" },
}

local function launch(cx: WindowCx, command: string)
	local placement = cx.settings:get("agent_placement")
	if placement == "new_tab" then
		cx.layout:new_tab({ command = command })
		return
	end
	local id = cx.session:focused()
	local info = id and cx.session:pane(id) or nil
	if not info then
		cx.layout:new_tab({ command = command })
		return
	end
	if placement == "replace_if_alone" then
		local tab = cx.session:tab_of(info.pane)
		local layout = tab and cx.session:layout(tab)
		if layout and layout.root.pane then
			local pane = cx.layout:split(info.pane, "right", { command = command })
			if pane then
				cx.layout:close(info.pane)
			end
			return
		end
	end
	cx.layout:split(info.pane, "right", { command = command })
end

local function menu(cx: WindowCx)
	local items: { PickItem } = {}
	for _, row in ipairs(blocks) do
		table.insert(items, {
			label = row.label,
			detail = row.detail,
			group = "Blocks",
			icon = row.icon,
			action = row.action,
		})
	end
	for _, row in ipairs(agents) do
		table.insert(items, {
			label = row.label,
			group = "Agents",
			icon = row.icon,
			command = row.command,
		})
	end
	local custom = cx.settings:get("agents.custom")
	if type(custom) == "table" then
		for _, entry in ipairs(custom) do
			local name = type(entry) == "table" and entry.name or nil
			local command = type(entry) == "table" and entry.command or nil
			if type(name) == "string" and type(command) == "string" and name ~= "" and command ~= "" then
				table.insert(items, {
					label = name,
					group = "Agents",
					icon = "puzzle",
					command = command,
				})
			end
		end
	end
	table.insert(items, { label = "Carly", group = "Agents", icon = "sparkle", action = "new_carly_block" })
	for _, block in ipairs(cx.session:block_types()) do
		if block.palette and block.kind ~= "canvas" and block.kind ~= "tern.canvas" then
			table.insert(items, {
				label = block.title,
				detail = block.kind,
				group = "Plugins",
				icon = block.icon,
				kind = block.kind,
			})
		end
	end
	cx:pick({ items = items, placeholder = "New block", icon = "plus", action = "create" })
		:next(function(item: PickItem?, _err: string?, fresh: WindowCx?)
			if not item then
				return
			end
			local next_cx = fresh or cx
			if item.command then
				launch(next_cx, item.command)
			elseif item.kind then
				next_cx:new_block(item.kind)
			elseif item.action then
				next_cx:action(item.action)
			end
		end)
end

tern.command({
	id = "new_block",
	title = "New block…",
	icon = "plus",
	keys = { "ctrl+n" },
	run = menu,
})
