local EditorCommand = require("src.Editor.Commands.EditorCommand")

---@class EditorCommandNodeMoveUp : EditorCommand
---@overload fun(nodeList): EditorCommandNodeMoveUp
local EditorCommandNodeMoveUp = EditorCommand:derive("EditorCommandNodeMoveUp")

---Constructs a new Node Move Up command.
---**WARNING!** This command works correctly ONLY if the node list is sorted by the tree order.
---And it still breaks sometimes, but that will require insane work to make it work always properly...
---@param nodeList NodeList The list of nodes that should be moved up in its hierarchy.
function EditorCommandNodeMoveUp:new(nodeList)
    self.NAME = "NodeMoveUp"
    self.nodeList = nodeList:copy()
    self.previousIndexes = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMoveUp:execute()
    if self.nodeList:getSize() == 0 then
        return false
    end
    self.previousIndexes = self.nodeList:bulkGetSelfIndexes()
    return self.nodeList:bulkMoveUp()
end

---Undoes this command.
function EditorCommandNodeMoveUp:undo()
    self.nodeList:bulkMoveToIndexes(self.previousIndexes)
end

return EditorCommandNodeMoveUp