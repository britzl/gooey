local gooey = require "gooey.gooey"
local utils = require "gooey.themes.utils"

local M = gooey.create_theme()

local LISTITEM = hash("buttonSquare_blue")
local BUTTON_SQUARE_PRESSED = hash("buttonSquare_blue_pressed")
local BUTTON_SQUARE = hash("buttonSquare_blue")
local CHECKBOX_PRESSED = hash("checkbox_blue_pressed")
local CHECKBOX = hash("checkbox_blue")
local RADIO_PRESSED = hash("buttonRound_blue_pressed")
local RADIO = hash("buttonRound_blue")


local function update_button(button)
	if button.pressed_now or button.released_now then
		utils.shake(button.node, vmath.vector3(1))
	end
	if button.pressed then
		gui.play_flipbook(button.node, BUTTON_SQUARE_PRESSED)
	else
		gui.play_flipbook(button.node, BUTTON_SQUARE)
	end
end
function M.button(node_id, action_id, action, fn)
	return gooey.button(node_id .. "/bg", action_id, action, fn, update_button)
end


local function update_checkbox(checkbox)
	if checkbox.pressed_now or checkbox.released_now then
		utils.shake(checkbox.node, vmath.vector3(1))
	end
	if checkbox.pressed then
		gui.play_flipbook(checkbox.node, CHECKBOX_PRESSED)
	elseif checkbox.checked then
		gui.play_flipbook(checkbox.node, CHECKBOX_PRESSED)
	else
		gui.play_flipbook(checkbox.node, CHECKBOX)
	end
end
function M.checkbox(node_id, action_id, action, fn)
	return gooey.checkbox(node_id .. "/box", action_id, action, fn, update_checkbox)
end


local function update_radiobutton(radio)
	if radio.pressed_now or radio.released_now then
		utils.shake(radio.node, vmath.vector3(1))
	end
	if radio.pressed then
		gui.play_flipbook(radio.node, RADIO_PRESSED)
	elseif radio.selected then
		gui.play_flipbook(radio.node, RADIO_PRESSED)
	else
		gui.play_flipbook(radio.node, RADIO)
	end		
end
function M.radiogroup(group_id, action_id, action, fn)
	return gooey.radiogroup(group_id, action_id, action, fn)
end
function M.radio(node_id, group_id, action_id, action, fn)
	return gooey.radio(node_id .. "/button", group_id, action_id, action, fn, update_radiobutton)
end


local function update_input(input, config, node_id)
	if input.selected_now then
		gui.play_flipbook(gui.get_node(node_id .. "/bg"), BUTTON_SQUARE_PRESSED)
	elseif input.deselected_now then
		gui.play_flipbook(gui.get_node(node_id .. "/bg"), BUTTON_SQUARE_PRESSED)
	end

	if input.empty and not input.selected then
		gui.set_text(input.node, config and config.empty_text or "")
	end

	local cursor = gui.get_node(node_id .. "/cursor")
	if input.selected then
		gui.set_enabled(cursor, true)
		gui.set_position(cursor, vmath.vector3(4 + input.total_width, 0, 0))
		gui.cancel_animation(cursor, gui.PROP_COLOR)
		gui.set_color(cursor, vmath.vector4(1))
		gui.animate(cursor, gui.PROP_COLOR, vmath.vector4(1,1,1,0), gui.EASING_INSINE, 0.8, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	else
		gui.set_enabled(cursor, false)
		gui.cancel_animation(cursor, gui.PROP_COLOR)
	end
end
function M.input(node_id, keyboard_type, action_id, action, config)
	return gooey.input(node_id .. "/text", keyboard_type, action_id, action, config, function(input)
		update_input(input, config, node_id)
	end)
end


local function update_listitem(list, item)
	local pos = gui.get_position(item.root)
	if item.index == list.selected_item then
		pos.x = 4
		gui.play_flipbook(item.root, LISTITEM)
	elseif item.index == list.pressed_item then
		pos.x = 1
		gui.play_flipbook(item.root, LISTITEM)
	elseif item.index == list.over_item_now then
		pos.x = 1
		gui.play_flipbook(item.root, LISTITEM)
	elseif item.index == list.out_item_now then
		pos.x = 0
		gui.play_flipbook(item.root, LISTITEM)
	elseif item.index ~= list.over_item then
		pos.x = 0
		gui.play_flipbook(item.root, LISTITEM)
	end
	gui.set_position(item.root, pos)
end

local function update_static_list(list)
	for _,item in ipairs(list.items) do
		update_listitem(list, item)
	end
end
function M.static_list(list_id, item_ids, action_id, action, config, fn)
	return gooey.static_list(list_id, list_id .. "/stencil", item_ids, action_id, action, config, fn, update_static_list)
end


local function update_dynamic_list(list)
	for _,item in ipairs(list.items) do
		update_listitem(list, item)
		gui.set_text(item.nodes[hash(list.id .. "/listitem_text")], tostring(item.data or "-"))
	end
end
function M.dynamic_list(list_id, data, action_id, action, config, fn)
	return gooey.dynamic_list(list_id, list_id .. "/stencil", list_id .. "/listitem_bg", data, action_id, action, config, fn, update_dynamic_list)
end


return M