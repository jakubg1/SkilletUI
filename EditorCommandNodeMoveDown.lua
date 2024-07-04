local class = require "com.class"

---@class EditorCommandNodeMoveDown
---@overload fun(node):EditorCommandNodeMoveDown
local EditorCommandNodeMoveDown = class:derive("EditorCommandNodeMoveDown")



---Constructs a new Node Move Down command.
---@param node Node The node that should be moved up in its hierarchy.
function EditorCommandNodeMoveDown:new(node)
    self.NAME = "NodeMoveDown"
    self.node = node
end



---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMoveDown:execute()
    if not self.node then
        return false
    end
    return self.node:moveSelfDown()
end



---Undoes this command.
function EditorCommandNodeMoveDown:undo()
    self.node:moveSelfUp()
end



return EditorCommandNodeMoveDown