-- Temporary input class yoinked somewhere from my legacy codebase. Will be removed at some point :]

local class = require "com.class"
local Input = class:derive("Input")

local utf8 = require("utf8")
local Vec2 = require("Vector2")
local Color = require("Color")



function Input:new()
	self.font = love.graphics.newFont()
	self.bigFont = love.graphics.newFont(18)

	self.inputType = nil
	self.inputText = ""
	self.error = nil

	-- Color picker only
	self.inputColor = {x = 0, y = 0, z = 0.5}
	self.colorDragging = nil
	local vertices = {}
	for i = 0, 200 do
		local t = i / 200
		local r, g, b = self:getPrimaryInputColor(t, 0)
		table.insert(vertices, {i, 0, 0, 0, r, g, b})
		table.insert(vertices, {i, 200, 0, 0, 0.5, 0.5, 0.5})
	end
	self.COLOR_MESH = love.graphics.newMesh(vertices, "strip", "static")
	self.SIDE_COLOR_MESHES = {love.graphics.newMesh(42, "strip", "dynamic"), love.graphics.newMesh(42, "strip", "dynamic")}
	self.COLOR_CHARACTERS = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"}

	self:updateSideColorPickerMeshes()

	-- File/Font picker only
	self.itemList = nil
	self.itemListOffset = 0
	self.ITEM_LIST_ENTRY_HEIGHT = 20
	self.ITEM_LIST_MAX_ENTRIES = 16

	-- File picker only
	self.fileWarnWhenExists = false
	self.fileWarningActive = false

	-- Shortcut picker only
	self.shortcut = nil

	-- Font/Image/NineImage picker only
	self.selectedResource = nil
end





function Input:inputAsk(type, value, extensions, warnWhenFileExists, basePath, pathFilter)
	self.inputType = type
	if type == "string" then
		self.inputText = value or ""
	elseif type == "number" then
		self.inputText = value and tostring(value) or ""
	elseif type == "color" then
		value = value or _COLORS.white
		self:setInputColor(value.r, value.g, value.b)
		self.inputText = self:getInputColorHex()
	elseif type == "file" then
		self.inputText = value or ""
		self.fileWarnWhenExists = warnWhenFileExists
		self.itemList = self:getItemList(basePath or "", pathFilter or "file", extensions)
		self.itemListOffset = 0
	elseif type == "shortcut" then
		self.shortcut = value
	elseif type == "Font" then
		self.selectedResource = value
		self.itemList = _RESOURCE_MANAGER:getFontList()
	elseif type == "Image" then
		self.selectedResource = value
		self.itemList = _RESOURCE_MANAGER:getImageList()
	elseif type == "NineImage" then
		self.selectedResource = value
		self.itemList = _RESOURCE_MANAGER:getNineImageList()
	end
end



function Input:inputCancel()
	if self.fileWarningActive then
		self.fileWarningActive = false
	else
		self:inputExit()
	end
end



function Input:inputExit()
	self.inputType = nil
	self.inputText = ""
	self.inputColor = {x = 0, y = 0, z = 0.5}
	self:updateSideColorPickerMeshes()
	self.fileWarningActive = false
end



function Input:inputAccept()
	local result = nil

	if self.inputType == "string" or self.inputType == "file" then
		result = self.inputText
	elseif self.inputType == "number" then
		result = tonumber(self.inputText)
		if not result then
			self.error = "Invalid number. Please enter a valid number."
			return
		end
	elseif self.inputType == "color" then
		result = Color(self:getInputColor())
	elseif self.inputType == "shortcut" then
		result = self.shortcut
	elseif self.inputType == "Font" or self.inputType == "Image" or self.inputType == "NineImage" then
		result = self.selectedResource
	end

	if self.fileWarnWhenExists and not self.fileWarningActive and _Utils.isValueInTable(self.itemList, result) then
		self.fileWarningActive = true
	else
		_EDITOR:onInputReceived(result)
		self:inputExit()
	end
end





---Color that has been selected in the big picker, not taking the side picker into the account.
function Input:getPrimaryInputColor(x, y)
	x, y = x or self.inputColor.x, y or self.inputColor.y
	local r = math.min(_Utils.interpolate2Clamped(2, 0, 0, 1/3, x) + _Utils.interpolate2Clamped(0, 2, 2/3, 1, x), 1)
	local g = math.min(x < 1/3 and _Utils.interpolate2Clamped(0, 2, 0, 1/3, x) or _Utils.interpolate2Clamped(2, 0, 1/3, 2/3, x), 1)
	local b = math.min(x < 2/3 and _Utils.interpolate2Clamped(0, 2, 1/3, 2/3, x) or _Utils.interpolate2Clamped(2, 0, 2/3, 1, x), 1)
	return _Utils.interpolate(r, 0.5, y), _Utils.interpolate(g, 0.5, y), _Utils.interpolate(b, 0.5, y)
end



function Input:getInputColor()
	local r, g, b = self:getPrimaryInputColor()
	local z = 1 - self.inputColor.z
	if z > 0.5 then
		local t = (z - 0.5) * 2
		return _Utils.interpolate(r, 1, t), _Utils.interpolate(g, 1, t), _Utils.interpolate(b, 1, t)
	else
		local t = z * 2
		return _Utils.interpolate(0, r, t), _Utils.interpolate(0, g, t), _Utils.interpolate(0, b, t)
	end
end

function Input:getInputColorHex()
	local r, g, b = self:getInputColor()
	return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end



function Input:setInputColor(r, g, b)
	-- Step 1: Determine the Z (brightness): it's (lowest + highest) / 2.
	local lowest = math.min(math.min(r, g), b)
	local highest = math.max(math.max(r, g), b)
	local z = (lowest + highest) / 2
	-- Next, modify the color so that Z=0.5...
	if z == 0 or z == 1 then
		-- Fix a NaN when Z=0 or Z=1. In these scenarios (pure white or pure black, respectively) this value does not matter, so we set it to 0.
		r, g, b = 0.5, 0.5, 0.5
	elseif z > 0.5 then
		local m = 0.5 / (1 - z)
		r, g, b = 1 - (1 - r) * m, 1 - (1 - g) * m, 1 - (1 - b) * m
	elseif z < 0.5 then
		local m = 0.5 / z
		r, g, b = r * m, g * m, b * m
	end
	-- Now check the lowest/average (gray) ratio. This will be the Y value (vibrance).
	lowest = math.min(math.min(r, g), b)
	highest = math.max(math.max(r, g), b)
	local y = lowest / ((lowest + highest) / 2)
	-- Modify the color so that Y=0...
	local m = (1 - highest) * 2
	r, g, b = (r - 0.5 * m) / (1 - m), (g - 0.5 * m) / (1 - m), (b - 0.5 * m) / (1 - m)
	-- Finally, extract the X (hue).
	-- We start with determining a base value, and then where it goes towards.
	local x = 0
	if r == 1 then
		x = g > 0.001 and (0 + g * 1/6) or (1 - b * 1/6)
	elseif g == 1 then
		x = b > 0.001 and (1/3 + b * 1/6) or (1/3 - r * 1/6)
	elseif b == 1 then
		x = r > 0.001 and (2/3 + r * 1/6) or (2/3 - g * 1/6)
	end
	self.inputColor = {x = x, y = y, z = 1 - z}
	self:updateSideColorPickerMeshes()
	--return x, y, 1 - z
end

function Input:setInputColorHex(hex)
	while hex:len() < 6 do
		hex = hex .. "0"
	end
	local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	self:setInputColor(r / 255, g / 255, b / 255)
end



function Input:updateSideColorPickerMeshes()
	local vertices = {}
	for i = 0, 20 do
		local r, g, b = self:getPrimaryInputColor()
		table.insert(vertices, {i, 0, 0, 0, 1, 1, 1})
		table.insert(vertices, {i, 100, 0, 0, r, g, b})
	end
	self.SIDE_COLOR_MESHES[1]:setVertices(vertices)
	vertices = {}
	for i = 0, 20 do
		local r, g, b = self:getPrimaryInputColor()
		table.insert(vertices, {i, 100, 0, 0, r, g, b})
		table.insert(vertices, {i, 200, 0, 0, 0, 0, 0})
	end
	self.SIDE_COLOR_MESHES[2]:setVertices(vertices)
end





function Input:getItemList(basePath, filter, extensions)
	local files = {}
	if extensions then
		for i, extension in ipairs(extensions) do
			local itemList = _Utils.getDirListing(basePath, filter, extension, true)
			for j, file in ipairs(itemList) do
				table.insert(files, file)
			end
		end
	else
		local itemList = _Utils.getDirListing(basePath, filter, nil)
		for i, file in ipairs(itemList) do
			table.insert(files, file)
		end
	end
	return files
end





function Input:getPos()
	local sizeX, sizeY = self:getSize()
	return (_WINDOW_SIZE.x - sizeX) / 2, (_WINDOW_SIZE.y - sizeY) / 2
end



function Input:getSize()
	if not self.inputType then
		return 0, 0
	elseif self.inputType == "string" or self.inputType == "number" or self.inputType == "shortcut" then
		return 400, 150
	elseif self.inputType == "color" then
		return 450, 300
	elseif self.inputType == "file" or self.inputType == "Font" or self.inputType == "Image" or self.inputType == "NineImage" then
		return 400, 500
	end
end



function Input:getOverwritePos()
	local sizeX, sizeY = self:getOverwriteSize()
	return (_WINDOW_SIZE.x - sizeX) / 2, (_WINDOW_SIZE.y - sizeY) / 2
end



function Input:getOverwriteSize()
	return 500, 110
end



function Input:isHovered()
	if not self.inputType then
		return false
	end

	local posX, posY = self:getPos()
	local sizeX, sizeY = self:getSize()
	return _MousePos.x >= posX and _MousePos.y >= posY and _MousePos.x <= posX + sizeX and _MousePos.y <= posY + sizeY
end



function Input:isColorMeshHovered()
	if self.inputType ~= "color" then
		return false
	end

	local posX, posY = self:getPos()
	return _MousePos.x >= posX + 20 and _MousePos.y >= posY + 50 and _MousePos.x <= posX + 220 and _MousePos.y <= posY + 250
end



function Input:isSideColorMeshHovered()
	if self.inputType ~= "color" then
		return false
	end

	local posX, posY = self:getPos()
	return _MousePos.x >= posX + 240 and _MousePos.y >= posY + 50 and _MousePos.x <= posX + 270 and _MousePos.y <= posY + 250
end



function Input:isFileInputBoxHovered()
	if (self.inputType ~= "file" and self.inputType ~= "Font" and self.inputType ~= "Image" and self.inputType ~= "NineImage") or self.fileWarningActive then
		return false
	end

	local posX, posY = self:getPos()
	return _MousePos.x >= posX + 30 and _MousePos.y >= posY + 75 and _MousePos.x <= posX + 370 and _MousePos.y <= posY + 405
end



function Input:getHoveredFileEntryIndex()
	if (self.inputType ~= "file" and self.inputType ~= "Font" and self.inputType ~= "Image" and self.inputType ~= "NineImage") or self.fileWarningActive then
		return nil
	end

	local posX, posY = self:getPos()
	-- Too far on the left/right.
	if not self:isFileInputBoxHovered() then
		return nil
	end
	local idx = math.floor((_MousePos.y - posY - 75) / self.ITEM_LIST_ENTRY_HEIGHT) + 1
	-- No entry here.
	if idx > #self.itemList then
		return nil
	end
	return idx + self.itemListOffset
end



function Input:isConfirmButtonHovered()
	if not self.inputType or self.fileWarningActive then
		return false
	end

	local posX, posY = self:getPos()
	local sizeX, sizeY = self:getSize()
	return _MousePos.x >= posX + sizeX - 380 and _MousePos.y >= posY + sizeY - 30 and _MousePos.x <= posX + sizeX - 200 and _MousePos.y <= posY + sizeY - 10
end



function Input:isCancelButtonHovered()
	if not self.inputType or self.fileWarningActive then
		return false
	end

	local posX, posY = self:getPos()
	local sizeX, sizeY = self:getSize()
	return _MousePos.x >= posX + sizeX - 180 and _MousePos.y >= posY + sizeY - 30 and _MousePos.x <= posX + sizeX and _MousePos.y <= posY + sizeY - 10
end



function Input:isOverwriteYesButtonHovered()
	if not self.fileWarningActive then
		return false
	end

	local posX, posY = self:getOverwritePos()
	local sizeX, sizeY = self:getOverwriteSize()
	return _MousePos.x >= posX + 80 and _MousePos.y >= posY + sizeY - 30 and _MousePos.x <= posX + 200 and _MousePos.y <= posY + sizeY - 10
end



function Input:isOverwriteNoButtonHovered()
	if not self.fileWarningActive then
		return false
	end

	local posX, posY = self:getOverwritePos()
	local sizeX, sizeY = self:getOverwriteSize()
	return _MousePos.x >= posX + 280 and _MousePos.y >= posY + sizeY - 30 and _MousePos.x <= posX + 400 and _MousePos.y <= posY + sizeY - 10
end



function Input:update(dt)
	if self.colorDragging == 1 then
		local posX, posY = self:getPos()
		self.inputColor.x = math.min(math.max((_MousePos.x - posX - 20) / 200, 0), 1)
		self.inputColor.y = math.min(math.max((_MousePos.y - posY - 50) / 200, 0), 1)
		self:updateSideColorPickerMeshes()
		self.inputText = self:getInputColorHex()
	elseif self.colorDragging == 2 then
		local posX, posY = self:getPos()
		self.inputColor.z = math.min(math.max((_MousePos.y - posY - 50) / 200, 0), 1)
		self.inputText = self:getInputColorHex()
	end
end

function Input:draw()
	if not self.inputType then
		return
	end

	local posX, posY = self:getPos()
	local sizeX, sizeY = self:getSize()

	love.graphics.setLineWidth(3)
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", posX, posY, sizeX, sizeY)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("line", posX, posY, sizeX, sizeY)
	love.graphics.setFont(self.bigFont)
	love.graphics.print(string.format("Enter Variable type = %s", self.inputType), posX + 10, posY + 10)
	if self.inputType == "string" or self.inputType == "number" then
		if self.error then
			love.graphics.setColor(1, 0, 0)
			love.graphics.setFont(self.font)
			love.graphics.print(self.error, posX + 20, posY + 100)
		end
		love.graphics.rectangle("line", posX + 20, posY + 70, sizeX - 40, 25)
		love.graphics.setColor(1, 1, 1)
		love.graphics.setFont(self.bigFont)
		love.graphics.print(string.format("%s_", self.inputText), posX + 30, posY + 70)
	elseif self.inputType == "color" then
		-- Main picker
		love.graphics.draw(self.COLOR_MESH, posX + 20, posY + 50)
		local cx, cy = posX + self.inputColor.x * 200 + 20, posY + self.inputColor.y * 200 + 50
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", cx - 1, cy - 10, 3, 8)
		love.graphics.rectangle("fill", cx - 10, cy - 1, 8, 3)
		love.graphics.rectangle("fill", cx - 1, cy + 3, 3, 8)
		love.graphics.rectangle("fill", cx + 3, cy - 1, 8, 3)
		-- Side picker
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(self.SIDE_COLOR_MESHES[1], posX + 240, posY + 50)
		love.graphics.draw(self.SIDE_COLOR_MESHES[2], posX + 240, posY + 50)
		local cx, cy = posX + 262, posY + self.inputColor.z * 200 + 50
		love.graphics.polygon("fill", cx, cy, cx + 8, cy + 8, cx + 8, cy - 8)
		-- Details
		local r, g, b = self:getInputColor()
		love.graphics.setColor(r, g, b)
		love.graphics.rectangle("fill", posX + 300, posY + 50, 60, 40)
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", posX + 300, posY + 50, 60, 40)
		love.graphics.print(string.format("R: %d", r * 255), posX + 300, posY + 100)
		love.graphics.print(string.format("G: %d", g * 255), posX + 300, posY + 120)
		love.graphics.print(string.format("B: %d", b * 255), posX + 300, posY + 140)
		--local x, y, z = self:setInputColor(r, g, b)
		--love.graphics.print(string.format("X: %s", self.inputColor.x), posX + 300, posY + 180)
		--love.graphics.print(string.format("Y: %s", self.inputColor.y), posX + 300, posY + 200)
		--love.graphics.print(string.format("Z: %s", self.inputColor.z), posX + 300, posY + 220)
		--love.graphics.print(string.format("X: %s", x), posX + 350, posY + 180)
		--love.graphics.print(string.format("Y: %s", y), posX + 350, posY + 200)
		--love.graphics.print(string.format("Z: %s", z), posX + 350, posY + 220)
		love.graphics.print(string.format("Hex: %s", self.inputText), posX + 300, posY + 180)
	elseif self.inputType == "file" or self.inputType == "Font" or self.inputType == "Image" or self.inputType == "NineImage" then
		local hoveredEntry = self:getHoveredFileEntryIndex()
		-- File list
		love.graphics.rectangle("line", posX + 20, posY + 70, sizeX - 40, 330)
		for i = 1, math.min(#self.itemList, self.ITEM_LIST_MAX_ENTRIES) do
			local item = self.itemList[i + self.itemListOffset]
			local y = posY + 75 + (i - 1) * self.ITEM_LIST_ENTRY_HEIGHT
			love.graphics.setColor(0, 0, 0, 0)
			if (self.inputType == "file" and item == self.inputText) or (self.inputType == "Font" and item.font == self.selectedResource) or ((self.inputType == "Image" or self.inputType == "NineImage") and item.resource == self.selectedResource) then
				love.graphics.setColor(0, 1, 1, 0.5)
			elseif hoveredEntry == i + self.itemListOffset then
				love.graphics.setColor(0, 1, 1, 0.3)
			end
			love.graphics.rectangle("fill", posX + 20, y, sizeX - 40, self.ITEM_LIST_ENTRY_HEIGHT)
			love.graphics.setColor(1, 1, 1)
			if self.inputType == "file" then
				love.graphics.print(item, posX + 30, y)
			elseif self.inputType == "Font" then
				love.graphics.setFont(item.font.font)
				love.graphics.print(item.name, posX + 30, y)
			elseif self.inputType == "Image" then
				item.resource:draw(Vec2(posX + 31, y + 1))
				love.graphics.print(item.name, posX + 100, y)
			elseif self.inputType == "NineImage" then
				item.resource:draw(Vec2(posX + 31, y + 1), Vec2(58, self.ITEM_LIST_ENTRY_HEIGHT - 2))
				love.graphics.print(item.name, posX + 100, y)
			end
		end
		love.graphics.setFont(self.bigFont)
		-- Input box
		if self.inputType == "file" then
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", posX + 20, posY + 420, sizeX - 40, 25)
			love.graphics.print(string.format("%s_", self.inputText), posX + 30, posY + 420)
		end
		if self.fileWarningActive then
			-- File overwrite warning
			local posBX, posBY = self:getOverwritePos()
			local sizeBX, sizeBY = self:getOverwriteSize()
			love.graphics.setLineWidth(3)
			love.graphics.setColor(0, 0, 0)
			love.graphics.rectangle("fill", posBX, posBY, sizeBX, sizeBY)
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", posBX, posBY, sizeBX, sizeBY)
			love.graphics.print(string.format("File \"%s\" already exists.", self.inputText), posBX + 10, posBY + 10)
			love.graphics.print("Overwrite it?", posBX + 10, posBY + 30)
			love.graphics.setColor(1, 1, 1)
			if self:isOverwriteYesButtonHovered() then
				love.graphics.setColor(0, 1, 1)
			end
			love.graphics.print("Yes [ Enter ]", posBX + 80, posBY + sizeBY - 30)
			love.graphics.setColor(1, 1, 1)
			if self:isOverwriteNoButtonHovered() then
				love.graphics.setColor(0, 1, 1)
			end
			love.graphics.print("No [ Esc ]", posBX + 280, posBY + sizeBY - 30)
		end
	elseif self.inputType == "shortcut" then
		if self.shortcut then
			love.graphics.print(_Utils.getShortcutString(self.shortcut), posX + 150, posY + 70)
		else
			love.graphics.setColor(0.5, 0.5, 0.5)
			love.graphics.print("[None set]", posX + 150, posY + 70)
		end
	end
	love.graphics.setColor(1, 1, 1)
	if self:isConfirmButtonHovered() then
		love.graphics.setColor(0, 1, 1)
	end
	love.graphics.print("[ Enter ] = Confirm", posX + sizeX - 380, posY + sizeY - 30)
	love.graphics.setColor(1, 1, 1)
	if self:isCancelButtonHovered() then
		love.graphics.setColor(0, 1, 1)
	end
	love.graphics.print("[ Esc ] = Cancel", posX + sizeX - 180, posY + sizeY - 30)
end

function Input:mousepressed(x, y, button, istouch, presses)
	if not self.inputType then
		return false
	end
	if button == 1 then
		if self:isColorMeshHovered() then
			self.colorDragging = 1
			return true
		elseif self:isSideColorMeshHovered() then
			self.colorDragging = 2
			return true
		elseif self:isFileInputBoxHovered() then
			local entry = self:getHoveredFileEntryIndex()
			if entry then
				if self.inputType == "file" then
					self.inputText = self.itemList[entry]
				elseif self.inputType == "Font" then
					self.selectedResource = self.itemList[entry].font
				elseif self.inputType == "Image" or self.inputType == "NineImage" then
					self.selectedResource = self.itemList[entry].resource
				end
				if presses >= 2 then
					self:inputAccept()
				end
			end
			return true
		elseif self:isConfirmButtonHovered() then
			self:inputAccept()
			return true
		elseif self:isCancelButtonHovered() then
			self:inputCancel()
			return true
		elseif self:isOverwriteYesButtonHovered() then
			self:inputAccept()
			return true
		elseif self:isOverwriteNoButtonHovered() then
			self:inputCancel()
			return true
		elseif not self:isHovered() then
			self:inputCancel()
			return true
		end
	end
	return false
end

function Input:mousereleased(x, y, button)
	if button == 1 then
		self.colorDragging = nil
	end
end

function Input:wheelmoved(x, y)
	if self.inputType == "file" then
		local maxY = math.max(#self.itemList - self.ITEM_LIST_MAX_ENTRIES, 0)
		self.itemListOffset = math.min(math.max(self.itemListOffset - y * 3, 0), maxY)
	end
end

function Input:keypressed(key)
	if not self.inputType then
		return false
	end
	if key == "backspace" then
		if self.inputType == "string" or self.inputType == "number" or self.inputType == "file" or self.inputType == "color" then
			local offset = utf8.offset(self.inputText, -1)
			if offset then
				self.inputText = self.inputText:sub(1, offset - 1)
				self.error = nil
				if self.inputType == "color" then
					self:setInputColorHex(self.inputText)
				end
			end
		end
		return true
	elseif key == "return" then
		self:inputAccept()
		return true
	elseif key == "escape" then
		self:inputCancel()
		return true
	end
	if self.inputType then
		if self.inputType == "shortcut" and not (key == "lctrl" or key == "lshift" or key == "rctrl" or key == "rshift") then
			self.shortcut = {key = key, ctrl = _IsCtrlPressed(), shift = _IsShiftPressed()}
		end
		-- Do not let anything else catch the keyboard input if the input box is currently active.
		return true
	end
	return false
end

function Input:textinput(text)
	if self.inputType == "string" or self.inputType == "number" or self.inputType == "file" then
		self.inputText = self.inputText .. text
		self.error = nil
	elseif self.inputType == "color" and _Utils.isValueInTable(self.COLOR_CHARACTERS, text) and self.inputText:len() < 6 then
		self.inputText = self.inputText .. text
		self:setInputColorHex(self.inputText)
	end
end



return Input