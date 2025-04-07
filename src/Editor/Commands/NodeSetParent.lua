local class = require "com.class"

---@class EditorCommandNodeSetParent
---@overload fun(nodeList, parent):EditorCommandNodeSetParent
local EditorCommandNodeSetParent = class:derive("EditorCommandNodeSetParent")

---Constructs a new Node Set Parent command.
---**WARNING!** This command works correctly ONLY if the node list is sorted by the tree order.
---And it still breaks sometimes, but that will require insane work to make it work always properly...
---@param nodeList NodeList The list of nodes that will have their parents changed.
---@param parent Node The new parent.
function EditorCommandNodeSetParent:new(nodeList, parent)
    self.NAME = "NodeSetParent"
    self.nodeList = nodeList:copy()
    self.parent = parent
    self.oldParents = nil
    self.oldIndexes = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeSetParent:execute()
    if self.nodeList:getSize() == 0 or not self.parent then
        return false
    end
    self.oldParents = self.nodeList:bulkGetParents()
    self.oldIndexes = self.nodeList:bulkGetSelfIndexes()
    return self.nodeList:bulkAdd(self.parent)
end

---Undoes this command.
function EditorCommandNodeSetParent:undo()
    self.nodeList:bulkAddSpread(self.oldParents, self.oldIndexes)
end

return EditorCommandNodeSetParent