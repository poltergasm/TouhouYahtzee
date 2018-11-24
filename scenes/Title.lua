local Baton = require "lib.Baton"
local Scene = require "lib.Scene"
local Title = Scene:extends()

function Title:new()
	Title.super.new(self)

	self.input = Baton.new {
		["controls"] = {
			["click"] = {'mouse:1'}
		}
	}
end

function Title:update(dt)
	Title.super.update(self, dt)
	self.input:update()

	if self.input:pressed "click" then
		SceneManager:switch("SGame")
	end
end

function Title:draw()
	Title.super.draw(self)
	love.graphics.setBackgroundColor(Color.Purple)
	love.graphics.setColor(1, 1, 1, 255)
	love.graphics.print("Click to play", 40, 40)
end

return Title