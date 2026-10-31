--!strict

local native = {
	{ label = "Terminal", detail = "shell block", icon = "terminal", action = "new_shell_block" },
	{ label = "Agent", detail = "omp, Claude, Codex", icon = "sparkle", action = "new_agent_block" },
	{ label = "Browser", detail = "web page", icon = "globe", action = "new_browser_block" },
	{ label = "Git", detail = "status, commits", icon = "branch", action = "new_git_block" },
	{ label = "Board", detail = "lanes and cards", icon = "kanban", action = "new_board_block" },
	{ label = "Canvas", detail = "shapes and notes", icon = "canvas", action = "new_canvas_block" },
	{ label = "Task manager", detail = "processes", icon = "list-checks", action = "new_task_manager_block" },
	{ label = "Screen", detail = "remote display", icon = "monitor", action = "new_screen_block" },
}

local function menu(cx: WindowCx)
	local items: { PickItem } = {}
	for _, row in ipairs(native) do
		table.insert(items, {
			label = row.label,
			detail = row.detail,
			group = "Tern",
			icon = row.icon,
			action = row.action,
		})
	end
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
			if item.kind then
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
