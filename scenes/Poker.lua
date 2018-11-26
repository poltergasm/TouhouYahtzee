local Button = require "lib.Button"
local Scene = require "lib.Scene"
local Poker = Scene:extends()

CARD_WIDTH = 144
CARD_HEIGHT = 217

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

	-- center slot dimensions
	local i, x = 0, 40
	for i = 1, 5 do
		self.card_slot[i] = { x = x+5, y = 255 }
		x = (x + 170)
	end
end

function Poker:draw_card(n, x, y, slot)
	if slot ~= nil then
		x = self.card_slot[slot].x+5
		y = self.card_slot[slot].y
	else
		love.graphics.setColor(Color.Shadow)
		love.graphics.rectangle("fill", x+1, y+1, CARD_WIDTH, CARD_HEIGHT, 10, 10)
	end
	love.graphics.setColor(Color.Clear)
	love.graphics.draw(self.cards[n], x, y)
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
	--local testbtn = Button(300, 300, "Test Button")
	--self.entity_mgr:add(testbtn)
end

function Poker:update(dt)
	Poker.super.update(self, dt)
end

function Poker:draw()
	love.graphics.clear(Color.LightBlue)
	Poker.super.draw(self)
	self:draw_center()
	self:draw_card(20, 0, 0, 2)
	self:draw_card(5, 0, 0, 4)
end

return Poker