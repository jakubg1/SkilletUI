local class = require "com.class"

---@class EditorCanvas
---@overload fun(editor, canvas):EditorCanvas
local EditorCanvas = class:derive("EditorCanvas")

-- Place your imports here
local Vec2 = require("Vector2")

---Constructs a new Editor Canvas Manager.
---It is responsible for zooming, panning, cropping the canvas, drawing on top of it, drawing proper background, scroll bars and all that stuff.
---@param editor Editor The editor this Canvas Manager belongs to.
---@param canvas MainCanvas The canvas this Canvas Manager will be managing.
function EditorCanvas:new(editor, canvas)
    self.editor = editor
    self.canvas = canvas

    self.SIZE_EDITOR = Vec2(960, 540)
    self.OFFSET_EDITOR = Vec2(230, 40)
    self.SIZE_PRESENTATION = _WINDOW_SIZE
    self.OFFSET_PRESENTATION = Vec2()

    self.zoom = 1
    self.pan = Vec2()
    self.fullscreen = false
    self.background = true

    self.dragOriginalPan = nil
    self.dragOrigin = nil

    self:updateCanvas()
end

---Updates the Canvas Manager.
---@param dt number Time delta in seconds.
function EditorCanvas:update(dt)
    if self.dragOrigin then
        local movement = _MousePos - self.dragOrigin
        self:panTo(self.dragOriginalPan - movement / self.canvas:getScale())
    end
end

---Updates the canvas' settings to match the current manager state.
function EditorCanvas:updateCanvas()
    local actualFullscreen = self.fullscreen and not _EDITOR.enabled
	self.canvas:setPos(actualFullscreen and self.OFFSET_PRESENTATION or self.OFFSET_EDITOR)
	self.canvas:setSize(actualFullscreen and self.SIZE_PRESENTATION or self.SIZE_EDITOR)
    self.canvas:setZoom(self.zoom)
    self.canvas:setPan(self.pan)
end

---Increases or decreases the canvas zoom by the given factor.
---@param factor number The factor to zoom by.
---@param around Vector2? The position to zoom the canvas around. That position will remain at the exact same pixel.
function EditorCanvas:zoomInOut(factor, around)
    around = around or Vec2()
    local newZoom = math.min(math.max(self.zoom * factor, 0.125), 8)
    local actualFactor = newZoom / self.zoom
    self.zoom = newZoom

    local startScreenSize = self.canvas.size / self.canvas:getScale()
    local startScreenSpace = (around - self.pan) / self.canvas.size * self.canvas:getScale()
    local targetScreenSize = startScreenSize / actualFactor
    self.pan = self.pan + (startScreenSize - targetScreenSize) * startScreenSpace
    self:updateCanvas()
end

---Pans the canvas to the specific position.
---@param pan Vector2 The new pan.
function EditorCanvas:panTo(pan)
    self.pan = pan
    self:updateCanvas()
end

---Starts the dragging (panning) of the canvas.
function EditorCanvas:startDrag()
    self.dragOriginalPan = self.canvas:getPan()
    self.dragOrigin = _MousePos
end

---Stops the dragging (panning) of the canvas.
function EditorCanvas:stopDrag()
    self.dragOriginalPan = nil
    self.dragOrigin = nil
end

---Resets the zoom scaling and panning.
function EditorCanvas:resetZoom()
    self.zoom = 1
    self.pan = Vec2()
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

---Toggles whether the hardcoded animated background should be displayed in the background of the canvas.
function EditorCanvas:toggleBackground()
    self.background = not self.background
end

---Executed whenever a mouse wheel has been scrolled.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
function EditorCanvas:wheelmoved(x, y)
    if _IsCtrlPressed() then
        self:zoomInOut(2 ^ y, _MouseCPos)
    end
end

---LOVE callback for when the window is resized.
---@param w integer The new width of the window.
---@param h integer The new height of the window.
function EditorCanvas:resize(w, h)
    self.SIZE_PRESENTATION = Vec2(w, h)
    self:updateCanvas()
end

return EditorCanvas