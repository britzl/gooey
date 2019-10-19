local core = require "gooey.internal.core"
local checkbox = require "gooey.internal.checkbox"
local button = require "gooey.internal.button"
local radio = require "gooey.internal.radio"
local list = require "gooey.internal.list"
local input = require "gooey.internal.input"
local scrollbar = require "gooey.internal.scrollbar"

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


function M.button(node_id, action_id, action, fn, refresh_fn)
	local b = button(node_id, action_id, action, fn, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = b
	end
	return b
end


function M.checkbox(node_id, action_id, action, fn, refresh_fn)
	local c = checkbox(node_id, action_id, action, fn, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = c
	end
	return c
end


function M.radiogroup(group_id, action_id, action, fn)
	return radio.group(group_id, action_id, action, fn, refresh_fn)
end


function M.radio(node_id, group_id, action_id, action, fn, refresh_fn)
	local r = radio.button(node_id, group_id, action_id, action, fn, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = r
	end
	return r
end

function M.static_list(list_id, stencil_id, item_ids, action_id, action, config, fn, refresh_fn)
	local l = list.static(list_id, stencil_id, item_ids, action_id, action, config, fn, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = l
	end
	return l
end

function M.horizontal_static_list(list_id, stencil_id, item_ids, action_id, action, config, fn, refresh_fn)
	config = config or {}
	config.horizontal = true
	return M.static_list(list_id, stencil_id, item_ids, action_id, action, config, fn, refresh_fn)
end

function M.vertical_static_list(list_id, stencil_id, item_ids, action_id, action, config, fn, refresh_fn)
	return M.static_list(list_id, stencil_id, item_ids, action_id, action, config, fn, refresh_fn)
end

function M.dynamic_list(list_id, stencil_id, item_id, data, action_id, action, config, fn, refresh_fn)
	local l = list.dynamic(list_id, stencil_id, item_id, data, action_id, action, config, fn, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = l
	end
	return l
end

function M.horizontal_dynamic_list(list_id, stencil_id, item_id, data, action_id, action, config, fn, refresh_fn)
	config = config or {}
	config.horizontal = true
	return M.dynamic_list(list_id, stencil_id, item_id, data, action_id, action, config, fn, refresh_fn)
end

function M.vertical_dynamic_list(list_id, stencil_id, item_id, data, action_id, action, config, fn, refresh_fn)
	return M.dynamic_list(list_id, stencil_id, item_id, data, action_id, action, config, fn, refresh_fn)
end

function M.vertical_scrollbar(handle_id, bounds_id, action_id, action, config, fn, refresh_fn)
	local sb = scrollbar.vertical(handle_id, bounds_id, action_id, action, config, fn, refresh_fn)
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
function M.group(id, fn)
	assert(id, "You must provide a group id")
	assert(fn, "You must provide a group function")
	groups[id] = groups[id] or { consumed = false, components = {} }
	local group = groups[id]

	-- set current group and call the group function
	-- then reset current group again once we're done
	current_group = group
	fn()
	current_group = nil

	-- go through the components in the group and check if
	-- any of them consumed input
	local components = group.components
	local consumed = false
	for i=1,#components do
		consumed = components[i].consumed or consumed
		components[i] = nil
	end
	group.consumed = consumed
	return group
end

return M