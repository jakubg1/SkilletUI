_Utils = require("com.utils")

local Vec2 = require("Vector2")
local Color = require("Color")
local Image = require("Image")
local NineImage = require("NineImage")
local MainCanvas = require("MainCanvas")
local GridBackground = require("GridBackground")
local TransitionTest = require("TransitionTest")
local Editor = require("Editor")
local Node = require("Node")

love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setLineStyle("rough")
love.graphics.setBackgroundColor(0.2, 0.5, 0.9)

-- Globals
_VEC2S_PER_FRAME = 0
_WINDOW_SIZE = Vec2(1600, 900)
_CANVAS_SIZE = Vec2(960, 540)
_CANVAS_OFFSET = Vec2(220, 40)
_MousePos = Vec2()
_MouseCPos = Vec2()

_DrawTime = 0
_FONT_CHARACTERS = " abcdefghijklmnopqrstuvwxyząćęłńóśźżABCDEFGHIJKLMNOPQRSTUVWXYZĄĆĘŁŃÓŚŹŻ0123456789<>-+()[]_.,:;'!?@#$€%^&*\"/|\\"
_FONTS = {
	default = love.graphics.newFont(),
	editor = love.graphics.newFont(14),
	standard = love.graphics.newImageFont("resources/standard.png", _FONT_CHARACTERS, 1)
}
_FONT_LOOKUP = {}
_IMAGES = {
	button = NineImage("resources/button.png", 2, 3, 3, 4),
	button_hover = NineImage("resources/button_hover.png", 2, 3, 3, 4),
	button_click = NineImage("resources/button_click.png", 2, 3, 3, 4),
	ed_button = NineImage("resources/ed_button.png", 2, 3, 2, 3),
	ed_button_click = NineImage("resources/ed_button_click.png", 2, 3, 2, 3),
	ed_input = NineImage("resources/ed_input.png", 2, 3, 2, 3),
	ed_input_hover = NineImage("resources/ed_input_hover.png", 2, 3, 2, 3),
	ed_input_disabled = NineImage("resources/ed_input_disabled.png", 2, 3, 2, 3),
	widget_box = Image("resources/widget_box.png"),
	widget_button = Image("resources/widget_button.png"),
	widget_canvas = Image("resources/widget_canvas.png"),
	widget_ninesprite = Image("resources/widget_ninesprite.png"),
	widget_none = Image("resources/widget_none.png"),
	widget_text = Image("resources/widget_text.png"),
	widget_titledigit = Image("resources/widget_titledigit.png")
}
_IMAGE_LOOKUP = {}
_COLORS = {
	white = Color(1, 1, 1),
	gray = Color(0.5, 0.5, 0.5),
	black = Color(0, 0, 0),
	blue = Color(0, 0, 1),
	cyan = Color(0, 1, 1),
	yellow = Color(1, 1, 0),
	red = Color(1, 0, 0),
	orange = Color(1, 0.4, 0),
	lightOrange = Color(1, 0.7, 0.5),
	purple = Color(0.4, 0, 1),
	lightPurple = Color(0.7, 0.5, 1)
}
_ALIGNMENTS = {
    topLeft = Vec2(0, 0),
    top = Vec2(0.5, 0),
    topRight = Vec2(1, 0),
    left = Vec2(0, 0.5),
    center = Vec2(0.5, 0.5),
    right = Vec2(1, 0.5),
    bottomLeft = Vec2(0, 1),
    bottom = Vec2(0.5, 1),
    bottomRight = Vec2(1, 1)
}

_CANVAS = MainCanvas()
_BACKGROUND = GridBackground()
_TRANSITION = TransitionTest()
_EDITOR = Editor()



function _PrepareResourceLookups()
	for fontName, font in pairs(_FONTS) do
		_FONT_LOOKUP[font] = fontName
	end
	for imageName, image in pairs(_IMAGES) do
		_IMAGE_LOOKUP[image] = imageName
	end
end



function _IsCtrlPressed()
	return love.keyboard.isDown("lctrl", "rctrl")
end



function _IsShiftPressed()
	return love.keyboard.isDown("lshift", "rshift")
end



function _LoadUI(path)
	local data = _Utils.loadJson(path)
	return Node(data)
end



function love.load()
	love.window.setMode(_WINDOW_SIZE.x, _WINDOW_SIZE.y)
	_PrepareResourceLookups()
	_UI = _LoadUI("ui.json")
	_UI:findChildByName("btn1"):setOnClick(function ()
		if _TRANSITION.state then
			_TRANSITION:hide()
		else
			_TRANSITION:show()
		end
	end)
	_EDITOR:load()
end



function love.update(dt)
	-- Mouse position
	_MousePos = Vec2(love.mouse.getPosition())
	_MouseCPos = _CANVAS:posToPixel(_MousePos)

	-- Main update
	_BACKGROUND:update(dt)
	_TRANSITION:update(dt)
	_UI:update(dt)
	_EDITOR:update(dt)
end



function love.draw()
	_VEC2S_PER_FRAME = 0
	local t = love.timer.getTime()
	_CANVAS:activate()
	-- Start of main drawing routine
	if not _EDITOR.enabled then
		_BACKGROUND:draw()
	end
	_UI:draw()
	_EDITOR:drawUIPass()
	_TRANSITION:draw()
	-- End of main drawing routine
	_CANVAS:draw()
	_EDITOR:draw()
	local t2 = love.timer.getTime() - t
	_DrawTime = _DrawTime * 0.95 + t2 * 0.05
end



function love.mousepressed(x, y, button)
	if not _EDITOR.enabled then
		_UI:mousepressed(x, y, button)
	end
	_EDITOR:mousepressed(x, y, button)
end



function love.mousereleased(x, y, button)
	if not _EDITOR.enabled then
		_UI:mousereleased(x, y, button)
	end
	_EDITOR:mousereleased(x, y, button)
end



function love.wheelmoved(x, y)
	_EDITOR:wheelmoved(x, y)
end



function love.keypressed(key)
	if not _EDITOR.enabled then
		_UI:keypressed(key)
	end
	_EDITOR:keypressed(key)
end



function love.textinput(text)
	_EDITOR:textinput(text)
end