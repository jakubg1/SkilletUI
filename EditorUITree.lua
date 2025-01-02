local class = require "com.class"

---@class EditorUITree
---@overload fun(editor):EditorUITree
local EditorUITree = class:derive("EditorUITree")

-- Place your imports here
local Vec2 = require("Vector2")



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
    self.uiTreeInfo = {}
end



---Returns UI tree information.
---This function should only be called internally. If you want to get the current UI tree info, fetch the `self.uiTreeInfo` field instead.
---@param node Node? The UI node of which the tree should be added to the list.
---@param tab table? The table, used internally.
---@param indent integer? The starting indentation.
---@return table tab This is a one-dimensional table of entries in the form `{node = Node, indent = number}`.
function EditorUITree:getUITreeInfo(node, tab, indent)
    node = node or _UI
    tab = tab or {}
    indent = indent or 0
    table.insert(tab, {node = node, indent = indent})
    for i, child in ipairs(node.children) do
        self:getUITreeInfo(child, tab, indent + 1)
    end
    return tab
end



---Returns the hovered UI node in the tree, if one exists.
---@return Node?
function EditorUITree:getHoveredNode()
    self.hoverTop = false
    self.hoverBottom = false
    for i, entry in ipairs(self.uiTreeInfo) do
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



---Updates the Editor UI Tree.
---@param dt number Time delta in seconds.
function EditorUITree:update(dt)
    self.uiTreeInfo = self:getUITreeInfo()

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
    for i, line in ipairs(self.uiTreeInfo) do
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