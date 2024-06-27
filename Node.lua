local class = require "com.class"

---@class Node
---@overload fun(data, parent):Node
local Node = class:derive("Node")

local Vec2 = require("Vector2")
local Box = require("Box")
local Canvas = require("Canvas")
local NineSprite = require("NineSprite")
local Text = require("Text")
local TitleDigit = require("TitleDigit")



local ALIGNMENTS = {
    topLeft = Vec2(0, 0),
    top = Vec2(0.5, 0),
    topRight = Vec2(1, 0),
    left = Vec2(0, 0.5),
    center = Vec2(0.5, 0.5),
    right = Vec2(1, 0.5),
    bottomLeft = Vec2(0, 1),
    bottom = Vec2(0.5, 1),
    bottomRight = Vec2(1, 1)
}



---Creates a new UI Node.
---@param data table The node data.
---@param parent Node? The parent node.
function Node:new(data, parent)
    self.parent = parent

    self.name = data.name
    self.type = data.type
    self.pos = Vec2(data.pos)
    self.align = data.align and ALIGNMENTS[data.align] or Vec2(data.align)
    self.parentAlign = data.parentAlign and ALIGNMENTS[data.parentAlign] or Vec2(data.parentAlign)
    self.alpha = data.alpha or 1
    self.inputScale = data.inputScale or 1

    self.clicked = false
    self.onClick = nil

    if data.type == "box" then
        self.widget = Box(self, data)
    elseif data.type == "canvas" then
        -- Not supported. Canvases have a few problems:
        -- - Debug drawing
        -- - Drawing stuff other than UI on such canvas would be a problem
        self.isCanvas = true
        self.widget = Canvas(self, data)
    elseif data.type == "9sprite" then
        self.widget = NineSprite(self, data)
    elseif data.type == "text" then
        self.widget = Text(self, data)
    elseif data.type == "@titleDigit" then
        self.widget = TitleDigit(self, data)
    end

    self.children = {}
    if data.children then
    	for i, child in ipairs(data.children) do
	    	table.insert(self.children, Node(child, self))
	    end
    end
end



---Returns the local position of this Node, which is relative to its parent's position.
---@return Vector2
function Node:getPos()
    return self.pos
end



---Sets the local position of this Node, which is relative to its parent's position.
---@param pos Vector2 The new local position to be set.
function Node:setPos(pos)
    self.pos = pos
end



---Returns the global position of this Node, i.e. the actual position after factoring in all parents' modifiers.
---@return Vector2
function Node:getGlobalPos()
    local pos = self.pos - (self:getSize() * self.align):floor()
    if self.parent then
        pos = pos + self:getParentAlignPos()
    end
    return pos
end



---Returns the global position of this Node, which has not been adjusted for the local widget alignment.
---@return Vector2
function Node:getGlobalPosWithoutLocalAlign()
    local pos = self.pos
    if self.parent then
        pos = pos + self:getParentAlignPos()
    end
    return pos
end



---Returns the Node's parent anchor.
---@return Vector2
function Node:getParentAlignPos()
    return self.parent:getGlobalPos() + (self.parent:getSize() * self.parentAlign):floor()
end



---Returns the size of this Node's widget, or `(0, 0)` if it contains no widget.
---@return Vector2
function Node:getSize()
    if self.widget then
        return self.widget:getSize()
    end
    return Vec2()
end



---Returns the input scale of this Node.
---@return number
function Node:getInputScale()
    if self.parent then
        return self.parent:getInputScale() * self.inputScale
    end
    return self.inputScale
end



---Returns whether this Node is hovered. (Currently works only for the upscaled UI)
function Node:isHovered()
    return self:hasPixel(_MousePos / self:getInputScale())
end



---Returns `true` if the given pixel position is inside of this Node's bounding box.
---@param pos Vector2 The position to be checked.
---@return boolean
function Node:hasPixel(pos)
    if self.widget then
        return _Utils.isPointInsideBox(pos, self:getGlobalPos(), self:getSize())
    end
    return false
end



---Sets an on-click function (or resets it, if no argument is provided).
---@param f function? The function to be executed if this Node is clicked.
function Node:setOnClick(f)
    self.onClick = f
end



---Returns the first encountered child of the provided name, or `nil` if it is not found.
---@param name string The name of the child to be found.
---@return Node?
function Node:findChildByName(name)
    for i, child in ipairs(self.children) do
        if child.name == name then
            return child
        end
        local potentialResult = child:findChildByName(name)
        if potentialResult then
            return potentialResult
        end
    end
end



---Returns the first encountered child that contains the provided position, or `nil` if it is not found.
---@param pos Vector2 The position to be checked.
---@return Node?
function Node:findChildByPixel(pos)
    for i, child in ipairs(self.children) do
        if child:hasPixel(pos) then
            return child
        end
        local potentialResult = child:findChildByPixel(pos)
        if potentialResult then
            return potentialResult
        end
    end
end



---Updates this Node's widget, if it exists, and all its children.
---@param dt number Time delta, in seconds.
function Node:update(dt)
    if self.widget then
        self.widget:update(dt)
    end
    for i, child in ipairs(self.children) do
        child:update(dt)
    end
end



---Draws this Node's widget, if it exists, and all its children.
function Node:draw()
    if not self.isCanvas then
        if self.widget then
            self.widget:draw()
        end
        for i, child in ipairs(self.children) do
            child:draw()
        end
    else
        -- Canvases are treated differently.
        self.widget:activate()
        for i, child in ipairs(self.children) do
            child:draw()
        end
        self.widget:draw()
    end
end



---Draws this Node's bounding box, or a crosshair if this Node has no widget.
---The borders are all inclusive.
function Node:drawHitbox()
    local pos = self:getGlobalPos()
    love.graphics.setLineWidth(1)
    if self.widget then
        local size = self:getSize()
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("line", pos.x + 0.5, pos.y + 0.5, size.x - 1, size.y - 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        self:drawCrosshair(pos, 2)
    end
end



---Draws this Node's bounding box in a different color (or a crosshair if this Node has no widget), and some indicators around.
---The borders are all inclusive.
function Node:drawSelected()
    local pos = self:getGlobalPos()
    love.graphics.setLineWidth(1)
    if self.widget then
        local size = self:getSize()
        love.graphics.setColor(0, 1, 1)
        love.graphics.rectangle("line", pos.x + 0.5, pos.y + 0.5, size.x - 1, size.y - 1)
    else
        love.graphics.setColor(1, 1, 1)
        self:drawCrosshair(pos, 2)
    end
    -- Draw local crosshair.
    local localPos = self:getGlobalPosWithoutLocalAlign()
    love.graphics.setColor(0, 0, 1)
    self:drawCrosshair(localPos, 2)
    -- Draw parent align crosshair.
    local localPos2 = self:getParentAlignPos()
    love.graphics.setColor(1, 0, 1)
    self:drawCrosshair(localPos2, 2)
    -- Draw a line between them.
    love.graphics.setColor(0.5, 0, 1)
    love.graphics.line(localPos.x, localPos.y, localPos2.x, localPos2.y)
end



---Internal function which draws a crosshair.
---@param pos Vector2 The crosshair position.
---@param size number The crosshair size, in pixels.
function Node:drawCrosshair(pos, size)
    pos = pos:floor() + 0.5
    love.graphics.line(pos.x - size, pos.y, pos.x + size, pos.y)
    love.graphics.line(pos.x, pos.y - size, pos.x, pos.y + size)
end



---Executed whenever a mouse button is pressed anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
function Node:mousepressed(x, y, button)
    if button == 1 and self:isHovered() then
        self.clicked = true
    end
    for i, child in ipairs(self.children) do
        child:mousepressed(x, y, button)
    end
end



---Executed whenever a mouse button is released anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function Node:mousereleased(x, y, button)
    if button == 1 and self.clicked then
        self.clicked = false
        -- We don't want the click function to occur if the cursor was released outside of the node.
        if self:isHovered() then
            if self.onClick then
                self.onClick()
            end
        end
    end
    for i, child in ipairs(self.children) do
        child:mousereleased(x, y, button)
    end
end



return Node