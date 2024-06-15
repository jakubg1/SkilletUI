_Utils = require("com.utils")

local Vec2 = require("Vector2")
local Color = require("Color")
local MainCanvas = require("MainCanvas")
local GridBackground = require("GridBackground")
local Node = require("Node")

love.graphics.setDefaultFilter("nearest", "nearest")

-- Globals
_WINDOW_SIZE = Vec2(1280, 720)
_DRAW_TIME = 0
_FONT_CHARACTERS = " abcdefghijklmnopqrstuvwxyząćęłńóśźżABCDEFGHIJKLMNOPQRSTUVWXYZĄĆĘŁŃÓŚŹŻ0123456789<>-+()[]_.,:;'!?@#$€%^&*\"/|\\"
_FONTS = {
	standard = love.graphics.newImageFont("standard.png", _FONT_CHARACTERS, 1)
}

_CANVAS = MainCanvas()
_BACKGROUND = GridBackground()



function _LoadUI()
	local data = _Utils.loadJson("ui.json")

	return Node(data)
end



function love.load()
	love.window.setMode(_WINDOW_SIZE.x, _WINDOW_SIZE.y)
	_UI = _LoadUI()
end



function love.update(dt)
	_BACKGROUND:update(dt)
	_UI:update(dt)
end



function love.draw()
	local t = love.timer.getTime()
	_CANVAS:activate()
	_BACKGROUND:draw()
	_UI:draw()
	_CANVAS:draw()
	local t2 = love.timer.getTime() - t
	_DRAW_TIME = _DRAW_TIME * 0.95 + t2 * 0.05
	love.graphics.print(string.format("Drawing took approximately %.1fms", _DRAW_TIME * 1000))
end