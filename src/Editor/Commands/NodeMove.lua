local EditorCommand = require("src.Editor.Commands.EditorCommand")

---@class EditorCommandNodeMove : EditorCommand
---@overload fun(nodeList, offset): EditorCommandNodeMove
local EditorCommandNodeMove = EditorCommand:derive("EditorCommandNodeMove")

---Constructs a new Node Move command.
---@param nodeList NodeList The node that should be moved.
---@param offset Vector2 The movement vector.
function EditorCommandNodeMove:new(nodeList, offset)
    self.NAME = "NodeMove"
    self.nodeList = nodeList:copy()
    self.offset = offset
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMove:execute()
    if self.nodeList:getSize() == 0 then
        return false
    end
    for i, node in ipairs(self.nodeList:getNodes()) do
        node:setPos(node:getPos() + self.offset)
    end
    return true
end

---Undoes this command.
function EditorCommandNodeMove:undo()
    for i, node in ipairs(self.nodeList:getNodes()) do
        node:setPos(node:getPos() - self.offset)
    end
end

return EditorCommandNodeMove