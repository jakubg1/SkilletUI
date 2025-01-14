local class = require "com.class"

---@class EditorCommandNodeSetWidgetProperty
---@overload fun(node, property, value):EditorCommandNodeSetWidgetProperty
local EditorCommandNodeSetWidgetProperty = class:derive("EditorCommandNodeSetWidgetProperty")

---Constructs a new Node Set Widget Property command.
---@param node Node The node that will have its widget's property changed.
---@param property string The property that will be changed.
---@param value any? The new value for the property.
function EditorCommandNodeSetWidgetProperty:new(node, property, value)
    self.NAME = "NodeSetWidgetProperty"
    self.node = node
    self.property = property
    self.value = value
    self.oldValue = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeSetWidgetProperty:execute()
    if not self.node or not self.property then
        return false
    end
    self.oldValue = self.node.widget:getPropBase(self.property)
    if self.value == self.oldValue then
        return false
    end
    self.node.widget:setPropBase(self.property, self.value)
    return true
end

---Undoes this command.
function EditorCommandNodeSetWidgetProperty:undo()
    self.node.widget:setPropBase(self.property, self.oldValue)
end

return EditorCommandNodeSetWidgetProperty