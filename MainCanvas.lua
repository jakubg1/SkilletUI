local class = require "com.class"

---@class MainCanvas
---@overload fun():MainCanvas
local MainCanvas = class:derive("MainCanvas")

local Vec2 = require("Vector2")



function MainCanvas:new()
    self.pos = _CANVAS_OFFSET_EDITOR
    self.size = _CANVAS_SIZE_EDITOR
    self.resolution = Vec2(320, 180)
    self.canvas = love.graphics.newCanvas(self.resolution.x, self.resolution.y)
end



function MainCanvas:posToPixel(pos)
    return ((pos - self.pos) / self.size * self.resolution):floor()
end



function MainCanvas:activate()
    love.graphics.setCanvas(self.canvas)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, self.resolution.x, self.resolution.y)
end



function MainCanvas:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setCanvas()
    love.graphics.draw(self.canvas, self.pos.x, self.pos.y, 0, self.size.x / self.resolution.x, self.size.y / self.resolution.y)
end



return MainCanvas