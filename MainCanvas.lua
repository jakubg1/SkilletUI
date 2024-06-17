local class = require "com.class"

---@class MainCanvas
---@overload fun():MainCanvas
local MainCanvas = class:derive("MainCanvas")

local Vec2 = require("Vector2")



function MainCanvas:new()
    self.SIZE = Vec2(320, 180)
    self.canvas = love.graphics.newCanvas(self.SIZE.x, self.SIZE.y)
end



function MainCanvas:activate()
    love.graphics.setCanvas(self.canvas)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, self.SIZE.x, self.SIZE.y)
end



function MainCanvas:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setCanvas()
    love.graphics.draw(self.canvas, 0, 0, 0, _WINDOW_SIZE.x / self.SIZE.x, _WINDOW_SIZE.y / self.SIZE.y)
end



return MainCanvas