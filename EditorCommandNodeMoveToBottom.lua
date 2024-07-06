local class = require "com.class"

---@class EditorCommandNodeMoveToBottom
---@overload fun(node):EditorCommandNodeMoveToBottom
local EditorCommandNodeMoveToBottom = class:derive("EditorCommandNodeMoveToBottom")

---Constructs a new Node Move To Bottom command.
---@param node Node The node that should be moved to the bottom in its hierarchy.
function EditorCommandNodeMoveToBottom:new(node)
    self.NAME = "NodeMoveToBottom"
    self.node = node
    self.previousIndex = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMoveToBottom:execute()
    if not self.node then
        return false
    end
    self.previousIndex = self.node:getSelfIndex()
    return self.node:moveSelfToBottom()
end

---Undoes this command.
function EditorCommandNodeMoveToBottom:undo()
    self.node:moveSelfToPosition(self.previousIndex)
end

return EditorCommandNodeMoveToBottom