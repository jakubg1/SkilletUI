local class = require "com.class"

---@class EditorCommandNodeRename
---@overload fun(node, name):EditorCommandNodeRename
local EditorCommandNodeRename = class:derive("EditorCommandNodeRename")

---Constructs a new Node Rename command.
---@param node Node The node that should be renamed.
---@param name string The new name.
function EditorCommandNodeRename:new(node, name)
    self.NAME = "NodeRename"
    self.node = node
    self.name = name
    self.oldName = nil
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeRename:execute()
    if not self.node or not self.name then
        return false
    end
    self.oldName = self.node:getName()
    if self.name == self.oldName then
        return false
    end
    self.node:setName(self.name)
    return true
end

---Undoes this command.
function EditorCommandNodeRename:undo()
    self.node:setName(self.oldName)
end

return EditorCommandNodeRename