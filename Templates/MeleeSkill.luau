--!strict
local RunService = game:GetService("RunService")
local Storage = game:GetService("ReplicatedStorage")
local Skill = {}
-- Advanced settings stay local. Edit shared damage/cooldown/range in Update Skills.
Skill.Config = {
	HitboxWidth = 5,
	HitboxHeight = 5,
	AnimationId = "", -- optional rbxassetid://... compatible with your rig
	HitDelay = 0, -- seconds after animation starts before the hit
}
-- Common settings come only from this Tool's explicit shared config link.
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
	if type(shared) ~= "table" or type(shared.Name) ~= "string" then return unavailable("config must return Name, Damage, Cooldown and Range") end
	for _, key in { "Damage", "Cooldown", "Range" } do
		local value = shared[key]
		if type(value) ~= "number" or value ~= value or value < 0 or value >= math.huge or (key == "Range" and value == 0) then
			return unavailable("invalid shared " .. key)
		end
	end
	local config = table.clone(Skill.Config)
	config.Damage = shared.Damage; config.Cooldown = shared.Cooldown; config.Range = shared.Range
	return config
end
function Skill.Validate(): boolean
	local config = Skill.Config
	for _, key in { "HitboxWidth", "HitboxHeight" } do
		local value = config[key]
		if type(value) ~= "number" or value ~= value or value <= 0 or value >= math.huge then return false end
	end
	return true
end
function Skill.Cast(caster: Model, _aimPoint, isValid: () -> boolean, config)
	assert(RunService:IsServer(), "Melee damage must run on the server")
	if not isValid() then return end
	local root = caster:FindFirstChild("HumanoidRootPart") :: BasePart
	local Hitbox = require(Storage.CombatForge.Runtime.Hitbox)
	local detector = Hitbox.Box(root.CFrame * CFrame.new(0, 0, -config.Range / 2),
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
