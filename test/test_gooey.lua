local mock_gui = require "deftest.mock.gui"
local gooey = require "gooey.gooey"

return function()
	describe("gooey", function()
		before(function()
			mock_gui.mock()
		end)

		after(function()
			mock_gui.unmock()
		end)

		test("it should be able to test if a component is enabled", function()
			mock_gui.add_box("box1", 10, 10)
			mock_gui.add_box("box2", 20, 20)

			local box1 = gui.get_node("box1")
			local box2 = gui.get_node("box2")
			gui.set_enabled(box2, false)
			assert(gooey.is_enabled(box1))
			assert(not gooey.is_enabled(box2))
		end)
	end)
end