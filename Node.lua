local class = require "com/class"

---@class Node
---@overload fun(data, parent):Node
local Node = class:derive("Node")

local Vec2 = require("Vector2")
local Box = require("Box")
local Text = require("Text")



---Creates a new UI Node.
---@param data table The node data.
---@param parent Node? The parent node.
function Node:new(data, parent)
    self.parent = parent

    self.pos = Vec2(data.pos)
    if data.type == "box" then
        self.widget = Box(data)
    elseif data.type == "text" then
        self.widget = Text(data)
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
    if self.parent then
        return self.parent:getGlobalPos() + self.pos
    end
    return self.pos
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
        self.widget:draw(self:getGlobalPos())
    end
    self:drawHitbox()
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
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("line", pos.x + 0.5, pos.y + 0.5, self.widget.size.x - 1, self.widget.size.y - 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.line(pos.x - 1.5, pos.y + 0.5, pos.x + 2.5, pos.y + 0.5)
        love.graphics.line(pos.x + 0.5, pos.y - 1.5, pos.x + 0.5, pos.y + 2.5)
    end
end



return Node