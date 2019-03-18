local core = require "gooey.internal.core"
local actions = require "gooey.actions"

local M = {}

local static_lists = {}
local dynamic_lists = {}


-- update the positions of the list items and set their data indices
local function update_dynamic_listitem_positions(list)
	local top_i = list.scroll_pos.y / list.item_size.y
	local top_y = list.scroll_pos.y % list.item_size.y
	local first_index = 1 + math.floor(top_i)
	for i=1,#list.items do
		local item = list.items[i]
		local item_pos = gui.get_position(item.root)
		local index = first_index + i - 1
		item.index = index
		item_pos.y = list.first_item_pos.y - (list.item_size.y * (i - 1)) + top_y
		gui.set_position(item.root, item_pos)
	end
end

-- assign new data to the list items
local function update_dynamic_listitem_data(list)
	for i=1,#list.items do
		local item = list.items[i]
		item.data = list.data[item.index] or ""
	end
end

local function update_static_listitems(items, start)
	local item_pos = start
	for i=1,#items do
		local item = items[i]
		item_pos.y = item_pos.y - item.size.y / 2
		gui.set_position(item.root, item_pos)
		item_pos.y = item_pos.y - item.size.y / 2
	end
end


-- instance functions
local LIST = {}
function LIST.refresh(list)
	if list.refresh_fn then list.refresh_fn(list) end
end
function LIST.set_visible(list, visible)
	gui.set_enabled(list.node, visible)
end
function LIST.scroll_to(list, x, y)
	list.consumed = true
	list.scrolling = true
	list.scroll_pos.y = list.min_y + (list.max_y - list.min_y) * y
	if list.static then
		update_static_listitems(list.items, vmath.vector3(list.scroll_pos))
	elseif list.dynamic then
		update_dynamic_listitem_positions(list)
		update_dynamic_listitem_data(list, data)
	end
end


-- get a list instance and set up some basics of a list on the instance
local function get_instance(list_id, stencil_id, refresh_fn, lists)
	stencil_id = core.to_hash(stencil_id)
	local list = core.instance(stencil_id, lists, LIST)
	list.id = list_id
	list.scroll = list.scroll or vmath.vector3()
	list.stencil = list.stencil or gui.get_node(stencil_id)	
	list.stencil_size = list.stencil_size or gui.get_size(list.stencil)
	list.refresh_fn = refresh_fn
	list.enabled = core.is_enabled(list.stencil)
	return list
end


local function handle_input(list, action_id, action, click_fn)
	local over_stencil = gui.pick_node(list.stencil, action.x, action.y)

	local touch = action_id == actions.TOUCH
	local scroll_up = action_id == actions.SCROLL_UP
	local scroll_down = action_id == actions.SCROLL_DOWN
	local pressed = touch and action.pressed and over_stencil
	local released = touch and action.released
	local action_pos = vmath.vector3(action.x, action.y, 0)
	if pressed then
		list.pressed_pos = action_pos
		list.action_pos = action_pos
		list.pressed = true
	elseif released then
		list.pressed = false
	end
	list.consumed = false
	
	-- handle mouse-wheel scrolling
	if over_stencil and (scroll_up or scroll_down) then
		list.consumed = true
		list.scrolling = true
		-- reset scroll speed if the time between two scroll events is too large
		local time = os.time()
		list.scroll_time = list.scroll_time or time
		if (time - list.scroll_time) > 1 then
			list.scroll_speed = 0
		end
		list.scroll_speed = list.scroll_speed or 0
		list.scroll_speed = math.min(list.scroll_speed + 0.25, 10)
		list.scroll_time = time
		list.scroll_pos.y = list.scroll_pos.y + ((scroll_up and 1 or -1) * list.scroll_speed)
		if action.released then
			list.scrolling = false
		end
	-- handle touch and drag scrolling
	elseif list.pressed and vmath.length(list.pressed_pos - action_pos) > 10 then
		list.consumed = true
		list.scrolling = true
		list.scroll_pos.y = list.scroll_pos.y + (action_pos.y - list.action_pos.y)
		list.action_pos = action_pos
	else
		list.scrolling = false
	end
	-- limit to scroll bounds
	if list.scrolling then
		list.scroll_pos.y = math.min(list.scroll_pos.y, list.max_y)
		list.scroll_pos.y = math.max(list.scroll_pos.y, list.min_y)
		list.scroll.y = 1 - (list.scroll_pos.y / list.max_y)
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
		if not list.scrolling and list.released_item_now == over_item then
			list.selected_item = list.released_item_now
			click_fn(list)
		end
		list.scrolling = false
	end
end


-- A static list where the list item nodes are already created
function M.static(list_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
	local list = get_instance(list_id, stencil_id, refresh_fn, static_lists)
	list.static = true
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
			gui.set_parent(node, list.stencil)
		end
		update_static_listitems(list.items, vmath.vector3(0))
		
		local last_item = list.items[#list.items].root
		local total_height = last_item and (math.abs(gui.get_position(last_item).y) + gui.get_size(last_item).y / 2) or 0
		local list_height = gui.get_size(list.stencil).y
		
		list.scroll_pos = vmath.vector3(0)
		list.min_y = 0
		list.max_y = total_height - list_height
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
		handle_input(list, action_id, action, fn)
		
		-- re-position the list items if we're scrolling
		if list.scrolling then
			update_static_listitems(list.items, vmath.vector3(list.scroll_pos))
		end
	end
	if refresh_fn then refresh_fn(list) end
	return list
end


--- A dynamic list where the nodes are reused to present a large list of items
function M.dynamic(list_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn)
	local list = get_instance(list_id, stencil_id, refresh_fn, dynamic_lists)
	list.dynamic = true
	list.data = data

	-- create list items (once!)
	if not list.items then
		item_id = core.to_hash(item_id)
		local item_node = gui.get_node(item_id)
		local item_pos = gui.get_position(item_node)
		local item_size = gui.get_size(item_node)
		list.items = {}
		list.item_size = item_size
		list.scroll_pos = vmath.vector3(0)
		list.first_item_pos = vmath.vector3(item_pos)
		list.data_size = nil
		
		local item_count = math.ceil(list.stencil_size.y / item_size.y) + 1
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
	local data_size_changed = list.data_size ~= #data
	if not list.data_size or data_size_changed then
		list.data_size = #data		
		list.min_y = 0
		list.max_y = (#data * list.item_size.y) - list.stencil_size.y
		list.selected_item = nil
		-- fewer items in the list than visible
		-- assign indices and disable list items
		if #data < #list.items then
			for i=1,#list.items do
				local item = list.items[i]
				item.index = i
				gui.set_enabled(item.root, (i <= #data))
			end
			list.scroll_pos.y = 0
			update_dynamic_listitem_positions(list)
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
	if list.data_size == 0 then
		if refresh_fn then refresh_fn(list) end
		return list
	end

	if list.enabled and (action_id or action) then
		handle_input(list, action_id, action, fn)
		-- re-position the list items if we're scrolling
		-- re-assign list item indices and data
		if list.scrolling then
			update_dynamic_listitem_positions(list)
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