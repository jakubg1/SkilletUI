local class = require "com.class"

---@class Editor
---@overload fun():Editor
local Editor = class:derive("Editor")



---Constructs a new UI Editor.
function Editor:new()
    self.UI = nil

    self.enabled = false
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



---Initializes the UI for this Editor...needed?
function Editor:load()
    self.UI = _LoadUI("editor_ui.json")
end



---Updates the Editor.
---@param dt number Time delta in seconds.
function Editor:update(dt)
	self.hoveredNode = _UI:findChildByPixelDepthFirst(_MouseCPos)
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
	if button == 1 then
		if self.enabled then
			self.selectedNode = self.hoveredNode
			if self.selectedNode then
				self.nodeDragOrigin = _MouseCPos
				self.nodeDragOriginalPos = self.selectedNode:getPos()
				self.nodeDragSnap = true
			end
		end
	end
    self.UI:mousepressed(x, y, button)
end



---Executed whenever a mouse button is released anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function Editor:mousereleased(x, y, button)
    self.UI:mousereleased(x, y, button)
    self.nodeDragOrigin = nil
    self.nodeDragOriginalPos = nil
    self.nodeDragSnap = false
end



---Executed whenever a key is pressed on the keyboard.
---@param key string The key code.
function Editor:keypressed(key)
	if key == "tab" then
		self.enabled = not self.enabled
	end
end



return Editor