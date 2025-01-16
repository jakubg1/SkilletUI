local class = require "com.class"

---@class EditorKeyframes
---@overload fun(editor):EditorKeyframes
local EditorKeyframes = class:derive("EditorKeyframes")

-- Place your imports here
local Vec2 = require("Vector2")



---Constructs a new Editor Keyframe Editor.
---@param editor Editor The UI editor this Keyframe Editor belongs to.
function EditorKeyframes:new(editor)
    self.editor = editor

    self.POS = Vec2(215, 685)
    self.SIZE = Vec2(1000, 180)
    self.NODE_LIST_WIDTH = 200
    self.KEYFRAME_AREA_X = self.POS.x + self.NODE_LIST_WIDTH
    self.KEYFRAME_AREA_WIDTH = self.SIZE.x - self.NODE_LIST_WIDTH
    self.HEADER_HEIGHT = 20
    self.ITEM_HEIGHT = 20
end



---Returns the Y coordinate of the n-th entry in the list (starting from 1) on the screen.
---@param n integer The item index.
---@return number
function EditorKeyframes:getItemY(n)
    return self.POS.y + self.HEADER_HEIGHT + self.ITEM_HEIGHT * (n - 1)-- - self.scrollOffset
end



---Returns the X coordinate of the given time `t` on the timeline.
---@param t number Time in seconds.
function EditorKeyframes:getTimeX(t)
    return self.POS.x + self.NODE_LIST_WIDTH + t * 150
end



---Draws the Keyframe Editor.
function EditorKeyframes:draw()
    -- Background
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)

    -- Timeline header
    love.graphics.setColor(1, 1, 1)
    _IMAGES.ed_button:draw(self.POS + Vec2(self.NODE_LIST_WIDTH, 0), Vec2(self.KEYFRAME_AREA_WIDTH, self.HEADER_HEIGHT), 2)
    for i = 0, 5 do
        self.editor:drawShadowedText(tostring(i), self:getTimeX(i), self.POS.y + 2, _COLORS.black, nil, nil, true)
    end

    -- Real entries
    local info = _TIMELINE:getInfo()
    for i, name in ipairs(_TIMELINE.nodeNames) do
        local node = _UI:findChildByName(name)
        local y = self:getItemY(i)
        -- Node name and timeline background
        local color = node and _COLORS.white or _COLORS.red
        self.editor:drawShadowedText(name, self.POS.x + 5, y + 2, color)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
        love.graphics.rectangle("fill", self.KEYFRAME_AREA_X, y, self.KEYFRAME_AREA_WIDTH, self.ITEM_HEIGHT)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", self.KEYFRAME_AREA_X, y, self.KEYFRAME_AREA_WIDTH, self.ITEM_HEIGHT)
    end

    -- Ghost entry
    if self.editor.selectedNode then
        self.editor:drawShadowedText(self.editor.selectedNode:getName(), self.POS.x + 5, self.POS.y + 22, _COLORS.white, nil, 0.5)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
        love.graphics.rectangle("fill", self.KEYFRAME_AREA_X, self.POS.y + self.HEADER_HEIGHT, self.KEYFRAME_AREA_WIDTH, self.ITEM_HEIGHT)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", self.KEYFRAME_AREA_X, self.POS.y + self.HEADER_HEIGHT, self.KEYFRAME_AREA_WIDTH, self.ITEM_HEIGHT)
    end

    -- Time grid
    for i = 0, 21 do
        local x = self:getTimeX(i * 0.25)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, i % 4 == 0 and 0.5 or 0.2)
        love.graphics.line(x, self.POS.y + self.HEADER_HEIGHT, x, self.POS.y + self.SIZE.y - self.HEADER_HEIGHT)
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

    -- Playhead
    local x = self:getTimeX(_TIMELINE.playbackTime or 0)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(3)
    love.graphics.line(x, self.POS.y + self.HEADER_HEIGHT - 5, x, self.POS.y + self.SIZE.y)
    love.graphics.polygon("fill", x - 10, self.POS.y + self.HEADER_HEIGHT - 10, x + 10, self.POS.y + self.HEADER_HEIGHT - 10, x, self.POS.y + self.HEADER_HEIGHT)

    -- Border
    love.graphics.setColor(0.5, 0.75, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)
end



return EditorKeyframes