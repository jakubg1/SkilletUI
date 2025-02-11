local class = require "com.class"

---@class ResourceManager
---@overload fun():ResourceManager
local ResourceManager = class:derive("ResourceManager")

-- Place your imports here
local Image = require("Image")
local NineImage = require("NineImage")

---Constructs the Resource Manager. It holds data.
---This is a faux Resource Manager which has a similar API to what is there in OpenSMCE.
function ResourceManager:new()
    local fontCharacters = " abcdefghijklmnopqrstuvwxyząćęłńóśźżABCDEFGHIJKLMNOPQRSTUVWXYZĄĆĘŁŃÓŚŹŻ0123456789<>-+()[]_.,:;'!?@#$€%^&*\"/|\\"
    self.fonts = {
        default = love.graphics.newFont(),
        editor = love.graphics.newFont(14),
        standard = love.graphics.newImageFont("resources/standard.png", fontCharacters, 1)
    }
    self.fontLookup = {}

    self.images = {
        base_button = NineImage("resources/base_button.png", 3, 3, 9, 9),
        base_button_hover = NineImage("resources/base_button_hover.png", 3, 3, 9, 9),
        base_button_click = NineImage("resources/base_button_click.png", 3, 3, 9, 9),
        button = NineImage("resources/button.png", 2, 3, 3, 4),
        button_hover = NineImage("resources/button_hover.png", 2, 3, 3, 4),
        button_click = NineImage("resources/button_click.png", 2, 3, 3, 4),
        ed_button = NineImage("resources/ed_button.png", 2, 3, 2, 3),
        ed_button_click = NineImage("resources/ed_button_click.png", 2, 3, 2, 3),
        ed_input = NineImage("resources/ed_input.png", 2, 3, 2, 3),
        ed_input_hover = NineImage("resources/ed_input_hover.png", 2, 3, 2, 3),
        ed_input_disabled = NineImage("resources/ed_input_disabled.png", 2, 3, 2, 3),
        widget_box = Image("resources/widget_box.png"),
        widget_button = Image("resources/widget_button.png"),
        widget_canvas = Image("resources/widget_canvas.png"),
        widget_ninesprite = Image("resources/widget_ninesprite.png"),
        widget_none = Image("resources/widget_none.png"),
        widget_text = Image("resources/widget_text.png"),
        widget_titledigit = Image("resources/widget_titledigit.png")
    }
    self.imageLookup = {}
end

---Inits the Resource Manager by preparing the resource lookups.
function ResourceManager:init()
	for fontName, font in pairs(self.fonts) do
		self.fontLookup[font] = fontName
	end
	for imageName, image in pairs(self.images) do
		self.imageLookup[image] = imageName
	end
end

---Returns a font with the provided name.
---@param name string The font name.
---@return love.Font
function ResourceManager:getFont(name)
    return self.fonts[name]
end

---Returns the name of the provided font.
---@param font love.Font The font to be looked up.
---@return string
function ResourceManager:getFontName(font)
    return self.fontLookup[font]
end

---Returns an image or NineImage with the provided name.
---@param name string The image name.
---@return Image|NineImage
function ResourceManager:getImage(name)
    return self.images[name]
end

---Returns the name of the provided image.
---@param image Image|NineImage The inage to be looked up.
function ResourceManager:getImageName(image)
    return self.imageLookup[image]
end

return ResourceManager