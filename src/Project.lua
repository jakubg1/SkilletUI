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

    self.layouts = {}
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
    self:loadLayouts()
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

---Returns the names of all layouts in this project, sorted alphabetically.
---The names do not have the `.json` extension.
---
---This function sources names directly from the project directory.
---Use `:getLayoutList()` instead!
---@return table
function Project:getLayoutFileList()
    local names = _Utils.getDirListing(self:getLayoutDirectory(), "file", ".json", false)
    for i, name in ipairs(names) do
        -- Strip the `.json` extension.
        names[i] = name:sub(1, name:len() - 5)
    end
    table.sort(names)
    return names
end

--##########################################--
---------------- L A Y O U T S ---------------
--##########################################--

---Adds the provided Layout to the project layout list and sets it as the current layout.
---@param layout ProjectLayout The layout to be added.
function Project:addLayoutAndSetAsCurrent(layout)
    local name = layout:getName()
    self.layouts[name] = layout
    self.currentLayout = name
end

---Creates a new empty layout and sets it as the current layout.
---The new layout is named `layout` by default, or if that name already exists, `layout#2`, `layout#3`, etc.
function Project:newLayout()
    self:addLayoutAndSetAsCurrent(ProjectLayout(self))
end

---Loads all layouts from this Project's directory.
function Project:loadLayouts()
    local names = self:getLayoutFileList()
    for i, name in ipairs(names) do
        self.layouts[name] = ProjectLayout(self, name)
    end
end

---Sets a layout as the current layout.
---@param name string The name of the layout, excluding `.json`.
function Project:openLayout(name)
    self.currentLayout = name
end

---Saves the current UI layout.
---@param name string The name of this layout, excluding `.json`.
function Project:saveLayout(name)
    self:getCurrentLayout():save(name)
end

---Saves all UI layouts and deletes files corresponding to removed layouts.
---Also, saves the project configuration.
function Project:save()
    for name, layout in pairs(self.layouts) do
        if layout:isModified() then
            layout:save()
        end
    end
    _Utils.saveJson(self:getSettingsPath(), self:serialize())
end

---Renames the current layout.
---Returns `false` if the name is illegal, another layout already has this name or no layout is loaded.
---@param name string The new name for the current layout.
function Project:renameCurrentLayout(name)
    if name == "" or self.layouts[name] or not self.currentLayout then
        return false
    end
    local layout = assert(self:getCurrentLayout())
    self.layouts[layout:getName()] = nil
    layout:setName(name)
    self.layouts[name] = layout
    self.currentLayout = name
end

---Deletes the current UI layout from this Project.
function Project:deleteCurrentLayout()
    if not self.currentLayout then
        return
    end
    self.layouts[self.currentLayout] = nil
    self.currentLayout = nil
end

---Creates a copy of the currently active UI layout.
function Project:duplicateCurrentLayout()
    if not self.currentLayout then
        return
    end
    self:addLayoutAndSetAsCurrent(self:getCurrentLayout():copy())
end

---Returns whether the layout of the given name exists.
---@param name string The name of the layout, excluding `.json`.
---@return boolean
function Project:hasLayout(name)
    return self.layouts[name] ~= nil
end

---Returns a layout of given name.
---If the layout does not exist, returns `nil`.
---@param name string The name of the layout, excluding `.json`.
---@return ProjectLayout?
function Project:getLayout(name)
    return self.layouts[name]
end

---Returns the current layout, or `nil` if no layout is loaded.
---@return ProjectLayout?
function Project:getCurrentLayout()
    return self.layouts[self.currentLayout]
end

---Returns the root node of the current layout, or `nil` if no layout is loaded.
---@return Node?
function Project:getCurrentLayoutUI()
    if not self.currentLayout then
        return nil
    end
    return self:getCurrentLayout():getUI()
end

---Returns the names of all layouts in this project, sorted alphabetically.
---@return table
function Project:getLayoutNameList()
    return _Utils.tableGetSortedKeys(self.layouts)
end

---Returns the current layout name, or `nil` if no layout is loaded.
---@return string?
function Project:getLayoutName()
    if not self.currentLayout then
        return nil
    end
    return self:getCurrentLayout():getName()
end

---Returns whether the current layout is modified (unsaved), or `nil` if no layout is loaded.
---@return boolean?
function Project:isLayoutModified()
    if not self.currentLayout then
        return nil
    end
    return self:getCurrentLayout():isModified()
end

---Marks the current layout as modified or not modified.
---@param modified boolean Whether the layout should be marked as modified (`true`) or not (`false`).
function Project:setLayoutModified(modified)
    self:getCurrentLayout():setModified(modified)
end

---If the layout of the provided name already exists, generates a `#N` suffix to ensure the names don't repeat.
---Returns the modified name, or the provided name without any modifications if that name is not taken.
---@param name string The name to be checked for.
---@return string
function Project:generateUniqueLayoutName(name)
    name = name:gsub("%#%d+$", "") -- Removes #N
    local currentName = name
    local suffixNumber = 2
    while self.layouts[currentName] do
        currentName = name .. "#" .. suffixNumber
        suffixNumber = suffixNumber + 1
    end
    return currentName
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
        self:getCurrentLayout():getUI():resetProperties()
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
        self:getCurrentLayout():update(dt)
    end
    for name, timeline in pairs(self.timelines) do
        timeline:update(dt)
    end
end

---Draws the Project's UI on the screen.
function Project:draw()
    if self.currentLayout then
        self:getCurrentLayout():draw()
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
        self:getCurrentLayout():mousepressed(x, y, button, istouch, presses)
    end
end

---Executed whenever a mouse button is released anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function Project:mousereleased(x, y, button)
    if self.currentLayout then
        self:getCurrentLayout():mousereleased(x, y, button)
    end
end

---Executed whenever a key is pressed on the keyboard.
---@param key string The key code.
function Project:keypressed(key)
    if self.currentLayout then
        self:getCurrentLayout():keypressed(key)
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

---Returns data for this Project which can be saved on disk and loaded later with `:deserialize()`.
---@return table
function Project:serialize()
    return self.properties:serialize()
end

return Project