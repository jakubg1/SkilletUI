local class = require "com.class"

---@class NineSprite
---@overload fun(data):NineSprite
local NineSprite = class:derive("NineSprite")

local Vec2 = require("Vector2")



---Creates a new NineSprite.
---@param data table The data to be used for this NineSprite.
function NineSprite:new(data)
    self.image = _IMAGES[data.image]
    self.size = Vec2(data.size)
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
---@param pos Vector2 The position where this NineSprite will be drawn.
---@param alpha number The opacity of this NineSprite.
function NineSprite:draw(pos, alpha)
    if self.shadowOffset then
        love.graphics.setColor(0, 0, 0, alpha * 0.5)
        self.image:draw(pos + self.shadowOffset, self.size)
    end
    love.graphics.setColor(1, 1, 1, alpha)
    self.image:draw(pos, self.size)
end



return NineSprite