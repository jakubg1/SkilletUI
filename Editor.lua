local class = require "com.class"

---@class Editor
---@overload fun():Editor
local Editor = class:derive("Editor")

local Vec2 = require("Vector2")
local Node = require("Node")

local CommandNodeMove = require("EditorCommandNodeMove")
local CommandNodeDelete = require("EditorCommandNodeDelete")
local CommandNodeSetAlign = require("EditorCommandNodeSetAlign")
local CommandNodeSetParentAlign = require("EditorCommandNodeSetParentAlign")
local CommandNodeMoveUp = require("EditorCommandNodeMoveUp")
local CommandNodeMoveDown = require("EditorCommandNodeMoveDown")

---@alias EditorCommand* EditorCommandNodeSetAlign|EditorCommandNodeSetParentAlign|EditorCommandNodeMove|EditorCommandNodeDelete|EditorCommandNodeMoveUp|EditorCommandNodeMoveDown



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
---
--- To Do:
--- - Undo/Redo (rewrite to commands)
--- - Adding new nodes (and entire node groups for stuff like buttons, scroll bars, etc.)
--- - Copy/Paste
--- - Multi-selection(?)
--- - Dragging entries around in the node tree
--- - Widget manipulation (color, text, size, scale, etc.)
--- - Loading/switching layouts
--- - Saving layouts
--- - Animations at some point



---Constructs a new UI Editor.
function Editor:new()
    self.UI = nil

    self.UI_TREE_POS = Vec2(5, 120)

    self.commandHistory = {}
    self.undoCommandHistory = {}

    self.enabled = true
    self.hoveredNode = nil
    self.isNodeHoverIndirect = false
    self.selectedNode = nil
    self.nodeDragOrigin = nil
    self.nodeDragOriginalPos = nil
    self.nodeDragSnap = false
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
---This function also sets the value of the `self.isNodeHoverIndirect` field.
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
    for i, entry in ipairs(self.uiTreeInfo) do
        if _Utils.isPointInsideBox(_MousePos, self.UI_TREE_POS + Vec2(0, 15 * i), Vec2(200, 15)) then
            self.isNodeHoverIndirect = true
            return entry.node
        end
    end
    -- Finally, look if any node is directly hovered.
	return _UI:findChildByPixelDepthFirst(_MouseCPos)
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



---Finishes dragging the selected node.
function Editor:finishDraggingSelectedNode()
    if not self.selectedNode then
        return
    end
    self.nodeDragOrigin = nil
    self.nodeDragOriginalPos = nil
    self.nodeDragSnap = false
end



---Restores the original selected node position and finishes the dragging process.
function Editor:cancelDraggingSelectedNode()
    if not self.selectedNode then
        return
    end
    self.selectedNode:setPos(self.nodeDragOriginalPos)
    self:finishDraggingSelectedNode()
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



---Moves the selected node up in its parent's hierarchy.
function Editor:moveSelectedNodeUp()
    self:executeCommand(CommandNodeMoveUp(self.selectedNode))
end



---Moves the selected node down in its parent's hierarchy.
function Editor:moveSelectedNodeDown()
    self:executeCommand(CommandNodeMoveDown(self.selectedNode))
end



---Parents the currently selected node to the currently hovered node.
---The selected node becomes a child, and the hovered node becomes its parent.
function Editor:parentSelectedNodeToHoveredNode()
    if not self.selectedNode or not self.hoveredNode then
        return
    end
    self.hoveredNode:addChild(self.selectedNode)
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
        table.insert(self.commandHistory, command)
    end
    return result
end



---Undoes the command that has been executed last and moves it to the undo command stack.
function Editor:undoLastCommand()
    if #self.commandHistory == 0 then
        return
    end
    local command = table.remove(self.commandHistory)
    command:undo()
    table.insert(self.undoCommandHistory, command)
end



---Redoes the undone command and moves it back to the main command stack.
function Editor:redoLastCommand()
    if #self.undoCommandHistory == 0 then
        return
    end
    local command = table.remove(self.undoCommandHistory)
    command:execute()
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
    local button = Node({name = "", type = "9sprite", image = "ed_button", clickImage = "ed_button_click", shortcut = key, pos = {x = x, y = y}, size = {x = w, y = 20}, scale = 2, children = {{name = "", type = "text", font = "default", text = text, pos = {x = 0, y = -1}, align = "center", parentAlign = "center", color = {r = 0, g = 0, b = 0}}}})
    button:setOnClick(fn)
    return button
end



---Returns whether an editor button (or any editor UI) is hovered.
---@return boolean
function Editor:isUIHovered()
    return self.UI:isHoveredWithChildren()
end



---Initializes the UI for this Editor.
function Editor:load()
    self.UI = _LoadUI("editor_ui.json")
    local buttons = {
        self:button(0, 400, 150, "Delete [Del]", function() self:deleteSelectedNode() end, "delete"),
        self:button(0, 420, 150, "Layer Up [PgUp]", function() self:moveSelectedNodeUp() end, "pageup"),
        self:button(0, 440, 150, "Layer Down [PgDown]", function() self:moveSelectedNodeDown() end, "pagedown"),

        self:button(100, 640, 30, "TL", function() self:setSelectedNodeAlign(_ALIGNMENTS.topLeft) end),
        self:button(130, 640, 30, "T", function() self:setSelectedNodeAlign(_ALIGNMENTS.top) end),
        self:button(160, 640, 30, "TR", function() self:setSelectedNodeAlign(_ALIGNMENTS.topRight) end),
        self:button(100, 660, 30, "ML", function() self:setSelectedNodeAlign(_ALIGNMENTS.left) end),
        self:button(130, 660, 30, "M", function() self:setSelectedNodeAlign(_ALIGNMENTS.center) end),
        self:button(160, 660, 30, "MR", function() self:setSelectedNodeAlign(_ALIGNMENTS.right) end),
        self:button(100, 680, 30, "BL", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottomLeft) end),
        self:button(130, 680, 30, "B", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottom) end),
        self:button(160, 680, 30, "BR", function() self:setSelectedNodeAlign(_ALIGNMENTS.bottomRight) end),

        self:button(300, 640, 30, "TL", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.topLeft) end),
        self:button(330, 640, 30, "T", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.top) end),
        self:button(360, 640, 30, "TR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.topRight) end),
        self:button(300, 660, 30, "ML", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.left) end),
        self:button(330, 660, 30, "M", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.center) end),
        self:button(360, 660, 30, "MR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.right) end),
        self:button(300, 680, 30, "BL", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottomLeft) end),
        self:button(330, 680, 30, "B", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottom) end),
        self:button(360, 680, 30, "BR", function() self:setSelectedNodeParentAlign(_ALIGNMENTS.bottomRight) end),
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

    self.UI:update(dt)
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
        end
        self:drawShadowedText(string.format("%s {%s}", line.node.name, line.node.type), x, y, color)
    end

    -- Command buffer
    self:drawShadowedText("Command Buffer", 1100, 20)
    for i, command in ipairs(self.commandHistory) do
        self:drawShadowedText(command.NAME, 1100, 35 + 15 * i)
    end

    -- Buttons
    self:drawShadowedText("Node Align", 100, 620)
    self:drawShadowedText("Parent Align", 300, 620)
    self:drawShadowedText("Ctrl+Click a node to make it a parent of the currently selected node", 500, 620)
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
function Editor:drawShadowedText(text, x, y, color)
    color = color or _COLORS.white
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
	if button == 1 and not self:isUIHovered() then
        if love.keyboard.isDown("lctrl", "rctrl") then
            -- Ctrl+Click parents the selected node instead.
            self:parentSelectedNodeToHoveredNode()
        else
            self.selectedNode = self.hoveredNode
            if self.selectedNode and not self.isNodeHoverIndirect then
                -- Indirectly selected nodes (by clicking on the hierarchy tree) cannot be dragged.
                self:startDraggingSelectedNode()
            end
        end
    elseif button == 2 and self.nodeDragOrigin then
        -- Cancel dragging if the right click is received.
        self:cancelDraggingSelectedNode()
	end
end



---Executed whenever a mouse button is released anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function Editor:mousereleased(x, y, button)
    self.UI:mousereleased(x, y, button)
    self:finishDraggingSelectedNode()
end



---Executed whenever a key is pressed on the keyboard.
---@param key string The key code.
function Editor:keypressed(key)
    self.UI:keypressed(key)
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
    elseif key == "backspace" then
        self:undoLastCommand()
    elseif key == "=" then
        self:redoLastCommand()
	end
end



return Editor