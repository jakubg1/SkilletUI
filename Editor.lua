local class = require "com.class"

---@class Editor
---@overload fun():Editor
local Editor = class:derive("Editor")

local Vec2 = require("Vector2")
local Node = require("Node")
local Input = require("Input")
local EditorUITree = require("EditorUITree")
local EditorCommands = require("EditorCommands")

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
--- - Saving layouts
--- - Loading/switching layouts
--- - Finish widget parameters
--- - Proper editing of node groups (size forwarding, unable to edit their components, etc.)
--- - Nullifying parameters
--- - Copy/Paste and widget duplication
---
--- To Do:
--- - Live editing of parameters
--- - Vector and image support for parameters
--- - Node modifier system, where you could add a rule, like: "modify this node and all its children's widgets' alpha by multiplying it by 0.5"
--- - Adding new nodes (and entire node groups for stuff like buttons, scroll bars, etc.)
---   - tip: have a Button class as a controller for the children which have unchangeable names and references them directly by name in the constructor
--- - Multi-selection(?)
--- - Animations and timelines



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

    self.currentSceneFile = nil
    self.isSceneModified = false
    self.clipboard = nil

    self.enabled = true
    self.activeInput = nil -- Can be a Node, but also `"save"` or `"load"`
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
    self.uiTreeShowsInternalUI = false

    self.commandMgr = EditorCommands(self)
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
    -- Already selected nodes take over the hover, regardless of whatever is over it.
    if self.selectedNode and self.selectedNode:isHovered() then
        return self.selectedNode
    end
    -- Finally, look if any node is directly hovered.
	return _UI:findChildByPixelDepthFirst(_MouseCPos, true)
end



---Returns `true` if the given Node Property is currently supported by the editor.
---@param property table The property in its entirety, as an item of the `Widget:getPropertyList()` result table.
---@return boolean
function Editor:isNodePropertySupported(property)
    return property.type == "string" or property.type == "number" or property.type == "color" or property.type == "boolean"
end



---Refreshes all critical UI for Editors, for example the node properties.
function Editor:refreshUI()
    -- If the selected node has been removed, deselect it.
    if _UI ~= self.selectedNode and not _UI:findChild(self.selectedNode) and self.UI ~= self.selectedNode and not self.UI:findChild(self.selectedNode) then
        self.selectedNode = nil
    end
    self:generateNodePropertyUI(self.selectedNode)
end



---Clears and regenerates the UI for given node's properties.
---@param node Node? The Node to generate property UI for. If not set, the node properties UI will be cleared.
function Editor:generateNodePropertyUI(node)
    -- Clear all properties.
    local previousPropertiesUI = self.UI:findChildByName("properties")
    if previousPropertiesUI then
        previousPropertiesUI:removeSelf()
    end
    -- Make a new property list UI.
    if node then
        local propertiesUI = Node({name = "properties", pos = {1220, 60}})
        local currentRow = 0
        local nodeProperties = node:getPropertyList()
        local propertyHeaderUI = self:label(0, currentRow * 20, "Node Properties")
        propertyHeaderUI.widget.underline = true
        propertyHeaderUI.widget.characterSeparation = 2
        currentRow = currentRow + 1
        propertiesUI:addChild(propertyHeaderUI)
        for i, property in ipairs(nodeProperties) do
            local inputValue = node[property.key]
            local inputFunction = function(input)
                self:setSelectedNodeProperty(property.key, input)
            end
            local propertyUI = Node({name = "input", pos = {0, currentRow * 20}})
            currentRow = currentRow + 1
            local propertyText = self:label(0, 0, property.name)
            local propertyInput = self:input(150, 0, 200, property.type, inputValue, property.nullable, inputFunction)
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
                propertyHeaderUI.widget.underline = true
                propertyHeaderUI.widget.characterSeparation = 2
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
                    local propertyUI = Node({name = "input", pos = {0, currentRow * 20}})
                    currentRow = currentRow + 1
                    local propertyText = self:label(0, 0, property.name)
                    local propertyInput = self:input(150, 0, 200, property.type, inputValue, property.nullable, inputFunction)
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



---Marks the provided node as selected and updates all UI in order to facilitate editing its properties.
---@param node Node? The node to be selected. If not provided, all nodes will be deselected.
function Editor:selectNode(node)
    self.selectedNode = node
    self:refreshUI()
end



---Adds the provided UI node as the currently selected node's sibling, or, if no node is selected, to the root node.
---@param node Node The node to be added.
function Editor:addNode(node)
    self:executeCommand(CommandNodeAdd(node, self.selectedNode and self.selectedNode.parent or _UI))
end



---Copies the currently selected UI node to the internal clipboard.
function Editor:copySelectedNode()
    if not self.selectedNode then
        return
    end
    self.clipboard = self.selectedNode:serialize()
end



---Pastes the UI node which is stored in the internal clipboard and adds it as the currently selected node's sibling (or to the root node).
---The newly added Node will be selected.
function Editor:pasteNode()
    if not self.clipboard then
        return
    end
    local node = Node(self.clipboard)
    self:addNode(node)
    self:selectNode(node)
end



---Duplicates the currently selected UI node and selects the newly made duplicate.
function Editor:duplicateSelectedNode()
    if not self.selectedNode then
        return
    end
    local data = self.selectedNode:serialize()
    local node = Node(data)
    self:addNode(node)
    self:selectNode(node)
end



---Renames the currently selected UI node.
---@param name string The new name.
function Editor:renameSelectedNode(name)
    self:executeCommand(CommandNodeRename(self.selectedNode, name))
end



---Moves the currently selected UI node by the given amount of pixels.
---@param offset Vector2 The movement vector the selected UI node should be moved towards.
function Editor:moveSelectedNode(offset)
    self:executeCommand(CommandNodeMove(self.selectedNode, offset), "widgetMove")
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
    -- If we were dragging a freshly duplicated node, we need to commit the transaction.
    if self.commandMgr.transactionMode then
        self:commitCommandTransaction()
    end
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
    -- If we were dragging a freshly duplicated node, we need to cancel the transaction.
    if self.commandMgr.transactionMode then
        self:cancelCommandTransaction()
    end
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
    self:executeCommand(CommandNodeDelete(self.selectedNode))
end



---Executes an editor command.
---If the command has been executed successfully, it can be undone using `:undoLastCommand()`.
---Returns `true` if the command has been executed successfully. Otherwise, returns `false`.
---@param command EditorCommand* The command to be performed.
---@param groupID string? An optional group identifier for this command execution. If set, commands with the same group ID will be grouped together, and so will be packed into a single command transaction.
---@return boolean
function Editor:executeCommand(command, groupID)
    local result = self.commandMgr:executeCommand(command, groupID)
    if result then
        -- Mark the scene as unsaved.
        self.isSceneModified = true
        -- Make sure to refresh UIs.
        self:refreshUI()
    end
    return result
end



---Starts a command transaction.
---Command transactions bundle a few commands into an atomic pack. It only can be undone as a whole.
---To close a command transaction, use `:commitCommandTransaction()`.
---@param groupID string? An optional group identifier for this command group. If set, any incoming command that does not match this group will automatically commit this transaction.
function Editor:startCommandTransaction(groupID)
    self.commandMgr:startCommandTransaction(groupID)
end



---Closes a command transaction.
---From this point, any new commands will be added separately, as usual.
function Editor:commitCommandTransaction()
    self.commandMgr:commitCommandTransaction()
end



---Cancels a command transaction by undoing all commands that have been already executed and removing the transaction from the stack.
---Cancelled command transactions can NOT be restored.
function Editor:cancelCommandTransaction()
    self.commandMgr:cancelCommandTransaction()
    -- Make sure to refresh UIs.
    self:refreshUI()
end



---Undoes the command that has been executed last and moves it to the undo command stack.
function Editor:undoLastCommand()
    self.commandMgr:undoLastCommand()
    -- Mark the scene as unsaved.
    self.isSceneModified = true
    -- Make sure to refresh UIs.
    self:refreshUI()
end



---Redoes the undone command and moves it back to the main command stack.
function Editor:redoLastCommand()
    self.commandMgr:redoLastCommand()
    -- Mark the scene as unsaved.
    self.isSceneModified = true
    -- Make sure to refresh UIs.
    self:refreshUI()
end



---Creates a new blank scene.
function Editor:newScene()
    _UI = Node({name = "root", canvasInputMode = true})
    self.currentSceneFile = nil
    self.isSceneModified = false
    -- Deselect any selected nodes.
    self:selectNode()
    -- Remove everything from the undo stack.
    self.commandHistory = {}
    self.undoCommandHistory = {}
end



---Loads a new scene from the specified file.
---@param path string The path to the file.
function Editor:loadScene(path)
    _UI = _LoadUI(path)
    self.currentSceneFile = path
    self.isSceneModified = false
    -- Deselect any selected nodes.
    self:selectNode()
    -- Remove everything from the undo stack.
    self.commandHistory = {}
    self.undoCommandHistory = {}
end



---Saves the current scene to a file.
---@param path string The path to the file.
function Editor:saveScene(path)
    _Utils.saveJson(path, _UI:serialize())
    self.currentSceneFile = path
    self.isSceneModified = false
end



---Convenience function which creates an editor label.
---@param x number The X coordinate of the label position.
---@param y number The Y coordinate of the label position.
---@param text string The text that should be written on the label.
---@param name string? The label name.
---@return Node
function Editor:label(x, y, text, name)
    local label = Node({name = name or ("lb_" .. text), type = "text", widget = {font = "editor", text = text, shadowOffset = 2, shadowAlpha = 0.8}, pos = {x, y}})
    return label
end



---Convenience function which creates an editor button.
---@param x number The X coordinate of the button position.
---@param y number The Y coordinate of the button position.
---@param w number The width of the button. Height is always 20.
---@param text string The text that should be written on the button.
---@param fn function? The function to be executed when this button is clicked.
---@param shortcut table? The key which will activate this button.
---@return Node
function Editor:button(x, y, w, text, fn, shortcut)
    local button = Node({name = "btn_" .. text, type = "9sprite", widget = {image = "ed_button", clickImage = "ed_button_click", size = {w, 20}, scale = 2}, shortcut = shortcut, pos = {x, y}, children = {{name = "$text", type = "text", widget = {font = "default", text = text, color = _COLORS.black}, pos = {0, -1}, align = "center", parentAlign = "center"}}})
    button:setOnClick(fn)
    return button
end



---Convenience function which creates an editor input field.
---@param x number The X coordinate of the position.
---@param y number The Y coordinate of the position.
---@param w number The width of the input field. Height is always 20.
---@param type string The input type. Can be `"string"`, `"number"`, `"color"` or `"file"`.
---@param value string|number|Color The value that should be initially set in the input field.
---@param nullable boolean? Whether the contents can be erased with a builtin X button.
---@param fn function? The function that will be executed when the value has been changed. The parameter will be the new text.
---@param extensions table? If `type` == `"file"`, the list of file extensions to be listed in the file picker.
---@return Node
function Editor:input(x, y, w, type, value, nullable, fn, extensions)
    local data = {
        name = "inp_" .. type,
        type = "input_text",
        pos = {x, y},
        children = {
            {
                name = "text",
                type = "text",
                widget = {
                    font = "default",
                    color = _COLORS.white
                },
                pos = {4, -1},
                align = "left",
                parentAlign = "left"
            },
            {
                name = "color",
                type = "box",
                visible = false,
                widget = {
                    color = _COLORS.white,
                    size = {w - 2, 18}
                },
                pos = {0, -1},
                align = "center",
                parentAlign = "center"
            },
            {
                name = "sprite",
                type = "9sprite",
                widget = {
                    image = "ed_input",
                    hoverImage = "ed_input_hover",
                    disabledImage = "ed_input_disabled",
                    size = {w, 20}
                },
                children = {
                    {
                        name = "nullifyButton",
                        type = "button",
                        align = "left",
                        parentAlign = "right",
                        children = {
                            {
                                name = "text",
                                type = "text",
                                widget = {
                                    font = "editor",
                                    text = "X",
                                    color = _COLORS.black
                                },
                                align = "center",
                                parentAlign = "center"
                            },
                            {
                                name = "sprite",
                                type = "9sprite",
                                widget = {
                                    image = "ed_button",
                                    clickImage = "ed_button_click",
                                    size = {20, 20}
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    local input = Node(data)
    input.widget.nullable = nullable or false
    input.widget:setType(type)
    input.widget:setValue(value)
    input:setOnClick(function() self:askForInput(input, type, extensions) end)
    if nullable and fn then
        input:findChildByName("nullifyButton"):setOnClick(function() fn(nil) end)
    end
    input._onChange = fn
    return input
end



---Sets whether an editor input field should be disabled.
---@param node Node The editor input field.
---@param disabled boolean Whether the field should be disabled.
function Editor:inputSetDisabled(node, disabled)
    node:setDisabled(disabled)
    node.widget:updateUI()
end



---Executed when an editor input field has been clicked.
---@param input Node|string The input node that has been clicked, or an identifier. Currently supported identifiers are `"save"` and `"load"`.
---@param inputType string The input type. Can be `"string"`, `"number"`, `"color"` or `"file"`.
---@param extensions table? If `type` == `"file"`, the list of file extensions to be listed in the input box.
---@param warnWhenFileExists boolean? If `type` == `"file"`, whether a file overwrite warning should be shown if the file exists.
function Editor:askForInput(input, inputType, extensions, warnWhenFileExists)
    self.activeInput = input
    if inputType == "boolean" then
        -- HACK: When asking for a boolean.... why would you do that? Let's just immediately flip the value instead.
        self:onInputReceived(not input.widget:getValue())
    else
        local value = ""
        if type(input) ~= "string" then
            value = input.widget:getValue()
        end
        self.INPUT_DIALOG:inputAsk(inputType, value, extensions, warnWhenFileExists)
    end
end



---Executed when an input has been submitted for a certain editor input field.
---@param result string|number|Color|boolean The value that has been submitted for this input.
function Editor:onInputReceived(result)
    if type(self.activeInput) == "string" then
        if self.activeInput == "save" then
            self:saveScene(result)
        elseif self.activeInput == "load" then
            self:loadScene(result)
        end
    else
        -- Not required for property lists, but required for file name.
        self.activeInput.widget:setValue(result)
    
        if self.activeInput._onChange then
            self.activeInput._onChange(result)
        end
    end
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
    local NEW_X = 5
    local NEW_Y = 100
    local UTILITY_X = 0
    local UTILITY_Y = 700
    local ALIGN_X = 250
    local ALIGN_Y = 600
    local PALIGN_X = 450
    local PALIGN_Y = 600
    local FILE_X = 250
    local FILE_Y = 10
    local nodes = {
        self:button(UTILITY_X, UTILITY_Y, 100, "Delete [Del]", function() self:deleteSelectedNode() end, {key = "delete"}),
        self:button(UTILITY_X + 100, UTILITY_Y, 100, "Duplicate [Ctrl+D]", function() self:deleteSelectedNode() end, {ctrl = true, key = "d"}),
        self:button(UTILITY_X, UTILITY_Y + 20, 200, "Layer Up [PgUp]", function() self:moveSelectedNodeUp() end, {key = "pageup"}),
        self:button(UTILITY_X, UTILITY_Y + 40, 200, "Layer Down [PgDown]", function() self:moveSelectedNodeDown() end, {key = "pagedown"}),
        self:button(UTILITY_X, UTILITY_Y + 60, 200, "To Top [Shift+PgUp]", function() self:moveSelectedNodeUp() end, {shift = true, key = "pageup"}),
        self:button(UTILITY_X, UTILITY_Y + 80, 200, "To Bottom [Shift+PgDown]", function() self:moveSelectedNodeDown() end, {shift = true, key = "pagedown"}),
        self:button(UTILITY_X, UTILITY_Y + 100, 100, "Undo [Ctrl+Z]", function() self:undoLastCommand() end, {ctrl = true, key = "z"}),
        self:button(UTILITY_X + 100, UTILITY_Y + 100, 100, "Redo [Ctrl+Y]", function() self:redoLastCommand() end, {ctrl = true, key = "y"}),
        self:button(UTILITY_X, UTILITY_Y + 120, 100, "Copy [Ctrl+C]", function() self:copySelectedNode() end, {ctrl = true, key = "c"}),
        self:button(UTILITY_X + 100, UTILITY_Y + 120, 100, "Paste [Ctrl+V]", function() self:pasteNode() end, {ctrl = true, key = "v"}),
        self:label(NEW_X, NEW_Y - 20, "New Widget:"),
        self:button(NEW_X, NEW_Y, 55, "Box", function() self:addNode(Node({type = "box"})) end),
        self:button(NEW_X + 55, NEW_Y, 55, "Text", function() self:addNode(Node({type = "text"})) end),
        self:button(NEW_X + 110, NEW_Y, 55, "9Sprite", function() self:addNode(Node({type = "9sprite"})) end),
        self:button(NEW_X + 165, NEW_Y, 55, "Button", function() self:addNode(Node({type = "button", children = {{name = "text", type = "text", align = "center", parentAlign = "center"}, {name = "sprite", type = "9sprite"}}})) end),
        self:button(NEW_X, NEW_Y + 20, 110, "TitleDigit", function() self:addNode(Node({type = "@titleDigit"})) end),
        self:button(NEW_X + 110, NEW_Y + 20, 110, "Test Btn", function() self:addNode(Node(_Utils.loadJson("layouts/snippet_test2.json"))) end),

        self:label(ALIGN_X, ALIGN_Y, "Node Align"),
        self:button(ALIGN_X, ALIGN_Y + 20, 30, "TL", function() self:setSelectedNodeAlign(_ALIGNMENTS.topLeft) end),
        self:button(ALIGN_X + 30, ALIGN_Y + 20, 30, "T", function() self:setSelectedNodeAlign(_ALIGNMENTS.top) end),
        self:button(ALIGN_X + 60, ALIGN_Y + 20, 30, "TR", function() self:setSelectedNodeAlign(_ALIGNMENTS.topRight) end),
        self:button(ALIGN_X, ALIGN_Y + 40, 30, "ML", function() self:setSelectedNodeAlign(_ALIGNMENTS.left) end),
        self:button(ALIGN_X + 30, ALIGN_Y + 40, 30, "M", function() self:setSelectedNodeAlign(_ALIGNMENTS.center) end),
        self:button(ALIGN_X + 60, ALIGN_Y + 40, 30, "MR", function() self:setSelectedNodeAlign(_ALIGNMENTS.right) end),
        self:button(ALIGN_X, ALIGN_Y + 60, 30, "BL", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottomLeft) end),
        self:button(ALIGN_X + 30, ALIGN_Y + 60, 30, "B", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottom) end),
        self:button(ALIGN_X + 60, ALIGN_Y + 60, 30, "BR", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottomRight) end),

        self:label(PALIGN_X, PALIGN_Y, "Parent Align"),
        self:button(PALIGN_X, PALIGN_Y + 20, 30, "TL", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.topLeft) end),
        self:button(PALIGN_X + 30, PALIGN_Y + 20, 30, "T", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.top) end),
        self:button(PALIGN_X + 60, PALIGN_Y + 20, 30, "TR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.topRight) end),
        self:button(PALIGN_X, PALIGN_Y + 40, 30, "ML", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.left) end),
        self:button(PALIGN_X + 30, PALIGN_Y + 40, 30, "M", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.center) end),
        self:button(PALIGN_X + 60, PALIGN_Y + 40, 30, "MR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.right) end),
        self:button(PALIGN_X, PALIGN_Y + 60, 30, "BL", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottomLeft) end),
        self:button(PALIGN_X + 30, PALIGN_Y + 60, 30, "B", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottom) end),
        self:button(PALIGN_X + 60, PALIGN_Y + 60, 30, "BR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottomRight) end),

        self:label(ALIGN_X, ALIGN_Y + 90, "Shift+Click a node to make it a parent of the currently selected node"),

        self:button(FILE_X, FILE_Y, 60, "New", function() self:newScene() end, {ctrl = true, key = "n"}),
        self:button(FILE_X + 60, FILE_Y, 60, "Load", function() self:askForInput("load", "file", {".json"}, false) end, {ctrl = true, key = "l"}),
        self:button(FILE_X + 120, FILE_Y, 60, "Save", function() if self.currentSceneFile then self:saveScene(self.currentSceneFile) else self:askForInput("save", "file", {".json"}, true) end end, {ctrl = true, key = "s"}),
        self:button(FILE_X + 180, FILE_Y, 60, "Save As", function() self:askForInput("save", "file", {".json"}, true) end, {ctrl = true, shift = true, key = "s"}),
        self:label(FILE_X + 250, FILE_Y, "File: (none)", "lb_file")
    }
    for i, node in ipairs(nodes) do
        self.UI:addChild(node)
    end
end



---Updates the Editor.
---@param dt number Time delta in seconds.
function Editor:update(dt)
    self.uiTreeInfo = self:getUITreeInfo(self.uiTreeShowsInternalUI and self.UI or nil)
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
	self.UI:findChildByName("drawtime"):setText(string.format("Drawing took approximately %.1fms", _DrawTime * 1000))
	self.UI:findChildByName("pos"):setText(string.format("Mouse position: %s", _MouseCPos))
	self.UI:findChildByName("line3"):setText(string.format("Vecs per frame: %s", _VEC2S_PER_FRAME))
	self.UI:findChildByName("hovText"):setText("")
	self.UI:findChildByName("selText"):setText("")
    self.UI:findChildByName("lb_file"):setText(string.format("File: %s%s", self.currentSceneFile or "(none)", self.isSceneModified and "*" or ""))

    -- Hovered and selected node
    if self.hoveredNode then
        self.UI:findChildByName("hovText"):setText(string.format("Hovered: %s {%s} pos: %s -> %s", self.hoveredNode.name, self.hoveredNode.type, self.hoveredNode:getPos(), self.hoveredNode:getGlobalPos()))
    end
    if self.selectedNode then
        self.UI:findChildByName("selText"):setText(string.format("Selected: %s {%s} pos: %s -> %s", self.selectedNode.name, self.selectedNode.type, self.selectedNode:getPos(), self.selectedNode:getGlobalPos()))
    end
	self.UI:draw()

    -- Other UI that will be hardcoded for now.
    love.graphics.setFont(_FONTS.editor)

    -- UI tree
    self.uiTree:draw()

    -- Command buffer
    self.commandMgr:draw()

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
---@param alpha number? The text alpha, 1 by default.
---@param noShadow boolean? If you don't want the shadow after all, despite this function's name...
function Editor:drawShadowedText(text, x, y, color, backgroundColor, alpha, noShadow)
    color = color or _COLORS.white
    alpha = alpha or 1
    if backgroundColor then
        local w = love.graphics.getFont():getWidth(text)
        local h = love.graphics.getFont():getHeight()
        love.graphics.setColor(backgroundColor.r, backgroundColor.g, backgroundColor.b, 0.5 * alpha)
        love.graphics.rectangle("fill", x - 2, y - 2, w + 4, h + 4)
    end
    if not noShadow then
        love.graphics.setColor(0, 0, 0, 0.8 * alpha)
        love.graphics.print(text, x + 2, y + 2)
    end
    love.graphics.setColor(color.r, color.g, color.b, alpha)
    love.graphics.print(text, x, y)
end



---Executed whenever a mouse button is pressed anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
---@param istouch boolean Whether the press is coming from a touch input.
---@param presses integer How many clicks have been performed in a short amount of time. Useful for double click checks.
function Editor:mousepressed(x, y, button, istouch, presses)
    if not self.enabled then
        return
    end
    self.UI:mousepressed(x, y, button, istouch, presses)
    if self.INPUT_DIALOG:mousepressed(x, y, button, istouch, presses) then
        return
    end
    if self.uiTree:mousepressed(x, y, button, istouch, presses) then
        return
    end
	if button == 1 and not self:isUIHovered() then
        local resizeHandleID = self.selectedNode and self.selectedNode:getHoveredResizeHandleID()
        if _IsShiftPressed() then
            -- Shift+Click parents the selected node instead.
            self:parentSelectedNodeToHoveredNode()
        elseif resizeHandleID then
            -- We've grabbed a resize handle of the currently selected node!
            self:startResizingSelectedNode(resizeHandleID)
        else
            self:selectNode(self.hoveredNode)
            if _IsCtrlPressed() then
                self:startCommandTransaction()
                self:duplicateSelectedNode()
            end
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



---Executed whenever a mouse wheel has been scrolled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function Editor:wheelmoved(x, y)
    self.uiTree:wheelmoved(x, y)
end



---Executed whenever a key is pressed on the keyboard.
---@param key string The key code.
function Editor:keypressed(key)
    love.keyboard.setKeyRepeat(key == "backspace" or key == "up" or key == "down" or key == "left" or key == "right")
    self.UI:keypressed(key)
    if self.INPUT_DIALOG:keypressed(key) then
        return
    end
    if self.uiTree:keypressed(key) then
        return
    end
	if key == "tab" then
		self.enabled = not self.enabled
    elseif key == "p" then
        self.uiTreeShowsInternalUI = not self.uiTreeShowsInternalUI
    elseif key == "up" then
        self:moveSelectedNode(Vec2(0, _IsShiftPressed() and -10 or -1))
    elseif key == "down" then
        self:moveSelectedNode(Vec2(0, _IsShiftPressed() and 10 or 1))
    elseif key == "left" then
        self:moveSelectedNode(Vec2(_IsShiftPressed() and -10 or -1, 0))
    elseif key == "right" then
        self:moveSelectedNode(Vec2(_IsShiftPressed() and 10 or 1, 0))
    elseif key == "p" and _IsCtrlPressed() then
        self:printInternalUITreeInfo()
	end
end



---Executed whenever a certain character has been typed on the keyboard.
---@param text string The character.
function Editor:textinput(text)
    self.INPUT_DIALOG:textinput(text)
    self.uiTree:textinput(text)
end



return Editor