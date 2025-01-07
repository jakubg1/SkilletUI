local class = require "com.class"

---@class EditorCommands
---@overload fun(editor):EditorCommands
local EditorCommands = class:derive("EditorCommands")

-- Place your imports here
local Vec2 = require("Vector2")



---Constructs a new Editor Command Manager.
---@param editor Editor The UI editor this Command Manager belongs to.
function EditorCommands:new(editor)
    self.editor = editor

    self.POS = Vec2(1220, 600)
    self.ITEM_HEIGHT = 20

    self.commandHistory = {}
    self.undoCommandHistory = {}
    self.transactionMode = false
end



---Executes a Command. Each command is an atomic action, which can be undone with a single press of the Undo button. They can be grouped into transactions.
---If the command has been executed successfully, it is added to the command stack and can be undone using `:undoLastCommand()`.
---Returns `true` if the command has been executed successfully. Otherwise, returns `false`.
---@param command EditorCommand* The command to be performed.
---@param groupID string? An optional group identifier for this command execution. If set, commands with the same group ID will be grouped together, and so will be packed into a single command transaction.
---@return boolean
function EditorCommands:executeCommand(command, groupID)
    local result = command:execute()
    if result then
        -- Purge the undo command stack if anything was there.
        if #self.undoCommandHistory > 0 then
            self.undoCommandHistory = {}
        end
        -- If the command groups differ between the new command and the current command group, commit the group.
        if self.transactionMode and groupID ~= self.commandHistory[#self.commandHistory].group then
            self:commitCommandTransaction()
        end
        -- If there is no command group active and we've got a group ID, create a new transaction.
        if not self.transactionMode and groupID then
            self:startCommandTransaction(groupID)
        end
        -- Add a command onto the stack, or into the transaction if one is open.
        if self.transactionMode then
            table.insert(self.commandHistory[#self.commandHistory].commands, {command = command})
        else
            table.insert(self.commandHistory, {command = command})
        end
    end
    return result
end



---Starts a command transaction.
---Command transactions bundle a few commands into an atomic pack. It only can be undone as a whole.
---
---Each command transaction is saved as a subtable in the `self.commandHistory` table.
---To close a command transaction, use `:commitCommandTransaction()`.
---@param groupID string? An optional group identifier for this command group. If set, any incoming command that does not match this group will automatically commit this transaction.
function EditorCommands:startCommandTransaction(groupID)
    if self.transactionMode then
        error("Cannot nest command transactions!")
    end
    self.transactionMode = true
    table.insert(self.commandHistory, {isGroup = true, commands = {}, group = groupID})
end



---Closes a command transaction.
---From this point, any new commands will be added separately, as usual.
function EditorCommands:commitCommandTransaction()
    if not self.transactionMode then
        error("Cannot close a command transaction when none is open!")
    end
    self.transactionMode = false
    if #self.commandHistory[#self.commandHistory].commands == 0 then
        -- Remove an empty transaction.
        table.remove(self.commandHistory)
    elseif #self.commandHistory[#self.commandHistory].commands == 1 then
        -- Unwrap a transaction with just one command.
        local entry = self.commandHistory[#self.commandHistory].commands[1]
        table.remove(self.commandHistory)
        table.insert(self.commandHistory, entry)
    end
end



---Cancels a command transaction by undoing all commands that have been already executed and removing the transaction from the stack.
---Cancelled command transactions can NOT be restored.
function EditorCommands:cancelCommandTransaction()
    if not self.transactionMode then
        error("Cannot cancel a command transaction when none is open!")
    end
    self.transactionMode = false
    local entry = table.remove(self.commandHistory)
    for i = #entry.commands, 1, -1 do
        entry.commands[i].command:undo()
    end
end



---Undoes the command that has been executed last and moves it to the undo command stack.
function EditorCommands:undoLastCommand()
    if #self.commandHistory == 0 then
        return
    end
    -- Undoing a command closes the transaction.
    -- TODO: Redoing should open it back. Find a solution to this problem.
    if self.transactionMode then
        self:commitCommandTransaction()
    end
    local entry = table.remove(self.commandHistory)
    if entry.isGroup then    -- Both command groups and commands themselves are tables, so we cannot do `type(command) == "table"` here.
        -- Undo the whole transaction at once.
        for i = #entry.commands, 1, -1 do
            entry.commands[i].command:undo()
        end
    else
        entry.command:undo()
    end
    table.insert(self.undoCommandHistory, entry)
end



---Redoes the undone command and moves it back to the main command stack.
function EditorCommands:redoLastCommand()
    if #self.undoCommandHistory == 0 then
        return
    end
    local entry = table.remove(self.undoCommandHistory)
    if entry.isGroup then
        for i = 1, #entry.commands do
            entry.commands[i].command:execute()
        end
    else
        entry.command:execute()
    end
    table.insert(self.commandHistory, entry)
end



---Draws the debug contents of Editor Command Manager on the screen.
function EditorCommands:draw()
    -- Command buffer
    self.editor:drawShadowedText("Command Buffer", self.POS.x, self.POS.y)
    local y = self.POS.y + 30
    for i, entry in ipairs(self.commandHistory) do
        if entry.isGroup then
            local line = entry.group and string.format("Transaction <%s> {", entry.group) or "Transaction {"
            self.editor:drawShadowedText(line, self.POS.x, y)
            y = y + self.ITEM_HEIGHT
            for j, subentry in ipairs(entry.commands) do
                self.editor:drawShadowedText(subentry.command.NAME, self.POS.x + 30, y)
                y = y + self.ITEM_HEIGHT
            end
            if entry ~= self.commandHistory[#self.commandHistory] or not self.transactionMode then
                self.editor:drawShadowedText("}", self.POS.x, y)
                y = y + self.ITEM_HEIGHT
            end
        else
            self.editor:drawShadowedText(entry.command.NAME, self.POS.x, y)
            y = y + self.ITEM_HEIGHT
        end
    end
end



return EditorCommands