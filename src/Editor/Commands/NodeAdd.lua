local EditorCommand = require("src.Editor.Commands.EditorCommand")

---@class EditorCommandNodeAdd : EditorCommand
---@overload fun(nodeList, parent): EditorCommandNodeAdd
local EditorCommandNodeAdd = EditorCommand:derive("EditorCommandNodeAdd")

---Constructs a new Node Add command.
---@param nodeList NodeList The list of nodes that should be added.
---@param parent Node The node which should be the parent of the new Node.
function EditorCommandNodeAdd:new(nodeList, parent)
    self.NAME = "NodeAdd"
    self.nodeList = nodeList:copy()
    self.parent = parent
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeAdd:execute()
    if self.nodeList:getSize() == 0 or not self.parent then
        return false
    end
    local result = self.nodeList:bulkAdd(self.parent)
    if not result then
        return false
    end
    self.nodeList:bulkEnsureUniqueName()
    return true
end

---Undoes this command.
function EditorCommandNodeAdd:undo()
    self.nodeList:bulkRemove()
end

return EditorCommandNodeAdd