local class = require "com.class"

---@class Text
---@overload fun(node, data):Text
local Text = class:derive("Text")

local utf8 = require("utf8")
local Vec2 = require("Vector2")
local Color = require("Color")



---Creates a new Text.
---@param node Node The Node that this Text is attached to.
---@param data table The data to be used for this Text.
function Text:new(node, data)
    self.PROPERTY_LIST = {
        {name = "Text", key = "text", type = "string"},
        {name = "Scale", key = "scale", type = "number"},
        {name = "Color", key = "color", type = "color"},
        {name = "Alpha", key = "alpha", type = "number"},
        {name = "Shadow Offset", key = "shadowOffset", type = "Vector2", nullable = true},
        {name = "Shadow Alpha", key = "shadowAlpha", type = "number"},
        {name = "Wave Amplitude", key = "waveAmplitude", type = "number", nullable = true},
        {name = "Wave Frequency", key = "waveFrequency", type = "number", nullable = true},
        {name = "Wave Speed", key = "waveSpeed", type = "number", nullable = true},
        {name = "Gradient Wave Color", key = "gradientWaveColor", type = "color", nullable = true},
        {name = "Gradient Wave Frequency", key = "gradientWaveFrequency", type = "number", nullable = true},
        {name = "Gradient Wave Speed", key = "gradientWaveSpeed", type = "number", nullable = true}
    }

    self.node = node

    self.font = _FONTS[data.font] or _FONTS.standard
    self.text = data.text or "Text"
    self.scale = data.scale or 1
    self.color = data.color and Color(data.color) or _COLORS.white
    self.alpha = data.alpha or 1
    self.shadowOffset = data.shadowOffset and Vec2(data.shadowOffset)
    self.shadowAlpha = data.shadowAlpha or 0.5

    self.waveAmplitude = data.waveAmplitude
    self.waveFrequency = data.waveFrequency
    self.waveSpeed = data.waveSpeed

    self.gradientWaveColor = data.gradientWaveColor and Color(data.gradientWaveColor)
    self.gradientWaveFrequency = data.gradientWaveFrequency
    self.gradientWaveSpeed = data.gradientWaveSpeed

    self.time = 0
end



---Enables or disables the wavy effect, if no parameters are provided.
---@param amplitude number? The maximum number of pixels that each letter can go up and down.
---@param frequency number? The horizontal distance between two wave peaks, in pixels.
---@param speed number? How fast the wave should travel, in pixels per second.
function Text:setWave(amplitude, frequency, speed)
    self.waveAmplitude = amplitude
    self.waveFrequency = frequency
    self.waveSpeed = speed
end



---Enables or disables the wave gradient effect, if no parameters are provided.
---@param color Color? The secondary color to be interpolated to. The first one is the main text color.
---@param frequency number? The horizontal distance between two wave peaks, in pixels.
---@param speed number? How fast the wave should travel, in pixels per second.
function Text:setGradientWave(color, frequency, speed)
    self.gradientWaveColor = color
    self.gradientWaveFrequency = frequency
    self.gradientWaveSpeed = speed
end



---Returns the size of this Text.
---@return Vector2
function Text:getSize()
    return Vec2(self.font:getWidth(self.text) - 1, self.font:getHeight()) * self.scale
end



---Sets the size of this Text. But you actually cannot set it. Don't even try :)
---@param size Vector2 The new size of this Text.
function Text:setSize(size)
    error("Texts cannot be resized!")
end



---Returns the property list of this Text.
---@return table
function Text:getPropertyList()
    return self.PROPERTY_LIST
end



---Updates the Text. You need to do this to make sure the time-dependent effects are working correctly.
---@param dt number Time delta, in seconds.
function Text:update(dt)
    self.time = self.time + dt
end



---Draws the Text on the screen.
function Text:draw()
    local pos = self.node:getGlobalPos()
    love.graphics.setFont(self.font)
    local x = 0
    for i = 1, utf8.len(self.text) do
        local chr = self.text:sub(utf8.offset(self.text, i), utf8.offset(self.text, i + 1) - 1)
        local w = self.font:getWidth(chr) * self.scale
        local y = 0
        if self.waveAmplitude then
            y = _Utils.getWavePoint(self.waveFrequency, self.waveSpeed, x, self.time) * self.waveAmplitude
        end
        local color = self.color
        if self.gradientWaveColor then
            local t
            if self.gradientWaveSpeed then
                t = (_Utils.getWavePoint(self.gradientWaveFrequency, self.gradientWaveSpeed, x, self.time) + 1) / 2
            else
                t = (_Utils.getWavePoint(1 / self.gradientWaveFrequency, 1, 0, self.time) + 1) / 2
            end
            color = _Utils.interpolate(color, self.gradientWaveColor, t)
        end

        if self.shadowOffset then
            love.graphics.setColor(0, 0, 0, self.alpha * self.shadowAlpha)
            love.graphics.print(chr, math.floor(pos.x + self.shadowOffset.x + x + 0.5), math.floor(pos.y + self.shadowOffset.y + y + 0.5), 0, self.scale)
        end
        love.graphics.setColor(color.r, color.g, color.b, self.alpha)
        love.graphics.print(chr, math.floor(pos.x + x + 0.5), math.floor(pos.y + y + 0.5), 0, self.scale)
        x = x + w
    end
end



---Returns the Text's data to be used for loading later.
---@return table
function Text:serialize()
    local data = {}

    data.font = _FONT_LOOKUP[self.font]
    data.text = self.text
    data.scale = self.scale
    data.color = {r = self.color.r, g = self.color.g, b = self.color.b}
    data.alpha = self.alpha
    data.shadowOffset = self.shadowOffset and {x = self.shadowOffset.x, y = self.shadowOffset.y}
    data.shadowAlpha = self.shadowAlpha

    data.waveAmplitude = self.waveAmplitude
    data.waveFrequency = self.waveFrequency
    data.waveSpeed = self.waveSpeed

    data.gradientWaveColor = self.gradientWaveColor and {r = self.gradientWaveColor.r, g = self.gradientWaveColor.g, b = self.gradientWaveColor.b}
    data.gradientWaveFrequency = self.gradientWaveFrequency
    data.gradientWaveSpeed = self.gradientWaveSpeed

    return data
end



return Text