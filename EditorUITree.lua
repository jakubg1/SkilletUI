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
    self.SIZE = Vec2(210, 500)
    self.ITEM_HEIGHT = 20
    self.ITEM_MARGIN = 8

    self.scrollOffset = 0
    self.maxScrollOffset = 0
    self.hoverTop = false
    self.hoverBottom = false
    self.dragOrigin = nil
    self.dragSnap = false
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
    for i, entry in ipairs(self.editor.uiTreeInfo) do
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

    -- Calculate the maximum scroll offset.
    self.maxScrollOffset = math.max(self.ITEM_HEIGHT * #self.editor.uiTreeInfo - self.SIZE.y, 0)
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
    for i, line in ipairs(self.editor.uiTreeInfo) do
        local x = self.POS.x + 30 * line.indent
        local y = self.POS.y + self:getItemY(i)
        local color = _COLORS.white
        if line.node.isController then
            color = _COLORS.orange
        elseif line.node:isControlled() then
            color = _COLORS.lightOrange
        end
        local bgColor = nil
        if line.node == self.editor.selectedNode then
            bgColor = _COLORS.cyan
        elseif line.node == self.editor.hoveredNode then
            bgColor = _COLORS.yellow
        end
        local image = _IMAGES.widget_none
        if line.node.type == "box" then
            image = _IMAGES.widget_box
        elseif line.node.type == "button" then
            image = _IMAGES.widget_button
        elseif line.node.type == "canvas" then
            image = _IMAGES.widget_canvas
        elseif line.node.type == "9sprite" then
            image = _IMAGES.widget_ninesprite
        elseif line.node.type == "text" then
            image = _IMAGES.widget_text
        elseif line.node.type == "@titleDigit" then
            image = _IMAGES.widget_titledigit
        end
        if bgColor then
            love.graphics.setColor(bgColor.r, bgColor.g, bgColor.b, 0.3)
            love.graphics.rectangle("fill", self.POS.x, y, self.SIZE.x, self.ITEM_HEIGHT)
        end
        love.graphics.setColor(1, 1, 1)
        image:draw(Vec2(x, y))
        self.editor:drawShadowedText(line.node.name, x + 25, y + 2, color)
        -- If dragged over, additional signs will be shown.
        if self.dragOrigin and not self.dragSnap and line.node ~= self.editor.selectedNode and line.node == self.editor.hoveredNode then
            if self.hoverTop then
                love.graphics.setColor(1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.line(x, y, self.POS.x + self.SIZE.x, y)
            elseif self.hoverBottom then
                -- Indent the line if this node has children.
                if line.node:hasChildren() then
                    x = x + 30
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
    love.graphics.setColor(0.5, 0.75, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)

    -- Dragged element in node tree
    if self.dragOrigin and not self.dragSnap then
        self.editor:drawShadowedText(string.format("%s {%s}", self.editor.selectedNode.name, self.editor.selectedNode.type), _MousePos.x + 10, _MousePos.y + 15, _COLORS.white, _COLORS.blue)
    end
end



---Executed whenever a mouse wheel has been scrolled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function EditorUITree:wheelmoved(x, y)
    if self:isHovered() then
        self.scrollOffset = math.min(math.max(self.scrollOffset - y * self.ITEM_HEIGHT * 3, 0), self.maxScrollOffset)
    end
end



return EditorUITree