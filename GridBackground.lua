local class = require "com/class"

---@class GridBackground
---@overload fun():GridBackground
local GridBackground = class:derive("GridBackground")

local Color = require("Color")
local Vec2 = require("Vector2")



function GridBackground:new()
    self.TILE_SIZE = 12
    self.GRID_SIZE = 1
    self.WIDTH = 320
    self.HEIGHT = 180

    self.BASE_X = 10000 * love.math.random()
    self.BASE_Y = 10000 * love.math.random()
    self.BASE_COLOR_X = 10000 * love.math.random() + 10000
    self.BASE_COLOR_Y = 10000 * love.math.random() + 10000
    self.MOVE_ROT_BASE = -10000 * love.math.random() - 10000
    self.ROT_BASE = -10000 * love.math.random()

    self.CELL_COLOR = Color(0, 0, 0.8)
    self.INFLATED_CELL_COLOR = Color(0.1, 0.5, 1)
    self.ALT_CELL_COLOR = Color(0.8, 0.4, 0)
    self.INFLATED_ALT_CELL_COLOR = Color(1, 0.6, 0.3)

    self.GRID_COLOR = Color(0.1, 0.1, 0.3)
    self.ALT_GRID_COLOR = Color(0.45, 0.3, 0.2)

    self.moveX = 0
    self.moveY = 0
    self.moveRot = 0
    self.speedMoveRot = 0
    self.speedRot = 0
    self.rot = 0
    self.time = 0
end



function GridBackground:transformPoint(x, y)
	x, y = x + self.moveX * self.TILE_SIZE, y + self.moveY * self.TILE_SIZE
	x, y = x * math.cos(self.rot) - y * math.sin(self.rot), x * math.sin(self.rot) + y * math.cos(self.rot)
	return x + self.WIDTH / 2, y + self.HEIGHT / 2
end



function GridBackground:drawRect(x, y, w, h)
	local x1, y1 = self:transformPoint(x - w / 2, y - h / 2)
	local x2, y2 = self:transformPoint(x + w / 2, y - h / 2)
	local x3, y3 = self:transformPoint(x + w / 2, y + h / 2)
	local x4, y4 = self:transformPoint(x - w / 2, y + h / 2)
	love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
end



function GridBackground:drawCell(x, y)
	local v = love.math.noise(self.BASE_X + x * 0.06 + self.time * 0.4, self.BASE_Y + y * 0.13 + self.time * 0.4)
	local c = math.min(math.max(love.math.noise(self.BASE_COLOR_X + x * 0.04 - self.time * 0.2, self.BASE_COLOR_Y + y * 0.04 + self.time * 0.2) * 1.4 - 0.2, 0), 1)

	local size = (self.TILE_SIZE - self.GRID_SIZE) * (0.1 + 0.9 * v)
    local color = _Utils.interpolate(_Utils.interpolate(self.CELL_COLOR, self.INFLATED_CELL_COLOR, v), _Utils.interpolate(self.ALT_CELL_COLOR, self.INFLATED_ALT_CELL_COLOR, v), c)
	love.graphics.setColor(color.r, color.g, color.b)
	self:drawRect((x + 0.5) * self.TILE_SIZE, (y + 0.5) * self.TILE_SIZE, size, size)

    local gridColor = _Utils.interpolate(self.GRID_COLOR, self.ALT_GRID_COLOR, c)
	love.graphics.setColor(gridColor.r, gridColor.g, gridColor.b)
	self:drawRect((x + 0.5) * self.TILE_SIZE, y * self.TILE_SIZE, self.TILE_SIZE + self.GRID_SIZE, self.GRID_SIZE)
	self:drawRect(x * self.TILE_SIZE, (y + 0.5) * self.TILE_SIZE, self.GRID_SIZE, self.TILE_SIZE + self.GRID_SIZE)
end



function GridBackground:update(dt)
	self.time = self.time + dt
	self.speedMoveRot = self.speedMoveRot * 0.6 + ((love.math.noise(self.MOVE_ROT_BASE + self.time * 0.05) - 0.5) * 0.015) * 0.4
	self.speedRot = self.speedRot * 0.6 + ((love.math.noise(self.ROT_BASE + self.time * 0.035) - 0.5) * 0.005) * 0.4
    self.moveRot = self.moveRot + self.speedMoveRot
    self.moveX = self.moveX + 0.025 * (math.cos(self.moveRot) - math.sin(self.moveRot))
    self.moveY = self.moveY + 0.025 * (math.sin(self.moveRot) + math.cos(self.moveRot))
	self.rot = self.rot + self.speedRot
end



function GridBackground:draw()
    love.graphics.setColor(0.05, 0.05, 0.15)
    love.graphics.rectangle("fill", 0, 0, self.WIDTH, self.HEIGHT)
	local x0, y0 = math.floor(-self.moveX + 0.5), math.floor(-self.moveY + 0.5)
	local range = math.sqrt(self.WIDTH * self.WIDTH + self.HEIGHT * self.HEIGHT) / self.TILE_SIZE / 2 + 1
	for x = x0 - range, x0 + range do
		for y = y0 - range, y0 + range do
			self:drawCell(x, y)
		end
	end
end



return GridBackground