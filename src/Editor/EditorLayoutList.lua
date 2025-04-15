local class = require "com.class"

---@class EditorLayoutList
---@overload fun(editor):EditorLayoutList
local EditorLayoutList = class:derive("EditorLayoutList")

-- Place your imports here
local utf8 = require("utf8")
local Vec2 = require("src.Essentials.Vector2")

---Constructs a new Editor Layout List.
---@param editor Editor The UI editor this layout list belongs to.
function EditorLayoutList:new(editor)
    self.editor = editor

    self.POS = Vec2(5, 70)
    self.SIZE = Vec2(220, 200)
    self.ITEM_HEIGHT = 20
    self.ITEM_INDENT = 20
    self.ITEM_MARGIN = 5

    self.items = {}
    self.showInternalUI = false

    self.scrollOffset = 0
    self.maxScrollOffset = 0
    self.hoverTop = false
    self.hoverBottom = false
    self.dragOrigin = nil
    self.dragSnap = false

    -- Stores the layout that if clicked the second time will actually be name edited.
    -- This is because you could click elsewhere the second time and still activate that layout's input box,
    -- even if that particular layout was clicked just once.
    self.nameEditLastClickedNode = nil
    self.nameEditLayout = nil
    self.nameEditValue = nil
end



---Returns UI tree information.
---This function should only be called internally. If you want to get the current UI tree info, fetch the `self.items` field instead.
---@param node Node? The UI node of which the tree should be added to the list.
---@param tab table? The table, used internally.
---@param indent integer? The starting indentation.
---@param ignoreCollapses boolean? If set to `true`, the result will contain nodes that should be invisible in the UI tree. This is required by `NodeList:sortByTreeOrder()` and at some point will be removed.
---@return table tab This is a one-dimensional table of entries in the form `{node = Node, indent = number}`.
function EditorLayoutList:getUITreeInfo(node, tab, indent, ignoreCollapses)
    node = node or _PROJECT:getCurrentLayoutUI()
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
function EditorLayoutList:getItemY(n)
    return self.ITEM_HEIGHT * (n - 1) - self.scrollOffset
end



---Returns `true` if the mouse cursor is inside of the Editor UI Tree area, `false` otherwise.
---@return boolean
function EditorLayoutList:isHovered()
    return _Utils.isPointInsideBox(_MousePos, self.POS, self.SIZE)
end



---Returns the index of the hovered item in the list.
---If none of the items are hovered, returns `nil`.
---Additionally, this function updates the `self.hoverTop` and `self.hoverBottom` fields.
---@return integer?
function EditorLayoutList:getHoveredItemID()
    if not self:isHovered() then
        return nil
    end
    self.hoverTop = false
    self.hoverBottom = false
    for i, entry in ipairs(self.items) do
        local y = self:getItemY(i)
        if _Utils.isPointInsideBox(_MousePos, self.POS + Vec2(0, y), Vec2(self.SIZE.x, self.ITEM_HEIGHT)) then
            self.editor.isNodeHoverIndirect = true
            -- Additional checks for specific parts of the entry. Used for node dragging so that you can drag in between the entries.
            if _Utils.isPointInsideBox(_MousePos, self.POS + Vec2(0, y), Vec2(self.SIZE.x, self.ITEM_MARGIN)) then
                self.hoverTop = true
            elseif _Utils.isPointInsideBox(_MousePos, self.POS + Vec2(0, y + self.ITEM_HEIGHT - self.ITEM_MARGIN), Vec2(self.SIZE.x, self.ITEM_MARGIN)) then
                self.hoverBottom = true
            end
            return i
        end
    end
end



---Selects the n-th listed layout and loads its corresponding UI, resets the name edit mode and changes the potential name edit node.
---@param index integer? The ID of the layout in the list to be loaded.
function EditorLayoutList:clickItem(index)
    if self.nameEditLayout then
        self.nameEditLayout = nil
        self.nameEditValue = nil
    end
    self.nameEditLastClickedNode = index
    if index then
        local layout = self.items[index].layout
        _PROJECT:openLayout(layout:getName())
    end
end



---Starts the name edit mode for the provided Layout.
---@param layout ProjectLayout The Layout for which the name edit box should show up.
function EditorLayoutList:startNameEdit(layout)
    self.nameEditLayout = layout
    self.nameEditValue = layout:getName()
end

---Ends the name edit mode with saving the new node name.
function EditorLayoutList:submitNameEdit()
    if not self.nameEditLayout then
        return
    end
    -- TODO: Layout rename should be an undoable Command.
    _PROJECT:setLayoutName(self.nameEditValue)
    self.nameEditLayout = nil
    self.nameEditValue = nil
end

---Ends the name edit mode without saving the new node name.
function EditorLayoutList:cancelNameEdit()
    if not self.nameEditLayout then
        return
    end
    self.nameEditLayout = nil
    self.nameEditValue = nil
end



---Updates the Editor Layout List.
---@param dt number Time delta in seconds.
function EditorLayoutList:update(dt)
    -- Update the list information.
    self.items = {}
    local names = _PROJECT:getLayoutNameList()
    for i, name in ipairs(names) do
        local layout = assert(_PROJECT:getLayout(name))
        table.insert(self.items, {layout = layout, indent = 0})
    end

    -- Calculate the maximum scroll offset.
    self.maxScrollOffset = math.max(self.ITEM_HEIGHT * #self.items - self.SIZE.y, 0)
    -- Scroll back if we've scrolled too far.
    self.scrollOffset = math.min(self.scrollOffset, self.maxScrollOffset)
end



---Draws the Editor Layout List.
function EditorLayoutList:draw()
    -- Background
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)

    -- Node tree
    love.graphics.setScissor(self.POS.x, self.POS.y, self.SIZE.x, self.SIZE.y)
    local hoveredItemID = self:getHoveredItemID()
    for i, item in ipairs(self.items) do
        local x = self.POS.x + self.ITEM_INDENT * item.indent
        local y = self.POS.y + self:getItemY(i)
        local bgColor = nil
        if item.layout == _PROJECT:getCurrentLayout() then
            bgColor = _COLORS.cyan
        elseif hoveredItemID == i and (not self.dragOrigin or not (self.hoverTop or self.hoverBottom)) then
            -- The additional condition above makes it extra clear what are you doing when arranging the nodes around in the tree.
            bgColor = _COLORS.yellow
        end
        -- Background
        if bgColor then
            love.graphics.setColor(bgColor.r, bgColor.g, bgColor.b, 0.5)
            love.graphics.rectangle("fill", self.POS.x, y, self.SIZE.x, self.ITEM_HEIGHT)
        end
        -- Foreground (icon, text)
        love.graphics.setColor(1, 1, 1)
        _RESOURCE_MANAGER:getImage("widget_box"):draw(Vec2(x, y))
        if self.nameEditLayout and item.layout == self.nameEditLayout then
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.rectangle("fill", x + 23, y + 1, self.SIZE.x - x - 20, self.ITEM_HEIGHT - 2)
            love.graphics.setColor(0.2, 0.2, 1)
            love.graphics.rectangle("line", x + 23, y + 1, self.SIZE.x - x - 20, self.ITEM_HEIGHT - 2)
            self.editor:drawShadowedText(self.nameEditValue, x + 25, y + 2, _COLORS.black, nil, 1, true)
        else
            self.editor:drawShadowedText(item.layout:getDisplayName(), x + 25, y + 2, _COLORS.white, nil)
        end
        -- If dragged over, additional signs will be shown.
        if self.dragOrigin and not self.dragSnap and not self.editor:isNodeSelected(item.node) and hoveredItemID == i then
            if self.hoverTop then
                love.graphics.setColor(1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.line(x, y, self.POS.x + self.SIZE.x, y)
            elseif self.hoverBottom then
                -- Indent the item if this node has children.
                if item.node:hasChildren() then
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
    if #self.items == 0 then
        self.editor:drawShadowedText("This project currently has\nno layouts.\n\nAdd a new layout by...", self.POS.x + 5, self.POS.y + 2)
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
        local selectedNode = self.editor.selectedNodes:getNode(1)
        if selectedNode then
            self.editor:drawShadowedText(string.format("%s {%s}", selectedNode:getName(), selectedNode.type), _MousePos.x + 10, _MousePos.y + 15, _COLORS.white, _COLORS.blue)
        end
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
function EditorLayoutList:mousepressed(x, y, button, istouch, presses)
    local hoveredItemID = self:getHoveredItemID()
    if button == 1 then
        if not hoveredItemID then
            self:cancelNameEdit()
        end
        if presses == 1 then
            -- Single click
            self:clickItem(hoveredItemID)
            if hoveredItemID then
                return true
            end
        else
            -- Subsequent clicks (double click)
            if hoveredItemID == self.nameEditLastClickedNode then
                if hoveredItemID then
                    -- We've clicked this actual Node the second time. Enable the name edit box.
                    self:startNameEdit(assert(_PROJECT:getCurrentLayout()))
                    return true
                end
            else
                -- We've clicked a different Node. If that one will be clicked the second time now, its name could be edited.
                self:clickItem(hoveredItemID)
            end
        end
    end
    return false
end



---Executed whenever a mouse wheel has been scrolled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function EditorLayoutList:wheelmoved(x, y)
    if self:isHovered() then
        self.scrollOffset = math.min(math.max(self.scrollOffset - y * self.ITEM_HEIGHT * 3, 0), self.maxScrollOffset)
    end
end



---Executed whenever a key is pressed on the keyboard.
---Returns `true` if the input is consumed.
---@param key string The key code.
---@return boolean
function EditorLayoutList:keypressed(key)
    if key == "f3" then
        self.showInternalUI = not self.showInternalUI
        return true
    end
    -- Anything below applies only if the name edit mode is enabled.
    if not self.nameEditLayout then
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
        -- Reject the current edit value in the name edit field.
        self:cancelNameEdit()
        return true
    end
	if self.nameEditLayout then
		-- Do not let anything else catch the keyboard input if the name edition box is currently active.
		return true
	end
    return false
end



---Executed whenever a certain character has been typed on the keyboard.
---@param text string The character.
function EditorLayoutList:textinput(text)
    if not self.nameEditLayout then
        return
    end
	self.nameEditValue = self.nameEditValue .. text
end



return EditorLayoutList