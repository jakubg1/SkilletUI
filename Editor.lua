local class = require "com.class"

---@class Editor
---@overload fun():Editor
local Editor = class:derive("Editor")

local Vec2 = require("Vector2")
local Node = require("Node")
local NodeList = require("NodeList")
local Input = require("Input")
local EditorUITree = require("EditorUITree")
local EditorKeyframes = require("EditorKeyframes")
local EditorCommands = require("EditorCommands")
local EditorCanvas = require("EditorCanvas")

local CommandNodeAdd = require("EditorCommands.NodeAdd")
local CommandNodeRename = require("EditorCommands.NodeRename")
local CommandNodeMove = require("EditorCommands.NodeMove")
local CommandNodeDrag = require("EditorCommands.NodeDrag")
local CommandNodeResize = require("EditorCommands.NodeResize")
local CommandNodeDelete = require("EditorCommands.NodeDelete")
local CommandNodeSetParent = require("EditorCommands.NodeSetParent")
local CommandNodeSetProperty = require("EditorCommands.NodeSetProperty")
local CommandNodeSetWidgetProperty = require("EditorCommands.NodeSetWidgetProperty")
local CommandNodeMoveUp = require("EditorCommands.NodeMoveUp")
local CommandNodeMoveDown = require("EditorCommands.NodeMoveDown")
local CommandNodeMoveToTop = require("EditorCommands.NodeMoveToTop")
local CommandNodeMoveToBottom = require("EditorCommands.NodeMoveToBottom")

---@alias Widget* Box|Button|Canvas|InputText|NineSprite|Text|TitleDigit
---@alias EditorCommand* EditorCommandNodeAdd|EditorCommandNodeRename|EditorCommandNodeMove|EditorCommandNodeDrag|EditorCommandNodeResize|EditorCommandNodeDelete|EditorCommandNodeSetParent|EditorCommandNodeSetProperty|EditorCommandNodeSetWidgetProperty|EditorCommandNodeMoveUp|EditorCommandNodeMoveDown|EditorCommandNodeMoveToTop|EditorCommandNodeMoveToBottom|EditorCommandNodeMoveToIndex



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
--- - Adding new nodes (and entire node groups for stuff like buttons, scroll bars, etc.)
--- - Animations and timelines
--- - Live editing of parameters
--- - Multi-selection
--- - Font and image support for parameters
--- - Grid and snapping to it
--- - Canvas zooming and panning
---
--- To Do (arbitrary order):
--- - Vector support for parameters
--- - Node modifier system, where you could add a rule, like: "modify this node and all its children's widgets' alpha by multiplying it by 0.5"
--- - Property modifier system: instead of always having just the base and current value, make it a base value and a list of any modifiers (current value could be cached and got but could not be set)
--- - Timeline editing
--- - Fix ctrl+drag in node tree
--- - Multiline text and inline formatting



---Constructs a new UI Editor.
function Editor:new()
    self.UI = nil
    self.INPUT_DIALOG = Input()

    self.NODE_RESIZE_DIRECTIONS = {
        Vec2(-1, -1),
        Vec2(0, -1),
        Vec2(1, -1),
        Vec2(1, 0),
        Vec2(1, 1),
        Vec2(0, 1),
        Vec2(-1, 1),
        Vec2(-1, 0)
    }

    self.clipboard = {}

    self.enabled = true
    self.activeInput = nil -- Can be a Node, but also `"save"` or `"load"`
    self.hoveredNode = nil
    self.isNodeHoverIndirect = false
    self.selectedNodes = NodeList()
    self.nodeDragOrigin = nil
    self.nodeDragSnap = false
    self.nodeResizeOrigin = nil
    self.nodeResizeOffset = nil -- Offset between the clicked position and the actual corner of the node
    self.nodeResizeDirection = nil
    self.nodeResizeHandleID = nil
    self.nodeMultiSelectOrigin = nil
    self.nodeMultiSelectSize = nil -- This size can be negative, be careful when drawing!

    self.uiTree = EditorUITree(self)
    self.keyframeEditor = EditorKeyframes(self)
    self.commandMgr = EditorCommands(self)
    self.canvasMgr = EditorCanvas(self, _CANVAS)
end



---Prints the internal Editor UI tree to the console.
function Editor:printInternalUITreeInfo()
    -- Node tree
    for i, line in ipairs(self.uiTree:getUITreeInfo(self.UI)) do
        local suffix = ""
        if line.node.isController then
            suffix = suffix .. " (controller)"
        elseif line.node:isControlled() then
            suffix = suffix .. " (controlled)"
        end
        print(string.rep("    ", line.indent) .. string.format("%s {%s}", (line.node.name ~= "" and line.node.name or "<unnamed>"), line.node.type) .. suffix)
    end
end



---Returns the layout position (like `_MouseCPos`) snapped to the nearest grid intersection.
---If the grid is disabled, returns the input position.
---@param pos Vector2 The input position.
---@return Vector2
function Editor:snapPositionToGrid(pos)
    local gridSize = _PROJECT:getGridSize()
    if not gridSize then
        return pos
    end
    return ((pos / gridSize) + 0.5):floor() * gridSize
end



---Returns the position of the provided box snapped to the nearest grid lines.
---If the grid is disabled, returns the input position.
---@param pos Vector2 The box position.
---@param size Vector2 The box size.
---@return Vector2
function Editor:snapBoxToGrid(pos, size)
    local gridSize = _PROJECT:getGridSize()
    if not gridSize then
        return pos
    end
    -- Snap the top left and bottom right corners independently to check how many pixels are needed to snap either side.
    local p2 = pos + size - 1
    local sp1 = self:snapPositionToGrid(pos)
    local sp2 = self:snapPositionToGrid(p2)
    local o1 = (pos - sp1):abs()
    local o2 = (p2 - sp2):abs()
    -- Get whichever one is closer.
    local x = o1.x <= o2.x and sp1.x or (sp2.x - size.x)
    local y = o1.y <= o2.y and sp1.y or (sp2.y - size.y)
    return Vec2(x, y)
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
    -- Do not hover any other node while dragging or resizing the selected node.
    if self.nodeDragOrigin or self.nodeResizeOrigin then
        return nil
    end
    -- Look whether we've hovered over any UI info entry.
    local hoveredNode = self.uiTree:getHoveredNode()
    if hoveredNode then
        return hoveredNode
    end
    -- Already selected nodes take over the hover, regardless of whatever is over it.
    -- TODO: Is that necessary? Also, update the code for multi-selection.
    --if self.selectedNode and (self.selectedNode:isHovered() or self.selectedNode:getHoveredResizeHandleID()) then
    --    return self.selectedNode
    --end
    -- Finally, look if any node is directly hovered.
    local currentLayout = _PROJECT:getCurrentLayout()
    if currentLayout then
        return currentLayout:findChildByPixelDepthFirst(_MouseCPos, true, true, true)
    end
end

---Returns the global screen position of the given selected node's resize handle.
---If the node is not resizable or more than one (or none) nodes are selected, returns `nil`.
---@param id integer 1 to 8: 1 is top left, then clockwise.
---@return Vector2?
function Editor:getNodeResizeHandlePos(id)
    assert(id >= 1 and id <= 8, string.format("Invalid resize handle ID: %s (expected 1..8)", id))
    if self.selectedNodes:getSize() ~= 1 then
        return nil
    end
    local node = self.selectedNodes:getNode(1)
    assert(node, "size > 0, but nodes[1] = nil. This should never happen")
    local pos, size = _CANVAS:pixelToPosBox(node:getGlobalPos(), node:getSize())
    pos = pos - 6
    size = size + 12
    return pos + size * (self.NODE_RESIZE_DIRECTIONS[id] + 1) / 2
end

---Returns the currently hovered node's resize handle ID of the selected node.
---If none of the resize handles are hovered, returns `nil`.
---@return integer?
function Editor:getHoveredNodeResizeHandleID()
    if self.selectedNodes:getSize() ~= 1 then
        return nil
    end
    local node = self.selectedNodes:getNode(1)
    assert(node, "size > 0, but nodes[1] = nil. This should never happen")
    if not node:isResizable() then
        return nil
    end
    for i = 1, 8 do
        local pos = self:getNodeResizeHandlePos(i)
        if _Utils.isPointInsideBox(_MousePos, pos - 8, Vec2(16)) then
            return i
        end
    end
    return nil
end



---Returns `true` if the given Node Property is currently supported by the editor.
---@param property table The property in its entirety, as an item of the `Widget:getPropertyList()` result table.
---@return boolean
function Editor:isNodePropertySupported(property)
    return property.type == "string" or property.type == "number" or property.type == "color" or property.type == "boolean" or property.type == "shortcut" or property.type == "Font" or property.type == "NineImage"
end



---Returns `true` if the provided Node exists anywhere either in the project's UI tree, or in the internal editor's UI tree.
---@param node Node The node to be looked for.
---@return boolean
function Editor:doesNodeExistSomewhere(node)
    local currentLayout = _PROJECT:getCurrentLayout()
    if currentLayout and (currentLayout == node or currentLayout:findChild(node) ~= nil) then
        return true
    end
    return self.UI == node or self.UI:findChild(node) ~= nil
end



---Refreshes all critical UI for Editors, for example the node properties.
function Editor:updateUI()
    -- If any of the selected nodes have been removed, deselect them.
    self.selectedNodes:removeNodesFunction(function(node) return not self:doesNodeExistSomewhere(node) end)
    if self.selectedNodes:getSize() == 1 then
        -- Display property UI only if a single node has been selected.
        self:generateNodePropertyUI(self.selectedNodes:getNode(1))
    else
        -- TODO: Make property UI for multiple nodes (show common values)
        self:generateNodePropertyUI()
    end
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
        local widget = node.widget
        local propertiesUI = Node({name = "properties", pos = {1200, 30}})
        local propertyWidgetInfoUI = self:label(20, 0, "")
        if widget then
            if not widget.getPropertyList then
                propertyWidgetInfoUI.widget:setProp("text", "This Widget does not support properties yet!")
            end
        else
            propertyWidgetInfoUI.widget:setProp("text", "This Node does not have a widget.")
        end
        local widgetListWrapperUI = Node({pos = {0, 30}})
        local widgetListUI = self:generatePropertyListUI(node, node:getPropertyList(), "Node Properties " .. tostring(math.floor(math.random() * 1000000)), "node", node:isControlled())
        widgetListWrapperUI:addChild(widgetListUI)
        propertiesUI:addChild(widgetListWrapperUI)
        if widget and widget.getPropertyList then
            local nodeListWrapperUI = Node({pos = {0, 250}})
            local nodeListUI = self:generatePropertyListUI(widget, widget:getPropertyList(), "Widget Properties", "widget", false)
            nodeListWrapperUI:addChild(nodeListUI)
            propertiesUI:addChild(nodeListWrapperUI)
        end
        self.UI:addChild(propertiesUI)
    end
end



---Generates a property list UI and returns a Node with a header, the properties and their labels.
---@param widgetOrNode Node|Widget* The Node or Widget to get the values from.
---@param properties table The property list to be generated from.
---@param header string The header text for this list.
---@param affectedType "node"|"widget" What to change when the input box value is submitted.
---@param controlled boolean If set, the properties marked as `disabledIfControlled` will be disabled.
---@return Node
function Editor:generatePropertyListUI(widgetOrNode, properties, header, affectedType, controlled)
    local listUI = Node({name = "proplist"})
    local y = 0
    local propertyHeaderUI = self:label(0, y, header)
    propertyHeaderUI.widget:setProp("underline", true)
    propertyHeaderUI.widget:setProp("characterSeparation", 2)
    y = y + 20
    listUI:addChild(propertyHeaderUI)
    for i, property in ipairs(properties) do
        local inputValue = widgetOrNode.properties:getBaseValue(property.key)
        local propertyUI = Node({name = "input", pos = {20, y}})
        y = y + 20
        local propertyText = self:label(0, 0, property.name)
        local propertyInput = self:input(200, 0, 150, property, inputValue, affectedType, nil)
        self:inputSetDisabled(propertyInput, not self:isNodePropertySupported(property) or (controlled and property.disabledIfControlled))
        propertyUI:addChild(propertyText)
        propertyUI:addChild(propertyInput)
        listUI:addChild(propertyUI)
    end
    return listUI
end



---Returns `true` if the provided node is currently selected, `false` otherwise.
---@param node Node The node to be checked.
---@return boolean
function Editor:isNodeSelected(node)
    return self.selectedNodes:hasNode(node)
end

---Marks the provided node as selected.
---@param node Node The node to be selected.
function Editor:selectNode(node)
    self.selectedNodes:addNode(node)
    self.selectedNodes:sortByTreeOrder()
end

---Marks the provided nodes as selected.
---@param nodes NodeList The nodes to be selected.
function Editor:selectNodes(nodes)
    for i, node in ipairs(nodes:getNodes()) do
        self.selectedNodes:addNode(node)
    end
    self.selectedNodes:sortByTreeOrder()
end

---Marks the provided node as unselected.
---@param node Node The node to be deselected.
function Editor:deselectNode(node)
    self.selectedNodes:removeNode(node)
    self.selectedNodes:sortByTreeOrder()
end

---Toggles the selection state of the provided node.
---@param node Node The node to be toggled.
function Editor:toggleNodeSelection(node)
    self.selectedNodes:toggleNode(node)
    self.selectedNodes:sortByTreeOrder()
end

---Deselects all previously selected nodes.
function Editor:deselectAllNodes()
    self.selectedNodes:clear()
end

---Adds the provided UI node as the currently selected node's sibling if exactly one node is selected.
---Otherwise, the node will be parented to the root node.
---@param node Node The node to be added.
function Editor:addNode(node)
    local target = self.selectedNodes:getSize() == 1 and self.selectedNodes:getNode(1)
    local targetParent = target and target.parent or _PROJECT:getCurrentLayout()
    self:executeCommand(CommandNodeAdd(NodeList(node), targetParent))
end

---Adds the provided UI nodes as the currently selected node's sibling if exactly one node is selected.
---Otherwise, the nodes will be parented to the root node.
---@param nodes NodeList The list of nodes to be added.
function Editor:addNodes(nodes)
    local target = self.selectedNodes:getSize() == 1 and self.selectedNodes:getNode(1)
    local targetParent = target and target.parent or _PROJECT:getCurrentLayout()
    self:executeCommand(CommandNodeAdd(nodes, targetParent))
end

---Copies the currently selected UI nodes to the internal clipboard.
function Editor:copySelectedNode()
    if self.selectedNodes:getSize() == 0 then
        -- We need to prevent clearing the clipboard when nothing is going to be copied.
        return
    end
    self.clipboard = self.selectedNodes:bulkSerialize()
end

---Pastes the UI nodes which are stored in the internal clipboard and adds them as the currently selected node's sibling (or to the root node).
---The newly added Nodes will be selected.
function Editor:pasteNode()
    if #self.clipboard == 0 then
        -- We need to prevent deselecting everything when nothing is going to be pasted.
        return
    end
    local newNodes = NodeList()
    for i, entry in ipairs(self.clipboard) do
        local node = Node(entry)
        newNodes:addNode(node)
    end
    self:addNodes(newNodes)
    self:deselectAllNodes()
    self:selectNodes(newNodes)
end

---Duplicates the currently selected UI nodes and selects the newly made duplicates.
function Editor:duplicateSelectedNode()
    if self.selectedNodes:getSize() == 0 then
        -- We need to prevent deselecting everything when nothing is going to be pasted.
        return
    end
    local newNodes = NodeList()
    for i, node in ipairs(self.selectedNodes:getNodes()) do
        local data = node:serialize()
        local newNode = Node(data)
        newNodes:addNode(newNode)
    end
    self:addNodes(newNodes)
    self:deselectAllNodes()
    self:selectNodes(newNodes)
end



---Starts dragging the selected node, starting from the current mouse position.
function Editor:startDraggingSelectedNode()
    if self.selectedNodes:getSize() == 0 then
        -- We need to prevent dragging when nothing is selected in the first place.
        return
    end
    self.nodeDragOrigin = _MouseCPos
    self.nodeDragSnap = true
end

---Finishes dragging the selected node and pushes a command so that the movement can be undone.
function Editor:finishDraggingSelectedNode()
    if not self.nodeDragOrigin then
        -- This is important as otherwise we would commit a drag command while resizing a node.
        return
    end
    self:executeCommand(CommandNodeDrag(self.selectedNodes))
    -- If we were dragging a freshly duplicated node, we need to commit the transaction.
    -- TODO: This is broken. Fix this somehow.
    if self.commandMgr.transactionMode then
        self:commitCommandTransaction()
    end
    self.nodeDragOrigin = nil
    self.nodeDragSnap = false
end

---Restores the original selected node position and finishes the dragging process.
function Editor:cancelDraggingSelectedNode()
    self.selectedNodes:bulkCancelDrag()
    -- If we were dragging a freshly duplicated node, we need to cancel the transaction.
    -- TODO: This is broken. Fix this somehow.
    if self.commandMgr.transactionMode then
        self:cancelCommandTransaction()
    end
    self.nodeDragOrigin = nil
    self.nodeDragSnap = false
end



---Starts resizing the selected node, starting from the current mouse position.
---Does nothing if more than one node is selected.
---@param handleID integer The ID of the resize handle that has been grabbed.
function Editor:startResizingSelectedNode(handleID)
    if self.selectedNodes:getSize() ~= 1 then
        -- Resizing more than one node at once or none at all does not make any sense.
        return
    end
    self.nodeResizeOrigin = _MouseCPos
    self.nodeResizeOffset = (self.selectedNodes:getNode(1):getGlobalPos() + (self.NODE_RESIZE_DIRECTIONS[handleID] + 1) / 2 * self.selectedNodes:getNode(1):getSize()) - _MouseCPos
    self.nodeResizeDirection = self.NODE_RESIZE_DIRECTIONS[handleID]
    self.nodeResizeHandleID = handleID
end

---Finishes resizing the selected node and pushes a command so that this process can be undone.
function Editor:finishResizingSelectedNode()
    if not self.nodeResizeOrigin then
        return
    end
    self:executeCommand(CommandNodeResize(self.selectedNodes))
    self.nodeResizeOrigin = nil
    self.nodeResizeOffset = nil
    self.nodeResizeDirection = nil
    self.nodeResizeHandleID = nil
end

---Restores the original selected node's positions and size and finishes the resizing process.
function Editor:cancelResizingSelectedNode()
    self.selectedNodes:bulkCancelResize()
    self.nodeResizeOrigin = nil
    self.nodeResizeOffset = nil
    self.nodeResizeDirection = nil
    self.nodeResizeHandleID = nil
end



---Renames the currently selected UI nodes.
---There is no duplicate checking when renaming multiple nodes; all get the same name.
---@param name string The new name.
function Editor:renameSelectedNode(name)
    self:executeCommand(CommandNodeRename(self.selectedNodes, name))
end

---Moves the currently selected UI nodes by the given amount of pixels.
---@param offset Vector2 The movement vector the selected UI nodes should be moved towards.
function Editor:moveSelectedNode(offset)
    self:executeCommand(CommandNodeMove(self.selectedNodes, offset), "widgetMove")
end

---Sets a new alignment for the selected nodes.
---@param align Vector2 The new alignment value.
function Editor:setSelectedNodeAlign(align)
    self:executeCommand(CommandNodeSetProperty(self.selectedNodes, "align", align))
end

---Sets a new parental alignment for the selected nodes.
---@param parentAlign Vector2 The new parental alignment value.
function Editor:setSelectedNodeParentAlign(parentAlign)
    self:executeCommand(CommandNodeSetProperty(self.selectedNodes, "parentAlign", parentAlign))
end

---Sets a new value for the selected nodes' property.
---@param property string The property to be set.
---@param value any? The value to be set for this property.
---@param groupID string? The command group ID. Used when scrolling so that everything can be undone at once.
function Editor:setSelectedNodeProperty(property, value, groupID)
    self:executeCommand(CommandNodeSetProperty(self.selectedNodes, property, value), groupID)
end

---Sets a new value for the selected nodes' widget property.
---@param property string The property to be set.
---@param value any? The value to be set for this property.
---@param groupID string? The command group ID. Used when scrolling so that everything can be undone at once.
function Editor:setSelectedNodeWidgetProperty(property, value, groupID)
    self:executeCommand(CommandNodeSetWidgetProperty(self.selectedNodes, property, value), groupID)
end

---Sets a new value for the given node's widget property.
---@param node Node The node that will have its widget property changed.
---@param property string The property to be set.
---@param value any? The value to be set for this property.
function Editor:setNodeWidgetProperty(node, property, value)
    self:executeCommand(CommandNodeSetWidgetProperty(NodeList(node), property, value))
end

---Moves the selected nodes up in their parents' hierarchy.
function Editor:moveSelectedNodeUp()
    self:executeCommand(CommandNodeMoveUp(self.selectedNodes))
end

---Moves the selected nodes down in their parents' hierarchy.
function Editor:moveSelectedNodeDown()
    self:executeCommand(CommandNodeMoveDown(self.selectedNodes))
end

---Moves the selected nodes to the top in their parents' hierarchy.
function Editor:moveSelectedNodeToTop()
    self:executeCommand(CommandNodeMoveToTop(self.selectedNodes))
end

---Moves the selected nodes to the bottom in their parents' hierarchy.
function Editor:moveSelectedNodeToBottom()
    self:executeCommand(CommandNodeMoveToBottom(self.selectedNodes))
end

---Parents the currently selected nodes to the currently hovered node.
---The selected nodes become the children, and the hovered node becomes their parent.
function Editor:parentSelectedNodeToHoveredNode()
    self:executeCommand(CommandNodeSetParent(self.selectedNodes, self.hoveredNode))
end

---Deletes the currently selected UI nodes.
function Editor:deleteSelectedNode()
    self:executeCommand(CommandNodeDelete(self.selectedNodes))
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
        _PROJECT:setLayoutModified(true)
        -- Make sure to refresh UIs.
        -- If the commands are grouped, UIs are not updated so that we don't pull our text input
        -- whenever we type a single character while maintaining real-time changes.
        -- TODO: Check the impact on this and make a better system?
        if not groupID and not self.commandMgr.transactionMode then
            self:updateUI()
        end
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
    -- Update the UI that we didn't do during the transaction.
    --self:updateUI()
end



---Cancels a command transaction by undoing all commands that have been already executed and removing the transaction from the stack.
---Cancelled command transactions can NOT be restored.
function Editor:cancelCommandTransaction()
    self.commandMgr:cancelCommandTransaction()
    -- Make sure to refresh UIs.
    self:updateUI()
end



---Undoes the command that has been executed last and moves it to the undo command stack.
function Editor:undoLastCommand()
    self.commandMgr:undoLastCommand()
    _PROJECT:setLayoutModified(not self.commandMgr:isAtSaveMarker())
    self:updateUI()
end



---Redoes the undone command and moves it back to the main command stack.
function Editor:redoLastCommand()
    self.commandMgr:redoLastCommand()
    _PROJECT:setLayoutModified(not self.commandMgr:isAtSaveMarker())
    self:updateUI()
end



---Loads another project from the specified folder.
---@param name string The name of the project.
function Editor:loadProject(name)
    _LoadProject(name)
    self:deselectAllNodes()
    self.commandMgr:clearStacks()
end



---Creates a new blank scene.
function Editor:newScene()
    _PROJECT:newLayout()
    self:deselectAllNodes()
    self.commandMgr:clearStacks()
end

---Loads a new scene from the specified file.
---@param name string The name of the layout.
function Editor:loadScene(name)
    _PROJECT:loadLayout(name)
    self:deselectAllNodes()
    self.commandMgr:clearStacks()
end

---Saves the current scene to a file as a different name.
---@param name string The name of the layout.
function Editor:saveScene(name)
    _PROJECT:saveLayout(name)
    self.commandMgr:setSaveMarker()
end

---Saves the current scene.
---If the current scene is a new scene, displays a file picker instead.
function Editor:trySaveCurrentScene()
    local name = _PROJECT:getLayoutName()
    if name then
        self:saveScene(name)
    else
        self:askForInput("save", "file", {".json"}, true, _PROJECT:getLayoutDirectory())
    end
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
---@param property table The input property data.
---@param value string|number|Color The value that should be initially set in the input field.
---@param affectedType "node"|"widget" Whether the specified property is belonging to the selected Node or its Widget.
---@param extensions table? If `property.type` == `"file"`, the list of file extensions to be listed in the file picker.
---@return Node
function Editor:input(x, y, w, property, value, affectedType, extensions)
    local data = {
        name = "inp_" .. property.type,
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
    input.widget.propertyKey = property.key
    input.widget.affectedType = affectedType
    input.widget:setType(property.type)
    input.widget:setValue(value)
    input.widget.nullable = property.nullable or false
    input.widget.minValue = property.minValue
    input.widget.maxValue = property.maxValue
    input.widget.scrollStep = property.scrollStep
    input:setOnClick(function() self:askForInput(input, property.type, extensions) end)
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
---@param inputType string The input type. Can be `"string"`, `"number"`, `"color"`, `"file"`, `"Font"` or `"NineImage"`.
---@param extensions table? If `type` == `"file"`, the list of file extensions to be listed in the input box.
---@param warnWhenFileExists boolean? If `type` == `"file"`, whether a file overwrite warning should be shown if the file exists.
---@param basePath string? If `type` == `"file"`, the path from which the file search should start.
---@param pathFilter string? If `type` == `"file"`: `"file"`, `"dir"` or `"all"` - show either files or directories or both respectively.
function Editor:askForInput(input, inputType, extensions, warnWhenFileExists, basePath, pathFilter)
    self.activeInput = input
    if inputType == "color" or inputType == "shortcut" or inputType == "file" or inputType == "Font" or inputType == "NineImage" then
        local value = ""
        if type(input) ~= "string" then
            value = input.widget:getValue()
        end
        self.INPUT_DIALOG:inputAsk(inputType, value, extensions, warnWhenFileExists, basePath, pathFilter)
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
        elseif self.activeInput == "loadProject" then
            self:loadProject(result)
        end
    else
        self.activeInput.widget:setValue(result)
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
    self.UI = Node(_Utils.loadJson("editor_ui.json"))
    local NEW_X = 5
    local NEW_Y = 45
    local UTILITY_X = 5
    local UTILITY_Y = 600
    local ALIGN_X = 240
    local ALIGN_Y = 595
    local PALIGN_X = 360
    local PALIGN_Y = 595
    local FILE_X = 5
    local FILE_Y = 0
    local nodes = {
        self:button(UTILITY_X, UTILITY_Y, 100, "Delete [Del]", function() self:deleteSelectedNode() end, {key = "delete"}),
        self:button(UTILITY_X + 100, UTILITY_Y, 100, "Dupe [Ctrl+D]", function() self:duplicateSelectedNode() end, {ctrl = true, key = "d"}),
        self:button(UTILITY_X, UTILITY_Y + 20, 200, "Layer Up [PgUp]", function() self:moveSelectedNodeUp() end, {key = "pageup"}),
        self:button(UTILITY_X, UTILITY_Y + 40, 200, "Layer Down [PgDown]", function() self:moveSelectedNodeDown() end, {key = "pagedown"}),
        self:button(UTILITY_X, UTILITY_Y + 60, 200, "To Top [Shift+PgUp]", function() self:moveSelectedNodeToTop() end, {shift = true, key = "pageup"}),
        self:button(UTILITY_X, UTILITY_Y + 80, 200, "To Bottom [Shift+PgDown]", function() self:moveSelectedNodeToBottom() end, {shift = true, key = "pagedown"}),
        self:button(UTILITY_X, UTILITY_Y + 100, 100, "Undo [Ctrl+Z]", function() self:undoLastCommand() end, {ctrl = true, key = "z"}),
        self:button(UTILITY_X + 100, UTILITY_Y + 100, 100, "Redo [Ctrl+Y]", function() self:redoLastCommand() end, {ctrl = true, key = "y"}),
        self:button(UTILITY_X, UTILITY_Y + 120, 100, "Copy [Ctrl+C]", function() self:copySelectedNode() end, {ctrl = true, key = "c"}),
        self:button(UTILITY_X + 100, UTILITY_Y + 120, 100, "Paste [Ctrl+V]", function() self:pasteNode() end, {ctrl = true, key = "v"}),
        self:label(NEW_X, NEW_Y - 20, "New Widget:"),
        self:button(NEW_X, NEW_Y, 55, "Node", function() self:addNode(Node({})) end),
        self:button(NEW_X + 55, NEW_Y, 55, "Box", function() self:addNode(Node({type = "box"})) end),
        self:button(NEW_X + 110, NEW_Y, 55, "Text", function() self:addNode(Node({type = "text"})) end),
        self:button(NEW_X + 165, NEW_Y, 55, "9Sprite", function() self:addNode(Node({type = "9sprite"})) end),
        self:button(NEW_X, NEW_Y + 20, 110, "TitleDigit", function() self:addNode(Node({type = "@titleDigit"})) end),
        self:button(NEW_X + 110, NEW_Y + 20, 55, "Button", function() self:addNode(Node({type = "button", children = {{name = "text", type = "text", align = "center", parentAlign = "center"}, {name = "sprite", type = "9sprite"}}})) end),
        self:button(NEW_X + 165, NEW_Y + 20, 55, "Test Btn", function() self:addNode(Node(_Utils.loadJson("layouts/snippet_test2.json"))) end),

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

        self:label(FILE_X, FILE_Y + 1, "Project: (none)", "lb_project"),
        self:button(FILE_X + 250, FILE_Y, 60, "Load", function() self:askForInput("loadProject", "file", nil, false, "projects/", "dir") end, {ctrl = true, key = "l"}),
        self:label(FILE_X + 360, FILE_Y + 1, "Layout: (none)", "lb_layout"),
        self:button(FILE_X + 560, FILE_Y, 60, "New", function() self:newScene() end, {ctrl = true, key = "n"}),
        self:button(FILE_X + 620, FILE_Y, 60, "Load", function() self:askForInput("load", "file", {".json"}, false, _PROJECT:getLayoutDirectory()) end, {ctrl = true, key = "l"}),
        self:button(FILE_X + 680, FILE_Y, 60, "Save", function() self:trySaveCurrentScene() end, {ctrl = true, key = "s"}),
        self:button(FILE_X + 740, FILE_Y, 60, "Save As", function() self:askForInput("save", "file", {".json"}, true, _PROJECT:getLayoutDirectory()) end, {ctrl = true, shift = true, key = "s"})
    }
    for i, node in ipairs(nodes) do
        self.UI:addChild(node)
    end
end



---Updates the Editor.
---@param dt number Time delta in seconds.
function Editor:update(dt)
    if not self.enabled then
        return
    end

    self.hoveredNode = self:getHoveredNode()

    -- Handle the node dragging.
    if self.nodeDragOrigin then
        local movement = _MouseCPos - self.nodeDragOrigin
        if self.nodeDragSnap then
            if movement:len() >= 5 then
                self.nodeDragSnap = false
            end
        else
            for i, node in ipairs(self.selectedNodes:getNodes()) do
                -- TODO: Fix dragging for nodes aligned to bottom right, middle, etc.
                -- TODO: Fix dragging of multiple nodes - they shouldn't be able to snap to the grid independently.
                local snappedPos = self:snapBoxToGrid(node:getPropBase("pos") + movement, node:getSize())
                node:dragTo(snappedPos)
            end
            self:updateUI()
        end
    end

    -- Handle the node resizing.
    if self.nodeResizeOrigin then
        assert(self.selectedNodes:getSize() < 2, "Resizing of multiple Nodes is not supported. How did you even trigger that?")
        for i, node in ipairs(self.selectedNodes:getNodes()) do
            local movement = self:snapPositionToGrid(_MouseCPos) - self.nodeResizeOffset - self.nodeResizeOrigin
            local size = node.widget:getPropBase("size") + movement * self.nodeResizeDirection
            if _IsShiftPressed() then
                -- Force a square size if Shift is held.
                size = Vec2(math.max(size.x, size.y), math.max(size.x, size.y))
            end
            -- TODO: Snap to grid for resizing.
            node:resizeTo(size, (self.nodeResizeDirection - 1) / 2)
            self:updateUI()
        end
    end

    -- Handle the multi-selection.
    if self.nodeMultiSelectOrigin then
        self.nodeMultiSelectSize = _MouseCPos - self.nodeMultiSelectOrigin
    end

    self.uiTree:update(dt)
    self.keyframeEditor:update(dt)
    self.canvasMgr:update(dt)

    self.UI:update(dt)
    self.INPUT_DIALOG:update(dt)

    -- Update the mouse cursor.
    local cursor = love.mouse.getSystemCursor("arrow")
    local resizeHandleID = self.nodeResizeHandleID or self:getHoveredNodeResizeHandleID()
    if resizeHandleID then
        if resizeHandleID % 4 == 0 then
            cursor = love.mouse.getSystemCursor("sizewe")
        elseif resizeHandleID % 4 == 1 then
            cursor = love.mouse.getSystemCursor("sizenwse")
        elseif resizeHandleID % 4 == 2 then
            cursor = love.mouse.getSystemCursor("sizens")
        elseif resizeHandleID % 4 == 3 then
            cursor = love.mouse.getSystemCursor("sizenesw")
        end
    end
    love.mouse.setCursor(cursor)
end



---Draws the Editor's UI part that should land behind the canvas.
function Editor:drawUnderCanvas()
    love.graphics.setFont(_RESOURCE_MANAGER:getFont("editor").font)
    self.canvasMgr:drawUnderCanvas()
end



---Draws the Editor.
function Editor:draw()
    if not self.enabled then
        love.graphics.setFont(_RESOURCE_MANAGER:getFont("editor").font)
        self.keyframeEditor:draw()
        return
    end
    self.UI:findChildByName("hovText"):setText("")
    self.UI:findChildByName("selText"):setText("")
    self.UI:findChildByName("hovEvText"):setText("")
    self.UI:findChildByName("selEvText"):setText("")
    self.UI:findChildByName("lb_project"):setText(string.format("Project: %s", _PROJECT.path or "(none)"))
    self.UI:findChildByName("lb_layout"):setText(string.format("Layout: %s%s", _PROJECT:getLayoutName() or "(none)", _PROJECT:isLayoutModified() and "*" or ""))

    -- Hovered and selected node
    if self.hoveredNode then
        self.UI:findChildByName("hovText"):setText(string.format("Hovered: %s {%s} pos: %s -> %s", self.hoveredNode:getName(), self.hoveredNode.type, self.hoveredNode:getPos(), self.hoveredNode:getGlobalPos()))
    end
    if self.selectedNodes:getSize() > 0 then
        local text = ""
        if self.selectedNodes:getSize() == 1 then
            local node = self.selectedNodes:getNode(1)
            assert(node, "size > 0, but nodes[1] = nil. This should never happen")
            text = string.format("Selected: %s {%s} pos: %s -> %s", node:getName(), node.type, node:getPos(), node:getGlobalPos())
        else
            text = string.format("Selected: [%s nodes]", self.selectedNodes:getSize())
        end
        self.UI:findChildByName("selText"):setText(text)
    end
    local hoveredEvent = self.keyframeEditor.hoveredEvent
    if hoveredEvent then
        self.UI:findChildByName("hovEvText"):setText(string.format("Hovered: %s {%s} time: %s -> %s", hoveredEvent.type, hoveredEvent.node, hoveredEvent.time, hoveredEvent.time + (hoveredEvent.duration or 0)))
    end
    local selectedEvent = self.keyframeEditor.selectedEvent
    if selectedEvent then
        self.UI:findChildByName("selEvText"):setText(string.format("Selected: %s {%s} time: %s -> %s", selectedEvent.type, selectedEvent.node, selectedEvent.time, selectedEvent.time + (selectedEvent.duration or 0)))
    end

    -- Before the UI itself will be drawn, make some nice background for the top bar.
    love.graphics.setColor(0, 0, 1, 0.5)
    love.graphics.rectangle("fill", 0, 0, _WINDOW_SIZE.x, 20)
    self.UI:draw()

    -- Other UI that will be hardcoded for now.
    love.graphics.setFont(_RESOURCE_MANAGER:getFont("editor").font)

    -- UI tree
    self.uiTree:draw()

    -- Keyframe editor (here for now)
    self.keyframeEditor:draw()

    -- Command buffer
    self.commandMgr:draw()

    -- Status bar
    love.graphics.setColor(0, 0, 1, 0.5)
    love.graphics.rectangle("fill", 0, _WINDOW_SIZE.y - 20, _WINDOW_SIZE.x, 20)
    local text = string.format("Draw: %.1fms | Vecs/frame: %s", _DrawTime * 1000, _VEC2S_PER_FRAME)
    _VEC2S_PER_FRAME = 0
    --text = text .. "          [Tab] Presentation Mode   [Arrow Keys] Move Selected Nodes   [Ctrl + P] Show Internal UI Tree   [M] Parent Selected to Hovered"
    self:drawShadowedText(text, 5, _WINDOW_SIZE.y - 19)

    -- Input box
    self.INPUT_DIALOG:draw()
end



---Draws the Editor during the main UI pass. Used to maintain the correct scaling.
function Editor:drawUIPass()
    if not self.enabled then
        return
    end
    self.canvasMgr:drawOnCanvas()
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



---Draws a striped rectangle (or actually only the stripes of it).
---@param x number The X coordinate.
---@param y number The Y coordinate.
---@param w number The width.
---@param h number The height.
---@param stripeSize number The size of the stripe.
function Editor:drawStripedRectangle(x, y, w, h, stripeSize)
    local stripes = math.floor((w + h) / stripeSize / 2 + 0.5)
    for i = 1, stripes do
        -- Distance from top left corner along either left -> down or down -> left (sides up/right, left/down)
        local p1 = (i * 2 - 1) * stripeSize
        local p2 = math.min(i * 2 * stripeSize, w + h)
        -- Top left/right up
        local x1 = x + (p1 < w and p1 or w)
        local y1 = y + (p1 < w and 0 or p1 - w)
        -- Corner point (top right)
        local x12 = x + ((p1 < w and p2 > w) and w or x1 - x)
        local y12 = y + ((p1 < w and p2 > w) and 0 or y1 - y)
        -- Top right/right down
        local x2 = x + (p2 < w and p2 or w)
        local y2 = y + (p2 < w and 0 or p2 - w)
        -- Left down/bottom right
        local x3 = x + (p2 < h and 0 or p2 - h)
        local y3 = y + (p2 < h and p2 or h)
        -- Corner point (bottom left)
        local x34 = x + ((p1 < h and p2 > h) and 0 or x3 - x)
        local y34 = y + ((p1 < h and p2 > h) and h or y3 - y)
        -- Left up/bottom left
        local x4 = x + (p1 < h and 0 or p1 - h)
        local y4 = y + (p1 < h and p1 or h)
        love.graphics.polygon("fill", x1, y1, x12, y12, x2, y2, x3, y3, x34, y34, x4, y4)
    end
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
    if self.INPUT_DIALOG:mousepressed(x, y, button, istouch, presses) then
        return
    end
    if self.UI:mousepressed(x, y, button, istouch, presses) then
        return
    end
    if self.uiTree:mousepressed(x, y, button, istouch, presses) then
        return
    end
    if self.keyframeEditor:mousepressed(x, y, button, istouch, presses) then
        return
    end
    if button == 1 and not self:isUIHovered() then
        local startedResizing = false
        if self.selectedNodes:getSize() == 1 then
            local resizeHandleID = self:getHoveredNodeResizeHandleID()
            if resizeHandleID then
                -- We've grabbed a resize handle of the currently selected node!
                self:startResizingSelectedNode(resizeHandleID)
                startedResizing = true
            end
        end
        if not startedResizing then
            if not _IsShiftPressed() then
                -- Selecting with Shift adds new nodes cumulatively, i.e. multi-selection.
                -- TODO: Sometimes you should be exempt from this, i.e. imagine you've selected
                -- three nodes and now you want to drag them.
                -- You should be able to do this without having to keep Shift pressed.
                self:deselectAllNodes()
            end
            if self.hoveredNode then
                if _IsShiftPressed() then
                    -- Deselect a node with Shift if it has been already hovered.
                    self:toggleNodeSelection(self.hoveredNode)
                else
                    self:selectNode(self.hoveredNode)
                end
                if _IsCtrlPressed() then
                    self:startCommandTransaction()
                    self:duplicateSelectedNode()
                end
                if self.selectedNodes:getSize() > 0 then
                    if not self.isNodeHoverIndirect then
                        -- Start dragging the actual node on the screen.
                        self:startDraggingSelectedNode()
                    else
                        -- Start dragging the node on the node tree list.
                        -- TODO: Move this call to the `EditorUITree` class.
                        self.uiTree:startDraggingSelectedNodeInNodeTree()
                    end
                end
            else
                -- If no node is hovered, start the multi-selection mode.
                self.nodeMultiSelectOrigin = _MouseCPos
                self.nodeMultiSelectSize = Vec2()
            end
        end
        self:updateUI()
    elseif button == 2 then
        -- Cancel dragging if the right click is received.
        self:cancelDraggingSelectedNode()
        self:cancelResizingSelectedNode()
        self.uiTree:cancelDraggingSelectedNodeInNodeTree()
    elseif button == 3 then
        self.canvasMgr:startDrag()
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
        if self.nodeMultiSelectOrigin then
            -- TODO: Make it actually possible to multi-select nodes by checking the boxes.
            -- Finish multi-selecting.
            self.nodeMultiSelectOrigin = nil
            self.nodeMultiSelectSize = nil
        end
    elseif button == 3 then
        self.canvasMgr:stopDrag()
    end
end



---Executed whenever a mouse wheel has been scrolled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function Editor:wheelmoved(x, y)
    self.UI:wheelmoved(x, y)
    self.INPUT_DIALOG:wheelmoved(x, y)
    self.uiTree:wheelmoved(x, y)
    self.keyframeEditor:wheelmoved(x, y)
    self.canvasMgr:wheelmoved(x, y)
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
        self.canvasMgr:updateCanvas()
        if self.enabled then
            _PROJECT:stopTimeline("test")
        else
            _PROJECT:playTimeline("test")
        end
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
    elseif self.enabled and key == "`" then
        self.commandMgr.visible = not self.commandMgr.visible
    elseif self.enabled and key == "kp+" then
        self.canvasMgr:zoomInOut(2, _MouseCPos)
    elseif self.enabled and key == "kp-" then
        self.canvasMgr:zoomInOut(0.5, _MouseCPos)
    elseif self.enabled and key == "kp0" then
        self.canvasMgr:resetZoom()
    elseif self.enabled and key == "kp1" then
        self.canvasMgr:naturalZoom(1, _MouseCPos)
    elseif not self.enabled and key == "`" then
        self.canvasMgr:toggleBackground()
    elseif not self.enabled and key == "f" then
        self.canvasMgr:toggleFullscreen()
    elseif key == "m" then
        self:parentSelectedNodeToHoveredNode()
    end
end



---Executed whenever a certain character has been typed on the keyboard.
---@param text string The character.
function Editor:textinput(text)
    self.UI:textinput(text)
    self.INPUT_DIALOG:textinput(text)
    self.uiTree:textinput(text)
end



---LOVE callback for when the window is resized.
---@param w integer The new width of the window.
---@param h integer The new height of the window.
function Editor:resize(w, h)
    self.canvasMgr:resize(w, h)
end



return Editor