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
			mock_gui.add_box("root", 10, 10)
			mock_gui.add_box("branch", 20, 20)
			mock_gui.add_box("leaf", 20, 20)
			
			local root = gui.get_node("root")
			local branch = gui.get_node("branch")
			local leaf = gui.get_node("leaf")
			gui.set_parent(branch, root)
			gui.set_parent(leaf, branch)
			gui.set_enabled(branch, false)

			assert(gooey.is_enabled(root))
			assert(not gooey.is_enabled(branch))
			assert(not gooey.is_enabled(leaf))
		end)
	end)
end