local mock_gui = require "deftest.mock.gui"
local mock = require "deftest.mock.mock"

local gooey = require "gooey.gooey"
local actions = require "test.actions"
local action_ids = require "gooey.actions"

local function callback_listener()
	local listener = {}
	function listener.callback() end
	mock.mock(listener)
	return listener.callback
end

return function()
	describe("static list", function()
		before(function()
			mock_gui.mock()
		end)

		after(function()
			mock_gui.unmock()
		end)

		test("it should handle clicks on list items", function()
			local stencil = gui.new_box_node(vmath.vector3(50, 50, 0), vmath.vector3(100, 100, 0))
			local item1 = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(100, 20, 0))
			local item2 = gui.new_box_node(vmath.vector3(0, 20, 0), vmath.vector3(100, 20, 0))
			local item3 = gui.new_box_node(vmath.vector3(0, 40, 0), vmath.vector3(100, 20, 0))
			local item4 = gui.new_box_node(vmath.vector3(0, 60, 0), vmath.vector3(100, 20, 0))
			gui.set_parent(item1, stencil)
			gui.set_parent(item2, stencil)
			gui.set_parent(item3, stencil)
			gui.set_parent(item4, stencil)
			
			local stencil_id = gui.get_id(stencil)
			local item1_id = gui.get_id(item1)
			local item2_id = gui.get_id(item2)
			local item3_id = gui.get_id(item3)
			local item4_id = gui.get_id(item4)
			local item_ids = { item1_id, item2_id, item3_id, item4_id }

			local click_fn = callback_listener()
			
			gooey.static_list(list_id, stencil_id, item_ids, action_ids.TOUCH, actions.pressed(50, 50), nil, click_fn)
			gooey.static_list(list_id, stencil_id, item_ids, action_ids.TOUCH, actions.released(50, 50), nil, click_fn)

			assert(click_fn.calls == 1)
		end)
		
	end)
end