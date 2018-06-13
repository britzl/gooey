local mock_gui = require "deftest.mock.gui"
local mock = require "deftest.mock.mock"

local gooey = require "gooey.gooey"
local actions = require "test.actions"


local function callback_listener()
	local listener = {}
	function listener.callback() end
	mock.mock(listener)
	return listener.callback
end

return function()
	describe("radio", function()
		before(function()
			mock_gui.mock()
		end)

		after(function()
			mock_gui.unmock()
		end)
		
		test("it should be clickable", function()
			mock_gui.add_box("radio1", 10, 10, 100, 40)
			mock_gui.add_box("radio2", 10, 60, 100, 40)
			mock_gui.add_box("radio3", 10, 110, 100, 40)
			
			local radio1 = gui.get_node("radio1")
			local radio2 = gui.get_node("radio2")
			local radio3 = gui.get_node("radio3")
			local click1 = callback_listener()
			local click2 = callback_listener()
			local click3 = callback_listener()
			local refresh1 = callback_listener()
			local refresh2 = callback_listener()
			local refresh3 = callback_listener()
			local group1 = "group1"

			
			--
			-- select second radio button
			--
			for _,action in ipairs({ actions.pressed(10, 60), actions.released(10, 60) }) do
				gooey.radiogroup(group1, gooey.TOUCH, action, function()
					gooey.radio("radio1", group1, gooey.TOUCH, action, click1, refresh1)
					gooey.radio("radio2", group1, gooey.TOUCH, action, click2, refresh2)
					gooey.radio("radio3", group1, gooey.TOUCH, action, click3, refresh3)
				end)
			end
			assert(click1.calls == 0)
			assert(click3.calls == 0)
			assert(click2.calls == 1)
			assert(click2.params[1].node == radio2)

			assert(refresh1.calls == 3) -- press, release, deselect
			assert(refresh3.calls == 3) -- press, release, deselect
			assert(refresh2.calls == 2) -- press, release
			
			-- check that second radio button is selected
			assert(not refresh1.params[1].selected)
			assert(not refresh3.params[1].selected)
			assert(refresh2.params[1].selected)
			assert(refresh2.params[1].selected_now)

			
			--
			-- select first radio button
			--
			for _,action in ipairs({ actions.pressed(10, 10), actions.released(10, 10) }) do
				gooey.radiogroup(group1, gooey.TOUCH, action, function()
					gooey.radio("radio1", group1, gooey.TOUCH, action, click1, refresh1)
					gooey.radio("radio2", group1, gooey.TOUCH, action, click2, refresh2)
					gooey.radio("radio3", group1, gooey.TOUCH, action, click3, refresh3)
				end)
			end
			assert(click1.calls == 1)
			assert(click3.calls == 0)
			assert(click2.calls == 1)
			assert(click1.params[1].node == radio1)

			assert(refresh2.calls == 2 + 3) -- press, release, deselect
			assert(refresh3.calls == 3 + 3) -- press, release, deselect
			assert(refresh1.calls == 3 + 2) -- press, release
						
			-- check that first radio button is selected and the second deselected
			assert(refresh1.params[1].selected)
			assert(not refresh2.params[1].selected)
			assert(not refresh3.params[1].selected)

			-- check that the first radio button was selected now and the second deselected now
			assert(refresh1.params[1].selected_now)
			assert(refresh2.params[1].deselected_now)


			--
			-- select first radio button again
			--
			for _,action in ipairs({ actions.pressed(10, 10), actions.released(10, 10) }) do
				gooey.radiogroup(group1, gooey.TOUCH, action, function()
					gooey.radio("radio1", group1, gooey.TOUCH, action, click1, refresh1)
					gooey.radio("radio2", group1, gooey.TOUCH, action, click2, refresh2)
					gooey.radio("radio3", group1, gooey.TOUCH, action, click3, refresh3)
				end)
			end
			-- check there is no change in the "now" state
			assert(not refresh1.params[1].selected_now)
			assert(not refresh2.params[1].deselected_now)
						
			assert(refresh2.calls == (2 + 3) + 2) -- press, release
			assert(refresh3.calls == (3 + 3) + 2) -- press, release
			assert(refresh1.calls == (3 + 2) + 2) -- press, release
			
			
			--
			-- generate a touch outside
			--
			local action = actions.move(0, 0)
			gooey.radiogroup(group1, gooey.TOUCH, action, function()
				gooey.radio("radio1", group1, gooey.TOUCH, action, click1, refresh1)
				gooey.radio("radio2", group1, gooey.TOUCH, action, click2, refresh2)
				gooey.radio("radio3", group1, gooey.TOUCH, action, click3, refresh3)
			end)

			-- move
			assert(refresh2.calls == (2 + 3 + 2) + 1)
			assert(refresh3.calls == (3 + 3 + 2) + 1)
			assert(refresh1.calls == (3 + 2 + 2) + 1)

			-- check that "now" state is cleared
			assert(not refresh1.params[1].selected_now)
			assert(not refresh2.params[1].deselected_now)
		end)
	end)
end