_Utils = require("com.utils")

local Vec2 = require("Vector2")
local NineImage = require("NineImage")
local MainCanvas = require("MainCanvas")
local GridBackground = require("GridBackground")
local TransitionTest = require("TransitionTest")
local Node = require("Node")

love.graphics.setDefaultFilter("nearest", "nearest")

-- Globals
_WINDOW_SIZE = Vec2(1280, 720)
_MOUSE_POS = Vec2()
_MOUSE_CPOS = Vec2()

_DRAW_TIME = 0
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

_EDITOR_MODE = true
_HOVERED_NODE = nil
_SELECTED_NODE = nil



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
	_MOUSE_POS = Vec2(love.mouse.getPosition())
	_MOUSE_CPOS = _CANVAS:posToPixel(_MOUSE_POS)
	_HOVERED_NODE = _UI:findChildByPixel(_MOUSE_CPOS)
	_BACKGROUND:update(dt)
	_TRANSITION:update(dt)
	_UI:update(dt)
	_EDITOR_UI:update(dt)
end



function love.draw()
	local t = love.timer.getTime()
	_CANVAS:activate()
	_BACKGROUND:draw()
	_UI:draw()
	if _EDITOR_MODE and _HOVERED_NODE then
		_HOVERED_NODE:drawHitbox()
	end
	if _EDITOR_MODE and _SELECTED_NODE then
		_SELECTED_NODE:drawSelected()
	end
	_TRANSITION:draw()
	_CANVAS:draw()
	local t2 = love.timer.getTime() - t
	_DRAW_TIME = _DRAW_TIME * 0.95 + t2 * 0.05
	_EDITOR_UI:findChildByName("drawtime").widget.text = string.format("Drawing took approximately %.1fms", _DRAW_TIME * 1000)
	_EDITOR_UI:findChildByName("pos").widget.text = string.format("Mouse position: %s", _MOUSE_CPOS)
	_EDITOR_UI:draw()
end



function love.mousepressed(x, y, button)
	if button == 1 then
		if _EDITOR_MODE then
			_SELECTED_NODE = _HOVERED_NODE
		end
	end
	_UI:mousepressed(x, y, button)
	_EDITOR_UI:mousepressed(x, y, button)
end



function love.mousereleased(x, y, button)
	_UI:mousereleased(x, y, button)
	_EDITOR_UI:mousereleased(x, y, button)
end



function love.keypressed(key)
	if key == "tab" then
		_EDITOR_MODE = not _EDITOR_MODE
	end
end