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

    -- Text Widgets store 3 different formats of text:
    -- - Raw text (`text` property)
    -- - Processed text (`text` with stripped formatting or as-is if formatting is disabled)
    -- - Character data (a list of characters with formatting applied or `nil` if formatting is disabled)
    -- - Escapes like `\n` and `\\` are always processed, `<...>` formatting marks are processed only if formatting is enabled.
    --
    -- Example:
    --                      FORMATTING DISABLED                         FORMATTING ENABLED
    --  RAW TEXT            PROCESSED TEXT      CHARACTER DATA          PROCESSED TEXT      CHARACTER DATA
    --  Color               Color               nil                     Color               {...}
    --  <blue>Color         <blue>Color         nil                     Color               {...}
    --  One!\nTwo!          One!                nil                     One!                {...}
    --                      Two!                                        Two!
    --  <b>One!\n</>Two!    <b>One!             nil                     One!                {...}
    --                      </>Two!                                     Two!
    --
    self.characterData = nil
    self.processedText = nil
    self.textSize = Vec2()
    self:generateCharacterData()
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
    self:generateCharacterData()
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
    self:generateCharacterData()
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

---Returns the actual raw text (but stripped from the formatting tags) that is visible on this Widget.
---It can differ from the real text if the `typeInProgress` or `inputCaret` properties are set.
---@return string
function Text:getText()
    local prop = self.properties:getValues()
    local caret = (prop.inputCaret and _Time % 1 < 0.5) and "|" or ""
    if not prop.typeInProgress then
        return self.processedText .. caret
    end
    local totalCharsRendered = math.floor(_Utils.interpolateClamped(0, utf8.len(self.processedText), prop.typeInProgress))
    return self.processedText:sub(0, utf8.offset(self.processedText, totalCharsRendered + 1) - 1) .. caret
end

---Returns the text (not the actual text, this function is unaffected by the `typeInProgress` property!) split into characters, with UTF-8 support.
---@return table
function Text:getTextCharacters()
    local text = self:getProp("text")
    local characters = {}
    for i = 1, utf8.len(text) do
        table.insert(characters, text:sub(utf8.offset(text, i), utf8.offset(text, i + 1) - 1))
    end
    return characters
end

---Returns `true` if the Text can be rendered as a whole batch, instead of having to be drawn character by character.
---@return boolean
function Text:isSimpleRendered()
    local prop = self.properties:getValues()
    -- Check if any of the properties which require changing the character drawing positions are not default.
    if prop.waveAmplitude or prop.gradientWaveColor or prop.characterSeparation ~= 0 or prop.boldness ~= 1 then
        return false
    end
    -- Check if there are any formatting marks in the text.
    if prop.formatted then
        local characters = self:getTextCharacters()
        local escape = false
        local formattingOpen = false
        for i, char in ipairs(characters) do
            if not escape then
                if char == "<" then
                    -- An unescaped opening formatting mark found.
                    formattingOpen = true
                elseif char == ">" and formattingOpen then
                    -- An unescaped closing formatting mark found. It's game over.
                    return false
                end
            end
            -- Handle escaped characters.
            if not escape and char == "\\" then
                escape = true
            else
                escape = false
            end
        end
    end
    return true
end

---Generates character data for this Text, or removes it, if this Text can be drawn in the simple mode.
---Also updates the text size.
function Text:generateCharacterData()
    local prop = self.properties:getValues()
    local lineHeight = prop.font:getHeight() * prop.scale
    if self:isSimpleRendered() then
        self.characterData = nil
        self.processedText = self:getProp("text")
        local w = (prop.font:getWidth(self.processedText) - 1) * prop.scale + self:getEffectiveCharacterSeparation() * (utf8.len(self.processedText) - 1) + prop.boldness - 1
        self.textSize = Vec2(math.max(w, 0), lineHeight)
        return
    end

    self.characterData = {}
    self.processedText = ""

    local characters = self:getTextCharacters()
    local x, y = 0, 0
    local color = prop.color
    local boldness = prop.boldness
    -- Formatting variables
    local escape = false
    local formattingContent = nil
    for i, char in ipairs(characters) do
        local draw = true

        if prop.formatted then
            -- Parse formatting characters.
            if not escape then
                if char == "<" then
                    -- An unescaped opening formatting mark found. Start parsing the contents.
                    formattingContent = ""
                    draw = false
                elseif formattingContent then
                    if char == ">" then
                        -- An unescaped closing formatting mark found. Stop parsing and apply the contents.
                        if formattingContent:sub(1, 1) ~= "/" then
                            -- Starting mark.
                            if _COLORS[formattingContent] then
                                color = _COLORS[formattingContent] -- Color name
                            elseif (formattingContent:len() == 4 or formattingContent:len() == 7) and formattingContent:sub(1, 1) == "#" then
                                color = Color(formattingContent:sub(2)) -- Color hex code (#rgb or #rrggbb)
                            elseif formattingContent == "b" then
                                boldness = 2 -- Bold
                            end
                        else
                            -- Ending mark.
                            formattingContent = formattingContent:sub(2)
                            if formattingContent == "" then
                                -- Reset everything to default.
                                color = prop.color
                                boldness = prop.boldness
                            elseif formattingContent == "#" then
                                color = prop.color -- Reset color
                            elseif formattingContent == "b" then
                                boldness = prop.boldness -- Reset boldness
                            end
                        end
                        formattingContent = nil
                    else
                        formattingContent = formattingContent .. char
                    end
                    draw = false
                end
            end
            -- Handle escaped characters.
            if not escape and char == "\\" and i < #characters then
                escape = true
                -- Don't draw the backslash if it escapes something.
                draw = false
            else
                escape = false
            end
        end

        -- Insert the character if eligible.
        if draw then
            local character = {
                char = char,
                x = math.floor(x + 0.5),
                y = math.floor(y + 0.5) + (_Debug and math.random(-1, 1) or 0),
                scaleX = prop.scale,
                scaleY = prop.scale,
                color = color,
                boldness = boldness
            }
            table.insert(self.characterData, character)
            self.processedText = self.processedText .. char
            x = x + prop.font:getWidth(char) * prop.scale + prop.characterSeparation + boldness - 1
        end
    end
    self.textSize = Vec2(math.max(x - 1, 0), lineHeight)
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
    local text = self:getText()
    local prop = self.properties:getValues()

    love.graphics.setFont(prop.font.font)

    local globalTextColor = prop.color
    if prop.hoverColor and self.node:isHovered() then
        globalTextColor = prop.hoverColor
    end

    if self.characterData then
        -- Character by character
        for i, char in ipairs(self.characterData) do
            local animOffset = char.x - pos.x
            local charY = char.y
            if prop.waveFrequency and prop.waveAmplitude and prop.waveSpeed then
                charY = charY + _Utils.getWavePoint(prop.waveFrequency, prop.waveSpeed, animOffset, _Time) * prop.waveAmplitude
            end
            local charColor = char.color
            if prop.hoverColor and self.node:isHovered() then
                charColor = prop.hoverColor
            end
            if prop.gradientWaveFrequency and prop.gradientWaveColor then
                local t
                if prop.gradientWaveSpeed then
                    t = (_Utils.getWavePoint(prop.gradientWaveFrequency, prop.gradientWaveSpeed, animOffset, _Time) + 1) / 2
                else
                    t = (_Utils.getWavePoint(1 / prop.gradientWaveFrequency, 1, 0, _Time) + 1) / 2
                end
                charColor = _Utils.interpolate(charColor, prop.gradientWaveColor, t)
            end

            if prop.shadowOffset then
                for j = 1, char.boldness do
                    local bx = j - 1
                    love.graphics.setColor(0, 0, 0, prop.alpha * prop.shadowAlpha)
                    love.graphics.print(char.char, pos.x + char.x * widthScale + bx + prop.shadowOffset.x, pos.y + charY + prop.shadowOffset.y, 0, char.scaleX * widthScale, char.scaleY)
                end
            end
            for j = 1, char.boldness do
                local bx = j - 1
                love.graphics.setColor(charColor.r, charColor.g, charColor.b, prop.alpha)
                love.graphics.print(char.char, pos.x + char.x * widthScale + bx, pos.y + charY, 0, char.scaleX * widthScale, char.scaleY)
            end
        end
    else
        -- Optimize drawing if there are no effects which require drawing each character separately.
        if prop.shadowOffset then
            love.graphics.setColor(0, 0, 0, prop.alpha * prop.shadowAlpha)
            love.graphics.print(text, math.floor(pos.x + prop.shadowOffset.x + 0.5), math.floor(pos.y + prop.shadowOffset.y + 0.5), 0, prop.scale * widthScale, prop.scale)
        end
        love.graphics.setColor(globalTextColor.r, globalTextColor.g, globalTextColor.b, prop.alpha)
        love.graphics.print(text, math.floor(pos.x + 0.5), math.floor(pos.y + 0.5), 0, prop.scale * widthScale, prop.scale)
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

    if not self.characterData then
        local size = self:getSize()
        local x1 = pos.x + 0.5
        local x2 = pos.x + size.x + 0.5
        local y = pos.y + 0.5
        love.graphics.setLineWidth(prop.scale)
        love.graphics.setColor(1, 0, 0.5, prop.alpha)
        love.graphics.line(math.floor(x1), math.floor(y), math.floor(x2), math.floor(y))
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