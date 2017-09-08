local M = {}

M.TOUCH = hash("touch")
M.TEXT = hash("text")
M.MARKED_TEXT = hash("marked_text")
M.BACKSPACE = hash("backspace")

local EMPTY = hash("")

local buttons = {}
local checkboxes = {}
local radiobuttons = {}
local lists = {}
local inputfields = {}

local utf8_gfind = "([%z\1-\127\194-\244][\128-\191]*)"

-- Convert string to hash, unless it's already a hash
-- @param str String to convert
-- @return The hashed string
local function to_hash(str)
	return type(str) == "string" and hash(str) or id
end

--- Create a unique key for an hash by combining the id with the current url
-- @param hsh Hash to create key for
-- @return Unique key based on the hash and the current url 
local function to_key(hsh)
	local url = msg.url()
	return hash_to_hex(url.socket or EMPTY)
		.. hash_to_hex(url.path or empty)
		.. hash_to_hex(url.fragment or empty)
		.. hash_to_hex(hsh)
end

--- Get an instance (table) for a node or create one if it doesn't
-- exist
-- @param node_id
-- @param instances
-- @return Instance for the node
local function instance(node_id, instances)
	local key = to_key(node_id)
	instances[key] = instances[key] or {}
	return instances[key]
end	

--- Convenience function to acquire input focus
function M.acquire_input()
	msg.post(".", "acquire_input_focus")
end

--- Convenience function to release input focus
function M.release_input()
	msg.post(".", "release_input_focus")
end

--- Check if a node is enabled. This is done by not only
-- looking at the state of the node itself but also it's
-- ancestors all the way up the hierarchy
-- @param node
-- @return true if node and all ancestors are enabled
function M.is_enabled(node)
	local parent = gui.get_parent(node)
	if parent then
		return M.is_enabled(parent)
	end
	return gui.is_enabled(node)
end

--- Mask text by replacing every character with a mask
-- character
-- @param text
-- @param mask
-- @return Masked text
function M.mask_text(text, mask)
	mask = mask or "*"
	local masked_text = ""
	for uchar in string.gfind(text, utf8_gfind) do
		masked_text = masked_text .. mask
	end
	return masked_text
end


function M.button(node_id, action_id, action, fn)
	node_id = to_hash(node_id)
	local node = gui.get_node(node_id)
	assert(node)

	local button = instance(node_id, buttons)
	button.enabled = M.is_enabled(node)
	button.node = node
	
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
	return button
end


function M.checkbox(node_id, action_id, action, fn)
	node_id = to_hash(node_id)
	local node = gui.get_node(node_id)
	assert(node)

	local checkbox = instance(node_id, checkboxes)
	checkbox.enabled = M.is_enabled(node)
	checkbox.node = node

	local over = gui.pick_node(node, action.x, action.y)
	checkbox.over_now = over and not checkbox.over
	checkbox.out_now = not over and checkbox.over
	checkbox.over = over

	if not checkbox.enabled then
		checkbox.pressed_now = false
		checkbox.released_now = false
	else
		local touch = action_id == M.TOUCH
		local pressed = touch and action.pressed and checkbox.over
		local released = touch and action.released
		checkbox.pressed_now = pressed and not checkbox.pressed
		checkbox.released_now = released and checkbox.pressed
		checkbox.pressed = pressed or (checkbox.pressed and not released)
		if checkbox.released_now and checkbox.over then
			checkbox.checked = not checkbox.checked
			fn(checkbox)
		end
	end
	return checkbox
end


function M.radio(node_id, group_id, action_id, action, fn)
	node_id = to_hash(node_id)
	group_id = to_hash(group_id)
	local node = gui.get_node(node_id)
	assert(node)

	local radio = instance(node_id, radiobuttons)
	radio.enabled = M.is_enabled(node)
	radio.node = node
	radio.group = to_key(group_id)

	local over = gui.pick_node(node, action.x, action.y)
	radio.over_now = over and not radio.over
	radio.out_now = not over and radio.over
	radio.over = over

	if not radio.enabled then
		radio.pressed_now = false
		radio.released_now = false
	else
		local touch = action_id == M.TOUCH
		local pressed = touch and action.pressed and radio.over
		local released = touch and action.released
		radio.pressed_now = pressed and not radio.pressed
		radio.released_now = released and radio.pressed
		radio.pressed = pressed or (radio.pressed and not released)
		if radio.released_now and radio.over then
			radio.selected = true
			for _,rb in pairs(radiobuttons) do
				if rb ~= radio and rb.group == radio.group and rb.selected then
					rb.selected = false
				end
			end
			fn(radio)
		end
	end
	return radio
end


function M.list(root_id, item_ids, action_id, action, fn)
	root_id = to_hash(root_id)
	local root = gui.get_node(root_id)
	assert(root)

	local list = instance(root_id, lists)
	list.enabled = M.is_enabled(root)
	list.root = root
	list.items = {}

	if #item_ids == 0 then return list end
	
	local over_item
	for i=1,#item_ids do
		local item = gui.get_node(item_ids[i])
		list.items[i] = item
		if gui.pick_node(item, action.x, action.y) then
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
	
	return list
end

-- from dirty larry with modifications
function M.input(node_id, keyboard_type, action_id, action)
	node_id = to_hash(node_id)
	local node = gui.get_node(node_id)
	assert(node)

	local input = instance(node_id, inputfields)
	input.enabled = M.is_enabled(node)
	input.node = node

	local over = gui.pick_node(node, action.x, action.y)
	input.over_now = over and not input.over
	input.out_now = not over and input.over
	input.over = over

	input.text = input.text or ""
	input.marked_text = input.marked_text or ""
	input.keyboard_type = keyboard_type

	if input.enabled then

		local touch = action_id == M.TOUCH
		local pressed = touch and action.pressed and input.over
		local released = touch and action.released
		input.deselected_now = false
		input.pressed_now = pressed and not input.pressed
		input.released_now = released and input.pressed
		input.pressed = pressed or (input.pressed and not released)
		if input.released_now then
			input.selected = input.over
			input.marked_text = ""
			gui.reset_keyboard()
			gui.show_keyboard(keyboard_type, true)
		elseif released and input.selected then
			input.deselected_now = true
			input.selected = false
			gui.hide_keyboard()
		end
	
		if input.selected then
			-- new raw text input
			if action_id == M.TEXT then
				input.text = input.text .. action.text
				input.marked_text = ""
			-- new marked text input (uncommitted text)
			elseif action_id == M.MARKEDTEXT then
				input.marked_text = action.text or ""
			-- input deletion
			elseif action_id == M.BACKSPACE and (action.pressed or action.repeated) then
				local last_s = 0
				for uchar in string.gfind(input.text, utf8_gfind) do
					last_s = string.len(uchar)
				end
				input.text = string.sub(input.text, 1, string.len(input.text) - last_s)
			end
			
			if keyboard_type == gui.KEYBOARD_TYPE_PASSWORD then
				input.masked_text = M.mask_text(input.text, "*")
				input.masked_marked_text = M.mask_text(input.marked_text, "*")
			else
				input.masked_text = nil
				input.masked_marked_text = nil
			end			
		end

		local text = input.masked_text or input.text
		local marked_text = input.masked_marked_text or input.marked_text
		input.empty = #text == 0 and #marked_text == 0
		if input.selected then
			gui.set_text(input.node, text .. marked_text)
		end
	end
	
	return input
end


return M