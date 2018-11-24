Color = require "lib.Palette"
Fonts = {
	["Main"] = love.graphics.newFont("assets/fonts/liebefinden.ttf", 32),
	["Status"] = love.graphics.newFont("assets/fonts/bebasneue.ttf", 40)
}
SceneManager = require "lib.SceneManager"
Canvas = love.graphics.newCanvas(910, 800)
Fullscreen = false
function love.load()
	min_dt = 1/60
	next_time = love.timer.getTime()
	Canvas:setFilter("nearest", "nearest")
	love.window.setTitle("Touhou Yahtzee")
	love.window.setMode(910, 800, { resizable = true })
	love.graphics.setFont(Fonts.Main)
	SceneManager:add({
		["STitle"] = require "scenes.Title"(),
		["SGame"]  = require "scenes.Game"()
	})
	SceneManager:switch("STitle")
end
scale = 0

function love.update(dt)
	next_time = next_time + min_dt
	SceneManager:update(dt)
end

function love.draw()
	love.graphics.setCanvas(Canvas)
	SceneManager:draw()
	love.graphics.setCanvas()
	local screenW,screenH = love.graphics.getDimensions()
	local canvasW,canvasH = Canvas:getDimensions()
	scaleX = love.graphics.getWidth() / Canvas:getWidth()
	scaleY = love.graphics.getHeight() / Canvas:getHeight()
	love.graphics.draw(Canvas, 0, 0, 0, scaleX, scaleY)

	local cur_time = love.timer.getTime()
	if next_time <= cur_time then
		next_time = cur_time
		return
	end
	love.timer.sleep(next_time - cur_time)
end
