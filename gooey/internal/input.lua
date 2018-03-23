local core = require "gooey.internal.core"

local M = {}

M.TOUCH = hash("touch")
M.TEXT = hash("text")
M.MARKED_TEXT = hash("marked_text")
M.BACKSPACE = hash("backspace")

local inputfields = {}

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
	local result = gui.get_text_metrics(font, text, 0, false, 0, 0).width
	for i=#text, 1, -1 do
		local c = string.sub(text, i, i)
		if c ~= ' ' then
			break
		end
		result = result + get_space_width(font)
	end
	return result
end


function M.utf8_gfind(text)
	return text:gfind("([%z\1-\127\194-\244][\128-\191]*)")
end

function M.input(node_id, keyboard_type, action_id, action, config, refresh_fn)
	node_id = core.to_hash(node_id)
	local node = gui.get_node(node_id)
	assert(node)

	local input = core.instance(node_id, inputfields)
	input.enabled = core.is_enabled(node)
	input.node = node
	input.refresh_fn = refresh_fn

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
		input.selected_now = released and input.pressed and input.over
		input.pressed = pressed or (input.pressed and not released)
		if input.selected_now then
			input.selected = true
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
					input.text = input.text .. action.text
					if config and config.max_length then
						input.text = input.text:sub(1, config.max_length)
					end
					input.marked_text = ""
				end
				-- new marked text input (uncommitted text)
			elseif action_id == M.MARKEDTEXT then
				input.marked_text = action.text or ""
				-- input deletion
			elseif action_id == M.BACKSPACE and (action.pressed or action.repeated) then
				local last_s = 0
				for uchar in M.utf8_gfind(input.text) do
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

		input.text_width = get_text_width(input.node, text)		
		input.marked_text_width = get_text_width(input.node, marked_text)

		if input.selected then
			gui.set_text(input.node, text .. marked_text)
		end
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