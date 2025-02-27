local class = require "com.class"

---@class Image
---@overload fun(path):Image
local Image = class:derive("Image")

local Vec2 = require("Vector2")

---Creates a new Image.
---@param path string The path to the image to be used for this Image.
function Image:new(path)
    self.path = path
    self.image = love.graphics.newImage(path)
    self.size = Vec2(self.image:getWidth(), self.image:getHeight())
end

---Returns the string representation of this Image.
---@return string
function Image:__tostring()
    return "Image<" .. self.path .. ">"
end

---Returns the image size.
---@return Vector2
function Image:getSize()
    return self.size
end

---Draws this Image on the screen.
---@param pos Vector2 The position where this Image will be drawn.
---@param scale number? The scale of this Image. The final size will be unaffected.
function Image:draw(pos, scale)
    scale = scale or 1
    love.graphics.draw(self.image, pos.x, pos.y, 0, scale, scale)
end



return Image