local core = require "gooey.internal.core"

local M = {}

local lists = {}

function M.list(root_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
	root_id = core.to_hash(root_id)
	local root = gui.get_node(root_id)
	assert(root)

	local list = core.instance(root_id, lists)
	list.enabled = core.is_enabled(root)
	list.root = root
	list.items = {}
	list.refresh_fn = refresh_fn

	if #item_ids == 0 then
		if refresh_fn then refresh_fn(list) end
		return list
	end

	local stencil = gui.get_node(stencil_id)
	local over_stencil = gui.pick_node(stencil, action.x, action.y)

	local over_item
	for i=1,#item_ids do
		local item = gui.get_node(item_ids[i])
		list.items[i] = item
		if over_stencil and gui.pick_node(item, action.x, action.y) then
			over_item = i
		end		
	end
	list.over = over_item ~= nil
	list.out_item_now = (list.over_item ~= over_item) and list.over_item or nil
	list.over_item_now = (list.over_item_now ~= list.over_item) and over_item or nil
	list.over_item = over_item


	local first_item = list.items[1]
	local last_item = list.items[#list.items]
	local total_height = math.abs(gui.get_position(last_item).y) + gui.get_size(last_item).y / 2
	local list_height = gui.get_size(list.root).y

	list.released_item_now = nil
	list.pressed_item_now = nil
	if list.enabled then
		local touch = action_id == M.TOUCH
		local pressed = touch and action.pressed and list.over
		local released = touch and action.released

		if released then
			list.released_item_now = list.pressed_item
			list.pressed_item = nil
		end

		if pressed and list.pressed_item_now ~= over_item then
			list.pressed_item_now = over_item
			list.pressed_item = over_item
		else
			list.pressed_item_now = nil
		end

		if list.pressed_item_now then
			list.root_pos = gui.get_position(root)
			list.action_pos = vmath.vector3(action.x, action.y, 0)
		end

		if list.released_item_now then
			if not list.scrolling and list.released_item_now == over_item then
				list.selected_item = list.released_item_now
				fn(list)
			end
			list.scrolling = false
		end

		if list.pressed_item or list.scrolling then
			local amount = vmath.vector3(action.x, action.y, 0) - list.action_pos
			amount.x = 0
			list.scrolling = math.abs(amount.y) > 10
			local root_pos = list.root_pos + amount
			root_pos.y = math.min(root_pos.y, total_height - list_height)
			root_pos.y = math.max(root_pos.y, 0)
			gui.set_position(list.root, root_pos)
		end
	end
	if refresh_fn then refresh_fn(list) end
	return list
end

setmetatable(M, {
	__call = function(_, ...)
		return M.list(...)
	end
})

return M