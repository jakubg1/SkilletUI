local class = require "com.class"

---@class TitleDigit
---@overload fun(node, data):TitleDigit
local TitleDigit = class:derive("TitleDigit")

-- Place your imports here
local Vec2 = require("Vector2")
local Color = require("Color")
local PropertyList = require("PropertyList")



---A hardcoded rotating "2" in the title screen.
---@param node Node The Node that this digit is attached to.
---@param data table? The data to be used for this Title Digit.
function TitleDigit:new(node, data)
    self.node = node

    self.PROPERTY_LIST = {
        {name = "Alpha", key = "alpha", type = "number", defaultValue = 1},
        {name = "Shadow Offset", key = "shadowOffset", type = "Vector2", nullable = true}
    }
    self.properties = PropertyList(self.PROPERTY_LIST, data)

    self.SIZE = Vec2(6, 7)
    self.MAIN_COLOR = Color(1, 0.8, 0)
    self.SECONDARY_COLOR = Color(0.5, 0.2, 0)
    self.TERNARY_COLOR = Color(0.7, 0.4, 0)
    self.SHADOW_COLOR = Color(0, 0, 0)
    self.CUBE_POSITIONS = {
                    Vec2(1, 0), Vec2(2, 0), Vec2(3, 0), Vec2(4, 0),
        Vec2(0, 1), Vec2(1, 1),                         Vec2(4, 1), Vec2(5, 1),
                                                        Vec2(4, 2), Vec2(5, 2),
                                Vec2(2, 3), Vec2(3, 3), Vec2(4, 3),
                    Vec2(1, 4), Vec2(2, 4),
        Vec2(0, 5), Vec2(1, 5),
        Vec2(0, 6), Vec2(1, 6), Vec2(2, 6), Vec2(3, 6), Vec2(4, 6), Vec2(5, 6)
    }
    self.CUBE_SIZE = 6

    self.time = 0
end



---Returns the given property of this TitleDigit.
---@param key string The property key.
---@return any?
function TitleDigit:getProp(key)
    return self.properties:getValue(key)
end



---Sets the given property of this TitleDigit to a given value.
---@param key string The property key.
---@param value any? The property value.
function TitleDigit:setProp(key, value)
    self.properties:setValue(key, value)
end



---Returns the given property base of this TitleDigit.
---@param key string The property key.
---@return any?
function TitleDigit:getPropBase(key)
    return self.properties:getBaseValue(key)
end



---Sets the given property base of this TitleDigit to a given value.
---@param key string The property key.
---@param value any? The property value.
function TitleDigit:setPropBase(key, value)
    self.properties:setBaseValue(key, value)
end



---Draws a single polygon.
---@param points table A list of Vec2's which are corners of the polygon.
---@param color Color The color which this polygon will have.
---@param alpha number The opacity of the polygon.
function TitleDigit:drawPoly(points, color, alpha)
    love.graphics.setColor(color.r, color.g, color.b, alpha)
    local points2 = {}
    for i, point in ipairs(points) do
        table.insert(points2, point.x)
        table.insert(points2, point.y + 0.5)
    end
    love.graphics.polygon("fill", points2)
end



---Draws a single cube (a single "pixel" of the number).
---@param pos Vector2 The position of the cube.
---@param angle number The cube rotation.
---@param alpha number The cube opacity.
---@param shadow boolean? Whether to draw this as a shadow (also offsets the position accordingly).
function TitleDigit:drawCube(pos, angle, alpha, shadow)
    local a = alpha
    local c1 = self.MAIN_COLOR
    local c2 = self.SECONDARY_COLOR
    local c3 = self.TERNARY_COLOR
    if shadow then
        pos = pos + self:getProp("shadowOffset")
        a = 0.5
        c1 = self.SHADOW_COLOR
        c2 = self.SHADOW_COLOR
        c3 = self.SHADOW_COLOR
    end
    angle = angle % (math.pi * 2)
--[[
   illustration for angle = pi/4
   rotating clockwise

     ,/1\,
    /     \
   4       2
   |\     /|
   | '\3/' |
   |   |   |
   8   |   6
    \  |  /
     '\7/'

]]
    local w = self.CUBE_SIZE / 2
    local p1 = pos + Vec2(-w, -w):rotate(angle) * Vec2(1, 0.5)
    local p2 = pos + Vec2(w, -w):rotate(angle) * Vec2(1, 0.5)
    local p3 = pos + Vec2(w, w):rotate(angle) * Vec2(1, 0.5)
    local p4 = pos + Vec2(-w, w):rotate(angle) * Vec2(1, 0.5)
    local p5 = p1 + Vec2(0, self.CUBE_SIZE)
    local p6 = p2 + Vec2(0, self.CUBE_SIZE)
    local p7 = p3 + Vec2(0, self.CUBE_SIZE)
    local p8 = p4 + Vec2(0, self.CUBE_SIZE)
    if angle > math.pi / 2 and angle < math.pi / 2 * 3 then
        self:drawPoly({p1, p2, p6, p5}, c2, a)
    end
    if angle > 0 and angle < math.pi then
        self:drawPoly({p2, p3, p7, p6}, c1, a)
    end
    if angle > math.pi / 2 * 3 or angle < math.pi / 2 then
        self:drawPoly({p3, p4, p8, p7}, c2, a)
    end
    if angle > math.pi and angle < math.pi * 2 then
        self:drawPoly({p4, p1, p5, p8}, c1, a)
    end
    self:drawPoly({p1, p2, p3, p4}, c3, a)
end



---Returns the size of this Title Digit.
---@return Vector2
function TitleDigit:getSize()
    return self.SIZE * self.CUBE_SIZE
end



---Sets the size of this TitleDigit. But you actually cannot set it. Don't even try :)
---@param size Vector2 The new size of this TitleDigit.
function TitleDigit:setSize(size)
    error("TitleDigits cannot be resized!")
end



---Updates the Title Digit.
---@param dt number Time delta, in seconds.
function TitleDigit:update(dt)
    self.time = self.time + dt
end



---Draws the Title Digit.
function TitleDigit:draw()
    local pos = self.node:getGlobalPos()
    local angle = self.time % (math.pi * 2)
    love.graphics.setColor(1, 1, 1)
    local u = (angle + math.pi / 2) % (math.pi * 2) - math.pi
    table.sort(self.CUBE_POSITIONS, function(a, b) return a.y * -10 + a.x * u < b.y * -10 + b.x * u end)
    --[[
    if self:getProp("shadowOffset") then
        for i, cubePos in ipairs(self.CUBE_POSITIONS) do
            local offsetX = cubePos.x - (self.SIZE.x - 1) / 2
            local cubePos2 = (Vec2(offsetX, 0):rotate(angle - math.pi / 2) * Vec2(1, 0.5) + Vec2(self.SIZE.x / 2, cubePos.y)) * self.CUBE_SIZE + pos
            self:drawCube(cubePos2, angle, self:getProp("alpha"), true)
        end
    end
    ]]
    for i, cubePos in ipairs(self.CUBE_POSITIONS) do
        local offsetX = cubePos.x - (self.SIZE.x - 1) / 2
        local cubePos2 = (Vec2(offsetX, 0):rotate(angle - math.pi / 2) * Vec2(1, 0.5) + Vec2(self.SIZE.x / 2, cubePos.y)) * self.CUBE_SIZE + pos
        self:drawCube(cubePos2, angle, self:getProp("alpha"))
    end
end



---Returns the TitleDigit's data to be used for loading later.
---@return table
function TitleDigit:serialize()
    return self.properties:serialize()
end



return TitleDigit
