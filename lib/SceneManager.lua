local SceneManager = {
  current = nil,
  scenes  = {}
}

function SceneManager:add(scenes)
  assert(scenes ~= nil and type(scenes) == "table", "SceneManager:add expects a table")
  for k,v in pairs(scenes) do
    self.scenes[k] = v
  end
end

function SceneManager:switch(scene)
  assert(self.scenes[scene], "Cannot switch to scene '" .. scene .. "' because it doesn't exist")
  self.current = self.scenes[scene]
  self.current:on_enter()
end

function SceneManager:update(dt) self.current:update(dt)  end
function SceneManager:draw()     self.current:draw()      end

return SceneManager