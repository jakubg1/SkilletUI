local class = require "com.class"

---@class EditorCommandNodeDrag
---@overload fun(node, startPos):EditorCommandNodeDrag
local EditorCommandNodeDrag = class:derive("EditorCommandNodeDrag")

---Constructs a new Node Drag command. This is a special command which is pushed onto the stack once the dragging has been FINISHED.
---@param node Node The node that has been dragged.
---@param startPos Vector2 The starting position of the Node.
function EditorCommandNodeDrag:new(node, startPos)
    self.NAME = "NodeDrag"
    self.node = node
    self.startPos = startPos
    self.targetPos = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeDrag:execute()
    if not self.node then
        return false
    end
    if not self.targetPos then
        self.targetPos = self.node:getPos()
    end
    if self.startPos == self.targetPos then
        return false
    end
    self.node:setPos(self.targetPos)
    return true
end

---Undoes this command.
function EditorCommandNodeDrag:undo()
    self.node:setPos(self.startPos)
end

return EditorCommandNodeDrag