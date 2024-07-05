local class = require "com.class"

---@class EditorCommandNodeMoveToTop
---@overload fun(node):EditorCommandNodeMoveToTop
local EditorCommandNodeMoveToTop = class:derive("EditorCommandNodeMoveToTop")



---Constructs a new Node Move To Top command.
---@param node Node The node that should be moved to the top in its hierarchy.
function EditorCommandNodeMoveToTop:new(node)
    self.NAME = "NodeMoveToTop"
    self.node = node
    self.previousIndex = nil
end



---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommandNodeMoveToTop:execute()
    if not self.node then
        return false
    end
    self.previousIndex = self.node:getSelfIndex()
    return self.node:moveSelfToTop()
end



---Undoes this command.
function EditorCommandNodeMoveToTop:undo()
    self.node:moveSelfToPosition(self.previousIndex)
end



return EditorCommandNodeMoveToTop