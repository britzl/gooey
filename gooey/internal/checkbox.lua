local core = require "gooey.internal.core"

local M = {}

M.TOUCH = hash("touch")

local checkboxes = {}

local CHECKBOX = {
	set_checked = function(checkbox, checked)
		checkbox.checked = checked
		if checkbox.refresh_fn then checkbox.refresh_fn(checkbox) end
	end,
	set_visible = function(checkbox, visible)
		gui.set_enabled(checkbox.node, visible)
	end,
	refresh = function(checkbox)
		if checkbox.refresh_fn then checkbox.refresh_fn(checkbox) end
	end,
}

function M.checkbox(node_id, action_id, action, fn, refresh_fn)
	node_id = core.to_hash(node_id)
	local node = gui.get_node(node_id)
	assert(node)

	local checkbox = core.instance(node_id, checkboxes, CHECKBOX)
	checkbox.enabled = core.is_enabled(node)
	checkbox.node = node
	checkbox.refresh_fn = refresh_fn

	if not action then
		checkbox.refresh()
		return checkbox
	end

	local over = gui.pick_node(node, action.x, action.y)
	checkbox.over_now = over and not checkbox.over
	checkbox.out_now = not over and checkbox.over
	checkbox.over = over

	if not checkbox.enabled then
		checkbox.pressed_now = false
		checkbox.released_now = false
	else
		local touch = action_id == M.TOUCH
		local pressed = touch and action.pressed and checkbox.over
		local released = touch and action.released
		checkbox.pressed_now = pressed and not checkbox.pressed
		checkbox.released_now = released and checkbox.pressed
		checkbox.pressed = pressed or (checkbox.pressed and not released)
		if checkbox.released_now and checkbox.over then
			checkbox.checked = not checkbox.checked
			fn(checkbox)
		end
	end
	checkbox.refresh()
	return checkbox
end

setmetatable(M, {
	__call = function(_, ...)
		return M.checkbox(...)
	end
})

return M