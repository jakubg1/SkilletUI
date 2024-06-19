local class = require "com.class"

---@class NineSprite
---@overload fun(node, data):NineSprite
local NineSprite = class:derive("NineSprite")

local Vec2 = require("Vector2")



---Creates a new NineSprite.
---@param node Node The Node that this NineSprite is attached to.
---@param data table The data to be used for this NineSprite.
function NineSprite:new(node, data)
    self.node = node

    self.image = _IMAGES[data.image]
    self.hoverImage = data.hoverImage and _IMAGES[data.hoverImage]
    self.clickImage = data.clickImage and _IMAGES[data.clickImage]
    self.size = Vec2(data.size)
    self.scale = data.scale or 1
    self.shadowOffset = data.shadow and (type(data.shadow) == "number" and Vec2(data.shadow) or Vec2(1))
end



---Returns the size of this NineSprite.
---@return Vector2
function NineSprite:getSize()
    return self.size
end



---Updates the NineSprite.
---@param dt number Time delta, in seconds.
function NineSprite:update(dt)
    -- no-op
end



---Draws the NineSprite on the screen.
function NineSprite:draw()
    local pos = self.node:getGlobalPos()
    local image = self.node:isHovered() and (self.node.clicked and self.clickImage or self.hoverImage) or self.image
    if self.shadowOffset then
        love.graphics.setColor(0, 0, 0, self.node.alpha * 0.5)
        image:draw(pos + self.shadowOffset, self.size, self.scale)
    end
    love.graphics.setColor(1, 1, 1, self.node.alpha)
    image:draw(pos, self.size, self.scale)
end



return NineSprite