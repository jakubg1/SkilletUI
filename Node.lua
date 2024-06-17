local class = require "com.class"

---@class Node
---@overload fun(data, parent):Node
local Node = class:derive("Node")

local Vec2 = require("Vector2")
local Box = require("Box")
local NineSprite = require("NineSprite")
local Text = require("Text")
local TitleDigit = require("TitleDigit")



local ALIGNMENTS = {
    topLeft = Vec2(0, 0),
    top = Vec2(0.5, 0),
    topRight = Vec2(1, 0),
    left = Vec2(0, 0.5),
    middle = Vec2(0.5, 0.5),
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
    self.pos = Vec2(data.pos)
    self.align = data.align and ALIGNMENTS[data.align] or Vec2(data.align)
    self.parentAlign = data.parentAlign and ALIGNMENTS[data.parentAlign] or Vec2(data.parentAlign)
    self.alpha = data.alpha or 1

    if data.type == "box" then
        self.widget = Box(data)
    elseif data.type == "9sprite" then
        self.widget = NineSprite(data)
    elseif data.type == "text" then
        self.widget = Text(data)
    elseif data.type == "@titleDigit" then
        self.widget = TitleDigit(data)
    end

    self.children = {}
    if data.children then
    	for i, child in ipairs(data.children) do
	    	table.insert(self.children, Node(child, self))
	    end
    end
end



---Returns the global position of this Node, i.e. the actual position after factoring in all parents' modifiers.
---@return Vector2
function Node:getGlobalPos()
    local pos = self.pos - (self:getSize() * self.align):floor()
    if self.parent then
        pos = pos + self.parent:getGlobalPos() + (self.parent:getSize() * self.parentAlign):floor()
    end
    return pos
end



---Returns the size of this Node's widget, or `(0, 0)` if it contains no widget.
---@return Vector2
function Node:getSize()
    if self.widget then
        return self.widget:getSize()
    end
    return Vec2()
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
    if self.widget then
        self.widget:draw(self:getGlobalPos(), self.alpha)
    end
    for i, child in ipairs(self.children) do
        child:draw()
    end
end



---Draws this Node's bounding box, or a crosshair if this Node has no widget.
---The borders are all inclusive.
function Node:drawHitbox()
    local pos = self:getGlobalPos()
    love.graphics.setLineWidth(1)
    if self.widget then
        local size = self:getSize()
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("line", pos.x + 0.5, pos.y + 0.5, size.x - 1, size.y - 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.line(pos.x - 1.5, pos.y + 0.5, pos.x + 2.5, pos.y + 0.5)
        love.graphics.line(pos.x + 0.5, pos.y - 1.5, pos.x + 0.5, pos.y + 2.5)
    end
end



return Node