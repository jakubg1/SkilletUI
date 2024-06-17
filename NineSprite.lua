local class = require "com.class"

---@class NineSprite
---@overload fun(data):NineSprite
local NineSprite = class:derive("NineSprite")

local Vec2 = require("Vector2")
local Color = require("Color")



---Creates a new NineSprite.
---@param data table The data to be used for this NineSprite.
function NineSprite:new(data)
    self.image = _IMAGES[data.image]
    self.size = Vec2(data.size)
end



---Updates the NineSprite.
---@param dt number Time delta, in seconds.
function NineSprite:update(dt)
    -- no-op
end



---Draws the NineSprite on the screen.
---@param pos Vector2 The position where this NineSprite will be drawn.
function NineSprite:draw(pos)
    love.graphics.setColor(1, 1, 1)
    self.image:draw(pos, self.size)
end



return NineSprite