-- Temporary input class yoinked somewhere from my legacy codebase. Will be removed at some point :]

local class = require "com.class"
local Input = class:derive("Input")



function Input:new()
	self.POS_X = (_WINDOW_SIZE.x - 400) / 2
	self.POS_Y = (_WINDOW_SIZE.y - 150) / 2

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
	if self.inputType then
		self.input = self.input .. text
	end
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
	
	return x >= self.POS_X and x < self.POS_X + 400 and y >= self.POS_Y and y < self.POS_Y + 150
end





function Input:draw()
	if not self.inputType then
		return
	end
	
	love.graphics.setLineWidth(3)
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", self.POS_X, self.POS_Y, 400, 150)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("line", self.POS_X, self.POS_Y, 400, 150)
	love.graphics.rectangle("line", self.POS_X + 20, self.POS_Y + 70, 360, 25)
	love.graphics.setFont(self.bigFont)
	love.graphics.print(string.format("Enter Variable type = %s", self.inputType), self.POS_X + 10, self.POS_Y + 10)
	love.graphics.print(string.format("%s_", self.input), self.POS_X + 30, self.POS_Y + 70)
	love.graphics.print("[ Enter ] = Confirm    [ Esc ] = Cancel", self.POS_X + 20, self.POS_Y + 120)
	love.graphics.setFont(self.font)
end



return Input