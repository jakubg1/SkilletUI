_Utils = require("com.utils")

local Vec2 = require("Vector2")
local NineImage = require("NineImage")
local MainCanvas = require("MainCanvas")
local GridBackground = require("GridBackground")
local TransitionTest = require("TransitionTest")
local Node = require("Node")

love.graphics.setDefaultFilter("nearest", "nearest")

-- Globals
_VEC2S_PER_FRAME = 0
_WINDOW_SIZE = Vec2(1280, 720)
_MousePos = Vec2()
_MouseCPos = Vec2()

_DrawTime = 0
_FONT_CHARACTERS = " abcdefghijklmnopqrstuvwxyząćęłńóśźżABCDEFGHIJKLMNOPQRSTUVWXYZĄĆĘŁŃÓŚŹŻ0123456789<>-+()[]_.,:;'!?@#$€%^&*\"/|\\"
_FONTS = {
	standard = love.graphics.newImageFont("standard.png", _FONT_CHARACTERS, 1)
}
_IMAGES = {
	button = NineImage(love.graphics.newImage("button.png"), 2, 3, 3, 4),
	button_hover = NineImage(love.graphics.newImage("button_hover.png"), 2, 3, 3, 4),
	button_click = NineImage(love.graphics.newImage("button_click.png"), 2, 3, 3, 4),
	ed_button = NineImage(love.graphics.newImage("ed_button.png"), 2, 3, 2, 3),
	ed_button_click = NineImage(love.graphics.newImage("ed_button_click.png"), 2, 3, 2, 3)
}

_CANVAS = MainCanvas()
_BACKGROUND = GridBackground()
_TRANSITION = TransitionTest()

_EditorMode = false
_HoveredNode = nil
_SelectedNode = nil
_NodeDragOrigin = nil
_NodeDragOriginalPos = nil
_NodeDragSnap = false



function _LoadUI(path, useCpos)
	local data = _Utils.loadJson(path)
	return Node(data, nil, useCpos)
end



function love.load()
	love.window.setMode(_WINDOW_SIZE.x, _WINDOW_SIZE.y)
	_UI = _LoadUI("ui.json", true)
	_UI:findChildByName("btn1"):setOnClick(function ()
		if _TRANSITION.state then
			_TRANSITION:hide()
		else
			_TRANSITION:show()
		end
	end)
	_EDITOR_UI = _LoadUI("editor_ui.json")
end



function love.update(dt)
	-- Mouse position
	_MousePos = Vec2(love.mouse.getPosition())
	_MouseCPos = _CANVAS:posToPixel(_MousePos)

	-- Editor
	_HoveredNode = _UI:findChildByPixel(_MouseCPos)
	if _SelectedNode and _NodeDragOrigin then
		local movement = _MouseCPos - _NodeDragOrigin
		if _NodeDragSnap then
			--if movement:len() > 2 then
				_NodeDragSnap = false
			--end
		else
			_SelectedNode:setPos(_NodeDragOriginalPos + movement)
		end
	end

	-- Main update
	_BACKGROUND:update(dt)
	_TRANSITION:update(dt)
	_UI:update(dt)
	_EDITOR_UI:update(dt)
end



function love.draw()
	_VEC2S_PER_FRAME = 0
	local t = love.timer.getTime()
	_CANVAS:activate()
	_BACKGROUND:draw()
	_UI:draw()
	if _EditorMode and _HoveredNode then
		_HoveredNode:drawHitbox()
	end
	if _EditorMode and _SelectedNode then
		_SelectedNode:drawSelected()
	end
	_TRANSITION:draw()
	_CANVAS:draw()
	local t2 = love.timer.getTime() - t
	_DrawTime = _DrawTime * 0.95 + t2 * 0.05
	_EDITOR_UI:findChildByName("drawtime").widget.text = string.format("Drawing took approximately %.1fms", _DrawTime * 1000)
	_EDITOR_UI:findChildByName("pos").widget.text = string.format("Mouse position: %s", _MouseCPos)
	_EDITOR_UI:findChildByName("line3").widget.text = string.format("Vecs per frame: %s", _VEC2S_PER_FRAME)
	_EDITOR_UI:draw()
end



function love.mousepressed(x, y, button)
	if button == 1 then
		if _EditorMode then
			_SelectedNode = _HoveredNode
			if _SelectedNode then
				_NodeDragOrigin = _MouseCPos
				_NodeDragOriginalPos = _SelectedNode:getPos()
				_NodeDragSnap = true
			end
		end
	end
	if not _EditorMode then
		_UI:mousepressed(x, y, button)
	end
	_EDITOR_UI:mousepressed(x, y, button)
end



function love.mousereleased(x, y, button)
	if not _EditorMode then
		_UI:mousereleased(x, y, button)
	end
	_EDITOR_UI:mousereleased(x, y, button)
	_NodeDragOrigin = nil
	_NodeDragOriginalPos = nil
	_NodeDragSnap = false
end



function love.keypressed(key)
	if key == "tab" then
		_EditorMode = not _EditorMode
	end
end