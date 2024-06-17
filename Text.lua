local class = require "com.class"

---@class Text
---@overload fun(data):Text
local Text = class:derive("Text")

local Vec2 = require("Vector2")
local Color = require("Color")



---Creates a new Text.
---@param data table The data to be used for this Text.
function Text:new(data)
    self.font = _FONTS[data.font]
    self.text = data.text or ""
    self.scale = data.scale or 1
    self.color = Color(data.color)
    self.shadowOffset = data.shadow and (type(data.shadow) == "number" and Vec2(data.shadow) or Vec2(1))

    self.time = 0

    self.waveAmplitude = data.wave and data.wave.amplitude
    self.waveFrequency = data.wave and data.wave.frequency
    self.waveSpeed = data.wave and data.wave.speed

    self.gradientWaveColor = data.gradientWave and Color(data.gradientWave.color)
    self.gradientWaveFrequency = data.gradientWave and data.gradientWave.frequency
    self.gradientWaveSpeed = data.gradientWave and data.gradientWave.speed
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



---Updates the Text. You need to do this to make sure the time-dependent effects are working correctly.
---@param dt number Time delta, in seconds.
function Text:update(dt)
    self.time = self.time + dt
end



---Draws the Text on the screen.
---@param pos Vector2 The position where this Text will be drawn.
---@param alpha number The opacity of this Text.
function Text:draw(pos, alpha)
    love.graphics.setFont(self.font)
    local x = 0
    for i = 1, #self.text do
        local chr = self.text:sub(i, i)
        local w = self.font:getWidth(chr) * self.scale
        local y = 0
        if self.waveAmplitude then
            y = _Utils.getWavePoint(self.waveFrequency, self.waveSpeed, x, self.time) * self.waveAmplitude
        end
        local color = self.color
        if self.gradientWaveColor then
            color = _Utils.interpolate(color, self.gradientWaveColor, (_Utils.getWavePoint(self.gradientWaveFrequency, self.gradientWaveSpeed, x, self.time) + 1) / 2)
        end

        if self.shadowOffset then
            love.graphics.setColor(0, 0, 0, alpha * 0.5)
            love.graphics.print(chr, math.floor(pos.x + self.shadowOffset.x + x + 0.5), math.floor(pos.y + self.shadowOffset.y + y + 0.5), 0, self.scale)
        end
        love.graphics.setColor(color.r, color.g, color.b, alpha)
        love.graphics.print(chr, math.floor(pos.x + x + 0.5), math.floor(pos.y + y + 0.5), 0, self.scale)
        x = x + w
    end
end



return Text