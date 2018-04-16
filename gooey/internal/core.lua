local M = {}

M.TOUCH = hash("touch")

--- Basic input handling for anything that is clickable
-- @param component Component state table
-- @param action_id
-- @param action
function M.clickable(component, action_id, action)
	if not component.enabled then
		component.pressed_now = false
		component.released_now = false
		return		
	end

	local over = gui.pick_node(component.node, action.x, action.y)
	component.over_now = over and not component.over
	component.out_now = not over and component.over
	component.over = over

	local touch = action_id == M.TOUCH
	local pressed = touch and action.pressed and component.over
	local released = touch and action.released

	component.pressed_now = pressed and not component.pressed
	component.released_now = released and component.pressed
	component.pressed = pressed or (component.pressed and not released)
	component.consumed = component.pressed or (component.released_now and component.over)
	component.clicked = component.released_now and component.over
end

--- Check if a node is enabled. This is done by not only
-- looking at the state of the node itself but also it's
-- ancestors all the way up the hierarchy
-- @param node
-- @return true if node and all ancestors are enabled
function M.is_enabled(node)
	local parent = gui.get_parent(node)
	if parent then
		return M.is_enabled(parent)
	end
	return gui.is_enabled(node)
end

-- Convert string to hash, unless it's already a hash
-- @param str String to convert
-- @return The hashed string
function M.to_hash(str)
	return type(str) == "string" and hash(str) or str
end

--- Create a unique key for an hash by combining the id with the current url
-- @param hsh Hash to create key for
-- @return Unique key based on the hash and the current url 
function M.to_key(hsh)
	local url = msg.url()
	return hash_to_hex(url.socket or EMPTY)
	.. hash_to_hex(url.path or empty)
	.. hash_to_hex(url.fragment or empty)
	.. hash_to_hex(hsh)
end

--- Get an instance (table) for an id or create one if it doesn't
-- exist
-- @param id (hash|string)
-- @param instances
-- @return instance Instance data for the node (public data)
-- @return state Internal state of the node (private data)
function M.instance(id, instances, functions)
	local key = M.to_key(id)
	local instance = instances[key]
	-- detect a reload (unload and load cycle) and start with an
	-- empty instance
	-- if the script instance has changed then we're certain that
	-- it's reloaded
	local script_instance = _G.__dm_script_instance__
	if instance and instance.__script ~= script_instance then
		instances[key] = nil
	end
	instances[key] = instances[key] or { __script = script_instance }
	if not instances[key].data then
		local data = {}
		instances[key].data = data
		for name,fn in pairs(functions or {}) do
			data[name] = function(...)
				fn(data, ...)
			end
		end
	end
	if not instances[key].state then
		instances[key].state = {}
	end
	return instances[key].data, instances[key].state
end	

return M