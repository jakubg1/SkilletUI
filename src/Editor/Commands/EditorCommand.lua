local Class = require("com.class")

---@class EditorCommand : Class
local EditorCommand = Class:derive("EditorCommand")

---Constructs a new Editor Command.
---This is an abstract class which is extended by the Editor Commands.
function EditorCommand:new()
    self.NAME = ""
end

---Executes this command. Returns `true` on success, `false` otherwise.
---@return boolean
function EditorCommand:execute()
    error("Not implemented")
end

---Undoes this command.
function EditorCommand:undo()
    error("Not implemented")
end

return EditorCommand