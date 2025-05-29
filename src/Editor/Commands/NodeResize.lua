local EditorCommand = require("src.Editor.Commands.EditorCommand")

---@class EditorCommandNodeResize : EditorCommand
---@overload fun(nodeList): EditorCommandNodeResize
local EditorCommandNodeResize = EditorCommand:derive("EditorCommandNodeResize")

---Constructs a new Node Resize command. This is a special command which is pushed onto the stack once the resizing has been **finished**.
---@param nodeList NodeList The list of nodes that have been resized.
function EditorCommandNodeResize:new(nodeList)
    self.NAME = "NodeResize"
    self.nodeList = nodeList:copy()
    self.startPos = nil
    self.startSize = nil
    self.targetPos = nil
    self.targetSize = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeResize:execute()
    if self.nodeList:getSize() == 0 then
        return false
    end
    if not self.startPos or not self.startSize or not self.targetPos or not self.targetSize then
        -- First time. Finish the resize process.
        self.startPos = self.nodeList:bulkGetPropBase("pos")
        self.startSize = self.nodeList:bulkGetWidgetPropBase("size")
        local result = self.nodeList:bulkFinishResize()
        if not result then
            return false
        end
        self.targetPos = self.nodeList:bulkGetPropBase("pos")
        self.targetSize = self.nodeList:bulkGetWidgetPropBase("size")
    else
        -- Subsequent times (we are doing a redo).
        self.nodeList:bulkSetPropBase("pos", self.targetPos)
        self.nodeList:bulkSetWidgetPropBase("size", self.targetSize)
    end
    return true
end

---Undoes this command.
function EditorCommandNodeResize:undo()
    self.nodeList:bulkSetPropBase("pos", self.startPos)
    self.nodeList:bulkSetWidgetPropBase("size", self.startSize)
end

return EditorCommandNodeResize