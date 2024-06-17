_Utils = require("com.utils")

local Vec2 = require("Vector2")
local NineImage = require("NineImage")
local MainCanvas = require("MainCanvas")
local GridBackground = require("GridBackground")
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
	button = NineImage(love.graphics.newImage("button.png"), 2, 3, 3, 4)
}

_CANVAS = MainCanvas()
_BACKGROUND = GridBackground()



function _LoadUI(path)
	local data = _Utils.loadJson(path)
	return Node(data)
end



function love.load()
	love.window.setMode(_WINDOW_SIZE.x, _WINDOW_SIZE.y)
	_UI = _LoadUI("ui.json")
	_EDITOR_UI = _LoadUI("editor_ui.json")
end



function love.update(dt)
	_MOUSE_POS = Vec2(love.mouse.getPosition())
	_MOUSE_CPOS = _CANVAS:posToPixel(_MOUSE_POS)
	_BACKGROUND:update(dt)
	_UI:update(dt)
	_EDITOR_UI:update(dt)
end



function love.draw()
	local t = love.timer.getTime()
	_CANVAS:activate()
	_BACKGROUND:draw()
	_UI:draw()
	local hover = _UI:findChildByPixel(_MOUSE_CPOS)
	if hover then
		hover:drawHitbox()
	end
	_CANVAS:draw()
	local t2 = love.timer.getTime() - t
	_DRAW_TIME = _DRAW_TIME * 0.95 + t2 * 0.05
	_EDITOR_UI:findChildByName("drawtime").widget.text = string.format("Drawing took approximately %.1fms", _DRAW_TIME * 1000)
	_EDITOR_UI:findChildByName("pos").widget.text = string.format("Mouse position: %s", _MOUSE_CPOS)
	_EDITOR_UI:draw()
end



function love.mousepressed(x, y, button)
	if button == 1 then
	end
end