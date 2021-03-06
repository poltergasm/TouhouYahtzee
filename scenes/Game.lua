local Score = require "lib.Score"
local Baton = require "lib.Baton"
local Scene = require "lib.Scene"
local Tween = require "lib.Tween"
local Snow = require "lib.Snow"
local Game = Scene:extends()

local CARD_Y = love.graphics.getHeight() - 256
local CARD_Y_BOT = CARD_Y + 226
local STATUS_Y = CARD_Y - 60
local STATUS_X = 265
local status_width

local tweens = {}
local background = love.graphics.newImage("assets/gfx/bg1.jpg")
function Game:new()
	Game.super.new(self)

	self.scores = {
		["chance"] = Score(335, 200, "Spellcard"),
		["aces"] = Score(60, 425, "Aces"),
		["twos"] = Score(60, 350, "Twos"),
		["threes"] = Score(60, 275, "Threes"),
		["fours"] = Score(60, 200, "Fours"),
		["fives"] = Score(60, 125, "Fives"),
		["sixes"] = Score(60, 50, "Sixes"),
		["yahtzee"] = Score(600, 50, "Yata!"),
		["lstraight"] = Score(600, 125, "Large Straight"),
		["sstraight"] = Score(600, 200, "Small Straight"),
		["fullhouse"] = Score(600, 275, "Full House"),
		["fourkind"] = Score(600, 350, "Four of a kind"),
		["threekind"] = Score(600, 425, "Three of a kind")
	}
	self.cards = {
		[1] = love.graphics.newImage("assets/gfx/card1.png"),
		[2] = love.graphics.newImage("assets/gfx/card2.png"),
		[3] = love.graphics.newImage("assets/gfx/card3.png"),
		[4] = love.graphics.newImage("assets/gfx/card4.png"),
		[5] = love.graphics.newImage("assets/gfx/card5.png"),
		[6] = love.graphics.newImage("assets/gfx/card6.png")
	}
	self.input = Baton.new {
		["controls"] = {
			["roll"] = {'key:r'},
			["play"] = {'key:p'},
			["alt"] = {'key:lalt'},
			["enter"] = {'key:return'},
			["esc"]   = {'key:escape'},
			["click"] = {'mouse:1'}
		}
	}
	self.spellcard = love.graphics.newImage("assets/gfx/spellcard.png")
	snd.spellcard:setVolume(0.3)
	self.tweening = false
end

function Game:on_enter()
	Jukebox.current = 1
	self.state = {
		["playing"] = true,
		["choosing"] = false,
		["discarding"] = false,
		["first_roll"] = true,
		["end_turn"] = false,
		["show_score"] = false
	}
	self.selected = nil
	self.used = {}
	self.last_score = nil
	self.rolls = 1
	self.points = 0
	self.slot = {{x=0,d=0}, {x=0,d=0}, {x=0,d=0}, {x=0,d=0}, {x=0,d=0}}
	self.state.discarding = true
	self.combo = -1

	Snow:load(love.graphics.getWidth(), love.graphics.getHeight(), 25)
	self:roll()
	self.state.first_roll = false
	Jukebox:play()
end

function Game:on_exit()
	Jukebox:stop()
end

function Game:roll()
	math.randomseed(love.timer.getTime())
	snd["cardPlace1"]:play()
	snd["cardPlace2"]:play()
	snd["cardPlace3"]:play()
	snd["cardPlace4"]:play()
	snd["cardPlace2"]:play()
	local i, x = 0, 40
	for i = 1, 5 do
		if (self.state.discarding and self.slot[i].discard) or self.state.end_turn or self.state.first_roll then
			local dc = { x = x, orig_x = x, d = math.random(1, 6), y = CARD_Y, orig_y = CARD_Y }
			self.slot[i] = dc
		end
		x = (x + 170)
	end
end

function Game:print_cards()
	local i
	for i=1, 5 do
		love.graphics.draw(self.cards[self.slot[i].d], self.slot[i].x, self.slot[i].y)
		if self.slot[i].discard then
			love.graphics.setColor(0, 0, 0, 0.7)
			love.graphics.rectangle("fill", self.slot[i].x, self.slot[i].y, 150, 220, 10, 10)
			love.graphics.setColor(1, 1, 1, 1)
		end
	end
end

function Game:print_status()
	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.rectangle("fill", 0, 475, 910, 60)
	love.graphics.setColor(1, 1, 1, 1)
	local msg
	if self.state.discarding then
		msg = "Click the cards you wish to discard"
	elseif self.state.choosing and self.selected == nil then
		msg = "Choose a score from the list above"
	elseif self.state.choosing and self.selected ~= nil then
		msg = "Click to accept " .. self.selected.name
		status_width = Fonts.Status:getWidth(msg)
	elseif self.state.show_score then
		msg = "Points: " .. self.points
	elseif self.state.end_game then
		msg = "Final Score: " .. self.points
	end
		-- 335 270
	if self.combo > 0 then
		love.graphics.setColor(0, 0, 0)
		love.graphics.print("Combo: x" .. self.combo, 337, 272)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Combo: x" .. self.combo, 335, 270)
	end

	if msg ~= nil then
		love.graphics.setFont(Fonts.Status)
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(msg, 267, CARD_Y-62)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(msg, STATUS_X, STATUS_Y)

		if self.last_score ~= nil then
			love.graphics.setColor(0, 0, 0)
			love.graphics.print("+" .. self.last_score, 432, STATUS_Y-2)
			love.graphics.setColor(Color.Green)
			love.graphics.print("+" .. self.last_score, 430, STATUS_Y)
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.setFont(Fonts.Main)
	end
end

function Game:print_scores()
	for k,v in pairs(self.scores) do
		if self.used[k] then
			love.graphics.setColor(Color.Gray)
		elseif self.selected ~= nil and self.selected.name == v.name then
			love.graphics.setColor(Color.DarkBlue)
		else
			love.graphics.setColor(Color.Purple)
		end
		love.graphics.rectangle("fill", (v.x-20), (v.y-5),
			230, (Fonts.Main:getHeight(v.name)+10), 4, 4)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.print(v.name, v.x-2, v.y-2)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(v.name, v.x, v.y)
	end
end

function Game:discard(s)
	if s.discard then
		s.discard = false
		snd.cardPlace1:stop()
		snd.cardPlace1:play()
	else
		s.discard = true
		snd.discard:stop()
		snd.discard:play()
	end
end

function Game:select_score(n)
	self.selected = n
	snd.choose:stop()
	snd.choose:play()
end

function Game:add_points(n)
	self.points = self.points + n
end

function Game.unpk(a)
	local s = ""
	local i
	for i=1,#a do s = s .. " " .. a[i] end
	return s
end

function Game:compute_score()
	local sc = self.selected.name
	local i, c = 0, 0
	if sc == "Aces" then
		for i = 1, 5 do if self.slot[i].d == 1 then c = c + 1 end end
		self.used.aces = true
	elseif sc == "Twos" then
		for i = 1, 5 do if self.slot[i].d == 2 then c = c + 2 end end
		self.used.twos = true
	elseif sc == "Threes" then
		for i = 1, 5 do if self.slot[i].d == 3 then c = c + 3 end end
		self.used.threes = true
	elseif sc == "Fours" then
		for i = 1, 5 do if self.slot[i].d == 4 then c = c + 4 end end
		self.used.fours = true
	elseif sc == "Fives" then
		for i = 1, 5 do if self.slot[i].d == 5 then c = c + 5 end end
		self.used.fives = true
	elseif sc == "Sixes" then
		for i = 1, 5 do if self.slot[i].d == 6 then c = c + 6 end end
		self.used.sixes = true
	
	elseif sc == "Spellcard" then
		snd.spellcard:play()
		for i = 1, 5 do c = c + self.slot[i].d end
		self.used.chance = true
		self.tweening = true
		tweens[1] = Tween.new(2, self.slot[1], {x=335, y=200}, 'inExpo')
		tweens[2] = Tween.new(2, self.slot[2], {x=335, y=200}, 'inExpo')
		tweens[3] = Tween.new(2, self.slot[3], {x=335, y=200}, 'inExpo')
		tweens[4] = Tween.new(2, self.slot[4], {x=335, y=200}, 'inExpo')
		tweens[5] = Tween.new(2, self.slot[5], {x=335, y=200}, 'inExpo')

	elseif sc == "Yata!" then
		local first = self.slot[1].d
		if self.slot[2].d == first and self.slot[3].d == first
			and self.slot[4].d == first and self.slot[5].d == first then
			c = 50
		end

		self.used.yahtzee = true

	elseif sc == "Full House" then
		local dices = {}
		local count = 1
		local f3,f2 = false, false
		for i = 1,5 do table.insert(dices, self.slot[i].d) end
		table.sort(dices)
		for i = 1, 5 do
			if dices[i] == dices[i-1] then
				count=count+1
			else
				if count == 3 then
					f3=true
				elseif count == 2 then
					f2=true
				end
				count=1
			end
		end
		if count == 3 then f3 = true
		elseif count == 2 then f2 = true end
		
		if f3 and f2 then
			c = 25
		end

		self.used.fullhouse = true

	elseif sc == "Large Straight" then
		local same,same2 = false, false
		local lstr = {
			{1,2,3,4,5},
			{2,3,4,5,6}
		}
		local dices={}
			for i = 1,5 do table.insert(dices, self.slot[i].d) end
		table.sort(dices)
		if self.unpk(dices) == self.unpk(lstr[1])
			or self.unpk(dices) == self.unpk(lstr[2]) then
			c = 40
		end

		self.used.lstraight = true

	elseif sc == "Small Straight" then
		local same,same2 = false, false
		local sstr = {
			{1,2,3,4},
			{2,3,4,5},
			{3,4,5,6}
		}
		local dices={}
		for i = 1,5 do table.insert(dices, self.slot[i].d) end
		table.sort(dices)
	
		-- remove duplicates or it bugs out
		local res,hash={},{}
		for _,v in ipairs(dices) do
			if not hash[v] then
				res[#res+1] = v
				hash[v] = true
			end
		end
		
		for i=1,#sstr do
			if string.match(self.unpk(res), self.unpk(sstr[i])) then
				c = 30
				break
			end
		end
		self.used.sstraight = true
	
	elseif sc == "Four of a kind" then
		local freq = {}
		for i=1,5 do
			freq[self.slot[i].d] = (freq[self.slot[i].d] or 0) + 1	
		end
		for k,v in pairs(freq) do
			if v >= 4 then
				c = k*v
			end 
		end
		self.used.fourkind = true

	elseif sc == "Three of a kind" then
		local freq = {}
		for i=1,5 do
			freq[self.slot[i].d] = (freq[self.slot[i].d] or 0) + 1	
		end
		for k,v in pairs(freq) do
			if v >= 3 then
				c = k*v
			end 
		end
		self.used.threekind = true
	end

	if c > 0 then
		snd.select:play()
		self:add_points(c)
		if self.used.chance and self.combo < 3 then
			self.combo = self.combo + 1
			if self.combo == 3 then
				self.used.chance = nil
				self.combo = -1
			end
		end
	else
		if self.used.chance and self.combo < 3 then
			self.combo = -1
		end
		snd.nothing:play()
	end
	self.last_score = c
	self.state.end_turn = true
	self.state.choosing = false
	self.state.discarding = false
	self.state.show_score = true
	self.selected = nil

	local countused = 0
	for _,v in pairs(self.used) do countused = countused + 1 end
	if countused == 13 then
		snd.select:stop()
		snd.nothing:stop()
		snd.win:play()
		self.state.end_game = true
		self.state.end_turn = false
		self.state.show_score = false
		self.last_score = nil
	end
end

function Game:check_click(mx, my)
	if self.state.choosing and self.selected ~= nil and status_width ~= nil then
		if mx >= STATUS_X*scaleX and mx <= (STATUS_X+status_width)*scaleX and my >= STATUS_Y*scaleY and my <= (STATUS_Y+50)*scaleY then
			self:compute_score()
		end
	end

	if self.state.discarding then
		if mx >= 40*scaleX and mx <= 190*scaleX and my >= CARD_Y*scaleY and my <= CARD_Y_BOT*scaleY then
			self:discard(self.slot[1])
		elseif mx >= 210*scaleX and mx <= 360*scaleX and my >= CARD_Y*scaleY and my <= CARD_Y_BOT*scaleY then
			self:discard(self.slot[2])
		elseif mx >= 380*scaleX and mx <= 530*scaleX and my >= CARD_Y*scaleY and my <= CARD_Y_BOT*scaleY then
			self:discard(self.slot[3])
		elseif mx >= 550*scaleX and mx <= 700*scaleX and my >= CARD_Y*scaleY and my <= CARD_Y_BOT*scaleY then
			self:discard(self.slot[4])
		elseif mx >= 720*scaleX and mx <= 870*scaleX and my >= CARD_Y*scaleY and my <= CARD_Y_BOT*scaleY then
			self:discard(self.slot[5])
		end
	-- scores
	elseif self.state.choosing then
		if mx >= 60*scaleX and mx <= 290*scaleX and my >= 425*scaleY and my <= 475*scaleY and self.used.aces == nil then
			self:select_score(self.scores["aces"])

		elseif mx >= 60*scaleX and mx <= 290*scaleX and my >= 350*scaleY and my <= 400*scaleY and self.used.twos == nil then
			self:select_score(self.scores["twos"])

		elseif mx >= 60*scaleX and mx <= 290*scaleX and my >= 275*scaleY and my <= 325*scaleY and self.used.threes == nil then
			self:select_score(self.scores["threes"])
	
		elseif mx >= 60*scaleX and mx <= 290*scaleX and my >= 200*scaleY and my <= 250*scaleY and self.used.fours == nil then
			self:select_score(self.scores["fours"])

		elseif mx >= 60*scaleX and mx <= 290*scaleX and my >= 125*scaleY and my <= 175*scaleY and self.used.fives == nil then 
			self:select_score(self.scores["fives"])

		elseif mx >= 60*scaleX and mx <= 290*scaleX and my >= 50*scaleY and my <= 100*scaleY and self.used.sixes == nil then
			self:select_score(self.scores["sixes"])

		elseif mx >= 600*scaleX and mx <= 830*scaleX and my >= 50*scaleY and my <= 100*scaleY and self.used.yahtzee == nil then
			self:select_score(self.scores["yahtzee"])

		elseif mx >= 600*scaleX and mx <= 830*scaleX and my >= 125*scaleY and my <= 175*scaleY and self.used.lstraight == nil then
			self:select_score(self.scores["lstraight"])

		elseif mx >= 600*scaleX and mx <= 830*scaleX and my >= 200*scaleY and my <= 250*scaleY and self.used.sstraight == nil then
			self:select_score(self.scores["sstraight"])

		elseif mx >= 600*scaleX and mx <= 830*scaleX and my >= 275*scaleY and my <= 325*scaleY and self.used.fullhouse == nil then 
			self:select_score(self.scores["fullhouse"])

		elseif mx >= 600*scaleX and mx <= 830*scaleX and my >= 350*scaleY and my <= 400*scaleY and self.used.fourkind == nil then
			self:select_score(self.scores["fourkind"])

		elseif mx >= 600*scaleX and mx <= 830*scaleX and my >= 425*scaleY and my <= 475*scaleY and self.used.threekind == nil then
			self:select_score(self.scores["threekind"])
		
		elseif mx >= 335*scaleX and mx <= 565*scaleX and my >= 200*scaleY and my <= 250*scaleY and self.used.chance == nil then
			self:select_score(self.scores["chance"])
		end
	end
end

local tween_c = false
local spc2played = false

function Game:update(dt)
	Game.super.update(self, dt)
	for _,v in pairs(tweens) do
		tween_c = v:update(dt)
	end
	if tween_c then
		if not spc2played then
			snd.spellcard2:play()
			spc2played = true
		end
		local i
		for i = 1,5 do
			tweens[i] = Tween.new(i*.3, self.slot[i], {x = self.slot[i].orig_x, y = self.slot[i].orig_y}, "linear")
		end
		tween_c = false
		self.tweening = false
	end
	Snow:update(dt)
	Jukebox:update(dt)
	self.input:update()
	if self.input:pressed "roll" and not self.tweening then
		if self.state.discarding then
			if self.rolls < 2 then
				self:roll()
				self.rolls = self.rolls + 1
			else
				self:roll()
				self.rolls = 1
				self.state.discarding = false
				self.state.choosing = true
			end
		elseif self.state.end_turn then
			self:roll()
			self.last_score = nil
			self.state.end_turn = false
			self.state.discarding = true
		elseif self.state.end_game then
			self.points = 0
			self.used = {}
			self.combo = -1
			self.selected = nil
			self.state.end_game = false
			self.state.first_roll = true
			self:roll()
			self.state.first_roll = false
			self.state.discarding = true
		end
	end

	if self.input:pressed "click" then
		local mx,my = love.mouse.getPosition()
		self:check_click(mx, my)
	end
	if self.input:pressed "play" then
		Jukebox:play()
	end
	if self.input:down "alt" and self.input:pressed "enter" then
		if Fullscreen then
			Fullscreen = false
			love.window.setFullscreen(false)
		else
			Fullscreen = true
			love.window.setFullscreen(true)
		end
	end
	if self.input:pressed "esc" then
		SceneManager:switch("STitle")
	end
end

-- 40 padding
-- 30 between cards
function Game:draw()
	Game.super.draw(self)
	local sx, sy = love.graphics.getWidth() / background:getWidth(),
		love.graphics.getHeight() / background:getHeight()
	love.graphics.draw(background, -120, 0, 0, math.max(sx,sy))

	--[[love.graphics.setColor(0, 0, 0, 0.4)
	local screenW, screenH = love.graphics.getDimensions()
	love.graphics.rectangle("fill", 0, 0, screenW, screenH)
	love.graphics.setColor(Color.Clear)]]

	Snow:draw()
	love.graphics.setColor(1, 1, 1, 255)
	self:print_scores()
	self:print_status()
	self:print_cards()
end

return Game