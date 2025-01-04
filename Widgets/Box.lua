local class = require "com.class"

---@class Box
---@overload fun(node, data):Box
local Box = class:derive("Box")

local Vec2 = require("Vector2")
local Color = require("Color")



---Creates a new Box.
---@param node Node The Node that this Box is attached to.
---@param data table The data to be used for this Box.
function Box:new(node, data)
    self.PROPERTY_LIST = {
        {name = "Size", key = "size", type = "Vector2"},
        {name = "Color", key = "color", type = "color"}
    }

    self.node = node

    self.size = Vec2(data.size)
    self.color = Color(data.color)
end



---Returns the size of this Box.
---@return Vector2
function Box:getSize()
    return self.size
end



---Sets the size of this Box.
---@param size Vector2 The new size of this Box.
function Box:setSize(size)
    self.size = size
end



---Returns whether this widget can be resized, i.e. squares will appear around that can be dragged.
---@return boolean
function Box:isResizable()
    return true
end



---Returns the property list of this Box.
---@return table
function Box:getPropertyList()
    return self.PROPERTY_LIST
end



---Updates the Box.
---@param dt number Time delta, in seconds.
function Box:update(dt)
    -- no-op
end



---Draws the Box on the screen.
function Box:draw()
    local pos = self.node:getGlobalPos()
    love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.node.alpha)
    love.graphics.rectangle("fill", pos.x + 0.5, pos.y + 0.5, self.size.x, self.size.y)
end



---Returns the Box's data to be used for loading later.
---@return table
function Box:serialize()
    local data = {}

    data.size = {x = self.size.x, y = self.size.y}
    data.color = {r = self.color.r, g = self.color.g, b = self.color.b}

    return data
end



return Box