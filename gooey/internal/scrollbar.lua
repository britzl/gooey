local core = require "gooey.internal.core"
local actions = require "gooey.actions"

local M = {}

local scrollbars = {}

local SCROLLBAR = {
	refresh = function(scrollbar)
		if scrollbar.refresh_fn then scrollbar.refresh_fn(button) end
	end,
	set_visible = function(button, visible)
		gui.set_enabled(scrollbar.node, visible)
	end,
}


local function scroll_to(scrollbar, ratio)
	local handle_pos = gui.get_position(scrollbar.node)

	if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
	handle_pos.y = ratio * scrollbar.bounds_size.y
	if handle_pos.y < 0 then
		handle_pos.y = 0
	elseif handle_pos.y > scrollbar.bounds_size.y then
		handle_pos.y = scrollbar.bounds_size.y
	end
	gui.set_position(scrollbar.node, handle_pos)
	scrollbar.scroll_y = 1 - ratio
end

function M.vertical(handle_id, bounds_id, action_id, action, fn, refresh_fn)
	handle_id = core.to_hash(handle_id)
	bounds_id = core.to_hash(bounds_id)
	local handle = gui.get_node(handle_id)
	local bounds = gui.get_node(bounds_id)
	assert(handle)
	assert(bounds)
	local scrollbar = core.instance(handle_id, scrollbars, SCROLLBAR)
	if action then
		local bounds_size = gui.get_size(bounds)

		scrollbar.enabled = core.is_enabled(handle)
		scrollbar.node = handle
		scrollbar.bounds = bounds
		scrollbar.bounds_size = bounds_size
		scrollbar.refresh_fn = refresh_fn

		local action_pos = vmath.vector3(action.x, action.y, 0)

		if action_id == actions.SCROLL_TO then
			scroll_to(scrollbar, action.scroll_y)
		else
			core.clickable(scrollbar, action_id, action)
			if scrollbar.pressed_now then
				scrollbar.pressed_position = action_pos
			elseif scrollbar.pressed then
				local diff = scrollbar.pressed_position.y - action_pos.y
				local ratio = (scrollbar.pressed_position.y / bounds_size.y) - (diff / bounds_size.y)
				scroll_to(scrollbar, ratio)
				action.scroll_y = scrollbar.scroll_y
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