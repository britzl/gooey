local core = require "gooey.internal.core"
local checkbox = require "gooey.component.checkbox"
local button = require "gooey.component.button"
local radio = require "gooey.component.radio"
local list = require "gooey.component.list"
local input = require "gooey.component.input"

local M = {}

M.TOUCH = hash("touch")
M.TEXT = hash("text")
M.MARKED_TEXT = hash("marked_text")
M.BACKSPACE = hash("backspace")


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


--- Mask text by replacing every character with a mask
-- character
-- @param text
-- @param mask
-- @return Masked text
function M.mask_text(text, mask)
	mask = mask or "*"
	local masked_text = ""
	for uchar in input.utf8_gfind(text) do
		masked_text = masked_text .. mask
	end
	return masked_text
end


function M.button(node_id, action_id, action, fn, refresh_fn)
	button.TOUCH = M.TOUCH
	return button(node_id, action_id, action, fn, refresh_fn)
end


function M.checkbox(node_id, action_id, action, fn, refresh_fn)
	checkbox.TOUCH = M.TOUCH
	return checkbox(node_id, action_id, action, fn, refresh_fn)
end


function M.radiogroup(group_id, action_id, action, fn)
	radio.TOUCH = M.TOUCH
	return radio.group(group_id, action_id, action, fn, refresh_fn)
end


function M.radio(node_id, group_id, action_id, action, fn, refresh_fn)
	radio.TOUCH = M.TOUCH
	return radio.button(node_id, group_id, action_id, action, fn, refresh_fn)
end


function M.static_list(list_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
	list.TOUCH = M.TOUCH
	return list.static(list_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
end
function M.list(...)
	print("WARN! gooey.list() is deprecated. Use gooey.static_list()")
	return M.static_list(...)
end
function M.dynamic_list(list_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn)
	list.TOUCH = M.TOUCH
	return list.dynamic(list_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn)
end


--- Input text
-- (from dirty larry with modifications)
-- @param node_id Id of a text node
-- @param keyboard_type Keyboard type to use (from gui.KEYBOARD_TYPE_*)
-- @param action_id
-- @param action
-- @param config Optional config table. Accepted values
--	* max_length (number) - Maximum number of characters that can be entered
function M.input(node_id, keyboard_type, action_id, action, config, refresh_fn)
	input.TOUCH = M.TOUCH
	input.TEXT = M.TEXT
	input.MARKED_TEXT = M.MARKED_TEXT
	input.BACKSPACE = M.BACKSPACE
	return input(node_id, keyboard_type, action_id, action, config, refresh_fn)
end


return M