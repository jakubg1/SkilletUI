local class = require "com.class"

---@class NineSprite
---@overload fun(node, data):NineSprite
local NineSprite = class:derive("NineSprite")

local Vec2 = require("Vector2")



---Creates a new NineSprite.
---@param node Node The Node that this NineSprite is attached to.
---@param data table? The data to be used for this NineSprite.
function NineSprite:new(node, data)
    self.PROPERTY_LIST = {
        {name = "Image", key = "image", type = "Image"},
        {name = "Hover Image", key = "hoverImage", type = "Image", nullable = true},
        {name = "Click Image", key = "clickImage", type = "Image", nullable = true},
        {name = "Disabled Image", key = "disabledImage", type = "Image", nullable = true},
        {name = "Size", key = "size", type = "Vector2"},
        {name = "Scale", key = "scale", type = "number"},
        {name = "Alpha", key = "alpha", type = "number"},
        {name = "Shadow Offset", key = "shadowOffset", type = "Vector2", nullable = true},
        {name = "Shadow Alpha", key = "shadowAlpha", type = "number"}
    }
    data = data or {image = "ed_button"}

    self.node = node

    self.image = _IMAGES[data.image]
    self.hoverImage = data.hoverImage and _IMAGES[data.hoverImage]
    self.clickImage = data.clickImage and _IMAGES[data.clickImage]
    self.disabledImage = data.disabledImage and _IMAGES[data.disabledImage]
    self.size = data.size and Vec2(data.size) or Vec2(10)
    self.scale = data.scale or 1
    self.alpha = data.alpha or 1
    self.shadowOffset = data.shadowOffset and Vec2(data.shadowOffset)
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
        love.graphics.setColor(0, 0, 0, self.alpha * self.shadowAlpha)
        image:draw(pos + self.shadowOffset, self.size, self.scale)
    end
    love.graphics.setColor(1, 1, 1, self.alpha)
    image:draw(pos, self.size, self.scale)
end



---Returns the NineSprite's data to be used for loading later.
---@return table
function NineSprite:serialize()
    local data = {}

    data.image = _IMAGE_LOOKUP[self.image]
    data.hoverImage = self.hoverImage and _IMAGE_LOOKUP[self.hoverImage]
    data.clickImage = self.clickImage and _IMAGE_LOOKUP[self.clickImage]
    data.disabledImage = self.disabledImage and _IMAGE_LOOKUP[self.disabledImage]
    data.size = {self.size.x, self.size.y}
    data.scale = self.scale ~= 1 and self.scale or nil
    data.alpha = self.alpha ~= 1 and self.alpha or nil
    data.shadowOffset = self.shadowOffset and {self.shadowOffset.x, self.shadowOffset.y}
    data.shadowAlpha = self.shadowAlpha ~= 0.5 and self.shadowAlpha or nil

    return data
end



return NineSprite