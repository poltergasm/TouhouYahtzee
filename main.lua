Color = require "lib.Palette"
Fonts = {
	["Main"] = love.graphics.newFont("assets/fonts/liebefinden.ttf", 32),
	["Status"] = love.graphics.newFont("assets/fonts/anjellicsans.ttf", 42)
}

local SceneManager = require "lib.SceneManager"

function love.load()
	min_dt = 1/60
	next_time = love.timer.getTime()
	love.window.setMode(910, 800)
	love.graphics.setFont(Fonts.Main)
	SceneManager:add({
		["STitle"] = require "scenes.Title"(),
		["SGame"]  = require "scenes.Game"()
	})
	SceneManager:switch("SGame")
end

function love.update(dt)
	next_time = next_time + min_dt
	SceneManager:update(dt)
end

function love.draw()
	SceneManager:draw()

	local cur_time = love.timer.getTime()
	if next_time <= cur_time then
		next_time = cur_time
		return
	end
	love.timer.sleep(next_time - cur_time)
end
