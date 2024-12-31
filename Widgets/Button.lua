local class = require "com.class"

---@class Button
---@overload fun(node, data):Button
local Button = class:derive("Button")

local Vec2 = require("Vector2")



---Creates a new Button.
---@param node Node The Node that this Button is attached to.
---@param data table The data to be used for this Button.
function Button:new(node, data)
    self.PROPERTY_LIST = {
        {name = "Text", key = "text", nodeKeys = {"textNode"}, type = "string"},
        {name = "Scale", key = "scale", nodeKeys = {"textNode", "spriteNode"}, type = "number"},
        {name = "Color", key = "color", nodeKeys = {"textNode"}, type = "color"}
    }

    self.node = node
    self.textNode = self.node:findChildByName("text")
    assert(self.textNode, string.format("Error in Button \"%s\": This Compound Widget must have a child Node with a Text Widget named \"text\" to work!", data.name))
    self.spriteNode = self.node:findChildByName("sprite")
    assert(self.spriteNode, string.format("Error in Button \"%s\": This Compound Widget must have a child Node with a Sprite Widget named \"sprite\" to work!", data.name))
end



---Returns the size of this Button.
---@return Vector2
function Button:getSize()
    return self.spriteNode.widget:getSize()
end



---Sets the size of this Button, except it doesn't. Don't even try!
---@param size Vector2 The new size of this Button.
function Button:setSize(size)
    error("You cannot resize a Button!")
end



---Returns whether this widget can be resized, i.e. squares will appear around that can be dragged.
---@return boolean
function Button:isResizable()
    return false
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



return Button