local M = {}

--- Fix a filename to ensure that it doesn't contain any illegal characters
-- @param filename
-- @return Filename with illegal characters replaced
local function fix(filename)
	filename = filename:gsub("([^0-9a-zA-Z%._ ])", function(c) return string.format("%%%02X", string.byte(c)) end)
	filename = filename:gsub(" ", "+")
	return filename
end

--- Get an application specific save file path to a filename. The path will be
-- based on the sys.get_save_file() function and the project title (with whitespace)
-- replaced by underscore
-- @param filename
-- @return Save file path
local function get_save_file_path(filename)
	local path = sys.get_save_file(fix(sys.get_config("project.title"):gsub(" ", "_")), filename)
	return path
end

local function load_image(url, cb)
	local filename = url
	local path = get_save_file_path(filename)
	http.request(url, "GET", function(self, id, response)
		local image_data = response.response
		if response.status == 200 then
			local f = io.open(path, "wb")
			if f then
				f:write(image_data)
				f:flush()
				f:close()
			end
		elseif response.status == 304 then
			if not image_data then
				local f = io.open(path, "rb")
				image_data = f:read("*a")
				f:close()
			end
		else
			image_data = nil
		end
		if image_data then
			image_data = image.load(image_data)
		end
		cb(image_data)
	end)
end

function M.create()
	return {
		node_to_url = {},
		url_to_image = {},
	}
end


function M.clear(cache)
	for url,_ in pairs(cache.url_to_image) do
		gui.delete_texture(url)
	end
	url_to_image = {}
	node_to_url = {}
end


function M.load(cache, url, node, cb)
	assert(url, "You must provide a url")
	assert(node, "You must provide a node")
	
	-- is the node using another texture?
	-- remove texture refence and unload if it is no longer in use
	local url_on_node = cache.node_to_url[node]
	if url_on_node and url_on_node ~= url then
		local img = cache.url_to_image[url_on_node]
		cache.node_to_url[node] = nil
		img.nodes[node] = nil
		if not next(img.nodes) and img.loaded then
			gui.delete_texture(url_on_node)
			cache.url_to_image[url_on_node] = nil
		end
	end

	-- has the url already been loaded
	local img = cache.url_to_image[url]
	if not img then
		img = {
			url = url,
			nodes = {},
			loading = false,
			loaded = false,
		}
		cache.url_to_image[url] = img
	end
	-- associate the node with the image
	cache.node_to_url[node] = url
	img.nodes[node] = true

	if not img.loading then
		if not img.loaded then
			img.loading = true
			load_image(url, function(image_data)
				img.loaded = true
				img.loading = false
				if not image_data then
					print("Unable to load image")
				else
					gui.new_texture(url, image_data.width, image_data.height, image_data.type, image_data.buffer, false)
					for n,_ in pairs(img.nodes) do
						gui.set_texture(n, url)
					end
				end
				if cb then cb() end
			end)
		else
			for n,_ in pairs(img.nodes) do
				gui.set_texture(n, url)
			end
			if cb then cb() end
		end
	end
end


return M