local class = require "com.class"

---@class ProjectLayout
---@overload fun(project, name):ProjectLayout
local ProjectLayout = class:derive("ProjectLayout")

-- Place your imports here
local Node = require("src.Node")

---Creates a new ProjectLayout.
---ProjectLayouts are stored in Projects and represent a single layout.
---Any Layout can have any number of timelines.
---Layouts are stored in the `layouts/<name>.json` file inside the project directory. That file also includes all the layout's timelines.
---@param project Project The Project this layout belongs to.
---@param name string? The name of the layout. This is also its file name. If not specified, a new empty layout will be created and a name will be assigned: `layout`, `layout#2`, etc.
function ProjectLayout:new(project, name)
    self.project = project
    self.name = name

    self.modified = false

    if self.name then
        local path = assert(self:getPath())
        local data = assert(_Utils.loadJson(path), "Could not load layout data from " .. path)
        self:deserialize(data)
    else
        -- Set up the root node and name.
        self.name = self.project:generateUniqueLayoutName("layout")
        local size = self.project:getNativeResolution()
        self.ui = Node({name = "root", type = "box", widget = {size = {size.x, size.y}}, canvasInputMode = true})
    end
end

--############################################################--
---------------- B A S I C   P R O P E R T I E S ---------------
--############################################################--

---Returns the name of this Layout.
---@return string
function ProjectLayout:getName()
    return self.name
end

---Returns the name of this Layout with a modified indicator `*` if this layout is modified.
---@return string
function ProjectLayout:getDisplayName()
    return self.name .. (self.modified and "*" or "")
end

---Changes the name of this Layout.
---This function does NOT change the Project's associations. Please use `Project:renameCurrentLayout()` instead!
---@param name string The new name for this Layout.
function ProjectLayout:setName(name)
    self.name = name
end

---Returns the root UI node of this Layout.
---@return Node
function ProjectLayout:getUI()
    return self.ui
end

---Returns whether this layout is modified.
---@return boolean
function ProjectLayout:isModified()
    return self.modified
end

---Marks this layout as modified or not modified.
---@param modified boolean Whether this layout should be marked as modified (`true`) or not (`false`).
function ProjectLayout:setModified(modified)
    self.modified = modified
end

---Makes a copy of this ProjectLayout and returns it.
---The Project generates a new name for this Layout, but does not add it to its list.
---@return ProjectLayout
function ProjectLayout:copy()
    local copy = ProjectLayout(self.project)
    local data = self:serialize()
    copy:deserialize(data)
    copy:setName(self.project:generateUniqueLayoutName(self.name))
    return copy
end

--################################################--
---------------- F I L E S Y S T E M ---------------
--################################################--

---Returns the complete file path to this Layout, starting from the root program directory.
---@return string
function ProjectLayout:getPath()
    return self.project:getLayoutDirectory() .. self.name .. ".json"
end

---Saves this Layout on disk and marks it as unmodified.
---@param name string? If provided, this layout will be renamed and saved under this name.
function ProjectLayout:save(name)
    if name then
        self.name = name
    end
    _Utils.saveJson(self:getPath(), self:serialize())
    self.modified = false
end

--##############################################--
---------------- C A L L B A C K S ---------------
--##############################################--

---Updates the Layout's components.
---@param dt number Time delta, in seconds.
function ProjectLayout:update(dt)
    self.ui:update(dt)
end

---Draws the Layout on the screen.
function ProjectLayout:draw()
    self.ui:draw()
end

---Executed whenever a mouse button is pressed anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been pressed.
---@param istouch boolean Whether the press is coming from a touch input.
---@param presses integer How many clicks have been performed in a short amount of time. Useful for double click checks.
function ProjectLayout:mousepressed(x, y, button, istouch, presses)
    self.ui:mousepressed(x, y, button, istouch, presses)
end

---Executed whenever a mouse button is released anywhere on the screen.
---@param x integer The X coordinate.
---@param y integer The Y coordinate.
---@param button integer The button that has been released.
function ProjectLayout:mousereleased(x, y, button)
    self.ui:mousereleased(x, y, button)
end

---Executed whenever a key is pressed on the keyboard.
---@param key string The key code.
function ProjectLayout:keypressed(key)
    self.ui:keypressed(key)
end

--######################################################--
---------------- S E R I A L I Z A T I O N ---------------
--######################################################--

---Loads the layout's properties from the given data.
---@param data table The layout data.
function ProjectLayout:deserialize(data)
    self.ui = Node(data)
end

---Returns data for this Layout which can be saved on disk and loaded later with `:deserialize()`.
---@return table
function ProjectLayout:serialize()
    return self.ui:serialize()
end

return ProjectLayout