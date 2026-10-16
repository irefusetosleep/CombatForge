--!strict
-- Pipeline: authorize input -> optional animation -> HitDelay -> server Cast.
local tool = script.Parent :: Tool
local remote = tool:WaitForChild("ActivateSkill") :: RemoteEvent
local Skill = require(tool:WaitForChild("Skill"))
local readyAt = 0
local generation = 0
local alive = true
local tracks: { [AnimationTrack]: { RBXScriptConnection } } = {}
local connections: { RBXScriptConnection } = {}

local function finite(value): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function validVector(value): boolean
	return typeof(value) == "Vector3" and finite(value.X) and finite(value.Y) and finite(value.Z)
end
local function releaseTrack(track: AnimationTrack)
	local listeners = tracks[track]
	if not listeners then return end
	tracks[track] = nil
	for _, listener in listeners do listener:Disconnect() end
	pcall(function() track:Stop(); track:Destroy() end)
end
local function stopTracks()
	for track in tracks do releaseTrack(track) end
end
local function invalidate()
	generation += 1
	stopTracks()
end
local function cleanup()
	if not alive then return end
	alive = false
	invalidate()
	for _, connection in connections do connection:Disconnect() end
	table.clear(connections)
end

table.insert(connections, tool.Unequipped:Connect(invalidate))
table.insert(connections, tool.AncestryChanged:Connect(invalidate))
table.insert(connections, tool.Destroying:Connect(cleanup))
table.insert(connections, script.Destroying:Connect(cleanup))
table.insert(connections, remote.OnServerEvent:Connect(function(player, aimPoint)
	local caster = player.Character
	if not alive or not caster or tool.Parent ~= caster or not tool.Enabled then return end
	local humanoid = caster:FindFirstChildOfClass("Humanoid")
	local root = caster:FindFirstChild("HumanoidRootPart")
	if not caster:IsDescendantOf(workspace) or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return end
	local config = Skill.Config
	if type(config) ~= "table" then return end
	for _, key in { "Damage", "Cooldown", "Range", "HitDelay" } do
		if not finite(config[key]) or config[key] < 0 then return end
	end
	if config.Range <= 0 or config.Cooldown < 0.05 or config.HitDelay > 30 or type(config.AnimationId) ~= "string" then return end
	if config.AimMode ~= nil and config.AimMode ~= "Mouse" and config.AimMode ~= "Body" then return end
	if config.AimMode == "Mouse" and not validVector(aimPoint) then return end
	local settingsOK, validSettings = pcall(Skill.Validate)
	if not settingsOK or not validSettings then return end
	local now = os.clock()
	if now < readyAt then return end
	readyAt = now + config.Cooldown
	local token = generation
	local function isValid(): boolean
		return alive and token == generation and player.Character == caster and tool.Parent == caster and tool.Enabled
			and caster:IsDescendantOf(workspace) and humanoid.Parent == caster and humanoid.Health > 0 and root.Parent == caster
	end
	local track: AnimationTrack? = nil
	local death = humanoid.Died:Connect(invalidate)
	if config.AnimationId ~= "" then
		local animation = Instance.new("Animation")
		local ok, failure = pcall(function()
			animation.AnimationId = config.AnimationId
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if not animator then animator = Instance.new("Animator"); animator.Parent = humanoid end
			track = animator:LoadAnimation(animation)
			local playing = track :: AnimationTrack
			tracks[playing] = {}
			table.insert(tracks[playing], playing.Ended:Connect(function() releaseTrack(playing) end))
			table.insert(tracks[playing], humanoid.Died:Connect(function() releaseTrack(playing) end))
			playing.Looped = false
			playing.Priority = Enum.AnimationPriority.Action
			playing:Play()
			-- Attack completion must not truncate a zero-delay melee animation.
			-- Natural Ended/teardown releases it; cap broken or unloaded assets at 30s.
			task.delay(30, function() releaseTrack(playing) end)
		end)
		animation:Destroy()
		if not ok then
			if track then releaseTrack(track) end
			warn("[CombatForge Template] Animation skipped: " .. tostring(failure))
		end
	end
	task.spawn(function()
		if config.HitDelay > 0 then task.wait(config.HitDelay) end
		local ok, failure = pcall(function()
			if isValid() then Skill.Cast(caster, aimPoint, isValid) end
		end)
		death:Disconnect()
		if not ok then warn("[CombatForge Template] Attack failed: " .. tostring(failure)) end
	end)
end))
