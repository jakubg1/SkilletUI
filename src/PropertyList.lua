local class = require "com.class"

---@class PropertyList
---@overload fun(properties, data):PropertyList
local PropertyList = class:derive("PropertyList")

-- Place your imports here
local Vec2 = require("src.Essentials.Vector2")
local Color = require("src.Essentials.Color")



---Constructs a Property List.
---Property Lists encapsulate a Node's or Widget's properties into a list that can be serialized and deserialized.
---It also allows you to store two values for each property: the current value (depending on which animations have been executed before),
---and the base value (which you can reset the current value to and is actually stored and saved).
---
---Each property definition entry can have the following fields:
--- - `key` (required) - The name under which this property will be saved.
--- - `name` (required) - The visible property name, for use in the editor.
--- - `type` (required) - The property type. One of `"string"`, `"number"`, `"boolean"`, `"color"`, `"shortcut"`, `"Vector2"`, `"Image"`, `"NineImage"`, `"Font"`.
--- - `nullable` - Whether the value can not exist.
--- - `defaultValue` - The default value for this property.
--- - `defaultValueNoData` - The default value for this property used only if the property is deserialized with NO DATA WHATSOEVER.
---@param properties table A list of property entries. Each of the property entries can have various parameters.
---@param data table? A table of values, keyed by properties' keys. If any of the properties are missing, the default values specified in `data` will be prepended.
function PropertyList:new(properties, data)
    self.properties = properties

    self.currentValues = {}
    self.baseValues = {}
    self.animations = {}

    self:deserialize(data or {})
end



---Returns the current value of the provided key.
---@param key string The property key.
---@return any?
function PropertyList:getValue(key)
    return self.currentValues[key]
end



---Sets the current value of the provided key.
---@param key string The property key.
---@param value any? The value which will be stored under that key.
function PropertyList:setValue(key, value)
    self.currentValues[key] = value
end



---Returns the base value of the provided key. Base value is always used for serialization.
---@param key string The property key.
---@return any?
function PropertyList:getBaseValue(key)
    return self.baseValues[key]
end



---Sets the base value of the provided key. Base value is always used for serialization.
---If the current value of that key is the same as the base value, the current value will be set too.
---@param key string The property key.
---@param value any? The value which will be stored under that key.
function PropertyList:setBaseValue(key, value)
    if self.currentValues[key] == self.baseValues[key] then
        self.currentValues[key] = value
    end
    self.baseValues[key] = value
end



---Returns the set of current values in this property list, keyed by the property keys.
---@return table
function PropertyList:getValues()
    return self.currentValues
end



---Resets the current value of the provided key to its base value.
---@param key string The property key.
function PropertyList:resetValue(key)
    self.currentValues[key] = self.baseValues[key]
end



---Resets all of the values in this property list to their base values and resets all animations.
function PropertyList:reset()
    for key, value in pairs(self.currentValues) do
        self.currentValues[key] = self.baseValues[key]
    end
    self.animations = {}
end



---Animates the provided property, effective immediately.
---@param key string The property key.
---@param startValue any? The starting value of the animation. If not provided, the current value will be used.
---@param finalValue any The final value of the animation.
---@param duration number? The duration of the animation. If not specified, the property's value will be set immediately.
function PropertyList:animateValue(key, startValue, finalValue, duration)
    if startValue then
        self.currentValues[key] = startValue
    end
    if duration then
        startValue = startValue or self.currentValues[key]
        table.insert(self.animations, {property = key, startValue = startValue, finalValue = finalValue, maxTime = duration, time = 0})
    else
        self.currentValues[key] = finalValue
    end
end



---Updates the Property List. Dispatches animations.
---@param dt number Time delta in seconds.
function PropertyList:update(dt)
    for i, animation in ipairs(self.animations) do
        animation.time = animation.time + dt
        if animation.time < animation.maxTime then
            self.currentValues[animation.property] = _Utils.interpolate2(animation.startValue, animation.finalValue, 0, animation.maxTime, animation.time)
        else
            -- The animation is over.
            self.currentValues[animation.property] = animation.finalValue
            animation.delQueue = true
        end
    end
    _Utils.removeDeadObjects(self.animations)
end



---Saves currently stored data from this property list and returns it as a table.
---Only base values are saved!
---@return table
function PropertyList:serialize()
    local data = {}
    for i, property in ipairs(self.properties) do
        local value = nil
        -- Retrieve the current base value of this property.
        local rawValue = self.baseValues[property.key]
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
                value = _RESOURCE_MANAGER:getImageName(rawValue)
            elseif property.type == "NineImage" then
                value = _RESOURCE_MANAGER:getNineImageName(rawValue)
            elseif property.type == "Font" then
                value = _RESOURCE_MANAGER:getFontName(rawValue)
            elseif property.type == "align" then
                -- Alignments do not serialize back into names.
                value = {rawValue.x, rawValue.y}
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
    self.currentValues = {}
    self.baseValues = {}
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
                    value = _RESOURCE_MANAGER:getImage(data[property.key])
                elseif property.type == "NineImage" then
                    value = _RESOURCE_MANAGER:getNineImage(data[property.key])
                elseif property.type == "Font" then
                    value = _RESOURCE_MANAGER:getFont(data[property.key])
                elseif property.type == "align" then
                    value = _ALIGNMENTS[data[property.key]] or Vec2(data[property.key])
                elseif property.type == "shortcut" then
                    value = data[property.key]
                end
            end
        end
        self.currentValues[property.key] = value
        self.baseValues[property.key] = value
    end
end



return PropertyList