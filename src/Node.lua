local class = require "com.class"

---@class Node
---@overload fun(data, parent):Node
local Node = class:derive("Node")

local Vec2 = require("src.Essentials.Vector2")
local PropertyList = require("src.PropertyList")
local NodeList = require("src.NodeList")

local Box = require("src.Widgets.Box")
local Button = require("src.Widgets.Button")
local Canvas = require("src.Widgets.Canvas")
local GridBackground = require("src.Widgets.GridBackground")
local InputText = require("src.Widgets.InputText")
local NineSprite = require("src.Widgets.NineSprite")
local Sprite = require("src.Widgets.Sprite")
local Text = require("src.Widgets.Text")
local TitleDigit = require("src.Widgets.TitleDigit")



---Creates a new UI Node.
---@param data table The node data.
---@param parent Node? The parent node. Warning! This does NOT add this Node to its parent! You need to call `:addChild()` on the parent for that.
function Node:new(data, parent)
    self.parent = parent

    self.WIDGET_TYPES = {
        none =                  {constructor = nil,             defaultName = "Node",           icon = "widget_none"},
        box =                   {constructor = Box,             defaultName = "Box",            icon = "widget_box"},
        button =                {constructor = Button,          defaultName = "Button",         icon = "widget_button"},
        canvas =                {constructor = Canvas,          defaultName = "Canvas",         icon = "widget_canvas"},
        input_text =            {constructor = InputText,       defaultName = "InputText",      icon = "widget_none"},
        ["9sprite"] =           {constructor = NineSprite,      defaultName = "NineSprite",     icon = "widget_ninesprite"},
        sprite =                {constructor = Sprite,          defaultName = "Sprite",         icon = "widget_sprite"},
        text =                  {constructor = Text,            defaultName = "Text",           icon = "widget_text"},
        ["@titleDigit"] =       {constructor = TitleDigit,      defaultName = "TitleDigit",     icon = "widget_titledigit"},
        ["@gridBackground"] =   {constructor = GridBackground,  defaultName = "GridBackground", icon = "widget_titledigit"}
    }
    self.type = "none"

    self.PROPERTY_LIST = {
        {name = "Name", key = "name", type = "string", defaultValue = "ERROR", disabledIfControlled = true},
        {name = "Position", key = "pos", type = "Vector2", defaultValue = Vec2()},
        {name = "Align", key = "align", type = "align", defaultValue = _ALIGNMENTS.topLeft},
        {name = "Parent Align", key = "parentAlign", type = "align", defaultValue = _ALIGNMENTS.topLeft},
        {name = "Visible", key = "visible", type = "boolean", defaultValue = true},
        {name = "Locked", key = "locked", type = "boolean", defaultValue = false},
        {name = "Tooltip", key = "tooltip", type = "string", nullable = true, description = "An optional tooltip which will be shown under the cursor when this Node is hovered.\nThis tooltip is visible only in the editor!"},
        {name = "Shortcut", key = "shortcut", type = "shortcut", nullable = true},
        {name = "Signal On Click", key = "signalOnClick", type = "string", nullable = true},
        {name = "Collapsed", key = "collapsed", type = "boolean", defaultValue = false, hidden = true},
        {name = "Canvas Input Mode", key = "canvasInputMode", type = "boolean", defaultValue = false, hidden = true}
    }
    self.properties = PropertyList(self.PROPERTY_LIST)

    self.dragPos = nil
    self.scaleSize = nil

    self.clicked = false
    self.onClick = nil
    self.disabled = false

    self.children = {}
    self.deleteIndex = nil

    self:deserialize(data)
end


--################################################--
---------------- P R O P E R T I E S ---------------
--################################################--

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

---Returns the given property of this Node's Widget.
---@param key string The property key.
---@return any?
function Node:getWidgetProp(key)
    return self.widget:getProp(key)
end

---Sets the given property of this Node's Widget to a given value.
---@param key string The property key.
---@param value any? The property value.
function Node:setWidgetProp(key, value)
    self.widget:setProp(key, value)
end

---Returns the given property base of this Node's Widget.
---@param key string The property key.
---@return any?
function Node:getWidgetPropBase(key)
    return self.widget:getPropBase(key)
end

---Sets the given property base of this Node's Widget to a given value.
---@param key string The property key.
---@param value any? The property value.
function Node:setWidgetPropBase(key, value)
    self.widget:setPropBase(key, value)
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
    -- Cannot rename a Node to the exact same name it had.
    if self:getProp("name") == name then
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
    until not self.parent:getChild(newName)
    -- When we finally find it, set it as our new name.
    prop.name = newName
end



---Returns the local position of this Node, which is relative to its parent's position.
---This position includes potential dragging position, if the Node is currently dragged.
---@return Vector2
function Node:getPos()
    return self.dragPos or self:getProp("pos")
end



---Sets the local position of this Node, which is relative to its parent's position.
---@param pos Vector2 The new local position to be set.
function Node:setPos(pos)
    self:setPropBase("pos", pos)
end



---Returns the global position of this Node, i.e. the actual position (top left corner) after factoring in all parents' modifiers.
---@return Vector2
function Node:getGlobalPos()
    return self:getPos() - ((self:getSize() - 1) * self:getProp("align")):ceil() + self:getParentAlignPos()
end



---Returns the global position of this Node, which has not been adjusted for the local widget alignment.
---@return Vector2
function Node:getGlobalPosWithoutLocalAlign()
    return self:getPos() + self:getParentAlignPos()
end



---Returns the Node's parent anchor. If the Node does not have a parent, this function will return `(0, 0)`.
---@return Vector2
function Node:getParentAlignPos()
    if self.parent then
        return self.parent:getGlobalPos() + ((self.parent:getSize() - 1) * self:getProp("parentAlign")):ceil()
    end
    return Vec2()
end



---Drags this Node to the given position. If not currently dragged, this Node will be automatically marked as being dragged.
---@param pos Vector2 The position this Node should be dragged to.
function Node:dragTo(pos)
    self.dragPos = pos
end

---Finishes the dragging process for this Node, by setting its actual position to the drag position.
---The drag position is cleared.
function Node:finishDrag()
    self:setPos(self:getPos())
    self.dragPos = nil
end

---Cancels the dragging process for this Node, by clearing the drag position.
function Node:cancelDrag()
    self.dragPos = nil
end

---Returns `true` if this Node is being currently dragged, `false` otherwise.
---@return boolean
function Node:isBeingDragged()
    return self.dragPos ~= nil
end



---Returns the size of this Node's widget, or `(1, 1)` if it contains no widget.
---@return Vector2
function Node:getSize()
    if self.widget then
        return self.scaleSize or self.widget:getSize()
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



---Resizes this Node to the given size and repositions (drags) it accordingly to the resize anchor.
---If not currently resized, this Node will be automatically marked as being resized.
---Returns `true` on success.
---@param size Vector2 The position this Node should be resized to.
---@return boolean
function Node:resizeTo(size, anchor)
    if not self:isResizable() then
        return false
    end
    -- Texts which did not have the `size` property will use the `:getFinalTextSize()` function, which calculates the text size.
    local oldSize = self.widget:getProp("size") or self.widget:getFinalTextSize()
    self.dragPos = self:getProp("pos") + (size - oldSize) * (anchor + self:getAlign())
    self.scaleSize = size
    return true
end

---Finishes the resize process for this Node, by setting its actual size to the set size. This also commits the drag position.
---The scale size is cleared.
function Node:finishResize()
    if not self.scaleSize then
        return
    end
    self:setPos(self:getPos())
    self:setSize(self:getSize())
    self.dragPos = nil
    self.scaleSize = nil
end

---Cancels the resize process for this Node, by clearing the drag position.
function Node:cancelResize()
    self.dragPos = nil
    self.scaleSize = nil
end

---Returns `true` if this Node is being currently resized, `false` otherwise.
---@return boolean
function Node:isBeingResized()
    return self.scaleSize ~= nil
end



---Returns whether this Node's widget is resizable. If so, squares will appear around it when selected.
---@return boolean
function Node:isResizable()
    if self.widget then
        return self:hasProperty("size")
    end
    return false
end



---Returns this Node's icon based on its Widget's type, for use in editors.
---@return Image
function Node:getIcon()
    return _RESOURCE_MANAGER:getImage(self.WIDGET_TYPES[self.type].icon)
end



---Returns whether the canvas input mode is enabled on this Node or its hierarchy.
---@return boolean
function Node:isCanvasInputModeEnabled()
    if self.parent then
        return self.parent:isCanvasInputModeEnabled()
    end
    return self:getProp("canvasInputMode")
end



---Returns whether this node is a root node (has no parent).
---@return boolean
function Node:isRoot()
    return self.parent == nil
end



---Returns a tooltip for this Node, if set.
---@return string?
function Node:getTooltip()
    return self:getProp("tooltip")
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



---Returns `true` if the given pixel position is inside of this Node's bounding box.
---@param pos Vector2 The position to be checked.
---@return boolean
function Node:hasPixel(pos)
    return _Utils.isPointInsideBox(pos, self:getGlobalPos(), self:getSize())
end

---Returns `true` if this Node is fully contained inside of the provided box.
---@param x number X position of the top left corner of the box.
---@param y number Y position of the top left corner of the box.
---@param w number Width of the box.
---@param h number Height of the box.
---@return boolean
function Node:isInsideBox(x, y, w, h)
    local pos = self:getGlobalPos()
    local size = self:getSize()
    return _Utils.areBoxesContained(pos.x, pos.y, size.x, size.y, x, y, w, h)
end

---Returns whether this Node is hovered.
---Controlled, invisible or locked Nodes cannot be hovered, unless their corresponding bypasses are turned on.
---@param bypassControlled boolean? If set, controlled nodes can still be hovered.
---@param bypassInvisible boolean? If set, invisible nodes can still be hovered.
---@param bypassLocked boolean? If set, locked nodes can still be hovered.
---@return boolean
function Node:isHovered(bypassControlled, bypassInvisible, bypassLocked)
    if self:isControlled() and not bypassControlled then
        return false
    end
    if not self:isVisible() and not bypassInvisible then
        return false
    end
    if self:isLocked() and not bypassLocked then
        return false
    end
    return self:hasPixel(self:isCanvasInputModeEnabled() and _MouseCPos or _MousePos)
end

---Returns whether any of this Node's children are hovered.
---@param bypassControlled boolean? If set, controlled nodes can still be hovered.
---@param bypassInvisible boolean? If set, invisible nodes can still be hovered.
---@param bypassLocked boolean? If set, locked nodes can still be hovered.
---@return boolean
function Node:isChildHovered(bypassControlled, bypassInvisible, bypassLocked)
    for i, child in ipairs(self.children) do
        if child:isHoveredWithChildren(bypassControlled, bypassInvisible, bypassLocked) then
            return true
        end
    end
    return false
end

---Returns whether this Node or any of its children is hovered.
---@param bypassControlled boolean? If set, controlled nodes can still be hovered.
---@param bypassInvisible boolean? If set, invisible nodes can still be hovered.
---@param bypassLocked boolean? If set, locked nodes can still be hovered.
---@return boolean
function Node:isHoveredWithChildren(bypassControlled, bypassInvisible, bypassLocked)
    return self:isHovered(bypassControlled, bypassInvisible, bypassLocked) or self:isChildHovered(bypassControlled, bypassInvisible, bypassLocked)
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

---Returns whether this Node is collapsed.
---@return boolean
function Node:isCollapsed()
    return self:getProp("collapsed")
end

---Sets whether this Node should be collapsed. Collapsed nodes do not have their children visible in the UI tree.
---@param collapsed boolean Whether this Node should be collapsed.
function Node:setCollapsed(collapsed)
    self:setPropBase("collapsed", collapsed)
end

---Sets whether this Node is collapsed: collapses it if it was not and vice versa.
function Node:toggleCollapse()
    self:setPropBase("collapsed", not self:getProp("collapsed"))
end

---Returns whether this Node is visible in the UI tree.
---This only returns `false` if any parent up its hierarchy is currently collapsed.
---@return boolean
function Node:isVisibleInUITree()
    if self.parent then
        return self.parent:isVisibleInUITree() and not self.parent:isCollapsed()
    end
    return true
end

---Returns whether this Node is locked. Locked nodes cannot be hovered.
---@return boolean
function Node:isLocked()
    return self:getProp("locked")
end

---Sets whether this Node is locked. Locked nodes cannot be hovered, but their children can.
---@param locked boolean Whether this Node should be locked.
function Node:setLocked(locked)
    self:setPropBase("locked", locked)
end



---Throws an error if the widget on this Node is not a Text Widget.
---@private
function Node:ensureTextNode()
    assert(self.type == "text", string.format("Cannot get or set text information on a non-text Widget: %s!", self:getName()))
end

---Returns any Text this Node's widget contains. Works only with `text` widgets.
---@return string
function Node:getText()
    self:ensureTextNode()
    return self.widget:getProp("text")
end

---Sets the given text on this Node's widget. Works only with `text` widgets.
---@param text string The text to be set on this Node's widget.
function Node:setText(text)
    assert(type(text) == "string", string.format("Cannot set the text to a non-string: %s!", text))
    self:ensureTextNode()
    self.widget:setPropBase("text", text)
end

---Returns whether this Node's text widget is formatted. Works only with `text` widgets.
function Node:getTextFormatted()
    self:ensureTextNode()
    return self.widget:getProp("formatted")
end

---Sets whether this Node's text widget is formatted. Works only with `text` widgets.
---@param formatted boolean Whether this Node's widget should be formatted.
function Node:setTextFormatted(formatted)
    self:ensureTextNode()
    self.widget:setPropBase("formatted", formatted)
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
    if node:isNodeInTree(self) then
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
---If this Node has no parent or is already at the top, this function will fail and return `false`. If the operation succeeds, returns `true`.
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
---If this Node has no parent or is already at the bottom, this function will fail and return `false`. If the operation succeeds, returns `true`.
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



---Returns `true` if this Node has at least one child.
---@return boolean
function Node:hasChildren()
    return #self.children > 0
end



--################################################################--
---------------- C H I L D R E N   O B T A I N I N G ---------------
--################################################################--

---Returns `true` if the provided Node is a child of this Node, at any depth, including self.
---@param node Node The node to be found.
---@return boolean
function Node:isNodeInTree(node)
    if node == self then
        return true
    end
    for i, child in ipairs(self.children) do
        if child:isNodeInTree(node) then
            return true
        end
    end
    return false
end

---Returns the first encountered child (or self) of the provided name (recursively), or `nil` if it is not found.
---@param name string The name of the child to be found.
---@return Node?
function Node:getChild(name)
    if self:getProp("name") == name then
        return self
    end
    for i, child in ipairs(self.children) do
        local potentialResult = child:getChild(name)
        if potentialResult then
            return potentialResult
        end
    end
end

---Returns the first encountered child (or self) that is hovered (recursively), or `nil` if it is not found.
---@param depthFirst boolean? If set, the nodes will be looked at depth-first, otherwise breadth-first.
---@param bypassControlled boolean? If set, controlled nodes can still be hovered (and returned by this function).
---@param bypassInvisible boolean? If set, invisible nodes can still be hovered (and returned by this function).
---@param bypassLocked boolean? If set, locked nodes can still be hovered (and returned by this function).
---@return Node?
function Node:getHoveredNode(depthFirst, bypassControlled, bypassInvisible, bypassLocked)
    if not depthFirst and self:isHovered(bypassControlled, bypassInvisible, bypassLocked) then
        return self
    end
    for i, child in ipairs(self.children) do
        local potentialResult = child:getHoveredNode(depthFirst, bypassControlled, bypassInvisible, bypassLocked)
        if potentialResult then
            return potentialResult
        end
    end
    if depthFirst and self:isHovered(bypassControlled, bypassInvisible, bypassLocked) then
        return self
    end
end

---Returns a list of all this Node and all its children, at any depth.
---@param list NodeList? If provided, all Nodes will be added to this Node List. Otherwise, a new Node List will be created.
---@return NodeList
function Node:getNodeList(list)
    list = list or NodeList()
    list:addNode(self)
    for i, child in ipairs(self.children) do
        child:getNodeList(list)
    end
    return list
end

---Returns a list of all Nodes (both self and children) which are contained within the provided box.
---@param x number X position of the top left corner of the box.
---@param y number Y position of the top left corner of the box.
---@param w number Width of the box.
---@param h number Height of the box.
---@param list NodeList? If provided, all Nodes will be added to this Node List. Otherwise, a new Node List will be created.
---@return NodeList
function Node:getBoxedNodeList(x, y, w, h, list)
    list = list or NodeList()
    if self:isInsideBox(x, y, w, h) then
        list:addNode(self)
    end
    for i, child in ipairs(self.children) do
        child:getBoxedNodeList(x, y, w, h, list)
    end
    return list
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



---Executed whenever a mouse button is pressed anywhere on the screen.
---Returns `true` if the input is consumed by at least one child Node or its Widget.
---The input consumption is not greedy; this node and all its children are guaranteed to get the `mousepressed` callback as long as they are not disabled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
---@param istouch boolean Whether the press is coming from a touch input.
---@param presses integer How many clicks have been performed in a short amount of time. Useful for double click checks.
---@return boolean
function Node:mousepressed(x, y, button, istouch, presses)
    if not self:isVisible() or self.disabled then
        return false
    end
    local consumed = false
    if button == 1 and self:isHovered() then
        self.clicked = true
    end
    if self.widget and self.widget.mousepressed then
        if self.widget:mousepressed(x, y, button, istouch, presses) then
            consumed = true
        end
    end
    for i, child in ipairs(self.children) do
        if child:mousepressed(x, y, button, istouch, presses) then
            consumed = true
        end
    end
    return consumed
end



---Executed whenever a mouse button is released anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function Node:mousereleased(x, y, button)
    if not self:isVisible() or self.disabled then
        return
    end
    if button == 1 and self.clicked then
        self.clicked = false
        -- We don't want the click function to occur if the cursor was released outside of the node.
        if self:isHovered() then
            self:click()
        end
        if self.widget and self.widget.mousereleased then
            self.widget:mousereleased(x, y, button)
        end
    end
    for i, child in ipairs(self.children) do
        child:mousereleased(x, y, button)
    end
end



---Executed whenever a mouse wheel has been scrolled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function Node:wheelmoved(x, y)
    if not self:isVisible() or self.disabled then
        return
    end
    if self:isHovered() then
        if self.widget and self.widget.wheelmoved then
            self.widget:wheelmoved(x, y)
        end
    end
    for i, child in ipairs(self.children) do
        child:wheelmoved(x, y)
    end
end



---Executed whenever a key is pressed on the keyboard.
---@param key string Code of the key that has been pressed.
function Node:keypressed(key)
    if not self:isVisible() or self.disabled then
        return
    end
    local shortcut = self:getProp("shortcut")
    if shortcut and shortcut.key == key and (shortcut.ctrl or false) == _IsCtrlPressed() and (shortcut.shift or false) == _IsShiftPressed() then
        self:click()
    end
    if self.widget and self.widget.keypressed then
        self.widget:keypressed(key)
    end
    for i, child in ipairs(self.children) do
        child:keypressed(key)
    end
end



---Executed whenever a certain character has been typed on the keyboard.
---@param text string The character.
function Node:textinput(text)
    if not self:isVisible() or self.disabled then
        return
    end
    if self.widget and self.widget.textinput then
        self.widget:textinput(text)
    end
    for i, child in ipairs(self.children) do
        child:textinput(text)
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
    local widgetData = self.WIDGET_TYPES[self.type]
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