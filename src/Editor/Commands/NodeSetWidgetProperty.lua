local class = require "com.class"

---@class EditorCommandNodeSetWidgetProperty
---@overload fun(nodeList, property, value):EditorCommandNodeSetWidgetProperty
local EditorCommandNodeSetWidgetProperty = class:derive("EditorCommandNodeSetWidgetProperty")

---Constructs a new Node Set Widget Property command.
---@param nodeList NodeList The list of nodes that will have their widgets' property changed.
---@param property string The property that will be changed.
---@param value any? The new value for the property.
function EditorCommandNodeSetWidgetProperty:new(nodeList, property, value)
    self.NAME = "NodeSetWidgetProperty"
    self.nodeList = nodeList:copy()
    self.property = property
    self.value = value
    self.oldValues = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeSetWidgetProperty:execute()
    if self.nodeList:getSize() == 0 or not self.property then
        return false
    end
    self.oldValues = self.nodeList:bulkGetWidgetPropBase(self.property)
    return self.nodeList:bulkSetWidgetPropBaseSingle(self.property, self.value)
end

---Undoes this command.
function EditorCommandNodeSetWidgetProperty:undo()
    self.nodeList:bulkSetWidgetPropBase(self.property, self.oldValues)
end

return EditorCommandNodeSetWidgetProperty