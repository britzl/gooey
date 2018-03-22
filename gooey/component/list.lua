local core = require "gooey.internal.core"

local M = {}

local lists = {}
local dynamic_lists = {}

-- iterate listitems and find which (if any) is picked
local function find_over_item(list, action, item_fn)
	local over_item
	for i=1,#list.items do
		local item = item_fn(list, i)
		if gui.pick_node(item, action.x, action.y) then
			over_item = i
		end		
	end
	return over_item
end

local function get_static_item(list, index)
	return list.items[index]
end
local function get_dynamic_item(list, index)
	return list.items[index][list.item_id]
end


local function handle_item_interaction(list, action, pressed, released, over_item, click_fn)
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


local function handle_dynamic_item_interaction(list, action, pressed, released, click_fn)
	local over_item = find_over_item(list, action, get_dynamic_item)
	if over_item then
		over_item = list.index - 1 + over_item
	end
	handle_item_interaction(list, action, pressed, released, over_item, click_fn)
end


local function handle_static_item_interaction(list, action, pressed, released, click_fn)
	local over_item = find_over_item(list, action, get_static_item)
	handle_item_interaction(list, action, pressed, released, over_item, click_fn)
end


local function handle_list_interaction(list, action_id, action)
	local over_stencil = gui.pick_node(list.stencil, action.x, action.y)

	local touch = action_id == M.TOUCH
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
	list.scrolling = list.pressed and vmath.length(list.pressed_pos - action_pos) > 10
	return pressed, released
end

local function handle_static_list_interaction(list, action_id, action, click_fn)
	local pressed, released = handle_list_interaction(list, action_id, action)
	handle_static_item_interaction(list, action, pressed, released, click_fn)
end

local function handle_dynamic_list_interaction(list, action_id, action, click_fn)
	local pressed, released = handle_list_interaction(list, action_id, action)
	handle_dynamic_item_interaction(list, action, pressed, released, click_fn)
end

function M.list(root_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
	root_id = core.to_hash(root_id)

	local list = core.instance(root_id, lists)
	list.root = list.root or gui.get_node(root_id)
	assert(list.root)
	list.stencil = list.stencil or gui.get_node(stencil_id)	
	list.enabled = core.is_enabled(list.root)
	list.refresh_fn = refresh_fn

	-- populate list items (once!)
	if not list.items then
		list.items = {}
		for i,item_id in ipairs(item_ids) do
			list.items[i] = gui.get_node(item_id)
		end
	end

	if #item_ids == 0 then
		if refresh_fn then refresh_fn(list) end
		return list
	end
	

	local first_item = list.items[1]
	local last_item = list.items[#list.items]
	local total_height = math.abs(gui.get_position(last_item).y) + gui.get_size(last_item).y / 2
	local list_height = gui.get_size(list.root).y

	if list.enabled then
		handle_static_list_interaction(list, action_id, action, fn)

		if list.scrolling then
			local action_pos = vmath.vector3(action.x, action.y, 0)
			local delta = action_pos - list.action_pos
			delta.x = 0
			list.action_pos = action_pos
			local root_pos = gui.get_position(list.root) + delta
			root_pos.y = math.min(root_pos.y, total_height - list_height)
			root_pos.y = math.max(root_pos.y, 0)
			gui.set_position(list.root, root_pos)
		end
	end
	if refresh_fn then refresh_fn(list) end
	return list
end




function M.dynamic(list_id, root_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn)
	root_id = core.to_hash(root_id)

	local list = core.instance(root_id, dynamic_lists)
	list.root = list.root or gui.get_node(root_id)
	assert(list.root)
	
	list.enabled = core.is_enabled(list.root)
	list.id = list_id
	list.stencil = list.stencil or gui.get_node(stencil_id)
	list.item_id = core.to_hash(item_id)
	list.data = data
	list.refresh_fn = refresh_fn


	-- create list items (once!)
	if not list.items then
		list.items = {}
		local item_node = gui.get_node(list.item_id)
		local item_pos = gui.get_position(item_node)
		local item_size = gui.get_size(item_node)
		local stencil_size = gui.get_size(list.stencil)
		local item_count = math.ceil(stencil_size.y / item_size.y) + 2
		local y = -item_size.y
		for i=1,item_count do
			list.items[i] = gui.clone_tree(item_node)
			local pos =  item_pos + vmath.vector3(0, (2 - i) * item_size.y, 0)
			gui.set_position(list.items[i][list.item_id], pos)
		end
		gui.delete_node(item_node)

		list.index = 0
		list.item_size = item_size
		list.first_item_pos = gui.get_position(list.items[1][list.item_id])
		list.scroll_pos = vmath.vector3(0)
		list.max_scroll_y = (#data * item_size.y) - stencil_size.y
	end

	if list.enabled then

		handle_dynamic_list_interaction(list, action_id, action, fn)


		-- handle item scrolling
		if list.scrolling then
			-- scroll list
			local action_pos = vmath.vector3(action.x, action.y, 0)
			local delta = action_pos - list.action_pos
			delta.x = 0
			list.action_pos = action_pos
			list.scroll_pos = list.scroll_pos + delta
			if list.scroll_pos.y < 0 then
				list.scroll_pos.y = 0
			elseif list.scroll_pos.y > list.max_scroll_y then
				list.scroll_pos.y = list.max_scroll_y
			end

			-- position nodes
			local i = list.scroll_pos.y / list.item_size.y
			local y = list.scroll_pos.y % list.item_size.y
			for i=1,#list.items do
				local item = list.items[i][list.item_id]
				local pos = vmath.vector3(list.first_item_pos.x, list.first_item_pos.y - (list.item_size.y * i) + y, 0)
				gui.set_position(item, pos)
			end
			list.index = 1 + math.floor(i)
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