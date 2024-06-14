_Utils = require("com.utils")

local Vec2 = require("Vector2")
local Color = require("Color")
local MainCanvas = require("MainCanvas")
local GridBackground = require("GridBackground")
local Text = require("Text")

love.graphics.setDefaultFilter("nearest", "nearest")

-- Globals
_WINDOW_SIZE = Vec2(1280, 720)
_DRAW_TIME = 0
_FONT_CHARACTERS = " abcdefghijklmnopqrstuvwxyząćęłńóśźżABCDEFGHIJKLMNOPQRSTUVWXYZĄĆĘŁŃÓŚŹŻ0123456789<>-+()[]_.,:;'!?@#$€%^&*\"/|\\"
_FONT = love.graphics.newImageFont("standard.png", _FONT_CHARACTERS, 1)

_CANVAS = MainCanvas()
_BACKGROUND = GridBackground()
_COLOR1 = Color(0.3, 1, 0.3)
_COLOR2 = Color(0.1, 0.6, 0.1)
_TEXT = Text(_FONT, "Let's write some code!", Vec2(50, 50), 1, nil, true)
_TEXT2 = Text(_FONT, "Chain Blast", Vec2(50, 100), 2, _COLOR1, true)
_TEXT:setWave(5, 80, 60)
--_TEXT2:setWave(4, 300, 100)
_TEXT2:setGradientWave(_COLOR2, 100, 50)



function love.load()
	love.window.setMode(_WINDOW_SIZE.x, _WINDOW_SIZE.y)
end



function love.update(dt)
	_BACKGROUND:update(dt)
	_TEXT:update(dt)
	_TEXT2:update(dt)
end



function love.draw()
	local t = love.timer.getTime()
	_CANVAS:activate()
	_BACKGROUND:draw()
	_TEXT:draw()
	_TEXT2:draw()
	_CANVAS:draw()
	local t2 = love.timer.getTime() - t
	_DRAW_TIME = _DRAW_TIME * 0.95 + t2 * 0.05
	love.graphics.print(string.format("Drawing took approximately %.1fms", _DRAW_TIME * 1000))
end