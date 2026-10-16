--!strict
local RunService = game:GetService("RunService")
local Storage = game:GetService("ReplicatedStorage")
local Skill = {}
-- Edit these server-owned defaults to customize this Tool. No asset is required.
Skill.Config = {
	Damage = 20, -- damage per living humanoid, once per click
	Cooldown = 0.75, -- seconds; at least 0.05
	Range = 6, -- forward reach in studs (also hitbox depth)
	HitboxWidth = 5,
	HitboxHeight = 5,
	AnimationId = "", -- optional rbxassetid://... compatible with your rig
	HitDelay = 0, -- seconds after animation starts before the hit
}
function Skill.Validate(): boolean
	local config = Skill.Config
	for _, key in { "HitboxWidth", "HitboxHeight" } do
		local value = config[key]
		if type(value) ~= "number" or value ~= value or value <= 0 or value >= math.huge then return false end
	end
	return true
end
function Skill.Cast(caster: Model, _aimPoint, isValid: () -> boolean)
	assert(RunService:IsServer(), "Melee damage must run on the server")
	if not isValid() then return end
	local root = caster:FindFirstChild("HumanoidRootPart") :: BasePart
	local config = Skill.Config
	local Hitbox = require(Storage:WaitForChild("CombatForge"):WaitForChild("Runtime"):WaitForChild("Hitbox"))
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
