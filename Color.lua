local class = require "com.class"

---@class Color
---@operator add(Color|number):Color
---@operator sub(Color|number):Color
---@operator mul(Color|number):Color
---@operator div(Color|number):Color
---@operator unm():Color
---@overload fun(r, g, b):Color
local Color = class:derive("Color")



---Constructor.
---
---`Color()` will make a `(1, 1, 1)` color (white).
---
---`Color(x)` will make a `(x, x, x)` color (grayscale).
---
---`Color(r, g, b)` will make a `(r, g, b)` color.
function Color:new(r, g, b)
	self.r = r or 1
	self.g = g or self.r
	self.b = b or self.r
end

function Color.__tostring(o) return "Color(" .. tostring(o.r) .. ", " .. tostring(o.g) .. ", " .. tostring(o.b) .. ")" end
function Color.__unm(o) return Color(-o.r, -o.g, -o.b) end
function Color.clone(o) return Color(o.r, o.g, o.b) end

function Color.__eq(o1, o2)
	if type(o2) == "number" then
		return o1.r == o2 and o1.g == o2 and o1.b == o2
	else
		return o1.r == o2.r and o1.g == o2.g and o1.b == o2.b
	end
end

function Color.__add(o1, o2)
	if type(o2) == "number" then
		return Color(o1.r + o2, o1.g + o2, o1.b + o2)
	else
		return Color(o1.r + o2.r, o1.g + o2.g, o1.b + o2.b)
	end
end

function Color.__sub(o1, o2)
	if type(o2) == "number" then
		return Color(o1.r - o2, o1.g - o2, o1.b - o2)
	else
		return Color(o1.r - o2.r, o1.g - o2.g, o1.b - o2.b)
	end
end

function Color.__mul(o1, o2)
	if type(o2) == "number" then
		return Color(o1.r * o2, o1.g * o2, o1.b * o2)
	else
		return Color(o1.r * o2.r, o1.g * o2.g, o1.b * o2.b)
	end
end

function Color.__div(o1, o2)
	if type(o2) == "number" then
		return Color(o1.r / o2, o1.g / o2, o1.b / o2)
	else
		return Color(o1.r / o2.r, o1.g / o2.g, o1.b / o2.b)
	end
end



return Color