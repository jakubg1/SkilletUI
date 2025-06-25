local class = require "com.class"

---@class Project
---@overload fun(name: string?):Project
local Project = class:derive("Project")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")
local PropertyList = require("src.PropertyList")
local ProjectLayout = require("src.ProjectLayout")

---Constructs a new Project.
---Projects contain all UI layouts belonging to it and some settings.
---@param name string The name of the project (and its folder in the `projects/` directory). If the specified directory doesn't exist, a new empty project will be created.
function Project:new(name)
    self.name = name

    ---@type {string: ProjectLayout}
    self.layouts = {}

    self.PROPERTY_LIST = {
        {name = "Native Resolution", key = "nativeResolution", type = "Vector2", defaultValue = Vec2(320, 180)},
        {name = "Grid Size", key = "gridSize", type = "Vector2", nullable = true},
        {name = "Snap to Grid", key = "gridSnap", type = "boolean", defaultValue = true},
        {name = "Grid Visible", key = "gridVisible", type = "boolean", defaultValue = false, description = "Toggles the visibility of the grid.\nYou need to set a grid size in order for the grid to show up.\n\nHotkey: G"},
        {name = "Guides Visible", key = "guidesVisible", type = "boolean", defaultValue = true, description = "Toggles the visibility of guides (crosshairs and lines of selected Nodes) on or off.\nThe guides will show up regardless while a node is being dragged, but hopefully that's\nmuch less annoying.\n\nHotkey: Q"}
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
        names[i] = _Utils.pathStripExtension(name)
    end
    table.sort(names)
    return names
end

--##########################################--
---------------- L A Y O U T S ---------------
--##########################################--

---Creates a new empty layout of the given name.
---Returns `true` if the operation succeeds, `false` otherwise.
---@param name string The name of the new layout.
function Project:newLayout(name)
    if self.layouts[name] then
        return false -- Name is already taken by a different layout.
    end
    self.layouts[name] = ProjectLayout(self, name, true)
end

---Loads all layouts from this Project's directory.
function Project:loadLayouts()
    local names = self:getLayoutFileList()
    for i, name in ipairs(names) do
        self.layouts[name] = ProjectLayout(self, name)
    end
end

---Saves the layout matching provided name.
---@param name string The name of the layout which will be saved.
function Project:saveLayout(name)
    if not self.layouts[name] then
        return false -- Layout not found.
    end
    self.layouts[name]:save()
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

---Renames the layout matching provided name.
---Returns `true` if the operation succeeds, `false` otherwise.
---@param name string The name of the layout which will be renamed.
---@param newName string The new name for the current layout.
---@return boolean
function Project:renameLayout(name, newName)
    if not self.layouts[name] then
        return false -- Layout not found.
    elseif self.layouts[newName] then
        return false -- Name is already taken by a different layout.
    elseif not self:isLayoutNameValid(newName) then
        return false -- Layout name is invalid.
    end
    self.layouts[name]:setName(newName)
    self.layouts[newName] = self.layouts[name]
    self.layouts[name] = nil
    return true
end

---Deletes the layout matching provided name from this Project.
---Returns `true` if the operation succeeds, `false` otherwise.
---@param name string The name of the layout which will be deleted.
---@return boolean
function Project:deleteLayout(name)
    if not self.layouts[name] then
        return false -- Layout not found.
    end
    self.layouts[name] = nil
    return true
end

---Creates a copy of the layout matching provided name.
---Returns `true` if the operation succeeds, `false` otherwise.
---@param name string The name of the layout which will be duplicated.
---@param newName string The name of the duplicate layout.
---@return boolean
function Project:duplicateLayout(name, newName)
    if not self.layouts[name] then
        return false -- Layout not found.
    end
    self.layouts[newName] = self.layouts[name]:copy(newName)
    return true
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

---Returns the names of all layouts in this project, sorted alphabetically.
---@return table
function Project:getLayoutNameList()
    return _Utils.tableGetSortedKeys(self.layouts)
end

---Returns `true` if the provided name is a valid layout name (is empty and does not contain illegal characters).
---@param name string The layout name to be checked.
---@return boolean
function Project:isLayoutNameValid(name)
    -- TODO: Add a check for illegal characters.
    return name ~= ""
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

---Switches snap to grid on or off.
function Project:toggleSnapToGrid()
    self:setProperty("gridSnap", not self:getProperty("gridSnap"))
end

---Returns whether the grid is visible.
---@return boolean
function Project:isGridVisible()
    return self:getProperty("gridVisible")
end

---Switches grid visibility on or off.
function Project:toggleGridVisibility()
    self:setProperty("gridVisible", not self:getProperty("gridVisible"))
end

---Returns whether the guides are visible.
---@return boolean
function Project:areGuidesVisible()
    return self:getProperty("guidesVisible")
end

---Switches guide visibility on or off.
function Project:toggleGuideVisibility()
    self:setProperty("guidesVisible", not self:getProperty("guidesVisible"))
end

--######################################################--
---------------- S E R I A L I Z A T I O N ---------------
--######################################################--

---Loads the project's properties from the given data.
---@param data table The project properties.
function Project:deserialize(data)
    self.properties:deserialize(data)
end

---Returns data for this Project which can be saved on disk and loaded later with `:deserialize()`.
---@return table
function Project:serialize()
    return self.properties:serialize()
end

return Project