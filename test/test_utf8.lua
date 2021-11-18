local utf8 = require "gooey.internal.utf8"



return function()
	describe("utf8", function()
		test("length", function()
			assert(utf8.len("") == 0)
			assert(utf8.len("abc") == 3)
			assert(utf8.len("åäö") == 3)
			assert(utf8.len("foo åäö bar") == 11)
			assert(utf8.len("\xf0\x9f\x98\x84") == 1)	-- emoji smiley
		end)

		test("sub", function()
			assert(utf8.sub("abc", 1) == "abc")
			assert(utf8.sub("abc", 2) == "bc")
			assert(utf8.sub("abc", 3) == "c")
			assert(utf8.sub("abc", 1, 1) == "a")
			assert(utf8.sub("abc", 2, 2) == "b")
			assert(utf8.sub("abc", 3, 3) == "c")
			assert(utf8.sub("abc", 1, 2) == "ab")
			assert(utf8.sub("abc", 2, 3) == "bc")
			assert(utf8.sub("åäö", 1) == "åäö")
			assert(utf8.sub("åäö", 2) == "äö")
			assert(utf8.sub("åäö", 3) == "ö")
			assert(utf8.sub("åäö", 1, 1) == "å")
			assert(utf8.sub("åäö", 2, 2) == "ä")
			assert(utf8.sub("åäö", 3, 3) == "ö")
			assert(utf8.sub("a\xf0\x9f\x98\x84b", 1, 1) == "a")
			assert(utf8.sub("a\xf0\x9f\x98\x84b", 2, 2) == "\xf0\x9f\x98\x84")
			assert(utf8.sub("a\xf0\x9f\x98\x84b", 1, -2) == "a\xf0\x9f\x98\x84")
			assert(utf8.sub("a\xf0\x9f\x98\x84", 1, -2) == "a")
		end)
	end)
end