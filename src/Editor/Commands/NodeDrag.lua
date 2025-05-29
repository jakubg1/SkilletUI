local EditorCommand = require("src.Editor.Commands.EditorCommand")

---@class EditorCommandNodeDrag : EditorCommand
---@overload fun(nodeList): EditorCommandNodeDrag
local EditorCommandNodeDrag = EditorCommand:derive("EditorCommandNodeDrag")

---Constructs a new Node Drag command. This is a special command which is pushed onto the stack once the dragging has been **finished**.
---@param nodeList NodeList The list of nodes that have been dragged.
function EditorCommandNodeDrag:new(nodeList)
    self.NAME = "NodeDrag"
    self.nodeList = nodeList:copy()
    self.startPos = nil
    self.targetPos = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeDrag:execute()
    if self.nodeList:getSize() == 0 then
        return false
    end
    if not self.startPos or not self.targetPos then
        -- First time. Finish the dragging process.
        self.startPos = self.nodeList:bulkGetPropBase("pos")
        local result = self.nodeList:bulkFinishDrag()
        if not result then
            return false
        end
        self.targetPos = self.nodeList:bulkGetPropBase("pos")
    else
        -- Subsequent times (we are doing a redo).
        self.nodeList:bulkSetPropBase("pos", self.targetPos)
    end
    return true
end

---Undoes this command.
function EditorCommandNodeDrag:undo()
    self.nodeList:bulkSetPropBase("pos", self.startPos)
end

return EditorCommandNodeDrag