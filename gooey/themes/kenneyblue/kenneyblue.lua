local gooey = require "gooey.gooey"


local M = {}


local function shake(node, initial_scale)
	gui.cancel_animation(node, "scale.x")
	gui.cancel_animation(node, "scale.y")
	gui.set_scale(node, initial_scale)
	local scale = gui.get_scale(node)
	gui.set_scale(node, scale * 1.2)
	gui.animate(node, "scale.x", scale.x, gui.EASING_OUTELASTIC, 0.8)
	gui.animate(node, "scale.y", scale.y, gui.EASING_OUTELASTIC, 0.8, 0.05, function()
		gui.set_scale(node, initial_scale)
	end)
end


function M.acquire_input()
	gooey.acquire_input()
end


local function refresh_button(button)
	if button.pressed_now or button.released_now then
		shake(button.node, vmath.vector3(1))
	end
	if button.pressed then
		gui.play_flipbook(button.node, hash("blue_button05"))
	else
		gui.play_flipbook(button.node, hash("blue_button04"))
	end
end
function M.button(node_id, action_id, action, fn)
	return gooey.button(node_id .. "/bg", action_id, action, fn, refresh_button)
end


local function refresh_checkbox(checkbox)
	if checkbox.pressed_now or checkbox.released_now then
		shake(checkbox.node, vmath.vector3(1))
	end
	if checkbox.pressed then
		gui.play_flipbook(checkbox.node, hash("grey_boxCross"))
	elseif checkbox.checked then
		gui.play_flipbook(checkbox.node, hash("blue_boxCross"))
	else
		gui.play_flipbook(checkbox.node, hash("grey_box"))
	end
end
function M.checkbox(node_id, action_id, action, fn)
	return gooey.checkbox(node_id .. "/box", action_id, action, fn, refresh_checkbox)
end


local function update_radiobutton(radio)
	if radio.pressed_now or radio.released_now then
		shake(radio.node, vmath.vector3(1))
	end
	if radio.pressed then
		gui.play_flipbook(radio.node, hash("grey_boxTick"))
	elseif radio.selected then
		gui.play_flipbook(radio.node, hash("blue_boxTick"))
	else
		gui.play_flipbook(radio.node, hash("grey_circle"))
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
		gui.play_flipbook(gui.get_node(node_id .. "/bg"), hash("blue_button05"))
	elseif input.deselected_now then
		gui.play_flipbook(gui.get_node(node_id .. "/bg"), hash("blue_button03"))
	end

	if input.empty and not input.selected then
		gui.set_text(input.node, config and config.empty_text or "")
	end

	local cursor = gui.get_node(node_id .. "/cursor")
	if input.selected then
		gui.set_enabled(cursor, true)
		gui.set_position(cursor, vmath.vector3(4 + input.text_width, 0, 0))
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
	local pos = gui.get_position(item)
	if item.index== list.selected_item then
		pos.x = 4
		gui.play_flipbook(item, hash("blue_button03"))
	elseif item.index == list.pressed_item then
		pos.x = 1
		gui.play_flipbook(item, hash("blue_button03"))
	elseif item.index == list.over_item_now then
		pos.x = 1
		gui.play_flipbook(item, hash("blue_button04"))
	elseif item.index == list.out_item_now then
		pos.x = 0
		gui.play_flipbook(item, hash("blue_button04"))
	elseif item.index ~= list.over_item then
		pos.x = 0
		gui.play_flipbook(item, hash("blue_button04"))
	end
	gui.set_position(item, pos)
end


local function update_static_list(list)
	for _,item in ipairs(list.items) do
		update_listitem(list, item.root)
	end
end
function M.list(root_id, stencil_id, item_ids, action_id, action, fn)
	return gooey.static_list(root_id, stencil_id, item_ids, action_id, action, fn, update_static_list)
end


local function update_dynamic_list(list)
	for _,item in ipairs(list.items) do
		local item_text_node = item.nodes[hash(list.id .. "/listitem_text")]
		gui.set_text(item_text_node, item.data)
		update_listitem(list, item.root)
	end
end
function M.dynamic_list(list_id, data, action_id, action, fn)
	return gooey.dynamic_list(list_id, list_id .. "/stencil", list_id .. "/listitem_bg", data, action_id, action, fn, update_dynamic_list)
end


return M