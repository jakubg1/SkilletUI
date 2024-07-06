local class = require "com.class"

---@class EditorCommandNodeSetParent
---@overload fun(node, parent):EditorCommandNodeSetParent
local EditorCommandNodeSetParent = class:derive("EditorCommandNodeSetParent")

---Constructs a new Node Set Parent command.
---@param node Node The node that will have its parent changed.
---@param parent Node The new parent.
function EditorCommandNodeSetParent:new(node, parent)
    self.NAME = "NodeSetParent"
    self.node = node
    self.parent = parent
    self.oldParent = nil
    self.oldIndex = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeSetParent:execute()
    if not self.node or not self.parent then
        return false
    end
    self.oldParent = self.node.parent
    self.oldIndex = self.node:getSelfIndex()
    if self.parent == self.oldParent then
        return false
    end
    self.parent:addChild(self.node)
    return true
end

---Undoes this command.
function EditorCommandNodeSetParent:undo()
    self.oldParent:addChild(self.node, self.oldIndex)
end

return EditorCommandNodeSetParent