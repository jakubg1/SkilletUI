local class = require "com.class"

---@class EditorCanvas
---@overload fun(editor, canvas):EditorCanvas
local EditorCanvas = class:derive("EditorCanvas")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")

---Constructs a new Editor Canvas Manager.
---It is responsible for zooming, panning, cropping the canvas, drawing on top of it, drawing proper background, scroll bars and all that stuff.
---@param editor Editor The editor this Canvas Manager belongs to.
---@param canvas MainCanvas The canvas this Canvas Manager will be managing.
function EditorCanvas:new(editor, canvas)
    self.editor = editor
    self.canvas = canvas

    self.SIZE_EDITOR = Vec2(960, 540)
    self.OFFSET_EDITOR = Vec2(230, 25)
    self.SIZE_PRESENTATION = _WINDOW_SIZE
    self.OFFSET_PRESENTATION = Vec2()

    self.scale = 1
    self.pan = Vec2()
    self.fullscreen = false

    self.dragOriginalPan = nil
    self.dragOrigin = nil

    self:updateCanvas()

    self.debug = false
end

--##############################################################--
---------------- B A S I C   I N T E R A C T I O N ---------------
--##############################################################--

---Updates the Canvas Manager.
---@param dt number Time delta in seconds.
function EditorCanvas:update(dt)
    if self.dragOrigin then
        local movement = _MousePos - self.dragOrigin
        self:panTo(self.dragOriginalPan - movement / self.canvas.scale)
    end
end

---Returns `true` if the mouse cursor is inside of the canvas area, otherwise `false`.
---@return boolean
function EditorCanvas:isHovered()
    return _Utils.isPointInsideBox(_MousePos, self.canvas.pos, self.canvas.size)
end

---Returns the layout position which is currently in the center of the canvas area.
---@return Vector2
function EditorCanvas:getCenterPos()
    return self.canvas:posToPixel(self.canvas.pos + self.canvas.size / 2)
end

---Returns the zoom factor of this Canvas to match its current size best.
---@return number
function EditorCanvas:getFittingScale()
    local scale = self.canvas.size / self.canvas.resolution
    return math.min(scale.x, scale.y)
end

---Returns the panning of this Canvas to match its current size best.
---@return Vector2
function EditorCanvas:getFittingPan()
    return ((self.canvas.size - self.canvas.resolution * self:getFittingScale()) / 2) / -self:getFittingScale()
end

---Updates the canvas' settings to match the current manager state.
function EditorCanvas:updateCanvas()
    local actualFullscreen = self.fullscreen and not _EDITOR.enabled
	self.canvas:setPos(actualFullscreen and self.OFFSET_PRESENTATION or self.OFFSET_EDITOR)
	self.canvas:setSize(actualFullscreen and self.SIZE_PRESENTATION or self.SIZE_EDITOR)
    self.canvas:setScale(actualFullscreen and self:getFittingScale() or self.scale)
    self.canvas:setPan(actualFullscreen and self:getFittingPan() or self.pan)
end

---Increases or decreases the canvas zoom by the given factor.
---@param factor number The factor to zoom by.
---@param around Vector2? The position to zoom the canvas around. That position will remain at the exact same pixel.
function EditorCanvas:zoomInOut(factor, around)
    around = around or Vec2()
    local newScale = math.min(math.max(self.scale * factor, 0.125), 8)
    local actualFactor = newScale / self.scale
    self.scale = newScale

    local startScreenSize = self.canvas.size / self.canvas.scale
    local startScreenSpace = (around - self.pan) / self.canvas.size * self.canvas.scale
    local targetScreenSize = startScreenSize / actualFactor
    self.pan = self.pan + (startScreenSize - targetScreenSize) * startScreenSpace
    self:updateCanvas()
end

---Zooms the canvas to the provided pixel scale.
---@param scale integer The target pixel scale.
---@param around Vector2? The position to zoom the canvas around. That position will remain at the exact same pixel.
function EditorCanvas:naturalZoom(scale, around)
    self:zoomInOut(scale / self.canvas.scale, around)
end

---Pans the canvas to the specific position.
---@param pan Vector2 The new pan.
function EditorCanvas:panTo(pan)
    self.pan = pan
    self:updateCanvas()
end

---Starts the dragging (panning) of the canvas.
function EditorCanvas:startDrag()
    self.dragOriginalPan = self.canvas.pan
    self.dragOrigin = _MousePos
end

---Stops the dragging (panning) of the canvas.
function EditorCanvas:stopDrag()
    self.dragOriginalPan = nil
    self.dragOrigin = nil
end

---Resets the zoom scaling and panning.
function EditorCanvas:resetZoom()
    self.scale = 1
    self.pan = Vec2()
    self:updateCanvas()
end

---Sets the zoom scaling and panning to fit the entire canvas.
function EditorCanvas:fitZoom()
    self.scale = self:getFittingScale()
    self.pan = self:getFittingPan()
    self:updateCanvas()
end

---Sets whether the fullscreen should be enabled.
---@param fullscreen boolean If `true`, the canvas will be expanded to cover the full screen. Otherwise, it will be shown in a little window.
function EditorCanvas:setFullscreen(fullscreen)
    self.fullscreen = fullscreen
    self:updateCanvas()
end

---Toggles the fullscreen mode.
function EditorCanvas:toggleFullscreen()
    self.fullscreen = not self.fullscreen
    self:updateCanvas()
end

--##########################################--
---------------- D R A W I N G ---------------
--##########################################--

---Draws everything that lies under the canvas, i.e. background and the status bar.
function EditorCanvas:drawUnderCanvas()
    -- Very background
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", self.canvas.pos.x, self.canvas.pos.y, self.canvas.size.x, self.canvas.size.y)
    love.graphics.setColor(0.15, 0.15, 0.15)
    self.editor:drawStripedRectangle(self.canvas.pos.x, self.canvas.pos.y, self.canvas.size.x, self.canvas.size.y, 8)
    -- Canvas outline (looks bad)
    --[[
    love.graphics.setScissor(self.canvas.pos.x, self.canvas.pos.y, self.canvas.size.x, self.canvas.size.y)
    love.graphics.setColor(0, 0, 0, 0.4)
    local pos = self.canvas:getGlobalPos()
    local size = self.canvas:getGlobalSize()
    love.graphics.rectangle("fill", pos.x - 5, pos.y - 5, size.x + 10, size.y + 10)
    love.graphics.setScissor()
    ]]
    -- Status bar
    _SetColor(_COLORS.e_blue, 0.5)
    love.graphics.rectangle("fill", self.canvas.pos.x, self.canvas.pos.y + self.canvas.size.y, self.canvas.size.x, 20)
    self.editor:drawShadowedText(string.format("Zoom: %.1f%% | Pos: %s", self.scale * 100, _MouseCPos), self.canvas.pos.x + 5, self.canvas.pos.y + self.canvas.size.y + 1)
end

---Draws everything that lies on the canvas, such as the grid, selected and hovered node outlines, etc.
function EditorCanvas:drawOnCanvas()
    -- Place a scissor.
    love.graphics.setScissor(self.canvas.pos.x, self.canvas.pos.y, self.canvas.size.x, self.canvas.size.y)
    -- Draw the grid.
    if _PROJECT:isGridVisible() then
        self:drawGrid()
    end
    -- Draw a frame around the hovered node and frames around the selected nodes.
    self:drawUIForNodes()
    -- Debug resize crosshair
    if self.debug and self.editor.nodeResizeOrigin then
        love.graphics.setColor(0, 1, 0)
        self:drawCrosshair(self.editor.nodeResizeOrigin, 6)
        love.graphics.setColor(1, 1, 0)
        self:drawCrosshair(self.editor.nodeResizeOrigin + self.editor.nodeResizeOffset, 6)
        love.graphics.setColor(1, 0, 0.5)
        self:drawCrosshair(self.editor:snapPositionToGrid(_MouseCPos) - self.editor.nodeResizeOffset, 6)
    end
    -- Draw the multi-selection frame.
    if self.editor.nodeMultiSelectOrigin then
        local origin = self.editor.nodeMultiSelectOrigin
        local origSize = self.editor.nodeMultiSelectSize
        local pos = Vec2(math.min(origin.x, origin.x + origSize.x), math.min(origin.y, origin.y + origSize.y))
        local size = origSize:abs()
        love.graphics.setColor(0, 1, 1, 0.5)
        self:drawFilledRectangle(pos, size)
        love.graphics.setColor(0, 1, 1)
        self:drawRectangle(pos, size, 1)
    end
    -- Remove the scissor.
    love.graphics.setScissor()
end

---Draws the grid, if it is enabled in the project.
function EditorCanvas:drawGrid()
    local layoutSize = self.editor:getCurrentLayout():getSize()
    local gridSize = _PROJECT:getGridSize()
    if not gridSize then
        return
    end
    local lineCount = (layoutSize / gridSize):ceil() - 1
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.2, 0.2, 0.8)
    -- Vertical lines
    for i = 1, lineCount.x do
        local p1 = Vec2(gridSize.x * i, 0)
        local p2 = Vec2(gridSize.x * i, layoutSize.y)
        self:drawDashedLine(p1, p2, 4, 4, 0)
    end
    -- Horizontal lines
    for i = 1, lineCount.y do
        local p1 = Vec2(0, gridSize.y * i)
        local p2 = Vec2(layoutSize.x, gridSize.y * i)
        self:drawDashedLine(p1, p2, 4, 4, 0)
    end
end

---Draws the Editor UI for the hovered and selected Nodes: selection frames, resize handles etc.
function EditorCanvas:drawUIForNodes()
    -- Hovered nodes
    if self.editor.hoveredNode then
        local pos = self.editor.hoveredNode:getGlobalPos()
        if self.editor.hoveredNode.widget then
            local size = self.editor.hoveredNode:getSize()
            love.graphics.setColor(1, 1, 0)
            self:drawRectangle(pos, size, 2)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            self:drawCrosshair(pos, 5)
        end
    end
    -- Selected nodes
    for i, node in ipairs(self.editor.selectedNodes:getNodes()) do
        local pos = node:getGlobalPos()
        if node.widget then
            local size = node:getSize()
            love.graphics.setColor(0, 1, 1)
            self:drawDashedRectangle(pos, size, 2)
        else
            love.graphics.setColor(1, 1, 1)
            self:drawCrosshair(pos, 5)
        end
        -- Draw a local crosshair.
        local localPos = node:getGlobalPosWithoutLocalAlign()
        love.graphics.setColor(0, 0, 1)
        self:drawCrosshair(localPos, 5)
        -- Draw parent align crosshair.
        local localPos2 = node:getParentAlignPos()
        love.graphics.setColor(1, 0, 1)
        self:drawCrosshair(localPos2, 5)
        -- Draw a line between them.
        love.graphics.setColor(0.5, 0, 1)
        self:drawLine(localPos, localPos2)
        -- Draw resizing boxes if the widget can be resized.
        if node:isResizable() then
            local id = self.editor:getHoveredNodeResizeHandleID()
            for j = 1, 8 do
                if j == id or j == self.editor.nodeResizeHandleID then
                    -- This handle is hovered or being dragged.
                    love.graphics.setColor(1, 1, 1)
                else
                    love.graphics.setColor(0, 1, 1)
                end
                local pos = self.editor:getNodeResizeHandlePos(j)
                if pos then
                    love.graphics.rectangle("fill", pos.x - 3, pos.y - 3, 7, 7)
                end
            end
        end
    end
end

---Draws a regular line between two points.
---@param p1 Vector2 The starting position of the line.
---@param p2 Vector2 The ending position of the line.
function EditorCanvas:drawLine(p1, p2)
    p1 = self.canvas:pixelToPos(p1)
    p2 = self.canvas:pixelToPos(p2)
    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
end

---Draws a dashed line between two points. The dashes are animated.
---@param p1 Vector2 The starting position of the line.
---@param p2 Vector2 The ending position of the line.
---@param filledPixels integer? The amount of filled pixels per cycle. Defaults to 10.
---@param blankPixels integer? The amount of blank pixels per cycle. Defaults to 10.
---@param speed number? The speed of the dash. Defaults to 12.
function EditorCanvas:drawDashedLine(p1, p2, filledPixels, blankPixels, speed)
    p1 = self.canvas:pixelToPos(p1)
    p2 = self.canvas:pixelToPos(p2)
    filledPixels = filledPixels or 10
    blankPixels = blankPixels or 10
    speed = speed or 12
    local offset = (_Time * speed) % (filledPixels + blankPixels) - filledPixels
    local length = (p2 - p1):len()
    while offset < length do
        local q1x = _Utils.interpolateClamped(p1.x, p2.x, offset / length)
        local q1y = _Utils.interpolateClamped(p1.y, p2.y, offset / length)
        local q2x = _Utils.interpolateClamped(p1.x, p2.x, (offset + filledPixels) / length)
        local q2y = _Utils.interpolateClamped(p1.y, p2.y, (offset + filledPixels) / length)
        love.graphics.line(q1x, q1y, q2x, q2y)
        offset = offset + filledPixels + blankPixels
    end
end

---Draws a solid line rectangle transformed so that the coordinates lay on top of the canvas.
---The rectangle thickness is always gravitating to the center.
---@param pos Vector2 The rectangle position.
---@param size Vector2 The rectangle size, in pixels.
---@param width integer The width of the rectangle's line.
function EditorCanvas:drawRectangle(pos, size, width)
    pos, size = self.canvas:pixelToPosBox(pos, size)
    love.graphics.setLineWidth(width)
    love.graphics.rectangle("line", pos.x + width / 2, pos.y + width / 2, size.x - width, size.y - width)
end

---Draws a filled rectangle transformed so that the coordinates lay on top of the canvas.
---@param pos Vector2 The rectangle position.
---@param size Vector2 The rectangle size, in pixels.
function EditorCanvas:drawFilledRectangle(pos, size)
    pos, size = self.canvas:pixelToPosBox(pos, size)
    love.graphics.rectangle("fill", pos.x, pos.y, size.x, size.y)
end

---Draws a dashed rectangle with the given position and size. The dashes are animated depending on the rules of `:drawDashedLine()`
---The rectangle thickness is always gravitating to the center.
---Maximum supported line thickness is 4.
---@param pos Vector2 The rectangle position.
---@param size Vector2 The rectangle size, in pixels.
---@param width integer The width of the rectangle's line.
function EditorCanvas:drawDashedRectangle(pos, size, width)
    local c1 = pos
    local c2 = pos + Vec2(size.x - 1, 0)
    local c3 = pos + size - 1
    local c4 = pos + Vec2(0, size.y - 1)
    love.graphics.setLineWidth(width)
    -- TODO: Get rid of these stupid corrections and find out a correct way to draw stuff like that...
    local a = {0, 0, 0.5, 0.5, 0.75}
    local b = {0, 1, 0.75, 0.75, 0.5}
    local c = {0, 0.75, 0.75, 0.5, 0.5}
    local d = {0, 0.5, 0.5, 0.75, 0.75}
    self:drawDashedLine(c1 + Vec2(0, a[width + 1]), c2 + Vec2(0, a[width + 1]))
    self:drawDashedLine(c2 + Vec2(b[width + 1], 0), c3 + Vec2(b[width + 1], 0))
    self:drawDashedLine(c3 + Vec2(0, c[width + 1]), c4 + Vec2(0, c[width + 1]))
    self:drawDashedLine(c4 + Vec2(d[width + 1], 0), c1 + Vec2(d[width + 1], 0))
end

---Draws a crosshair.
---@param pos Vector2 The crosshair position.
---@param size number The crosshair size, in pixels.
function EditorCanvas:drawCrosshair(pos, size)
    pos = self.canvas:pixelToPos(pos:floor() + 0.5)
    love.graphics.line(pos.x - size, pos.y, pos.x + size + 1, pos.y)
    love.graphics.line(pos.x, pos.y - size, pos.x, pos.y + size + 1)
end

--##############################################--
---------------- C A L L B A C K S ---------------
--##############################################--

---Executed whenever a mouse wheel has been scrolled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function EditorCanvas:wheelmoved(x, y)
    if self:isHovered() then
        self:zoomInOut(2 ^ y, _MouseCPos)
    end
end

---LOVE callback for when the window is resized.
---@param w integer The new width of the window.
---@param h integer The new height of the window.
function EditorCanvas:resize(w, h)
    self.SIZE_EDITOR = Vec2(w - 640, h - 360)
    self.SIZE_PRESENTATION = Vec2(w, h)
    self:updateCanvas()
end

return EditorCanvas