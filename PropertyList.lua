local class = require "com.class"

---@class PropertyList
---@overload fun(properties, data):PropertyList
local PropertyList = class:derive("PropertyList")

-- Place your imports here
local Vec2 = require("Vector2")
local Color = require("Color")



---Constructs a Property List.
---Property Lists encapsulate a Node's or Widget's properties into a list that can be serialized and deserialized.
---It also allows you to store two values for each property: the current value (depending on which animations have been executed before),
---and the base value (which you can reset the current value to and is actually stored and saved).
---
---Each property definition entry can have the following fields:
--- - `key` (required) - The name under which this property will be saved.
--- - `name` (required) - The visible property name, for use in the editor.
--- - `type` (required) - The property type. One of `"string"`, `"number"`, `"boolean"`, `"color"`, `"shortcut"`, `"Vector2"`, `"Image"`, `"Font"`.
--- - `nullable` - Whether the value can not exist.
--- - `defaultValue` - The default value for this property.
--- - `defaultValueNoData` - The default value for this property used only if the property is deserialized with NO DATA WHATSOEVER.
---@param properties table A list of property entries. Each of the property entries can have various parameters.
---@param data table A table of values, keyed by properties' keys. If any of the properties are missing, the default values specified in `data` will be prepended.
function PropertyList:new(properties, data)
    self.properties = properties

    self.values = {}
    self:deserialize(data)
end



---Returns the current value of the provided key.
---@param key string The property key.
---@return any?
function PropertyList:getValue(key)
    return self.values[key].current
end



---Returns the base value of the provided key. Base value is always used for serialization.
---@param key string The property key.
---@return any?
function PropertyList:getBaseValue(key)
    return self.values[key].base
end



---Sets the current value of the provided key.
---@param key string The property key.
---@param value any? The value which will be stored under that key.
function PropertyList:setValue(key, value)
    self.values[key].current = value
end



---Sets the base value of the provided key. Base value is always used for serialization.
---If the current value of that key is the same as the base value, the current value will be set too.
---@param key string The property key.
---@param value any? The value which will be stored under that key.
function PropertyList:setBaseValue(key, value)
    if self.values[key].current == self.values[key].base then
        self.values[key].current = value
    end
    self.values[key].base = value
end



---Resets the current value of the provided key to its base value.
---@param key string The property key.
function PropertyList:resetValue(key)
    self.values[key].current = self.values[key].base
end



---Saves currently stored data from this property list and returns it as a table.
---Only base values are saved!
---@return table
function PropertyList:serialize()
    local data = {}
    for i, property in ipairs(self.properties) do
        local value = nil
        -- Retrieve the current base value of this property.
        local rawValue = self.values[property.key].base
        -- If the property value matches its default value or is equal to `nil`, we do not store it. Otherwise, proceed.
        if rawValue ~= nil and rawValue ~= property.defaultValue then
            -- Go over the types and treat the value accordingly.
            if property.type == "string" then
                value = rawValue
            elseif property.type == "number" then
                value = rawValue
            elseif property.type == "boolean" then
                value = rawValue
            elseif property.type == "color" then
                value = rawValue:getHex()
            elseif property.type == "Vector2" then
                value = {rawValue.x, rawValue.y}
            elseif property.type == "Image" then
                value = _IMAGE_LOOKUP[rawValue]
            elseif property.type == "Font" then
                value = _FONT_LOOKUP[rawValue]
            elseif property.type == "shortcut" then
                value = rawValue
            end
        end
        data[property.key] = value
    end
    return data
end



---Loads provided data into this property list. If no data is provided, data from the `defaultValueNoData` fields for each supported property will be prepended.
---@param data table? The data to be loaded.
function PropertyList:deserialize(data)
    self.values = {}
    for i, property in ipairs(self.properties) do
        local value = nil
        if not data then
            -- If there is no data, first check the `defaultValueNoData` field, then `defaultValue` field, and if neither exists put `nil`.
            value = property.defaultValueNoData or property.defaultValue
        else
            -- There is data. Check if the key exists.
            if data[property.key] == nil then
                -- No such key. Put the default value if it exists.
                value = property.defaultValue
            else
                -- Carry on by checking the types.
                if property.type == "string" then
                    value = data[property.key]
                elseif property.type == "number" then
                    value = data[property.key]
                elseif property.type == "boolean" then
                    value = data[property.key]
                elseif property.type == "color" then
                    value = Color(data[property.key])
                elseif property.type == "Vector2" then
                    value = Vec2(data[property.key])
                elseif property.type == "Image" then
                    value = _IMAGES[data[property.key]]
                elseif property.type == "Font" then
                    value = _FONTS[data[property.key]]
                elseif property.type == "shortcut" then
                    value = data[property.key]
                end
            end
        end
        self.values[property.key] = {base = value, current = value}
    end
end



return PropertyList