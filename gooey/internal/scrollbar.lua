local core = require "gooey.internal.core"
local actions = require "gooey.actions"

local M = {}

local scrollbars = {}

-- instance functions
local SCROLLBAR = {}
function SCROLLBAR.refresh(scrollbar)
	if scrollbar.refresh_fn then scrollbar.refresh_fn(button) end
end
function SCROLLBAR.scroll_to(scrollbar, x, y)
	assert(scrollbar)
	assert(x)
	assert(y)
	local handle_pos = gui.get_position(scrollbar.node)

	x = core.clamp(x, 0, 1)
	y = core.clamp(y, 0, 1)
	if scrollbar.vertical then
		local adjusted_height = (scrollbar.bounds_size.y - scrollbar.handle_size.y)
		local offset_y = scrollbar.vertical and (scrollbar.handle_size.y / 2) or 0
		handle_pos.y = offset_y + adjusted_height - y * adjusted_height
	else
		local adjusted_width = (scrollbar.bounds_size.x - scrollbar.handle_size.x)
		local offset_x = scrollbar.vertical and 0 or (scrollbar.handle_size.x / 2)
		handle_pos.x = offset_x + adjusted_width - x * adjusted_width
	end
	gui.set_position(scrollbar.node, handle_pos)
	scrollbar.scroll.y = y
end
function SCROLLBAR.set_visible(scrollbar, visible)
	gui.set_enabled(scrollbar.node, visible)
end
function SCROLLBAR.set_long_pressed_time(scrollbar, time)
	scrollbar.long_pressed_time = time
end


function M.vertical(handle_id, bounds_id, action_id, action, fn, refresh_fn)
	handle_id = core.to_hash(handle_id)
	bounds_id = core.to_hash(bounds_id)
	local handle = gui.get_node(handle_id)
	local bounds = gui.get_node(bounds_id)
	assert(handle)
	assert(bounds)
	local scrollbar = core.instance(handle_id, scrollbars, SCROLLBAR)
	scrollbar.scroll = scrollbar.scroll or vmath.vector3(0, 0, 0)
	scrollbar.vertical = true

	local handle_size = gui.get_size(handle)
	local bounds_size = gui.get_size(bounds)

	scrollbar.enabled = core.is_enabled(handle)
	scrollbar.node = handle
	scrollbar.bounds = bounds
	scrollbar.bounds_size = bounds_size
	scrollbar.handle_size = handle_size

	if action then
		scrollbar.refresh_fn = refresh_fn

		local action_pos = vmath.vector3(action.x, action.y, 0)

		core.clickable(scrollbar, action_id, action)
		if scrollbar.pressed_now or scrollbar.pressed then
			local bounds_pos = core.get_root_position(bounds)
			local size = bounds_size.y - handle_size.y
			local ratio = (size - (action_pos.y - bounds_pos.y - (scrollbar.handle_size.y / 2))) / size
			SCROLLBAR.scroll_to(scrollbar, 0, ratio)
			fn(scrollbar)
		end
	else
		SCROLLBAR.scroll_to(scrollbar, 0, scrollbar.scroll.y)
	end

	scrollbar.refresh()
	return scrollbar
end

setmetatable(M, {
	__call = function(_, ...)
		return M.scrollbar(...)
	end
})

return M
