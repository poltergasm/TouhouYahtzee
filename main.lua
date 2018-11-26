Jukebox = require("lib.Jukebox"):new(true)

Color = require "lib.Palette"
Fonts = {
	["Main"] = love.graphics.newFont("assets/fonts/liebefinden.ttf", 32),
	["Status"] = love.graphics.newFont("assets/fonts/bebasneue.ttf", 40),
	["Text"] = love.graphics.newFont("assets/fonts/liebefinden.ttf", 20),
	["Button"] = love.graphics.newFont("assets/fonts/bebasneue.ttf", 25)
}
SceneManager = require "lib.SceneManager"
Canvas = love.graphics.newCanvas(910, 800)
Fullscreen = false
snd = {
	["cardPlace1"] = love.audio.newSource("assets/audio/sfx/cardPlace1.wav", "static"),
	["cardPlace2"] = love.audio.newSource("assets/audio/sfx/cardPlace2.wav", "static"),
	["cardPlace3"] = love.audio.newSource("assets/audio/sfx/cardPlace3.wav", "static"),
	["cardPlace4"] = love.audio.newSource("assets/audio/sfx/cardPlace4.wav", "static"),
	["spellcard"] = love.audio.newSource("assets/audio/sfx/spellcard.mp3", "static"),
	["spellcard2"] = love.audio.newSource("assets/audio/sfx/spellcard2.wav", "static"),
	["discard"] = love.audio.newSource("assets/audio/sfx/discard.wav", "static"),
	["select"] = love.audio.newSource("assets/audio/sfx/select.wav", "static"),
	["nothing"] = love.audio.newSource("assets/audio/sfx/nothing.wav", "static"),
	["choose"] = love.audio.newSource("assets/audio/sfx/choose.wav", "static"),
	["win"] = love.audio.newSource("assets/audio/sfx/win.wav", "static")
}

function love.load()
	min_dt = 1/60
	next_time = love.timer.getTime()
	--love.window.setIcon(love.image.newImageData("assets/gfx/icon.png"))
	Canvas:setFilter("nearest", "nearest")
	love.window.setTitle("Touhou Yahtzee")
	love.window.setMode(910, 800, { resizable = true })
	love.graphics.setFont(Fonts.Main)

	Jukebox:add_song({ file = "assets/audio/bgm/lullaby_of_deserted_hell.mp3"})
	Jukebox:add_song({ file = "assets/audio/bgm/sky_of_scarlet_perception.mp3"})
	Jukebox:add_song({ file = "assets/audio/bgm/a_soul_as_red_as_a_ground_cherry.mp3"})
	Jukebox:add_song({ file = "assets/audio/bgm/desire_drive.mp3" })
	Jukebox:add_song({ file = "assets/audio/bgm/the_youkai_mountain.mp3" })
	Jukebox:volume(0.2)

	SceneManager:add({
		["STitle"] = require "scenes.Title"(),
		["SGame"]  = require "scenes.Game"(),
		["SPoker"] = require "scenes.Poker"()
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
