local class = require "com.class"

---@class EditorCommandNodeAdd
---@overload fun(node, parent):EditorCommandNodeAdd
local EditorCommandNodeAdd = class:derive("EditorCommandNodeAdd")



---Constructs a new Node Add command.
---@param node Node The node that should be added.
---@param parent Node The node which should be the parent of the new Node.
function EditorCommandNodeAdd:new(node, parent)
    self.NAME = "NodeAdd"
    self.node = node
    self.parent = parent
end



---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeAdd:execute()
    if not self.node or not self.parent then
        return false
    end
    self.parent:addChild(self.node)
    return true
end



---Undoes this command.
function EditorCommandNodeAdd:undo()
    self.parent:removeChild(self.node)
end



return EditorCommandNodeAdd