local class = require "com.class"

---@class MainCanvas
---@overload fun():MainCanvas
local MainCanvas = class:derive("MainCanvas")

local Vec2 = require("src.Essentials.Vector2")

---Constructs a new Canvas. This Canvas is the project canvas and can have different sizes, positions and resolutions throughout its lifetime.
function MainCanvas:new()
    self.pos = Vec2()
    self.size = _WINDOW_SIZE
    self.resolution = Vec2(320, 180)
    self.scale = 1
    self.pan = Vec2()
    self.canvas = love.graphics.newCanvas(self.resolution.x, self.resolution.y)
    self.canvas:setFilter("linear", "nearest")
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
    self.canvas:setFilter("linear", "nearest")
end

---Sets the zoom factor of this Canvas. The zoom origin is in the top left corner.
---@param zoom number The new zoom factor.
function MainCanvas:setZoom(zoom)
    self.scale = zoom
end

---Pans the zoomed in canvas to the specific position (relative to the top left position of the viewport).
---@param pan Vector2 The new pan value.
function MainCanvas:setPan(pan)
    self.pan = pan
end

---Sets the zoom factor of this Canvas so that the total scaling factor matches the provided value. The zoom origin is in the top left corner.
---@param scale number The desired scale.
function MainCanvas:setScale(scale)
    self.scale = scale
end

---Returns the global position on which this Canvas will be drawn.
---@return Vector2
function MainCanvas:getGlobalPos()
    return self.pos - self.pan * self.scale
end

---Returns the global size with which this Canvas will be drawn.
---@return Vector2
function MainCanvas:getGlobalSize()
    return self.resolution * self.scale
end

---Converts the global screen position to the position on this canvas.
---@param pos Vector2 The global screen position.
---@return Vector2
function MainCanvas:posToPixel(pos)
    return ((pos - self.pos) / self.scale + self.pan):floor()
end

---Converts the pixel on this canvas to its global screen position.
---@param pixel Vector2 The pixel positon on this canvas.
---@return Vector2
function MainCanvas:pixelToPos(pixel)
    return ((pixel - self.pan) * self.scale + self.pos):floor()
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
    love.graphics.setScissor(self.pos.x, self.pos.y, self.size.x, self.size.y)
    local pos = self:getGlobalPos()
    love.graphics.draw(self.canvas, pos.x, pos.y, 0, self.scale)
    love.graphics.setScissor()
end

return MainCanvas