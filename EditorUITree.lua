local class = require "com.class"

---@class EditorUITree
---@overload fun(editor):EditorUITree
local EditorUITree = class:derive("EditorUITree")

-- Place your imports here
local Vec2 = require("Vector2")

local CommandNodeSetParent = require("EditorCommands.NodeSetParent")
local CommandNodeMoveToTop = require("EditorCommands.NodeMoveToTop")
local CommandNodeMoveToIndex = require("EditorCommands.NodeMoveToIndex")



---Constructs a new Editor UI Tree.
---@param editor Editor The UI editor this UI tree belongs to.
function EditorUITree:new(editor)
    self.editor = editor

    self.POS = Vec2(5, 120)
    self.ITEM_HEIGHT = 20
    self.ITEM_MARGIN = 8

    self.hoverTop = false
    self.hoverBottom = false
    self.dragOrigin = nil
    self.dragSnap = false
end



---Returns the hovered UI node in the tree, if one exists.
---@return Node?
function EditorUITree:getHoveredNode()
    self.hoverTop = false
    self.hoverBottom = false
    for i, entry in ipairs(self.editor.uiTreeInfo) do
        if _Utils.isPointInsideBox(_MousePos, self.POS + Vec2(0, self.ITEM_HEIGHT * i), Vec2(200, self.ITEM_HEIGHT)) then
            self.editor.isNodeHoverIndirect = true
            -- Additional checks for specific parts of the entry. Used for node dragging so that you can drag in between the entries.
            if _Utils.isPointInsideBox(_MousePos, self.POS + Vec2(0, self.ITEM_HEIGHT * i), Vec2(200, self.ITEM_MARGIN)) then
                self.hoverTop = true
            elseif _Utils.isPointInsideBox(_MousePos, self.POS + Vec2(0, self.ITEM_HEIGHT * i + self.ITEM_HEIGHT - self.ITEM_MARGIN), Vec2(200, self.ITEM_MARGIN)) then
                self.hoverBottom = true
            end
            return entry.node
        end
    end
end



---Starts dragging the selected node in the node tree.
function EditorUITree:startDraggingSelectedNodeInNodeTree()
    if not self.editor.selectedNode then
        return
    end
    self.dragOrigin = _MousePos
    self.dragSnap = true
end



---Finishes dragging the selected node in the node tree and pushes a command so that the movement can be undone.
function EditorUITree:finishDraggingSelectedNodeInNodeTree()
    if not self.editor.selectedNode or not self.dragOrigin then
        return
    end
    if self.dragSnap then
        -- We didn't break the snap (mouse not moved enough to initiate the movement process), so reset everything as if nothing has ever happened.
        self:cancelDraggingSelectedNodeInNodeTree()
        return
    end
    self.editor:startCommandTransaction()
    if self.hoverTop then
        -- We've dropped the node above the hovered node.
        -- First, make sure that our parent is correct.
        if self.editor.selectedNode.parent ~= self.editor.hoveredNode.parent then
            self.editor:executeCommand(CommandNodeSetParent(self.editor.selectedNode, self.editor.hoveredNode.parent))
        end
        -- Now, reorder it so that the selected node is before the hovered node.
        local index = self.editor.hoveredNode:getSelfIndex()
        if index > self.editor.selectedNode:getSelfIndex() then
            index = index - 1
        end
        self.editor:executeCommand(CommandNodeMoveToIndex(self.editor.selectedNode, index))
    elseif self.hoverBottom then
        -- We've dropped the node below the hovered node.
        if self.editor.hoveredNode:hasChildren() then
            -- If we've done this on a node that has children, the selected node should become its first child.
            self.editor:executeCommand(CommandNodeSetParent(self.editor.selectedNode, self.editor.hoveredNode))
            self.editor:executeCommand(CommandNodeMoveToTop(self.editor.selectedNode))
        else
            -- Otherwise, move on similarly to the top case.
            -- First, make sure that our parent is correct.
            if self.editor.selectedNode.parent ~= self.editor.hoveredNode.parent then
                self.editor:executeCommand(CommandNodeSetParent(self.editor.selectedNode, self.editor.hoveredNode.parent))
            end
            -- Now, reorder it so that the selected node is after the hovered node.
            local index = self.editor.hoveredNode:getSelfIndex() + 1
            if index > self.editor.selectedNode:getSelfIndex() then
                index = index - 1
            end
            self.editor:executeCommand(CommandNodeMoveToIndex(self.editor.selectedNode, index))
        end
    else
        -- We've dropped the node inside of another node: attach it as a parent.
        self.editor:executeCommand(CommandNodeSetParent(self.editor.selectedNode, self.editor.hoveredNode))
    end
    self.editor:closeCommandTransaction()
    self.dragOrigin = nil
    self.dragSnap = false
end



---Cancels the drag of the selected node in the node tree.
function EditorUITree:cancelDraggingSelectedNodeInNodeTree()
    self.dragOrigin = nil
    self.dragSnap = false
end



---Updates the Editor UI Tree.
---@param dt number Time delta in seconds.
function EditorUITree:update(dt)
    -- Handle the node dragging in the node tree.
    if self.editor.selectedNode and self.dragOrigin then
        local movement = _MousePos - self.dragOrigin
        if self.dragSnap then
            if movement:len() > 5 then
                self.dragSnap = false
            end
        end
    end
end



---Draws the Editor UI tree.
function EditorUITree:draw()
    -- Node tree
    for i, line in ipairs(self.editor.uiTreeInfo) do
        local x = self.POS.x + 30 * line.indent
        local y = self.POS.y + self.ITEM_HEIGHT * i
        local color = _COLORS.white
        if line.node == self.editor.selectedNode then
            color = _COLORS.cyan
        elseif line.node == self.editor.hoveredNode then
            color = _COLORS.yellow
        elseif line.node.isController then
            color = _COLORS.purple
        elseif line.node:isControlled() then
            color = _COLORS.lightPurple
        end
        self.editor:drawShadowedText(string.format("%s {%s}", line.node.name, line.node.type), x, y, color)
        -- If dragged over, additional signs will be shown.
        if self.dragOrigin and not self.dragSnap and line.node ~= self.editor.selectedNode and line.node == self.editor.hoveredNode then
            if self.hoverTop then
                love.graphics.setColor(1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.line(x, y, self.POS.x + 200, y)
            elseif self.hoverBottom then
                -- Indent the line if this node has children.
                if line.node:hasChildren() then
                    x = x + 30
                end
                love.graphics.setColor(1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.line(x, y + self.ITEM_HEIGHT, self.POS.x + 200, y + self.ITEM_HEIGHT)
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", self.POS.x, y, 200, self.ITEM_HEIGHT)
            end
        end
    end

    -- Dragged element in node tree
    if self.dragOrigin and not self.dragSnap then
        self.editor:drawShadowedText(string.format("%s {%s}", self.editor.selectedNode.name, self.editor.selectedNode.type), _MousePos.x + 10, _MousePos.y + 15, _COLORS.white, _COLORS.blue)
    end
end



return EditorUITree