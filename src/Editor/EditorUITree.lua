local class = require "com.class"

---@class EditorUITree
---@overload fun(editor):EditorUITree
local EditorUITree = class:derive("EditorUITree")

-- Place your imports here
local utf8 = require("utf8")
local Vec2 = require("src.Essentials.Vector2")
local NodeList = require("src.NodeList")

local CommandNodeRename = require("src.Editor.Commands.NodeRename")
local CommandNodeSetParent = require("src.Editor.Commands.NodeSetParent")
local CommandNodeMoveToTop = require("src.Editor.Commands.NodeMoveToTop")
local CommandNodeMoveToIndex = require("src.Editor.Commands.NodeMoveToIndex")



---Constructs a new Editor UI Tree.
---@param editor Editor The UI editor this UI tree belongs to.
function EditorUITree:new(editor)
    self.editor = editor

    self.POS = Vec2(5, 350)
    self.SIZE = Vec2(220, 375)
    self.ITEM_HEIGHT = 20
    self.ITEM_INDENT = 20
    self.ITEM_MARGIN = 5

    self.uiTreeInfo = {}
    self.showInternalUI = false

    self.scrollOffset = 0
    self.maxScrollOffset = 0
    self.hoverTop = false
    self.hoverBottom = false
    self.dragOrigin = nil
    self.dragSnap = false

    -- Stores the node that if clicked the second time will actually be name edited.
    -- This is because you could click elsewhere the second time and still activate that node's input box,
    -- even if that particular node was clicked just once.
    self.nameEditLastClickedNode = nil
    self.nameEditNode = nil
    self.nameEditValue = nil
end



---Returns UI tree information.
---This function should only be called internally. If you want to get the current UI tree info, fetch the `self.uiTreeInfo` field instead.
---@private
---@param node Node? The UI node of which the tree should be added to the list.
---@param tab table? The table, used internally.
---@param indent integer? The starting indentation.
---@param ignoreCollapses boolean? If set to `true`, the result will contain nodes that should be invisible in the UI tree. This is required by `NodeList:sortByTreeOrder()` and at some point will be removed.
---@return table tab This is a one-dimensional table of entries in the form `{node = Node, indent = number}`.
function EditorUITree:getUITreeInfo(node, tab, indent, ignoreCollapses)
    node = node or self.editor:getCurrentLayoutUI()
    if not node then
        -- Currently no layout is open.
        return {}
    end
    tab = tab or {}
    indent = indent or 0
    table.insert(tab, {node = node, indent = indent})
    for i, child in ipairs(node.children) do
        if ignoreCollapses or child:isVisibleInUITree() then
            self:getUITreeInfo(child, tab, indent + 1, ignoreCollapses)
        end
    end
    return tab
end



---Returns the Y coordinate of the n-th entry in the tree (starting from 1) on the screen. Does not take the position of the tree itself!
---@param n integer The item index.
---@return number
function EditorUITree:getItemY(n)
    return self.ITEM_HEIGHT * (n - 1) - self.scrollOffset
end



---Returns `true` if the mouse cursor is inside of the Editor UI Tree area, `false` otherwise.
---@return boolean
function EditorUITree:isHovered()
    return _Utils.isPointInsideBox(_MousePos, self.POS, self.SIZE)
end



---Returns the hovered UI node in the tree, if one exists.
---@return Node?
function EditorUITree:getHoveredNode()
    if not self:isHovered() then
        return nil
    end
    self.hoverTop = false
    self.hoverBottom = false
    for i, entry in ipairs(self.uiTreeInfo) do
        local y = self:getItemY(i)
        if _Utils.isPointInsideBox(_MousePos, self.POS + Vec2(0, y), Vec2(self.SIZE.x, self.ITEM_HEIGHT)) then
            self.editor.isNodeHoverIndirect = true
            -- Additional checks for specific parts of the entry. Used for node dragging so that you can drag in between the entries.
            if _Utils.isPointInsideBox(_MousePos, self.POS + Vec2(0, y), Vec2(self.SIZE.x, self.ITEM_MARGIN)) then
                self.hoverTop = true
            elseif _Utils.isPointInsideBox(_MousePos, self.POS + Vec2(0, y + self.ITEM_HEIGHT - self.ITEM_MARGIN), Vec2(self.SIZE.x, self.ITEM_MARGIN)) then
                self.hoverBottom = true
            end
            return entry.node
        end
    end
end



---Starts dragging the selected node in the node tree.
function EditorUITree:startDraggingSelectedNodeInNodeTree()
    -- TODO: Be able to drag multiple nodes in the tree.
    if self.editor.selectedNodes:getSize() ~= 1 then
        return
    end
    self.dragOrigin = _MousePos
    self.dragSnap = true
end



---Finishes dragging the selected node in the node tree and pushes a command so that the movement can be undone.
function EditorUITree:finishDraggingSelectedNodeInNodeTree()
    if self.editor.selectedNodes:getSize() ~= 1 or not self.dragOrigin then
        return
    end
    if not self.editor.hoveredNode then
        -- We've dropped the node on a nothing burger. Don't do anything.
        self:cancelDraggingSelectedNodeInNodeTree()
        return
    end
    if self.dragSnap then
        -- We didn't break the snap (mouse not moved enough to initiate the movement process), so reset everything as if nothing has ever happened.
        self:cancelDraggingSelectedNodeInNodeTree()
        return
    end
    local selectedNode = self.editor:getSingleSelectedNode()
    self.editor:startCommandTransaction()
    if self.hoverTop then
        -- We've dropped the node above the hovered node.
        -- First, make sure that our parent is correct.
        if selectedNode.parent ~= self.editor.hoveredNode.parent then
            self.editor:executeCommand(CommandNodeSetParent(self.editor.selectedNodes, self.editor.hoveredNode.parent))
        end
        -- Now, reorder it so that the selected node is before the hovered node.
        local index = self.editor.hoveredNode:getSelfIndex()
        if index > selectedNode:getSelfIndex() then
            index = index - 1
        end
        self.editor:executeCommand(CommandNodeMoveToIndex(self.editor.selectedNodes, index))
    elseif self.hoverBottom then
        -- We've dropped the node below the hovered node.
        if self.editor.hoveredNode:hasChildren() then
            -- If we've done this on a node that has children, the selected node should become its first child.
            self.editor:executeCommand(CommandNodeSetParent(self.editor.selectedNodes, self.editor.hoveredNode))
            self.editor:executeCommand(CommandNodeMoveToTop(self.editor.selectedNodes))
        else
            -- Otherwise, move on similarly to the top case.
            -- First, make sure that our parent is correct.
            if selectedNode.parent ~= self.editor.hoveredNode.parent then
                self.editor:executeCommand(CommandNodeSetParent(self.editor.selectedNodes, self.editor.hoveredNode.parent))
            end
            -- Now, reorder it so that the selected node is after the hovered node.
            local index = self.editor.hoveredNode:getSelfIndex() + 1
            if index > selectedNode:getSelfIndex() then
                index = index - 1
            end
            self.editor:executeCommand(CommandNodeMoveToIndex(self.editor.selectedNodes, index))
        end
    else
        -- We've dropped the node inside of another node: attach it as a parent.
        self.editor:executeCommand(CommandNodeSetParent(self.editor.selectedNodes, self.editor.hoveredNode))
    end
    self.editor:commitCommandTransaction()
    self.dragOrigin = nil
    self.dragSnap = false
end



---Cancels the drag of the selected node in the node tree.
function EditorUITree:cancelDraggingSelectedNodeInNodeTree()
    self.dragOrigin = nil
    self.dragSnap = false
end



---Selects the provided node, resets the name edit mode and changes the potential name edit node.
---@param node Node? The Node to be selected.
function EditorUITree:clickItem(node)
    if self.nameEditNode then
        self.nameEditNode = nil
        self.nameEditValue = nil
    end
    self.nameEditLastClickedNode = node
    if node then
        self.editor:clickNode(node)
        self.editor:updateUI()
        self:startDraggingSelectedNodeInNodeTree()
    end
end



---Starts the name edit mode for the provided Node.
---@param node Node The Node for which the name edit box should show up.
function EditorUITree:startNameEdit(node)
    self.nameEditNode = node
    self.nameEditValue = node:getName()
end

---Ends the name edit mode with saving the new node name.
function EditorUITree:submitNameEdit()
    if not self.nameEditNode then
        return
    end
    self.editor:executeCommand(CommandNodeRename(NodeList(self.nameEditNode), self.nameEditValue))
    self.nameEditNode = nil
    self.nameEditValue = nil
end

---Ends the name edit mode without saving the new node name.
function EditorUITree:cancelNameEdit()
    if not self.nameEditNode then
        return
    end
    self.nameEditNode = nil
    self.nameEditValue = nil
end



---Updates the Editor UI Tree.
---@param dt number Time delta in seconds.
function EditorUITree:update(dt)
    -- Update the tree information.
    self.uiTreeInfo = self:getUITreeInfo(self.showInternalUI and self.editor.UI or nil)

    -- Handle the node dragging in the node tree.
    if self.editor.selectedNodes:getSize() == 1 and self.dragOrigin then
        local movement = _MousePos - self.dragOrigin
        if self.dragSnap then
            if movement:len() > 5 then
                self.dragSnap = false
            end
        end
    end

    -- Calculate the maximum scroll offset.
    self.maxScrollOffset = math.max(self.ITEM_HEIGHT * #self.uiTreeInfo - self.SIZE.y, 0)
    -- Scroll back if we've scrolled too far.
    self.scrollOffset = math.min(self.scrollOffset, self.maxScrollOffset)
end



---Draws the Editor UI tree.
function EditorUITree:draw()
    -- Background
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)

    -- Node tree
    love.graphics.setScissor(self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)
    for i, line in ipairs(self.uiTreeInfo) do
        local x = self.POS.x + self.ITEM_INDENT * line.indent
        local y = self.POS.y + self:getItemY(i)
        local color = _COLORS.white
        if line.node.isController then
            color = _COLORS.orange
        elseif line.node:isControlled() then
            color = _COLORS.beige
        end
        local bgColor = nil
        if self.editor:isNodeSelected(line.node) then
            bgColor = _COLORS.cyan
        elseif line.node == self.editor.hoveredNode and (not self.dragOrigin or not (self.hoverTop or self.hoverBottom)) then
            -- The additional condition above makes it extra clear what are you doing when arranging the nodes around in the tree.
            bgColor = _COLORS.yellow
        end
        local alpha = 1
        if not line.node:getProp("visible") then
            alpha = 0.5
        elseif not line.node:isVisible() then
            alpha = 0.75
        end
        local image = line.node:getIcon()
        if bgColor then
            love.graphics.setColor(bgColor.r, bgColor.g, bgColor.b, 0.5)
            love.graphics.rectangle("fill", self.POS.x, y, self.SIZE.x, self.ITEM_HEIGHT)
        end
        love.graphics.setColor(1, 1, 1)
        image:draw(Vec2(x, y))
        if line.node:isLocked() then
            _RESOURCE_MANAGER:getImage("widget_locked"):draw(Vec2(self.POS.x + self.SIZE.x - 25, y))
        end
        if line.node == self.nameEditNode then
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.rectangle("fill", x + 23, y + 1, self.SIZE.x - x - 20, self.ITEM_HEIGHT - 2)
            love.graphics.setColor(0.2, 0.2, 1)
            love.graphics.rectangle("line", x + 23, y + 1, self.SIZE.x - x - 20, self.ITEM_HEIGHT - 2)
            self.editor:drawShadowedText(self.nameEditValue, x + 25, y + 2, _COLORS.black, nil, alpha, true)
        else
            self.editor:drawShadowedText(line.node:getName() .. (line.node:isCollapsed() and " ..." or ""), x + 25, y + 2, color, nil, alpha)
        end
        -- If dragged over, additional signs will be shown.
        if self.dragOrigin and not self.dragSnap and not self.editor:isNodeSelected(line.node) and line.node == self.editor.hoveredNode then
            if self.hoverTop then
                love.graphics.setColor(1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.line(x, y, self.POS.x + self.SIZE.x, y)
            elseif self.hoverBottom then
                -- Indent the line if this node has children.
                if line.node:hasChildren() then
                    x = x + self.ITEM_INDENT
                end
                love.graphics.setColor(1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.line(x, y + self.ITEM_HEIGHT, self.POS.x + self.SIZE.x, y + self.ITEM_HEIGHT)
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", self.POS.x, y, self.SIZE.x, self.ITEM_HEIGHT)
            end
        end
    end
    if #self.uiTreeInfo == 0 then
        self.editor:drawShadowedText("When you load a layout,\nits tree will show up here.", self.POS.x + 5, self.POS.y + 2)
    end
    love.graphics.setScissor()

    -- Scroll bar (non-interactive)
    if self.maxScrollOffset > 0 then
        love.graphics.setColor(0.5, 0.75, 1, 0.5)
        love.graphics.rectangle("fill", self.POS.x + self.SIZE.x - 10, self.POS.y, 10, self.SIZE.y)
        local y = self.scrollOffset / (self.maxScrollOffset + self.SIZE.y)
        local h = self.SIZE.y / (self.maxScrollOffset + self.SIZE.y)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", self.POS.x + self.SIZE.x - 10, self.POS.y + y * self.SIZE.y, 10, h * self.SIZE.y)
    end

    -- Border
    _SetColor(_COLORS.e_bblue)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)

    -- Dragged element in node tree
    if self.dragOrigin and not self.dragSnap then
        local selectedNode = self.editor:getSingleSelectedNode()
        self.editor:drawShadowedText(string.format("%s {%s}", selectedNode:getName(), selectedNode.type), _MousePos.x + 10, _MousePos.y + 15, _COLORS.white, _COLORS.blue)
    end
end



---Executed whenever a mouse button is pressed anywhere on the screen.
---Returns `true` if the input is consumed.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
---@param istouch boolean Whether the press is coming from a touch input.
---@param presses integer How many clicks have been performed in a short amount of time. Useful for double click checks.
---@return boolean
function EditorUITree:mousepressed(x, y, button, istouch, presses)
    local hoveredNode = self:getHoveredNode()
    if button == 1 then
        if not hoveredNode then
            self:cancelNameEdit()
        end
        if presses == 1 then
            -- Single click
            self:clickItem(hoveredNode)
            if hoveredNode then
                return true
            end
        else
            -- Subsequent clicks (double click)
            if hoveredNode == self.nameEditLastClickedNode then
                if hoveredNode then
                    -- We've clicked the same Node twice. Enable the name edit box.
                    self:startNameEdit(hoveredNode)
                    return true
                end
            else
                -- We've clicked a different Node. If that one will be clicked the second time now, its name could be edited.
                -- This could be the third click after double clikcing a different node. End name edit mode.
                self:clickItem(hoveredNode)
            end
        end
    elseif button == 2 then
        if hoveredNode then
            if hoveredNode:hasChildren() then
                hoveredNode:toggleCollapse()
            else
                -- Nodes with no children shouldn't ever be able to be collapsed.
                hoveredNode:setCollapsed(false)
            end
        end
    end
    return false
end



---Executed whenever a mouse wheel has been scrolled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function EditorUITree:wheelmoved(x, y)
    if self:isHovered() then
        self.scrollOffset = math.min(math.max(self.scrollOffset - y * self.ITEM_HEIGHT * 3, 0), self.maxScrollOffset)
    end
end



---Executed whenever a key is pressed on the keyboard.
---Returns `true` if the input is consumed.
---@param key string The key code.
---@return boolean
function EditorUITree:keypressed(key)
    if key == "f3" then
        self.showInternalUI = not self.showInternalUI
        return true
    end
    -- Anything below applies only if the name edit mode is enabled.
    if not self.nameEditNode then
        return false
    end
	if key == "backspace" then
        -- Remove the last character in the name edit field.
        local offset = utf8.offset(self.nameEditValue, -1)
        if offset then
            self.nameEditValue = self.nameEditValue:sub(1, offset - 1)
        end
        return true
    elseif key == "return" then
        -- Submit the current edit value in the name edit field.
        self:submitNameEdit()
        return true
    elseif key == "escape" then
        self:cancelNameEdit()
        return true
    end
	if self.nameEditNode then
		-- Do not let anything else catch the keyboard input if the name edition box is currently active.
		return true
	end
    return false
end



---Executed whenever a certain character has been typed on the keyboard.
---@param text string The character.
function EditorUITree:textinput(text)
    if not self.nameEditNode then
        return
    end
	self.nameEditValue = self.nameEditValue .. text
end



return EditorUITree