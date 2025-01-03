local class = require "com.class"

---@class Image
---@overload fun(image):Image
local Image = class:derive("Image")



---Creates a new Image.
---@param image love.Texture The image to be used for this Image.
function Image:new(image)
    self.image = image
end



---Draws this Image on the screen.
---@param pos Vector2 The position where this Image will be drawn.
---@param scale number? The scale of this Image. The final size will be unaffected.
function Image:draw(pos, scale)
    scale = scale or 1
    love.graphics.draw(self.image, pos.x, pos.y, 0, scale, scale)
end



return Image