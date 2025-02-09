local class = require "com.class"

---@class EditorCommandNodeMoveToIndex
---@overload fun(nodeList, index):EditorCommandNodeMoveToIndex
local EditorCommandNodeMoveToIndex = class:derive("EditorCommandNodeMoveToIndex")

---Constructs a new Node Move To Index command.
---**WARNING!** This command works correctly ONLY if the node list is sorted by the tree order.
---And it still breaks sometimes, but that will require insane work to make it work always properly...
---@param nodeList NodeList The list of nodes that should be moved to the specified index in its hierarchy.
---@param index integer The index the nodes should be moved to.
function EditorCommandNodeMoveToIndex:new(nodeList, index)
    self.NAME = "NodeMoveToIndex"
    self.nodeList = nodeList:copy()
    self.index = index
    self.previousIndexes = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMoveToIndex:execute()
    if self.nodeList:getSize() == 0 then
        return false
    end
    self.previousIndexes = self.nodeList:bulkGetSelfIndexes()
    return self.nodeList:bulkMoveToIndex(self.index)
end

---Undoes this command.
function EditorCommandNodeMoveToIndex:undo()
    self.nodeList:bulkMoveToIndexes(self.previousIndexes)
end

return EditorCommandNodeMoveToIndex