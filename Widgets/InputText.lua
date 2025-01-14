local class = require "com.class"

---@class InputText
---@overload fun(node, data):InputText
local InputText = class:derive("InputText")

local Vec2 = require("Vector2")



---Creates a new InputText.
---@param node Node The Node that this InputText is attached to.
---@param data table? The data to be used for this InputText.
function InputText:new(node, data)
    self.PROPERTY_LIST = {
        {name = "Size", key = "size", nodeKeys = {"spriteNode"}, type = "Vector2"},
        {name = "Text", key = "text", nodeKeys = {"textNode"}, type = "string"},
        {name = "Scale", key = "scale", nodeKeys = {"textNode", "spriteNode"}, type = "number"},
        {name = "Color", key = "color", nodeKeys = {"textNode"}, type = "color"},
        {name = "Nullable", key = "nullable", type = "boolean"}
    }
    data = data or {}

    self.node = node
    self.textNode = self.node:findChildByName("text")
    assert(self.textNode, string.format("Error in InputText \"%s\": This Compound Widget must have a child Node with a Text Widget named \"text\" to work!", self.node.name))
    self.colorNode = self.node:findChildByName("color")
    assert(self.colorNode, string.format("Error in InputText \"%s\": This Compound Widget must have a child Node with a Box Widget named \"color\" to work!", self.node.name))
    self.spriteNode = self.node:findChildByName("sprite")
    assert(self.spriteNode, string.format("Error in InputText \"%s\": This Compound Widget must have a child Node with a Sprite Widget named \"sprite\" to work!", self.node.name))
    self.nullifyButtonNode = self.node:findChildByName("nullifyButton")
    assert(self.nullifyButtonNode, string.format("Error in InputText \"%s\": This Compound Widget must have a child Node with a Button Widget named \"nullifyButton\" to work!", self.node.name))

    self.type = "string"
    self.value = nil
    self.nullable = false
end



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
---@param value any? The new value for this InputText.
function InputText:setValue(value)
    self.value = value
    self:updateUI()
end



---Updates the internal UI of this InputText. Call when fiddling with the Node's attributes.
function InputText:updateUI()
    if self.value ~= nil then
        local textValue = "ERROR"
        local showColor = false
        local darkColorText = false
        if self.type == "string" then
            textValue = self.value
        elseif self.type == "color" then
            textValue = self.value:getHex()
            showColor = true
            darkColorText = self.value.r * 0.2 + self.value.g + self.value.b * 0.1 > 0.7 and self.value.r + self.value.b > self.value.g / 2
        elseif self.type == "shortcut" then
            textValue = _Utils.getShortcutString(self.value)
        else
            textValue = tostring(self.value)
        end
        self.textNode:setText(textValue)
        self.textNode:setPos(Vec2(4, -1))
        self.textNode:setColor(self.node.disabled and _COLORS.gray or (darkColorText and _COLORS.black or _COLORS.white))
        self.textNode:setAlign(_ALIGNMENTS.left)
        self.textNode:setParentAlign(_ALIGNMENTS.left)
        self.colorNode:setVisible(showColor)
        if showColor then
            self.colorNode:setColor(self.value)
        end
        self.nullifyButtonNode:setVisible(self.nullable)
    else
        self.textNode:setText("<none>")
        self.textNode:setPos(Vec2(0, -1))
        self.textNode:setColor(_COLORS.gray)
        self.textNode:setAlign(_ALIGNMENTS.center)
        self.textNode:setParentAlign(_ALIGNMENTS.center)
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



---Returns the InputText's data to be used for loading later.
---@return nil
function InputText:serialize()
    -- no-op
end



return InputText