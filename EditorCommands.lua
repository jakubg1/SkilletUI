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

    self.POS = Vec2(0, 0)
    self.SIZE = Vec2(800, 600)
    self.ITEM_HEIGHT = 15
    self.MAX_ITEMS = 13

    self.commandHistory = {}
    self.undoCommandHistory = {}
    self.transactionMode = false

    self.visible = false
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
    if not self.visible then
        return
    end

    -- Background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)

    -- Draw the main text.
    self.editor:drawShadowedText("Command Buffer", self.POS.x, self.POS.y)
    local items = {}
    local lastName = nil
    for i, entry in ipairs(self.commandHistory) do
        if entry.isGroup then
            -- We have a group. Time to hack something very dirty.
            -- Before we do anything, we will check if we can summarize the transaction in one line.
            -- That is, the entire contents of the transaction is just one command repeated any number of times.
            -- Based on that information, we can choose one of two paths to add the entries in the most efficient way.
            -- So, let's go!
            local compact = true
            lastName = nil
            local count = 0
            for j, subentry in ipairs(entry.commands) do
                local name = subentry.command.NAME
                if name ~= lastName then
                    -- Our name is different. If our slot is empty, that is the name that we are going for.
                    if not lastName then
                        lastName = name
                        count = 1
                    else
                        -- Whoops! We've got a different name. This means we can't print a compact version of the transaction.
                        compact = false
                        break
                    end
                else
                    count = count + 1
                end
            end
            -- Now print a compact or non-compact version depending on what has been deduced.
            local prefix = entry.group and string.format("Transaction <%s> {", entry.group) or "Transaction {"
            local isGroupClosed = entry ~= self.commandHistory[#self.commandHistory] or not self.transactionMode
            if compact then
                local name = lastName
                if count > 1 then
                    name = name .. string.format(" (x%s)", count)
                end
                if isGroupClosed then
                    name = name .. "}"
                end
                table.insert(items, {value = prefix .. name, indent = 0, count = 1})
            else
                -- Add a transaction group prefix.
                table.insert(items, {value = prefix, indent = 0, count = 1})
                lastName = nil
                for j, subentry in ipairs(entry.commands) do
                    -- Add a new item or modify the existing one if it's the same.
                    local name = subentry.command.NAME
                    if name == lastName then
                        items[#items].count = items[#items].count + 1
                    else
                        table.insert(items, {value = name, indent = 1, count = 1})
                        lastName = name
                    end
                end
                if isGroupClosed then
                    -- If the transaction has been finished, we can close it with the closing brace.
                    table.insert(items, {value = "}", indent = 0, count = 1})
                    lastName = nil
                end
            end
        else
            -- Add a new item or modify the existing one if it's the same.
            local name = entry.command.NAME
            if name == lastName then
                items[#items].count = items[#items].count + 1
            else
                table.insert(items, {value = name, indent = 0, count = 1})
                lastName = name
            end
        end
    end
    -- Draw the items.
    for i, item in ipairs(items) do
        local name = item.value
        if item.count > 1 then
            name = name .. string.format(" (x%s)", item.count)
        end
        self.editor:drawShadowedText(name, self.POS.x + 5 + item.indent * 30, self.POS.y + 10 + (i * self.ITEM_HEIGHT))
    end
    -- Or a none text if there's nothing.
    if #items == 0 then
        self.editor:drawShadowedText("(empty)", self.POS.x + 5, self.POS.y + 25, _COLORS.gray)
    end
end



return EditorCommands