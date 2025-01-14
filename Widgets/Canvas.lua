local class = require "com.class"

---@class Canvas
---@overload fun(node, data):Canvas
local Canvas = class:derive("Canvas")

local Vec2 = require("Vector2")
local PropertyList = require("PropertyList")



---Creates a new Canvas.
---Canvases are deprecated and will crash the engine if loaded.
---Might be removed or updated, I don't know yet.
---@param node Node The Node that this Canvas is attached to.
---@param data table? The data to be used for this Canvas.
function Canvas:new(node, data)
    self.node = node

    self.PROPERTY_LIST = {
        {name = "Size", key = "size", type = "Vector2", defaultValue = Vec2(40)},
        {name = "Canvas Size", key = "canvasSize", type = "Vector2", defaultValue = Vec2(10)}
    }
    self.properties = PropertyList(self.PROPERTY_LIST, data)

    local canvasSize = self:getProp("canvasSize")
    self.canvas = love.graphics.newCanvas(canvasSize.x, canvasSize.y)
end



---Returns the given property of this Canvas.
---@param key string The property key.
---@return any?
function Canvas:getProp(key)
    return self.properties:getValue(key)
end



---Sets the given property of this Canvas to a given value.
---@param key string The property key.
---@param value any? The property value.
function Canvas:setProp(key, value)
    self.properties:setValue(key, value)
end



---Returns the given property base of this Canvas.
---@param key string The property key.
---@return any?
function Canvas:getPropBase(key)
    return self.properties:getBaseValue(key)
end



---Sets the given property base of this Canvas to a given value.
---@param key string The property key.
---@param value any? The property value.
function Canvas:setPropBase(key, value)
    self.properties:setBaseValue(key, value)
end



---Returns the size of this Canvas.
---@return Vector2
function Canvas:getSize()
    return self:getProp("size")
end



---Sets the size of this Canvas.
---@param size Vector2 The new size of this Canvas.
function Canvas:setSize(size)
    self:setProp("size", size)
end



---Activates this Canvas for drawing. The canvas is automatically cleared.
function Canvas:activate()
    local canvasSize = self:getProp("canvasSize")
    love.graphics.setCanvas(self.canvas)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, canvasSize.x, canvasSize.y)
end



---Updates the Canvas.
---@param dt number Time delta, in seconds.
function Canvas:update(dt)
    -- no-op
end



---Draws the Canvas on the screen.
function Canvas:draw()
    local pos = self.node:getGlobalPos()
    local size = self:getProp("size")
    local canvasSize = self:getProp("canvasSize")
    love.graphics.setColor(1, 1, 1)
    love.graphics.setCanvas()
    love.graphics.draw(self.canvas, pos.x, pos.y, 0, size.x / canvasSize.x, size.y / canvasSize.y)
end



---Returns the Canvas's data to be used for loading later.
---@return table
function Canvas:serialize()
    return self.properties:serialize()
end



return Canvas