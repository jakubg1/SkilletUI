_Utils = require("com.utils")

local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")
local MainCanvas = require("src.MainCanvas")
local TransitionTest = require("src.TransitionTest")
local ResourceManager = require("src.ResourceManager")
local Project = require("src.Project")
local Editor = require("src.Editor.Editor")

love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setLineStyle("rough")
love.graphics.setBackgroundColor(0.2, 0.5, 0.9)

-- Globals
_VEC2S_PER_FRAME = 0
_WINDOW_SIZE = Vec2(1600, 900)
_Time = 0
_MousePos = Vec2()
_MouseCPos = Vec2()
_Debug = false

_DrawTime = 0

-- credit: SoundsDotZip
_COLORS = {
	black = Color("000"),
	dark_gray = Color("333"),
	gray = Color("777"),
	light_gray = Color("bbb"),
	white = Color("fff"),
	light_blue = Color("5ce"), cyan = Color("5ce"),
	blue = Color("37b"),
	dark_blue = Color("236"),
	dark_green = Color("154"),
	green = Color("395"),
	light_green = Color("7c5"), lime = Color("7c5"),
	yellow = Color("ed5"),
	orange = Color("e84"),
	red = Color("c34"),
	dark_red = Color("724"),
	dark_purple = Color("526"),
	purple = Color("949"),
	pink = Color("e79"),
	beige = Color("fb9"), tan = Color("fb9"),
	brown = Color("943"),

	e_blue = Color("00f"),
	e_bblue = Color("8cf"),
	e_cyan = Color("0ff"),
	e_yellow = Color("ff0")
}
_COLOR_ORDER = {
	"black", "dark_gray", "gray", "light_gray", "white",
	"light_blue", "blue", "dark_blue", "dark_green", "green",
	"light_green", "yellow", "orange", "red", "dark_red",
	"dark_purple", "purple", "pink", "beige", "brown"
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
_TRANSITION = TransitionTest()
_RESOURCE_MANAGER = ResourceManager()
---@type Project?
_PROJECT = nil
--_EDITOR = nil
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
	_PROJECT = Project(name)
end



---Loads a runtime by loading the project and layout from the runtime.json file.
---If that file does not exist, does nothing.
function _LoadRuntime()
	local runtime = _Utils.loadJson("runtime.json")
	if not runtime then
		return
	end
	_LoadProject(runtime.lastProject)
	_PROJECT:openLayout(runtime.lastLayout)
end

---Saves a runtime by saving the currently opened project and layout.
function _SaveRuntime()
	local runtime = {lastProject = _PROJECT:getName(), lastLayout = _PROJECT:getLayoutName()}
	_Utils.saveJson("runtime.json", runtime)
end



---Executed whenever a signal is fired by a Node.
---TODO: Move that somewhere else. UI Script, perhaps. Remember about sandboxing...
---TODO: Maybe signals should be more than simple strings. A command name, and then some parameters? Like "loadLayout", "welcome" would be hardwired.
---@param name string The signal name.
function _OnSignal(name)
	if name == "main" then
		_PROJECT:openLayout("welcome")
	elseif name == "page1" then
		_PROJECT:openLayout("todo")
	elseif name == "page2" then
		_PROJECT:openLayout("todo2")
	elseif name == "page3" then
		_PROJECT:openLayout("todo3")
	elseif name == "page4" then
		_PROJECT:openLayout("todo4")
	elseif name == "dive1" then
		_PROJECT:openLayout("dive1")
	elseif name == "dive2" then
		_PROJECT:openLayout("dive2")
	elseif name == "dive3" then
		_PROJECT:openLayout("dive3")
	elseif name == "dive4" then
		_PROJECT:openLayout("dive4")
	elseif name == "dive5" then
		_PROJECT:openLayout("dive5")
	elseif name == "dive6" then
		_PROJECT:openLayout("dive6")
	elseif name == "dive7" then
		_PROJECT:openLayout("dive7")
	elseif name == "dive8" then
		_PROJECT:openLayout("dive8")
	elseif name == "dive9" then
		_PROJECT:openLayout("dive9")
	elseif name == "dive10" then
		_PROJECT:openLayout("dive10")
	elseif name == "transition" then
		if _TRANSITION.state then
			_TRANSITION:hide()
		else
			_TRANSITION:show()
		end
	end
end



---Acts as `love.graphics.setColor()` but takes a Color instance as an argument.
---@param color Color The color to be changed to.
---@param alpha number? Transparency. 1 is default.
function _SetColor(color, alpha)
	love.graphics.setColor(color.r, color.g, color.b, alpha or 1)
end



function love.load()
	_RESOURCE_MANAGER:init()
	_LoadRuntime()
	if _EDITOR then
		_EDITOR:load()
		_EDITOR.canvasMgr:fitZoom()
	end
end

function love.update(dt)
	-- Global time
	_Time = _Time + dt

	-- Mouse position
	_MousePos = Vec2(love.mouse.getPosition())
	_MouseCPos = _CANVAS:posToPixel(_MousePos)

	-- Main update
	_TRANSITION:update(dt)
	_PROJECT:update(dt)
	if _EDITOR then
		_EDITOR:update(dt)
	end
end

function love.draw()
	local t = love.timer.getTime()
	if _EDITOR then
		_EDITOR:drawUnderCanvas()
	end
	_CANVAS:activate()
	-- Start of main drawing routine
	_PROJECT:draw()
	_TRANSITION:draw()
	-- End of main drawing routine
	_CANVAS:draw()
	if _EDITOR then
		_EDITOR:drawUIPass()
		_EDITOR:draw()
	end
	local t2 = love.timer.getTime() - t
	_DrawTime = _DrawTime * 0.95 + t2 * 0.05
end

function love.mousepressed(x, y, button, istouch, presses)
	if not _EDITOR or not _EDITOR.enabled then
		_PROJECT:mousepressed(x, y, button, istouch, presses)
	end
	if _EDITOR then
		_EDITOR:mousepressed(x, y, button, istouch, presses)
	end
end

function love.mousereleased(x, y, button)
	if not _EDITOR or not _EDITOR.enabled then
		_PROJECT:mousereleased(x, y, button)
	end
	if _EDITOR then
		_EDITOR:mousereleased(x, y, button)
	end
end

function love.wheelmoved(x, y)
	if _EDITOR then
		_EDITOR:wheelmoved(x, y)
	end
end

function love.keypressed(key)
	if key == "f12" then
		_Debug = not _Debug
	end
	if not _EDITOR or not _EDITOR.enabled then
		_PROJECT:keypressed(key)
	end
	if _EDITOR then
		_EDITOR:keypressed(key)
	end
end

function love.textinput(text)
	if _EDITOR then
		_EDITOR:textinput(text)
	end
end

function love.resize(w, h)
	_WINDOW_SIZE = Vec2(w, h)
	if _EDITOR then
		_EDITOR:resize(w, h)
	end
end

function love.quit()
	_SaveRuntime()
end