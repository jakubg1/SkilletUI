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
        {name = "Font", key = "font", type = "Font", defaultValue = _RESOURCE_MANAGER:getFont("standard")},
        {name = "Text", key = "text", type = "string", defaultValue = "Text"},
        {name = "Scale", key = "scale", type = "number", defaultValue = 1, minValue = 1, scrollStep = 1},
        {name = "Color", key = "color", type = "color", defaultValue = _COLORS.white},
        {name = "Hover Color", key = "hoverColor", type = "color", nullable = true},
        {name = "Alpha", key = "alpha", type = "number", defaultValue = 1, minValue = 0, maxValue = 1, scrollStep = 0.1},
        {name = "Shadow Offset", key = "shadowOffset", type = "Vector2", nullable = true},
        {name = "Shadow Alpha", key = "shadowAlpha", type = "number", defaultValue = 0.5, minValue = 0, maxValue = 1, scrollStep = 0.1},
        {name = "Boldness", key = "boldness", type = "number", defaultValue = 1, minValue = 1, scrollStep = 1},
        {name = "Underline", key = "underline", type = "boolean", defaultValue = false},
        {name = "Strikethrough", key = "strikethrough", type = "boolean", defaultValue = false},
        {name = "Character Separation", key = "characterSeparation", type = "number", defaultValue = 0, minValue = -1, scrollStep = 1},
        {name = "Wave Amplitude", key = "waveAmplitude", type = "number", nullable = true},
        {name = "Wave Frequency", key = "waveFrequency", type = "number", nullable = true},
        {name = "Wave Speed", key = "waveSpeed", type = "number", nullable = true},
        {name = "Gradient Wave Color", key = "gradientWaveColor", type = "color", nullable = true},
        {name = "Gradient Wave Frequency", key = "gradientWaveFrequency", type = "number", nullable = true},
        {name = "Gradient Wave Speed", key = "gradientWaveSpeed", type = "number", nullable = true},
        {name = "Type-in Progress", key = "typeInProgress", type = "number", nullable = true, minValue = 0, maxValue = 1, scrollStep = 0.1},
        {name = "Input Caret", key = "inputCaret", type = "boolean", defaultValue = false}
    }
    self.properties = PropertyList(self.PROPERTY_LIST, data)
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



---Returns the size of this Text.
---@return Vector2
function Text:getSize()
    local prop = self.properties:getValues()
    local text = self:getText()
    return Vec2(prop.font:getWidth(text) - 1, prop.font:getHeight()) * prop.scale + Vec2(self:getEffectiveCharacterSeparation() * (utf8.len(text) - 1) + prop.boldness - 1, 0)
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
    self.properties:update(dt)
end



---Returns the actual text that is visible on this Widget. It can differ from the real text if the `typeInProgress` property is set.
---@return string
function Text:getText()
    local prop = self.properties:getValues()
    local caret = (prop.inputCaret and _Time % 1 < 0.5) and "|" or ""
    if not prop.typeInProgress then
        return prop.text .. caret
    end
    local totalCharsRendered = math.floor(_Utils.interpolateClamped(0, utf8.len(prop.text), prop.typeInProgress))
    return prop.text:sub(0, utf8.offset(prop.text, totalCharsRendered + 1) - 1) .. caret
end



---Returns the effective character separation of this Text, as both the character separation but also boldness will push the characters apart.
---@return integer
function Text:getEffectiveCharacterSeparation()
    local prop = self.properties:getValues()
    return prop.boldness + prop.characterSeparation - 1
end



---Returns `true` if the Text can be rendered as a whole batch, instead of having to be drawn character by character.
---@return boolean
function Text:isSimpleRendered()
    local prop = self.properties:getValues()
    if prop.waveAmplitude or prop.gradientWaveColor or prop.characterSeparation ~= 0 or prop.boldness ~= 1 then
        return false
    end
    return true
end



---Draws the Text on the screen.
function Text:draw()
    local pos = self.node:getGlobalPos()
    local text = self:getText()
    local prop = self.properties:getValues()

    love.graphics.setFont(prop.font)
    local color = prop.color
    if prop.hoverColor and self.node:isHovered() then
        color = prop.hoverColor
    end
    if self:isSimpleRendered() then
        -- Optimize drawing if there are no effects which require drawing each character separately.
        if prop.shadowOffset then
            love.graphics.setColor(0, 0, 0, prop.alpha * prop.shadowAlpha)
            love.graphics.print(text, math.floor(pos.x + prop.shadowOffset.x + 0.5), math.floor(pos.y + prop.shadowOffset.y + 0.5), 0, prop.scale)
        end
        love.graphics.setColor(color.r, color.g, color.b, prop.alpha)
        love.graphics.print(text, math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), 0, prop.scale)
    else
        -- Draw everything character by character.
        local x = 0
        local sep = self:getEffectiveCharacterSeparation()
        for i = 1, utf8.len(text) do
            local chr = text:sub(utf8.offset(text, i), utf8.offset(text, i + 1) - 1)
            local w = prop.font:getWidth(chr) * prop.scale
            local y = 0
            if prop.waveFrequency and prop.waveAmplitude and prop.waveSpeed then
                y = _Utils.getWavePoint(prop.waveFrequency, prop.waveSpeed, x, _Time) * prop.waveAmplitude
            end
            local charColor = color
            if prop.gradientWaveFrequency and prop.gradientWaveColor then
                local t
                if prop.gradientWaveSpeed then
                    t = (_Utils.getWavePoint(prop.gradientWaveFrequency, prop.gradientWaveSpeed, x, _Time) + 1) / 2
                else
                    t = (_Utils.getWavePoint(1 / prop.gradientWaveFrequency, 1, 0, _Time) + 1) / 2
                end
                charColor = _Utils.interpolate(color, prop.gradientWaveColor, t)
            end

            if prop.shadowOffset then
                for j = 1, prop.boldness do
                    local bx = j - 1
                    love.graphics.setColor(0, 0, 0, prop.alpha * prop.shadowAlpha)
                    love.graphics.print(chr, math.floor(pos.x + x + bx + 0.5 + prop.shadowOffset.x), math.floor(pos.y + y + 0.5 + prop.shadowOffset.y), 0, prop.scale)
                end
            end
            for j = 1, prop.boldness do
                local bx = j - 1
                love.graphics.setColor(charColor.r, charColor.g, charColor.b, prop.alpha)
                love.graphics.print(chr, math.floor(pos.x + x + bx + 0.5), math.floor(pos.y + y + 0.5), 0, prop.scale)
            end
            x = x + w + sep
        end
    end

    if prop.underline then
        local size = self:getSize()
        local x1 = pos.x + 0.5
        local x2 = pos.x + size.x + 0.5
        local y = pos.y + size.y + 0.5
        love.graphics.setLineWidth(prop.scale)
        if prop.shadowOffset then
            love.graphics.setColor(0, 0, 0, prop.alpha * prop.shadowAlpha)
            love.graphics.line(math.floor(x1 + prop.shadowOffset.x), math.floor(y + prop.shadowOffset.y), math.floor(x2 + prop.shadowOffset.x), math.floor(y + prop.shadowOffset.y))
        end
        love.graphics.setColor(color.r, color.g, color.b, prop.alpha)
        love.graphics.line(math.floor(x1), math.floor(y), math.floor(x2), math.floor(y))
    end

    if prop.strikethrough then
        local size = self:getSize()
        local x1 = pos.x + 0.5
        local x2 = pos.x + size.x + 0.5
        local y = pos.y + size.y / 2 + 0.5
        love.graphics.setLineWidth(prop.scale)
        if prop.shadowOffset then
            love.graphics.setColor(0, 0, 0, prop.alpha * prop.shadowAlpha)
            love.graphics.line(math.floor(x1 + prop.shadowOffset.x), math.floor(y + prop.shadowOffset.y), math.floor(x2 + prop.shadowOffset.x), math.floor(y + prop.shadowOffset.y))
        end
        love.graphics.setColor(color.r, color.g, color.b, prop.alpha)
        love.graphics.line(math.floor(x1), math.floor(y), math.floor(x2), math.floor(y))
    end
end



---Returns the Text's data to be used for loading later.
---@return table
function Text:serialize()
    return self.properties:serialize()
end



return Text