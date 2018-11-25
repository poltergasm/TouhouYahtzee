local Class = require "lib.Class"
local Button = Class:extends()

function Button:new(x, y, label)
	assert(label ~= nil, "Button arguments (x, y, label)")
	local fontW
	self.x = x
	self.y = y
	self.w = Fonts.Button:getWidth(label)+22
	self.h = Fonts.Button:getHeight(label)+10
	self.label = label
end

function Button:update(dt) end

function Button:draw()
	love.graphics.setColor(0, 0, 0, 0.6)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.setFont(Fonts.Button)
	love.graphics.print(self.label, self.x+12, self.y+7)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(self.label, self.x+10, self.y+5)
	love.graphics.setFont(Fonts.Main)
end

return Button