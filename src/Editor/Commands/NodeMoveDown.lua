local class = require "com.class"

---@class EditorCommandNodeMoveDown
---@overload fun(nodeList):EditorCommandNodeMoveDown
local EditorCommandNodeMoveDown = class:derive("EditorCommandNodeMoveDown")

---Constructs a new Node Move Down command.
---**WARNING!** This command works correctly ONLY if the node list is sorted by the tree order.
---And it still breaks sometimes, but that will require insane work to make it work always properly...
---@param nodeList NodeList The list of nodes that should be moved up in its hierarchy.
function EditorCommandNodeMoveDown:new(nodeList)
    self.NAME = "NodeMoveDown"
    self.nodeList = nodeList:copy()
    self.previousIndexes = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMoveDown:execute()
    if self.nodeList:getSize() == 0 then
        return false
    end
    self.previousIndexes = self.nodeList:bulkGetSelfIndexes()
    return self.nodeList:bulkMoveDown()
end

---Undoes this command.
function EditorCommandNodeMoveDown:undo()
    self.nodeList:bulkMoveToIndexes(self.previousIndexes)
end

return EditorCommandNodeMoveDown