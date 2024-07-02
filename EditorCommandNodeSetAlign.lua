local class = require "com.class"

---@class EditorCommandNodeSetAlign
---@overload fun(node, align):EditorCommandNodeSetAlign
local EditorCommandNodeSetAlign = class:derive("EditorCommandNodeSetAlign")



---Constructs a new Node Set Align command.
---@param node Node The node that will have its align point changed.
---@param align Vector2 The new alignment.
function EditorCommandNodeSetAlign:new(node, align)
    self.NAME = "NodeSetAlign"
    self.node = node
    self.align = align
    self.oldAlign = nil
end



---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeSetAlign:execute()
    if not self.node then
        return false
    end
    self.oldAlign = self.node:getAlign()
    if self.align == self.oldAlign then
        return false
    end
    self.node:setAlign(self.align)
    return true
end



---Undoes this command.
function EditorCommandNodeSetAlign:undo()
    self.node:setAlign(self.oldAlign)
end



return EditorCommandNodeSetAlign