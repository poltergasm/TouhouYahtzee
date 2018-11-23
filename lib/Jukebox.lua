local Jukebox = {}
Jukebox.sfx = {}

function Jukebox:new(stopped)
  self.songs = {}
  self.current = 1
  self.stopped = stopped and true or false
  self.is_paused = false
  return self
end

function Jukebox:play()
  self.stopped = false
  self.songs[self.current].source:play()
end
function Jukebox:pause()
  self.is_paused = true
  self.stopped = true
  self.songs[self.current].source:pause()
end
function Jukebox:stop()
  self.songs[self.current].source:stop()
end
function Jukebox:get_current() return self.songs[self.current] end

function Jukebox:volume(v)
  for i = 1, #self.songs do
    self.songs[i].source:setVolume(v)
  end
end

local lastSfx = nil

function Jukebox:add_sfx(s, cb)
  if s ~= nil then
    local ns = {
      source = love.audio.newSource(s),
      state = "stopped"
    }
    function ns:play()
      lastSfx = self
      self.source:play()
    end
    if cb ~= nil and type(cb) == "function" then
      ns.callback = cb
    end
    table.insert(self.sfx, ns)
    return ns
  end
end

function Jukebox:add_song(s)
  if s.file ~= nil then
    -- automatically set stream to true, as jukeboxes are more known for 
    -- playing music rather than sound effects..
    self.songs[#self.songs + 1] = {
      source = love.audio.newSource(s.file, "stream"),
      name   = s.name or nil
    }
  end
end

function Jukebox.sfx:update(dt)
  if lastSfx and not lastSfx.source:isPlaying() then
    if lastSfx.callback ~= nil then lastSfx.callback() end
    lastSfx = nil
  end
end

function Jukebox:update(dt)
  self.sfx:update(dt)
  if #self.songs > 0 then

    -- has the current song finished playing?
    -- also make sure it's not just paused
    local song = self.songs[self.current].source
    if not song:isPlaying() and not self.is_paused then
      local nextId = self.current + 1
      if self.songs[nextId] ~= nil then
        self.current = nextId
        self.songs[nextId].source:play()
      else
        -- no songs left, so go back to the beginning
        self.current = 1
        self.songs[1].source:play()
      end
    end
  end
end

return Jukebox