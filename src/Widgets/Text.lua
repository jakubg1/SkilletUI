local class = require "com.class"

---@class Text
---@overload fun(node, data):Text
local Text = class:derive("Text")

local utf8 = require("utf8")
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")
local PropertyList = require("src.PropertyList")



---Creates a new Text.
---@param node Node The Node that this Text is attached to.
---@param data table? The data to be used for this Text.
function Text:new(node, data)
    self.node = node

    self.PROPERTY_LIST = {
        {name = "Font", key = "font", type = "Font", defaultValue = _RESOURCE_MANAGER:getFont("standard")},
        {name = "Text", key = "text", type = "string", defaultValue = "Text"},
        {name = "Formatted", key = "formatted", type = "boolean", defaultValue = false},
        {name = "Size", key = "size", type = "Vector2", nullable = true},
        {name = "Text Align", key = "textAlign", type = "align", defaultValue = _ALIGNMENTS.topLeft},
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
        {name = "Input Caret", key = "inputCaret", type = "boolean", defaultValue = false},
        {name = "Max Width", key = "maxWidth", type = "number", nullable = true, minValue = 1, scrollStep = 10},
        {name = "Editable", key = "editable", type = "boolean", defaultValue = false},
        {name = "Shift+Enter New Line Input", key = "newlineShiftInput", type = "boolean", defaultValue = false},
        {name = "Signal On Input", key = "signalOnInput", type = "string", nullable = true}
    }
    self.properties = PropertyList(self.PROPERTY_LIST, data)

    self.chunkData = nil
    self.textSize = Vec2()
    self:generateChunks()
end

--################################################--
---------------- P R O P E R T I E S ---------------
--################################################--

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
    self:generateChunks()
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
    self:generateChunks()
end

---Returns the property list of this Text.
---@return table
function Text:getPropertyList()
    return self.PROPERTY_LIST
end

--##############################################################--
---------------- P O S I T I O N   A N D   S I Z E ---------------
--##############################################################--

---Returns the top left corner of where the Text will be actually drawn. This includes adjustments for the widget's own text alignment.
---@return Vector2
function Text:getPos()
    local pos = self.node:getGlobalPos()
    local size = self:getSize()
    local textSize = self:getFinalTextSize()
    return pos + (size - textSize) * self:getProp("textAlign")
end

---Returns the size of this Text.
---@return Vector2
function Text:getSize()
    if self.node.scaleSize then
        return self.node.scaleSize
    end
    local prop = self.properties:getValues()
    if prop.size then
        return prop.size
    end
    return self:getFinalTextSize()
end

---Sets the size of this Text.
---@param size Vector2 The new size of this Text.
function Text:setSize(size)
    self:setPropBase("size", size)
end

---Returns the size of this Text after taking the actual widget size into effect.
---@return Vector2
function Text:getFinalTextSize()
    local prop = self.properties:getValues()
    local size = self.textSize:clone()
    if prop.maxWidth then
        size.x = math.min(size.x, prop.maxWidth)
    end
    return size
end

---Returns the effective character separation of this Text, as both the character separation but also boldness will push the characters apart.
---@return integer
function Text:getEffectiveCharacterSeparation()
    local prop = self.properties:getValues()
    return prop.boldness + prop.characterSeparation - 1
end

---Returns the width scaling (squish) of this Text: 1 if it falls into the `maxWidth` property, less than 1 if not.
---@return number
function Text:getWidthScale()
    local maxWidth = self:getProp("maxWidth")
    if not maxWidth then
        return 1
    end
    return math.min(maxWidth / self.textSize.x, 1)
end

--##################################################################--
---------------- T E X T   A N D   C H A R A C T E R S ---------------
--##################################################################--

---Returns the displayed text, which might differ from the `text` property if certain properties, such as `typeInProgress` or `inputCaret` are set.
---@return string
function Text:getDisplayedText()
    local prop = self.properties:getValues()
    local caret = (prop.inputCaret and _Time % 1 < 0.5) and "|" or ""
    if not prop.typeInProgress then
        return prop.text .. caret
    end
    local totalCharsRendered = math.floor(_Utils.interpolateClamped(0, utf8.len(prop.text), prop.typeInProgress))
    return prop.text:sub(0, utf8.offset(prop.text, totalCharsRendered + 1) - 1) .. caret
end

---Processes the formatting characters and returns a list of text and formatting values.
---Backslashes are treated as follows:
--- - All backslashed characters are treated as text.
--- - Backslashed formatting opening `\<` will cause the `<` character to render instead of being treated as a formatting clause.
--- - Double backslashes are converted into one backslash.
--- - The `\n` string is NOT converted into a newline character, but instead into `n`.
--- - Newline characters are left intact.
---@private
---@return [{type: "text"|"format", value: string}]
function Text:parseFormatting()
    local tokens = {}
    local token = ""
    local formatting = false
    local escape = false
    local characters = _Utils.strSplitChars(self:getDisplayedText())
    for i, char in ipairs(characters) do
        if escape then
            -- Escaped characters are directly added to the token.
            token = token .. char
            escape = false
        else
            if char == "\\" then
                escape = true
            elseif not formatting then
                -- If we are not in formatting mode, check whether we should start.
                if char == "<" then
                    if token ~= "" then
                        table.insert(tokens, {type = "text", value = token})
                        token = ""
                    end
                    formatting = true
                else
                    token = token .. char
                end
            else
                -- If we are in formatting mode, check whether we should finish.
                if char == ">" then
                    table.insert(tokens, {type = "format", value = token})
                    token = ""
                    formatting = false
                else
                    token = token .. char
                end
            end
        end
    end
    -- If there is a leftover text token, add it.
    if not formatting and token ~= "" then
        table.insert(tokens, {type = "text", value = token})
    end
    return tokens
end

---(Re)generates text chunk data which is used to draw this Text on the screen and recalculates the text size.
---This should ideally be only ever called whenever the text is changed.
function Text:generateChunks()
    local d = self.node:getName() == "previewText"
    if d then print("================ START") end
    local prop = self.properties:getValues()
    local tokens
    if prop.formatted then
        tokens = self:parseFormatting()
    else
        tokens = {{type = "text", value = prop.text}}
    end
    local chunkData = {}
    local x, y = 0, 0
    local width = 0
    local lineHeight = 0
    local style = {
        color = prop.color,
        boldness = prop.boldness,
        separation = prop.characterSeparation
    }
    for i, token in ipairs(tokens) do
        if token.type == "format" then
            -- Change the formatting.
            if token.value:sub(1, 1) ~= "/" then
                -- Starting mark.
                local value = token.value
                if _COLORS[value] then
                    style.color = _COLORS[value] -- Color name
                elseif (value:len() == 4 or value:len() == 7) and value:sub(1, 1) == "#" then
                    style.color = Color(value:sub(2)) -- Color hex code (#rgb or #rrggbb)
                elseif value == "b" then
                    style.boldness = 2 -- Bold
                end
            else
                -- Ending mark.
                local value = token.value:sub(2)
                if value == "" then
                    -- Reset everything to default.
                    style.color = prop.color
                    style.boldness = prop.boldness
                elseif value == "#" then
                    style.color = prop.color -- Reset color
                elseif value == "b" then
                    style.boldness = prop.boldness -- Reset boldness
                end
            end
        elseif token.type == "text" then
            -- Add text.
            local chunks = _Utils.strSplit(token.value, "\n")
            -- We will do a greedy split (split into single characters) if the characters have to be drawn one by one.
            -- For example when they are bolded, separated or have a different color or wave effect active.
            local greedySplit = style.boldness ~= 1 or style.separation ~= 0
            for j, chunk in ipairs(chunks) do
                if d then print("chunk: " .. chunk, j) end
                local subchunks
                if greedySplit then
                    subchunks = _Utils.strSplitChars(chunk)
                else
                    subchunks = {chunk}
                end
                if j > 1 then
                    if d then print("LBREAK") end
                    -- All subsequent chunks are guaranteed to have a line break character before them.
                    -- Do line break stuff.
                    x = 0
                    y = y + lineHeight
                    lineHeight = 0
                end
                for k, subchunk in ipairs(subchunks) do
                    if subchunk ~= "" then
                        if d then print("  subchunk: " .. subchunk) end
                        -- If no formatting has been changed, append text to the most recent chunk.
                        local lastChunk = chunkData[#chunkData]
                        if not greedySplit and j == 1 and lastChunk and lastChunk.color == style.color and lastChunk.boldness == style.boldness then
                            lastChunk.text = lastChunk.text .. subchunk
                        else
                            -- Add a brand new chunk.
                            table.insert(chunkData, {text = subchunk, x = x, y = y, color = style.color, boldness = style.boldness})
                        end
                        -- Update the chunk data.
                        lastChunk = chunkData[#chunkData]
                        lastChunk.width = (prop.font:getWidth(lastChunk.text) - 1) * prop.scale + lastChunk.boldness - 1
                        lastChunk.height = prop.font:getHeight() * prop.scale
                        x = x + lastChunk.width
                        width = math.max(width, x)
                        x = x + prop.scale + style.separation
                        lineHeight = math.max(lineHeight, lastChunk.height)
                    end
                end
            end
        end
    end
    -- Shorten last chunk so that we don't have a pesky extra pixel at the end.
    self.chunkData = chunkData
    self.textSize = Vec2(width, y + lineHeight)
end

---Turns the formatting token list generated by `:parseFormatting()` into a readable string format for debugging.
---@private
---@param tokens [{type: "text"|"format", value: string}] Token list to stringify.
---@return string
function Text:formattingToString(tokens)
    local str = ""
    for i, token in ipairs(tokens) do
        if i > 1 then
            str = str .. " "
        end
        if token.type == "text" then
            str = str .. "\"" .. token.value .. "\""
        elseif token.type == "format" then
            str = str .. "<" .. token.value .. ">"
        end
    end
    return str
end

--##############################################--
---------------- C A L L B A C K S ---------------
--##############################################--

---Updates the Text. You need to do this to make sure the time-dependent effects are working correctly.
---@param dt number Time delta, in seconds.
function Text:update(dt)
    self.properties:update(dt)
end

---Draws the Text on the screen.
function Text:draw()
    local pos = self:getPos()
    local widthScale = self:getWidthScale()
    local prop = self.properties:getValues()

    love.graphics.setFont(prop.font.font)

    local globalTextColor = prop.color
    if prop.hoverColor and self.node:isHovered() then
        globalTextColor = prop.hoverColor
    end

    -- TEMPORARY: Draw a placeholder input caret.
    if prop.inputCaret and _Time % 1 < 0.5 then
        love.graphics.setColor(1, 0, 0.5, 0.5)
        love.graphics.rectangle("fill", pos.x, pos.y, self.textSize.x, self.textSize.y)
    end
    -- The text is drawn chunk by chunk.
    for i, chunk in ipairs(self.chunkData) do
        local animOffset = chunk.x - pos.x
        local chunkY = chunk.y
        if prop.waveFrequency and prop.waveAmplitude and prop.waveSpeed then
            chunkY = chunkY + _Utils.getWavePoint(prop.waveFrequency, prop.waveSpeed, animOffset, _Time) * prop.waveAmplitude
        end
        local chunkColor = chunk.color
        if prop.hoverColor and self.node:isHovered() then
            chunkColor = prop.hoverColor
        end
        if prop.gradientWaveFrequency and prop.gradientWaveColor then
            local t
            if prop.gradientWaveSpeed then
                t = (_Utils.getWavePoint(prop.gradientWaveFrequency, prop.gradientWaveSpeed, animOffset, _Time) + 1) / 2
            else
                t = (_Utils.getWavePoint(1 / prop.gradientWaveFrequency, 1, 0, _Time) + 1) / 2
            end
            chunkColor = _Utils.interpolate(chunkColor, prop.gradientWaveColor, t)
        end

        if prop.shadowOffset then
            for j = 1, chunk.boldness do
                local bx = j - 1
                love.graphics.setColor(0, 0, 0, prop.alpha * prop.shadowAlpha)
                love.graphics.print(chunk.text, pos.x + chunk.x * widthScale + bx + prop.shadowOffset.x, pos.y + chunkY + prop.shadowOffset.y, 0, prop.scale * widthScale, prop.scale)
            end
        end
        for j = 1, chunk.boldness do
            local bx = j - 1
            love.graphics.setColor(chunkColor.r, chunkColor.g, chunkColor.b, prop.alpha)
            love.graphics.print(chunk.text, pos.x + chunk.x * widthScale + bx, pos.y + chunkY, 0, prop.scale * widthScale, prop.scale)
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
        love.graphics.setColor(globalTextColor.r, globalTextColor.g, globalTextColor.b, prop.alpha)
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
        love.graphics.setColor(globalTextColor.r, globalTextColor.g, globalTextColor.b, prop.alpha)
        love.graphics.line(math.floor(x1), math.floor(y), math.floor(x2), math.floor(y))
    end

    if _Debug then
        self:drawDebug()
    end
end

---Draws debug information associated with this Text on the screen:
--- - When the text is drawn in the simple mode, a magenta line will be drawn above the text.
function Text:drawDebug()
    local pos = self:getPos()
    local prop = self.properties:getValues()

    local colors = {_COLORS.blue, _COLORS.green, _COLORS.red, _COLORS.gray}
    for i, chunk in ipairs(self.chunkData) do
        _SetColor(colors[i % 4 + 1], 0.5)
        love.graphics.rectangle("fill", pos.x + chunk.x, pos.y + chunk.y, chunk.width, chunk.height)
    end
end

---Executed whenever a mouse button has been pressed.
---This Widget's Node must not be disabled or invisible.
---Returns `true` if the input is consumed.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
---@param istouch boolean Whether the press is coming from a touch input.
---@param presses integer How many clicks have been performed in a short amount of time. Useful for double click checks.
---@return boolean
function Text:mousepressed(x, y, button, istouch, presses)
    --print(self.node:getName(), "mousepressed", x, y, button, istouch, presses)
    return false
end

---Executed whenever a mouse button is released.
---The button must have been pressed on this Widget's Node.
---The mouse cursor can be anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function Text:mousereleased(x, y, button)
    --print(self.node:getName(), "mousereleased", x, y, button)
end

---Executed whenever a mouse wheel has been scrolled.
---The mouse cursor must be hovering this Widget's Node.
---This Widget's Node must not be disabled or invisible.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function Text:wheelmoved(x, y)
    --print(self.node:getName(), "wheelmoved", x, y)
end

---Executed whenever a key is pressed on the keyboard.
---This Widget's Node must not be disabled or invisible.
---@param key string Code of the key that has been pressed.
function Text:keypressed(key)
    -- If the editing mode is active, check backspace.
    if self:getProp("editable") then
        if key == "backspace" then
            local offset = utf8.offset(self:getProp("text"), -1)
            if offset then
                self:setPropBase("text", self:getProp("text"):sub(1, offset - 1))
            end
            if self:getProp("signalOnInput") then
                _OnSignal(self:getProp("signalOnInput"))
            end
        elseif key == "return" and self:getProp("newlineShiftInput") == _IsShiftPressed() then
            self:setPropBase("text", self:getProp("text") .. "\n")
            if self:getProp("signalOnInput") then
                _OnSignal(self:getProp("signalOnInput"))
            end
        end
    end
end

---Executed whenever a certain character has been typed on the keyboard.
---This Widget's Node must not be disabled or invisible.
---@param text string The character.
function Text:textinput(text)
    -- If the editing mode is active, add the typed characters to the edited value.
    if self:getProp("editable") then
        self:setPropBase("text", self:getProp("text") .. text)
        if self:getProp("signalOnInput") then
            _OnSignal(self:getProp("signalOnInput"))
        end
    end
end

--######################################################--
---------------- S E R I A L I Z A T I O N ---------------
--######################################################--

---Returns the Text's data to be used for loading later.
---@return table
function Text:serialize()
    return self.properties:serialize()
end

return Text