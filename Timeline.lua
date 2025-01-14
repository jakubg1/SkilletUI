local class = require "com.class"

---@class Timeline
---@overload fun():Timeline
local Timeline = class:derive("Timeline")

-- Place your imports here
local Vec2 = require("Vector2")



---Constructs a Timeline.
---Timelines can be launched and when updated, they will alter the node states.
---Right now, very much a test! This is a whole segment of code that is just starting off!!!
---The first Timeline animates the positions and alphas of Nodes/Widgets.
function Timeline:new()
    self.events = {
        {time = 0, type = "setNodeProperty", node = "TitleH1", property = "pos", value = Vec2(150, 35), duration = 3},
        {time = 0, type = "setNodeProperty", node = "TitleH2", property = "pos", value = Vec2(170, 35), duration = 3},
        {time = 3, type = "setNodeProperty", node = "TitleH1", property = "visible", value = false},
        {time = 3, type = "setNodeProperty", node = "TitleH2", property = "visible", value = false},
        {time = 3, type = "setNodeProperty", node = "Title", property = "visible", value = true},
        {time = 3, type = "setNodeProperty", node = "TitleDigit", property = "visible", value = true},
        {time = 3, type = "setWidgetProperty", node = "Flash", property = "alpha", value = 1},
        {time = 3, type = "setWidgetProperty", node = "Flash", property = "alpha", value = 0, duration = 0.5}
    }

    self.playbackTime = nil
    self.playbackStep = nil
end



---Updates this Timeline.
---@param dt number Time delta in seconds.
function Timeline:update(dt)
    if not self.playbackTime then
        -- This Timeline is not playing.
        return
    end

    self.playbackTime = self.playbackTime + dt
end



---Plays the Timeline from the beginning.
function Timeline:play()
    self.playbackTime = 0
    self.playbackStep = 0
end



return Timeline