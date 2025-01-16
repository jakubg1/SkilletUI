local class = require "com.class"

---@class Node
---@overload fun(data, parent):Node
local Node = class:derive("Node")

local Vec2 = require("Vector2")
local PropertyList = require("PropertyList")
local Box = require("Widgets.Box")
local Button = require("Widgets.Button")
local Canvas = require("Widgets.Canvas")
local InputText = require("Widgets.InputText")
local NineSprite = require("Widgets.NineSprite")
local Text = require("Widgets.Text")
local TitleDigit = require("Widgets.TitleDigit")

local WIDGET_TYPES = {
    none = {constructor = nil, defaultName = "Node"},
    box = {constructor = Box, defaultName = "Box"},
    button = {constructor = Button, defaultName = "Button"},
    canvas = {constructor = Canvas, defaultName = "Canvas"},
    input_text = {constructor = InputText, defaultName = "InputText"},
    ["9sprite"] = {constructor = NineSprite, defaultName = "NineSprite"},
    text = {constructor = Text, defaultName = "Text"},
    ["@titleDigit"] = {constructor = TitleDigit, defaultName = "TitleDigit"}
}



---Creates a new UI Node.
---@param data table The node data.
---@param parent Node? The parent node.
function Node:new(data, parent)
    self.parent = parent

    self.PROPERTY_LIST = {
        {name = "Name", key = "name", type = "string", defaultValue = "ERROR", disabledIfControlled = true},
        {name = "Position", key = "pos", type = "Vector2", defaultValue = Vec2()},
        {name = "Align", key = "align", type = "align", defaultValue = _ALIGNMENTS.topLeft},
        {name = "Parent Align", key = "parentAlign", type = "align", defaultValue = _ALIGNMENTS.topLeft},
        {name = "Visible", key = "visible", type = "boolean", defaultValue = true},
        {name = "Canvas Input Mode", key = "canvasInputMode", type = "boolean", defaultValue = false},
        {name = "Shortcut", key = "shortcut", type = "shortcut", nullable = true},
        {name = "Signal On Click", key = "signalOnClick", type = "string", nullable = true}
    }
    self.properties = PropertyList(self.PROPERTY_LIST, data)

    self.type = "none"

    self.clicked = false
    self.onClick = nil
    self.disabled = false

    self.children = {}
    self.deleteIndex = nil

    self:deserialize(data)
end



---Returns the given property of this Node.
---@param key string The property key.
---@return any?
function Node:getProp(key)
    return self.properties:getValue(key)
end



---Sets the given property of this Node to a given value.
---@param key string The property key.
---@param value any? The property value.
function Node:setProp(key, value)
    self.properties:setValue(key, value)
end



---Returns the given property base of this Node.
---@param key string The property key.
---@return any?
function Node:getPropBase(key)
    return self.properties:getBaseValue(key)
end



---Sets the given property base of this Node to a given value.
---@param key string The property key.
---@param value any? The property value.
function Node:setPropBase(key, value)
    self.properties:setBaseValue(key, value)
end



---Resets all of the properties of this Node, its Widget, and all its children to the base values.
function Node:resetProperties()
    self.properties:reset()
    if self.widget and self.widget.properties then
        self.widget.properties:reset()
    end
    for i, child in ipairs(self.children) do
        child:resetProperties()
    end
end



---Returns the name of this Node.
function Node:getName()
    return self:getProp("name")
end



---Renames this Node. Returns `true` on success.
---@param name string The new name.
---@return boolean
function Node:setName(name)
    -- Controlled Nodes cannot be renamed.
    if self:isControlled() then
        return false
    end
    self:setPropBase("name", name)
    return true
end



---If another sibling of this Node has the same name, this function will change the name of this Node by adding a suffix of the form `#2`, `#3`, `#4`, etc.
---Otherwise, this Node's name will remain unchanged.
function Node:ensureUniqueName()
    if not self.parent then
        return
    end
    local prop = self.properties:getValues()
    -- Check if any other Node with this name exists.
    local found = false
    for i, child in ipairs(self.parent.children) do
        if child ~= self and child.name == prop.name then
            -- We've found a sibling that has the same name as us!
            found = true
            break
        end
    end
    -- If this Node's name is unique, we don't need to do anything.
    if not found then
        return
    end
    local nameBase = prop.name
    local suffixNumber = 2
    -- Check if we've got a suffix already.
    local split = _Utils.strSplit(prop.name, "#")
    if #split > 1 then
        local n = tonumber(split[#split])
        if n then
            -- We've got a proper suffix.
            split[#split] = nil
            nameBase = table.concat(split, "#")
            suffixNumber = n + 1
        end
    end
    -- Now, try our new name and increment each time we find a sibling.
    local newName
    repeat
        newName = nameBase .. "#" .. tostring(suffixNumber)
        suffixNumber = suffixNumber + 1
    until not self.parent:findChildByName(newName)
    -- When we finally find it, set it as our new name.
    prop.name = newName
end



---Returns the local position of this Node, which is relative to its parent's position.
---@return Vector2
function Node:getPos()
    return self:getProp("pos")
end



---Sets the local position of this Node, which is relative to its parent's position.
---@param pos Vector2 The new local position to be set.
function Node:setPos(pos)
    self:setPropBase("pos", pos)
end



---Returns the global position of this Node, i.e. the actual position (top left corner) after factoring in all parents' modifiers.
---@return Vector2
function Node:getGlobalPos()
    local prop = self.properties:getValues()
    return prop.pos - ((self:getSize() - 1) * prop.align):ceil() + self:getParentAlignPos()
end



---Returns the global position of this Node, which has not been adjusted for the local widget alignment.
---@return Vector2
function Node:getGlobalPosWithoutLocalAlign()
    return self:getProp("pos") + self:getParentAlignPos()
end



---Returns the Node's parent anchor. If the Node does not have a parent, this function will return `(0, 0)`.
---@return Vector2
function Node:getParentAlignPos()
    if self.parent then
        return self.parent:getGlobalPos() + ((self.parent:getSize() - 1) * self:getProp("parentAlign")):ceil()
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



---Sets the size of this Node's widget. Not all widgets support resizing. Check `:isResizable()` to see if you can.
---@param size Vector2 The new size of this Node's widget.
function Node:setSize(size)
    if self.widget then
        self.widget:setSize(size)
    end
end



---Returns whether this Node's widget is resizable. If so, squares will appear around it when selected.
---@return boolean
function Node:isResizable()
    if self.widget then
        return self:hasProperty("size")
    end
    return false
end



---Returns the position of the resize handle for this Node's widget.
---@param id integer 1 to 8: top left, top middle, top right, middle left, middle right, bottom left, bottom middle, and you guessed it - bottom right.
---@return Vector2
function Node:getResizeHandlePos(id)
    local pos = self:getGlobalPos()
    local size = self:getSize()
    if id == 1 then
        return Vec2(pos.x - 4, pos.y - 4)
    elseif id == 2 then
        return Vec2(pos.x + size.x / 2 - 1, pos.y - 4)
    elseif id == 3 then
        return Vec2(pos.x + size.x + 1, pos.y - 4)
    elseif id == 4 then
        return Vec2(pos.x - 4, pos.y + size.y / 2 - 1)
    elseif id == 5 then
        return Vec2(pos.x + size.x + 1, pos.y + size.y / 2 - 1)
    elseif id == 6 then
        return Vec2(pos.x - 4, pos.y + size.y + 1)
    elseif id == 7 then
        return Vec2(pos.x + size.x / 2 - 1, pos.y + size.y + 1)
    elseif id == 8 then
        return Vec2(pos.x + size.x + 1, pos.y + size.y + 1)
    end
    error(string.format("Invalid resize handle ID: %s (expected 1..8)", id))
end



---Returns whether the canvas input mode is enabled on this Node or its hierarchy.
---@return boolean
function Node:isCanvasInputModeEnabled()
    if self.parent then
        return self.parent:isCanvasInputModeEnabled()
    end
    return self:getProp("canvasInputMode")
end



---Returns the current alignment of the Node.
---@return Vector2
function Node:getAlign()
    return self:getProp("align")
end



---Sets the alignment of this Node.
---@param align Vector2 The new Node alignment.
--- - `(0, 0)` aligns to top left.
--- - `(1, 1)` aligns to bottom right.
--- - `(0.5, 0.5)` aligns to the center.
--- - Any combination is available, including going out of bounds.
function Node:setAlign(align)
    self:setPropBase("align", align)
end



---Returns the current parental alignment of the Node.
---@return Vector2
function Node:getParentAlign()
    return self:getProp("parentAlign")
end



---Sets the parental alignment of this Node.
---@param parentAlign Vector2 The new Node alignment.
--- - `(0, 0)` aligns to top left.
--- - `(1, 1)` aligns to bottom right.
--- - `(0.5, 0.5)` aligns to the center.
--- - Any combination is available, including going out of bounds.
function Node:setParentAlign(parentAlign)
    self:setPropBase("parentAlign", parentAlign)
end



---Sets an on-click function (or resets it, if no argument is provided).
---@param f function? The function to be executed if this Node is clicked.
function Node:setOnClick(f)
    self.onClick = f
end



---Fires the callback specified in the `onClick` and `signalOnClick` fields if these fields have been defined.
---If `onClick` is defined, it will be executed without any parameters.
---If `signalOnClick` is defined, it will send a signal, for now hardcoded to the `_OnSignal(signalOnClick)` call.
function Node:click()
    if self.onClick then
        self.onClick()
    end
    if self:getProp("signalOnClick") then
        _OnSignal(self:getProp("signalOnClick"))
    end
end



---Returns the list of properties on this Node. This list is always the same.
---This function does NOT return properties belonging to its Widget. For that, call `node.widget:getPropertyList()`.
---Make sure to wrap this call as the node or the function might not exist!
---@return table
function Node:getPropertyList()
    return self.PROPERTY_LIST
end



---Returns `true` if this Node has a widget and that widget has a property of the given key.
---@param key string The key to search for.
---@return boolean
function Node:hasProperty(key)
    if not self.widget or not self.widget.getPropertyList then
        return false
    end
    local properties = self.widget:getPropertyList()
    for i, property in ipairs(properties) do
        if property.key == key then
            return true
        end
    end
    return false
end



---Returns whether this Node is hovered.
function Node:isHovered()
    return self:hasPixel(self:isCanvasInputModeEnabled() and _MouseCPos or _MousePos)
end



---Returns the ID of the hovered resize handle of this Node's widget, if any is hovered.
---If none of the resize handles are hovered, returns `nil`.
---@return integer?
function Node:getHoveredResizeHandleID()
    if not self:isResizable() then
        return nil
    end
    for i = 1, 8 do
        local pos = self:getResizeHandlePos(i)
        if _Utils.isPointInsideBox(self:isCanvasInputModeEnabled() and _MouseCPos or _MousePos, pos, Vec2(3)) then
            return i
        end
    end
    return nil
end



---Returns whether this Node or any of the Nodes up the tree is disabled.
---
---Disabled Nodes can still be hovered, but their `onClick` callbacks will not fire if the mouse button or a keyboard shortcut has been pressed.
---They can have their own graphics used in Widgets.
---@return boolean
function Node:isDisabled()
    if self.parent then
        return self.parent:isDisabled() or self.disabled
    end
    return self.disabled
end



---Sets whether this Node should be disabled.
---@param disabled boolean Whether this Node should be disabled.
function Node:setDisabled(disabled)
    self.disabled = disabled
end



---Returns whether this Node is visible, i.e. all of the Nodes in this Node's hierarchy have the visible flag set.
---@return boolean
function Node:isVisible()
    if self.parent then
        return self.parent:isVisible() and self:getProp("visible")
    end
    return self:getProp("visible")
end



---Sets whether this Node (and all its children!) should be visible.
---@param visible boolean Whether this Node should be visible. If a Node is not visible, it cannot be seen, including all its children.
function Node:setVisible(visible)
    self:setPropBase("visible", visible)
end



---Returns any Text this Node's widget contains. Works only with `text` widgets. Returns `nil` otherwise.
---@return string?
function Node:getText()
    if self.type == "text" then
        return self.widget:getProp("text")
    end
end



---Sets the given text on this Node's widget. Works only with `text` widgets.
---@param text string The text to be set on this Node's widget.
function Node:setText(text)
    assert(type(text) == "string", string.format("Cannot set the text to a non-string: %s!", text))
    if self.type == "text" then
        self.widget:setProp("text", text)
    end
end



---Returns any color this Node's widget contains. Works only with `text` and `box` widgets. Returns `nil` otherwise.
---@return Color?
function Node:getColor()
    if self.type == "text" or self.type == "box" then
        return self.widget:getProp("color")
    end
end



---Sets the given color on this Node's widget. Works only with `text` and `box` widgets.
---@param color Color The color to be set on this Node's widget.
function Node:setColor(color)
    if self.type == "text" or self.type == "box" then
        self.widget:setProp("color", color)
    end
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



---Returns whether this Node is controlled.
---By a Controlled Node we mean a Node of which at least one of their parents up the hierarchy is a Controller Node.
---Controlled Nodes are limited: you cannot change their name, add children to them or move them outside of their current position in hierarchy.
---These limits are not enforced by this class; instead, the Editor should provide sufficient safeguards so that this does not happen.
---Renaming or changing the hierarchy of controlled Nodes will have unexpected consequences... mostly. You can expect that the program will crash!
---@return boolean
function Node:isControlled()
    if not self.parent then
        return false
    end
    if self.parent and self.parent.isController then
        return true
    end
    return self.parent:isControlled()
end



---Inserts the provided Node as a child of this Node.
---If the provided Node is already integrated into another UI tree (has a parent), it is removed from that parent - the Node is effectively moved.
---Returns `true` on success, `false` if the tree would form a cycle or when the widget would be parented to itself.
---@param node Node The node to be added.
---@param index number? The index specifying where in the hierarchy the Node should be located. By default, it is inserted as the last element (on the bottom).
---@return boolean
function Node:addChild(node, index)
    -- We cannot parent a node to itself or its own child, or else we will get stuck in a loop!!!
    if node == self or node:findChild(self) then
        return false
    end
    -- Controller Nodes cannot have their structure changed. And we must not accept any Controlled Node that's trying to run away from their controller, either.
    if self:isControlled() or self.isController or node:isControlled() then
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
    -- Controlled Nodes cannot be removed.
    if node:isControlled() then
        return false
    end
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
    -- Controlled Nodes cannot be moved in their hierarchy.
    if node:isControlled() then
        return false
    end
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
    -- Controlled Nodes cannot be moved in their hierarchy.
    if node:isControlled() then
        return false
    end
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
    -- Controlled Nodes cannot be moved in their hierarchy.
    if node:isControlled() then
        return false
    end
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



---Returns `true` if this Node has at least one child.
---@return boolean
function Node:hasChildren()
    return #self.children > 0
end



---Returns the first encountered child by reference (recursively), or `nil` if it is not found.
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



---Returns the first encountered child of the provided name (recursively), or `nil` if it is not found.
---@param name string The name of the child to be found.
---@return Node?
function Node:findChildByName(name)
    for i, child in ipairs(self.children) do
        if child:getProp("name") == name then
            return child
        end
        local potentialResult = child:findChildByName(name)
        if potentialResult then
            return potentialResult
        end
    end
end



---Returns the first encountered child that contains the provided position (recursively), or `nil` if it is not found.
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



---Returns the first encountered child that contains the provided position (recursively, depth first), or `nil` if it is not found.
---@param pos Vector2 The position to be checked.
---@param ignoreControlledNodes boolean? If set, controlled nodes will not be returned by this function.
---@param ignoreInvisibleNodes boolean? If set, invisible nodes will not be returned by this function.
---@return Node?
function Node:findChildByPixelDepthFirst(pos, ignoreControlledNodes, ignoreInvisibleNodes)
    for i, child in ipairs(self.children) do
        local potentialResult = child:findChildByPixelDepthFirst(pos, ignoreControlledNodes, ignoreInvisibleNodes)
        if potentialResult then
            return potentialResult
        end
        if child:hasPixel(pos) and (not ignoreControlledNodes or not child:isControlled()) and (not ignoreInvisibleNodes or child:isVisible()) then
            if ignoreInvisibleNodes then
                print(child:getName(), child:isVisible())
            end
            return child
        end
    end
end



---Returns the last encountered child that contains the provided position (recursively, depth first), or `nil` if it is not found.
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
    self.properties:update(dt)
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
---If the Node is invisible, the call immediately returns, resulting in neither this nor any children's widgets being drawn.
function Node:draw()
    if not self:getProp("visible") then
        return
    end
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
    -- Draw resizing boxes if the widget can be resized.
    if self:isResizable() then
        local id = self:getHoveredResizeHandleID()
        for i = 1, 8 do
            if i == id then
                -- This handle is hovered.
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.setColor(0, 1, 1)
            end
            local p = self:getResizeHandlePos(i)
            love.graphics.rectangle("fill", p.x, p.y, 3, 3)
        end
    end
end



---Internal function which draws a crosshair.
---@param pos Vector2 The crosshair position.
---@param size number The crosshair size, in pixels.
function Node:drawCrosshair(pos, size)
    pos = pos:floor() + 0.5
    love.graphics.line(pos.x - size, pos.y, pos.x + size + 1, pos.y)
    love.graphics.line(pos.x, pos.y - size, pos.x, pos.y + size + 1)
end



---Executed whenever a mouse button is pressed anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
---@param istouch boolean Whether the press is coming from a touch input.
---@param presses integer How many clicks have been performed in a short amount of time. Useful for double click checks.
function Node:mousepressed(x, y, button, istouch, presses)
    if button == 1 and self:isHovered() and not self.disabled then
        self.clicked = true
    end
    for i, child in ipairs(self.children) do
        child:mousepressed(x, y, button, istouch, presses)
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
            self:click()
        end
    end
    for i, child in ipairs(self.children) do
        child:mousereleased(x, y, button)
    end
end



---Executed whenever a key is pressed on the keyboard.
---@param key string Code of the key that has been pressed.
function Node:keypressed(key)
    local shortcut = self:getProp("shortcut")
    if shortcut and shortcut.key == key and (shortcut.ctrl or false) == _IsCtrlPressed() and (shortcut.shift or false) == _IsShiftPressed() then
        self:click()
    end
    for i, child in ipairs(self.children) do
        child:keypressed(key)
    end
end



---Returns Node's data to be used for loading later.
---@return table
function Node:serialize()
    local data = self.properties:serialize()

    data.type = self.type ~= "none" and self.type or nil
    data.widget = self.widget and self.widget:serialize()

    if #self.children > 0 then
        data.children = {}
        for i, child in ipairs(self.children) do
            data.children[i] = child:serialize()
        end
    end

    return data
end



---Loads Node data to this Node from a previously serialized table.
---@param data table The data to be loaded.
function Node:deserialize(data)
    self.properties:deserialize(data)

    self.type = data.type or "none"
    local widgetData = WIDGET_TYPES[self.type]
    if self.properties:getBaseValue("name") == "ERROR" then
        self.properties:setBaseValue("name", widgetData.defaultName)
    end

    if data.children then
    	for i, child in ipairs(data.children) do
	    	table.insert(self.children, Node(child, self))
	    end
    end

    if self.type == "button" or self.type == "input_text" then
        self.isController = true
    end
    if self.type == "canvas" then
        -- Not supported. Canvases have a few problems:
        -- - Debug drawing
        -- - Drawing stuff other than UI on such canvas would be a problem
        self.isCanvas = true
    end

    if widgetData.constructor then
        local success, result = pcall(function() return widgetData.constructor(self, data.widget) end)
        assert(success, string.format("Node \"%s\": Could not make widget of type \"%s\": %s", self.properties:getBaseValue("name"), self.type, result))
        self.widget = result
    end
end



return Node