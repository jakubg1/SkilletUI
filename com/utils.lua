-- utils.lua by jakubg1
-- version for all the new stuff! (I need to find a more exhaustively edited one)

local utf8 = require("utf8")
local json = require("com.json")

local utils = {}



---Loads a file from a given path and returns its contents, or `nil` if the file has not been found.
---@param path string The path to the file.
---@return string?
function utils.loadFile(path)
	local file, err = io.open(path, "r")
	if not file then
		print(string.format("WARNING: Error during loading: \"%s\" (%s): expect errors!", path, err))
		return
	end
	io.input(file)
	local contents = io.read("*a")
	io.close(file)
	return contents
end

---Saves a file to the given path with the given contents. Errors out if the file cannot be created.
---@param path string The path to the file.
---@param data string The contents of the file.
function utils.saveFile(path, data)
	local file = io.open(path, "w")
	assert(file, string.format("SAVE FILE FAIL: %s", path))
	io.output(file)
	io.write(data)
	io.close(file)
end



---Loads a file from a given path and interprets it as JSON data. Returns `nil` if the file doesn't exist. Errors out if the file does not contain valid JSON data.
---@param path string The path to the file.
---@return table?
function utils.loadJson(path)
	print("Loading JSON data from " .. path .. "...")
	local contents = utils.loadFile(path)
	if not contents then
		return nil
	end
	local success, data = pcall(function() return json.decode(contents) end)
	assert(success, string.format("JSON error: %s: %s", path, data))
	assert(data, string.format("Could not JSON-decode: %s, error in file contents", path))
	return data
end

---Saves a file to the given path with the given contents, converted and beautified in JSON format. Errors out if the file cannot be created.
---@param path string The path to the file.
---@param data table The contents of the file.
function utils.saveJson(path, data)
	print("Saving JSON data to " .. path .. "...")
	utils.saveFile(path, utils.jsonBeautify(json.encode(data)))
end



-- This function allows to load images from external sources.
-- This is an altered code from https://love2d.org/forums/viewtopic.php?t=85350#p221460

---Opens an image file and returns its data. Returns `nil` if the file has not been found.
---@param path string The path to the file.
---@return love.ImageData?
function utils.loadImageData(path)
	local f = io.open(path, "rb")
	if f then
		local data = f:read("*all")
		f:close()
		if data then
			data = love.filesystem.newFileData(data, "tempname")
			data = love.image.newImageData(data)
			return data
		end
	end
end



---Opens an image file and constructs `love.Image` from it. Errors out if the file has not been found.
---@param path string The path to the file.
---@return love.Image
function utils.loadImage(path)
	local imageData = utils.loadImageData(path)
	assert(imageData, string.format("LOAD IMAGE FAIL: %s", path))
	local image = love.graphics.newImage(imageData)
	return image
end



-- This function allows to load sounds from external sources.
-- This is an altered code from the above function.

---Opens a sound file and returns its sound data. Returns `nil` if the file has not been found.
---@param path string The path to the file.
---@return love.SoundData?
function utils.loadSoundData(path)
	local f = io.open(path, "rb")
	if f then
		local data = f:read("*all")
		f:close()
		if data then
			-- to make everything work properly, we need to get the extension from the path, because it is used
			-- source: https://love2d.org/wiki/love.filesystem.newFileData
			local t = utils.strSplit(path, ".")
			local extension = t[#t]
			data = love.filesystem.newFileData(data, "tempname." .. extension)
			data = love.sound.newSoundData(data)
			return data
		end
	end
end



---Opens a sound file and constructs `love.Source` from it. Errors out if the file has not been found.
---@param path string The path to the file.
---@param type string How the sound should be loaded: `static` or `stream`.
---@return love.Source
function utils.loadSound(path, type)
	local soundData = utils.loadSoundData(path)
	assert(soundData, string.format("LOAD SOUND FAIL: %s", path))
	local sound = love.audio.newSource(soundData, type)
	return sound
end



-- This function allows to load fonts from external sources.
-- This is an altered code from the above function.

---Opens a font file and returns its font data. Returns `nil` if the file has not been found.
---@param path string The path to the file.
---@param size integer? The size of the font, in pixels. Defaults to LOVE-specified 12 pixels.
---@return love.Rasterizer?
function utils.loadFontData(path, size)
	local f = io.open(path, "rb")
	if f then
		local data = f:read("*all")
		f:close()
		if data then
			data = love.filesystem.newFileData(data, "tempname")
			data = love.font.newRasterizer(data, size)
			return data
		end
	end
end



---Opens a fond file and constructs `love.Font` from it. Errors out if the file has not been found.
---@param path string The path to the file.
---@param size integer? The size of the font, in pixels. Defaults to LOVE-specified 12 pixels.
---@return love.Font
function utils.loadFont(path, size)
	local fontData = utils.loadFontData(path, size)
	assert(fontData, string.format("LOAD FONT FAIL: %s", path))
	local font = love.graphics.newFont(fontData)
	return font
end



---Returns a list of directories and/or files in a given path.
---@param path string The path to the folder of which contents should be checked.
---@param filter string? `"dir"` will only list directories, `"file"` will only list files, `"all"` (default) will list both.
---@param extFilter string? If provided, files will have to end with this string in order to be listed. For example, `".json"` will only list `.json` files.
---@param recursive boolean? If set, files and directories will be checked recursively. Otherwise, only directories and files in this exact folder will be listed.
---@param pathRec string? Internal usage. Don't set.
---@return table
function utils.getDirListing(path, filter, extFilter, recursive, pathRec)
	-- filter can be "all", "dir" for directories only or "file" for files only.
	filter = filter or "all"
	pathRec = pathRec or ""

	local result = {}
	-- If it's compiled /fused/, this piece of code is needed to be able to read the external files
	if love.filesystem.isFused() then
		local success = love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), _FSPrefix)
		if not success then
			local msg = string.format("Failed to read contents of folder: \"%s\". Report this error to a developer.", path)
			error(msg)
		end
	end
	-- Now we can access the directory regardless of whether it's fused or not.
	local items = love.filesystem.getDirectoryItems(path .. "/" .. pathRec)
	-- Each folder will get a / character on the end BUT ONLY IN "ALL" FILTER so it's easier to tell whether this is a file or a directory.
	for i, item in ipairs(items) do
		local p = path .. "/" .. pathRec .. item
		if love.filesystem.getInfo(p).type == "directory" then
			if filter == "all" then
				table.insert(result, pathRec .. item .. "/")
			elseif filter == "dir" then
				table.insert(result, pathRec .. item)
			end
			if recursive then
				for j, file in ipairs(utils.getDirListing(path, filter, extFilter, true, pathRec .. item .. "/")) do
					table.insert(result, file)
				end
			end
		else
			if filter == "all" or filter == "file" and (not extFilter or utils.strEndsWith(item, extFilter)) then
				table.insert(result, pathRec .. item)
			end
		end
	end
	-- Unmount it so we don't get into safety problems.
	if pathRec == "" then
		love.filesystem.unmount(love.filesystem.getSourceBaseDirectory())
	end
	return result
end



---Returns `true` if the provided value is in the table.
---@param t table The table to be checked.
---@param v any The value to be checked. The function will return `true` if this value is inside the `t` table.
---@return boolean
function utils.isValueInTable(t, v)
	for i, n in pairs(t) do
		if n == v then
			return true
		end
	end
	return false
end



---Returns a table with combined entries of both tables. Duplicates are not removed.
---@param t1 table The first table.
---@param t2 table The second table.
---@return table
function utils.tableAdd(t1, t2)
	local t = {}
	for i, v in ipairs(t1) do
		table.insert(t, v)
	end
	for i, v in ipairs(t2) do
		table.insert(t, v)
	end
	return t
end



---Returns `true` if both tables are identical in contents. Shallow check is used.
---@param t1 table The first table.
---@param t2 table The second table to be compared with the first table.
function utils.areTablesIdentical(t1, t2)
	for i, n in pairs(t1) do
		if t2[i] ~= n then
			return false
		end
	end
	for i, n in pairs(t2) do
		if t1[i] ~= n then
			return false
		end
	end
	return true
end



---Returns an index of the value in the provided table, or `nil` if the value does not exist in the table.
---@param t table The table to be checked.
---@param v any The value to be checked. The function will return an index of the first matching value from the `t` table.
---@return any?
function utils.getKeyInTable(t, v)
	for i, n in pairs(t) do
		if n == v then
			return i
		end
	end
end



---Returns a list of all keys in table `t`, sorted alphabetically.
---@param t table The table from which the keys will be sourced.
---@return table
function utils.tableGetSortedKeys(t)
	local keys = {}
	for k, v in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys)
	return keys
end



---Removes the first matching occurence of the given value from the table.
---@param t table The table from which the value should be removed.
---@param v any The value to be removed.
function utils.removeValueFromTable(t, v)
	for i, n in pairs(t) do
		if n == v then
			if #t > 0 then
				-- We need to do this in order to preserve the index continuity.
				table.remove(t, i)
			else
				t[i] = nil
			end
			break
		end
	end
end



---Creates and returns a shallow copy of the given table.
---@param t table The table to be copied.
function utils.copyTable(t)
	local new = {}
	for k, v in pairs(t) do
		new[k] = v
	end
	return new
end



---Returns an index of the provided weight list, randomly picked from that list.
---For example, providing `{1, 2, 3}` will return `0` 1/6 of the time, `1` 2/6 of the time and `2` 3/6 of the time.
---@param weights table A list of integers, which depict the weights.
---@return integer
function utils.weightedRandom(weights)
	local t = 0
	for i, w in ipairs(weights) do
		t = t + w
	end
	local rnd = math.random(t) -- from 1 to t, inclusive, integer!!
	local i = 1
	while rnd > weights[i] do
		rnd = rnd - weights[i]
		i = i + 1
	end
	return i
end



---Splits a string `s` with the delimiter being `k` and returns a list of results.
---@param s string A string to be split.
---@param k string A delimiter which determines where to split `s`.
---@return table
function utils.strSplit(s, k)
	local t = {}
	local l = k:len()
	while true do
		local n = s:find("%" .. k)
		if n then
			table.insert(t, s:sub(1, n - 1))
			s = s:sub(n + l)
		else
			table.insert(t, s)
			return t
		end
	end
end



---Splits a string `str` into characters. UTF-8 characters are respected.
---@param str string A string to be split.
---@return table
function utils.strSplitChars(str)
    local characters = {}
    for i = 1, utf8.len(str) do
        table.insert(characters, str:sub(utf8.offset(str, i), utf8.offset(str, i + 1) - 1))
    end
    return characters
end



---Returns `true` if the string `s` starts with the clause `c`.
---@param s string The string to be searched.
---@param c string The expected beginning of the string `s`.
---@return boolean
function utils.strStartsWith(s, c)
	return s:sub(1, c:len()) == c
end



---Returns `true` if the string `s` ends with the clause `c`.
---@param s string The string to be searched.
---@param c string The expected ending of the string `s`.
---@return boolean
function utils.strEndsWith(s, c)
	return s:sub(s:len() - c:len() + 1) == c
end



---Combines a table of strings together to produce a string and returns the result.
---@param t table A table of strings to be combined.
---@param k string A delimiter which will separate the terms.
---@return string
function utils.strJoin(t, k)
	return table.concat(t, k)
end



---Trims whitespace from both the beginning and the end of a given string, and returns the result.
---Currently supported whitespace characters are `" "` and `"\t"`.
---@param s string A string to be truncated.
---@return string
function utils.strTrim(s)
	-- truncate leading whitespace
	while s:sub(1, 1) == " " or s:sub(1, 1) == "\t" do
        s = s:sub(2)
    end
	-- truncate trailing whitespace
	while s:sub(s:len(), s:len()) == " " or s:sub(s:len(), s:len()) == "\t" do
        s = s:sub(1, s:len() - 1)
    end

	return s
end



---Trims a line from a trailing comment.
---The only supported comment marker is `//`.
---
---Example: `"abcdef   // ghijkl"` will be truncated to `"abcdef"`.
---@param s string A string to be truncated.
---@return string
function utils.strTrimComment(s)
	-- truncate the comment part and trim
	return utils.strTrim(utils.strSplit(s, "//")[1])
end



---Strips the formatted text from formatting, if exists.
---@param s string|table A formatted string. If an unformatted string is passed, this function returns that string.
---@return string
function utils.strUnformat(s)
	if type(s) == "table" then
		local t = ""
		for i = 1, #s / 2 do
			t = t .. s[i * 2]
		end
		return t
	else
		return s
	end
end



---Checks whether the whole string is inside a single pair of brackets.
---For example, `(abcdef)` and `(abc(def))` will return `true`, but `(ab)cd(ef)` and `a(bcdef)` will return `false`.
---@param s string The string to be checked.
---@return boolean
function utils.strIsInWholeBracket(s)
	if s:sub(1, 1) ~= "(" or s:sub(s:len()) ~= ")" then
		return false
	end
	
	local pos = 2
	local brackets = 1

	-- Test whether this is the same bracket at the beginning and at the end.
	while pos < s:len() do
		-- Get the character.
		local c = s:sub(pos, pos)
		-- Update the bracket count.
		if c == "(" then
			brackets = brackets + 1
		elseif c == ")" then
			brackets = brackets - 1
		end
		-- If we're out of the root bracket, return false.
		if brackets == 0 then
			return false
		end
		pos = pos + 1
	end
	
	return true
end



---A simple function which makes JSON formatting nicer.
---@param s string Raw JSON input to be formatted.
---@return string
function utils.jsonBeautify(s)
	local indent = 0
	local ret = "" -- returned string
	local ln = "" -- current line
	local strMode = false -- if we're inside a string chain (")

	for i = 1, s:len() do
		local pc = s:sub(i-1, i-1) -- previous character
		local c = s:sub(i, i) -- this character
		local nc = s:sub(i+1, i+1) -- next character
		local strModePrev = false -- so we don't switch this back off on the way

		if not strMode and c == "\"" then
			strMode = true
			strModePrev = true
		end
		if strMode then -- strings are not JSON syntax, so they omit the formatting rules
			ln = ln .. c
			if not strModePrev and c == "\"" and pc ~= "\\" then
                strMode = false
            end
		else
			if (c == "]" or c == "}") and not (pc == "[" or pc == "{") then
				indent = indent - 1
				ret = ret .. ln .. "\n"
				ln = string.rep("\t", indent)			-- NEWLINE
			end
			ln = ln .. c
			if c == ":" then
				ln = ln .. " " -- spacing after colons, for more juice
			end
			if c == "," then
				ret = ret .. ln .. "\n"
				ln = string.rep("\t", indent)			-- NEWLINE
			end
			if (c == "[" or c == "{") and not (nc == "]" or nc == "}") then
				indent = indent + 1
				ret = ret .. ln .. "\n"
				ln = string.rep("\t", indent)			-- NEWLINE
			end
		end
	end

	ret = ret .. ln .. "\n"

	return ret
end



---Returns `true` if the given position is inside of a box of given position and size.
---If the point lies anywhere on the box's edge, the check will still pass.
---@param p Vector2 The point which is checked against.
---@param bp Vector2 The position of the upper left corner of the box.
---@param bs Vector2 The size of the box.
---@return boolean
function utils.isPointInsideBox(p, bp, bs)
	return p.x >= bp.x and p.y >= bp.y and p.x < (bp.x + bs.x) and p.y < (bp.y + bs.y)
end



---Returns `true` if two ranges of numbers intersect (at least one number is common).
---@param s1 number The start of the first range.
---@param e1 number The end of the first range.
---@param s2 number The start of the second range.
---@param e2 number The end of the second range.
---@return boolean
function utils.doRangesIntersect(s1, e1, s2, e2)
	return s1 <= e2 and s2 <= e1
end



---Returns `true` if the first range of numbers is fully contained within the second range.
---This function does NOT return `true` if the second range is contained in the first range!
---@param s1 number The start of the first range.
---@param e1 number The end of the first range.
---@param s2 number The start of the second range.
---@param e2 number The end of the second range.
---@return boolean
function utils.areRangesContained(s1, e1, s2, e2)
	return s1 >= s2 and e1 <= e2
end



---Returns `true` if the first box intersects the second box in any way.
---@param x1 number X position of the top left corner of the first box.
---@param y1 number Y position of the top left corner of the first box.
---@param w1 number Width of the first box.
---@param h1 number Height of the first box.
---@param x2 number X position of the top left corner of the second box.
---@param y2 number Y position of the top left corner of the second box.
---@param w2 number Width of the second box.
---@param h2 number Height of the second box.
---@return boolean
function utils.doBoxesIntersect(x1, y1, w1, h1, x2, y2, w2, h2)
	assert(w1 >= 0 and h1 >= 0 and w2 >= 0 and h2 >= 0, "Illegal boxes passed to `_Utils.doBoxesIntersect()`! You must normalize the boxes first using `_Utils.normalizeBox(x, y, w, h)`.")
	return utils.doRangesIntersect(x1, x1 + w1, x2, x2 + w2) and utils.doRangesIntersect(y1, y1 + h1, y2, y2 + h2)
end



---Returns `true` if the first box is fully contained in the second box.
---This function does NOT return `true` if the second box is contained in the first box instead!
---@param x1 number X position of the top left corner of the first box.
---@param y1 number Y position of the top left corner of the first box.
---@param w1 number Width of the first box.
---@param h1 number Height of the first box.
---@param x2 number X position of the top left corner of the second box.
---@param y2 number Y position of the top left corner of the second box.
---@param w2 number Width of the second box.
---@param h2 number Height of the second box.
---@return boolean
function utils.areBoxesContained(x1, y1, w1, h1, x2, y2, w2, h2)
	assert(w1 >= 0 and h1 >= 0 and w2 >= 0 and h2 >= 0, "Illegal boxes passed to `_Utils.doBoxesIntersect()`! You must normalize the boxes first using `_Utils.normalizeBox(x, y, w, h)`.")
	return utils.areRangesContained(x1, x1 + w1, x2, x2 + w2) and utils.areRangesContained(y1, y1 + h1, y2, y2 + h2)
end



---Normalizes a box to make sure it does not have a negative width and/or height.
---@param x number X position of the top left corner of the box.
---@param y number Y position of the top left corner of the box.
---@param w number Width of the box.
---@param h number Height of the box.
---@return number, number, number, number
function utils.normalizeBox(x, y, w, h)
	return math.min(x, x + w), math.min(y, y + h), math.abs(w), math.abs(h)
end



---Removes all dead objects from the table `t`. By dead objects we mean objects that have their `delQueue` field set to `true`.
---The table must be a list-like. Other keysets are not supported.
---@param t table The table to be cleaned up.
function utils.removeDeadObjects(t)
	for i = #t, 1, -1 do
		if t[i].delQueue then
			table.remove(t, i)
		end
	end
end



function utils.interpolate(a, b, t)
	return a * (1 - t) + b * t
end



function utils.interpolateClamped(a, b, t)
	return utils.interpolate(a, b, math.min(math.max(t, 0), 1))
end



function utils.interpolate2(a, b, t1, t2, t)
	return utils.interpolate(a, b, (t - t1) / (t2 - t1))
end



function utils.interpolate2Clamped(a, b, t1, t2, t)
	return utils.interpolate(a, b, math.min(math.max((t - t1) / (t2 - t1), 0), 1))
end



---Returns a value in range from `-1` to `1` based on the sine wave.
---@param frequency number The frequency of the wave.
---@param speed number The speed of the wave.
---@param offset number The offset of the wave.
---@param time number The time.
---@return number
function utils.getWavePoint(frequency, speed, offset, time)
	return math.sin(((offset - speed * time) / frequency) % 1 * math.pi * 2)
end



---Returns `true` if both provided values are close enough to be considered equal. Useful for places where there is floating point imprecision.
---@param a number The first number to compare.
---@param b number The second number to compare.
---@param e number? The margin of error. Defaults to `1e-9`.
---@return boolean
function utils.almostEqual(a, b, e)
	e = e or 1e-9
	return a > b - e and a < b + e
end



---Takes a table with a required `key` string field and optional `ctrl` and `shift` boolean fields.
---Returns a human-readable shortcut name.
---@param shortcut table The shortcut to be turned into a string.
---@return string
function utils.getShortcutString(shortcut)
	local value = string.format("[%s]", shortcut.key)
	if shortcut.shift then
		value = "Shift + " .. value
	end
	if shortcut.ctrl then
		value = "Ctrl + " .. value
	end
	return value
end



---Strips the extension from a path to a file.
---@param path string The path to have its extension stripped.
---@return string
function utils.pathStripExtension(path)
	local spl = utils.strSplit(path, ".")
	spl[#spl] = nil
	return utils.strJoin(spl, ".")
end




return utils
