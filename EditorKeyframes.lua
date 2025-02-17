local class = require "com.class"

---@class EditorKeyframes
---@overload fun(editor):EditorKeyframes
local EditorKeyframes = class:derive("EditorKeyframes")

-- Place your imports here
local Vec2 = require("Vector2")



---Constructs a new Keyframe Editor.
---@param editor Editor The UI editor this Keyframe Editor belongs to.
function EditorKeyframes:new(editor)
    self.editor = editor

    self.POS = Vec2(230, 675)
    self.SIZE = Vec2(960, 200)
    self.NODE_LIST_WIDTH = 200
    self.KEYFRAME_AREA_X = self.POS.x + self.NODE_LIST_WIDTH
    self.KEYFRAME_AREA_WIDTH = self.SIZE.x - self.NODE_LIST_WIDTH
    self.HEADER_HEIGHT = 20
    self.ITEM_HEIGHT = 20
    self.TIME_SCALE_CONSTANT = 150

    self.eventInfo = {}
    self.hoveredEvent = nil
    self.selectedEvent = nil

    self.timeOffset = 0
    self.scrollOffset = 0
    self.maxScrollOffset = 0
end



---Returns event display information, in the form of a table. If no timeline exists, returns `nil`
---This function should only be called internally. If you want to get the current event display info, fetch the `self.eventInfo` field instead.
---@return table?
function EditorKeyframes:getEventInfo()
    local timeline = _PROJECT:getCurrentTimeline()
    if not timeline then
        return nil
    end
    local tab = {}
    local info = timeline:getInfo()
    -- Iterate over all nodes.
    for i, name in ipairs(timeline.nodeNames) do
        local events = info[name]
        local y = self:getItemY(i)
        -- Iterate over all events belonging to that node.
        for j, event in ipairs(events) do
            local x1 = self:getTimeX(event.time)
            local x2 = self:getTimeX(event.time + (event.duration or 0))
            table.insert(tab, {event = event, pos = Vec2(x1, y), size = Vec2(x2 - x1, self.ITEM_HEIGHT)})
        end
    end
    return tab
end



---Returns the Y coordinate of the n-th entry in the list (starting from 1) on the screen.
---@param n integer The item index.
---@return number
function EditorKeyframes:getItemY(n)
    return self.POS.y + self.HEADER_HEIGHT + self.ITEM_HEIGHT * (n - 1) - self.scrollOffset
end



---Returns the X coordinate of the given time `t` on the timeline.
---@param t number Time in seconds.
function EditorKeyframes:getTimeX(t)
    return self.POS.x + self.NODE_LIST_WIDTH + t * self.TIME_SCALE_CONSTANT
end



---Returns the time from the given `x` position on the screen.
---@param x number The X position on the screen.
function EditorKeyframes:getTimeFromX(x)
    return (x - self.POS.x - self.NODE_LIST_WIDTH) / self.TIME_SCALE_CONSTANT
end



---Returns `true` if the mouse cursor is inside of the Keyframe Editor area, `false` otherwise.
---@return boolean
function EditorKeyframes:isHovered()
    return _Utils.isPointInsideBox(_MousePos, self.POS, self.SIZE)
end



---Returns the hovered Timeline Event, if any is hovered.
---
---This function should only be called internally. If you want to get the currently hovered event, fetch the `self.hoveredEvent` field instead.
---@return TimelineEvent?
function EditorKeyframes:getHoveredEvent()
    if not self.eventInfo then
        return nil
    end
    for i, entry in ipairs(self.eventInfo) do
        local pos = entry.pos
        local size = entry.size
        if size.x == 0 then
            -- If the event is a point on the timeline, generate a some sort of margin to be able to hover it at all.
            pos = pos + Vec2(-5, 0)
            size = size + Vec2(10, 0)
        end
        if _Utils.isPointInsideBox(_MousePos, pos, size) then
            return entry.event
        end
    end
end



---Updates the Keyframe Editor.
---@param dt number Time delta in seconds.
function EditorKeyframes:update(dt)
    -- Update the event information.
    self.eventInfo = self:getEventInfo()
    self.hoveredEvent = self:getHoveredEvent()

    -- Calculate the maximum scroll offset.
    local timeline = _PROJECT:getCurrentTimeline()
    if timeline then
        self.maxScrollOffset = math.max(self.ITEM_HEIGHT * #timeline.nodeNames - self.SIZE.y + self.HEADER_HEIGHT, 0)
    else
        self.maxScrollOffset = 0
    end
    -- Scroll back if we've scrolled too far.
    self.scrollOffset = math.min(self.scrollOffset, self.maxScrollOffset)
end



---Draws this timeline's entry base for a single Node.
---@param n integer The index of this item on the list.
---@param nodeOrName Node|string If the Node exists, the Node. Otherwise, the name that will be displayed in red.
---@param isGhost boolean? If set, the node name will be grayed out as a ghost timeline.
function EditorKeyframes:drawEntryBase(n, nodeOrName, isGhost)
    local y = self:getItemY(n)
    local bgColor = nil
    if type(nodeOrName) == "table" and self.editor:isNodeSelected(nodeOrName) then
        bgColor = _COLORS.cyan
    elseif nodeOrName == self.editor.hoveredNode then
        bgColor = _COLORS.yellow
    end
    if bgColor then
        love.graphics.setColor(bgColor.r, bgColor.g, bgColor.b, 0.3)
        love.graphics.rectangle("fill", self.POS.x, y, self.NODE_LIST_WIDTH, self.ITEM_HEIGHT)
    end
    if type(nodeOrName) ~= "string" then
        love.graphics.setColor(1, 1, 1)
        nodeOrName:getIcon():draw(Vec2(self.POS.x, y))
        self.editor:drawShadowedText(nodeOrName:getName(), self.POS.x + 25, y + 2, _COLORS.white, nil, isGhost and 0.5 or 1)
    else
        self.editor:drawShadowedText(nodeOrName, self.POS.x + 5, y + 2, _COLORS.red, nil, isGhost and 0.5 or 1)
    end
    love.graphics.setColor(0.3, 0.3, 0.3, isGhost and 0.4 or 0.8)
    love.graphics.rectangle("fill", self.KEYFRAME_AREA_X, y, self.KEYFRAME_AREA_WIDTH, self.ITEM_HEIGHT)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", self.KEYFRAME_AREA_X, y, self.KEYFRAME_AREA_WIDTH, self.ITEM_HEIGHT)
end



---Draws the Keyframe Editor.
function EditorKeyframes:draw()
    -- Background
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)

    -- Timeline header
    love.graphics.setColor(1, 1, 1)
    _RESOURCE_MANAGER:getNineImage("ed_button"):draw(self.POS + Vec2(self.NODE_LIST_WIDTH, 0), Vec2(self.KEYFRAME_AREA_WIDTH, self.HEADER_HEIGHT), 2)
    local tmin = self:getTimeFromX(self.POS.x + self.NODE_LIST_WIDTH)
    local tmax = self:getTimeFromX(self.POS.x + self.SIZE.x)
    local t = math.ceil(tmin)
    while t < tmax do
        self.editor:drawShadowedText(tostring(t), self:getTimeX(t), self.POS.y + 2, _COLORS.black, nil, nil, true)
        t = t + 1
    end

    local timeline = _PROJECT:getCurrentTimeline()
    if timeline then
        -- Real entries
        love.graphics.setScissor(self.POS.x, self.POS.y + self.HEADER_HEIGHT, self.SIZE.x, self.SIZE.y - self.HEADER_HEIGHT)
        local displayGhostNode = true
        for i, name in ipairs(timeline.nodeNames) do
            local layout = _PROJECT:getCurrentLayout()
            local node = layout and layout:findChildByName(name)
            local hovered = node and self.editor.hoveredNode == node
            local selected = node and self.editor:isNodeSelected(node)
            -- Do not display the ghost node if we've selected a node that's already on the list!
            if selected then
                displayGhostNode = false
            end
            -- Node name and timeline background
            self:drawEntryBase(i, node or name)
        end

        -- Ghost entry. They are entries which are visible when exactly one node is selected and allows adding events to the timeline.
        if displayGhostNode and #self.editor.selectedNodes == 1 then
            self:drawEntryBase(#timeline.nodeNames + 1, self.editor.selectedNodes[1], true)
        end
    end

    -- Time grid
    local t = math.ceil(tmin * 4) / 4
    while t < tmax do
        local x = self:getTimeX(t)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, t % 1 == 0 and 0.3 or 0.1)
        love.graphics.line(x, self.POS.y + self.HEADER_HEIGHT, x, self.POS.y + self.SIZE.y)
        t = t + 0.25
    end

    -- Events
    for i, entry in ipairs(self.eventInfo) do
        local event = entry.event
        local color = _COLORS.white
        if event.property == "pos" then
            color = _COLORS.green
        elseif event.property == "alpha" then
            color = _COLORS.red
        elseif event.property == "visible" then
            color = _COLORS.orange
        elseif event.property == "typeInProgress" then
            color = _COLORS.blue
        end
        if event == self.selectedEvent then
            color = _COLORS.cyan
        elseif event == self.hoveredEvent then
            color = _COLORS.yellow
        end
        if entry.size.x == 0 or event.startValue then
            -- Instant events and events with a start value are drawn as a line.
            love.graphics.setLineWidth(3)
            love.graphics.setColor(color.r, color.g, color.b)
            love.graphics.line(entry.pos.x, entry.pos.y, entry.pos.x, entry.pos.y + entry.size.y)
        end
        if entry.size.x > 0 then
            -- Events that have duration are drawn as a filled box.
            love.graphics.setColor(color.r, color.g, color.b, 0.5)
            love.graphics.rectangle("fill", entry.pos.x, entry.pos.y, entry.size.x, entry.size.y)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(color.r, color.g, color.b)
            love.graphics.rectangle("line", entry.pos.x, entry.pos.y, entry.size.x, entry.size.y)
        end
    end
    love.graphics.setScissor()

    -- Playhead
    local x = self:getTimeX(timeline and timeline.playbackTime or 0)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(3)
    love.graphics.line(x, self.POS.y + self.HEADER_HEIGHT - 5, x, self.POS.y + self.SIZE.y)
    love.graphics.polygon("fill", x - 8, self.POS.y + self.HEADER_HEIGHT - 15, x + 8, self.POS.y + self.HEADER_HEIGHT - 15, x, self.POS.y + self.HEADER_HEIGHT)

    -- Scroll bar (non-interactive)
    if self.maxScrollOffset > 0 then
        local eh = self.SIZE.y - self.HEADER_HEIGHT
        love.graphics.setColor(0.5, 0.75, 1, 0.5)
        love.graphics.rectangle("fill", self.POS.x + self.SIZE.x - 10, self.POS.y + self.HEADER_HEIGHT, 10, eh)
        local y = self.scrollOffset / (self.maxScrollOffset + eh)
        local h = eh / (self.maxScrollOffset + eh)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", self.POS.x + self.SIZE.x - 10, self.POS.y + self.HEADER_HEIGHT + y * eh, 10, h * eh)
    end

    -- Border
    love.graphics.setColor(0.5, 0.75, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)
end



---Executed whenever a mouse button is pressed anywhere on the screen.
---Returns `true` if the input is consumed.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
---@param istouch boolean Whether the press is coming from a touch input.
---@param presses integer How many clicks have been performed in a short amount of time. Useful for double click checks.
---@return boolean
function EditorKeyframes:mousepressed(x, y, button, istouch, presses)
    if not self:isHovered() then
        return false
    end
    if button == 1 then
        self.selectedEvent = self.hoveredEvent
        return true
    end
    return false
end



---Executed whenever a mouse wheel has been scrolled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function EditorKeyframes:wheelmoved(x, y)
    if self:isHovered() then
        self.scrollOffset = math.min(math.max(self.scrollOffset - y * self.ITEM_HEIGHT * 3, 0), self.maxScrollOffset)
    end
end

---LOVE callback for when the window is resized.
---@param w integer The new width of the window.
---@param h integer The new height of the window.
function EditorKeyframes:resize(w, h)
    self.POS = Vec2(230, h - 225)
    self.SIZE = Vec2(w - 640, 200)
    self.KEYFRAME_AREA_WIDTH = self.SIZE.x - self.NODE_LIST_WIDTH
end



return EditorKeyframes