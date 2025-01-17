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

    self.POS = Vec2(215, 685)
    self.SIZE = Vec2(1000, 200)
    self.NODE_LIST_WIDTH = 200
    self.KEYFRAME_AREA_X = self.POS.x + self.NODE_LIST_WIDTH
    self.KEYFRAME_AREA_WIDTH = self.SIZE.x - self.NODE_LIST_WIDTH
    self.HEADER_HEIGHT = 20
    self.ITEM_HEIGHT = 20
    self.TIME_SCALE_CONSTANT = 150

    self.timeOffset = 0
    self.scrollOffset = 0
    self.maxScrollOffset = 0
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



---Updates the Keyframe Editor.
---@param dt number Time delta in seconds.
function EditorKeyframes:update(dt)
    -- Calculate the maximum scroll offset.
    self.maxScrollOffset = math.max(self.ITEM_HEIGHT * #_TIMELINE.nodeNames - self.SIZE.y + self.HEADER_HEIGHT, 0)
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
    if nodeOrName == self.editor.selectedNode then
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
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.KEYFRAME_AREA_X, y, self.KEYFRAME_AREA_WIDTH, self.ITEM_HEIGHT)
end



---Draws the Keyframe Editor.
function EditorKeyframes:draw()
    -- Background
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)

    -- Timeline header
    love.graphics.setColor(1, 1, 1)
    _IMAGES.ed_button:draw(self.POS + Vec2(self.NODE_LIST_WIDTH, 0), Vec2(self.KEYFRAME_AREA_WIDTH, self.HEADER_HEIGHT), 2)
    local tmin = self:getTimeFromX(self.POS.x + self.NODE_LIST_WIDTH)
    local tmax = self:getTimeFromX(self.POS.x + self.SIZE.x)
    local t = math.ceil(tmin)
    while t < tmax do
        self.editor:drawShadowedText(tostring(t), self:getTimeX(t), self.POS.y + 2, _COLORS.black, nil, nil, true)
        t = t + 1
    end

    -- Real entries
    love.graphics.setScissor(self.POS.x, self.POS.y + self.HEADER_HEIGHT, self.SIZE.x, self.SIZE.y - self.HEADER_HEIGHT)
    local info = _TIMELINE:getInfo()
    local displayGhostNode = true
    for i, name in ipairs(_TIMELINE.nodeNames) do
        local node = _UI:findChildByName(name)
        local hovered = node and self.editor.hoveredNode == node
        local selected = node and self.editor.selectedNode == node
        -- Do not display the ghost node if we've selected a node that's already on the list!
        if selected then
            displayGhostNode = false
        end
        -- Node name and timeline background
        self:drawEntryBase(i, node or name)
    end

    -- Ghost entry
    if displayGhostNode and self.editor.selectedNode then
        self:drawEntryBase(#_TIMELINE.nodeNames + 1, self.editor.selectedNode, true)
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
    for i, name in ipairs(_TIMELINE.nodeNames) do
        local events = info[name]
        local y = self:getItemY(i)
        -- Events on the timeline
        for j, event in ipairs(events) do
            local x1 = self:getTimeX(event.time)
            local x2 = self:getTimeX(event.time + (event.duration or 0))
            local color = _COLORS.white
            if event.property == "pos" then
                color = _COLORS.green
            elseif event.property == "alpha" then
                color = _COLORS.red
            elseif event.property == "visible" then
                color = _COLORS.yellow
            elseif event.property == "typeInProgress" then
                color = _COLORS.blue
            end
            if x1 == x2 then
                -- Instant events are drawn as a line.
                love.graphics.setLineWidth(3)
                love.graphics.setColor(color.r, color.g, color.b)
                love.graphics.line(x1, y, x1, y + self.ITEM_HEIGHT)
            else
                -- Events that have duration are drawn as a filled box.
                love.graphics.setColor(color.r, color.g, color.b, 0.5)
                love.graphics.rectangle("fill", x1, y, x2 - x1, self.ITEM_HEIGHT)
                love.graphics.setLineWidth(1)
                love.graphics.setColor(color.r, color.g, color.b)
                love.graphics.rectangle("line", x1, y, x2 - x1, self.ITEM_HEIGHT)
            end
        end
    end
    love.graphics.setScissor()

    -- Playhead
    local x = self:getTimeX(_TIMELINE.playbackTime or 0)
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



---Executed whenever a mouse wheel has been scrolled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function EditorKeyframes:wheelmoved(x, y)
    if self:isHovered() then
        self.scrollOffset = math.min(math.max(self.scrollOffset - y * self.ITEM_HEIGHT * 3, 0), self.maxScrollOffset)
    end
end



return EditorKeyframes