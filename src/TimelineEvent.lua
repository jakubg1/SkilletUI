local class = require "com.class"

---@class TimelineEvent
---@overload fun(timeline, data):TimelineEvent
local TimelineEvent = class:derive("TimelineEvent")

-- Place your imports here



---Constructs a new Timeline Event.
---@param timeline Timeline The Timeline this Event belongs to.
---@param data table The timeline data.
function TimelineEvent:new(timeline, data)
    self.timeline = timeline

    self.time = data.time
    self.type = data.type
    self.node = data.node
    self.property = data.property
    self.startValue = data.startValue
    self.value = data.value
    self.duration = data.duration
end



---Executes this Timeline Event.
function TimelineEvent:execute()
    if self.type == "setNodeProperty" then
        local node = _EDITOR:getCurrentLayoutUI() and _EDITOR:getCurrentLayoutUI():findChildByName(self.node)
        if not node then
            print(string.format("Could not find node %s to animate, skipping", self.node))
            return
        end
        node.properties:animateValue(self.property, self.startValue, self.value, self.duration)
    elseif self.type == "setWidgetProperty" then
        local node = _EDITOR:getCurrentLayoutUI() and _EDITOR:getCurrentLayoutUI():findChildByName(self.node)
        if not node then
            print(string.format("Could not find node %s to animate, skipping", self.node))
            return
        end
        node.widget.properties:animateValue(self.property, self.startValue, self.value, self.duration)
    end
end



return TimelineEvent