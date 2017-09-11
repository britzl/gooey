local gooey = require "gooey.gooey"


local M = {}


function M.acquire_input()
	gooey.acquire_input()
end

function M.button(node_id, action_id, action, fn)
	local button = gooey.button(node_id .. "/bg", action_id, action, fn)
	if button.pressed then
		gui.play_flipbook(button.node, "button_pressed")
	else
		gui.play_flipbook(button.node, "button_normal")
	end
	return button
end


function M.checkbox(node_id, action_id, action, fn)
	local checkbox = gooey.checkbox(node_id .. "/box", action_id, action, fn)
	if checkbox.pressed and not checkbox.checked then
		gui.play_flipbook(checkbox.node, "checkbox_pressed")
	elseif checkbox.pressed and checkbox.checked then
		gui.play_flipbook(checkbox.node, "checkbox_checked_pressed")
	elseif checkbox.checked then
		gui.play_flipbook(checkbox.node, "checkbox_checked_normal")
	else
		gui.play_flipbook(checkbox.node, "checkbox_normal")
	end
	return checkbox
end


local function update_radiobutton(radio)
	if radio.pressed and not radio.selected then
		gui.play_flipbook(radio.node, "radio_pressed")
	elseif radio.pressed and radio.selected then
		gui.play_flipbook(radio.node, "radio_checked_pressed")
	elseif radio.selected then
		gui.play_flipbook(radio.node, "radio_checked_normal")
	else
		gui.play_flipbook(radio.node, "radio_normal")
	end
end

function M.radiogroup(group_id, action_id, action, fn)
	local radiobuttons = gooey.radiogroup(group_id, action_id, action, fn)
	for _,radio in ipairs(radiobuttons) do
		update_radiobutton(radio)
	end
	return radiobuttons
end

function M.radio(node_id, group_id, action_id, action, fn)
	local radio = gooey.radio(node_id .. "/button", group_id, action_id, action, fn)
	update_radiobutton(radio)
	return radio
end


function M.input(node_id, keyboard_type, action_id, action, empty_text)
	local input = gooey.input(node_id .. "/text", keyboard_type, action_id, action)
	
	if input.empty and not input.selected then
		gui.set_text(input.node, empty_text)
	end

	local cursor = gui.get_node(node_id .. "/cursor")
	if input.selected then
		gui.set_enabled(cursor, true)
		gui.set_position(cursor, vmath.vector3(14 + input.text_width, 0, 0))
		gui.cancel_animation(cursor, gui.PROP_COLOR)
		gui.set_color(cursor, vmath.vector4(1))
		gui.animate(cursor, gui.PROP_COLOR, vmath.vector4(1,1,1,0), gui.EASING_INSINE, 0.8, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	else
		gui.set_enabled(cursor, false)
		gui.cancel_animation(cursor, gui.PROP_COLOR)
	end
	return input
end

return M