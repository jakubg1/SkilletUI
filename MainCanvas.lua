local class = require "com.class"

---@class MainCanvas
---@overload fun():MainCanvas
local MainCanvas = class:derive("MainCanvas")

local Vec2 = require("Vector2")

---Constructs a new Canvas. This Canvas is the project canvas and can have different sizes, positions and resolutions throughout its lifetime.
function MainCanvas:new()
    self.pos = _CANVAS_OFFSET_EDITOR
    self.size = _CANVAS_SIZE_EDITOR
    self.resolution = Vec2(320, 180)
    self.canvas = love.graphics.newCanvas(self.resolution.x, self.resolution.y)
end

---Sets a new top left corner position of this Canvas on the screen.
---@param pos Vector2 The new screen position.
function MainCanvas:setPos(pos)
    self.pos = pos
end

---Sets a new size for this Canvas on the screen.
---@param size Vector2 The new screen size.
function MainCanvas:setSize(size)
    self.size = size
end

---Sets a new resolution for this Canvas. This also clears its contents.
---@param resolution Vector2 The new canvas resolution.
function MainCanvas:setResolution(resolution)
    self.resolution = resolution
    self.canvas = love.graphics.newCanvas(resolution.x, resolution.y)
end

---Converts the global screen position to the position on this canvas.
---@param pos Vector2 The global screen position.
---@return Vector2
function MainCanvas:posToPixel(pos)
    return ((pos - self.pos) / self.size * self.resolution):floor()
end

---Converts the pixel on this canvas to its global screen position.
---@param pixel Vector2 The pixel positon on this canvas.
---@return Vector2
function MainCanvas:pixelToPos(pixel)
    return (pixel * self.size / self.resolution + self.pos):floor()
end

---Transfers pixel and size from the canvas into the corresponding values on the screen.
---@param pixel Vector2 The position of the top left corner of the box.
---@param size Vector2 The size of the box.
---@return Vector2
---@return Vector2
function MainCanvas:pixelToPosBox(pixel, size)
    local p1 = self:pixelToPos(pixel)
    local p2 = self:pixelToPos(pixel + size)
    return p1, p2 - p1
end

---Activates this Canvas for drawing. Everything onwards will be drawn on this Canvas, until `:draw()` is called.
function MainCanvas:activate()
    love.graphics.setCanvas(self.canvas)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, self.resolution.x, self.resolution.y)
end

---Draws this Canvas on the screen. This also deactivates this Canvas.
function MainCanvas:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setCanvas()
    love.graphics.draw(self.canvas, self.pos.x, self.pos.y, 0, self.size.x / self.resolution.x, self.size.y / self.resolution.y)
end

return MainCanvas