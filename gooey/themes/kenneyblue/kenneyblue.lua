local gooey = require "gooey.gooey"
local actions = require "gooey.actions"
local utils = require "gooey.themes.utils"

local M = gooey.create_theme()

local INPUT_FOCUS = hash("blue_button05")
local INPUT = hash("blue_button03")


local BUTTON_PRESSED = hash("blue_button05")
local BUTTON = hash("blue_button04")

local LISTITEM_SELECTED = hash("blue_button03")
local LISTITEM_PRESSED = hash("blue_button03")
local LISTITEM = hash("blue_button04")

local CHECKBOX_PRESSED = hash("grey_boxCross")
local CHECKBOX_CHECKED = hash("blue_boxCross")
local CHECKBOX = hash("grey_box")

local RADIO_PRESSED = hash("grey_boxTick")
local RADIO_SELECTED = hash("blue_boxTick")
local RADIO = hash("grey_circle")




local function refresh_button(button)
	if button.pressed_now or button.released_now then
		utils.shake(button.node, vmath.vector3(1))
	end
	if button.pressed then
		gui.play_flipbook(button.node, BUTTON_PRESSED)
	else
		gui.play_flipbook(button.node, BUTTON)
	end
end
function M.button(node_id, action_id, action, fn)
	return gooey.button(node_id .. "/bg", action_id, action, fn, refresh_button)
end


local function refresh_checkbox(checkbox)
	if checkbox.pressed_now or checkbox.released_now then
		utils.shake(checkbox.node, vmath.vector3(1))
	end
	if checkbox.pressed then
		gui.play_flipbook(checkbox.node, CHECKBOX_PRESSED)
	elseif checkbox.checked then
		gui.play_flipbook(checkbox.node, CHECKBOX_CHECKED)
	else
		gui.play_flipbook(checkbox.node, CHECKBOX)
	end
end
function M.checkbox(node_id, action_id, action, fn)
	return gooey.checkbox(node_id .. "/box", action_id, action, fn, refresh_checkbox)
end


local function update_radiobutton(radio)
	if radio.pressed_now or radio.released_now then
		utils.shake(radio.node, vmath.vector3(1))
	end
	if radio.pressed then
		gui.play_flipbook(radio.node, RADIO_PRESSED)
	elseif radio.selected then
		gui.play_flipbook(radio.node, RADIO_SELECTED)
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
		gui.play_flipbook(gui.get_node(node_id .. "/bg"), INPUT_FOCUS)
	elseif input.deselected_now then
		gui.play_flipbook(gui.get_node(node_id .. "/bg"), INPUT)
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
		gui.play_flipbook(item.root, LISTITEM_SELECTED)
	elseif item.index == list.pressed_item then
		pos.x = 1
		gui.play_flipbook(item.root, LISTITEM_PRESSED)
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
function M.static_list(list_id, scrollbar_id, item_ids, action_id, action, config, fn)
	local list = gooey.static_list(list_id, list_id .. "/stencil", item_ids, action_id, action, config, fn, update_static_list)
	if scrollbar_id then
		-- scrolled in list -> update scrollbar
		if list.scrolling then
			gooey.vertical_scrollbar(scrollbar_id .. "/handle", scrollbar_id .. "/bounds").scroll_to(0, list.scroll.y)
		else
			-- scroll using scrollbar -> scroll list
			gooey.vertical_scrollbar(scrollbar_id .. "/handle", scrollbar_id .. "/bounds", action_id, action, function(scrollbar)
				gooey.static_list(list_id, list_id .. "/stencil", item_ids).scroll_to(0, scrollbar.scroll.y)
			end)
		end
	end

	return list
end


local function update_dynamic_list(list)
	for _,item in ipairs(list.items) do
		update_listitem(list, item)
		gui.set_text(item.nodes[hash(list.id .. "/listitem_text")], tostring(item.data or "-"))
	end
end
function M.dynamic_list(list_id, scrollbar_id, data, action_id, action, config, fn)
	local list = gooey.dynamic_list(list_id, list_id .. "/stencil", list_id .. "/listitem_bg", data, action_id, action, config, fn, update_dynamic_list)
	if scrollbar_id then
		-- scrolled in list -> update scrollbar
		if list.scrolling then
			gooey.vertical_scrollbar(scrollbar_id .. "/handle", scrollbar_id .. "/bounds").scroll_to(0, list.scroll.y)
		else
			-- scroll using scrollbar -> scroll list
			gooey.vertical_scrollbar(scrollbar_id .. "/handle", scrollbar_id .. "/bounds", action_id, action, function(scrollbar)
				gooey.dynamic_list(list_id, list_id .. "/stencil", list_id .. "/listitem_bg", data).scroll_to(0, scrollbar.scroll.y)
			end)
		end
	end

	return list
end

function M.scrollbar(scrollbar_id, action_id, action, fn)
	return gooey.vertical_scrollbar(scrollbar_id .. "/handle", scrollbar_id .. "/bounds")
end

return M
