local class = require "com.class"

---@class Editor
---@overload fun():Editor
local Editor = class:derive("Editor")

local Vec2 = require("Vector2")
local Node = require("Node")



---Constructs a new UI Editor.
function Editor:new()
    self.UI = nil

    self.BUTTONS = {
        self:button(0, 400, 150, "Delete [Del]", function() self:deleteSelectedNode() end),
        self:button(0, 420, 150, "Layer Up [PgUp]", function() self:moveSelectedNodeUp() end),
        self:button(0, 440, 150, "Layer Down [PgDown]", function() self:moveSelectedNodeDown() end),

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

    self.enabled = true
    self.hoveredNode = nil
    self.selectedNode = nil
    self.nodeDragOrigin = nil
    self.nodeDragOriginalPos = nil
    self.nodeDragSnap = false
end



---Returns UI tree information.
---@param node Node? The UI node of which the tree should be added to the list.
---@param tab table? The table, used internally.
---@param indent integer? The starting indentation.
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



---Moves the currently selected UI node by the given amount of pixels.
---@param offset Vector2 The movement vector the selected UI node should be moved towards.
function Editor:moveSelectedNode(offset)
    if not self.selectedNode then
        return
    end
    self.selectedNode:setPos(self.selectedNode:getPos() + offset)
end



---Sets a new alignment for the selected node.
---@param align Vector2 The new alignment value.
function Editor:setSelectedNodeAlign(align)
    if not self.selectedNode then
        return
    end
    self.selectedNode:setAlign(align)
end



---Sets a new parental alignment for the selected node.
---@param parentAlign Vector2 The new parental alignment value.
function Editor:setSelectedNodeParentAlign(parentAlign)
    if not self.selectedNode then
        return
    end
    self.selectedNode:setParentAlign(parentAlign)
end



---Moves the selected node up in its parent's hierarchy.
function Editor:moveSelectedNodeUp()
    if not self.selectedNode then
        return
    end
    self.selectedNode:moveSelfUp()
end



---Moves the selected node down in its parent's hierarchy.
function Editor:moveSelectedNodeDown()
    if not self.selectedNode then
        return
    end
    self.selectedNode:moveSelfDown()
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
    if not self.selectedNode then
        return
    end
    self.selectedNode:removeSelf()
    self.selectedNode = nil
end



---Convenience function which creates an editor button. 
---@param x number The X coordinate of the button position.
---@param y number The Y coordinate of the button position.
---@param w number The width of the button. Height is always 20.
---@param text string The text that should be written on the button.
---@param fn function? The function to be executed when this button is clicked.
---@return Node
function Editor:button(x, y, w, text, fn)
    local button = Node({name = "", type = "9sprite", image = "ed_button", clickImage = "ed_button_click", pos = {x = x, y = y}, size = {x = w, y = 20}, scale = 2, children = {{name = "", type = "text", font = "default", text = text, pos = {x = 0, y = -1}, align = "center", parentAlign = "center", color = {r = 0, g = 0, b = 0}}}})
    button:setOnClick(fn)
    return button
end



---Returns whether an editor button (or any editor UI) is hovered.
---@return boolean
function Editor:isUIHovered()
    for i, button in ipairs(self.BUTTONS) do
        if button:isHovered() then
            return true
        end
    end
    return false
end



---Initializes the UI for this Editor...needed?
function Editor:load()
    self.UI = _LoadUI("editor_ui.json")
end



---Updates the Editor.
---@param dt number Time delta in seconds.
function Editor:update(dt)
	self.hoveredNode = _UI:findChildByPixelDepthFirst(_MouseCPos)
    if self:isUIHovered() then
        self.hoveredNode = nil
    end

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
    for i, button in ipairs(self.BUTTONS) do
        button:update(dt)
    end
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
    local treeInfo = self:getUITreeInfo()
    for i, line in ipairs(treeInfo) do
        local color = _COLORS.white
        if line.node == self.selectedNode then
            color = _COLORS.cyan
        elseif line.node == self.hoveredNode then
            color = _COLORS.yellow
        end
        self:drawShadowedText(string.format("%s {%s}", line.node.name, line.node.type), 5 + 30 * line.indent, 120 + 15 * i, color)
    end

    -- Buttons
    self:drawShadowedText("Node Align", 100, 620)
    self:drawShadowedText("Parent Align", 300, 620)
    self:drawShadowedText("Ctrl+Click a node to make it a parent of the currently selected node", 500, 620)
    for i, button in ipairs(self.BUTTONS) do
        button:draw()
    end
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
    for i, btn in ipairs(self.BUTTONS) do
        btn:mousepressed(x, y, button)
    end
	if button == 1 and not self:isUIHovered() then
        if love.keyboard.isDown("lctrl", "rctrl") then
            -- Ctrl+Click parents the selected node instead.
            self:parentSelectedNodeToHoveredNode()
        else
            self.selectedNode = self.hoveredNode
            if self.selectedNode then
                self.nodeDragOrigin = _MouseCPos
                self.nodeDragOriginalPos = self.selectedNode:getPos()
                self.nodeDragSnap = true
            end
        end
	end
end



---Executed whenever a mouse button is released anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function Editor:mousereleased(x, y, button)
    self.UI:mousereleased(x, y, button)
    for i, btn in ipairs(self.BUTTONS) do
        btn:mousereleased(x, y, button)
    end
    self.nodeDragOrigin = nil
    self.nodeDragOriginalPos = nil
    self.nodeDragSnap = false
end



---Executed whenever a key is pressed on the keyboard.
---@param key string The key code.
function Editor:keypressed(key)
	if key == "tab" then
		self.enabled = not self.enabled
    elseif key == "delete" then
        self:deleteSelectedNode()
    elseif key == "pageup" then
        self:moveSelectedNodeUp()
    elseif key == "pagedown" then
        self:moveSelectedNodeDown()
    elseif key == "up" then
        self:moveSelectedNode(Vec2(0, -1))
    elseif key == "down" then
        self:moveSelectedNode(Vec2(0, 1))
    elseif key == "left" then
        self:moveSelectedNode(Vec2(-1, 0))
    elseif key == "right" then
        self:moveSelectedNode(Vec2(1, 0))
	end
end



return Editor