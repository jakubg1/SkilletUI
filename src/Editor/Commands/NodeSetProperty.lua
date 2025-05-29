local EditorCommand = require("src.Editor.Commands.EditorCommand")

---@class EditorCommandNodeSetProperty : EditorCommand
---@overload fun(nodeList, property, value): EditorCommandNodeSetProperty
local EditorCommandNodeSetProperty = EditorCommand:derive("EditorCommandNodeSetProperty")

---Constructs a new Node Set Property command.
---@param nodeList NodeList The list of nodes that will have their property changed.
---@param property string The property that will be changed.
---@param value any? The new value for the property.
function EditorCommandNodeSetProperty:new(nodeList, property, value)
    self.NAME = "NodeSetProperty"
    self.nodeList = nodeList:copy()
    self.property = property
    self.value = value
    self.oldValues = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeSetProperty:execute()
    if self.nodeList:getSize() == 0 or not self.property then
        return false
    end
    self.oldValues = self.nodeList:bulkGetPropBase(self.property)
    return self.nodeList:bulkSetPropBaseSingle(self.property, self.value)
end

---Undoes this command.
function EditorCommandNodeSetProperty:undo()
    self.nodeList:bulkSetPropBase(self.property, self.oldValues)
end

return EditorCommandNodeSetProperty