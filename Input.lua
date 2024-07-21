-- Temporary input class yoinked somewhere from my legacy codebase. Will be removed at some point :]

local class = require "com.class"
local Input = class:derive("Input")



function Input:new()
	self.allowedInput = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.- "
	
	self.font = love.graphics.newFont()
	self.bigFont = love.graphics.newFont(18)
	
	self.inputType = nil
	self.input = ""
end





function Input:keypressed(key)
	if key == "backspace" then
		if self.inputType then
			if #self.input > 0 then
				self.input = self.input:sub(1, #self.input - 1)
			end
		end
	elseif key == "return" then
		local result = self:inputAccept()
		_EDITOR:onInputReceived(result)
	elseif key == "escape" then
		self:inputCancel()
	end
end



function Input:textinput(text)
	if not self:isValidInput(text) then
		return
	end
	
	if self.inputType then
		self.input = self.input .. text
	end
end





function Input:isValidInput(text)
	for i = 1, #self.allowedInput do
		if self.allowedInput:sub(i, i) == text then
			return true
		end
	end
	return false
end





function Input:inputAsk(type, value)
	self.inputType = type
	if value then
		self.input = value
	end
end



function Input:inputCancel()
	self.inputType = nil
	self.input = ""
end



function Input:inputAccept()
	local result = nil
	
	if self.inputType == "string" then
		result = self.input
	elseif self.inputType == "number" then
		result = tonumber(self.input)
	end
	
	self:inputCancel()
	return result
end





function Input:isObstructing(x, y)
	if not self.inputType then
		return false
	end
	
	return x >= 200 and x < 600 and y >= 200 and y < 350
end





function Input:draw()
	if not self.inputType then
		return
	end
	
	love.graphics.setLineWidth(3)
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", 200, 200, 400, 150)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("line", 200, 200, 400, 150)
	love.graphics.rectangle("line", 220, 270, 360, 25)
	love.graphics.setFont(self.bigFont)
	love.graphics.print(string.format("Enter Variable type = %s", self.inputType), 210, 210)
	love.graphics.print(string.format("%s_", self.input), 230, 270)
	love.graphics.print("[ Enter ] = Confirm    [ Esc ] = Cancel", 220, 320)
	love.graphics.setFont(self.font)
end



return Input