local class = require "com.class"

---@class Node
---@overload fun(data, parent):Node
local Node = class:derive("Node")

local Vec2 = require("Vector2")
local Box = require("Box")
local NineSprite = require("NineSprite")
local Text = require("Text")



---Creates a new UI Node.
---@param data table The node data.
---@param parent Node? The parent node.
function Node:new(data, parent)
    self.parent = parent

    self.name = data.name
    self.pos = Vec2(data.pos)
    if data.type == "box" then
        self.widget = Box(data)
    elseif data.type == "9sprite" then
        self.widget = NineSprite(data)
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