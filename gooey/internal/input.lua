local core = require "gooey.internal.core"
local actions = require "gooey.actions"
local utf8 = require "gooey.internal.utf8"

local M = {}

local inputfields = {}
local space_width = {}

-- calculate space width with font
local function get_space_width(font)
	if not space_width[font] then
		local no_space = gui.get_text_metrics(font, "1", 0, false, 0, 0).width
		local with_space = gui.get_text_metrics(font, " 1", 0, false, 0, 0).width
		space_width[font] = with_space - no_space
	end 
	return space_width[font]
end

-- calculate text width with font with respect to trailing space (issue DEF-1761)
local function get_text_width(node, text)
	local font = gui.get_font(node)
	local scale = gui.get_scale(node)
	local result = gui.get_text_metrics(font, text, 0, false, 0, 0).width
	for i=#text, 1, -1 do
		local c = string.sub(text, i, i)
		if c ~= ' ' then
			break
		end
		result = result + get_space_width(font)
	end
	result = result * scale.x
	return result
end


function M.utf8_gfind(text, regex)
	return utf8.gmatch(text, regex)
end


--- Mask text by replacing every character with a mask
-- character
-- @param text
-- @param mask
-- @return Masked text
function M.mask_text(text, mask)
	mask = mask or "*"
	local masked_text = ""
	for uchar in M.utf8_gfind(text, ".") do
		masked_text = masked_text .. mask
	end
	return masked_text
end


-- instance functions
local INPUT = {}
function INPUT.refresh(input)
	if input.refresh_fn then input.refresh_fn(input) end
end
function INPUT.set_visible(input, visible)
	gui.set_enabled(input.node, visible)
end
function INPUT.set_text(input, text)
	input.text = text

	-- only update the text if it has changed
	local current_text = input.text .. input.marked_text
	if current_text ~= input.current_text then
		input.current_text = current_text

		-- mask text if password field
		if input.keyboard_type == gui.KEYBOARD_TYPE_PASSWORD then
			input.masked_text = M.mask_text(input.text, "*")
			input.masked_marked_text = M.mask_text(input.marked_text, "*")
		else
			input.masked_text = nil
			input.masked_marked_text = nil
		end

		-- text + marked text
		local text = input.masked_text or input.text
		local marked_text = input.masked_marked_text or input.marked_text
		input.empty = #text == 0 and #marked_text == 0

		-- measure it
		local text_width = get_text_width(input.node, text)
		local marked_text_width = get_text_width(input.node, marked_text)

		-- prevent text from overflowing the input field
		local field_width = gui.get_size(input.node).x * gui.get_scale(input.node).x
		if (text_width + marked_text_width) > field_width then
			
			-- guess how long the new text should be based on the previous text in the node
			local field_text = gui.get_text(input.node)
			local length = #field_text 

			-- generate a best guess
			local truncated = string.sub(text, -length, -1)
			local truncated_width = get_text_width(input.node, truncated)

			-- make sure the text is wider than field_width then shorten it to be within field_width
			-- doing both makes sure that the text will be correctly sized no matter if the guess was too wide or too thin
			while (truncated_width + marked_text_width) < field_width do
				length = length + 1
				truncated = string.sub(text, -length, -1)
				truncated_width = get_text_width(input.node, truncated)
			end
			while (truncated_width + marked_text_width) > field_width do
				length = length - 1
				truncated = string.sub(text, -length, -1)
				truncated_width = get_text_width(input.node, truncated)
			end

			-- finalize
			text = truncated
		end
		
		input.text_width = text_width
		input.marked_text_width = marked_text_width
		input.total_width = text_width + marked_text_width
		
		gui.set_text(input.node, text .. marked_text)
	end
end
function INPUT.set_long_pressed_time(input, time)
	input.long_pressed_time = time
end

function M.input(node_id, keyboard_type, action_id, action, config, refresh_fn)
	node_id = core.to_hash(node_id)
	local node = gui.get_node(node_id)
	assert(node)

	local input = core.instance(node_id, inputfields, INPUT)
	input.enabled = core.is_enabled(node)
	input.node = node
	input.node_id = node_id
	input.refresh_fn = refresh_fn
	input.deselected_now = false
	input.selected_now = false

	local use_marked_text = (config and config.use_marked_text == nil) and true or (config and config.use_marked_text)
	input.text = input.text or "" .. (not use_marked_text and input.marked_text or "")
	input.marked_text = input.marked_text or ""
	input.keyboard_type = keyboard_type
	
	if not action then
		input.empty = #input.text == 0 and #input.marked_text == 0
		input.refresh()
		return input
	end

	core.clickable(input, action_id, action)

	if input.enabled then
		input.deselected_now = false
		if input.released_now then
			if not input.selected then
				input.selected_now = true
			end
			input.selected = true
			input.marked_text = ""
			gui.reset_keyboard()
			gui.show_keyboard(keyboard_type, true)
		elseif input.selected and action.pressed and action_id == actions.TOUCH and not input.over then
			input.selected = false
			input.deselected_now = true
			input.text = input.text .. (not use_marked_text and input.marked_text or "")
			input.marked_text = ""
			gui.hide_keyboard()
		end

		if input.selected then
			-- new raw text input
			if action_id == actions.TEXT then
				input.consumed = true
				-- ignore return key
				if action.text == "\n" or action.text == "\r" then
					if refresh_fn then refresh_fn(input) end
					return input
				end
				local hex = string.gsub(action.text,"(.)", function (c)
					return string.format("%02X%s",string.byte(c), "")
				end)
				-- ignore arrow keys
				if not string.match(hex, "EF9C8[0-3]") then
					if not config or not config.allowed_characters or action.text:match(config.allowed_characters) then
						input.text = input.text .. action.text
						if config and config.max_length then
							input.text = utf8.sub(input.text, 1, config.max_length)
						end
					end
					input.marked_text = ""
				end
			-- new marked text input (uncommitted text)
			elseif action_id == actions.MARKED_TEXT then
				input.consumed = true
				input.marked_text = action.text or ""
				if config and config.max_length then
					input.marked_text = utf8.sub(input.marked_text, 1, config.max_length)
				end
			-- input deletion
			elseif action_id == actions.BACKSPACE and (action.pressed or action.repeated) then
				input.consumed = true
				input.text = utf8.sub(input.text, 1, -2)
			end
		end

		input.set_text(input.text)
	end
	if input.empty then
		local text = input.selected and "" or (config and config.empty_text or "")
		gui.set_text(input.node, text)
	end
	if refresh_fn then refresh_fn(input) end
	return input
end

setmetatable(M, {
	__call = function(_, ...)
		return M.input(...)
	end
})

return  M
