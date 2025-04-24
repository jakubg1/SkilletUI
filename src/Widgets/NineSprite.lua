local class = require "com.class"

---@class NineSprite
---@overload fun(node, data):NineSprite
local NineSprite = class:derive("NineSprite")

local Vec2 = require("src.Essentials.Vector2")
local PropertyList = require("src.PropertyList")



---Creates a new NineSprite.
---@param node Node The Node that this NineSprite is attached to.
---@param data table? The data to be used for this NineSprite.
function NineSprite:new(node, data)
    self.node = node

    self.PROPERTY_LIST = {
        {name = "Image", key = "image", type = "NineImage", defaultValue = _RESOURCE_MANAGER:getNineImage("ed_button")},
        {name = "Hover Image", key = "hoverImage", type = "NineImage", nullable = true},
        {name = "Click Image", key = "clickImage", type = "NineImage", nullable = true},
        {name = "Disabled Image", key = "disabledImage", type = "NineImage", nullable = true},
        {name = "Size", key = "size", type = "Vector2", defaultValue = Vec2(10)},
        {name = "Scale", key = "scale", type = "number", defaultValue = 1, minValue = 1, scrollStep = 1},
        {name = "Alpha", key = "alpha", type = "number", defaultValue = 1, minValue = 0, maxValue = 1, scrollStep = 0.1},
        {name = "Shadow Offset", key = "shadowOffset", type = "Vector2", nullable = true},
        {name = "Shadow Alpha", key = "shadowAlpha", type = "number", defaultValue = 0.5, minValue = 0, maxValue = 1, scrollStep = 0.1}
    }
    self.properties = PropertyList(self.PROPERTY_LIST, data)
end



---Returns the given property of this NineSprite.
---@param key string The property key.
---@return any?
function NineSprite:getProp(key)
    return self.properties:getValue(key)
end



---Sets the given property of this NineSprite to a given value.
---@param key string The property key.
---@param value any? The property value.
function NineSprite:setProp(key, value)
    self.properties:setValue(key, value)
end



---Returns the given property base of this NineSprite.
---@param key string The property key.
---@return any?
function NineSprite:getPropBase(key)
    return self.properties:getBaseValue(key)
end



---Sets the given property base of this NineSprite to a given value.
---@param key string The property key.
---@param value any? The property value.
function NineSprite:setPropBase(key, value)
    self.properties:setBaseValue(key, value)
end



---Returns the size of this NineSprite.
---@return Vector2
function NineSprite:getSize()
    return self.node.scaleSize or self:getProp("size")
end



---Sets the size of this NineSprite.
---@param size Vector2 The new size of this NineSprite.
function NineSprite:setSize(size)
    self:setPropBase("size", size)
end



---Returns the property list of this NineSprite.
---@return table
function NineSprite:getPropertyList()
    return self.PROPERTY_LIST
end



---Updates the NineSprite.
---@param dt number Time delta, in seconds.
function NineSprite:update(dt)
    self.properties:update(dt)
end



---Draws the NineSprite on the screen.
function NineSprite:draw()
    local pos = self.node:getGlobalPos()
    local size = self:getSize()
    local prop = self.properties:getValues()
    local image = prop.image
    if self.node:isDisabled() then
        image = prop.disabledImage or image
    elseif self.node:isHovered() then
        image = prop.hoverImage or image
        if self.node.clicked then
            image = prop.clickImage or image
        end
    end
    if prop.shadowOffset then
        love.graphics.setColor(0, 0, 0, prop.alpha * prop.shadowAlpha)
        image:draw(pos + prop.shadowOffset, size, prop.scale)
    end
    love.graphics.setColor(1, 1, 1, prop.alpha)
    image:draw(pos, size, prop.scale)
end



---Returns the NineSprite's data to be used for loading later.
---@return table
function NineSprite:serialize()
    return self.properties:serialize()
end



return NineSprite