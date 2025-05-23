local actions = require "gooey.actions"

local M = {}

local EMPTY = hash("")

local long_press_start = 0

local function handle_action(component, action_id, action)
	action.id = action.id or -1
	component.long_pressed_time = component.long_pressed_time or 1.5
	if not component.touch_id or component.touch_id == action.id then
		local over = false
		if action.x or action.y then
			over = gui.pick_node(component.node, action.x, action.y)
		end
		if component.focus and action_id == actions.SELECT then
			over = true
		end
		component.over_now = over and not component.over
		component.out_now = not over and component.over
		component.over = over

		local touch = action_id == actions.TOUCH or action_id == actions.MULTITOUCH or action_id == actions.SELECT
		local pressed = touch and action.pressed and component.over
		local released = touch and action.released
		if pressed then
			component.touch_id = action.id
			long_press_start = socket.gettime()
		elseif released then
			component.touch_id = nil
			component.long_pressed = socket.gettime() - long_press_start > component.long_pressed_time
		end

		component.pressed_now = pressed and not component.pressed
		component.released_now = released and component.pressed
		component.pressed = pressed or (component.pressed and not released)
		component.consumed = component.pressed or (component.released_now and component.over)
		component.clicked = component.released_now and component.over
		component.long_pressed = component.long_pressed or false
	end
end

function M.get_root_position(node)
	local get_pos
	get_pos = function(node)
		local parent = gui.get_parent(node)
		local pos = gui.get_position(node)
		if parent then
			return pos + get_pos(parent)
		else
			return pos
		end
	end
	return get_pos(node)
end

--- Basic input handling for anything that is clickable
-- @param component Component state table
-- @param action_id
-- @param action
function M.clickable(component, action_id, action)
	if not component.enabled or not action then
		component.pressed_now = false
		component.released_now = false
		component.consumed = false
		component.clicked = false
		component.pressed = false
		return
	end

	if not action.touch then
		handle_action(component, action_id, action)
	else
		for _,touch_action in pairs(action.touch) do
			handle_action(component, action_id, touch_action)
		end
	end
end

--- Check if a node is enabled. This is done by not only
-- looking at the state of the node itself but also it's
-- ancestors all the way up the hierarchy
-- @param node
-- @return true if node and all ancestors are enabled
function M.is_enabled(node)
	local parent = gui.get_parent(node)
	local enabled = gui.is_enabled(node)
	if parent then
		return enabled and M.is_enabled(parent)
	end
	return enabled
end

-- Convert string to hash, unless it's already a hash
-- @param str String to convert
-- @return The hashed string
function M.to_hash(str)
	return type(str) == "string" and hash(str) or str
end

--- Create a unique key for a hash by combining the id with the current url
-- @param hsh Hash to create key for
-- @return Unique key based on the hash and the current url 
function M.to_key(hsh)
	local url = msg.url()
	return hash_to_hex(url.socket or EMPTY)
	.. hash_to_hex(url.path or EMPTY)
	.. hash_to_hex(url.fragment or EMPTY)
	.. hash_to_hex(hsh)
end

--- Get an instance (table) for an id or create one if it doesn't
-- exist
-- @param id (hash|string)
-- @param instances
-- @return instance Instance data for the node (public data)
-- @return state Internal state of the node (private data)
function M.instance(id, instances, functions)
	id = M.to_hash(id)
	local key = M.to_key(id)
	local instance = instances[key]
	-- detect a reload (unload and load cycle) and start with an
	-- empty instance
	-- if the script instance has changed then we're certain that
	-- it's reloaded
	-- NOTE: In Defold 1.2.151 __dm_script_instance__ has been
	-- replaced by a numeric key
	-- 3700146495 (Android, macOS etc)
	-- -594820801 (HTML5)
	local script_instance = _G[3700146495] or _G[-594820801]
	if instance and instance.__script ~= script_instance then
		instances[key] = nil
	end
	instances[key] = instances[key] or { __script = script_instance }
	if not instances[key].data then
		local data = {}
		data.id = id
		instances[key].data = data
		for name,fn in pairs(functions or {}) do
			data[name] = function(...)
				fn(data, ...)
				return instances[key].data, instances[key].state
			end
		end
	end
	if not instances[key].state then
		instances[key].state = {}
	end
	return instances[key].data, instances[key].state
end

function M.state(id, instances)
	local key = M.to_key(id)
	if not instances[key].state then
		instances[key].state = {}
	end
	return instances[key].state
end

function M.clamp(v, min, max)
	if v < min then
		return min
	elseif v > max then
		return max
	else
		return v
	end
end

local DISPLAY_WIDTH = tonumber(sys.get_config("display.width")) or 960
local DISPLAY_HEIGHT = tonumber(sys.get_config("display.height")) or 640
local WINDOW_WIDTH = nil
local WINDOW_HEIGHT = nil

local GUI_ADJUST = {
	[gui.ADJUST_FIT] = {sx=1, sy=1, ox=0, oy=0}, -- Fit
	[gui.ADJUST_ZOOM] = {sx=1, sy=1, ox=0, oy=0}, -- Zoom
	[gui.ADJUST_STRETCH] = {sx=1, sy=1, ox=0, oy=0}, -- Stretch
}

function M.adjust(adjust_mode, x, y)
	local ww, wh = window.get_size()
	if ww ~= WINDOW_WIDTH or wh ~= WINDOW_HEIGHT then
		WINDOW_WIDTH = ww
		WINDOW_HEIGHT = wh

		local sx = WINDOW_WIDTH / DISPLAY_WIDTH
		local sy = WINDOW_HEIGHT / DISPLAY_HEIGHT

		-- Fit
		local adjust = GUI_ADJUST[gui.ADJUST_FIT]
		local scale = math.min(sx, sy)
		adjust.sx = scale * 1 / sx
		adjust.sy = scale * 1 / sy
		adjust.ox = (WINDOW_WIDTH - DISPLAY_WIDTH * scale) * 0.5 / scale
		adjust.oy = (WINDOW_HEIGHT - DISPLAY_HEIGHT * scale) * 0.5 / scale

		-- Zoom
		adjust = GUI_ADJUST[gui.ADJUST_ZOOM]
		scale = math.max(sx, sy)
		adjust.sx = scale * 1 / sx
		adjust.sy = scale * 1 / sy
		adjust.ox = (WINDOW_WIDTH - DISPLAY_WIDTH * scale) * 0.5 / scale
		adjust.oy = (WINDOW_HEIGHT - DISPLAY_HEIGHT * scale) * 0.5 / scale

		-- Stretch
		adjust = GUI_ADJUST[gui.ADJUST_STRETCH]
		adjust.sx = 1
		adjust.sy = 1
		-- distorts to fit window, offsets always zero
	end

	x = (x / GUI_ADJUST[adjust_mode].sx) - GUI_ADJUST[adjust_mode].ox
	y = (y / GUI_ADJUST[adjust_mode].sy) - GUI_ADJUST[adjust_mode].oy
	return x, y
end

return M