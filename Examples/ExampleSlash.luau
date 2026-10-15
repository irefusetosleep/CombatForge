--!strict
-- Server-side skill logic. The editable configuration stays separate from behaviour.
local RunService = game:GetService("RunService")
local Storage = game:GetService("ReplicatedStorage")
local combatForge = Storage:WaitForChild("CombatForge")
local Hitbox = require(combatForge:WaitForChild("Runtime"):WaitForChild("Hitbox"))
local Config = require(combatForge:WaitForChild("Abilities"):WaitForChild("ExampleSlash"))
local Skill = {}
local readyAt: { [Humanoid]: number } = setmetatable({}, { __mode = "k" }) :: any
local damagedByCaster: { [Model]: { [Instance]: boolean } } = setmetatable({}, { __mode = "k" }) :: any

local function damage(caster: Model, hit, damaged: { [Instance]: boolean })
	if hit.Humanoid and hit.Target ~= caster and hit.Humanoid.Health > 0 and not damaged[hit.Target] then
		damaged[hit.Target] = true
		hit.Humanoid:TakeDamage(Config.Damage)
		print("[CombatForge ExampleSlash] Hit", hit.Target.Name, "for", Config.Damage)
	end
end

-- Called by the Tool's server script after it verifies who equipped the Tool.
function Skill.Activate(caster: Model): boolean
	assert(RunService:IsServer(), "ExampleSlash must execute on the server")
	local humanoid = caster:FindFirstChildOfClass("Humanoid")
	local root = caster:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return false end
	local now = os.clock()
	if now < (readyAt[humanoid] or 0) then return false end
	for _, key in { "Damage", "Cooldown", "Range" } do
		local value = Config[key]
		assert(type(value) == "number" and value == value and math.abs(value) < math.huge and value >= 0, "Invalid ExampleSlash " .. key)
	end
	assert(Config.Range > 0, "ExampleSlash Range must be positive")
	readyAt[humanoid] = now + Config.Cooldown

	local damaged: { [Instance]: boolean } = {}
	damagedByCaster[caster] = damaged
	-- Left box: regular server detection. Right box: ClientToServer below.
	-- They overlap slightly to demonstrate shared damage deduplication.
	local center = root.CFrame * CFrame.new(-1.5, 0, -Config.Range / 2)
	local size = Vector3.new(4, 5, Config.Range)
	local detector = Hitbox.Box(center, size, { Caster = caster, CanHitCaster = false, Filter = {} }, true)
	detector.HitDetected:Connect(function(hit)
		damage(caster, hit, damaged)
	end)
	-- Keep the detector alive while deferred listeners run; always release it afterward.
	task.delay(1, function() detector:Destroy() end)
	detector:Cast()

	return true
end

function Skill.Bind(tool: Tool, remote: RemoteEvent)
	assert(RunService:IsServer(), "ExampleSlash must execute on the server")
	local endpoint = Hitbox.ClientToServer({
		Remote = remote,
		Shape = "Box",
		Size = Vector3.new(4, 5, Config.Range),
		Offset = CFrame.new(1.5, 0, -Config.Range / 2),
		Cooldown = math.max(0.05, Config.Cooldown),
		CanHitCaster = false,
		Filter = {},
		Authorize = function(player: Player)
			local caster = player.Character
			if not caster or tool.Parent ~= caster or not tool.Enabled then return false end
			-- One accepted report starts BOTH scans and their shared damage window.
			return Skill.Activate(caster)
		end,
	}, true) -- server validation preview
	endpoint.HitDetected:Connect(function(hit, player: Player)
		local caster = player.Character
		local damaged = if caster then damagedByCaster[caster] else nil
		if caster and damaged and tool.Parent == caster then damage(caster, hit, damaged) end
	end)
	return endpoint
end

return Skill
