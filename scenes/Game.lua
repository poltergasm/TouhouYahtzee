local Score = require "lib.Score"
local Baton = require "lib.Baton"
local Scene = require "lib.Scene"
local Game = Scene:extends()

local CARD_Y = love.graphics.getHeight() - 256
local CARD_Y_BOT = CARD_Y + 226
local snd = {
	["cardPlace1"] = love.audio.newSource("assets/audio/sfx/cardPlace1.wav", "static"),
	["cardPlace2"] = love.audio.newSource("assets/audio/sfx/cardPlace2.wav", "static"),
	["cardPlace3"] = love.audio.newSource("assets/audio/sfx/cardPlace3.wav", "static"),
	["cardPlace4"] = love.audio.newSource("assets/audio/sfx/cardPlace4.wav", "static"),
	["discard"] = love.audio.newSource("assets/audio/sfx/discard.wav", "static")
}

function Game:new()
	Game.super.new(self)

	self.selected = nil
	self.used = {}
	self.last_score = nil
	self.rolls = 1
	self.points = 0
	self.slot = {{x=0,d=0}, {x=0,d=0}, {x=0,d=0}, {x=0,d=0}, {x=0,d=0}}
	self.state = {
		["playing"] = true,
		["choosing"] = false,
		["discarding"] = false,
		["first_roll"] = true,
		["end_turn"] = false
	}
	self.scores = {
		--["change"] = Score(200, 50, "Spellcard"),
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
			["click"] = {'mouse:1'}
		}
	}
	self.spellcard = love.graphics.newImage("assets/gfx/spellcard.png")
	self.state.discarding = true
	self:roll()
	self.state.first_roll = false
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
			local dc = { x = x, d = math.random(1, 6) }
			self.slot[i] = dc
		end
		x = x + 170
	end
	-- play sound
end

function Game:print_cards()
	local i
	for i=1, 5 do
		love.graphics.draw(self.cards[self.slot[i].d], self.slot[i].x, CARD_Y)
		if self.slot[i].discard then
			love.graphics.setColor(0, 0, 0, 0.7)
			love.graphics.rectangle("fill", self.slot[i].x, CARD_Y, 150, 220, 10, 10)
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
	end

	if msg ~= nil then
		love.graphics.setFont(Fonts.Status)
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(msg, 267, CARD_Y-62)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(msg, 265, CARD_Y-60)
		love.graphics.setFont(Fonts.Main)
	end
end

function Game:print_scores()
	love.graphics.setColor(Color.Blue)
	love.graphics.rectangle("fill", 330, 195, 230, 50, 4, 4)
	love.graphics.setColor(0, 0, 0)
	love.graphics.print("Spellcard", 348, 198)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Spellcard", 350, 200)
	for _,v in pairs(self.scores) do
		if self.used[v.name] then 
			love.graphics.setColor(Color.Red)
		elseif self.selected ~= nil and self.selected.name == v.name then
			love.graphics.setColor(Color.DarkBlue)
		else
			love.graphics.setColor(Color.Purple)
		end
		love.graphics.rectangle("fill", v.x-20, v.y-5,
			230, Fonts.Main:getHeight(v.name)+10, 4, 4)
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(v.name, v.x-2, v.y-2)
		love.graphics.setColor(1, 1, 1)
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
	-- play sound
end

function Game:check_click(mx, my)
	-- slot 1
	if self.state.discarding then
		if mx >= 40 and mx <= 190 and my >= CARD_Y and my <= CARD_Y_BOT then
			self:discard(self.slot[1])
		elseif mx >= 210 and mx <= 360 and my >= CARD_Y and my <= CARD_Y_BOT then
			self:discard(self.slot[2])
		elseif mx >= 380 and mx <= 530 and my >= CARD_Y and my <= CARD_Y_BOT then
			self:discard(self.slot[3])
		elseif mx >= 550 and mx <= 700 and my >= CARD_Y and my <= CARD_Y_BOT then
			self:discard(self.slot[4])
		elseif mx >= 720 and mx <= 870 and my >= CARD_Y and my <= CARD_Y_BOT then
			self:discard(self.slot[5])
		end
	-- scores
	elseif self.state.choosing then
		if mx >= 60 and mx <= 290 and my >= 425 and my <= 475 and self.used.aces == nil then
			self:select_score(self.scores["aces"])

		elseif mx >= 60 and mx <= 290 and my >= 350 and my <= 400 and self.used.twos == nil then
			self:select_score(self.scores["twos"])

		elseif mx >= 60 and mx <= 290 and my >= 275 and my <= 325 and self.used.threes == nil then
			self:select_score(self.scores["threes"])
	
		elseif mx >= 60 and mx <= 290 and my >= 200 and my <= 250 and self.used.fours == nil then
			self:select_score(self.scores["fours"])

		elseif mx >= 60 and mx <= 290 and my >= 125 and my <= 175 and self.used.fives == nil then 
			self:select_score(self.scores["fives"])

		elseif mx >= 60 and mx <= 290 and my >= 50 and my <= 100 and self.used.sixes == nil then
			self:select_score(self.scores["sixes"])

		elseif mx >= 600 and mx <= 830 and my >= 50 and my <= 100 and self.used.yahtzee == nil then
			self:select_score(self.scores["yahtzee"])

		elseif mx >= 600 and mx <= 830 and my >= 125 and my <= 175 and self.used.lstraight == nil then
			self:select_score(self.scores["lstraight"])

		elseif mx >= 600 and mx <= 830 and my >= 200 and my <= 250 and self.used.sstraight == nil then
			self:select_score(self.scores["sstraight"])

		elseif mx >= 600 and mx <= 830 and my >= 275 and my <= 325 and self.used.fullhouse == nil then 
			self:select_score(self.scores["fullhouse"])

		elseif mx >= 600 and mx <= 830 and my >= 350 and my <= 400 and self.used.fourkind == nil then
			self:select_score(self.scores["fourkind"])

		elseif mx >= 600 and mx <= 830 and my >= 425 and my <= 475 and self.used.threekind == nil then
			self:select_score(self.scores["threekind"])	
		end
	end 
end

function Game:update(dt)
	Game.super.update(self, dt)
	self.input:update()
	if self.input:pressed "roll" then
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
		end
	end

	if self.input:pressed "click" then
		local mx,my = love.mouse.getPosition()
		self:check_click(mx, my)
	end
end

-- 40 padding
-- 30 between cards
function Game:draw()
	Game.super.draw(self)
	love.graphics.setBackgroundColor(Color.Pink)
	love.graphics.setColor(1, 1, 1, 255)
	self:print_scores()
	self:print_status()
	self:print_cards()
end

return Game