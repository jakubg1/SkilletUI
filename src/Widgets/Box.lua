local class = require "com.class"

---@class Box
---@overload fun(node, data):Box
local Box = class:derive("Box")

local Vec2 = require("src.Essentials.Vector2")
local PropertyList = require("src.PropertyList")



---Creates a new Box.
---@param node Node The Node that this Box is attached to.
---@param data table? The data to be used for this Box.
function Box:new(node, data)
    self.node = node

    self.PROPERTY_LIST = {
        {name = "Size", key = "size", type = "Vector2", description = "Size of this box in pixels.", defaultValue = Vec2(10)},
        {name = "Color", key = "color", type = "color", description = "The color of this box.", nullable = true, defaultValueNoData = _COLORS.white},
        {name = "Alpha", key = "alpha", type = "number", description = "Opacity of this box.\n1 = fully opaque, 0 = fully transparent.", defaultValue = 1, minValue = 0, maxValue = 1, scrollStep = 0.1},
        {name = "Border Color", key = "borderColor", type = "color", description = "The color of this box border.", nullable = true},
        {name = "Border Alpha", key = "borderAlpha", type = "number", description = "Opacity of this box border.\n1 = fully opaque, 0 = fully transparent.", defaultValue = 1, minValue = 0, maxValue = 1, scrollStep = 0.1}
    }
    self.properties = PropertyList(self.PROPERTY_LIST, data)
end



---Returns the given property of this Box.
---@param key string The property key.
---@return any?
function Box:getProp(key)
    return self.properties:getValue(key)
end



---Sets the given property of this Box to a given value.
---@param key string The property key.
---@param value any? The property value.
function Box:setProp(key, value)
    self.properties:setValue(key, value)
end



---Returns the given property base of this Box.
---@param key string The property key.
---@return any?
function Box:getPropBase(key)
    return self.properties:getBaseValue(key)
end



---Sets the given property base of this Box to a given value.
---@param key string The property key.
---@param value any? The property value.
function Box:setPropBase(key, value)
    self.properties:setBaseValue(key, value)
end



---Returns the size of this Box.
---@return Vector2
function Box:getSize()
    return self.node.scaleSize or self:getProp("size")
end



---Sets the size of this Box.
---@param size Vector2 The new size of this Box.
function Box:setSize(size)
    self:setPropBase("size", size)
end



---Returns the property list of this Box.
---@return table
function Box:getPropertyList()
    return self.PROPERTY_LIST
end



---Updates the Box.
---@param dt number Time delta, in seconds.
function Box:update(dt)
    self.properties:update(dt)
end



---Draws the Box on the screen.
function Box:draw()
    local pos = self.node:getGlobalPos()
    local prop = self.properties:getValues()
    local size = self:getSize()
    if prop.color then
        love.graphics.setColor(prop.color.r, prop.color.g, prop.color.b, prop.alpha)
        love.graphics.rectangle("fill", pos.x + 0.5, pos.y + 0.5, size.x, size.y)
    end
    if prop.borderColor then
        love.graphics.setColor(prop.borderColor.r, prop.borderColor.g, prop.borderColor.b, prop.borderAlpha)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", pos.x + 0.5, pos.y + 0.5, size.x - 0.5, size.y - 0.5)
    end
end



---Returns the Box's data to be used for loading later.
---@return table
function Box:serialize()
    return self.properties:serialize()
end



return Box