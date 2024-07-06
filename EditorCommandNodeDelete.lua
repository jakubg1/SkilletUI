local class = require "com.class"

---@class EditorCommandNodeDelete
---@overload fun(node):EditorCommandNodeDelete
local EditorCommandNodeDelete = class:derive("EditorCommandNodeDelete")

---Constructs a new Node Delete command.
---@param node Node The node that should be deleted.
function EditorCommandNodeDelete:new(node)
    self.NAME = "NodeDelete"
    self.node = node
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeDelete:execute()
    if not self.node then
        return false
    end
    return self.node:removeSelf()
end

---Undoes this command.
function EditorCommandNodeDelete:undo()
    self.node:restoreSelf()
end

return EditorCommandNodeDelete