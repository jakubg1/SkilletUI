local class = require "com.class"

---@class InputText
---@overload fun(node, data):InputText
local InputText = class:derive("InputText")

local utf8 = require("utf8")
local Vec2 = require("Vector2")
local Color = require("Color")



---Creates a new InputText. This class is misleadingly named, as it currently allows editing strings, numbers, booleans, colors, keyboard shortcuts and more.
---@param node Node The Node that this InputText is attached to.
---@param data table? The data to be used for this InputText.
function InputText:new(node, data)
    self.node = node

    self.PROPERTY_LIST = {
        {name = "Size", key = "size", nodeKeys = {"spriteNode"}, type = "Vector2"},
        {name = "Text", key = "text", nodeKeys = {"textNode"}, type = "string"},
        {name = "Scale", key = "scale", nodeKeys = {"textNode", "spriteNode"}, type = "number"},
        {name = "Color", key = "color", nodeKeys = {"textNode"}, type = "color"},
        {name = "Nullable", key = "nullable", type = "boolean"}
    }

    self.textNode = self.node:findChildByName("text")
    assert(self.textNode, string.format("Error in InputText \"%s\": This Compound Widget must have a child Node with a Text Widget named \"text\" to work!", self.node:getName()))
    self.colorNode = self.node:findChildByName("color")
    assert(self.colorNode, string.format("Error in InputText \"%s\": This Compound Widget must have a child Node with a Box Widget named \"color\" to work!", self.node:getName()))
    self.spriteNode = self.node:findChildByName("sprite")
    assert(self.spriteNode, string.format("Error in InputText \"%s\": This Compound Widget must have a child Node with a Sprite Widget named \"sprite\" to work!", self.node:getName()))
    self.nullifyButtonNode = self.node:findChildByName("nullifyButton")
    assert(self.nullifyButtonNode, string.format("Error in InputText \"%s\": This Compound Widget must have a child Node with a Button Widget named \"nullifyButton\" to work!", self.node:getName()))
    self.nullifyButtonNode:setOnClick(function() self:setValue(nil) end)

    self.propertyKey = nil
    self.affectedType = nil
    self.type = "string"
    self.value = nil
    self.nullable = false
    self.minValue = nil
    self.maxValue = nil
    self.scrollStep = nil

    self.editText = nil
    self.active = false
end



---Returns the given property of this InputText.
---@param key string The property key.
---@return any?
function InputText:getProp(key)
    return self.textNode.widget.properties:getValue(key)
end



---Sets the given property of this InputText to a given value.
---@param key string The property key.
---@param value any? The property value.
function InputText:setProp(key, value)
    self.textNode.widget.properties:setValue(key, value)
    self.colorNode.widget.properties:setValue(key, value)
    self.spriteNode.widget.properties:setValue(key, value)
    self.nullifyButtonNode.widget.properties:setValue(key, value)
end



---Returns the given property base of this InputText.
---@param key string The property key.
---@return any?
function InputText:getPropBase(key)
    return self.textNode.widget.properties:getBaseValue(key)
end



---Sets the given property base of this InputText to a given value.
---@param key string The property key.
---@param value any? The property value.
function InputText:setPropBase(key, value)
    self.textNode.widget.properties:setBaseValue(key, value)
    self.colorNode.widget.properties:setBaseValue(key, value)
    self.spriteNode.widget.properties:setBaseValue(key, value)
    self.nullifyButtonNode.widget.properties:setBaseValue(key, value)
end



---Returns the current type of this InputText.
---@return string
function InputText:getType()
    return self.type
end



---Sets the current type of this InputText.
---The type determines the form of display and what happens when this Widget is clicked.
---Allowed values are: `"string"`, `"number"`, `"boolean"`, `"color"`, `"Vector2"`, `"Image"`, `"shortcut"`.
---@param type string The new type for this InputText.
function InputText:setType(type)
    self.type = type
    self:updateUI()
end



---Returns the current value of this InputText.
---@return any?
function InputText:getValue()
    return self.value
end



---Sets a new value of this InputText, or clears it if nothing is provided.
---This also changes the currently selected Node's (or its Widget's) property via a command that can be undone (optionally grouped).
---@param value any? The new value for this InputText.
---@param group boolean? If set, all calls from the same input field with this value set will be grouped. Used when scrolling or typing in text so that everything can be undone at once.
function InputText:setValue(value, group)
    if self.minValue then
        value = math.max(value, self.minValue)
    end
    if self.maxValue then
        value = math.min(value, self.maxValue)
    end
    self.value = value
    self:setAffectedEntityValue(value, group)
    self:updateUI()
end



---Sets a new value for the currently selected Node's (or its Widget's) property.
---@param value any? The new value for the property.
---@param group boolean? If set, all calls from the same input field with this value set will be grouped. Used when scrolling or typing in text so that everything can be undone at once.
function InputText:setAffectedEntityValue(value, group)
    if _EDITOR.selectedNode and self.propertyKey then
        if self.affectedType == "node" then
            _EDITOR:setSelectedNodeProperty(self.propertyKey, value, group and self.propertyKey or nil)
        elseif self.affectedType == "widget" then
            _EDITOR:setSelectedNodeWidgetProperty(self.propertyKey, value, group and self.propertyKey or nil)
        end
    end
end



---Returns the current value of this InputText as a string. If `value == nil`, returns an empty string.
---@return string
function InputText:getStringValue()
    if self.value == nil then
        return ""
    end
    if self.type == "string" then
        return self.value
    elseif self.type == "color" then
        return self.value:getHex()
    elseif self.type == "shortcut" then
        return _Utils.getShortcutString(self.value)
    else
        return tostring(self.value)
    end
end



---Parses the provided value from the string representation into the current type of this InputText, if possible.
---If not possible, returns `nil`.
---@param value string The string representation of the value to be converted.
---@return any?
function InputText:parseStringValue(value)
    if self.type == "string" then
        return value
    elseif self.type == "number" then
		return tonumber(value)
    elseif self.type == "color" then
        local success, result = pcall(function() return Color(value) end)
        if success then
            return result
        end
    end
end



---Sets a new value of this InputText, from the value provided as a string.
---If the provided value cannot be meaningfully converted, this function will return `false`.
---@param value string The string representation of the new value for this InputText.
---@param group boolean? If set, all calls from the same input field with this value set will be grouped. Used when scrolling or typing in text so that everything can be undone at once.
---@return boolean
function InputText:setStringValue(value, group)
    local result = self:parseStringValue(value)
    if result then
        self:setValue(result, group)
        return true
    end
    return false
end



---Activates the editing mode for this InputText.
function InputText:startEditing()
    if self.editText then
        return
    end
    self.editText = self:getStringValue()
    self:updateUI()
end



---Updates the changes on the layout, while keeping the editing mode active.
---If the input is correct, the changes will be committed as a command but as a part of a transaction, so it could still be undone.
---Otherwise, nothing will happen.
function InputText:progressEditing()
    local result = self:parseStringValue(self.editText)
    if result then
        self:setAffectedEntityValue(result, true)
    end
end



---Submits the changes.
---If the input is correct, the editing mode will be deactivated and changes applied.
---Otherwise, an error will be displayed and the input field will stay in the editing mode.
function InputText:submitEditing()
    local success = self:setStringValue(self.editText)
    if success then
        self:cancelEditing()
    else
        print("Incorrect input")
    end
end



---Deactivates the editing mode for this InputText without submitting the changes.
function InputText:cancelEditing()
    if not self.editText then
        return
    end
    self.editText = nil
    self:updateUI()
    -- Make sure to revert any progress that has been done during editing.
    if _EDITOR.commandMgr.transactionMode then
        _EDITOR.commandMgr:cancelCommandTransaction()
    end
end



---Updates the internal UI of this InputText. Call when fiddling with the Node's attributes.
function InputText:updateUI()
    if self.value ~= nil or self.editText then
        local textValue = self.editText or self:getStringValue()
        local color = _COLORS.white
        if self.value ~= nil then
            if self.type == "color" and self.value.r * 0.2 + self.value.g + self.value.b * 0.1 > 0.7 and self.value.r + self.value.b > self.value.g / 2 then
                color = _COLORS.black
            elseif self.type == "boolean" then
                color = self.value and _COLORS.green or _COLORS.red
            end
        end
        if self.node.disabled then
            color = _COLORS.gray
        end
        self.textNode:setText(textValue)
        self.textNode:setPos(Vec2(4, -1))
        self.textNode:setColor(color)
        self.textNode:setAlign(_ALIGNMENTS.left)
        self.textNode:setParentAlign(_ALIGNMENTS.left)
        self.textNode.widget:setProp("inputCaret", self.editText ~= nil)
        self.colorNode:setVisible(self.type == "color")
        if self.type == "color" then
            self.colorNode:setColor(self.value)
        end
        self.nullifyButtonNode:setVisible(self.nullable)
    else
        self.textNode:setText("<none>")
        self.textNode:setPos(Vec2(0, -1))
        self.textNode:setColor(_COLORS.gray)
        self.textNode:setAlign(_ALIGNMENTS.center)
        self.textNode:setParentAlign(_ALIGNMENTS.center)
        self.textNode.widget:setProp("inputCaret", false)
        self.nullifyButtonNode:setVisible(false)
    end
end



---Returns the size of this InputText.
---@return Vector2
function InputText:getSize()
    return self.spriteNode.widget:getSize()
end



---Sets the size of this InputText.
---@param size Vector2 The new size of this InputText.
function InputText:setSize(size)
    self.spriteNode:setSize(size)
end



---Returns the property list of this InputText.
---@return table
function InputText:getPropertyList()
    return self.PROPERTY_LIST
end



---Updates the InputText.
---@param dt number Time delta, in seconds.
function InputText:update(dt)
    -- no-op
end



---Draws the InputText on the screen.
function InputText:draw()
    -- no-op
end



---Executed whenever a mouse button has been pressed.
---This Widget's Node must not be disabled.
---Returns `true` if the input is consumed.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
---@param istouch boolean Whether the press is coming from a touch input.
---@param presses integer How many clicks have been performed in a short amount of time. Useful for double click checks.
---@return boolean
function InputText:mousepressed(x, y, button, istouch, presses)
    --print(self.node:getName(), "mousepressed", x, y, button, istouch, presses)
    local clicked = self.node:isHovered()
    self.active = clicked
    if clicked then
        if self.type == "boolean" then
            -- If this is a boolean field, just immediately flip the value instead.
            self:setValue(not self.value)
        elseif self.type == "string" or self.type == "number" then
            -- TODO: Colors, Shortcuts etc. use the legacy input method. Do something with this in 100,000 years.
            self:startEditing()
        end
        return true
    elseif self.editText then
        self:submitEditing()
        if self.editText then
            -- If we're here, our input has been rejected. Exit the edit mode without saving.
            self:cancelEditing()
        end
        return true
    end
    return false
end



---Executed whenever a mouse button is released.
---The button must have been pressed on this Widget's Node.
---The mouse cursor can be anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function InputText:mousereleased(x, y, button)
    --print(self.node:getName(), "mousereleased", x, y, button)
end



---Executed whenever a mouse wheel has been scrolled.
---The mouse cursor must be hovering this Widget's Node.
---This Widget's Node must not be disabled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function InputText:wheelmoved(x, y)
    --print(self.node:getName(), "wheelmoved", x, y)
    -- If the input box allows scrolling the value, handle it here.
    if self.scrollStep then
        local multiple = self.value / self.scrollStep
        local newValue
        if _Utils.almostEqual(self.value, self.scrollStep * math.floor(multiple + 0.5)) then
            -- We have an exact multiple, bring it up or down one multiple.
            newValue = self.scrollStep * (math.floor(multiple + 0.5) + y)
        else
            -- Bring it to the exact multiple first.
            if y > 0 then
                newValue = self.scrollStep * (math.ceil(multiple) + y - 1)
            else
                newValue = self.scrollStep * (math.floor(multiple) + y + 1)
            end
        end
        self:setValue(newValue, true)
    end
    -- If the input is a boolean value, make it `true` if scrolling up and `false` if scrolling down.
    if self.type == "boolean" then
        local newValue = y > 0
        if self.value ~= newValue then
            self:setValue(newValue, true)
        end
    end
end



---Executed whenever a key is pressed on the keyboard.
---This Widget's Node must not be disabled.
---@param key string Code of the key that has been pressed.
function InputText:keypressed(key)
    --print(self.node:getName(), "keypressed", key)
    -- If the editing mode is active, check some keys.
    if self.editText then
        if key == "backspace" then
            local offset = utf8.offset(self.editText, -1)
            if offset then
                self.editText = self.editText:sub(1, offset - 1)
                self:updateUI()
                self:progressEditing()
            end
        elseif key == "return" then
            self:submitEditing()
        elseif key == "escape" then
            self:cancelEditing()
        end
    end
end



---Executed whenever a certain character has been typed on the keyboard.
---This Widget's Node must not be disabled.
---@param text string The character.
function InputText:textinput(text)
    --print(self.node:getName(), "textinput", text)
    -- If the editing mode is active, add the typed characters to the edited value.
    if self.editText then
        self.editText = self.editText .. text
        self:updateUI()
        self:progressEditing()
    end
end



---Returns the InputText's data to be used for loading later.
---InputTexts are only ever intended for internal use, and as such are not serializable.
---@return nil
function InputText:serialize()
    -- no-op
end



return InputText