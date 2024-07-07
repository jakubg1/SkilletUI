local class = require "com.class"

---@class EditorCommandNodeMoveUp
---@overload fun(node):EditorCommandNodeMoveUp
local EditorCommandNodeMoveUp = class:derive("EditorCommandNodeMoveUp")

---Constructs a new Node Move Up command.
---@param node Node The node that should be moved up in its hierarchy.
function EditorCommandNodeMoveUp:new(node)
    self.NAME = "NodeMoveUp"
    self.node = node
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMoveUp:execute()
    if not self.node then
        return false
    end
    return self.node:moveSelfUp()
end

---Undoes this command.
function EditorCommandNodeMoveUp:undo()
    self.node:moveSelfDown()
end

return EditorCommandNodeMoveUp