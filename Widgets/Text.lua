local class = require "com.class"

---@class Text
---@overload fun(node, data):Text
local Text = class:derive("Text")

local utf8 = require("utf8")
local Vec2 = require("Vector2")
local PropertyList = require("PropertyList")



---Creates a new Text.
---@param node Node The Node that this Text is attached to.
---@param data table? The data to be used for this Text.
function Text:new(node, data)
    self.node = node

    self.PROPERTY_LIST = {
        {name = "Font", key = "font", type = "Font", defaultValue = _FONTS.standard},
        {name = "Text", key = "text", type = "string", defaultValue = "Text"},
        {name = "Scale", key = "scale", type = "number", defaultValue = 1},
        {name = "Color", key = "color", type = "color", defaultValue = _COLORS.white},
        {name = "Hover Color", key = "hoverColor", type = "color", nullable = true},
        {name = "Alpha", key = "alpha", type = "number", defaultValue = 1},
        {name = "Shadow Offset", key = "shadowOffset", type = "Vector2", nullable = true},
        {name = "Shadow Alpha", key = "shadowAlpha", type = "number", defaultValue = 0.5},
        {name = "Boldness", key = "boldness", type = "number", defaultValue = 1},
        {name = "Underline", key = "underline", type = "boolean", defaultValue = false},
        {name = "Strikethrough", key = "strikethrough", type = "boolean", defaultValue = false},
        {name = "Character Separation", key = "characterSeparation", type = "number", defaultValue = 0},
        {name = "Wave Amplitude", key = "waveAmplitude", type = "number", nullable = true},
        {name = "Wave Frequency", key = "waveFrequency", type = "number", nullable = true},
        {name = "Wave Speed", key = "waveSpeed", type = "number", nullable = true},
        {name = "Gradient Wave Color", key = "gradientWaveColor", type = "color", nullable = true},
        {name = "Gradient Wave Frequency", key = "gradientWaveFrequency", type = "number", nullable = true},
        {name = "Gradient Wave Speed", key = "gradientWaveSpeed", type = "number", nullable = true}
    }
    self.properties = PropertyList(self.PROPERTY_LIST, data)

    self.time = 0
end



---Returns the given property of this Text.
---@param key string The property key.
---@return any?
function Text:getProp(key)
    return self.properties:getValue(key)
end



---Sets the given property of this Text to a given value.
---@param key string The property key.
---@param value any? The property value.
function Text:setProp(key, value)
    self.properties:setValue(key, value)
end



---Returns the given property base of this Text.
---@param key string The property key.
---@return any?
function Text:getPropBase(key)
    return self.properties:getBaseValue(key)
end



---Sets the given property base of this Text to a given value.
---@param key string The property key.
---@param value any? The property value.
function Text:setPropBase(key, value)
    self.properties:setBaseValue(key, value)
end



---Enables or disables the wavy effect, if no parameters are provided.
---@param amplitude number? The maximum number of pixels that each letter can go up and down.
---@param frequency number? The horizontal distance between two wave peaks, in pixels.
---@param speed number? How fast the wave should travel, in pixels per second.
function Text:setWave(amplitude, frequency, speed)
    self:setProp("waveAmplitude", amplitude)
    self:setProp("waveFrequency", frequency)
    self:setProp("waveSpeed", speed)
end



---Enables or disables the wave gradient effect, if no parameters are provided.
---@param color Color? The secondary color to be interpolated to. The first one is the main text color.
---@param frequency number? The horizontal distance between two wave peaks, in pixels.
---@param speed number? How fast the wave should travel, in pixels per second.
function Text:setGradientWave(color, frequency, speed)
    self:setProp("gradientWaveColor", color)
    self:setProp("gradientWaveFrequency", frequency)
    self:setProp("gradientWaveSpeed", speed)
end



---Returns the size of this Text.
---@return Vector2
function Text:getSize()
    local font = self:getProp("font")
    local text = self:getProp("text")
    local scale = self:getProp("scale")
    local boldness = self:getProp("boldness")
    return Vec2(font:getWidth(text) - 1, font:getHeight()) * scale + Vec2(self:getEffectiveCharacterSeparation() * (utf8.len(text) - 1) + boldness - 1, 0)
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
    return self:getProp("boldness") + self:getProp("characterSeparation") - 1
end



---Returns `true` if the Text can be rendered as a whole batch, instead of having to be drawn character by character.
---@return boolean
function Text:isSimpleRendered()
    if self:getProp("waveAmplitude") or self:getProp("gradientWaveColor") or self:getProp("characterSeparation") ~= 0 or self:getProp("boldness") ~= 1 then
        return false
    end
    return true
end



---Draws the Text on the screen.
function Text:draw()
    local pos = self.node:getGlobalPos()
    local font = self:getProp("font")
    local text = self:getProp("text")
    local scale = self:getProp("scale")
    local color = self:getProp("color")
    local hoverColor = self:getProp("hoverColor")
    local alpha = self:getProp("alpha")
    local shadowOffset = self:getProp("shadowOffset")
    local shadowAlpha = self:getProp("shadowAlpha")
    local boldness = self:getProp("boldness")
    local underline = self:getProp("underline")
    local strikethrough = self:getProp("strikethrough")
    local waveAmplitude = self:getProp("waveAmplitude")
    local waveFrequency = self:getProp("waveFrequency")
    local waveSpeed = self:getProp("waveSpeed")
    local gradientWaveColor = self:getProp("gradientWaveColor")
    local gradientWaveFrequency = self:getProp("gradientWaveFrequency")
    local gradientWaveSpeed = self:getProp("gradientWaveSpeed")

    love.graphics.setFont(font)
    if hoverColor and self.node:isHovered() then
        color = hoverColor
    end
    if self:isSimpleRendered() then
        -- Optimize drawing if there are no effects which require drawing each character separately.
        if shadowOffset then
            love.graphics.setColor(0, 0, 0, alpha * shadowAlpha)
            love.graphics.print(text, math.floor(pos.x + shadowOffset.x + 0.5), math.floor(pos.y + shadowOffset.y + 0.5), 0, scale)
        end
        love.graphics.setColor(color.r, color.g, color.b, alpha)
        love.graphics.print(text, math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), 0, scale)
    else
        -- Draw everything character by character.
        local x = 0
        local sep = self:getEffectiveCharacterSeparation()
        for i = 1, utf8.len(text) do
            local chr = text:sub(utf8.offset(text, i), utf8.offset(text, i + 1) - 1)
            local w = font:getWidth(chr) * scale
            local y = 0
            if waveAmplitude then
                y = _Utils.getWavePoint(waveFrequency, waveSpeed, x, self.time) * waveAmplitude
            end
            local charColor = color
            if gradientWaveColor then
                local t
                if gradientWaveSpeed then
                    t = (_Utils.getWavePoint(gradientWaveFrequency, gradientWaveSpeed, x, self.time) + 1) / 2
                else
                    t = (_Utils.getWavePoint(1 / gradientWaveFrequency, 1, 0, self.time) + 1) / 2
                end
                charColor = _Utils.interpolate(color, gradientWaveColor, t)
            end

            if shadowOffset then
                for j = 1, boldness do
                    local bx = j - 1
                    love.graphics.setColor(0, 0, 0, alpha * shadowAlpha)
                    love.graphics.print(chr, math.floor(pos.x + x + bx + 0.5 + shadowOffset.x), math.floor(pos.y + y + 0.5 + shadowOffset.y), 0, scale)
                end
            end
            for j = 1, boldness do
                local bx = j - 1
                love.graphics.setColor(charColor.r, charColor.g, charColor.b, alpha)
                love.graphics.print(chr, math.floor(pos.x + x + bx + 0.5), math.floor(pos.y + y + 0.5), 0, scale)
            end
            x = x + w + sep
        end
    end

    if underline then
        local size = self:getSize()
        local x1 = pos.x + 0.5
        local x2 = pos.x + size.x + 0.5
        local y = pos.y + size.y + 0.5
        love.graphics.setLineWidth(scale)
        if shadowOffset then
            love.graphics.setColor(0, 0, 0, alpha * shadowAlpha)
            love.graphics.line(math.floor(x1 + shadowOffset.x), math.floor(y + shadowOffset.y), math.floor(x2 + shadowOffset.x), math.floor(y + shadowOffset.y))
        end
        love.graphics.setColor(color.r, color.g, color.b, alpha)
        love.graphics.line(math.floor(x1), math.floor(y), math.floor(x2), math.floor(y))
    end

    if strikethrough then
        local size = self:getSize()
        local x1 = pos.x + 0.5
        local x2 = pos.x + size.x + 0.5
        local y = pos.y + size.y / 2 + 0.5
        love.graphics.setLineWidth(scale)
        if shadowOffset then
            love.graphics.setColor(0, 0, 0, alpha * shadowAlpha)
            love.graphics.line(math.floor(x1 + shadowOffset.x), math.floor(y + shadowOffset.y), math.floor(x2 + shadowOffset.x), math.floor(y + shadowOffset.y))
        end
        love.graphics.setColor(color.r, color.g, color.b, alpha)
        love.graphics.line(math.floor(x1), math.floor(y), math.floor(x2), math.floor(y))
    end
end



---Returns the Text's data to be used for loading later.
---@return table
function Text:serialize()
    return self.properties:serialize()
end



return Text