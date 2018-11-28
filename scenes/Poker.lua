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
	["bot"] = {
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
			self.cards[#self.cards+1] = {
				image = love.graphics.newImage("assets/gfx/poker/" .. suit .. "_" .. n .. ".png"),
				value = n
			}
		end
	end

	self.card_back = love.graphics.newImage("assets/gfx/poker/card_back.png")

	-- center slot dimensions
	local i, x = 0, 40
	for i = 1, 5 do
		self.card_slot[i] = { x = x+10, y = 255 }
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

function Poker:on_exit()
	Jukebox:stop()
end

function Poker:reset()
	self.state = {
		["river"] = false
	}

	self.pot = 0
	self.bet = 0
	self.credits = 50
	self.blind = 1 -- 1 for player, 2 for opponent
	self.bot_credits = 50
	self.deck = {}
	self.hand = {}
	self.table_cards = {}
	self.first_play = true
	self.bot_hand = {}
	self.bot_think_time = nil
	self.bot_thinking = false
	self.deck_length = 52
	self.cards_in_play = 0
	self.msgbox = {"Welcome, and good luck!", "You're up first"}
	self:shuffle()
	self:deal()
end

function Poker:on_enter()
	Jukebox.current = 2
	--Jukebox:play()
	self.entity_mgr.entities = {}
	Snow:load(love.graphics.getWidth(), love.graphics.getHeight(), 25)

	self:reset()

	local raise_max = Button(400, 544, "Raise Max")
	local raise = Button(400, 594, "Raise")
	local call  = Button(400, 644, "Call")
	local fold  = Button(400, 694, "Fold")
	call.on_click = function() self:call_hand(1) end
	raise.on_click = function() self:raise_bet(1) end
	raise_max.on_click = function() self:raise_bet(1, true) end

	local i
	for i = 1, 5 do self.table_cards[i] = { x = 710, y = 544 } end
	
	self.entity_mgr:add(raise_max)
	self.entity_mgr:add(raise)
	self.entity_mgr:add(call)
	self.entity_mgr:add(fold)
end

function Poker:draw_card(n, x, y, slot, shadow)
	if slot ~= nil and slot > 0 then
		x = self.card_slot[slot].x
		y = self.card_slot[slot].y
	else
		if shadow then
			love.graphics.setColor(Color.Shadow)
			love.graphics.rectangle("fill", x+1, y+1, CARD_WIDTH, CARD_HEIGHT, 10, 10)
		end
	end
	love.graphics.setColor(Color.Clear)
	local card = n > 0 and self.deck[n].image or self.card_back
	love.graphics.draw(card, x, y)
end

function Poker.unpk(a)
	local s = ""
	local i
	for i=1,#a do s = s .. " " .. a[i] end
	return s
end

function Poker:compute_score()
	local player_score, bot_score = 0, 0
	local tcards = {}
	for i = 1, self.cards_in_play do table.insert(tcards, self.table_cards[i].card) end
	table.sort(tcards)
end

function Poker:draw_center()
	love.graphics.setLineWidth(10)
	love.graphics.setColor(Color.DarkBlue)
	local i = 0
	for i = 1, 5 do
		love.graphics.rectangle("line", self.card_slot[i].x, 250, CARD_WIDTH+10, CARD_HEIGHT+10, 10, 10)
	end
	love.graphics.setColor(Color.Clear)

	if #self.table_cards > 0 then
		for i = 1, 5 do
			if self.table_cards[i].card ~= nil then
				local card = self.table_cards[i]
				self:draw_card(card.card, card.x, card.y)
			end
		end
	end
end

function Poker:call_hand(p)
	if p == 1 then
		snd.chipsHandle:stop()
		snd.chipsHandle:play()
		if self.first_play then self.bet = 1 end
		self:add_to_pot(1, self.bet)
		self:bot_turn()
	elseif p == 2 then
		self.msgbox = {"I will call", "Your turn"}
		self:add_to_pot(2, self.bet)
	end
end

function Poker:raise_bet(p, max)
	local chips = max and 5 or 1
	snd.chipsHandle:stop()
	snd.chipsHandle:play()
	if self.credits - chips < 0 then
		snd.chipsHandle:stop()
		snd.nothing:play()
	else
		self.bet = self.bet + chips
		self:add_to_pot(1, chips)
		local cred = chips > 1 and "credits" or "credit"
		self:bot_turn(false, {"The bet has been raised", "to " .. self.bet .. " " .. cred})
	end
end

function Poker:fold(p)
	-- 1 = player, 2 = bot
	if p == 1 then
		self.msgbox = {"Better luck next time"}
		self.bot_credits = self.bot_credits + self.pot
		self.pot = 0
		self.fold_time = love.timer.getTime()
	elseif p == 2 then
		self.msgbox = {"Drats, I fold", "You win this round."}
		self.credits = self.credits + self.pot
		self.pot = 0
		self.fold_time = love.timer.getTime()
	end
end

function Poker:bot_turn(decide, str)
	if not decide then
		self.bot_thinking = true
		self.bot_think_time = love.timer.getTime()
		self.msgbox = str ~= nil and str or {"Hmm... let me see"}
	else
		if self.first_play then
			self.first_play = false
			-- if the bet has been raised and we have no jacks+ or doubles
			-- then bail!
			if self.bet > 1 then
				local has_jack_or_higher = false
				local has_pair = false
				for _,v in pairs(self.bot_hand) do
					if v.value >= 11 then has_jack_or_higher = true end
				end
				if self.bot_hand[1].value == self.bot_hand[2].value then
					has_pair = true
				end

				if not has_jack_or_higher and not has_pair then
					self:fold(2)
				else
					self:call_hand(2)
				end
			else
				self:call_hand(2)
			end
		end
	end
end

function Poker:shuffle()
	math.randomseed(love.timer.getTime())
	local i
	local swap, temp
	for i = 1, self.deck_length do
		swap = math.floor(math.random(1, i))
		temp = self.cards[i]
		self.deck[i] = self.cards[swap]
		self.deck[swap] = temp
	end
end

function Poker:deal()
	math.randomseed(love.timer.getTime())
	self.hand[1] = {
		card = math.random(1, self.deck_length),
		x    = 710,
		y    = 544
	}

	self.hand[2] = {
		card = math.random(1, self.deck_length),
		x    = 710,
		y    = 544
	}

	self.dealing = true
	self.card_one_dealt = false
	tweens[1] = Tween.new(0.4, self.hand[1], CARD_DIMS.player[1], 'linear')
	snd.cardPlace1:play()
	
	self.bot_hand[1] = self.deck[math.random(1,self.deck_length)]
	self.bot_hand[2] = self.deck[math.random(1,self.deck_length)]
end

function Poker:deal_river()
	math.randomseed(love.timer.getTime())

	local i
	for i = 1, 3 do
		snd["cardPlace" .. i]:play()
		self.table_cards[i] = {
			x = 710,
			y = 544,
			card = math.random(1, self.deck_length)
		}

		tweens[i] = Tween.new(0.2 + i / 10, self.table_cards[i], { x = self.card_slot[i].x+5, y = self.card_slot[i].y }, 'linear')
	end
	self.state.river = true
end

function Poker:add_to_pot(p, n)
	if p == 1 then self.credits = self.credits - n end
	if p == 2 then self.bot_credits = self.bot_credits - n end
	self.pot = self.pot + n
end

function Poker:show_hand()
	-- n, x, y, slot
	if self.hand[1] ~= nil then
		self:draw_card(self.hand[1].card, self.hand[1].x, self.hand[1].y, 0, true)
		self:draw_card(self.hand[2].card, self.hand[2].x, self.hand[1].y, 0, true)
	end
end

function Poker:draw_status()
	love.graphics.setColor(0, 0, 0, 0.4)
	love.graphics.rectangle("fill", 47, 5, 285, 150)

	self.println(self.avatar.marisa.name .. " says:", 60, 20, Fonts.Button, Color.LimeGreen)
	
	local y = 55
	for _,v in pairs(self.msgbox) do
		self.println(v, 60, y, Fonts.Text2)
		y = y + 30
	end
end

function Poker.println(s, x, y, f, c)
	if f ~= nil then
		love.graphics.setFont(f)
	else
		love.graphics.setFont(Fonts.Button)
	end
	love.graphics.setColor(Color.Shadow)
	love.graphics.print(s, x+2, y+2)
	local color = c ~= nil and c or Color.Clear
	love.graphics.setColor(color)
	love.graphics.print(s, x, y)
	if c then love.graphics.setColor(Color.Clear) end
end

function Poker:update(dt)
	Poker.super.update(self, dt)

	if self.fold_time == nil then
		for _,v in pairs(tweens) do
			local c = v:update(dt)
			if self.dealing and not self.card_one_dealt and c then
				self.dealing = false
				self.card_one_dealt = true
				tweens[2] = Tween.new(0.4, self.hand[2], CARD_DIMS.player[2], 'linear')
				snd.cardPlace1:stop()
				snd.cardPlace2:play()
			end
		end
		Snow:update(dt)
		self.input:update()

		if not self.bot_thinking then
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
		else
			if love.timer.getTime() > self.bot_think_time+2 then
				self.bot_thinking = false
				self:bot_turn(true)
			end
		end
	else
		if love.timer.getTime() > self.fold_time+3 then
			self.fold_time = nil
			self:reset()
		end
	end
end

function Poker:draw()
	love.graphics.clear(Color.LightBlue)
	
	Snow:draw()

	-- backdrop for opponent
	local credstr = self.avatar.marisa.name .. ": " .. self.bot_credits
	local creditx = (495-Fonts.Button:getWidth(credstr))-40

	love.graphics.setColor(0.47, 0.13, 0.30, 0.3)
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

	-- draw status
	self:draw_status()

	Poker.super.draw(self)
end

return Poker