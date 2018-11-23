local Class = require "lib.Class"
local EntityManager = require "lib.EntityManager"

local Scene = Class:extends()

function Scene:new()
  self.entity_mgr = EntityManager()
end

function Scene:on_enter() end

function Scene:update(dt)
  self.entity_mgr:update(dt)
end

function Scene:draw()
  self.entity_mgr:draw()
end

return Scene