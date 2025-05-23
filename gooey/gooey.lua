local core = require "gooey.internal.core"
local checkbox = require "gooey.internal.checkbox"
local button = require "gooey.internal.button"
local radio = require "gooey.internal.radio"
local list = require "gooey.internal.list"
local input = require "gooey.internal.input"
local scrollbar = require "gooey.internal.scrollbar"
local actions = require "gooey.actions"

local M = {}

local groups = {}
local current_group = nil

--- Check if a node is enabled. This is done by not only
-- looking at the state of the node itself but also it's
-- ancestors all the way up the hierarchy
-- @param node
-- @return true if node and all ancestors are enabled
function M.is_enabled(node)
	return core.is_enabled(node)
end


--- Convenience function to acquire input focus
function M.acquire_input()
	msg.post(".", "acquire_input_focus")
end


--- Convenience function to release input focus
function M.release_input()
	msg.post(".", "release_input_focus")
end


function M.create_theme()
	local theme = {}

	theme.is_enabled = function(component)
		if component.node then
			return M.is_enabled(component.node)
		end
	end

	theme.set_enabled = function(component, enabled)
		if component.node then
			gui.set_enabled(component.node, enabled)
		end
	end

	theme.acquire_input = M.acquire_input
	theme.release_input = M.release_input

	theme.group = M.group

	return theme
end


--- Mask text by replacing every character with a mask
-- character
-- @param text
-- @param mask
-- @return Masked text
function M.mask_text(text, mask)
	return input.mask_text(text, mask)
end


-- no-operation
-- empty function to use when no component callback function was provided
local function nop() end


function M.button(node_id, action_id, action, fn, refresh_fn)
	local b = button(node_id, action_id, action, fn or nop, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = b
	end
	return b
end


function M.checkbox(node_id, action_id, action, fn, refresh_fn)
	local c = checkbox(node_id, action_id, action, fn or nop, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = c
	end
	return c
end


function M.radiogroup(group_id, action_id, action, fn)
	return radio.group(group_id, action_id, action, fn or nop, refresh_fn)
end


function M.radio(node_id, group_id, action_id, action, fn, refresh_fn)
	local r = radio.button(node_id, group_id, action_id, action, fn or nop, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = r
	end
	return r
end

function M.static_list(list_id, stencil_id, item_ids, action_id, action, config, fn, refresh_fn)
	local l = list.static(list_id, stencil_id, item_ids, action_id, action, config, fn or nop, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = l
	end
	return l
end

function M.horizontal_static_list(list_id, stencil_id, item_ids, action_id, action, config, fn, refresh_fn)
	config = config or {}
	config.horizontal = true
	return M.static_list(list_id, stencil_id, item_ids, action_id, action, config, fn or nop, refresh_fn)
end

function M.vertical_static_list(list_id, stencil_id, item_ids, action_id, action, config, fn, refresh_fn)
	return M.static_list(list_id, stencil_id, item_ids, action_id, action, config, fn or nop, refresh_fn)
end

function M.dynamic_list(list_id, stencil_id, item_id, data, action_id, action, config, fn, refresh_fn)
	fn = fn or nop
	local l = list.dynamic(list_id, stencil_id, item_id, data, action_id, action, config, function(...)
		local data_changed = fn(...)
		if data_changed then
			list.dynamic(list_id, stencil_id, item_id, data, nil, nil, config, nop, refresh_fn)
		end
	end, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = l
	end
	return l
end

function M.horizontal_dynamic_list(list_id, stencil_id, item_id, data, action_id, action, config, fn, refresh_fn)
	config = config or {}
	config.horizontal = true
	return M.dynamic_list(list_id, stencil_id, item_id, data, action_id, action, config, fn or nop, refresh_fn)
end

function M.vertical_dynamic_list(list_id, stencil_id, item_id, data, action_id, action, config, fn, refresh_fn)
	return M.dynamic_list(list_id, stencil_id, item_id, data, action_id, action, config, fn or nop, refresh_fn)
end

function M.vertical_scrollbar(handle_id, bounds_id, action_id, action, config, fn, refresh_fn)
	local sb = scrollbar.vertical(handle_id, bounds_id, action_id, action, config, fn or nop, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = sb
	end
	return sb
end

function M.horizontal_scrollbar(handle_id, bounds_id, action_id, action, config, fn, refresh_fn)
	local sb = scrollbar.horizontal(handle_id, bounds_id, action_id, action, config, fn or nop, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = sb
	end
	return sb
end


--- Input text
-- (from dirty larry with modifications)
-- @param node_id Id of a text node
-- @param keyboard_type Keyboard type to use (from gui.KEYBOARD_TYPE_*)
-- @param action_id
-- @param action
-- @param config Optional config table. Accepted values
--  * empty_text (string) - Text to show when the field is empty
--	* max_length (number) - Maximum number of characters that can be entered
--  * allowed_characters (string) - Lua pattern to filter which characters to accept
-- @return Component state
function M.input(node_id, keyboard_type, action_id, action, config, refresh_fn)
	local i = input(node_id, keyboard_type, action_id, action, config, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = i
	end
	return i
end


--- A group of components
-- Use this to collect input consume state from multiple components in a convenient way
-- @param id
-- @param fn Interact with gooey components inside this function
-- @return Group state
function M.group(id, action_id, action, fn)
	assert(id, "You must provide a group id")
	assert(fn, "You must provide a group function")
	if not groups[id] then
		groups[id] = {
			id = id,
			consumed = false,     -- true if a component in the group consumed input
			components = {},      -- list of all components in the group
			focus = {
				component = nil,  -- component with focus
				index = nil,      -- index of component with focus
			},
		}
	end
	local group = groups[id]
	local components = group.components
	local focus = group.focus

	-- clear list of components
	for i=1,#components do
		components[i] = nil
	end
	-- clear focus component
	focus.component = nil

	-- set current group and call the group function
	-- then reset current group again once we're done
	current_group = group
	fn()
	current_group = nil

	-- exit early if there are no components in the group
	if #components == 0 then
		focus.component = nil
		focus.index = nil
		return group
	end

	-- go through the components in the group and check if
	-- any of them consumed input
	-- also check which component has focus and if another
	-- component was selected and should gain focus
	local consumed = false
	local current_focus_index = nil
	local new_focus_index = nil
	for i=1,#components do
		local component = components[i]
		consumed = component.consumed or consumed
		if component.focus then
			current_focus_index = i
		elseif component.released_now or component.released_item_now then
			new_focus_index = i
		end
	end

	if not new_focus_index then
		new_focus_index = current_focus_index
	end

	-- assign focus to the next component or first if
	-- no component currently has focus
	if not consumed then
		if action_id == actions.NEXT then
			if action.pressed then
				if new_focus_index then
					new_focus_index = new_focus_index + 1
					if new_focus_index > #components then
						new_focus_index = 1
					end
				else
					new_focus_index = 1
				end
			end
			consumed = true
		elseif action_id == actions.PREVIOUS then
			if action.pressed then
				if new_focus_index then
					new_focus_index = new_focus_index - 1
					if new_focus_index == 0 then
						new_focus_index = #components
					end
				else
					new_focus_index = 1
				end
			end
			consumed = true
		end
	end

	-- change focus or keep same
	if current_focus_index ~= new_focus_index then
		if current_focus_index then
			local component = components[current_focus_index]
			component.focus = false
			component.refresh()
			focus.index = nil
			focus.component = nil
		end
		if new_focus_index then
			local component = components[new_focus_index]
			component.focus = true
			component.refresh()
			focus.index = new_focus_index
			focus.component = component
		end
	elseif current_focus_index then
		focus.index = current_focus_index
		focus.component = components[current_focus_index]
	end
	group.consumed = consumed
	return group
end

function M.set_focus(group, index)
	assert(group)
	assert(index)
	local component = group.components[index]
	if component then
		component.focus = true
		component.refresh()
		group.focus.index = index
		group.focus.component = component
	end
end

return M