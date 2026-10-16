--!strict
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
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
	for _, key in { "Name", "Damage", "Cooldown", "Range", "AnimationId", "HitDelay", "ProjectileSpeed", "ProjectileRadius", "ProjectileLifetime", "AimMode" } do config[key] = shared[key] end
	if not Skill.Validate(config) then return unavailable("config has missing or invalid required settings") end
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
	for _, key in { "ProjectileSpeed", "ProjectileRadius", "ProjectileLifetime" } do
		if not finite(config[key]) or config[key] <= 0 then return false end
	end
	return config.ProjectileRadius <= 256 and config.ProjectileLifetime <= 60
		and (config.AimMode == "Mouse" or config.AimMode == "Body")
end
local function humanoidFrom(part: BasePart): Humanoid?
	local parent: Instance? = part.Parent
	while parent and parent ~= workspace do
		if parent:IsA("Model") then
			local humanoid = parent:FindFirstChildOfClass("Humanoid")
			if humanoid then return humanoid end
		end
		parent = parent.Parent
	end
	return nil
end
function Skill.Cast(caster: Model, aimPoint, isValid: () -> boolean, config)
	assert(RunService:IsServer(), "Projectile damage must run on the server")
	if not isValid() then return end
	local root = caster:FindFirstChild("HumanoidRootPart") :: BasePart
	-- Begin at the server character, so a nearby wall cannot be skipped by a muzzle offset.
	local position = root.Position
	local direction = root.CFrame.LookVector
	if config.AimMode == "Mouse" then
		local delta = aimPoint - position
		if delta.Magnitude < 0.001 or delta.Magnitude >= math.huge then return end
		direction = delta.Unit
	end
	local visual = Instance.new("Part")
	visual.Name = "CombatForgeProjectile"
	visual.Shape = Enum.PartType.Ball
	visual.Size = Vector3.one * config.ProjectileRadius * 2
	visual.Anchored = true
	visual.CanCollide = false; visual.CanTouch = false; visual.CanQuery = false
	visual.Material = Enum.Material.Neon
	visual.Color = Color3.fromRGB(255, 190, 70)
	visual.CFrame = CFrame.new(position)
	visual.Parent = workspace
	Debris:AddItem(visual, config.ProjectileLifetime + 1)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { caster, visual }
	params.RespectCanCollide = false
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { caster, visual }
	overlap.RespectCanCollide = false
	local function impact(part: BasePart)
		local humanoid = humanoidFrom(part)
		if humanoid and humanoid.Health > 0 and not humanoid:IsDescendantOf(caster) and isValid() then
			humanoid:TakeDamage(config.Damage)
		end
	end
	local ok, failure = pcall(function()
		-- Spherecast does not detect an initial overlap. Check the actual sphere first.
		local initial = workspace:GetPartsInPart(visual, overlap)
		if #initial > 0 then impact(initial[1]); return end
		local distance = 0
		local elapsed = 0
		while isValid() and distance < config.Range and elapsed < config.ProjectileLifetime do
			local dt = RunService.Heartbeat:Wait()
			local remainingTime = math.min(dt, config.ProjectileLifetime - elapsed)
			elapsed += dt
			local step = math.min(config.ProjectileSpeed * remainingTime, config.Range - distance, 1024)
			if step <= 0 then break end
			if not isValid() then break end
			local hit = workspace:Spherecast(position, config.ProjectileRadius, direction * step, params)
			if hit then visual.Position = hit.Position; impact(hit.Instance); break end
			position += direction * step
			distance += step
			visual.Position = position
		end
	end)
	visual:Destroy()
	if not ok then error(failure) end
end
return Skill
