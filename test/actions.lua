local M = {}


function M.move(x, y)
	return {
		pressed = false, released = false, repeated = false,
		x = x, y = y, screen_x = x, screen_y = y,
	}
end

function M.text(text)
	return {
		text = text,
		pressed = true, released = false, repeated = false,
		x = 0, y = 0, screen_x = 0, screen_y = 0,
	}
end

function M.pressed(x, y)
	return {
		pressed = true, released = false, repeated = false,
		x = x, y = y, screen_x = x, screen_y = y,
	}
end

function M.released(x, y)
	return {
		pressed = false, released = true, repeated = false,
		x = x, y = y, screen_x = x, screen_y = y,
	}
end


return M