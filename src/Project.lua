local class = require "com.class"

---@class Project
---@overload fun(path: string?):Project
local Project = class:derive("Project")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")
local PropertyList = require("src.PropertyList")
local Node = require("src.Node")
local Timeline = require("src.Timeline")

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

    self.PROPERTY_LIST = {
        {name = "Native Resolution", key = "nativeResolution", type = "Vector2", defaultValue = Vec2(320, 180)},
        {name = "Grid Size", key = "gridSize", type = "Vector2", nullable = true},
        {name = "Snap to Grid", key = "gridSnap", type = "boolean", defaultValue = true},
        {name = "Grid Visible", key = "gridVisible", type = "boolean", defaultValue = false}
    }
    self.properties = PropertyList(self.PROPERTY_LIST)

    local data = _Utils.loadJson(path .. "/settings.json")
    assert(data, "Could not load project data from " .. path .. "/settings.json")
    self:deserialize(data)
end

--######################################--
---------------- B A S I C ---------------
--######################################--

---Returns the current project's name. Currently, this is derived from its path.
---@return string
function Project:getName()
    return _Utils.strSplit(self.path, "/")[2]
end

--##########################################--
---------------- L A Y O U T S ---------------
--##########################################--

---Erases the current UI layout and replaces it with an empty one.
function Project:newLayout()
    local size = self:getProperty("nativeResolution")
    self.ui = Node({name = "root", type = "box", widget = {size = {size.x, size.y}}, canvasInputMode = true})
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

---Returns all layout names in this project. The names include the `.json` extension.
---@return table
function Project:getLayoutList()
    return _Utils.getDirListing(self:getLayoutDirectory(), "file", ".json", false)
end

---Returns the current layout name, or `nil` if no layout is loaded. The name includes the `.json` extension.
---@return string?
function Project:getLayoutName()
    return self.currentLayout
end

---Marks the current layout as modified or not modified.
---@param layoutModified boolean Whether the layout should be marked as modified (`true`) or not (`false`).
function Project:setLayoutModified(layoutModified)
    self.layoutModified = layoutModified
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
    if self.ui then
        self.ui:resetProperties()
    end
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

--############################################--
---------------- S E T T I N G S ---------------
--############################################--

---Returns the given property of this Project.
---@param key string The property key.
---@return any?
function Project:getProperty(key)
    return self.properties:getValue(key)
end

---Sets the given property of this Project to a given value.
---@param key string The property key.
---@param value any? The property value.
function Project:setProperty(key, value)
    self.properties:setBaseValue(key, value)
end

---Returns the property list manifest for use in the editor's property UI generator.
---@return table
function Project:getPropertyList()
    return self.PROPERTY_LIST
end

---Returns the native resolution of this Project.
---@return Vector2
function Project:getNativeResolution()
    return self:getProperty("nativeResolution")
end

---Returns the current grid size, or `nil` if the grid is disabled.
---@return Vector2?
function Project:getGridSize()
    local gridSize = self:getProperty("gridSize")
    if not gridSize or gridSize.x == 0 or gridSize.y == 0 then
        -- Prevent an infinite loop :>
        return nil
    end
    return gridSize
end

---Returns whether the Snap to Grid is enabled for this Project.
---@return boolean
function Project:isSnapToGridEnabled()
    return self:getProperty("gridSnap")
end

---Returns whether the grid is visible.
---@return boolean
function Project:isGridVisible()
    return self:getProperty("gridVisible")
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

--######################################################--
---------------- S E R I A L I Z A T I O N ---------------
--######################################################--

---Loads the project's properties from the given data.
---@param data table The project properties.
function Project:deserialize(data)
    self.properties:deserialize(data)

    _CANVAS:setResolution(self:getProperty("nativeResolution"))
end

return Project