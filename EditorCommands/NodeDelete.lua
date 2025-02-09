local class = require "com.class"

---@class EditorCommandNodeDelete
---@overload fun(nodeList):EditorCommandNodeDelete
local EditorCommandNodeDelete = class:derive("EditorCommandNodeDelete")

---Constructs a new Node Delete command.
---@param nodeList NodeList The node that should be deleted.
function EditorCommandNodeDelete:new(nodeList)
    self.NAME = "NodeDelete"
    self.nodeList = nodeList:copy()
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeDelete:execute()
    if self.nodeList:getSize() == 0 then
        return false
    end
    return self.nodeList:bulkRemove()
end

---Undoes this command.
function EditorCommandNodeDelete:undo()
    self.nodeList:bulkRestore()
end

return EditorCommandNodeDelete