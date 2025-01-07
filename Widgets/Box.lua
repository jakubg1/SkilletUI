local class = require "com.class"

---@class Box
---@overload fun(node, data):Box
local Box = class:derive("Box")

local Vec2 = require("Vector2")
local Color = require("Color")



---Creates a new Box.
---@param node Node The Node that this Box is attached to.
---@param data table? The data to be used for this Box.
function Box:new(node, data)
    self.PROPERTY_LIST = {
        {name = "Size", key = "size", type = "Vector2"},
        {name = "Color", key = "color", type = "color", nullable = true},
        {name = "Alpha", key = "alpha", type = "number"},
        {name = "Border Color", key = "borderColor", type = "color", nullable = true},
        {name = "Border Alpha", key = "borderAlpha", type = "number"}
    }
    data = data or {color = _COLORS.white}

    self.node = node

    self.size = data.size and Vec2(data.size) or Vec2(10)
    self.color = data.color and Color(data.color)
    self.alpha = data.alpha or 1
    self.borderColor = data.borderColor and Color(data.borderColor)
    self.borderAlpha = data.borderAlpha or 1
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
    if self.color then
        love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.alpha)
        love.graphics.rectangle("fill", pos.x + 0.5, pos.y + 0.5, self.size.x, self.size.y)
    end
    if self.borderColor then
        love.graphics.setColor(self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderAlpha)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", pos.x + 0.5, pos.y + 0.5, self.size.x - 0.5, self.size.y - 0.5)
    end
end



---Returns the Box's data to be used for loading later.
---@return table
function Box:serialize()
    local data = {}

    data.size = {x = self.size.x, y = self.size.y}
    data.color = self.color and {r = self.color.r, g = self.color.g, b = self.color.b}
    data.alpha = self.alpha
    data.borderColor = self.borderColor and {r = self.borderColor.r, g = self.borderColor.g, b = self.borderColor.b}
    data.borderAlpha = self.borderAlpha

    return data
end



return Box