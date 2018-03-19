local core = require "gooey.internal.core"

local M = {}

M.TOUCH = hash("touch")

local buttons = {}

local BUTTON = {
	refresh = function(button)
		if button.refresh_fn then button.refresh_fn(button) end
	end,
}

function M.button(node_id, action_id, action, fn, refresh_fn)
	node_id = core.to_hash(node_id)
	local node = gui.get_node(node_id)
	assert(node)

	local button = core.instance(node_id, buttons, BUTTON)
	button.enabled = core.is_enabled(node)
	button.node = node
	button.refresh_fn = refresh_fn

	local over = gui.pick_node(node, action.x, action.y)
	button.over_now = over and not button.over
	button.out_now = not over and button.over
	button.over = over

	if not button.enabled then
		button.pressed_now = false
		button.released_now = false
	else
		local touch = action_id == M.TOUCH
		local pressed = touch and action.pressed and button.over
		local released = touch and action.released
		button.pressed_now = pressed and not button.pressed
		button.released_now = released and button.pressed
		button.pressed = pressed or (button.pressed and not released)
		if button.released_now and button.over then
			fn(button)
		end
	end
	button.refresh()
	return button
end

setmetatable(M, {
	__call = function(_, ...)
		return M.button(...)
	end
})

return M