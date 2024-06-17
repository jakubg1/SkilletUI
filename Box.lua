local class = require "com.class"

---@class Box
---@overload fun(data):Box
local Box = class:derive("Box")

local Vec2 = require("Vector2")
local Color = require("Color")



---Creates a new Box.
---@param data table The data to be used for this Box.
function Box:new(data)
    self.size = Vec2(data.size)
    self.color = Color(data.color)
end



---Returns the size of this Box.
---@return Vector2
function Box:getSize()
    return self.size
end



---Updates the Box.
---@param dt number Time delta, in seconds.
function Box:update(dt)
    -- no-op
end



---Draws the Box on the screen.
---@param pos Vector2 The position where this Box will be drawn.
---@param alpha number The opacity of this Box.
function Box:draw(pos, alpha)
    love.graphics.setColor(self.color.r, self.color.g, self.color.b, alpha)
    love.graphics.rectangle("fill", pos.x + 0.5, pos.y + 0.5, self.size.x, self.size.y)
end



return Box