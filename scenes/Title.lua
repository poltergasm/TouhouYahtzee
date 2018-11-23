local Scene = require "lib.Scene"
local Title = Scene:extends()

function Title:new()
	Title.super.new(self)
end

function Title:update(dt)
	Title.super.update(self, dt)
end

function Title:draw()
	Title.super.draw(self)
	love.graphics.setBackgroundColor(Color.Pink)
	love.graphics.setColor(1, 1, 1, 255)
	love.graphics.print("Click to play", 40, 40)
end

return Title