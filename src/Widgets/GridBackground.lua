local class = require "com.class"

---@class GridBackground
---@overload fun(node, data):GridBackground
local GridBackground = class:derive("GridBackground")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")
local PropertyList = require("src.PropertyList")



---A hardcoded background which was supposed to be in the title screen.
---@param node Node The Node that this background is attached to.
---@param data table? The data to be used for this Grid Background.
function GridBackground:new(node, data)
    self.node = node

    self.PROPERTY_LIST = {}
    self.properties = PropertyList(self.PROPERTY_LIST, data)

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



---Returns the given property of this GridBackground.
---@param key string The property key.
---@return any?
function GridBackground:getProp(key)
    return self.properties:getValue(key)
end



---Sets the given property of this GridBackground to a given value.
---@param key string The property key.
---@param value any? The property value.
function GridBackground:setProp(key, value)
    self.properties:setValue(key, value)
end



---Returns the given property base of this GridBackground.
---@param key string The property key.
---@return any?
function GridBackground:getPropBase(key)
    return self.properties:getBaseValue(key)
end



---Sets the given property base of this GridBackground to a given value.
---@param key string The property key.
---@param value any? The property value.
function GridBackground:setPropBase(key, value)
    self.properties:setBaseValue(key, value)
end



---Transforms a point to match the current background position and rotation.
---@param x number The X coordinate of the point to be transformed.
---@param y number The Y coordinate of the point to be transformed.
---@return number
---@return number
function GridBackground:transformPoint(x, y)
	x, y = x + self.moveX * self.TILE_SIZE, y + self.moveY * self.TILE_SIZE
	x, y = x * math.cos(self.rot) - y * math.sin(self.rot), x * math.sin(self.rot) + y * math.cos(self.rot)
	return x + self.WIDTH / 2, y + self.HEIGHT / 2
end



---Draws a single transformed rectangle on the screen.
---@param x number The X coordinate of the rectangle center before transformation.
---@param y number The Y coordinate of the rectangle center before transformation.
---@param w number The width of the rectangle in pixels.
---@param h number The height of the rectangle in pixels.
function GridBackground:drawRect(x, y, w, h)
	local x1, y1 = self:transformPoint(x - w / 2, y - h / 2)
	local x2, y2 = self:transformPoint(x + w / 2, y - h / 2)
	local x3, y3 = self:transformPoint(x + w / 2, y + h / 2)
	local x4, y4 = self:transformPoint(x - w / 2, y + h / 2)
	love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
end



---Draws a single background cell on the screen.
---This includes both the cell and the grid. This function also calculates the colors and sizes.
---@param x number The X coordinate of the cell.
---@param y number The Y coordinate of the cell.
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



---Returns the size of this Grid Background.
---@return Vector2
function GridBackground:getSize()
    return Vec2(self.WIDTH, self.HEIGHT)
end



---Sets the size of this GridBackground. But you actually cannot set it. Don't even try :)
---@param size Vector2 The new size of this GridBackground.
function GridBackground:setSize(size)
    error("GridBackgrounds cannot be resized!")
end



---Updates the Grid Background.
---@param dt number Time delta, in seconds.
function GridBackground:update(dt)
    self.properties:update(dt)

	self.time = self.time + dt
	self.speedMoveRot = self.speedMoveRot * 0.6 + ((love.math.noise(self.MOVE_ROT_BASE + self.time * 0.05) - 0.5) * 0.015) * 0.4
	self.speedRot = self.speedRot * 0.6 + ((love.math.noise(self.ROT_BASE + self.time * 0.035) - 0.5) * 0.005) * 0.4
    self.moveRot = self.moveRot + self.speedMoveRot
    self.moveX = self.moveX + 0.025 * (math.cos(self.moveRot) - math.sin(self.moveRot))
    self.moveY = self.moveY + 0.025 * (math.sin(self.moveRot) + math.cos(self.moveRot))
	self.rot = self.rot + self.speedRot
end



---Draws the Grid Background.
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



---Returns the GridBackground's data to be used for loading later.
---@return table
function GridBackground:serialize()
    return self.properties:serialize()
end



return GridBackground
