local class = require "com.class"

---@class EditorCommandNodeSetProperty
---@overload fun(node, property, value):EditorCommandNodeSetProperty
local EditorCommandNodeSetProperty = class:derive("EditorCommandNodeSetProperty")

---Constructs a new Node Set Property command.
---@param node Node The node that will have its property changed.
---@param property string The property that will be changed.
---@param value any? The new value for the property.
function EditorCommandNodeSetProperty:new(node, property, value)
    self.NAME = "NodeSetProperty"
    self.node = node
    self.property = property
    self.value = value
    self.oldValue = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeSetProperty:execute()
    if not self.node or not self.property then
        return false
    end
    self.oldValue = self.node:getPropBase(self.property)
    if self.value == self.oldValue then
        return false
    end
    self.node:setPropBase(self.property, self.value)
    return true
end

---Undoes this command.
function EditorCommandNodeSetProperty:undo()
    self.node:setPropBase(self.property, self.oldValue)
end

return EditorCommandNodeSetProperty