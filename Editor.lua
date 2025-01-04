local class = require "com.class"

---@class Editor
---@overload fun():Editor
local Editor = class:derive("Editor")

local Vec2 = require("Vector2")
local Node = require("Node")
local Input = require("Input")
local EditorUITree = require("EditorUITree")

local CommandNodeAdd = require("EditorCommands.NodeAdd")
local CommandNodeRename = require("EditorCommands.NodeRename")
local CommandNodeMove = require("EditorCommands.NodeMove")
local CommandNodeDrag = require("EditorCommands.NodeDrag")
local CommandNodeResize = require("EditorCommands.NodeResize")
local CommandNodeDelete = require("EditorCommands.NodeDelete")
local CommandNodeSetParent = require("EditorCommands.NodeSetParent")
local CommandNodeSetAlign = require("EditorCommands.NodeSetAlign")
local CommandNodeSetParentAlign = require("EditorCommands.NodeSetParentAlign")
local CommandNodeSetProperty = require("EditorCommands.NodeSetProperty")
local CommandNodeSetWidgetProperty = require("EditorCommands.NodeSetWidgetProperty")
local CommandNodeMoveUp = require("EditorCommands.NodeMoveUp")
local CommandNodeMoveDown = require("EditorCommands.NodeMoveDown")
local CommandNodeMoveToTop = require("EditorCommands.NodeMoveToTop")
local CommandNodeMoveToBottom = require("EditorCommands.NodeMoveToBottom")

---@alias EditorCommand* EditorCommandNodeAdd|EditorCommandNodeRename|EditorCommandNodeMove|EditorCommandNodeDrag|EditorCommandNodeResize|EditorCommandNodeDelete|EditorCommandNodeSetParent|EditorCommandNodeSetAlign|EditorCommandNodeSetParentAlign|EditorCommandNodeSetProperty|EditorCommandNodeSetWidgetProperty|EditorCommandNodeMoveUp|EditorCommandNodeMoveDown|EditorCommandNodeMoveToTop|EditorCommandNodeMoveToBottom|EditorCommandNodeMoveToIndex



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
--- - Resizing widgets like boxes
---
--- To Do:
--- - Saving layouts
--- - Loading/switching layouts
--- - Live editing of parameters
--- - Vector support for parameters
--- - Finish widget parameters
--- - Copy/Paste and widget duplication
--- - Adding new nodes (and entire node groups for stuff like buttons, scroll bars, etc.)
---   - tip: have a Button class as a controller for the children which have unchangeable names and references them directly by name in the constructor
--- - Multi-selection(?)
--- - Animations at some point



---Constructs a new UI Editor.
function Editor:new()
    self.UI = nil
    self.INPUT_DIALOG = Input()

    self.NODE_RESIZE_DIRECTIONS = {
        Vec2(-1, -1),
        Vec2(0, -1),
        Vec2(1, -1),
        Vec2(-1, 0),
        Vec2(1, 0),
        Vec2(-1, 1),
        Vec2(0, 1),
        Vec2(1, 1)
    }

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
    self.nodeResizeOrigin = nil
    self.nodeResizeOriginalPos = nil
    self.nodeResizeOriginalSize = nil
    self.nodeResizeDirection = nil

    self.uiTree = EditorUITree(self)
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



---Prints the internal Editor UI tree to the console.
function Editor:printInternalUITreeInfo()
    -- Node tree
    for i, line in ipairs(self:getUITreeInfo(self.UI)) do
        local suffix = ""
        if line.node.isController then
            suffix = suffix .. " (controller)"
        elseif line.node:isControlled() then
            suffix = suffix .. " (controlled)"
        end
        print(string.rep("    ", line.indent) .. string.format("%s {%s}", (line.node.name ~= "" and line.node.name or "<unnamed>"), line.node.type) .. suffix)
    end
end



---Returns the currently hovered Node.
---This function also sets the values of the `self.isNodeHoverIndirect`, `self.nodeTreeHoverTop` and `self.nodeTreeHoverBottom` fields.
---
---This function should only be called internally. If you want to get the currently hovered node, fetch the `self.hoveredNode` field instead.
---@return Node?
function Editor:getHoveredNode()
    self.isNodeHoverIndirect = false
    -- Editor UI has hover precedence over actual UI.
    if self:isUIHovered() then
        return nil
    end
    -- Look whether we've hovered over any UI info entry.
    local hoveredNode = self.uiTree:getHoveredNode()
    if hoveredNode then
        return hoveredNode
    end
    -- Finally, look if any node is directly hovered.
	return _UI:findChildByPixelDepthFirst(_MouseCPos)
end



---Returns `true` if the given Node Property is currently supported by the editor.
---@param property table The property in its entirety, as an item of the `Widget:getPropertyList()` result table.
---@return boolean
function Editor:isNodePropertySupported(property)
    return property.type == "string" or property.type == "number" or property.type == "color"
end



---Marks the provided node as selected and updates all UI in order to facilitate editing its properties.
---@param node Node? The node to be selected. If not provided, all nodes will be deselected.
function Editor:selectNode(node)
    self.selectedNode = node
    -- Clear all properties.
    local previousPropertiesUI = self.UI:findChildByName("properties")
    if previousPropertiesUI then
        previousPropertiesUI:removeSelf()
    end
    -- Make a new property list UI.
    if node then
        local propertiesUI = Node({name = "properties", pos = {x = 1220, y = 60}})
        local currentRow = 0
        local nodeProperties = node:getPropertyList()
        local propertyHeaderUI = self:label(0, currentRow * 20, "Node Properties")
        currentRow = currentRow + 1
        propertiesUI:addChild(propertyHeaderUI)
        for i, property in ipairs(nodeProperties) do
            local inputValue
            inputValue = node[property.key]
            local inputFunction = function(input)
                self:setSelectedNodeProperty(property.key, input)
            end
            local propertyUI = Node({name = "input", pos = {x = 0, y = currentRow * 20}})
            currentRow = currentRow + 1
            local propertyText = self:label(0, 0, property.name)
            local propertyInput = self:input(150, 0, 200, property.type, inputValue, inputFunction)
            self:inputSetDisabled(propertyInput, not self:isNodePropertySupported(property) or (node:isControlled() and property.disabledIfControlled))
            propertyUI:addChild(propertyText)
            propertyUI:addChild(propertyInput)
            propertiesUI:addChild(propertyUI)
        end
        local widget = node.widget
        if widget then
            if widget.getPropertyList then
                local properties = widget:getPropertyList()
                local propertyHeaderUI = self:label(0, currentRow * 20, "Widget Properties")
                currentRow = currentRow + 1
                propertiesUI:addChild(propertyHeaderUI)
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
                    local propertyUI = Node({name = "input", pos = {x = 0, y = currentRow * 20}})
                    currentRow = currentRow + 1
                    local propertyText = self:label(0, 0, property.name)
                    local propertyInput = self:input(150, 0, 200, property.type, inputValue, inputFunction)
                    self:inputSetDisabled(propertyInput, not self:isNodePropertySupported(property))
                    propertyUI:addChild(propertyText)
                    propertyUI:addChild(propertyInput)
                    propertiesUI:addChild(propertyUI)
                end
            end
        end
        self.UI:addChild(propertiesUI)
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



---Starts resizing the selected node, starting from the current mouse position.
---@param handleID integer The ID of the resize handle that has been grabbed.
function Editor:startResizingSelectedNode(handleID)
    if not self.selectedNode then
        return
    end
    self.nodeResizeOrigin = _MouseCPos
    self.nodeResizeOriginalPos = self.selectedNode:getPos()
    self.nodeResizeOriginalSize = self.selectedNode:getSize()
    self.nodeResizeDirection = self.NODE_RESIZE_DIRECTIONS[handleID]
end



---Finishes resizing the selected node and pushes a command so that this process can be undone.
function Editor:finishResizingSelectedNode()
    if not self.selectedNode or not self.nodeResizeOriginalPos then
        return
    end
    self:executeCommand(CommandNodeResize(self.selectedNode, self.nodeResizeOriginalPos, self.nodeResizeOriginalSize))
    self.nodeResizeOrigin = nil
    self.nodeResizeOriginalPos = nil
    self.nodeResizeOriginalSize = nil
    self.nodeResizeDirection = nil
end



---Restores the original selected node's positions and size and finishes the resizing process.
function Editor:cancelResizingSelectedNode()
    if not self.selectedNode or not self.nodeResizeOriginalPos then
        return
    end
    self.selectedNode:setPos(self.nodeResizeOriginalPos)
    self.selectedNode:setSize(self.nodeResizeOriginalSize)
    self:finishResizingSelectedNode()
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



---Sets a new value for the selected node property.
---@param property string The property to be set.
---@param value any? The value to be set for this property.
function Editor:setSelectedNodeProperty(property, value)
    self:executeCommand(CommandNodeSetProperty(self.selectedNode, property, value))
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



---Saves the current scene to a file.
---@param name string The file name.
function Editor:save(name)
    _Utils.saveJson(name .. ".json", _UI:serialize())
end



---Convenience function which creates an editor label.
---@param x number The X coordinate of the label position.
---@param y number The Y coordinate of the label position.
---@param text string The text that should be written on the label.
---@return Node
function Editor:label(x, y, text)
    local label = Node({name = "lb_" .. text, type = "text", widget = {font = "editor", text = text, shadowOffset = 2, shadowAlpha = 0.8}, pos = {x = x, y = y}})
    return label
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
    local button = Node({name = "btn_" .. text, type = "9sprite", widget = {image = "ed_button", clickImage = "ed_button_click", size = {x = w, y = 20}, scale = 2}, shortcut = key, pos = {x = x, y = y}, children = {{name = "$text", type = "text", widget = {font = "default", text = text, color = _COLORS.black}, pos = {x = 0, y = -1}, align = "center", parentAlign = "center"}}})
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
        input = Node({name = "inp_" .. type, type = "9sprite", widget = {image = "ed_input", hoverImage = "ed_input_hover", disabledImage = "ed_input_disabled", size = {x = w, y = 20}}, pos = {x = x, y = y}, children = {{name = "$text", type = "text", widget = {font = "default", text = tostring(value), color = _COLORS.white}, pos = {x = 4, y = -1}, align = "left", parentAlign = "left"}}})
    else
        input = Node({name = "inp_" .. type, type = "9sprite", widget = {image = "ed_input", hoverImage = "ed_input_hover", disabledImage = "ed_input_disabled", size = {x = w, y = 20}}, pos = {x = x, y = y}, children = {{name = "$color", type = "box", widget = {color = value, size = {x = w - 2, y = 18}}, pos = {x = 0, y = -1}, align = "center", parentAlign = "center"}}})
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
    local UTILITY_X = 0
    local UTILITY_Y = 700
    local ALIGN_X = 200
    local ALIGN_Y = 800
    local PALIGN_X = 400
    local PALIGN_Y = 800
    local buttons = {
        self:button(UTILITY_X, UTILITY_Y, 150, "Delete [Del]", function() self:deleteSelectedNode() end, "delete"),
        self:button(UTILITY_X, UTILITY_Y + 20, 150, "Layer Up [PgUp]", function() self:moveSelectedNodeUp() end, "pageup"),
        self:button(UTILITY_X, UTILITY_Y + 40, 150, "Layer Down [PgDown]", function() self:moveSelectedNodeDown() end, "pagedown"),
        self:button(UTILITY_X, UTILITY_Y + 60, 150, "Undo [Ctrl+Z]", function() self:undoLastCommand() end),
        self:button(UTILITY_X, UTILITY_Y + 80, 150, "Redo [Ctrl+Y]", function() self:redoLastCommand() end),
        self:button(UTILITY_X, UTILITY_Y + 130, 75, "Box", function() self:addNode(Node({name = "NewNode", type = "box", widget = {size = {x = 10, y = 10}, color = {r = 1, g = 1, b = 1}}})) end),
        self:button(UTILITY_X + 75, UTILITY_Y + 130, 75, "Text", function() self:addNode(Node({name = "NewNode", type = "text", widget = {font = "standard", text = "You can't change me!"}})) end),

        self:button(ALIGN_X, ALIGN_Y, 30, "TL", function() self:setSelectedNodeAlign(_ALIGNMENTS.topLeft) end),
        self:button(ALIGN_X + 30, ALIGN_Y, 30, "T", function() self:setSelectedNodeAlign(_ALIGNMENTS.top) end),
        self:button(ALIGN_X + 60, ALIGN_Y, 30, "TR", function() self:setSelectedNodeAlign(_ALIGNMENTS.topRight) end),
        self:button(ALIGN_X, ALIGN_Y + 20, 30, "ML", function() self:setSelectedNodeAlign(_ALIGNMENTS.left) end),
        self:button(ALIGN_X + 30, ALIGN_Y + 20, 30, "M", function() self:setSelectedNodeAlign(_ALIGNMENTS.center) end),
        self:button(ALIGN_X + 60, ALIGN_Y + 20, 30, "MR", function() self:setSelectedNodeAlign(_ALIGNMENTS.right) end),
        self:button(ALIGN_X, ALIGN_Y + 40, 30, "BL", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottomLeft) end),
        self:button(ALIGN_X + 30, ALIGN_Y + 40, 30, "B", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottom) end),
        self:button(ALIGN_X + 60, ALIGN_Y + 40, 30, "BR", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottomRight) end),

        self:button(PALIGN_X, PALIGN_Y, 30, "TL", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.topLeft) end),
        self:button(PALIGN_X + 30, PALIGN_Y, 30, "T", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.top) end),
        self:button(PALIGN_X + 60, PALIGN_Y, 30, "TR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.topRight) end),
        self:button(PALIGN_X, PALIGN_Y + 20, 30, "ML", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.left) end),
        self:button(PALIGN_X + 30, PALIGN_Y + 20, 30, "M", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.center) end),
        self:button(PALIGN_X + 60, PALIGN_Y + 20, 30, "MR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.right) end),
        self:button(PALIGN_X, PALIGN_Y + 40, 30, "BL", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottomLeft) end),
        self:button(PALIGN_X + 30, PALIGN_Y + 40, 30, "B", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottom) end),
        self:button(PALIGN_X + 60, PALIGN_Y + 40, 30, "BR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottomRight) end),
    }
    for i, button in ipairs(buttons) do
        self.UI:addChild(button)
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
			if movement:len() >= 5 then
                self.nodeDragSnap = false
			end
		else
			self.selectedNode:setPos(self.nodeDragOriginalPos + movement)
		end
	end

    -- Handle the node resizing.
    if self.selectedNode and self.nodeResizeOrigin then
        local movement = (_MouseCPos - self.nodeResizeOrigin):floor()
        local posVector = ((self.nodeResizeDirection - 1) / 2 + self.selectedNode:getAlign()) * self.nodeResizeDirection
        self.selectedNode:setPos(((self.nodeResizeOriginalPos + movement * posVector) + 0.5):floor())
        self.selectedNode:setSize(self.nodeResizeOriginalSize + movement * self.nodeResizeDirection)
    end

    self.uiTree:update(dt)

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
	self.UI:findChildByName("hovText").widget.text = ""
	self.UI:findChildByName("selText").widget.text = ""

    -- Hovered and selected node
    if self.hoveredNode then
        self.UI:findChildByName("hovText").widget.text = string.format("Hovered: %s {%s} pos: %s -> %s", self.hoveredNode.name, self.hoveredNode.type, self.hoveredNode:getPos(), self.hoveredNode:getGlobalPos())
    end
    if self.selectedNode then
        self.UI:findChildByName("selText").widget.text = string.format("Selected: %s {%s} pos: %s -> %s", self.selectedNode.name, self.selectedNode.type, self.selectedNode:getPos(), self.selectedNode:getGlobalPos())
    end
	self.UI:draw()

    -- Other UI that will be hardcoded for now.
    love.graphics.setFont(_FONTS.editor)

    -- UI tree
    self.uiTree:draw()

    -- Command buffer
    local COMMAND_BUFFER_POS = Vec2(1220, 400)
    local COMMAND_BUFFER_ITEM_HEIGHT = 20
    self:drawShadowedText("Command Buffer", COMMAND_BUFFER_POS.x, COMMAND_BUFFER_POS.y)
    local y = COMMAND_BUFFER_POS.y + 30
    for i, command in ipairs(self.commandHistory) do
        if #command > 0 then
            self:drawShadowedText("Transaction {", COMMAND_BUFFER_POS.x, y)
            y = y + COMMAND_BUFFER_ITEM_HEIGHT
            for j, subcommand in ipairs(command) do
                self:drawShadowedText(subcommand.NAME, COMMAND_BUFFER_POS.x + 30, y)
                y = y + COMMAND_BUFFER_ITEM_HEIGHT
            end
            if command ~= self.commandHistory[#self.commandHistory] or not self.transactionMode then
                self:drawShadowedText("}", COMMAND_BUFFER_POS.x, y)
                y = y + COMMAND_BUFFER_ITEM_HEIGHT
            end
        else
            self:drawShadowedText(command.NAME, COMMAND_BUFFER_POS.x, y)
            y = y + COMMAND_BUFFER_ITEM_HEIGHT
        end
    end

    -- Buttons
    self:drawShadowedText("New Widget:", 5, 810)
    self:drawShadowedText("Node Align", 200, 780)
    self:drawShadowedText("Parent Align", 400, 780)
    self:drawShadowedText("Ctrl+Click a node to make it a parent of the currently selected node", 200, 870)

    -- Widget properties
    if self.selectedNode then
        local widget = self.selectedNode.widget
        if widget then
            if not widget.getPropertyList then
                self:drawShadowedText("This Widget does not support properties yet!", 1220, 30)
            end
        else
            self:drawShadowedText("This Node does not have a widget.", 1220, 30)
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
        local w = love.graphics.getFont():getWidth(text)
        local h = love.graphics.getFont():getHeight()
        love.graphics.setColor(backgroundColor.r, backgroundColor.g, backgroundColor.b, 0.5)
        love.graphics.rectangle("fill", x - 2, y - 2, w + 4, h + 4)
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
        local resizeHandleID = self.selectedNode and self.selectedNode:getHoveredResizeHandleID()
        if _IsCtrlPressed() then
            -- Ctrl+Click parents the selected node instead.
            self:parentSelectedNodeToHoveredNode()
        elseif resizeHandleID then
            -- We've grabbed a resize handle of the currently selected node!
            self:startResizingSelectedNode(resizeHandleID)
        else
            self:selectNode(self.hoveredNode)
            if self.selectedNode then
                if not self.isNodeHoverIndirect then
                    -- Start dragging the actual node on the screen.
                    self:startDraggingSelectedNode()
                else
                    -- Start dragging the node on the node tree list.
                    self.uiTree:startDraggingSelectedNodeInNodeTree()
                end
            end
        end
    elseif button == 2 then
        -- Cancel dragging if the right click is received.
        self:cancelDraggingSelectedNode()
        self:cancelResizingSelectedNode()
        self.uiTree:cancelDraggingSelectedNodeInNodeTree()
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
        self:finishResizingSelectedNode()
        self.uiTree:finishDraggingSelectedNodeInNodeTree()
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
    elseif key == "s" and _IsCtrlPressed() then
        self:save("ui_test")
    elseif key == "z" and _IsCtrlPressed() then
        self:undoLastCommand()
    elseif key == "y" and _IsCtrlPressed() then
        self:redoLastCommand()
    elseif key == "p" and _IsCtrlPressed() then
        self:printInternalUITreeInfo()
	end
end



---Executed whenever a certain character has been typed on the keyboard.
---@param text string The character.
function Editor:textinput(text)
    self.INPUT_DIALOG:textinput(text)
end



return Editor