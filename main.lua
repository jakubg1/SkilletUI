_Utils = require("com.utils")

local Vec2 = require("Vector2")
local Color = require("Color")
local MainCanvas = require("MainCanvas")
local GridBackground = require("GridBackground")
local TransitionTest = require("TransitionTest")
local ResourceManager = require("ResourceManager")
local Project = require("Project")
local Editor = require("Editor")

love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setLineStyle("rough")
love.graphics.setBackgroundColor(0.2, 0.5, 0.9)

-- Globals
_VEC2S_PER_FRAME = 0
_WINDOW_SIZE = Vec2(1600, 900)
_Time = 0
_MousePos = Vec2()
_MouseCPos = Vec2()

_DrawTime = 0
_COLORS = {
	white = Color("fff"),
	gray = Color("888"),
	black = Color("000"),
	blue = Color("00f"),
	cyan = Color("0ff"),
	green = Color("0f0"),
	yellow = Color("ff0"),
	red = Color("f00"),
	orange = Color("f60"),
	lightOrange = Color("fb8"),
	purple = Color("60f"),
	lightPurple = Color("b8f")
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
_RESOURCE_MANAGER = ResourceManager()
---@type Project?
_PROJECT = nil
_EDITOR = Editor()



function _IsCtrlPressed()
	return love.keyboard.isDown("lctrl", "rctrl")
end

function _IsShiftPressed()
	return love.keyboard.isDown("lshift", "rshift")
end



---Loads a project from the `projects/<name>` folder.
---@param name string The project name.
function _LoadProject(name)
	_PROJECT = Project("projects/" .. name)
end



---Executed whenever a signal is fired by a Node.
---TODO: Move that somewhere else. UI Script, perhaps. Remember about sandboxing...
---TODO: Maybe signals should be more than simple strings. A command name, and then some parameters? Like "loadLayout", "welcome" would be hardwired.
---@param name string The signal name.
function _OnSignal(name)
	if name == "main" then
		_PROJECT:loadLayout("welcome.json")
	elseif name == "page1" then
		_PROJECT:loadLayout("todo.json")
	elseif name == "page2" then
		_PROJECT:loadLayout("todo2.json")
	elseif name == "page3" then
		_PROJECT:loadLayout("todo3.json")
	elseif name == "page4" then
		_PROJECT:loadLayout("todo4.json")
	elseif name == "dive1" then
		_PROJECT:loadLayout("dive1.json")
	elseif name == "dive2" then
		_PROJECT:loadLayout("dive2.json")
	elseif name == "dive3" then
		_PROJECT:loadLayout("dive3.json")
	elseif name == "dive4" then
		_PROJECT:loadLayout("dive4.json")
	elseif name == "dive5" then
		_PROJECT:loadLayout("dive5.json")
	elseif name == "dive6" then
		_PROJECT:loadLayout("dive6.json")
	elseif name == "dive7" then
		_PROJECT:loadLayout("dive7.json")
	elseif name == "dive8" then
		_PROJECT:loadLayout("dive8.json")
	elseif name == "dive9" then
		_PROJECT:loadLayout("dive9.json")
	elseif name == "dive10" then
		_PROJECT:loadLayout("dive10.json")
	elseif name == "transition" then
		if _TRANSITION.state then
			_TRANSITION:hide()
		else
			_TRANSITION:show()
		end
	end
end



function love.load()
	_RESOURCE_MANAGER:init()
	_EDITOR:load()
	_LoadProject("Demo")
	_PROJECT:loadLayout("welcome.json")
end



function love.update(dt)
	-- Global time
	_Time = _Time + dt

	-- Mouse position
	_MousePos = Vec2(love.mouse.getPosition())
	_MouseCPos = _CANVAS:posToPixel(_MousePos)

	-- Main update
	_BACKGROUND:update(dt)
	_TRANSITION:update(dt)
	_PROJECT:update(dt)
	_EDITOR:update(dt)
end



function love.draw()
	local t = love.timer.getTime()
	_CANVAS:activate()
	-- Start of main drawing routine
	if not _EDITOR.enabled and _EDITOR.canvasMgr.background then
		_BACKGROUND:draw()
	end
	_PROJECT:draw()
	_TRANSITION:draw()
	-- End of main drawing routine
	_CANVAS:draw()
	_EDITOR:drawUIPass()
	_EDITOR:draw()
	local t2 = love.timer.getTime() - t
	_DrawTime = _DrawTime * 0.95 + t2 * 0.05
end



function love.mousepressed(x, y, button, istouch, presses)
	if not _EDITOR.enabled then
		_PROJECT:mousepressed(x, y, button, istouch, presses)
	end
	_EDITOR:mousepressed(x, y, button, istouch, presses)
end



function love.mousereleased(x, y, button)
	if not _EDITOR.enabled then
		_PROJECT:mousereleased(x, y, button)
	end
	_EDITOR:mousereleased(x, y, button)
end



function love.wheelmoved(x, y)
	_EDITOR:wheelmoved(x, y)
end



function love.keypressed(key)
	if not _EDITOR.enabled then
		_PROJECT:keypressed(key)
	end
	_EDITOR:keypressed(key)
end



function love.textinput(text)
	_EDITOR:textinput(text)
end



function love.resize(w, h)
	_WINDOW_SIZE = Vec2(w, h)
	_EDITOR:resize(w, h)
end