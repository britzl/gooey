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
	handle_pos.x = x * scrollbar.bounds_size.x
	handle_pos.y = y * scrollbar.bounds_size.y
	gui.set_position(scrollbar.node, handle_pos)
	scrollbar.scroll.y = 1 - y
end
function SCROLLBAR.set_visible(button, visible)
	gui.set_enabled(scrollbar.node, visible)
end


function M.vertical(handle_id, bounds_id, action_id, action, fn, refresh_fn)
	handle_id = core.to_hash(handle_id)
	bounds_id = core.to_hash(bounds_id)
	local handle = gui.get_node(handle_id)
	local bounds = gui.get_node(bounds_id)
	assert(handle)
	assert(bounds)
	local scrollbar = core.instance(handle_id, scrollbars, SCROLLBAR)
	scrollbar.scroll = scrollbar.scroll or vmath.vector3()
	if action then
		local bounds_size = gui.get_size(bounds)

		scrollbar.enabled = core.is_enabled(handle)
		scrollbar.node = handle
		scrollbar.bounds = bounds
		scrollbar.bounds_size = bounds_size
		scrollbar.refresh_fn = refresh_fn

		local action_pos = vmath.vector3(action.x, action.y, 0)

		if action_id == actions.SCROLL_TO then
			SCROLLBAR.scroll_to(scrollbar, 0, action.scroll_y)
		else
			core.clickable(scrollbar, action_id, action)
			if scrollbar.pressed_now then
				scrollbar.pressed_position = action_pos
			elseif scrollbar.pressed then
				local diff = scrollbar.pressed_position.y - action_pos.y
				local ratio = (scrollbar.pressed_position.y / bounds_size.y) - (diff / bounds_size.y)
				SCROLLBAR.scroll_to(scrollbar, 0, ratio)
				action.scroll_y = scrollbar.scroll.y
				fn(scrollbar, actions.SCROLL_TO, action)
			end
		end
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