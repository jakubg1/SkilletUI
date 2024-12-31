local class = require "com.class"

---@class EditorCommandNodeMoveToIndex
---@overload fun(node, index):EditorCommandNodeMoveToIndex
local EditorCommandNodeMoveToIndex = class:derive("EditorCommandNodeMoveToIndex")

---Constructs a new Node Move To Index command.
---@param node Node The node that should be moved to the specified index in its hierarchy.
---@param index integer The index this node should be moved to.
function EditorCommandNodeMoveToIndex:new(node, index)
    self.NAME = "NodeMoveToIndex"
    self.node = node
    self.index = index
    self.previousIndex = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMoveToIndex:execute()
    if not self.node then
        return false
    end
    self.previousIndex = self.node:getSelfIndex()
    return self.node:moveSelfToPosition(self.index)
end

---Undoes this command.
function EditorCommandNodeMoveToIndex:undo()
    self.node:moveSelfToPosition(self.previousIndex)
end

return EditorCommandNodeMoveToIndex