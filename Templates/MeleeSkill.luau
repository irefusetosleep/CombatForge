--!strict
local RunService = game:GetService("RunService")
local Storage = game:GetService("ReplicatedStorage")
local Skill = {}
-- All settings come only from this Tool's explicit shared config link.
function Skill.GetConfig()
	local function unavailable(reason)
		warn("[CombatForge Template] " .. script.Parent.Name .. ": " .. reason .. ". Restore Skill.Config and its ModuleScript in ReplicatedStorage.CombatForge.Abilities; restart Play.")
		return nil
	end
	local link = script:FindFirstChild("Config")
	if not link or not link:IsA("ObjectValue") then return unavailable("missing or invalid Config ObjectValue") end
	local module = link.Value
	local storage = game:GetService("ReplicatedStorage")
	local root = storage:FindFirstChild("CombatForge")
	local abilities = if root and root:IsA("Folder") then root:FindFirstChild("Abilities") else nil
	if not module or not module:IsA("ModuleScript") or not abilities or not abilities:IsA("Folder") or module.Parent ~= abilities then
		return unavailable("linked config is missing, deleted or outside Abilities")
	end
	local ok, shared = pcall(require, module)
	if not ok then return unavailable("config could not load: " .. tostring(shared)) end
	if type(shared) ~= "table" then return unavailable("config must return a settings table") end
	-- Capture scalar values once; delayed attacks never reread a mutable required table.
	local config = {}
	for _, key in { "Name", "Damage", "Cooldown", "Range", "AnimationId", "HitDelay", "HitboxWidth", "HitboxHeight", "HitboxOffsetX", "HitboxOffsetY", "HitboxOffsetZ", "HitboxRotationX", "HitboxRotationY", "HitboxRotationZ" } do config[key] = shared[key] end
	if not Skill.Validate(config) then return unavailable("config has missing or invalid required settings") end
	if config.HitboxOffsetX == nil then
		config.HitboxOffsetX = 0; config.HitboxOffsetY = 0; config.HitboxOffsetZ = 0
	end
	return config
end
local function finite(value): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function Skill.Validate(config): boolean
	if type(config) ~= "table" or type(config.Name) ~= "string" or #config.Name == 0 or #config.Name > 64
		or not config.Name:match("^[A-Za-z_][A-Za-z0-9_]*$") then return false end
	for _, key in { "Damage", "Cooldown", "Range", "HitDelay" } do
		if not finite(config[key]) or config[key] < 0 then return false end
	end
	if config.Range <= 0 or config.HitDelay > 30 or type(config.AnimationId) ~= "string"
		or #config.AnimationId > 1024 or config.AnimationId:find("[%z\1-\31\127]") then return false end
	for _, key in { "HitboxWidth", "HitboxHeight" } do
		if not finite(config[key]) or config[key] <= 0 then return false end
	end
	local offsets = 0
	for _, key in { "HitboxOffsetX", "HitboxOffsetY", "HitboxOffsetZ" } do
		if config[key] ~= nil then
			offsets += 1
			if not finite(config[key]) then return false end
		end
	end
	if offsets ~= 0 and offsets ~= 3 then return false end
	local rotations = 0
	for _, key in { "HitboxRotationX", "HitboxRotationY", "HitboxRotationZ" } do
		if config[key] ~= nil then
			rotations += 1
			if not finite(config[key]) then return false end
		end
	end
	if rotations ~= 0 and rotations ~= 3 then return false end
	return true
end
function Skill.Cast(caster: Model, _aimPoint, isValid: () -> boolean, config)
	assert(RunService:IsServer(), "Melee damage must run on the server")
	if not isValid() then return end
	local root = caster:FindFirstChild("HumanoidRootPart") :: BasePart
	local Hitbox = require(Storage.CombatForge.Runtime.Hitbox)
	local detector = Hitbox.Box(root.CFrame * CFrame.new(config.HitboxOffsetX or 0, config.HitboxOffsetY or 0, -config.Range / 2 + (config.HitboxOffsetZ or 0))
		* CFrame.fromOrientation(math.rad((config.HitboxRotationX or 0) % 360), math.rad((config.HitboxRotationY or 0) % 360), math.rad((config.HitboxRotationZ or 0) % 360)),
		Vector3.new(config.HitboxWidth, config.HitboxHeight, config.Range), { Caster = caster })
	local ok, hits = pcall(function() return detector:Cast() end)
	detector:Destroy()
	if not ok then error(hits) end
	local damaged = {}
	for _, hit in hits do
		if not isValid() then break end
		if hit.Target ~= caster and hit.Humanoid and hit.Humanoid.Health > 0 and not damaged[hit.Humanoid] then
			damaged[hit.Humanoid] = true
			hit.Humanoid:TakeDamage(config.Damage)
		end
	end
end
return Skill
