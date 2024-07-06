local class = require "com.class"

---@class EditorCommandNodeSetParentAlign
---@overload fun(node, parentAlign):EditorCommandNodeSetParentAlign
local EditorCommandNodeSetParentAlign = class:derive("EditorCommandNodeSetParentAlign")

---Constructs a new Node Set Parent Align command.
---@param node Node The node that will have its parent align point changed.
---@param parentAlign Vector2 The new alignment.
function EditorCommandNodeSetParentAlign:new(node, parentAlign)
    self.NAME = "NodeSetParentAlign"
    self.node = node
    self.parentAlign = parentAlign
    self.oldParentAlign = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeSetParentAlign:execute()
    if not self.node then
        return false
    end
    self.oldParentAlign = self.node:getParentAlign()
    if self.parentAlign == self.oldParentAlign then
        return false
    end
    self.node:setParentAlign(self.parentAlign)
    return true
end

---Undoes this command.
function EditorCommandNodeSetParentAlign:undo()
    self.node:setParentAlign(self.oldParentAlign)
end

return EditorCommandNodeSetParentAlign