local class = require "com.class"

---@class Project
---@overload fun(path: string?):Project
local Project = class:derive("Project")

-- Place your imports here
local Vec2 = require("Vector2")
local Node = require("Node")
local Timeline = require("Timeline")

---Constructs a new Project.
---Projects contain some settings and the currently loaded UI layout loaded to it.
---They also store a list of Timelines.
---@param path string? The path to the project folder. If not specified, an empty project will be created.
function Project:new(path)
    self.path = path

    self.ui = nil
    self.currentLayout = nil
    self.layoutModified = false

    self.timelines = {
        test = Timeline()
    }
    self.currentTimeline = "test"

    local data = {
        nativeResolution = {x = 320, y = 180}
    }
    self.nativeResolution = Vec2(data.nativeResolution)
    _CANVAS:setResolution(self.nativeResolution)
end

--##########################################--
---------------- L A Y O U T S ---------------
--##########################################--

---Erases the current UI layout and replaces it with an empty one.
function Project:newLayout()
    self.ui = Node({name = "root", canvasInputMode = true})
    self.currentLayout = nil
    self.layoutModified = false
end

---Loads a UI layout from this Project.
---@param name string The name of this layout, including `.json`.
function Project:loadLayout(name)
    self.ui = Node(_Utils.loadJson(self:getLayoutDirectory() .. "/" .. name))
    self.currentLayout = name
    self.layoutModified = false
end

---Saves the current UI layout.
---@param name string The name of this layout, including `.json`.
function Project:saveLayout(name)
    _Utils.saveJson(self:getLayoutDirectory() .. "/" .. name, self.ui:serialize())
    self.currentLayout = name
    self.layoutModified = false
end

---Returns the current UI layout.
---@return Node?
function Project:getCurrentLayout()
    return self.ui
end

---Returns this project's directory where layouts are stored.
---@return string
function Project:getLayoutDirectory()
    return self.path .. "/layouts"
end

---Returns the current layout name, or `nil` if no layout is loaded.
---@return string?
function Project:getLayoutName()
    return self.currentLayout
end

---Marks the current layout as modified.
function Project:markLayoutAsModified()
    self.layoutModified = true
end

---Returns whether this layout is modified (unsaved).
---@return boolean
function Project:isLayoutModified()
    return self.layoutModified
end

--##############################################--
---------------- T I M E L I N E S ---------------
--##############################################--

---Plays the specified Timeline.
---@param name string The name of the Timeline to be played.
function Project:playTimeline(name)
    self.timelines[name]:play()
end

---Stops the specified Timeline from playing and resets all widget properties.
---@param name string The name of the Timeline to be stopped.
function Project:stopTimeline(name)
    self.timelines[name]:stop()
    self.ui:resetProperties()
end

---Returns the specified Timeline.
---@param name string The name of the Timeline to be returned.
---@return Timeline?
function Project:getTimeline(name)
    return self.timelines[name]
end

---Returns the current Timeline, if any exists.
---@return Timeline?
function Project:getCurrentTimeline()
    return self.timelines[self.currentTimeline]
end

--######################################--
---------------- O T H E R ---------------
--######################################--

---Updates the Project's components: layout and all timelines.
---@param dt number Time delta, in seconds.
function Project:update(dt)
    if self.ui then
        self.ui:update(dt)
    end
    for name, timeline in pairs(self.timelines) do
        timeline:update(dt)
    end
end

---Draws the Project's UI on the screen.
function Project:draw()
    if self.ui then
        self.ui:draw()
    end
end

---Executed whenever a mouse button is pressed anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
---@param istouch boolean Whether the press is coming from a touch input.
---@param presses integer How many clicks have been performed in a short amount of time. Useful for double click checks.
function Project:mousepressed(x, y, button, istouch, presses)
    if self.ui then
        self.ui:mousepressed(x, y, button, istouch, presses)
    end
end

---Executed whenever a mouse button is released anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function Project:mousereleased(x, y, button)
    if self.ui then
        self.ui:mousereleased(x, y, button)
    end
end

---Executed whenever a key is pressed on the keyboard.
---@param key string The key code.
function Project:keypressed(key)
    if self.ui then
        self.ui:keypressed(key)
    end
end

return Project