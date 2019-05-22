local core = require "gooey.internal.core"

local M = {}

local buttons = {}

-- instance functions
local BUTTON = {}
function BUTTON.refresh(button)
	if button.refresh_fn then button.refresh_fn(button) end
end
function BUTTON.set_visible(button, visible)
	gui.set_enabled(button.node, visible)
end
function BUTTON.set_long_pressed_time(button, time)
	button.long_pressed_time = time
end

function M.button(node_id, action_id, action, fn, refresh_fn)
	node_id = core.to_hash(node_id)
	local node = gui.get_node(node_id)
	assert(node)

	local button = core.instance(node_id, buttons, BUTTON)
	button.enabled = core.is_enabled(node)
	button.node = node
	button.refresh_fn = refresh_fn

	core.clickable(button, action_id, action)
	if button.clicked then
		fn(button)
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