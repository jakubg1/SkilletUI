local class = require "com.class"

---@class Button
---@overload fun(node, data):Button
local Button = class:derive("Button")



---Creates a new Button.
---@param node Node The Node that this Button is attached to.
---@param data table? The data to be used for this Button.
function Button:new(node, data)
    self.node = node

    self.PROPERTY_LIST = {
        {name = "Size", key = "size", nodeKeys = {"spriteNode"}, type = "Vector2"},
        {name = "Text", key = "text", nodeKeys = {"textNode"}, type = "string"},
        {name = "Scale", key = "scale", nodeKeys = {"textNode", "spriteNode"}, type = "number"},
        {name = "Color", key = "color", nodeKeys = {"textNode"}, type = "color"}
    }

    self.textNode = self.node:findChildByName("text")
    assert(self.textNode, string.format("Error in Button \"%s\": This Compound Widget must have a child Node with a Text Widget named \"text\" to work!", self.node.name))
    self.spriteNode = self.node:findChildByName("sprite")
    assert(self.spriteNode, string.format("Error in Button \"%s\": This Compound Widget must have a child Node with a Sprite Widget named \"sprite\" to work!", self.node.name))
end



---Returns the given property of this Button.
---@param key string The property key.
---@return any?
function Button:getProp(key)
    return self.textNode.widget.properties:getValue(key)
end



---Sets the given property of this Button to a given value.
---@param key string The property key.
---@param value any? The property value.
function Button:setProp(key, value)
    self.textNode.widget.properties:setValue(key, value)
    self.spriteNode.widget.properties:setValue(key, value)
end



---Returns the given property base of this Button.
---@param key string The property key.
---@return any?
function Button:getPropBase(key)
    return self.textNode.widget.properties:getBaseValue(key)
end



---Sets the given property base of this Button to a given value.
---@param key string The property key.
---@param value any? The property value.
function Button:setPropBase(key, value)
    self.textNode.widget.properties:setBaseValue(key, value)
    self.spriteNode.widget.properties:setBaseValue(key, value)
end



---Returns the size of this Button.
---@return Vector2
function Button:getSize()
    return self.spriteNode.widget:getSize()
end



---Sets the size of this Button.
---@param size Vector2 The new size of this Button.
function Button:setSize(size)
    self.spriteNode:setSize(size)
end



---Returns the property list of this Button.
---@return table
function Button:getPropertyList()
    return self.PROPERTY_LIST
end



---Updates the Button.
---@param dt number Time delta, in seconds.
function Button:update(dt)
    -- no-op
end



---Draws the Button on the screen.
function Button:draw()
    -- no-op
end



---Returns the Button's data to be used for loading later.
---@return nil
function Button:serialize()
    -- no-op
end



return Button