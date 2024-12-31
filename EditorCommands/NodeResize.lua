local class = require "com.class"

---@class EditorCommandNodeResize
---@overload fun(node, startPos, startSize):EditorCommandNodeResize
local EditorCommandNodeResize = class:derive("EditorCommandNodeResize")

---Constructs a new Node Resize command. This is a special command which is pushed onto the stack once the resizing has been FINISHED.
---@param node Node The node that has been resized.
---@param startPos Vector2 The starting position of the Node.
---@param startSize Vector2 The starting size of this Node.
function EditorCommandNodeResize:new(node, startPos, startSize)
    self.NAME = "NodeResize"
    self.node = node
    self.startPos = startPos
    self.startSize = startSize
    self.targetPos = nil
    self.targetSize = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeResize:execute()
    if not self.node then
        return false
    end
    if not self.targetPos then
        self.targetPos = self.node:getPos()
    end
    if not self.targetSize then
        self.targetSize = self.node:getSize()
    end
    if self.startPos == self.targetPos and self.startSize == self.targetSize then
        return false
    end
    self.node:setPos(self.targetPos)
    self.node:setSize(self.targetSize)
    return true
end

---Undoes this command.
function EditorCommandNodeResize:undo()
    self.node:setPos(self.startPos)
    self.node:setSize(self.startSize)
end

return EditorCommandNodeResize