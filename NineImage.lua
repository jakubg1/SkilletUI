local class = require "com.class"

---@class NineImage
---@overload fun(path, x1, x2, y1, y2):NineImage
local NineImage = class:derive("NineImage")



---Creates a new NineImage.
---@param path string The path to the image to be used as a base for this NineImage.
---@param x1 number The first vertical bar position, in pixels.
---@param x2 number The second vertical bar position, in pixels.
---@param y1 number The first horizontal bar position, in pixels.
---@param y2 number The second horizontal bar position, in pixels.
function NineImage:new(path, x1, x2, y1, y2)
    self.path = path
    self.image = love.graphics.newImage(path)
    self.x1 = x1
    self.x2 = x2
    self.y1 = y1
    self.y2 = y2

    -- Size of center piece
    self.cx = x2 - x1
    self.cy = y2 - y1
    -- Size of bottom right piece
    self.brx = self.image:getWidth() - x2
    self.bry = self.image:getHeight() - y2

    self.pieces = {
        top_left = love.graphics.newQuad(0, 0, x1, y1, self.image),
        top = love.graphics.newQuad(x1, 0, self.cx, y1, self.image),
        top_right = love.graphics.newQuad(x2, 0, self.brx, y1, self.image),
        left = love.graphics.newQuad(0, y1, x1, self.cy, self.image),
        center = love.graphics.newQuad(x1, y1, self.cx, self.cy, self.image),
        right = love.graphics.newQuad(x2, y1, self.brx, self.cy, self.image),
        bottom_left = love.graphics.newQuad(0, y2, x1, self.bry, self.image),
        bottom = love.graphics.newQuad(x1, y2, self.cx, self.bry, self.image),
        bottom_right = love.graphics.newQuad(x2, y2, self.brx, self.bry, self.image)
    }
end



---Returns the string representation of this NineImage.
---@return string
function NineImage:__tostring()
    return "NineImage<" .. self.path .. ">"
end



---Draws this NineImage on the screen.
---@param pos Vector2 The position where this NineImage will be drawn.
---@param size Vector2 The size of this NineImage.
---@param scale number? The scale of this NineImage. The final size will be unaffected.
function NineImage:draw(pos, size, scale)
    scale = scale or 1
    local x1 = pos.x + self.x1 * scale
    local x2 = pos.x + size.x - self.brx * scale
    local y1 = pos.y + self.y1 * scale
    local y2 = pos.y + size.y - self.bry * scale
    local centerStretchFactorX = (size.x - (self.x1 + self.brx) * scale) / self.cx
    local centerStretchFactorY = (size.y - (self.y1 + self.bry) * scale) / self.cy
    love.graphics.draw(self.image, self.pieces.top_left, pos.x, pos.y, 0, scale, scale)
    love.graphics.draw(self.image, self.pieces.top, x1, pos.y, 0, centerStretchFactorX, scale)
    love.graphics.draw(self.image, self.pieces.top_right, x2, pos.y, 0, scale, scale)
    love.graphics.draw(self.image, self.pieces.left, pos.x, y1, 0, scale, centerStretchFactorY)
    love.graphics.draw(self.image, self.pieces.center, x1, y1, 0, centerStretchFactorX, centerStretchFactorY)
    love.graphics.draw(self.image, self.pieces.right, x2, y1, 0, scale, centerStretchFactorY)
    love.graphics.draw(self.image, self.pieces.bottom_left, pos.x, y2, 0, scale, scale)
    love.graphics.draw(self.image, self.pieces.bottom, x1, y2, 0, centerStretchFactorX, scale)
    love.graphics.draw(self.image, self.pieces.bottom_right, x2, y2, 0, scale, scale)
end



return NineImage