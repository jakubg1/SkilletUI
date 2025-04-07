local class = require "com.class"

---@class Font
---@overload fun(path):Font
local Font = class:derive("Font")

-- Place your imports here

---Creates a new Font.
---@param path string The path to the font definition file.
function Font:new(path)
    self.path = path
    local data = _Utils.loadJson(path)
    assert(data, "Failed to load font data from " .. path)

    if data.type == "builtin" then
        if data.size then
            self.font = love.graphics.newFont(data.size)
        else
            self.font = love.graphics.newFont()
        end
        self.font:setFilter("linear", "linear")
    elseif data.type == "image" then
        self.font = love.graphics.newImageFont(data.image, data.characters, data.spacing or 1)
    end
end

---Returns the string representation of this Font.
---@return string
function Font:__tostring()
    return "Font<" .. self.path .. ">"
end

---Returns the width of the provided text written with this Font, in pixels.
---@param text string The text to be calculated for.
---@return number
function Font:getWidth(text)
    return self.font:getWidth(text)
end

---Returns the height of this Font.
---@return number
function Font:getHeight()
    return self.font:getHeight()
end

return Font