local class = require "com.class"

---@class Text
---@overload fun(node, data):Text
local Text = class:derive("Text")

local utf8 = require("utf8")
local Vec2 = require("Vector2")
local Color = require("Color")



---Creates a new Text.
---@param node Node The Node that this Text is attached to.
---@param data table? The data to be used for this Text.
function Text:new(node, data)
    self.PROPERTY_LIST = {
        {name = "Text", key = "text", type = "string"},
        {name = "Scale", key = "scale", type = "number"},
        {name = "Color", key = "color", type = "color"},
        {name = "Hover Color", key = "hoverColor", type = "color", nullable = true},
        {name = "Alpha", key = "alpha", type = "number"},
        {name = "Shadow Offset", key = "shadowOffset", type = "Vector2", nullable = true},
        {name = "Shadow Alpha", key = "shadowAlpha", type = "number"},
        {name = "Boldness", key = "boldness", type = "number"},
        {name = "Underline", key = "underline", type = "boolean"},
        {name = "Strikethrough", key = "strikethrough", type = "boolean"},
        {name = "Character Separation", key = "characterSeparation", type = "number"},
        {name = "Wave Amplitude", key = "waveAmplitude", type = "number", nullable = true},
        {name = "Wave Frequency", key = "waveFrequency", type = "number", nullable = true},
        {name = "Wave Speed", key = "waveSpeed", type = "number", nullable = true},
        {name = "Gradient Wave Color", key = "gradientWaveColor", type = "color", nullable = true},
        {name = "Gradient Wave Frequency", key = "gradientWaveFrequency", type = "number", nullable = true},
        {name = "Gradient Wave Speed", key = "gradientWaveSpeed", type = "number", nullable = true}
    }
    data = data or {}

    self.node = node

    self.font = _FONTS[data.font] or _FONTS.standard
    self.text = data.text or "Text"
    self.scale = data.scale or 1
    self.color = data.color and Color(data.color) or _COLORS.white
    self.hoverColor = data.hoverColor and Color(data.hoverColor)
    self.alpha = data.alpha or 1
    self.shadowOffset = data.shadowOffset and Vec2(data.shadowOffset)
    self.shadowAlpha = data.shadowAlpha or 0.5
    self.boldness = data.boldness or 1
    self.underline = data.underline or false
    self.strikethrough = data.strikethrough or false
    self.characterSeparation = data.characterSeparation or 0

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
    return Vec2(self.font:getWidth(self.text) - 1, self.font:getHeight()) * self.scale + Vec2(self:getEffectiveCharacterSeparation() * (utf8.len(self.text) - 1) + self.boldness - 1, 0)
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



---Returns the effective character separation of this Text, as both the character separation but also boldness will push the characters apart.
---@return integer
function Text:getEffectiveCharacterSeparation()
    return self.boldness + self.characterSeparation - 1
end



---Returns `true` if the Text can be rendered as a whole batch, instead of having to be drawn character by character.
---@return boolean
function Text:isSimpleRendered()
    if self.waveAmplitude or self.gradientWaveColor or self.characterSeparation ~= 0 or self.boldness ~= 1 then
        return false
    end
    return true
end



---Draws the Text on the screen.
function Text:draw()
    local pos = self.node:getGlobalPos()
    love.graphics.setFont(self.font)
    local color = self.color
    if self.hoverColor and self.node:isHovered() then
        color = self.hoverColor
    end
    if self:isSimpleRendered() then
        -- Optimize drawing if there are no effects which require drawing each character separately.
        if self.shadowOffset then
            love.graphics.setColor(0, 0, 0, self.alpha * self.shadowAlpha)
            love.graphics.print(self.text, math.floor(pos.x + self.shadowOffset.x + 0.5), math.floor(pos.y + self.shadowOffset.y + 0.5), 0, self.scale)
        end
        love.graphics.setColor(color.r, color.g, color.b, self.alpha)
        love.graphics.print(self.text, math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), 0, self.scale)
    else
        -- Draw everything character by character.
        local x = 0
        local sep = self:getEffectiveCharacterSeparation()
        for i = 1, utf8.len(self.text) do
            local chr = self.text:sub(utf8.offset(self.text, i), utf8.offset(self.text, i + 1) - 1)
            local w = self.font:getWidth(chr) * self.scale
            local y = 0
            if self.waveAmplitude then
                y = _Utils.getWavePoint(self.waveFrequency, self.waveSpeed, x, self.time) * self.waveAmplitude
            end
            local charColor = color
            if self.gradientWaveColor then
                local t
                if self.gradientWaveSpeed then
                    t = (_Utils.getWavePoint(self.gradientWaveFrequency, self.gradientWaveSpeed, x, self.time) + 1) / 2
                else
                    t = (_Utils.getWavePoint(1 / self.gradientWaveFrequency, 1, 0, self.time) + 1) / 2
                end
                charColor = _Utils.interpolate(color, self.gradientWaveColor, t)
            end

            if self.shadowOffset then
                for j = 1, self.boldness do
                    local bx = j - 1
                    love.graphics.setColor(0, 0, 0, self.alpha * self.shadowAlpha)
                    love.graphics.print(chr, math.floor(pos.x + x + bx + 0.5 + self.shadowOffset.x), math.floor(pos.y + y + 0.5 + self.shadowOffset.y), 0, self.scale)
                end
            end
            for j = 1, self.boldness do
                local bx = j - 1
                love.graphics.setColor(charColor.r, charColor.g, charColor.b, self.alpha)
                love.graphics.print(chr, math.floor(pos.x + x + bx + 0.5), math.floor(pos.y + y + 0.5), 0, self.scale)
            end
            x = x + w + sep
        end
    end

    if self.underline then
        local size = self:getSize()
        local x1 = pos.x + 0.5
        local x2 = pos.x + size.x + 0.5
        local y = pos.y + size.y + 0.5
        love.graphics.setLineWidth(self.scale)
        if self.shadowOffset then
            love.graphics.setColor(0, 0, 0, self.alpha * self.shadowAlpha)
            love.graphics.line(math.floor(x1 + self.shadowOffset.x), math.floor(y + self.shadowOffset.y), math.floor(x2 + self.shadowOffset.x), math.floor(y + self.shadowOffset.y))
        end
        love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.alpha)
        love.graphics.line(math.floor(x1), math.floor(y), math.floor(x2), math.floor(y))
    end

    if self.strikethrough then
        local size = self:getSize()
        local x1 = pos.x + 0.5
        local x2 = pos.x + size.x + 0.5
        local y = pos.y + size.y / 2 + 0.5
        love.graphics.setLineWidth(self.scale)
        if self.shadowOffset then
            love.graphics.setColor(0, 0, 0, self.alpha * self.shadowAlpha)
            love.graphics.line(math.floor(x1 + self.shadowOffset.x), math.floor(y + self.shadowOffset.y), math.floor(x2 + self.shadowOffset.x), math.floor(y + self.shadowOffset.y))
        end
        love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.alpha)
        love.graphics.line(math.floor(x1), math.floor(y), math.floor(x2), math.floor(y))
    end
end



---Returns the Text's data to be used for loading later.
---@return table
function Text:serialize()
    local data = {}

    data.font = _FONT_LOOKUP[self.font]
    data.text = self.text
    data.scale = self.scale ~= 1 and self.scale or nil
    data.color = self.color ~= _COLORS.white and self.color:getHex() or nil
    data.hoverColor = self.hoverColor and self.hoverColor:getHex()
    data.alpha = self.alpha ~= 1 and self.alpha or nil
    data.shadowOffset = self.shadowOffset and {self.shadowOffset.x, self.shadowOffset.y}
    data.shadowAlpha = self.shadowAlpha ~= 0.5 and self.shadowAlpha or nil
    data.boldness = self.boldness ~= 1 and self.boldness or nil
    data.underline = self.underline or nil
    data.strikethrough = self.strikethrough or nil
    data.characterSeparation = self.characterSeparation ~= 0 and self.characterSeparation or nil

    data.waveAmplitude = self.waveAmplitude
    data.waveFrequency = self.waveFrequency
    data.waveSpeed = self.waveSpeed

    data.gradientWaveColor = self.gradientWaveColor and self.gradientWaveColor:getHex()
    data.gradientWaveFrequency = self.gradientWaveFrequency
    data.gradientWaveSpeed = self.gradientWaveSpeed

    return data
end



return Text