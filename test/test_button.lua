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
	describe("button", function()
		before(function()
			mock_gui.mock()
		end)

		after(function()
			mock_gui.unmock()
		end)

		test("it should be clickable", function()
			mock_gui.add_box("button", 10, 10, 100, 40)

			local button = gui.get_node("button")
			local click = callback_listener()
			gooey.button("button", action_ids.TOUCH, actions.pressed(10, 10), click)
			gooey.button("button", action_ids.TOUCH, actions.released(10, 10), click)
			assert(click.calls == 1)
			assert(click.params[1].node == button)
		end)

		test("it should not be clickable if disabled", function()
			mock_gui.add_box("button", 10, 10, 100, 40)

			local button = gui.get_node("button")
			gui.set_enabled(button, false)
			local click = callback_listener()
			gooey.button("button", action_ids.TOUCH, actions.pressed(10, 10), click)
			gooey.button("button", action_ids.TOUCH, actions.released(10, 10), click)
			assert(click.calls == 0)
		end)
		
		test("it should not treat a press inside and release outside as a click", function()
			mock_gui.add_box("button", 10, 10, 100, 40)

			local click = callback_listener()
			gooey.button("button", action_ids.TOUCH, actions.pressed(10, 10), click)
			gooey.button("button", action_ids.TOUCH, actions.released(0, 0), click)
			assert(click.calls == 0)
		end)

		test("it should not treat a press outside and release inside as a click", function()
			mock_gui.add_box("button", 10, 10, 100, 40)

			local click = callback_listener()
			gooey.button("button", action_ids.TOUCH, actions.pressed(0, 0), click)
			gooey.button("button", action_ids.TOUCH, actions.released(10, 10), click)
			assert(click.calls == 0)
		end)

		test("it should notify state changes", function()
			mock_gui.add_box("button", 10, 10, 100, 40)

			local button = gui.get_node("button")
			local click = callback_listener()
			local refresh = callback_listener()
			-- move outside
			gooey.button("button", action_ids.TOUCH, actions.move(0, 0), click, refresh)
			
			-- move over
			gooey.button("button", action_ids.TOUCH, actions.move(10, 10), click, refresh)
			assert(refresh.params[1].over)
			assert(refresh.params[1].over_now)

			-- move inside
			gooey.button("button", action_ids.TOUCH, actions.move(10, 10), click, refresh)
			assert(refresh.params[1].over)
			assert(not refresh.params[1].over_now)
			
			-- move out
			gooey.button("button", action_ids.TOUCH, actions.move(0, 0), click, refresh)
			assert(not refresh.params[1].over)
			assert(refresh.params[1].out_now)

			-- move
			gooey.button("button", action_ids.TOUCH, actions.move(0, 0), click, refresh)
			assert(not refresh.params[1].out_now)
			
			-- pressed
			gooey.button("button", action_ids.TOUCH, actions.pressed(10, 10), click)
			assert(refresh.params[1].pressed)
			assert(refresh.params[1].pressed_now)

			-- move inside while pressed
			gooey.button("button", action_ids.TOUCH, actions.move(10, 10), click, refresh)
			assert(refresh.params[1].pressed)
			assert(not refresh.params[1].pressed_now)

			-- released
			gooey.button("button", action_ids.TOUCH, actions.released(10, 10), click, refresh)
			assert(not refresh.params[1].pressed)
			assert(refresh.params[1].released_now)

			-- move
			gooey.button("button", action_ids.TOUCH, actions.move(10, 10), click, refresh)
			assert(not refresh.params[1].released_now)
		end)
		
	end)
end