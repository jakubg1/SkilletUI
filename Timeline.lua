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
        {time = 2.5, type = "setNodeProperty", node = "TitleH1", property = "pos", value = Vec2(160, 35), duration = 0.5},
        {time = 2.5, type = "setNodeProperty", node = "TitleH2", property = "pos", value = Vec2(160, 35), duration = 0.5},
        {time = 3, type = "setNodeProperty", node = "TitleH1", property = "visible", value = false},
        {time = 3, type = "setNodeProperty", node = "TitleH2", property = "visible", value = false},
        {time = 3, type = "setNodeProperty", node = "Title", property = "visible", value = true},
        {time = 3, type = "setNodeProperty", node = "TitleDigit", property = "visible", value = true},
        {time = 3, type = "setWidgetProperty", node = "Flash", property = "alpha", value = 1},
        {time = 3, type = "setWidgetProperty", node = "Flash", property = "alpha", value = 0, duration = 1},
        {time = 4, type = "setNodeProperty", node = "Node", property = "visible", value = true}
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
    -- Process the events until either we've run out of them or the next one should not be executed yet.
    while self.events[self.playbackStep] and self.events[self.playbackStep].time <= self.playbackTime do
        self:processEvent(self.events[self.playbackStep])
        self.playbackStep = self.playbackStep + 1
    end
    -- If all events have been finished, stop the playback.
    if self.playbackStep > #self.events then
        self.playbackTime = nil
        self.playbackStep = nil
    end
end



---Processes a single Timeline Event.
---@param event table The event to be processed.
function Timeline:processEvent(event)
    if event.type == "setNodeProperty" then
        local node = _UI:findChildByName(event.node)
        if not node then
            print(string.format("Could not find node %s to animate, skipping", event.node))
            return
        end
        node.properties:animateValue(event.property, nil, event.value, event.duration)
    elseif event.type == "setWidgetProperty" then
        local node = _UI:findChildByName(event.node)
        if not node then
            print(string.format("Could not find node %s to animate, skipping", event.node))
            return
        end
        node.widget.properties:animateValue(event.property, nil, event.value, event.duration)
    end
end



---Plays the Timeline from the beginning.
function Timeline:play()
    self.playbackTime = 0
    self.playbackStep = 1
end



---Stops the Timeline from playing.
function Timeline:stop()
    self.playbackTime = nil
    self.playbackStep = nil
end



return Timeline