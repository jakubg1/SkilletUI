local class = require "com.class"

---@class EditorCommandNodeMove
---@overload fun(node, offset):EditorCommandNodeMove
local EditorCommandNodeMove = class:derive("EditorCommandNodeMove")



---Constructs a new Node Move command.
---@param node Node The node that should be moved.
---@param offset Vector2 The movement vector.
function EditorCommandNodeMove:new(node, offset)
    self.NAME = "NodeMove"
    self.node = node
    self.offset = offset
end



---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMove:execute()
    if not self.node then
        return false
    end
    self.node:setPos(self.node:getPos() + self.offset)
    return true
end



---Undoes this command.
function EditorCommandNodeMove:undo()
    self.node:setPos(self.node:getPos() - self.offset)
end



return EditorCommandNodeMove