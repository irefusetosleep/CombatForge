--!strict
local Theme = {}
local HttpService = game:GetService("HttpService")
local KEY = "CombatForgeThemeV1"
export type Settings = { mode: string, background: string, surface: string, text: string, accent: string }
local dark = { mode = "Dark", background = "181B21", surface = "252A33", text = "E4EAF2", accent = "64DCA0" }
local light = { mode = "Light", background = "F4F6FA", surface = "E2E7EF", text = "202936", accent = "167A50" }

function Theme.hex(value: any): string?
	if type(value) ~= "string" then return nil end
	local trimmed = value:match("^%s*(.-)%s*$") or ""
	trimmed = trimmed:gsub("^#", "")
	if #trimmed ~= 6 or not trimmed:match("^%x+$") then return nil end
	return string.upper(trimmed)
end

function Theme.validate(value: any): (Settings?, string?)
	if type(value) ~= "table" or (value.mode ~= "Dark" and value.mode ~= "Light" and value.mode ~= "Custom") then
		return nil, "Choose Dark, Light or Custom."
	end
	local result = { mode = value.mode } :: any
	for _, key in { "background", "surface", "text", "accent" } do
		result[key] = Theme.hex(value[key])
		if not result[key] then return nil, key .. " must be a six-digit hex colour, such as #64DCA0." end
	end
	return result, nil
end

function Theme.export(settings: Settings): (string?, string?)
	local valid, problem = Theme.validate(settings)
	if not valid then return nil, problem end
	return HttpService:JSONEncode({ format = "CombatForgeTheme", version = 1, colours = {
		background = valid.background, surface = valid.surface, text = valid.text, accent = valid.accent,
	} }), nil
end

function Theme.import(code: string): (Settings?, string?)
	if #code > 4096 then return nil, "Theme code is too long (maximum 4096 characters)." end
	local ok, data = pcall(function() return HttpService:JSONDecode(code) end)
	if not ok or type(data) ~= "table" then return nil, "Paste a valid CombatForge theme code." end
	if data.format ~= "CombatForgeTheme" or data.version ~= 1 or type(data.colours) ~= "table" then
		return nil, "This is not a supported CombatForge theme code (version 1)."
	end
	return Theme.validate({ mode = "Custom", background = data.colours.background, surface = data.colours.surface, text = data.colours.text, accent = data.colours.accent })
end

function Theme.palette(settings: Settings)
	local source = if settings.mode == "Light" then light elseif settings.mode == "Dark" then dark else settings
	local function colour(hex: string): Color3
		return Color3.fromRGB(tonumber(hex:sub(1, 2), 16) :: number, tonumber(hex:sub(3, 4), 16) :: number, tonumber(hex:sub(5, 6), 16) :: number)
	end
	local background = colour(source.background)
	local accent = colour(source.accent)
	local function brightness(c: Color3): number return c.R * 0.299 + c.G * 0.587 + c.B * 0.114 end
	return {
		background = background, surface = colour(source.surface), text = colour(source.text), accent = accent,
		accentText = if brightness(accent) > 0.55 then Color3.fromRGB(20, 25, 30) else Color3.new(1, 1, 1),
		success = if brightness(background) > 0.55 then Color3.fromRGB(15, 110, 65) else Color3.fromRGB(100, 220, 160),
		error = if brightness(background) > 0.55 then Color3.fromRGB(170, 35, 40) else Color3.fromRGB(255, 160, 150),
	}
end

function Theme.new(pluginRef: Plugin?)
	local current: Settings = table.clone(dark)
	if pluginRef then
		local ok, saved = pcall(function() return pluginRef:GetSetting(KEY) end)
		if ok then
			local valid = Theme.validate(saved)
			if valid then current = valid end
		else warn("[CombatForge] Could not load theme; using Dark.") end
	end
	return {
		get = function(): Settings return table.clone(current) end,
		save = function(candidate: Settings): (boolean, string)
			local valid, problem = Theme.validate(candidate)
			if not valid then return false, problem or "Invalid theme." end
			if pluginRef then
				local ok, failure = pcall(function()
					pluginRef:SetSetting(KEY, valid)
					local readBack = Theme.validate(pluginRef:GetSetting(KEY))
					if not readBack then error("Could not verify saved settings.") end
					for key, value in valid do
						if (readBack :: any)[key] ~= value then error("Settings changed in another Studio window. Try again.") end
					end
				end)
				if not ok then return false, "Could not save theme: " .. tostring(failure) end
			end
			current = valid
			return true, "Theme saved."
		end,
	}
end

return Theme
