local Baton = require "lib.Baton"
local Snow = require "lib.Snow"
local Scene = require "lib.Scene"
local Title = Scene:extends()

local title_image = love.graphics.newImage("assets/gfx/title.jpg")
local title_music = love.audio.newSource("assets/audio/bgm/snow_or_cherry_petal.mp3", "stream")

function Title:new()
	Title.super.new(self)
	self.show_rules = false

	self.input = Baton.new {
		["controls"] = {
			["click"] = {'mouse:1'},
			["play"] = {'key:p'},
			["esc"] = {'key:escape'}
		}
	}
end

function Title:on_enter()
	Snow:load(love.graphics.getWidth(), love.graphics.getHeight(), 25)
	title_music:play()
end

function Title:check_click(mx, my)
	if mx >= 320*scaleX and mx <= 553*scaleX and my >= 220*scaleY and my <= 275*scaleY then
		title_music:stop()
		SceneManager:switch("SGame")
	elseif mx >= 320*scaleX and mx <= 553*scaleX and my >= 310*scaleY and my <= 360*scaleY then
		self.show_rules = true
	end
end

function Title:update(dt)
	Title.super.update(self, dt)
	Snow:update(dt)
	self.input:update()

	if self.input:pressed "click" then
		local mx,my = love.mouse.getPosition()
		self:check_click(mx, my)
	end
end

function Title.print_rules()
	local y = 30
	for line in love.filesystem.lines("rules.txt") do
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.print(line, 42, y+2)
		love.graphics.setColor(1, 1, 1 ,1)
		love.graphics.print(line, 40, y)
		y = y + 30
	end
end

function Title:draw()
	Title.super.draw(self)
	love.graphics.clear(Color.Purple)
	local sx, sy = love.graphics.getWidth() / title_image:getWidth(),
		love.graphics.getHeight() / title_image:getHeight()
	love.graphics.draw(title_image, 0, 0, 0, math.max(sx,sy))
	Snow:draw()
	if self.show_rules then
		if self.input:pressed "esc" then
			self.show_rules = false
		end
		love.graphics.setColor(0, 0, 0, 0.8)
		love.graphics.setFont(Fonts.Text)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
		love.graphics.setColor(1, 1, 1, 1)
		self.print_rules()
		love.graphics.setFont(Fonts.Main)
	else
		love.graphics.setColor(0, 0, 0, 0.7)
		love.graphics.rectangle("fill", 320, 220, 230, 55, 10, 10)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.print("Click to play", 347, 227)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print("Click to play", 345, 225)

		love.graphics.setColor(0, 0, 0, 0.7)
		love.graphics.rectangle("fill", 320, 310, 230, 55, 10, 10)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.print("How to play", 347, 317)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print("How to play", 345, 315)
	end
end

return Title