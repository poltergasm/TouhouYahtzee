local Class = require "lib.Class"
local Score = Class:extends()

function Score:new(x, y, n)
	self.x = x and x or 0
	self.y = y and y or 0
	self.name = n and n or "Unknown"
	self.h = 0
	self.w = 0
	self.used = false
	return self
end

return Score