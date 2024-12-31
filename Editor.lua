local class = require "com.class"

---@class Editor
---@overload fun():Editor
local Editor = class:derive("Editor")

local Vec2 = require("Vector2")
local Node = require("Node")
local Input = require("Input")

local CommandNodeAdd = require("EditorCommands.NodeAdd")
local CommandNodeRename = require("EditorCommands.NodeRename")
local CommandNodeMove = require("EditorCommands.NodeMove")
local CommandNodeDrag = require("EditorCommands.NodeDrag")
local CommandNodeDelete = require("EditorCommands.NodeDelete")
local CommandNodeSetParent = require("EditorCommands.NodeSetParent")
local CommandNodeSetAlign = require("EditorCommands.NodeSetAlign")
local CommandNodeSetParentAlign = require("EditorCommands.NodeSetParentAlign")
local CommandNodeSetWidgetProperty = require("EditorCommands.NodeSetWidgetProperty")
local CommandNodeMoveUp = require("EditorCommands.NodeMoveUp")
local CommandNodeMoveDown = require("EditorCommands.NodeMoveDown")
local CommandNodeMoveToTop = require("EditorCommands.NodeMoveToTop")
local CommandNodeMoveToBottom = require("EditorCommands.NodeMoveToBottom")
local CommandNodeMoveToIndex = require("EditorCommands.NodeMoveToIndex")

---@alias EditorCommand* EditorCommandNodeAdd|EditorCommandNodeRename|EditorCommandNodeMove|EditorCommandNodeDrag|EditorCommandNodeDelete|EditorCommandNodeSetParent|EditorCommandNodeSetAlign|EditorCommandNodeSetParentAlign|EditorCommandNodeSetWidgetProperty|EditorCommandNodeMoveUp|EditorCommandNodeMoveDown|EditorCommandNodeMoveToTop|EditorCommandNodeMoveToBottom|EditorCommandNodeMoveToIndex



--- Done:
--- - Hovering nodes
--- - Selecting nodes
--- - Deleting nodes
--- - Moving nodes around
--- - Cancelling a node movement while it is being dragged
--- - Changing nodes' anchor points
--- - Changing nodes' parents
--- - Reordering nodes
--- - Node tree
--- - Selecting via node tree
--- - Undo/Redo (rewrite to commands)
--- - Widget manipulation (color, text, size, scale, etc.)
--- - Dragging entries around in the node tree
---
--- To Do:
--- - Resizing widgets like boxes
--- - Saving layouts
--- - Loading/switching layouts
--- - Copy/Paste and widget duplication
--- - Adding new nodes (and entire node groups for stuff like buttons, scroll bars, etc.)
---   - tip: have a Button class as a controller for the children which have unchangeable names and references them directly by name in the constructor
--- - Multi-selection(?)
--- - Animations at some point



---Constructs a new UI Editor.
function Editor:new()
    self.UI = nil
    self.UI_INPUTS = {}
    self.INPUT_DIALOG = Input()

    self.UI_TREE_POS = Vec2(5, 120)

    self.commandHistory = {}
    self.undoCommandHistory = {}
    self.transactionMode = false

    self.enabled = true
    self.activeInput = nil
    self.hoveredNode = nil
    self.isNodeHoverIndirect = false
    self.selectedNode = nil
    self.nodeDragOrigin = nil
    self.nodeDragOriginalPos = nil
    self.nodeDragSnap = false
    self.nodeTreeHoverTop = false
    self.nodeTreeHoverBottom = false
    self.nodeTreeDragOrigin = nil
    self.nodeTreeDragSnap = false

    self.uiTreeInfo = {}
end



---Returns UI tree information.
---This function should only be called internally. If you want to get the current UI tree info, fetch the `self.uiTreeInfo` field instead.
---@param node Node? The UI node of which the tree should be added to the list.
---@param tab table? The table, used internally.
---@param indent integer? The starting indentation.
---@return table tab This is a one-dimensional table of entries in the form `{node = Node, indent = number}`.
function Editor:getUITreeInfo(node, tab, indent)
    node = node or _UI
    tab = tab or {}
    indent = indent or 0
    table.insert(tab, {node = node, indent = indent})
    for i, child in ipairs(node.children) do
        self:getUITreeInfo(child, tab, indent + 1)
    end
    return tab
end



---Returns the currently hovered Node.
---This function also sets the values of the `self.isNodeHoverIndirect`, `self.nodeTreeHoverTop` and `self.nodeTreeHoverBottom` fields.
---
---This function should only be called internally. If you want to get the currently hovered node, fetch the `self.hoveredNode` field instead.
---@return Node?
function Editor:getHoveredNode()
    self.isNodeHoverIndirect = false
    self.nodeTreeHoverTop = false
    self.nodeTreeHoverBottom = false
    -- Editor UI has hover precedence over actual UI.
    if self:isUIHovered() then
        return nil
    end
    -- Look whether we've hovered over any UI info entry.
    for i, entry in ipairs(self.uiTreeInfo) do
        if _Utils.isPointInsideBox(_MousePos, self.UI_TREE_POS + Vec2(0, 15 * i), Vec2(200, 15)) then
            self.isNodeHoverIndirect = true
            -- Additional checks for specific parts of the entry. Used for node dragging so that you can drag in between the entries.
            local MARGIN = 4
            if _Utils.isPointInsideBox(_MousePos, self.UI_TREE_POS + Vec2(0, 15 * i), Vec2(200, MARGIN)) then
                self.nodeTreeHoverTop = true
            elseif _Utils.isPointInsideBox(_MousePos, self.UI_TREE_POS + Vec2(0, 15 * i + 15 - MARGIN), Vec2(200, MARGIN)) then
                self.nodeTreeHoverBottom = true
            end
            return entry.node
        end
    end
    -- Finally, look if any node is directly hovered.
	return _UI:findChildByPixelDepthFirst(_MouseCPos)
end



---Marks the provided node as selected and updates all UI in order to facilitate editing its properties.
---@param node Node? The node to be selected. If not provided, all nodes will be deselected.
function Editor:selectNode(node)
    self.selectedNode = node
    -- Update the name box.
    self:inputSetValue(self.UI_INPUTS.nodeName, "string", node and node:getName() or "")
    self:inputSetDisabled(self.UI_INPUTS.nodeName, not node or node:isControlled())
    -- Clear all properties.
    local previousPropertiesUI = self.UI:findChildByName("properties")
    if previousPropertiesUI then
        previousPropertiesUI:removeSelf()
    end
    -- Make a new property list UI.
    if node then
        local widget = node.widget
        if widget then
            if widget.getPropertyList then
                local propertiesUI = Node({name = "properties", pos = {x = 700, y = 628}})
                local properties = widget:getPropertyList()
                for i, property in ipairs(properties) do
                    local inputValue
                    if property.nodeKeys then
                        -- If we have multiple widgets attached to this property, fetch the value from the first one of them. Not elegant.
                        -- TODO: Figure out a way to fetch from all of them and to signal somehow whether they are different (they shouldn't).
                        inputValue = widget[property.nodeKeys[1]].widget[property.key]
                    else
                        inputValue = widget[property.key]
                    end
                    local inputFunction = function(input)
                        if property.nodeKeys then
                            for j, node in ipairs(property.nodeKeys) do
                                self:setNodeWidgetProperty(widget[node], property.key, input)
                            end
                        else
                            self:setSelectedNodeWidgetProperty(property.key, input)
                        end
                    end
                    local propertyUI = self:input(0, (i - 1) * 20, 200, property.type, inputValue, inputFunction)
                    propertiesUI:addChild(propertyUI)
                end
                self.UI:addChild(propertiesUI)
            end
        end
    end
end



---Adds the provided UI node to the currently selected node, or, if no node is selected, to the root node.
---@param node Node The node to be added.
function Editor:addNode(node)
    self:executeCommand(CommandNodeAdd(node, self.selectedNode or _UI))
end



---Renames the currently selected UI node.
---@param name string The new name.
function Editor:renameSelectedNode(name)
    self:executeCommand(CommandNodeRename(self.selectedNode, name))
end



---Moves the currently selected UI node by the given amount of pixels.
---@param offset Vector2 The movement vector the selected UI node should be moved towards.
function Editor:moveSelectedNode(offset)
    self:executeCommand(CommandNodeMove(self.selectedNode, offset))
end



---Starts dragging the selected node, starting from the current mouse position.
function Editor:startDraggingSelectedNode()
    if not self.selectedNode then
        return
    end
    self.nodeDragOrigin = _MouseCPos
    self.nodeDragOriginalPos = self.selectedNode:getPos()
    self.nodeDragSnap = true
end



---Finishes dragging the selected node and pushes a command so that the movement can be undone.
function Editor:finishDraggingSelectedNode()
    if not self.selectedNode or not self.nodeDragOriginalPos then
        return
    end
    self:executeCommand(CommandNodeDrag(self.selectedNode, self.nodeDragOriginalPos))
    self.nodeDragOrigin = nil
    self.nodeDragOriginalPos = nil
    self.nodeDragSnap = false
end



---Restores the original selected node position and finishes the dragging process.
function Editor:cancelDraggingSelectedNode()
    if not self.selectedNode or not self.nodeDragOriginalPos then
        return
    end
    self.selectedNode:setPos(self.nodeDragOriginalPos)
    self:finishDraggingSelectedNode()
end



---Starts dragging the selected node in the node tree.
function Editor:startDraggingSelectedNodeInNodeTree()
    if not self.selectedNode then
        return
    end
    self.nodeTreeDragOrigin = _MousePos
    self.nodeTreeDragSnap = true
end



---Finishes dragging the selected node in the node tree and pushes a command so that the movement can be undone.
function Editor:finishDraggingSelectedNodeInNodeTree()
    if not self.selectedNode or not self.nodeTreeDragOrigin then
        return
    end
    if self.nodeTreeDragSnap then
        -- We didn't break the snap (mouse not moved enough to initiate the movement process), so reset everything as if nothing has ever happened.
        self:cancelDraggingSelectedNodeInNodeTree()
        return
    end
    self:startCommandTransaction()
    if self.nodeTreeHoverTop then
        -- We've dropped the node above the hovered node.
        -- First, make sure that our parent is correct.
        if self.selectedNode.parent ~= self.hoveredNode.parent then
            self:executeCommand(CommandNodeSetParent(self.selectedNode, self.hoveredNode.parent))
        end
        -- Now, reorder it so that the selected node is before the hovered node.
        local index = self.hoveredNode:getSelfIndex()
        if index > self.selectedNode:getSelfIndex() then
            index = index - 1
        end
        self:executeCommand(CommandNodeMoveToIndex(self.selectedNode, index))
    elseif self.nodeTreeHoverBottom then
        -- We've dropped the node below the hovered node.
        if self.hoveredNode:hasChildren() then
            -- If we've done this on a node that has children, the selected node should become its first child.
            self:executeCommand(CommandNodeSetParent(self.selectedNode, self.hoveredNode))
            self:executeCommand(CommandNodeMoveToTop(self.selectedNode))
        else
            -- Otherwise, move on similarly to the top case.
            -- First, make sure that our parent is correct.
            if self.selectedNode.parent ~= self.hoveredNode.parent then
                self:executeCommand(CommandNodeSetParent(self.selectedNode, self.hoveredNode.parent))
            end
            -- Now, reorder it so that the selected node is after the hovered node.
            local index = self.hoveredNode:getSelfIndex() + 1
            if index > self.selectedNode:getSelfIndex() then
                index = index - 1
            end
            self:executeCommand(CommandNodeMoveToIndex(self.selectedNode, index))
        end
    else
        -- We've dropped the node inside of another node: attach it as a parent.
        self:executeCommand(CommandNodeSetParent(self.selectedNode, self.hoveredNode))
    end
    self:closeCommandTransaction()
    self.nodeTreeDragOrigin = nil
    self.nodeTreeDragSnap = false
end



---Cancels the drag of the selected node in the node tree.
function Editor:cancelDraggingSelectedNodeInNodeTree()
    self.nodeTreeDragOrigin = nil
    self.nodeTreeDragSnap = false
end



---Sets a new alignment for the selected node.
---@param align Vector2 The new alignment value.
function Editor:setSelectedNodeAlign(align)
    self:executeCommand(CommandNodeSetAlign(self.selectedNode, align))
end



---Sets a new parental alignment for the selected node.
---@param parentAlign Vector2 The new parental alignment value.
function Editor:setSelectedNodeParentAlign(parentAlign)
    self:executeCommand(CommandNodeSetParentAlign(self.selectedNode, parentAlign))
end



---Sets a new value for the selected node's widget property.
---@param property string The property to be set.
---@param value any? The value to be set for this property.
function Editor:setSelectedNodeWidgetProperty(property, value)
    self:executeCommand(CommandNodeSetWidgetProperty(self.selectedNode, property, value))
end



---Sets a new value for the given node's widget property.
---@param node Node The node that will have its widget property changed.
---@param property string The property to be set.
---@param value any? The value to be set for this property.
function Editor:setNodeWidgetProperty(node, property, value)
    self:executeCommand(CommandNodeSetWidgetProperty(node, property, value))
end



---Moves the selected node up in its parent's hierarchy.
function Editor:moveSelectedNodeUp()
    self:executeCommand(CommandNodeMoveUp(self.selectedNode))
end



---Moves the selected node down in its parent's hierarchy.
function Editor:moveSelectedNodeDown()
    self:executeCommand(CommandNodeMoveDown(self.selectedNode))
end



---Moves the selected node to the top in its parent's hierarchy.
function Editor:moveSelectedNodeToTop()
    self:executeCommand(CommandNodeMoveToTop(self.selectedNode))
end



---Moves the selected node to the bottom in its parent's hierarchy.
function Editor:moveSelectedNodeToBottom()
    self:executeCommand(CommandNodeMoveToBottom(self.selectedNode))
end



---Parents the currently selected node to the currently hovered node.
---The selected node becomes a child, and the hovered node becomes its parent.
function Editor:parentSelectedNodeToHoveredNode()
    self:executeCommand(CommandNodeSetParent(self.selectedNode, self.hoveredNode))
end



---Deletes the currently selected UI node.
function Editor:deleteSelectedNode()
    local result = self:executeCommand(CommandNodeDelete(self.selectedNode))
    -- Unselect the selected node if it has been successfully deleted.
    if result then
        self.selectedNode = nil
    end
end



---Executes an editor command. Each command is an atomic action, which can be undone with a single press of the Undo button.
---If the command has been executed successfully, it is added to the command stack and can be undone using `:undoLastCommand()`.
---Returns `true` if the command has been executed successfully. Otherwise, returns `false`.
---@param command EditorCommand* The command to be performed.
---@return boolean
function Editor:executeCommand(command)
    local result = command:execute()
    if result then
        -- Purge the undo command stack if anything was there.
        if #self.undoCommandHistory > 0 then
            self.undoCommandHistory = {}
        end
        -- Add a command onto the stack, or into the transaction if one is open.
        if self.transactionMode then
            table.insert(self.commandHistory[#self.commandHistory], command)
        else
            table.insert(self.commandHistory, command)
        end
    end
    return result
end



---Starts a command transaction.
---Command transactions bundle a few commands into an atomic pack. It only can be undone as a whole.
---
---Each command transaction is saved as a subtable in the `self.commandHistory` table.
---To close a command transaction, use `:closeCommandTransaction()`.
function Editor:startCommandTransaction()
    if self.transactionMode then
        error("Cannot nest command transactions!")
    end
    self.transactionMode = true
    table.insert(self.commandHistory, {})
end



---Closes a command transaction.
---From this point, any new commands will be added separately, as usual.
function Editor:closeCommandTransaction()
    if not self.transactionMode then
        error("Cannot close a command transaction when none is open!")
    end
    self.transactionMode = false
    if #self.commandHistory[#self.commandHistory] == 0 then
        -- Remove an empty transaction.
        table.remove(self.commandHistory)
    elseif #self.commandHistory[#self.commandHistory] == 1 then
        -- Unwrap a transaction with just one command.
        local command = self.commandHistory[#self.commandHistory][1]
        table.remove(self.commandHistory)
        table.insert(self.commandHistory, command)
    end
end



---Undoes the command that has been executed last and moves it to the undo command stack.
function Editor:undoLastCommand()
    if #self.commandHistory == 0 then
        return
    end
    -- Undoing a command closes the transaction.
    -- TODO: Redoing should open it back. Find a solution to this problem.
    if self.transactionMode then
        self:closeCommandTransaction()
    end
    local command = table.remove(self.commandHistory)
    if #command > 0 then    -- Both command groups and commands themselves are tables, so we cannot do `type(command) == "table"` here.
        -- Undo the whole transaction at once.
        for i = #command, 1, -1 do
            command[i]:undo()
        end
    else
        command:undo()
    end
    table.insert(self.undoCommandHistory, command)
end



---Redoes the undone command and moves it back to the main command stack.
function Editor:redoLastCommand()
    if #self.undoCommandHistory == 0 then
        return
    end
    local command = table.remove(self.undoCommandHistory)
    if #command > 0 then
        for i = 1, #command do
            command[i]:execute()
        end
    else
        command:execute()
    end
    table.insert(self.commandHistory, command)
end



---Convenience function which creates an editor button.
---@param x number The X coordinate of the button position.
---@param y number The Y coordinate of the button position.
---@param w number The width of the button. Height is always 20.
---@param text string The text that should be written on the button.
---@param fn function? The function to be executed when this button is clicked.
---@param key string? The key which will activate this button.
---@return Node
function Editor:button(x, y, w, text, fn, key)
    local button = Node({name = "", type = "9sprite", image = "ed_button", clickImage = "ed_button_click", shortcut = key, pos = {x = x, y = y}, size = {x = w, y = 20}, scale = 2, children = {{name = "", type = "text", font = "default", text = text, pos = {x = 0, y = -1}, align = "center", parentAlign = "center", color = _COLORS.black}}})
    button:setOnClick(fn)
    return button
end



---Convenience function which creates an editor input field.
---@param x number The X coordinate of the position.
---@param y number The Y coordinate of the position.
---@param w number The width of the input field. Height is always 20.
---@param type string The input type. Can be `"string"`, `"number"` or `"color"`.
---@param value string|number|Color The value that should be initially set in the input field.
---@param fn function The function that will be executed when the value has been changed. The parameter will be the new text.
---@return Node
function Editor:input(x, y, w, type, value, fn)
    local input
    if type ~= "color" then
        input = Node({name = "", type = "9sprite", image = "ed_input", hoverImage = "ed_input_hover", disabledImage = "ed_input_disabled", pos = {x = x, y = y}, size = {x = w, y = 20}, children = {{name = "$text", type = "text", font = "default", text = tostring(value), pos = {x = 4, y = -1}, align = "left", parentAlign = "left", color = _COLORS.white}}})
    else
        input = Node({name = "", type = "9sprite", image = "ed_input", hoverImage = "ed_input_hover", disabledImage = "ed_input_disabled", pos = {x = x, y = y}, size = {x = w, y = 20}, children = {{name = "$color", type = "box", color = value, pos = {x = 0, y = -1}, size = {x = w - 2, y = 18}, align = "center", parentAlign = "center"}}})
    end
    input:setOnClick(function() self:askForInput(input, type) end)
    input._onChange = fn
    return input
end



---Returns the value of an editor input field.
---@param node Node The editor input field.
---@param type string The input type. Can be `"string"`, `"number"` or `"color"`.
---@return string|number|Color?
function Editor:inputGetValue(node, type)
    if type == "string" then
        return node:findChildByName("$text").widget.text
    elseif type == "number" then
        return tonumber(node:findChildByName("$text").widget.text)
    elseif type == "color" then
        return node:findChildByName("$color").widget.color
    end
end



---Sets the value of an editor input field.
---@param node Node The editor input field.
---@param type string The input type. Can be `"string"`, `"number"` or `"color"`.
---@param value string|number|Color The value to be set.
function Editor:inputSetValue(node, type, value)
    if type == "string" then
        node:findChildByName("$text").widget.text = value
    elseif type == "number" then
        node:findChildByName("$text").widget.text = tostring(value)
    elseif type == "color" then
        node:findChildByName("$color").widget.color = value
    end
end



---Sets whether an editor input field should be disabled.
---@param node Node The editor input field.
---@param disabled boolean Whether the field should be disabled.
function Editor:inputSetDisabled(node, disabled)
    node:setDisabled(disabled)
    local textNode = node:findChildByName("$text")
    if textNode then
        textNode.widget.color = disabled and _COLORS.gray or _COLORS.white
    end
end



---Executed when an editor input field has been clicked.
---@param input Node The input node that has been clicked.
---@param type string The input type. Can be `"string"`, `"number"` or `"color"`.
function Editor:askForInput(input, type)
    self.activeInput = input
    local value = self:inputGetValue(input, type)
    self.INPUT_DIALOG:inputAsk(type, value)
end



---Executed when an input has been submitted for a certain editor input field.
---@param result string|number|Color The value that has been submitted for this input.
---@param type string The input type. Can be `"string"`, `"number"` or `"color"`.
function Editor:onInputReceived(result, type)
    self:inputSetValue(self.activeInput, type, result)
    self.activeInput._onChange(result)
    self.activeInput = nil
end



---Returns whether an editor button (or any editor UI) is hovered.
---@return boolean
function Editor:isUIHovered()
    return self.UI:isHoveredWithChildren() or self.INPUT_DIALOG:isHovered()
end



---Initializes the UI for this Editor.
function Editor:load()
    self.UI = _LoadUI("editor_ui.json")
    local buttons = {
        self:button(0, 400, 150, "Delete [Del]", function() self:deleteSelectedNode() end, "delete"),
        self:button(0, 420, 150, "Layer Up [PgUp]", function() self:moveSelectedNodeUp() end, "pageup"),
        self:button(0, 440, 150, "Layer Down [PgDown]", function() self:moveSelectedNodeDown() end, "pagedown"),
        self:button(0, 460, 150, "Undo [Ctrl+Z]", function() self:undoLastCommand() end),
        self:button(0, 480, 150, "Redo [Ctrl+Y]", function() self:redoLastCommand() end),
        self:button(0, 530, 75, "Box", function() self:addNode(Node({name = "NewNode", type = "box", size = {x = 10, y = 10}, color = {r = 1, g = 1, b = 1}})) end),
        self:button(75, 530, 75, "Text", function() self:addNode(Node({name = "NewNode", type = "text", font = "standard", text = "You can't change me!"})) end),

        self:button(100, 630, 30, "TL", function() self:setSelectedNodeAlign(_ALIGNMENTS.topLeft) end),
        self:button(130, 630, 30, "T", function() self:setSelectedNodeAlign(_ALIGNMENTS.top) end),
        self:button(160, 630, 30, "TR", function() self:setSelectedNodeAlign(_ALIGNMENTS.topRight) end),
        self:button(100, 650, 30, "ML", function() self:setSelectedNodeAlign(_ALIGNMENTS.left) end),
        self:button(130, 650, 30, "M", function() self:setSelectedNodeAlign(_ALIGNMENTS.center) end),
        self:button(160, 650, 30, "MR", function() self:setSelectedNodeAlign(_ALIGNMENTS.right) end),
        self:button(100, 670, 30, "BL", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottomLeft) end),
        self:button(130, 670, 30, "B", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottom) end),
        self:button(160, 670, 30, "BR", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottomRight) end),

        self:button(300, 630, 30, "TL", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.topLeft) end),
        self:button(330, 630, 30, "T", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.top) end),
        self:button(360, 630, 30, "TR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.topRight) end),
        self:button(300, 650, 30, "ML", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.left) end),
        self:button(330, 650, 30, "M", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.center) end),
        self:button(360, 650, 30, "MR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.right) end),
        self:button(300, 670, 30, "BL", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottomLeft) end),
        self:button(330, 670, 30, "B", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottom) end),
        self:button(360, 670, 30, "BR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottomRight) end),
    }
    for i, button in ipairs(buttons) do
        self.UI:addChild(button)
    end
    local inputs = {
        nodeName = self:input(800, 608, 150, "string", "", function(input) self:renameSelectedNode(input) end),
    }
    for inputN, input in pairs(inputs) do
        self.UI:addChild(input)
        self.UI_INPUTS[inputN] = input
    end
end



---Updates the Editor.
---@param dt number Time delta in seconds.
function Editor:update(dt)
    self.uiTreeInfo = self:getUITreeInfo()
    self.hoveredNode = self:getHoveredNode()

    -- Handle the node dragging.
	if self.selectedNode and self.nodeDragOrigin then
		local movement = _MouseCPos - self.nodeDragOrigin
		if self.nodeDragSnap then
			--if movement:len() > 2 then
                self.nodeDragSnap = false
			--end
		else
			self.selectedNode:setPos(self.nodeDragOriginalPos + movement)
		end
	end

    -- Handle the node dragging in the node tree.
    if self.selectedNode and self.nodeTreeDragOrigin then
        local movement = _MousePos - self.nodeTreeDragOrigin
        if self.nodeTreeDragSnap then
            if movement:len() > 5 then
                self.nodeTreeDragSnap = false
            end
        end
    end

    self.UI:update(dt)
    self.INPUT_DIALOG:update(dt)
end



---Draws the Editor.
function Editor:draw()
    if not self.enabled then
        return
    end
	self.UI:findChildByName("drawtime").widget.text = string.format("Drawing took approximately %.1fms", _DrawTime * 1000)
	self.UI:findChildByName("pos").widget.text = string.format("Mouse position: %s", _MouseCPos)
	self.UI:findChildByName("line3").widget.text = string.format("Vecs per frame: %s", _VEC2S_PER_FRAME)
	self.UI:findChildByName("selText").widget.text = ""
	self.UI:draw()

    -- Other UI that will be hardcoded for now.
    love.graphics.setFont(_FONTS.default)

    -- Hovered and selected node
    if self.hoveredNode then
        self:drawShadowedText(string.format("Hovered: %s {%s} pos: %s -> %s", self.hoveredNode.name, self.hoveredNode.type, self.hoveredNode:getPos(), self.hoveredNode:getGlobalPos()), 5, 90, _COLORS.yellow)
    end
    if self.selectedNode then
        self:drawShadowedText(string.format("Selected: %s {%s} pos: %s -> %s", self.selectedNode.name, self.selectedNode.type, self.selectedNode:getPos(), self.selectedNode:getGlobalPos()), 5, 105, _COLORS.cyan)
    end

    -- Node tree
    for i, line in ipairs(self.uiTreeInfo) do
        local x = self.UI_TREE_POS.x + 30 * line.indent
        local y = self.UI_TREE_POS.y + 15 * i
        local color = _COLORS.white
        if line.node == self.selectedNode then
            color = _COLORS.cyan
        elseif line.node == self.hoveredNode then
            color = _COLORS.yellow
        elseif line.node.isController then
            color = _COLORS.orange
        elseif line.node:isControlled() then
            color = _COLORS.lightOrange
        end
        self:drawShadowedText(string.format("%s {%s}", line.node.name, line.node.type), x, y, color)
        -- If dragged over, additional signs will be shown.
        if self.nodeTreeDragOrigin and not self.nodeTreeDragSnap and line.node ~= self.selectedNode and line.node == self.hoveredNode then
            if self.nodeTreeHoverTop then
                love.graphics.setColor(1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.line(x, y, self.UI_TREE_POS.x + 200, y)
            elseif self.nodeTreeHoverBottom then
                -- Indent the line if this node has children.
                if line.node:hasChildren() then
                    x = x + 30
                end
                love.graphics.setColor(1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.line(x, y + 15, self.UI_TREE_POS.x + 200, y + 15)
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", self.UI_TREE_POS.x, y, 200, 15)
            end
        end
    end

    -- Dragged element in node tree
    if self.nodeTreeDragOrigin and not self.nodeTreeDragSnap then
        self:drawShadowedText(string.format("%s {%s}", self.selectedNode.name, self.selectedNode.type), _MousePos.x + 10, _MousePos.y + 10, _COLORS.white, _COLORS.blue)
    end

    -- Command buffer
    self:drawShadowedText("Command Buffer", 1100, 20)
    local y = 50
    for i, command in ipairs(self.commandHistory) do
        if #command > 0 then
            self:drawShadowedText("Transaction {", 1100, y)
            y = y + 15
            for j, subcommand in ipairs(command) do
                self:drawShadowedText(subcommand.NAME, 1130, y)
                y = y + 15
            end
            if command ~= self.commandHistory[#self.commandHistory] or not self.transactionMode then
                self:drawShadowedText("}", 1100, y)
                y = y + 15
            end
        else
            self:drawShadowedText(command.NAME, 1100, y)
            y = y + 15
        end
    end

    -- Buttons
    self:drawShadowedText("New Widget:", 5, 510)
    self:drawShadowedText("Node Align", 100, 610)
    self:drawShadowedText("Parent Align", 300, 610)
    self:drawShadowedText("Ctrl+Click a node to make it a parent of the currently selected node", 100, 700)
    
    -- Widget properties
    self:drawShadowedText("Node/Widget Properties", 600, 610)
    self:drawShadowedText("Name:", 760, 610)
    if self.selectedNode then
        local widget = self.selectedNode.widget
        if widget then
            if widget.getPropertyList then
                local properties = widget:getPropertyList()
                for i, property in ipairs(properties) do
                    if property.type == "string" or property.type == "number" or property.type == "color" then
                        self:drawShadowedText(string.format("%s", property.name), 600, 630 + (i - 1) * 20)
                    else
                        self:drawShadowedText(string.format("%s: %s", property.name, widget[property.key]), 600, 630 + (i - 1) * 20)
                    end
                end
            else
                self:drawShadowedText("This Widget does not support properties yet!", 600, 630)
            end
        else
            self:drawShadowedText("This Node does not have a widget.", 600, 630)
        end
    end

    -- Input box
    self.INPUT_DIALOG:draw()
end



---Draws the Editor during the main UI pass. Used for correct scaling.
function Editor:drawUIPass()
	if self.enabled and self.hoveredNode then
		self.hoveredNode:drawHitbox()
	end
	if self.enabled and self.selectedNode then
		self.selectedNode:drawSelected()
	end
end



---Draws the hardcoded editor text with an extra shadow for easier readability.
---@param text string The text to be drawn.
---@param x number The X coordinate.
---@param y number The Y coordinate.
---@param color Color? The color to be used, white by default.
---@param backgroundColor Color? The background color to be used. No background by default.
function Editor:drawShadowedText(text, x, y, color, backgroundColor)
    color = color or _COLORS.white
    if backgroundColor then
        local w = love.graphics.getFont():getWidth(text) + 2
        love.graphics.setColor(backgroundColor.r, backgroundColor.g, backgroundColor.b, 0.5)
        love.graphics.rectangle("fill", x, y, w, 15)
    end
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(text, x + 2, y + 2)
    love.graphics.setColor(color.r, color.g, color.b)
    love.graphics.print(text, x, y)
end



---Executed whenever a mouse button is pressed anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
function Editor:mousepressed(x, y, button)
    if not self.enabled then
        return
    end
    self.UI:mousepressed(x, y, button)
    self.INPUT_DIALOG:mousepressed(x, y, button)
	if button == 1 and not self:isUIHovered() then
        if _IsCtrlPressed() then
            -- Ctrl+Click parents the selected node instead.
            self:parentSelectedNodeToHoveredNode()
        else
            self:selectNode(self.hoveredNode)
            if self.selectedNode then
                if not self.isNodeHoverIndirect then
                    -- Start dragging the actual node on the screen.
                    self:startDraggingSelectedNode()
                else
                    -- Start dragging the node on the node tree list.
                    self:startDraggingSelectedNodeInNodeTree()
                end
            end
        end
    elseif button == 2 then
        if self.nodeDragOrigin then
            -- Cancel dragging if the right click is received.
            self:cancelDraggingSelectedNode()
        end
        if self.nodeTreeDragOrigin then
            -- Cancel dragging if the right click is received.
            self:cancelDraggingSelectedNodeInNodeTree()
        end
	end
end



---Executed whenever a mouse button is released anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function Editor:mousereleased(x, y, button)
    self.UI:mousereleased(x, y, button)
    self.INPUT_DIALOG:mousereleased(x, y, button)
    if button == 1 then
        self:finishDraggingSelectedNode()
        self:finishDraggingSelectedNodeInNodeTree()
    end
end



---Executed whenever a key is pressed on the keyboard.
---@param key string The key code.
function Editor:keypressed(key)
    love.keyboard.setKeyRepeat(key == "backspace")
    self.UI:keypressed(key)
    self.INPUT_DIALOG:keypressed(key)
	if key == "tab" then
		self.enabled = not self.enabled
    elseif key == "up" then
        self:moveSelectedNode(Vec2(0, -1))
    elseif key == "down" then
        self:moveSelectedNode(Vec2(0, 1))
    elseif key == "left" then
        self:moveSelectedNode(Vec2(-1, 0))
    elseif key == "right" then
        self:moveSelectedNode(Vec2(1, 0))
    elseif key == "pageup" and _IsShiftPressed() then
        self:moveSelectedNodeToTop()
    elseif key == "pagedown" and _IsShiftPressed() then
        self:moveSelectedNodeToBottom()
    elseif key == "z" and _IsCtrlPressed() then
        self:undoLastCommand()
    elseif key == "y" and _IsCtrlPressed() then
        self:redoLastCommand()
	end
end



---Executed whenever a certain character has been typed on the keyboard.
---@param text string The character.
function Editor:textinput(text)
    self.INPUT_DIALOG:textinput(text)
end



return Editor