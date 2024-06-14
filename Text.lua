local class = require "com/class"

---@class Text
---@overload fun(font, text, pos, scale, color, shadow):Text
local Text = class:derive("Text")

local Vec2 = require("Vector2")
local Color = require("Color")



---Creates a new Text.
---@param font love.Font Font to be used.
---@param text string The text to be displayed.
---@param pos Vector2 Where the Text should be displayed.
---@param scale number? The scale of the Text.
---@param color Color? The color of the Text, white by default.
---@param shadow boolean? Whether the Text should have a shadow.
function Text:new(font, text, pos, scale, color, shadow)
    self.font = font
    self.text = text
    self.pos = pos
    self.scale = scale or 1
    self.color = color or Color()
    self.shadowOffset = shadow and Vec2(1)

    self.time = 0

    self.waveAmplitude = nil
    self.waveFrequency = nil
    self.waveSpeed = nil

    self.gradientWaveColor = nil
    self.gradientWaveFrequency = nil
    self.gradientWaveSpeed = nil
end



---Updates the Text. You need to do this to make sure the time-dependent effects are working correctly.
---@param dt number Time delta in seconds.
function Text:update(dt)
    self.time = self.time + dt
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



---Draws the Text on the screen.
function Text:draw()
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
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.print(chr, math.floor(self.pos.x + self.shadowOffset.x + x + 0.5), math.floor(self.pos.y + self.shadowOffset.y + y + 0.5), 0, self.scale)
        end
        love.graphics.setColor(color.r, color.g, color.b)
        love.graphics.print(chr, math.floor(self.pos.x + x + 0.5), math.floor(self.pos.y + y + 0.5), 0, self.scale)
        x = x + w
    end
end



return Text