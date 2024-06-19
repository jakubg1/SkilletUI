local class = require "com.class"

---@class Canvas
---@overload fun(node, data):Canvas
local Canvas = class:derive("Canvas")

local Vec2 = require("Vector2")



---Creates a new Canvas.
---@param node Node The Node that this Canvas is attached to.
---@param data table The data to be used for this Canvas.
function Canvas:new(node, data)
    self.node = node

    self.size = Vec2(data.size)
    self.canvasSize = Vec2(data.canvasSize)

    self.canvas = love.graphics.newCanvas(self.canvasSize.x, self.canvasSize.y)
end



---Returns the size of this Canvas.
---@return Vector2
function Canvas:getSize()
    return self.size
end



---Activates this Canvas for drawing. The canvas is automatically cleared.
function Canvas:activate()
    love.graphics.setCanvas(self.canvas)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, self.canvasSize.x, self.canvasSize.y)
end



---Updates the Canvas.
---@param dt number Time delta, in seconds.
function Canvas:update(dt)
    -- no-op
end



---Draws the Canvas on the screen.
function Canvas:draw()
    local pos = self.node:getGlobalPos()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setCanvas()
    love.graphics.draw(self.canvas, pos.x, pos.y, 0, self.size.x / self.canvasSize.x, self.size.y / self.canvasSize.y)
end



return Canvas