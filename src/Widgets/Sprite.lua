local class = require "com.class"

---@class Sprite
---@overload fun(node, data):Sprite
local Sprite = class:derive("Sprite")

local Vec2 = require("src.Essentials.Vector2")
local PropertyList = require("src.PropertyList")



---Creates a new Sprite.
---@param node Node The Node that this Sprite is attached to.
---@param data table? The data to be used for this Sprite.
function Sprite:new(node, data)
    self.node = node

    self.PROPERTY_LIST = {
        {name = "Image", key = "image", type = "Image", defaultValue = _RESOURCE_MANAGER:getImage("widget_canvas")},
        {name = "Hover Image", key = "hoverImage", type = "Image", nullable = true},
        {name = "Click Image", key = "clickImage", type = "Image", nullable = true},
        {name = "Disabled Image", key = "disabledImage", type = "Image", nullable = true},
        {name = "Scale", key = "scale", type = "number", defaultValue = 1, minValue = 1, scrollStep = 1},
        {name = "Alpha", key = "alpha", type = "number", defaultValue = 1, minValue = 0, maxValue = 1, scrollStep = 0.1},
        {name = "Shadow Offset", key = "shadowOffset", type = "Vector2", nullable = true},
        {name = "Shadow Alpha", key = "shadowAlpha", type = "number", defaultValue = 0.5, minValue = 0, maxValue = 1, scrollStep = 0.1}
    }
    self.properties = PropertyList(self.PROPERTY_LIST, data)
end



---Returns the given property of this Sprite.
---@param key string The property key.
---@return any?
function Sprite:getProp(key)
    return self.properties:getValue(key)
end



---Sets the given property of this Sprite to a given value.
---@param key string The property key.
---@param value any? The property value.
function Sprite:setProp(key, value)
    self.properties:setValue(key, value)
end



---Returns the given property base of this Sprite.
---@param key string The property key.
---@return any?
function Sprite:getPropBase(key)
    return self.properties:getBaseValue(key)
end



---Sets the given property base of this Sprite to a given value.
---@param key string The property key.
---@param value any? The property value.
function Sprite:setPropBase(key, value)
    self.properties:setBaseValue(key, value)
end



---Returns the size of this Sprite.
---@return Vector2
function Sprite:getSize()
    return self.node.scaleSize or self:getProp("image"):getSize()
end



---Sets the size of this Sprite. You cannot resize them, though!
---@param size Vector2 The new size of this Sprite.
function Sprite:setSize(size)
    error("Sprites cannot be resized!")
end



---Returns the property list of this Sprite.
---@return table
function Sprite:getPropertyList()
    return self.PROPERTY_LIST
end



---Updates the Sprite.
---@param dt number Time delta, in seconds.
function Sprite:update(dt)
    self.properties:update(dt)
end



---Draws the Sprite on the screen.
function Sprite:draw()
    local pos = self.node:getGlobalPos()
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
        image:draw(pos + prop.shadowOffset, prop.scale)
    end
    love.graphics.setColor(1, 1, 1, prop.alpha)
    image:draw(pos, prop.scale)
end



---Returns the Sprite's data to be used for loading later.
---@return table
function Sprite:serialize()
    return self.properties:serialize()
end



return Sprite