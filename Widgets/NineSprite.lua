local class = require "com.class"

---@class NineSprite
---@overload fun(node, data):NineSprite
local NineSprite = class:derive("NineSprite")

local Vec2 = require("Vector2")



---Creates a new NineSprite.
---@param node Node The Node that this NineSprite is attached to.
---@param data table The data to be used for this NineSprite.
function NineSprite:new(node, data)
    self.PROPERTY_LIST = {
        {name = "Image", key = "image", type = "Image"},
        {name = "Hover Image", key = "hoverImage", type = "Image"},
        {name = "Click Image", key = "clickImage", type = "Image"},
        {name = "Disabled Image", key = "disabledImage", type = "Image"},
        {name = "Scale", key = "scale", type = "number"},
        {name = "Shadow Offset", key = "shadowOffset", type = "Vector2"},
        {name = "Shadow Alpha", key = "shadowAlpha", type = "number"}
    }

    self.node = node

    self.image = _IMAGES[data.image]
    self.hoverImage = data.hoverImage and _IMAGES[data.hoverImage]
    self.clickImage = data.clickImage and _IMAGES[data.clickImage]
    self.disabledImage = data.disabledImage and _IMAGES[data.disabledImage]
    self.size = Vec2(data.size)
    self.scale = data.scale or 1
    self.shadowOffset = data.shadowOffset and (type(data.shadowOffset) == "number" and Vec2(data.shadowOffset) or Vec2(data.shadowOffset.x, data.shadowOffset.y))
    self.shadowAlpha = data.shadowAlpha or 0.5
end



---Returns the size of this NineSprite.
---@return Vector2
function NineSprite:getSize()
    return self.size
end



---Sets the size of this NineSprite.
---@param size Vector2 The new size of this NineSprite.
function NineSprite:setSize(size)
    self.size = size
end



---Returns whether this widget can be resized, i.e. squares will appear around that can be dragged.
---@return boolean
function NineSprite:isResizable()
    return true
end



---Returns the property list of this NineSprite.
---@return table
function NineSprite:getPropertyList()
    return self.PROPERTY_LIST
end



---Updates the NineSprite.
---@param dt number Time delta, in seconds.
function NineSprite:update(dt)
    -- no-op
end



---Draws the NineSprite on the screen.
function NineSprite:draw()
    local pos = self.node:getGlobalPos()
    local image = self.image
    if self.node:isDisabled() then
        image = self.disabledImage or image
    elseif self.node:isHovered() then
        image = self.hoverImage or image
        if self.node.clicked then
            image = self.clickImage or image
        end
    end
    if self.shadowOffset then
        love.graphics.setColor(0, 0, 0, self.node.alpha * self.shadowAlpha)
        image:draw(pos + self.shadowOffset, self.size, self.scale)
    end
    love.graphics.setColor(1, 1, 1, self.node.alpha)
    image:draw(pos, self.size, self.scale)
end



return NineSprite