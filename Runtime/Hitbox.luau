--!strict
-- Standalone runtime module. Networking is opt-in; damage stays in your server skill.
local Players = game:GetService("Players")
local Hitbox = {}

export type Options = {
	Caster: Model | Player,
	CanHitCaster: boolean?,
	Filter: { Instance }?,
	WorldRoot: WorldRoot?,
}
export type Hit = {
	Target: Instance,
	Part: BasePart,
	Model: Model?,
	Humanoid: Humanoid?,
	Player: Player?,
}

local function finite(value: number): boolean
	return value == value and math.abs(value) < math.huge
end

local function vector(value: any, positive: boolean): boolean
	return typeof(value) == "Vector3" and finite(value.X) and finite(value.Y) and finite(value.Z)
		and (not positive or (value.X > 0 and value.Y > 0 and value.Z > 0))
end

local function validCFrame(value: any): boolean
	if typeof(value) ~= "CFrame" then return false end
	for _, component in { value:GetComponents() } do
		if not finite(component) then return false end
	end
	return true
end

-- Short-lived snapshots intentionally outlive detector:Destroy(), including the
-- temporary detectors used by network validation. Never participate in queries.
local function displayArea(shape: string, center: CFrame | Vector3, dimensions: Vector3 | number, world: WorldRoot)
	local preview = Instance.new("Part")
	preview.Name = "CombatForgeHitboxDebug"
	preview.Anchored = true
	preview.CanCollide = false
	preview.CanTouch = false
	preview.CanQuery = false
	preview.CastShadow = false
	preview.Material = Enum.Material.Neon
	preview.Color = Color3.fromRGB(70, 220, 140)
	preview.Transparency = 0.75
	if shape == "Box" then
		preview.Size = dimensions :: Vector3
		preview.CFrame = center :: CFrame
	else
		preview.Shape = Enum.PartType.Ball
		preview.Size = Vector3.one * (dimensions :: number) * 2
		preview.CFrame = CFrame.new(center :: Vector3)
	end
	preview.Parent = world
	game:GetService("Debris"):AddItem(preview, 0.25)
end

local function resolve(part: BasePart, world: WorldRoot): Hit
	local closestModel: Model? = nil
	local ancestor: Instance? = part.Parent
	while ancestor and ancestor ~= world do
		if ancestor:IsA("Model") then
			if not closestModel then closestModel = ancestor end
			local humanoid = ancestor:FindFirstChildOfClass("Humanoid")
			if humanoid then
				return { Target = ancestor, Part = part, Model = ancestor, Humanoid = humanoid, Player = Players:GetPlayerFromCharacter(ancestor) }
			end
		end
		ancestor = ancestor.Parent
	end
	return { Target = closestModel or part, Part = part, Model = closestModel, Humanoid = nil, Player = nil }
end

local function create(shape: string, origin: CFrame | Vector3, dimensions: Vector3 | number, options: Options, showDebug: boolean?)
	assert(showDebug == nil or type(showDebug) == "boolean", "showDebug must be a boolean")
	assert(type(options) == "table", "Hitbox options with a Caster are required")
	assert(typeof(options.Caster) == "Instance" and (options.Caster:IsA("Model") or options.Caster:IsA("Player")), "Caster must be a character Model or Player")
	assert(options.CanHitCaster == nil or type(options.CanHitCaster) == "boolean", "CanHitCaster must be a boolean")
	assert(options.Filter == nil or type(options.Filter) == "table", "Filter must be an array of Instances")
	local filter: { Instance } = {}
	for _, item in options.Filter or {} do
		assert(typeof(item) == "Instance", "Filter entries must be Instances")
		table.insert(filter, item)
	end
	local world = options.WorldRoot or workspace
	assert(typeof(world) == "Instance" and world:IsA("WorldRoot"), "WorldRoot must be Workspace or a WorldModel")
	local caster = options.Caster
	local canHitCaster = options.CanHitCaster == true
	local event = Instance.new("BindableEvent")
	local destroyed = false
	local detector = { HitDetected = event.Event }

	-- Each Cast is one scan and one deduplication window. Connect before calling it.
	function detector:Cast(newOrigin: (CFrame | Vector3)?): { Hit }
		assert(not destroyed, "Cannot cast a destroyed hitbox")
		local center = newOrigin or origin
		if shape == "Box" then
			assert(validCFrame(center), "Box origin must be a finite CFrame")
		else
			assert(vector(center, false), "Sphere origin must be a finite Vector3")
		end
		local excluded = table.clone(filter)
		if not canHitCaster then
			local character: Model? = if caster:IsA("Player") then caster.Character else caster :: Model
			-- Resolve a Player's current character on every cast, including after respawn.
			if character then table.insert(excluded, character) end
		end
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = excluded
		params.MaxParts = 0
		params.RespectCanCollide = false
		local parts: { BasePart }
		if shape == "Box" then
			parts = world:GetPartBoundsInBox(center :: CFrame, dimensions :: Vector3, params)
		else
			parts = world:GetPartBoundsInRadius(center :: Vector3, dimensions :: number, params)
		end
		if showDebug then displayArea(shape, center, dimensions, world) end
		local seen: { [Instance]: boolean } = {}
		local hits: { Hit } = {}
		for _, part in parts do
			local hit = resolve(part, world)
			if not seen[hit.Target] then
				seen[hit.Target] = true
				table.insert(hits, hit)
			end
		end
		for _, hit in hits do
			if destroyed then break end
			event:Fire(hit)
		end
		return hits
	end

	function detector:Destroy()
		if destroyed then return end
		destroyed = true
		event:Destroy()
	end
	return detector
end

function Hitbox.Box(cframe: CFrame, size: Vector3, options: Options, showDebug: boolean?)
	assert(validCFrame(cframe), "Box origin must be a finite CFrame")
	assert(vector(size, true), "Box size must contain positive finite dimensions")
	return create("Box", cframe, size, options, showDebug)
end

function Hitbox.Sphere(position: Vector3, radius: number, options: Options, showDebug: boolean?)
	assert(vector(position, false), "Sphere origin must be a finite Vector3")
	assert(type(radius) == "number" and finite(radius) and radius > 0, "Sphere radius must be positive and finite")
	return create("Sphere", position, radius, options, showDebug)
end

export type NetworkOptions = {
	Remote: RemoteEvent,
	Shape: string,
	Size: Vector3?,
	Radius: number?,
	Offset: CFrame?,
	Cooldown: number?,
	Filter: { Instance }?,
	CanHitCaster: boolean?,
	-- Server-only, required: check equipped skill, stun state, resources, etc.
	Authorize: ((Player) -> boolean)?,
	-- Optional server-only per-target rules (teams, walls, invulnerability).
	ValidateHit: ((Player, Hit) -> boolean)?,
}

-- One dedicated RemoteEvent and one server endpoint per skill. Client reports
-- candidate targets only; the server derives all geometry and hit records itself.
function Hitbox.ClientToServer(options: NetworkOptions, showDebug: boolean?)
	assert(showDebug == nil or type(showDebug) == "boolean", "showDebug must be a boolean")
	assert(type(options) == "table", "Network options are required")
	assert(typeof(options.Remote) == "Instance" and options.Remote:IsA("RemoteEvent"), "Remote must be a RemoteEvent")
	assert(options.Shape == "Box" or options.Shape == "Sphere", "Shape must be Box or Sphere")
	local shape = options.Shape
	local size, radius = options.Size, options.Radius
	if shape == "Box" then
		assert(vector(size, true), "Size must contain positive finite dimensions")
	else
		assert(type(radius) == "number" and finite(radius) and radius > 0, "Radius must be positive and finite")
	end
	local offset = options.Offset or CFrame.identity
	assert(validCFrame(offset), "Offset must be a finite CFrame")
	local cooldown = options.Cooldown or 0.25
	assert(type(cooldown) == "number" and finite(cooldown) and cooldown >= 0.05, "Cooldown must be at least 0.05 seconds")
	assert(options.CanHitCaster == nil or type(options.CanHitCaster) == "boolean", "CanHitCaster must be a boolean")
	assert(options.Filter == nil or type(options.Filter) == "table", "Filter must be an array of Instances")
	local filter = table.clone(options.Filter or {})
	for _, item in filter do assert(typeof(item) == "Instance", "Filter entries must be Instances") end
	local canHitCaster = options.CanHitCaster == true
	local remote = options.Remote
	local run = game:GetService("RunService")
	local server = run:IsServer()
	assert(server or run:IsClient(), "ClientToServer requires a running server or client")
	local authorize, validate = options.Authorize, options.ValidateHit
	assert(not server or type(authorize) == "function", "Server requires an Authorize(player) callback")
	assert(validate == nil or type(validate) == "function", "ValidateHit must be a function")
	local event = Instance.new("BindableEvent")
	local destroyed = false
	local readyAt = setmetatable({}, { __mode = "k" })
	local localReadyAt = 0
	local connection: RBXScriptConnection? = nil
	local endpoint = { HitDetected = if server then event.Event else nil, CandidateDetected = if not server then event.Event else nil }
	local function scan(character: Model): { Hit }
		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return {} end
		local center = root.CFrame * offset
		local detectorOptions = { Caster = character, Filter = filter, CanHitCaster = canHitCaster }
		local detector = if shape == "Box" then Hitbox.Box(center, size :: Vector3, detectorOptions, showDebug)
			else Hitbox.Sphere(center.Position, radius :: number, detectorOptions, showDebug)
		local hits = detector:Cast()
		detector:Destroy() -- use return values, not this temporary detector's events
		return hits
	end
	if server then
		connection = remote.OnServerEvent:Connect(function(player, candidates)
			if destroyed then return end
			local now = os.clock()
			if now < (readyAt[player] or 0) then return end
			readyAt[player] = now + cooldown -- throttle malformed and rejected requests too
			if type(candidates) ~= "table" then return end
			local requested: { [Instance]: boolean } = {}
			local count = 0
			for key, target in candidates do
				count += 1
				if count > 64 or type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > 64
					or typeof(target) ~= "Instance" or not target:IsDescendantOf(workspace) then return end
				requested[target] = true
			end
			local character = player.Character
			if not character or not character:IsDescendantOf(workspace) then return end
			local ok, allowed = pcall(authorize :: any, player)
			if not ok then warn("[CombatForge] Authorize failed: " .. tostring(allowed)); return end
			if allowed ~= true or destroyed or player.Character ~= character then return end
			for _, hit in scan(character) do
				if destroyed then break end
				if requested[hit.Target] then
					local valid = true
					if validate then
						local success, result = pcall(validate, player, hit)
						valid = success and result == true
						if not success then warn("[CombatForge] ValidateHit failed: " .. tostring(result)) end
					end
					if valid and not destroyed and player.Character == character then event:Fire(hit, player) end
				end
			end
		end)
	end
	function endpoint:Cast(): { Hit }
		assert(not destroyed, "Cannot cast a destroyed hitbox")
		assert(not server, "Call Cast on the client; connect HitDetected on the server")
		local now = os.clock()
		if now < localReadyAt then return {} end
		local character = Players.LocalPlayer.Character
		if not character then return {} end
		localReadyAt = now + cooldown
		local hits = scan(character)
		local candidates = {}
		local sent = {}
		for index = 1, math.min(#hits, 64) do
			local hit = hits[index]
			table.insert(candidates, hit.Target)
			table.insert(sent, hit)
		end
		remote:FireServer(candidates) -- send empty casts too, so misses consume server cooldown
		for _, hit in sent do if not destroyed then event:Fire(hit) end end
		return sent
	end
	function endpoint:Destroy()
		if destroyed then return end
		destroyed = true
		if connection then connection:Disconnect() end
		table.clear(readyAt)
		event:Destroy()
	end
	return endpoint
end

return Hitbox
