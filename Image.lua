local class = require "com.class"

---@class Image
---@overload fun(path):Image
local Image = class:derive("Image")



---Creates a new Image.
---@param path string The path to the image to be used for this Image.
function Image:new(path)
    self.path = path
    self.image = love.graphics.newImage(path)
end



---Draws this Image on the screen.
---@param pos Vector2 The position where this Image will be drawn.
---@param scale number? The scale of this Image. The final size will be unaffected.
function Image:draw(pos, scale)
    scale = scale or 1
    love.graphics.draw(self.image, pos.x, pos.y, 0, scale, scale)
end



return Image