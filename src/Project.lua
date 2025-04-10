local class = require "com.class"

---@class Project
---@overload fun(name: string?):Project
local Project = class:derive("Project")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")
local PropertyList = require("src.PropertyList")
local ProjectLayout = require("src.ProjectLayout")
local Timeline = require("src.Timeline")

---Constructs a new Project.
---Projects contain some settings and the currently loaded UI layout loaded to it.
---They also store a list of Timelines.
---@param name string The name of the project (and its folder in the `projects/` directory). If the specified directory doesn't exist, a new empty project will be created.
function Project:new(name)
    self.name = name

    self.currentLayout = nil

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

    local path = assert(self:getSettingsPath())
    local data = assert(_Utils.loadJson(path), "Could not load project data from " .. path)
    self:deserialize(data)
end

--######################################--
---------------- B A S I C ---------------
--######################################--

---Returns the current project's name. Currently, this is derived from its path.
---@return string
function Project:getName()
    return self.name
end

--################################################--
---------------- F I L E S Y S T E M ---------------
--################################################--

---Returns the complete path to this Project's directory, starting from the root program directory.
---The returned path contains a trailing `/` character.
---@return string
function Project:getPath()
    return "projects/" .. self.name .. "/"
end

---Returns the complete path to this Project's `settings.json` file, starting from the root program directory.
---@return string
function Project:getSettingsPath()
    return self:getPath() .. "settings.json"
end

---Returns this project's directory where layouts are stored. The returned path contains a trailing `/` character.
---@return string
function Project:getLayoutDirectory()
    return self:getPath() .. "layouts/"
end

--##########################################--
---------------- L A Y O U T S ---------------
--##########################################--

---Erases the current UI layout and replaces it with an empty one.
function Project:newLayout()
    self.currentLayout = ProjectLayout(self)
end

---Loads a UI layout from this Project.
---@param name string The name of this layout, excluding `.json`.
function Project:loadLayout(name)
    self.currentLayout = ProjectLayout(self, name)
end

---Saves the current UI layout.
---@param name string The name of this layout, excluding `.json`.
function Project:saveLayout(name)
    self.currentLayout:save(name)
end

---Returns the root node of the current layout, or `nil` if no layout is loaded.
---@return Node?
function Project:getCurrentLayout()
    if not self.currentLayout then
        return nil
    end
    return self.currentLayout:getUI()
end

---Returns the names of all layouts in this project, sorted alphabetically.
---@return table
function Project:getLayoutList()
    local names = _Utils.getDirListing(self:getLayoutDirectory(), "file", ".json", false)
    for i, name in ipairs(names) do
        -- Strip the `.json` extension.
        names[i] = name:sub(1, name:len() - 5)
    end
    table.sort(names)
    return names
end

---Returns the current layout name, or `nil` if no layout is loaded.
---@return string?
function Project:getLayoutName()
    if not self.currentLayout then
        return nil
    end
    return self.currentLayout:getName()
end

---Marks the current layout as modified or not modified.
---@param modified boolean Whether the layout should be marked as modified (`true`) or not (`false`).
function Project:setLayoutModified(modified)
    self.currentLayout:setModified(modified)
end

---Returns whether the current layout is modified (unsaved), or `nil` if no layout is loaded.
---@return boolean?
function Project:isLayoutModified()
    if not self.currentLayout then
        return nil
    end
    return self.currentLayout:isModified()
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
    if self.currentLayout then
        self.currentLayout:getUI():resetProperties()
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

--##############################################--
---------------- C A L L B A C K S ---------------
--##############################################--

---Updates the Project's components: layout and all timelines.
---@param dt number Time delta, in seconds.
function Project:update(dt)
    if self.currentLayout then
        self.currentLayout:update(dt)
    end
    for name, timeline in pairs(self.timelines) do
        timeline:update(dt)
    end
end

---Draws the Project's UI on the screen.
function Project:draw()
    if self.currentLayout then
        self.currentLayout:draw()
    end
end

---Executed whenever a mouse button is pressed anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
---@param istouch boolean Whether the press is coming from a touch input.
---@param presses integer How many clicks have been performed in a short amount of time. Useful for double click checks.
function Project:mousepressed(x, y, button, istouch, presses)
    if self.currentLayout then
        self.currentLayout:mousepressed(x, y, button, istouch, presses)
    end
end

---Executed whenever a mouse button is released anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function Project:mousereleased(x, y, button)
    if self.currentLayout then
        self.currentLayout:mousereleased(x, y, button)
    end
end

---Executed whenever a key is pressed on the keyboard.
---@param key string The key code.
function Project:keypressed(key)
    if self.currentLayout then
        self.currentLayout:keypressed(key)
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