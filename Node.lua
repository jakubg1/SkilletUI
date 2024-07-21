local class = require "com.class"

---@class Node
---@overload fun(data, parent):Node
local Node = class:derive("Node")

local Vec2 = require("Vector2")
local Box = require("Box")
local Canvas = require("Canvas")
local NineSprite = require("NineSprite")
local Text = require("Text")
local TitleDigit = require("TitleDigit")



---Creates a new UI Node.
---@param data table The node data.
---@param parent Node? The parent node.
function Node:new(data, parent)
    self.parent = parent

    self.name = data.name
    self.type = data.type
    self.pos = Vec2(data.pos)
    self.align = data.align and _ALIGNMENTS[data.align] or Vec2(data.align)
    self.parentAlign = data.parentAlign and _ALIGNMENTS[data.parentAlign] or Vec2(data.parentAlign)
    self.alpha = data.alpha or 1
    self.shortcut = data.shortcut
    self.inputScale = data.inputScale or 1

    self.clicked = false
    self.onClick = nil

    if data.type == "box" then
        self.widget = Box(self, data)
    elseif data.type == "canvas" then
        -- Not supported. Canvases have a few problems:
        -- - Debug drawing
        -- - Drawing stuff other than UI on such canvas would be a problem
        self.isCanvas = true
        self.widget = Canvas(self, data)
    elseif data.type == "9sprite" then
        self.widget = NineSprite(self, data)
    elseif data.type == "text" then
        self.widget = Text(self, data)
    elseif data.type == "@titleDigit" then
        self.widget = TitleDigit(self, data)
    end

    self.children = {}
    if data.children then
    	for i, child in ipairs(data.children) do
	    	table.insert(self.children, Node(child, self))
	    end
    end
    self.deleteIndex = nil
end



---Returns the name of this Node.
function Node:getName()
    return self.name
end



---Renames this Node.
---@param name string The new name.
function Node:setName(name)
    self.name = name
end



---Returns the local position of this Node, which is relative to its parent's position.
---@return Vector2
function Node:getPos()
    return self.pos
end



---Sets the local position of this Node, which is relative to its parent's position.
---@param pos Vector2 The new local position to be set.
function Node:setPos(pos)
    self.pos = pos
end



---Returns the global position of this Node, i.e. the actual position after factoring in all parents' modifiers.
---@return Vector2
function Node:getGlobalPos()
    return self.pos - ((self:getSize() - 1) * self.align):ceil() + self:getParentAlignPos()
end



---Returns the global position of this Node, which has not been adjusted for the local widget alignment.
---@return Vector2
function Node:getGlobalPosWithoutLocalAlign()
    return self.pos + self:getParentAlignPos()
end



---Returns the Node's parent anchor. If the Node does not have a parent, this function will return `(0, 0)`.
---@return Vector2
function Node:getParentAlignPos()
    if self.parent then
        return self.parent:getGlobalPos() + ((self.parent:getSize() - 1) * self.parentAlign):ceil()
    end
    return Vec2()
end



---Returns the size of this Node's widget, or `(1, 1)` if it contains no widget.
---@return Vector2
function Node:getSize()
    if self.widget then
        return self.widget:getSize()
    end
    return Vec2(1)
end



---Returns the input scale of this Node.
---@return number
function Node:getInputScale()
    if self.parent then
        return self.parent:getInputScale() * self.inputScale
    end
    return self.inputScale
end



---Returns the current alignment of the Node.
---@return Vector2
function Node:getAlign()
    return self.align
end



---Sets the alignment of this Node.
---@param align Vector2 The new Node alignment.
--- - `(0, 0)` aligns to top left.
--- - `(1, 1)` aligns to bottom right.
--- - `(0.5, 0.5)` aligns to the center.
--- - Any combination is available, including going out of bounds.
function Node:setAlign(align)
    self.align = align
end



---Returns the current parental alignment of the Node.
---@return Vector2
function Node:getParentAlign()
    return self.parentAlign
end



---Sets the parental alignment of this Node.
---@param parentAlign Vector2 The new Node alignment.
--- - `(0, 0)` aligns to top left.
--- - `(1, 1)` aligns to bottom right.
--- - `(0.5, 0.5)` aligns to the center.
--- - Any combination is available, including going out of bounds.
function Node:setParentAlign(parentAlign)
    self.parentAlign = parentAlign
end



---Sets an on-click function (or resets it, if no argument is provided).
---@param f function? The function to be executed if this Node is clicked.
function Node:setOnClick(f)
    self.onClick = f
end



---Returns whether this Node is hovered.
function Node:isHovered()
    return self:hasPixel(_MousePos / self:getInputScale())
end



---Returns whether this Node or any of its children is hovered.
function Node:isHoveredWithChildren()
    if self:isHovered() then
        return true
    end
    for i, child in ipairs(self.children) do
        if child:isHoveredWithChildren() then
            return true
        end
    end
    return false
end



---Inserts the provided Node as a child of this Node.
---If the provided Node is already integrated into another UI tree (has a parent), it is removed from that parent - the Node is effectively moved.
---Returns `true` on success, `false` if the tree would form a cycle or when the widget would be parented to itself.
---@param node Node The node to be added.
---@param index number? The index specifying where in the hierarchy the Node should be located. By default, it is inserted as the last element (on the bottom).
---@return boolean
function Node:addChild(node, index)
    if node == self or node:findChild(self) then
        -- We cannot parent a node to itself or its own child, or else we will get stuck in a loop!!!
        return false
    end
    -- Resolve linkages.
    if node.parent then
        node:removeSelf()
    end
    node.parent = self
    -- Add as a child.
    if index then
        table.insert(self.children, index, node)
    else
        table.insert(self.children, node)
    end
    return true
end



---Removes a child Node by its reference. Returns `true` on success.
---@param node Node The node to be removed.
---@return boolean
function Node:removeChild(node)
    local index = self:getChildIndex(node)
    if index then
        table.remove(self.children, index)
        node.deleteIndex = index
        return true
    end
    return false
end



---Removes itself from a parent Node. If succeeded, returns `true`.
---If this Node has no parent, this function will fail and return `false`.
---@return boolean
function Node:removeSelf()
    if not self.parent then
        return false
    end
    return self.parent:removeChild(self)
end



---Restores this Node to the tree after its deletion.
function Node:restoreSelf()
    if not self.deleteIndex then
        return
    end
    self.parent:addChild(self, self.deleteIndex)
    self.deleteIndex = nil
end



---Moves a child Node up in the hierarchy (to the front), by its reference.
---Returns `true` if the node has been successfully moved, `false` if the node could not be found or is already the frontmost node.
---@param node Node The node to be moved up.
---@return boolean
function Node:moveChildUp(node)
    local index = self:getChildIndex(node)
    if not index then
        return false
    end
    return self:moveChildToPosition(node, index - 1)
end



---Moves itself up in the hierarchy of the parent Node.
---If this Node has no parent, this function will fail and return `false`. If the operation succeeds, returns `true`.
---@return boolean
function Node:moveSelfUp()
    if not self.parent then
        return false
    end
    return self.parent:moveChildUp(self)
end



---Moves a child Node down in the hierarchy (to the back), by its reference.
---Returns `true` if the node has been successfully moved, `false` if the node could not be found or is already the backmost node.
---@param node Node The node to be moved down.
---@return boolean
function Node:moveChildDown(node)
    local index = self:getChildIndex(node)
    if not index then
        return false
    end
    return self:moveChildToPosition(node, index + 1)
end



---Moves itself down in the hierarchy of the parent Node.
---If this Node has no parent, this function will fail and return `false`. If the operation succeeds, returns `true`.
---@return boolean
function Node:moveSelfDown()
    if not self.parent then
        return false
    end
    return self.parent:moveChildDown(self)
end



---Moves a child Node to the top of the hierarchy (to the front), by its reference.
---Returns `true` if the node has been successfully moved, `false` if the node could not be found or is already the frontmost node.
---@param node Node The node to be moved to the top.
---@return boolean
function Node:moveChildToTop(node)
    return self:moveChildToPosition(node, 1)
end



---Moves itself to the top of the hierarchy of the parent Node.
---If this Node has no parent, this function will fail and return `false`. If the operation succeeds, returns `true`.
---@return boolean
function Node:moveSelfToTop()
    if not self.parent then
        return false
    end
    return self.parent:moveChildToTop(self)
end



---Moves a child Node to the bottom of the hierarchy (to the front), by its reference.
---Returns `true` if the node has been successfully moved, `false` if the node could not be found or is already the backmost node.
---@param node Node The node to be moved to the bottom.
---@return boolean
function Node:moveChildToBottom(node)
    return self:moveChildToPosition(node, #self.children)
end



---Moves itself to the bottom of the hierarchy of the parent Node.
---If this Node has no parent, this function will fail and return `false`. If the operation succeeds, returns `true`.
---@return boolean
function Node:moveSelfToBottom()
    if not self.parent then
        return false
    end
    return self.parent:moveChildToBottom(self)
end



---Moves a child Node to the given position in the hierarchy by its reference.
---Returns `true` if the node has been successfully moved, `false` if the node could not be found, is already at the given position or the position is out of bounds.
---@param node Node The node to be moved.
---@param position integer The new Node position. `1` is the top, `#self.children` is the bottom.
---@return boolean
function Node:moveChildToPosition(node, position)
    -- Fail if the position is illegal.
    if position < 1 or position > #self.children then
        return false
    end
    local i = self:getChildIndex(node)
    -- Fail if the given node is not our child or is already at the right position.
    if not i or i == position then
        return false
    end
    table.remove(self.children, i)
    table.insert(self.children, position, node)
    return true
end



---Moves itself to the given position if the hierarchy of the parent Node.
---If this Node has no parent, this function will fail and return `false`. If the operation succeeds, returns `true`.
---@return boolean
function Node:moveSelfToPosition(position)
    if not self.parent then
        return false
    end
    return self.parent:moveChildToPosition(self, position)
end



---Returns the index of a child contained in this Node. If the given node is not a child of this node, returns `nil`.
---@param node Node The node to be looked for.
---@return integer?
function Node:getChildIndex(node)
    return _Utils.getKeyInTable(self.children, node)
end



---Returns the index of this Node in its parent. If this Node has no parent, returns `nil`.
---@return integer?
function Node:getSelfIndex()
    if not self.parent then
        return nil
    end
    return self.parent:getChildIndex(self)
end



---Returns `true` if the given pixel position is inside of this Node's bounding box.
---@param pos Vector2 The position to be checked.
---@return boolean
function Node:hasPixel(pos)
    return _Utils.isPointInsideBox(pos, self:getGlobalPos(), self:getSize())
end



---Returns the first encountered child by reference, or `nil` if it is not found.
---@param node Node The instance of the child to be found.
---@return Node?
function Node:findChild(node)
    for i, child in ipairs(self.children) do
        if child == node then
            return child
        end
        local potentialResult = child:findChild(node)
        if potentialResult then
            return potentialResult
        end
    end
end



---Returns the first encountered child of the provided name, or `nil` if it is not found.
---@param name string The name of the child to be found.
---@return Node?
function Node:findChildByName(name)
    for i, child in ipairs(self.children) do
        if child.name == name then
            return child
        end
        local potentialResult = child:findChildByName(name)
        if potentialResult then
            return potentialResult
        end
    end
end



---Returns the first encountered child that contains the provided position, or `nil` if it is not found.
---@param pos Vector2 The position to be checked.
---@return Node?
function Node:findChildByPixel(pos)
    for i, child in ipairs(self.children) do
        if child:hasPixel(pos) then
            return child
        end
        local potentialResult = child:findChildByPixel(pos)
        if potentialResult then
            return potentialResult
        end
    end
end



---Returns the first encountered child that contains the provided position (depth first), or `nil` if it is not found.
---@param pos Vector2 The position to be checked.
---@return Node?
function Node:findChildByPixelDepthFirst(pos)
    for i, child in ipairs(self.children) do
        local potentialResult = child:findChildByPixelDepthFirst(pos)
        if potentialResult then
            return potentialResult
        end
        if child:hasPixel(pos) then
            return child
        end
    end
end



---Returns the last encountered child that contains the provided position (depth first), or `nil` if it is not found.
---@param pos Vector2 The position to be checked.
---@return Node?
function Node:findChildByPixelDepthFirstReverse(pos)
    local result = nil
    for i, child in ipairs(self.children) do
        if child:hasPixel(pos) then
            result = child
        end
        local potentialResult = child:findChildByPixelDepthFirst(pos)
        if potentialResult then
            result = potentialResult
        end
    end
    return result
end



---Updates this Node's widget, if it exists, and all its children.
---@param dt number Time delta, in seconds.
function Node:update(dt)
    if self.widget then
        self.widget:update(dt)
    end
    for i, child in ipairs(self.children) do
        child:update(dt)
    end
end



---Draws this Node's widget, if it exists, and all of its children.
---The draw order is as follows:
--- - First, the node itself is drawn.
--- - Then, its children are drawn in *reverse* order (from bottom to the top), so that the first entry in the hierarchy is the topmost one.
--- - If any child has its own children, draw them immediately after that child has been drawn.
function Node:draw()
    if not self.isCanvas then
        if self.widget then
            self.widget:draw()
        end
        for i = #self.children, 1, -1 do
            local child = self.children[i]
            child:draw()
        end
    else
        -- Canvases are treated differently.
        self.widget:activate()
        for i = #self.children, 1, -1 do
            local child = self.children[i]
            child:draw()
        end
        self.widget:draw()
    end
end



---Draws this Node's bounding box, or a crosshair if this Node has no widget.
---The borders are all inclusive.
function Node:drawHitbox()
    local pos = self:getGlobalPos()
    love.graphics.setLineWidth(1)
    if self.widget then
        local size = self:getSize()
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("line", pos.x + 0.5, pos.y + 0.5, size.x - 1, size.y - 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        self:drawCrosshair(pos, 2)
    end
end



---Draws this Node's bounding box in a different color (or a crosshair if this Node has no widget), and some indicators around.
---The borders are all inclusive.
function Node:drawSelected()
    local pos = self:getGlobalPos()
    love.graphics.setLineWidth(1)
    if self.widget then
        local size = self:getSize()
        love.graphics.setColor(0, 1, 1)
        love.graphics.rectangle("line", pos.x + 0.5, pos.y + 0.5, size.x - 1, size.y - 1)
    else
        love.graphics.setColor(1, 1, 1)
        self:drawCrosshair(pos, 2)
    end
    -- Draw local crosshair.
    local localPos = self:getGlobalPosWithoutLocalAlign()
    love.graphics.setColor(0, 0, 1)
    self:drawCrosshair(localPos, 2)
    -- Draw parent align crosshair.
    local localPos2 = self:getParentAlignPos()
    love.graphics.setColor(1, 0, 1)
    self:drawCrosshair(localPos2, 2)
    -- Draw a line between them.
    love.graphics.setColor(0.5, 0, 1)
    love.graphics.line(localPos.x, localPos.y, localPos2.x, localPos2.y)
end



---Internal function which draws a crosshair.
---@param pos Vector2 The crosshair position.
---@param size number The crosshair size, in pixels.
function Node:drawCrosshair(pos, size)
    pos = pos:floor() + 0.5
    love.graphics.line(pos.x - size, pos.y, pos.x + size, pos.y)
    love.graphics.line(pos.x, pos.y - size, pos.x, pos.y + size)
end



---Executed whenever a mouse button is pressed anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
function Node:mousepressed(x, y, button)
    if button == 1 and self:isHovered() then
        self.clicked = true
    end
    for i, child in ipairs(self.children) do
        child:mousepressed(x, y, button)
    end
end



---Executed whenever a mouse button is released anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function Node:mousereleased(x, y, button)
    if button == 1 and self.clicked then
        self.clicked = false
        -- We don't want the click function to occur if the cursor was released outside of the node.
        if self:isHovered() then
            if self.onClick then
                self.onClick()
            end
        end
    end
    for i, child in ipairs(self.children) do
        child:mousereleased(x, y, button)
    end
end



---Executed whenever a key is pressed on the keyboard.
---@param key string Code of the key that has been pressed.
function Node:keypressed(key)
    if key == self.shortcut and not _IsCtrlPressed() and not _IsShiftPressed() then
        if self.onClick then
            self.onClick()
        end
    end
    for i, child in ipairs(self.children) do
        child:keypressed(key)
    end
end



return Node