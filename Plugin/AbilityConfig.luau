--!strict
-- Pure validation/serialization: never executes configuration scripts from a place.
local AbilityConfig = {}

export type Inputs = { Name: string, Damage: string, Cooldown: string, Range: string }
export type Config = {
	Name: string, Damage: number, Cooldown: number, Range: number,
	AnimationId: string?, HitDelay: number?, HitboxWidth: number?, HitboxHeight: number?,
	ProjectileSpeed: number?, ProjectileRadius: number?, ProjectileLifetime: number?, AimMode: string?,
	HitboxOffsetX: number?, HitboxOffsetY: number?, HitboxOffsetZ: number?,
	HitboxRotationX: number?, HitboxRotationY: number?, HitboxRotationZ: number?,
}
local fields = {
	"Name", "Damage", "Cooldown", "Range", "AnimationId", "HitDelay", "HitboxWidth", "HitboxHeight",
	"ProjectileSpeed", "ProjectileRadius", "ProjectileLifetime", "AimMode",
	"HitboxOffsetX", "HitboxOffsetY", "HitboxOffsetZ", "HitboxRotationX", "HitboxRotationY", "HitboxRotationZ",
}
local supported: { [string]: boolean } = {}
for _, field in fields do supported[field] = true end
local function finite(value): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

-- Advanced fields remain optional here so ordinary four-field abilities stay valid.
function AbilityConfig.validateConfig(values): (Config?, string?)
	if type(values) ~= "table" then return nil, "Settings must be a table." end
	for key in values do
		if not supported[key] then return nil, "Unsupported setting: " .. tostring(key) end
	end
	local name = values.Name
	if type(name) ~= "string" or #name == 0 or #name > 64 or not name:match("^[A-Za-z_][A-Za-z0-9_]*$") then
		return nil, "Name must be 1-64 letters, numbers or underscores, starting with a letter or underscore."
	end
	for _, field in { "Damage", "Cooldown", "Range" } do
		local value = values[field]
		if not finite(value) then return nil, field .. " must be a finite number." end
		if value < 0 or (field == "Range" and value == 0) then
			return nil, field .. (if field == "Range" then " must be greater than zero." else " cannot be negative.")
		end
	end
	for _, field in { "HitboxWidth", "HitboxHeight", "ProjectileSpeed", "ProjectileRadius", "ProjectileLifetime", "HitDelay" } do
		local value = values[field]
		if value ~= nil then
			if not finite(value) or value < 0 or (field ~= "HitDelay" and value == 0) then
				return nil, field .. " must be finite and " .. (if field == "HitDelay" then "nonnegative." else "greater than zero.")
			end
			local maximum = if field == "ProjectileRadius" then 256 elseif field == "ProjectileLifetime" then 60 elseif field == "HitDelay" then 30 else math.huge
			if value > maximum then return nil, field .. " exceeds " .. tostring(maximum) .. "." end
		end
	end
	local offsets = 0
	for _, field in { "HitboxOffsetX", "HitboxOffsetY", "HitboxOffsetZ" } do
		if values[field] ~= nil then
			offsets += 1
			if not finite(values[field]) then return nil, field .. " must be a finite number." end
		end
	end
	if offsets ~= 0 and offsets ~= 3 then return nil, "Supply all three hitbox offsets or omit all three." end
	local rotations = 0
	for _, field in { "HitboxRotationX", "HitboxRotationY", "HitboxRotationZ" } do
		if values[field] ~= nil then
			rotations += 1
			if not finite(values[field]) then return nil, field .. " must be a finite number." end
		end
	end
	if rotations ~= 0 and rotations ~= 3 then return nil, "Supply all three hitbox rotations or omit all three." end
	if values.AimMode ~= nil and values.AimMode ~= "Mouse" and values.AimMode ~= "Body" then return nil, "AimMode must be Mouse or Body." end
	if values.AnimationId ~= nil then
		if type(values.AnimationId) ~= "string" or #values.AnimationId > 1024 or values.AnimationId:find("[%z\1-\31\127]") then
			return nil, "AnimationId must be a string of at most 1024 bytes without ASCII control characters."
		end
	end
	local config = {}
	for _, field in fields do config[field] = values[field] end
	return config :: Config, nil
end

-- Geometry editing is restricted to complete melee configs, never inferred from names.
function AbilityConfig.isMelee(config): boolean
	local valid = AbilityConfig.validateConfig(config)
	if not valid or valid.HitboxWidth == nil or valid.HitboxHeight == nil or valid.AnimationId == nil or valid.HitDelay == nil then return false end
	for _, key in { "ProjectileSpeed", "ProjectileRadius", "ProjectileLifetime", "AimMode" } do
		if config[key] ~= nil then return false end
	end
	return true
end

function AbilityConfig.validate(inputs: Inputs): (Config?, string?)
	local name = string.match(inputs.Name, "^%s*(.-)%s*$") or ""
	local values: { [string]: any } = { Name = name }
	for _, field in { "Damage", "Cooldown", "Range" } do
		values[field] = tonumber((inputs :: any)[field])
	end
	return AbilityConfig.validateConfig(values)
end

local function quote(value: string): string
	-- This explicit subset matches the scanner; controls are rejected by validation.
	return '\"' .. value:gsub("\\", "\\\\"):gsub('\"', '\\\"') .. '\"'
end
function AbilityConfig.serialize(config: Config): string
	local valid, problem = AbilityConfig.validateConfig(config)
	assert(valid, problem)
	local lines = { "-- Generated by CombatForge", "return {" }
	for _, field in fields do
		local value = (valid :: any)[field]
		if value ~= nil then
			-- 17 significant digits preserve double-precision values through a source round trip.
			local literal = if type(value) == "string" then quote(value) else string.format("%.17g", value)
			table.insert(lines, "\t" .. field .. " = " .. literal .. ",")
		end
	end
	table.insert(lines, "}")
	return table.concat(lines, "\n") .. "\n"
end

-- A small literal scanner, not an evaluator. Delimiters/comments inside quotes are data.
-- Refuse custom syntax intact rather than overwriting executable configuration logic.
function AbilityConfig.parse(source: string): (Config?, string?)
	local unsupported = "This skill contains unsupported or custom Luau. Keep it unchanged and edit its ModuleScript directly."
	local cursor = 1
	local function skip()
		while cursor <= #source do
			local char = source:sub(cursor, cursor)
			if char:match("%s") then cursor += 1
			elseif source:sub(cursor, cursor + 1) == "--" then
				-- Long comments are outside the supported line-comment format.
				if source:sub(cursor + 2):match("^%[=*%[") then return false end
				local newline = source:find("[\r\n]", cursor + 2)
				cursor = newline or (#source + 1)
			else break end
		end
		return true
	end
	local function take(text: string): boolean
		if not skip() or source:sub(cursor, cursor + #text - 1) ~= text then return false end
		cursor += #text
		return true
	end
	local function identifier(): string?
		if not skip() then return nil end
		local value = source:sub(cursor):match("^([A-Za-z_][A-Za-z0-9_]*)")
		if value then cursor += #value end
		return value
	end
	local function literal(): any
		if not skip() then return nil end
		local char = source:sub(cursor, cursor)
		if char == '\"' or char == "'" then
			local delimiter = char
			cursor += 1
			local pieces = {}
			while cursor <= #source do
				char = source:sub(cursor, cursor); cursor += 1
				if char == delimiter then return table.concat(pieces) end
				if char == "\\" then
					char = source:sub(cursor, cursor); cursor += 1
					if char ~= "\\" and char ~= '\"' and char ~= "'" then return nil end
				end
				local byte = string.byte(char)
				if not byte or byte < 32 or byte == 127 then return nil end
				table.insert(pieces, char)
			end
			return nil
		end
		local remaining = source:sub(cursor)
		-- Match a single decimal literal, leaving adjacent line comments for skip().
		local token = remaining:match("^([%+%-]?%d+%.?%d*[eE][%+%-]?%d+)")
			or remaining:match("^([%+%-]?%.%d+[eE][%+%-]?%d+)")
			or remaining:match("^([%+%-]?%d+%.?%d*)")
			or remaining:match("^([%+%-]?%.%d+)")
		if not token then return nil end
		cursor += #token
		return tonumber(token)
	end
	if identifier() ~= "return" or not take("{") then return nil, unsupported end
	local values = {}
	if not skip() then return nil, unsupported end
	while source:sub(cursor, cursor) ~= "}" do
		local key = identifier()
		if not key or not supported[key] or values[key] ~= nil or not take("=") then return nil, unsupported end
		local value = literal()
		if value == nil then return nil, unsupported end
		values[key] = value
		if not skip() then return nil, unsupported end
		local delimiter = source:sub(cursor, cursor)
		if delimiter == "," or delimiter == ";" then cursor += 1
		elseif delimiter ~= "}" then return nil, unsupported end
		if not skip() then return nil, unsupported end
	end
	cursor += 1
	if not skip() or cursor <= #source then return nil, unsupported end
	return AbilityConfig.validateConfig(values)
end

return AbilityConfig
