local mock_gui = require "deftest.mock.gui"
local mock = require "deftest.mock.mock"
local unload = require "deftest.util.unload"

local gooey = require "gooey.gooey"
local actions = require "test.actions"


local function callback_listener()
	local listener = {}
	function listener.callback() end
	mock.mock(listener)
	return listener.callback
end

return function()
	describe("input", function()
		before(function()
			unload("^gooey.*")
			gooey = require "gooey.gooey"
			mock_gui.mock()
		end)

		after(function()
			mock_gui.unmock()
		end)

		test("it should be possible to type text", function()
			mock_gui.add_text("text", 10, 10, 100, 40)

			local config = nil
			gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.TOUCH, actions.pressed(10, 10))
			gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.TOUCH, actions.released(10, 10))
			gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.TEXT, actions.text("f"))
			gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.TEXT, actions.text("o"))
			gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.TEXT, actions.text("o"))
			gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.TEXT, actions.text("b"))
			gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.TEXT, actions.text("a"))
			local input = gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.TEXT, actions.text("r"))
			assert(input.text == "foobar")
		end)

		test("it should be possible to delete typed text", function()
			mock_gui.add_text("text", 10, 10, 100, 40)

			local config = nil
			gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.TOUCH, actions.pressed(10, 10))
			gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.TOUCH, actions.released(10, 10))
			gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.TEXT, actions.text("foobar"))
			assert(gooey.input("text").text == "foobar")

			local input = gooey.input("text", gui.KEYBOARD_TYPE_DEFAULT, gooey.BACKSPACE, actions.text(""))
			assert(input.text == "fooba")
		end)
		
	end)
end