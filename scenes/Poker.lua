local Button = require "lib.Button"
local Baton  = require "lib.Baton"
local Scene = require "lib.Scene"
local Tween = require "lib.Tween"
local Snow = require "lib.Snow"
local Poker = Scene:extends()

CARD_WIDTH = 144
CARD_HEIGHT = 217

CARD_DIMS = {
	["player"] = {
		{ x = 50, y = 544 },
		{ x = 200, y = 544 }
	},
	["dealer"] = {
		{ x = 495, y = 10 },
		{ x = 535, y = 10}
	}
}

local tweens = {}

function Poker:new()
	Poker.super.new(self)
	self.cards = {}
	self.card_slot = {}
	local s, n
	for s = 1, 4 do
		local suit
		if s == 1 then suit = "hearts"
		elseif s == 2 then suit = "diamonds"
		elseif s == 3 then suit = "clubs"
		elseif s == 4 then suit = "spades"
		end

		for n = 1, 13 do
			self.cards[#self.cards+1] = love.graphics.newImage("assets/gfx/poker/" .. suit .. "_" .. n .. ".png")
		end
	end

	self.card_back = love.graphics.newImage("assets/gfx/poker/card_back.png")

	-- center slot dimensions
	local i, x = 0, 40
	for i = 1, 5 do
		self.card_slot[i] = { x = x+5, y = 255 }
		x = (x + 170)
	end

	-- avatars
	self.avatar = {
		marisa = {
			image = love.graphics.newImage("assets/gfx/poker/marisa.png"),
			name  = "Marisa"
		}
	}

	-- controls
	self.input = Baton.new {
		["controls"] = {
			["click"] = {'mouse:1'}
		}
	}
end

function Poker:draw_card(n, x, y, slot, shadow)
	if slot ~= nil and slot > 0 then
		x = self.card_slot[slot].x+5
		y = self.card_slot[slot].y
	else
		if shadow then
			love.graphics.setColor(Color.Shadow)
			love.graphics.rectangle("fill", x+1, y+1, CARD_WIDTH, CARD_HEIGHT, 10, 10)
		end
	end
	love.graphics.setColor(Color.Clear)
	local card = n > 0 and self.deck[n] or self.card_back
	love.graphics.draw(card, x, y)
end

function Poker:draw_center()
	love.graphics.setLineWidth(10)
	love.graphics.setColor(Color.DarkBlue)
	local i = 0
	for i = 1, 5 do
		love.graphics.rectangle("line", self.card_slot[i].x, 250, CARD_WIDTH+10, CARD_HEIGHT+10, 10, 10)
	end
	love.graphics.setColor(Color.Clear)
end

function Poker:on_enter()
	Snow:load(love.graphics.getWidth(), love.graphics.getHeight(), 25)
	local raise_max = Button(400, 544, "Raise Max")
	local raise = Button(400, 594, "Raise")
	local call  = Button(400, 644, "Call")
	call.on_click = function()
		print("Clicked call")
	end
	local fold  = Button(400, 694, "Fold")
	self.entity_mgr:add(raise_max)
	self.entity_mgr:add(raise)
	self.entity_mgr:add(call)
	self.entity_mgr:add(fold)

	-- generate a new deck
	self.pot = 0
	self.credits = 100
	self.dealer_credits = 100
	self.deck = {}
	self.hand = {}
	self.dealer_hand = {}
	self.deck_length = 52
	self:shuffle()
	self:add_to_pot(2, 5)

	self:deal()
end

function Poker:shuffle()
	math.randomseed(love.timer.getTime())
	local i
	local swap, temp
	for i = 1, self.deck_length do
		swap = math.floor(math.random() * i)
		temp = self.cards[i]
		self.deck[i] = self.cards[swap]
		self.deck[swap] = temp
	end
end

function Poker:deal()
	math.randomseed(love.timer.getTime())
	local new_card = {
		card = math.random(1, self.deck_length),
		x    = 710,
		y    = 544
	}

	self.hand[1], self.hand[2] = new_card, new_card

	tweens[1] = Tween.new(0.5, self.hand[1], CARD_DIMS.player[1], 'linear')
	tweens[2] = Tween.new(0.7, self.hand[2], CARD_DIMS.player[2], 'linear')

	self.dealer_hand[1] = self.deck[math.random(1,self.deck_length)]
	self.dealer_hand[2] = self.deck[math.random(1,self.deck_length)]
end

function Poker:add_to_pot(p, n)
	if p == 1 then self.credits = self.credits - n end
	if p == 2 then self.dealer_credits = self.dealer_credits - n end
	self.pot = self.pot + n
end

function Poker:show_hand()
	-- n, x, y, slot
	if self.hand[1] ~= nil then
		self:draw_card(self.hand[1].card, self.hand[1].x, self.hand[1].y, 0, true)
		self:draw_card(self.hand[2].card, self.hand[2].x, self.hand[1].y, 0, true)
	end
end

function Poker:update(dt)
	Poker.super.update(self, dt)
	for _,v in pairs(tweens) do v:update(dt) end
	Snow:update(dt)
	self.input:update()

	if self.input:pressed "click" then
		local mx, my = love.mouse.getPosition()
		for _,v in pairs(self.entity_mgr.entities) do
			if mx >= v.x*scaleX and mx <= (v.x+v.w)*scaleX and my >= v.y*scaleY and my <= (v.y+v.h)*scaleY then
				if v.on_click ~= nil then
					v:on_click()
				end
			end
		end
	end
end

function Poker.println(s, x, y, f)
	if f ~= nil then
		love.graphics.setFont(f)
	else
		love.graphics.setFont(Fonts.Button)
	end
	love.graphics.setColor(Color.Shadow)
	love.graphics.print(s, x+2, y+2)
	love.graphics.setColor(Color.Clear)
	love.graphics.print(s, x, y)
end

function Poker:draw()
	love.graphics.clear(Color.LightBlue)
	
	Snow:draw()

	-- backdrop for opponent
	local credstr = self.avatar.marisa.name .. ": " .. self.dealer_credits
	local creditx = (495-Fonts.Button:getWidth(credstr))-40

	love.graphics.setColor(Color.Purple)
	love.graphics.rectangle("fill", creditx-30, 5, 560, 230)
	love.graphics.setColor(Color.Clear)

	-- opponents avatar
	love.graphics.draw(self.avatar.marisa.image, 695, 30)
	self:draw_center()

	-- opponents cards
	self:draw_card(0, 495, 10, nil, false)
	self:draw_card(0, 535, 10, nil, false)

	-- opponents credits
	
	self.println(credstr, creditx, 10)
	
	-- draw pot
	self.println("Pot: " .. self.pot, 47, 200, Fonts.Status)

	love.graphics.setColor(0.10196078431, 0.2862745098, 0.36078431372, 0.4)
	love.graphics.rectangle("fill", 30, 525, 855, 250)
	love.graphics.setColor(Color.Clear)
	-- show players hand and credits
	self:show_hand()
	self.println("Credits: " .. self.credits, 530, 544, Fonts.Status)

	-- draw the deck
	self:draw_card(0, 710, 544)

	Poker.super.draw(self)
end

return Poker