local class = require "com.class"

---@class ProjectLayout
---@overload fun(project, name, blank):ProjectLayout
local ProjectLayout = class:derive("ProjectLayout")

-- Place your imports here
local Node = require("src.Node")
local Timeline = require("src.Timeline")

---Creates a new ProjectLayout.
---ProjectLayouts are stored in Projects and represent a single layout.
---Any Layout can have any number of timelines.
---Layouts are stored in the `layouts/<name>.json` file inside the project directory. That file also includes all the layout's timelines.
---@param project Project The Project this layout belongs to.
---@param name string The name of the layout. This is also its file name.
---@param blank boolean? If set to `true`, create a new empty layout instead of trying to load an existing file.
function ProjectLayout:new(project, name, blank)
    self.project = project
    self.name = name

    self.timelines = {
        test = Timeline()
    }
    self.modified = false

    if not blank then
        -- Load an existing layout from a file. If the file does not exist, error out.
        local path = assert(self:getPath())
        local data = assert(_Utils.loadJson(path), "Could not load layout data from " .. path)
        self:deserialize(data)
    else
        -- Create a new empty layout. Set up the root node.
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
---This function does NOT change the Project's associations. Please use `Project:renameLayout()` instead!
---@param name string The new name for this Layout.
function ProjectLayout:setName(name)
    self.name = name
end

---Returns the root UI node of this Layout.
---@return Node
function ProjectLayout:getUI()
    return self.ui
end

---Returns the size of this Layout.
---@return Vector2
function ProjectLayout:getSize()
    local size = self.ui:getSize()
    if size.x == 1 and size.y == 1 then
        -- If the returned size is `(1, 1)`, the root node is widgetless. Accomodate for that.
        return self.project:getNativeResolution()
    end
    return size
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
---The copy will have the provided name.
---@param name string The name for the copied layout.
---@return ProjectLayout
function ProjectLayout:copy(name)
    local copy = ProjectLayout(self.project, name, true)
    local data = self:serialize()
    copy:deserialize(data)
    return copy
end

--##############################################--
---------------- T I M E L I N E S ---------------
--##############################################--

---Plays the specified Timeline.
---@param name string The name of the Timeline to be played.
function ProjectLayout:playTimeline(name)
    self.timelines[name]:play()
end

---Stops the specified Timeline from playing and resets all widget properties.
---@param name string The name of the Timeline to be stopped.
function ProjectLayout:stopTimeline(name)
    self.timelines[name]:stop()
    self:getUI():resetProperties()
end

---Returns the specified Timeline.
---@param name string The name of the Timeline to be returned.
---@return Timeline?
function ProjectLayout:getTimeline(name)
    return self.timelines[name]
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
    for name, timeline in pairs(self.timelines) do
        timeline:update(dt)
    end
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