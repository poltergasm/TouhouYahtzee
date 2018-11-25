local Button = require "lib.Button"
local Scene = require "lib.Scene"
local Poker = Scene:extends()

function Poker:new()
	Poker.super.new(self)
end

function Poker:on_enter()
	local testbtn = Button(300, 300, "Test Button")
	self.entity_mgr:add(testbtn)
end

function Poker:update(dt)
	Poker.super.update(self, dt)
end

function Poker:draw()
	love.graphics.clear(Color.LightBlue)
	Poker.super.draw(self)

end

return Poker