local core = require "gooey.internal.core"

local M = {}

local static_lists = {}
local dynamic_lists = {}

local LIST = {
	refresh = function(list)
		if list.refresh_fn then list.refresh_fn(list) end
	end,
	set_visible = function(list, visible)
		gui.set_enabled(list.node, visible)
	end,
}

-- get a list instance and set up some basics of a list on the instance
local function get_instance(list_id, stencil_id, refresh_fn, lists)
	stencil_id = core.to_hash(stencil_id)
	local list, state = core.instance(stencil_id, lists, LIST)
	list.id = list_id
	state.stencil = state.stencil or gui.get_node(stencil_id)	
	state.stencil_size = state.stencil_size or gui.get_size(state.stencil)
	state.refresh_fn = refresh_fn
	list.enabled = core.is_enabled(state.stencil)
	return list, state
end


local function handle_input(list, state, action_id, action, click_fn)
	local over_stencil = gui.pick_node(state.stencil, action.x, action.y)

	local touch = action_id == M.TOUCH
	local scroll_up = action_id == M.SCROLL_UP
	local scroll_down = action_id == M.SCROLL_DOWN
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
	list.consumed = false
	
	-- handle mouse-wheel scrolling
	if over_stencil and (scroll_up or scroll_down) then
		list.consumed = true
		state.scrolling = true
		-- reset scroll speed if the time between two scroll events is too large
		local time = os.time()
		state.scroll_time = state.scroll_time or time
		if (time - state.scroll_time) > 1 then
			state.scroll_speed = 0
		end
		state.scroll_speed = state.scroll_speed or 0
		state.scroll_speed = math.min(state.scroll_speed + 0.25, 10)
		state.scroll_time = time
		state.scroll_pos.y = state.scroll_pos.y + ((scroll_up and 1 or -1) * state.scroll_speed)
	end
	-- handle touch and drag scrolling
	if list.pressed and vmath.length(state.pressed_pos - action_pos) > 10 then
		list.consumed = true
		state.scrolling = true
		state.scroll_pos.y = state.scroll_pos.y + (action_pos.y - state.action_pos.y)
		state.action_pos = action_pos
	end
	-- limit to scroll bounds
	if state.scrolling then
		state.scroll_pos.y = math.min(state.scroll_pos.y, state.max_y)
		state.scroll_pos.y = math.max(state.scroll_pos.y, state.min_y)
	end

	-- find which item (if any) that the touch event is over
	local over_item
	for i=1,#list.items do
		local item = list.items[i]
		if gui.pick_node(item.root, action.x, action.y) then
			list.consumed = true
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


local function arrange_items(items, start)
	local item_pos = start
	for i=1,#items do
		local item = items[i]
		item_pos.y = item_pos.y - item.size.y / 2
		gui.set_position(item.root, item_pos)
		item_pos.y = item_pos.y - item.size.y / 2
	end
end

-- A static list where the list item nodes are already created
function M.static(list_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
	local list, state = get_instance(list_id, stencil_id, refresh_fn, static_lists)
	-- populate list items (once!)
	if not list.items then
		list.items = {}
		for i,item_id in ipairs(item_ids) do
			local node = gui.get_node(item_id)
			list.items[i] = {
				root = node,
				nodes = { [core.to_hash(item_id)] = node },
				index = i,
				size = gui.get_size(node),
			}
			gui.set_parent(node, state.stencil)
		end
		arrange_items(list.items, vmath.vector3(0))
		
		local last_item = list.items[#list.items].root
		local total_height = last_item and (math.abs(gui.get_position(last_item).y) + gui.get_size(last_item).y / 2) or 0
		local list_height = gui.get_size(state.stencil).y
		
		state.scroll_pos = vmath.vector3(0)
		state.min_y = 0
		state.max_y = total_height - list_height
	end

	if #list.items == 0 then
		if refresh_fn then refresh_fn(list) end
		return list
	end

	if not action_id and not action then
		if refresh_fn then refresh_fn(list) end
		return list
	end
		
	if list.enabled then
		handle_input(list, state, action_id, action, fn)
		
		-- re-position the list items if we're scrolling
		if state.scrolling then
			arrange_items(list.items, vmath.vector3(state.scroll_pos))
		end
				
	end
	if refresh_fn then refresh_fn(list) end
	return list
end


-- update the positions of the list items and set their data indices
local function update_dynamic_listitem_positions(list, state)
	local top_i = state.scroll_pos.y / list.item_size.y
	local top_y = state.scroll_pos.y % list.item_size.y
	local first_index = 1 + math.floor(top_i)
	for i=1,#list.items do
		local item = list.items[i]
		local item_pos = gui.get_position(item.root)
		local index = first_index + i - 1
		item.index = index
		item_pos.y = state.first_item_pos.y - (list.item_size.y * (i - 1)) + top_y
		gui.set_position(item.root, item_pos)
	end
end

-- assign new data to the list items
local function update_dynamic_listitem_data(list, data)
	for i=1,#list.items do
		local item = list.items[i]
		item.data = data[item.index] or ""
	end
end

--- A dynamic list where the nodes are reused to present a large list of items
function M.dynamic(list_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn)
	if action_id == hash("scroll_up") then
		pprint(action)
	end
	local list, state = get_instance(list_id, stencil_id, refresh_fn, dynamic_lists)

	-- create list items (once!)
	if not list.items then
		item_id = core.to_hash(item_id)
		local item_node = gui.get_node(item_id)
		local item_pos = gui.get_position(item_node)
		local item_size = gui.get_size(item_node)
		list.items = {}
		list.item_size = item_size
		state.first_item_pos = vmath.vector3(item_pos)
		state.scroll_pos = vmath.vector3(0)
		state.data_size = nil
		
		local item_count = math.ceil(state.stencil_size.y / item_size.y) + 1
		for i=1,item_count do
			local nodes = gui.clone_tree(item_node)
			list.items[i] = {
				root = nodes[item_id],
				nodes = nodes,
				index = i,
				size = gui.get_size(nodes[item_id]),
				data = data[i] or ""
			}
			local pos = item_pos - vmath.vector3(0, item_size.y * (i - 1), 0)
			gui.set_position(list.items[i].root, pos)
		end
		gui.delete_node(item_node)
	end

	-- recalculate size of list if the amount of data has changed
	-- deselect and realign items
	local data_size_changed = state.data_size ~= #data
	if not state.data_size or data_size_changed then
		state.data_size = #data		
		state.min_y = 0
		state.max_y = (#data * list.item_size.y) - state.stencil_size.y
		list.selected_item = nil
		-- fewer items in the list than visible
		-- assign indices and disable list items
		if #data < #list.items then
			for i=1,#list.items do
				local item = list.items[i]
				item.index = i
				gui.set_enabled(item.root, (i <= #data))
			end
			state.scroll_pos.y = 0
			update_dynamic_listitem_positions(list, state)
		-- more items in list than visible
		-- assign indices and enable list items
		else
			local first_index = list.items[1].index
			if (first_index + #list.items) > #data then
				first_index = #data - #list.items + 1
			end
			for i=1,#list.items do
				local item = list.items[i]
				item.index = first_index + i -1
				gui.set_enabled(item.root, true)
			end
		end
		
	end
	
	-- bail early if the list is empty
	if state.data_size == 0 then
		if refresh_fn then refresh_fn(list) end
		return list
	end

	if list.enabled and (action_id or action) then
		handle_input(list, state, action_id, action, fn)
		-- re-position the list items if we're scrolling
		-- re-assign list item indices and data
		if state.scrolling then
			update_dynamic_listitem_positions(list, state)
		end
	end
	
	update_dynamic_listitem_data(list, data)

	if refresh_fn then refresh_fn(list) end

	return list
end

setmetatable(M, {
	__call = function(_, ...)
		return M.static(...)
	end
})

return M