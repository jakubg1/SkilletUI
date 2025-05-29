local EditorCommand = require("src.Editor.Commands.EditorCommand")

---@class EditorCommandNodeRename : EditorCommand
---@overload fun(nodeList, name): EditorCommandNodeRename
local EditorCommandNodeRename = EditorCommand:derive("EditorCommandNodeRename")

---Constructs a new Node Rename command.
---@param nodeList NodeList The list of nodes that should be renamed.
---@param name string The new name. There is no duplicate checking; all of the nodes will get the same name.
function EditorCommandNodeRename:new(nodeList, name)
    self.NAME = "NodeRename"
    self.nodeList = nodeList:copy()
    self.name = name
    self.oldNames = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeRename:execute()
    if self.nodeList:getSize() == 0 or not self.name then
        return false
    end
    self.oldNames = self.nodeList:bulkGetPropBase("name")
    return self.nodeList:bulkSetName(self.name)
end

---Undoes this command.
function EditorCommandNodeRename:undo()
    for i, node in ipairs(self.nodeList:getNodes()) do
        node:setName(self.oldNames[i])
    end
end

return EditorCommandNodeRename