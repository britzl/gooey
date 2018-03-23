local core = require "gooey.internal.core"

local M = {}

local static_lists = {}
local dynamic_lists = {}


-- get a list instance and set up some basics of a list on the instance
local function get_instance(stencil_id, refresh_fn, lists)
	stencil_id = core.to_hash(stencil_id)
	local list, state = core.instance(stencil_id, static_lists)
	state.stencil = state.stencil or gui.get_node(stencil_id)	
	state.refresh_fn = refresh_fn
	list.enabled = core.is_enabled(state.stencil)
	return list, state
end


local function handle_list_interaction(list, state, action_id, action, click_fn)
	local over_stencil = gui.pick_node(state.stencil, action.x, action.y)

	local touch = action_id == M.TOUCH
	local pressed = touch and action.pressed and over_stencil
	local released = touch and action.released
	local action_pos = vmath.vector3(action.x, action.y, 0)
	if pressed then
		state.pressed_pos = action_pos
		state.action_pos = action_pos
		list.pressed = true
	elseif released then
		list.pressed = false
	end
	
	state.scrolling = list.pressed and vmath.length(state.pressed_pos - action_pos) > 10
	if state.scrolling then
		local delta = action_pos - state.action_pos
		delta.x = 0
		state.action_pos = action_pos
		state.scroll_pos = state.scroll_pos + delta
		state.scroll_pos.y = math.min(state.scroll_pos.y, state.max_y)
		state.scroll_pos.y = math.max(state.scroll_pos.y, state.min_y)
	end

	-- find which item (if any) that the touch event is over
	local over_item
	for i=1,#list.items do
		local item = list.items[i]
		if gui.pick_node(item.root, action.x, action.y) then
			over_item = item.index
			break
		end	
	end

	-- handle list item over state
	list.out_item_now = (list.over_item ~= over_item) and list.over_item or nil
	list.over_item_now = (list.over_item_now ~= list.over_item) and over_item or nil
	list.over_item = over_item

	-- handle list item clicks
	list.released_item_now = nil
	list.pressed_item_now = nil
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
	if list.released_item_now then
		if not state.scrolling and list.released_item_now == over_item then
			list.selected_item = list.released_item_now
			click_fn(list)
		end
		state.scrolling = false
	end
end


-- A static list where the list item nodes are already created
function M.static(root_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
	local list, state = get_instance(stencil_id, refresh_fn, static_lists)
	list.root = list.root or gui.get_node(root_id)

	-- populate list items (once!)
	if not list.items then
		list.items = {}
		for i,item_id in ipairs(item_ids) do
			local node = gui.get_node(item_id)
			list.items[i] = {
				root = node,
				nodes = { [core.to_hash(item_id)] = node },
				index = i
			}
		end

		local last_item = list.items[#list.items].root
		local total_height = last_item and (math.abs(gui.get_position(last_item).y) + gui.get_size(last_item).y / 2) or 0
		local list_height = gui.get_size(list.root).y
		
		state.scroll_pos = vmath.vector3(0)
		state.min_y = 0
		state.max_y = total_height - list_height
	end

	if #list.items == 0 then
		if refresh_fn then refresh_fn(list) end
		return list
	end
	
	if list.enabled then
		handle_list_interaction(list, state, action_id, action, fn)
		gui.set_position(list.root, state.scroll_pos)
	end
	if refresh_fn then refresh_fn(list) end
	return list
end



--- A dynamic list where the nodes are reused to present a large list of items
function M.dynamic(list_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn)
	local list, state = get_instance(stencil_id, refresh_fn, dynamic_lists)
	
	list.id = list_id

	-- create list items (once!)
	if not list.items then
		list.items = {}
		item_id = core.to_hash(item_id)
		local item_node = gui.get_node(item_id)
		local item_pos = gui.get_position(item_node)
		local item_size = gui.get_size(item_node)
		local stencil_size = gui.get_size(state.stencil)
		local item_count = math.min(math.ceil(stencil_size.y / item_size.y) + 1, #data)
		for i=1,item_count do
			local nodes = gui.clone_tree(item_node)
			list.items[i] = {
				root = nodes[item_id],
				nodes = nodes,
				index = i,
				data = data[i] or ""
			}
			local pos = item_pos - vmath.vector3(0, item_size.y * (i - 1), 0)
			gui.set_position(list.items[i].root, pos)
		end
		gui.delete_node(item_node)

		list.item_size = item_size
		state.first_item_pos = gui.get_position(list.items[1].root)
		state.scroll_pos = vmath.vector3(0)
		state.min_y = 0
		state.max_y = (#data * item_size.y) - stencil_size.y
	end

	-- bail early if the list is empty
	if #list.items == 0 then
		if refresh_fn then refresh_fn(list) end
		return list
	end

	if not action_id and not action then
		if refresh_fn then refresh_fn(list) end
		return list
	end
	
	if list.enabled then

		handle_list_interaction(list, state, action_id, action, fn)

		-- re-position the list items if we're scrolling
		-- re-assign list item indices and data
		if state.scrolling then
			local top_i = state.scroll_pos.y / list.item_size.y
			local top_y = state.scroll_pos.y % list.item_size.y
			local first_index = 1 + math.floor(top_i)

			
			for i=1,#list.items do
				local item = list.items[i]
				local item_pos = gui.get_position(item.root)
				item_pos.y = state.first_item_pos.y - (list.item_size.y * (i - 1)) + top_y
				gui.set_position(item.root, item_pos)

				local index = first_index + i - 1
				item.index = index
				item.data = data[index] or ""
			end
		end
	end

	if refresh_fn then refresh_fn(list) end

	return list
end

setmetatable(M, {
	__call = function(_, ...)
		return M.static(...)
	end
})

return M