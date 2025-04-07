local class = require "com.class"

---@class EditorCommandNodeMoveToTop
---@overload fun(nodeList):EditorCommandNodeMoveToTop
local EditorCommandNodeMoveToTop = class:derive("EditorCommandNodeMoveToTop")

---Constructs a new Node Move To Top command.
---**WARNING!** This command works correctly ONLY if the node list is sorted by the tree order.
---And it still breaks sometimes, but that will require insane work to make it work always properly...
---@param nodeList NodeList The node that should be moved to the top in its hierarchy.
function EditorCommandNodeMoveToTop:new(nodeList)
    self.NAME = "NodeMoveToTop"
    self.nodeList = nodeList:copy()
    self.previousIndexes = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMoveToTop:execute()
    if self.nodeList:getSize() == 0 then
        return false
    end
    self.previousIndexes = self.nodeList:bulkGetSelfIndexes()
    return self.nodeList:bulkMoveToTop()
end

---Undoes this command.
function EditorCommandNodeMoveToTop:undo()
    self.nodeList:bulkMoveToIndexes(self.previousIndexes)
end

return EditorCommandNodeMoveToTop