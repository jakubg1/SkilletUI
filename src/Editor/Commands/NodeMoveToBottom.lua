local EditorCommand = require("src.Editor.Commands.EditorCommand")

---@class EditorCommandNodeMoveToBottom : EditorCommand
---@overload fun(nodeList): EditorCommandNodeMoveToBottom
local EditorCommandNodeMoveToBottom = EditorCommand:derive("EditorCommandNodeMoveToBottom")

---Constructs a new Node Move To Bottom command.
---**WARNING!** This command works correctly ONLY if the node list is sorted by the tree order.
---And it still breaks sometimes, but that will require insane work to make it work always properly...
---@param nodeList NodeList The list of nodes that should be moved to the bottom in their hierarchy.
function EditorCommandNodeMoveToBottom:new(nodeList)
    self.NAME = "NodeMoveToBottom"
    self.nodeList = nodeList:copy()
    self.previousIndexes = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMoveToBottom:execute()
    if self.nodeList:getSize() == 0 then
        return false
    end
    self.previousIndexes = self.nodeList:bulkGetSelfIndexes()
    return self.nodeList:bulkMoveToBottom()
end

---Undoes this command.
function EditorCommandNodeMoveToBottom:undo()
    self.nodeList:bulkMoveToIndexes(self.previousIndexes)
end

return EditorCommandNodeMoveToBottom