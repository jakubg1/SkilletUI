local class = require "com.class"

---@class ResourceManager
---@overload fun():ResourceManager
local ResourceManager = class:derive("ResourceManager")

-- Place your imports here
local Font = require("src.Font")
local Image = require("src.Image")
local NineImage = require("src.NineImage")

---Constructs the Resource Manager. It holds data.
---This is a faux Resource Manager which has a similar API to what is there in OpenSMCE.
function ResourceManager:new()
    self.fonts = {
        default = Font("resources/font_default.json"),
        editor = Font("resources/font_editor.json"),
        standard = Font("resources/font_standard.json")
    }
    self.fontLookup = {}

    self.images = {
        widget_box = Image("resources/widget_box.png"),
        widget_button = Image("resources/widget_button.png"),
        widget_canvas = Image("resources/widget_canvas.png"),
        widget_locked = Image("resources/widget_locked.png"),
        widget_ninesprite = Image("resources/widget_ninesprite.png"),
        widget_none = Image("resources/widget_none.png"),
        widget_sprite = Image("resources/widget_sprite.png"),
        widget_text = Image("resources/widget_text.png"),
        widget_titledigit = Image("resources/widget_titledigit.png")
    }
    self.imageLookup = {}

    self.nineImages = {
        base_button = NineImage("resources/base_button.png", 3, 9, 3, 9),
        base_button_hover = NineImage("resources/base_button_hover.png", 3, 9, 3, 9),
        base_button_click = NineImage("resources/base_button_click.png", 3, 9, 3, 9),
        button = NineImage("resources/button.png", 2, 3, 3, 4),
        button_hover = NineImage("resources/button_hover.png", 2, 3, 3, 4),
        button_click = NineImage("resources/button_click.png", 2, 3, 3, 4),
        ed_button = NineImage("resources/ed_button.png", 2, 3, 2, 3),
        ed_button_click = NineImage("resources/ed_button_click.png", 2, 3, 2, 3),
        ed_input = NineImage("resources/ed_input.png", 2, 3, 2, 3),
        ed_input_hover = NineImage("resources/ed_input_hover.png", 2, 3, 2, 3),
        ed_input_disabled = NineImage("resources/ed_input_disabled.png", 2, 3, 2, 3)
    }
    self.nineImageLookup = {}
end

---Inits the Resource Manager by preparing the resource lookups.
function ResourceManager:init()
	for fontName, font in pairs(self.fonts) do
		self.fontLookup[font] = fontName
	end
	for imageName, image in pairs(self.images) do
		self.imageLookup[image] = imageName
	end
	for nineImageName, nineImage in pairs(self.nineImages) do
		self.nineImageLookup[nineImage] = nineImageName
	end
end

---Returns a font with the provided name.
---@param name string The font name.
---@return Font
function ResourceManager:getFont(name)
    return self.fonts[name]
end

---Returns the name of the provided font.
---@param font Font The font to be looked up.
---@return string
function ResourceManager:getFontName(font)
    return self.fontLookup[font]
end

---Returns the list of all available fonts, in the format of `{{name = name, font = Font}, ...}`.
---The list is sorted by names alphabetically.
---@return table
function ResourceManager:getFontList()
    local result = {}
    for name, font in pairs(self.fonts) do
        table.insert(result, {name = name, font = font})
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end

---Returns an image with the provided name.
---@param name string The image name.
---@return Image
function ResourceManager:getImage(name)
    return self.images[name]
end

---Returns the name of the provided image.
---@param image Image The inage to be looked up.
function ResourceManager:getImageName(image)
    return self.imageLookup[image]
end

---Returns the list of all available Images, in the format of `{{name = name, resource = Image}, ...}`.
---The list is sorted by names alphabetically.
---@return table
function ResourceManager:getImageList()
    local result = {}
    for name, image in pairs(self.images) do
        table.insert(result, {name = name, resource = image})
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end

---Returns a NineImage with the provided name.
---@param name string The image name.
---@return NineImage
function ResourceManager:getNineImage(name)
    return self.nineImages[name]
end

---Returns the name of the provided NineImage.
---@param nineImage NineImage The inage to be looked up.
function ResourceManager:getNineImageName(nineImage)
    return self.nineImageLookup[nineImage]
end

---Returns the list of all available NineImages, in the format of `{{name = name, resource = NineImage}, ...}`.
---The list is sorted by names alphabetically.
---@return table
function ResourceManager:getNineImageList()
    local result = {}
    for name, nineImage in pairs(self.nineImages) do
        table.insert(result, {name = name, resource = nineImage})
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end

return ResourceManager