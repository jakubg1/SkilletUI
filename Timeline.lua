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
        {time = 1, type = "setNodeProperty", node = "TitleH1", property = "pos", value = Vec2(160, 35), duration = 0.5},
        {time = 1, type = "setNodeProperty", node = "TitleH2", property = "pos", value = Vec2(160, 35), duration = 0.5},
        {time = 1.5, type = "setNodeProperty", node = "TitleH1", property = "visible", value = false},
        {time = 1.5, type = "setNodeProperty", node = "TitleH2", property = "visible", value = false},
        {time = 1.5, type = "setNodeProperty", node = "Title", property = "visible", value = true},
        {time = 1.5, type = "setNodeProperty", node = "TitleDigit", property = "visible", value = true},
        {time = 1.5, type = "setNodeProperty", node = "Flash", property = "visible", value = true},
        {time = 1.5, type = "setWidgetProperty", node = "Flash", property = "alpha", value = 1},
        {time = 1.5, type = "setWidgetProperty", node = "Flash", property = "alpha", value = 0, duration = 1},
        {time = 2.5, type = "setNodeProperty", node = "Node", property = "visible", value = true},
        {time = 3, type = "setWidgetProperty", node = "TypeText", property = "typeInProgress", value = 1, duration = 1.5}
    }
    self.nodeNames = {
        "Title",
        "TitleH1",
        "TitleH2",
        "TitleDigit",
        "Flash",
        "Node",
        "TypeText"
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



---Returns a table, keyed by node names, of all events they have, in order of being specified in the `events` list.
---@return table
function Timeline:getInfo()
    local info = {}
    for i, event in ipairs(self.events) do
        -- Create a list for a node if that's the first time we see it.
        if not info[event.node] then
            info[event.node] = {}
        end
        -- Add the event to the appropriate list.
        table.insert(info[event.node], event)
    end
    return info
end



return Timeline