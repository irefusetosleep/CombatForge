--!strict
local Players = game:GetService("Players")
local History = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local DummySpawner = {}
local busy = false

-- Ordered from the root outwards: 15 joints connect 15 body parts plus the root.
local R15_JOINTS = {
	{ "Root", "HumanoidRootPart", "LowerTorso" },
	{ "Waist", "LowerTorso", "UpperTorso" },
	{ "Neck", "UpperTorso", "Head" },
	{ "LeftShoulder", "UpperTorso", "LeftUpperArm" },
	{ "LeftElbow", "LeftUpperArm", "LeftLowerArm" },
	{ "LeftWrist", "LeftLowerArm", "LeftHand" },
	{ "RightShoulder", "UpperTorso", "RightUpperArm" },
	{ "RightElbow", "RightUpperArm", "RightLowerArm" },
	{ "RightWrist", "RightLowerArm", "RightHand" },
	{ "LeftHip", "LowerTorso", "LeftUpperLeg" },
	{ "LeftKnee", "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftAnkle", "LeftLowerLeg", "LeftFoot" },
	{ "RightHip", "LowerTorso", "RightUpperLeg" },
	{ "RightKnee", "RightUpperLeg", "RightLowerLeg" },
	{ "RightAnkle", "RightLowerLeg", "RightFoot" },
}

local function stripR15Appearance(model: Model, humanoid: Humanoid, grey: Color3)
	-- The generated body already has its final dimensions; scale values are stripped.
	humanoid.AutomaticScalingEnabled = false
	local animator = humanoid:FindFirstChildOfClass("Animator")
	-- Retain only the body and its animation dependencies. Reject whole unsupported
	-- subtrees so accessory Handles and descendants of inherited scripts cannot survive.
	local function stripChildren(parent: Instance)
		for _, item in parent:GetChildren() do
			local keep = false
			if item:IsA("BasePart") and parent == model then
				keep = true
				item.Color = grey
				item.Material = Enum.Material.SmoothPlastic
				item.MaterialVariant = ""
				item.Reflectance = 0
				if item:IsA("MeshPart") then item.TextureID = "" end
			elseif item == humanoid and parent == model then
				keep = true
			elseif item == animator and parent == humanoid then
				keep = true
			elseif item.ClassName == "Attachment" and (parent:IsA("BasePart") or parent.ClassName == "Attachment") then
				keep = true
			elseif item:IsA("Motor6D") and parent:IsA("BasePart") then
				local part0, part1 = item.Part0, item.Part1
				keep = part0 ~= nil and part1 ~= nil and part0.Parent == model and part1.Parent == model
			end
			if keep then stripChildren(item) else item:Destroy() end
		end
	end
	stripChildren(model)
end

local function normalizeR15(model: Model, humanoid: Humanoid, grey: Color3)
	local requiresNeck = humanoid.RequiresNeck
	humanoid.RequiresNeck = false
	stripR15Appearance(model, humanoid, grey)
	local oldHead = model:FindFirstChild("Head")
	assert(oldHead and oldHead:IsA("BasePart"), "R15 dummy is missing its Head.")
	-- A plain block gives the face a planar front instead of the avatar mesh's UVs.
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = oldHead.Size
	head.CFrame = oldHead.CFrame
	head.PivotOffset = oldHead.PivotOffset
	head.Color = grey
	head.Material = Enum.Material.SmoothPlastic
	head.TopSurface = Enum.SurfaceType.Smooth
	head.BottomSurface = Enum.SurfaceType.Smooth
	head.CanCollide = oldHead.CanCollide
	head.CanTouch = oldHead.CanTouch
	head.CanQuery = oldHead.CanQuery
	head.CollisionGroup = oldHead.CollisionGroup
	head.Massless = oldHead.Massless
	head.CustomPhysicalProperties = oldHead.CustomPhysicalProperties
	head.Transparency = oldHead.Transparency
	head.CastShadow = oldHead.CastShadow
	head.Parent = model
	for _, item in oldHead:GetChildren() do
		if item.ClassName == "Attachment" then item.Parent = head end
	end
	if model.PrimaryPart == oldHead then model.PrimaryPart = head end
	oldHead:Destroy()

	-- Generated avatars may use AnimationConstraints. The whitelist removes those,
	-- so construct explicit Motor6Ds from matching rig attachments after cleanup.
	for _, item in model:GetDescendants() do
		if item:IsA("Motor6D") then item:Destroy() end
	end
	local parts: { [string]: BasePart } = {}
	local partCount = 0
	for _, item in model:GetChildren() do
		if item:IsA("BasePart") then
			assert(not parts[item.Name], "R15 dummy has duplicate body parts: " .. item.Name)
			parts[item.Name] = item
			partCount += 1
		end
	end
	assert(partCount == 16 and parts.HumanoidRootPart, "R15 dummy must contain 15 body parts and one root.")
	local connected: { [string]: boolean } = { HumanoidRootPart = true }
	for _, spec in R15_JOINTS do
		local name, parentName, childName = spec[1], spec[2], spec[3]
		local part0, part1 = parts[parentName], parts[childName]
		assert(part0 and part1, "R15 dummy is missing body parts for " .. name)
		assert(connected[parentName] and not connected[childName], "Invalid R15 joint tree: " .. name)
		local attachment0 = part0:FindFirstChild(name .. "RigAttachment")
		local attachment1 = part1:FindFirstChild(name .. "RigAttachment")
		assert(attachment0 and attachment0:IsA("Attachment"), "R15 dummy is missing parent attachment for " .. name)
		assert(attachment1 and attachment1:IsA("Attachment"), "R15 dummy is missing child attachment for " .. name)
		local joint = Instance.new("Motor6D")
		joint.Name = name
		joint.Part0 = part0
		joint.Part1 = part1
		joint.C0 = attachment0.CFrame
		joint.C1 = attachment1.CFrame
		joint.Parent = part1
		connected[childName] = true
	end
	local jointCount = 0
	for _, item in model:GetDescendants() do
		if item:IsA("Motor6D") then
			assert(item.Enabled and item.Part0 and item.Part1, "R15 dummy has a disconnected joint.")
			jointCount += 1
		end
	end
	assert(jointCount == 15, "R15 dummy must contain 15 Motor6D joints.")
	for name in parts do assert(connected[name], "R15 body part is disconnected from the root: " .. name) end
	humanoid.RequiresNeck = requiresNeck
end

function DummySpawner.spawn(rigType: Enum.HumanoidRigType?): (boolean, string)
	if RunService:IsRunning() then return false, "Stop the playtest before spawning a dummy." end
	if busy then return false, "A dummy is already being created." end
	busy = true
	local dummy: Model? = nil
	local description = Instance.new("HumanoidDescription")
	local grey = Color3.fromRGB(163, 162, 165)
	description.HeadColor = grey
	description.TorsoColor = grey
	description.LeftArmColor = grey
	description.RightArmColor = grey
	description.LeftLegColor = grey
	description.RightLegColor = grey
	local recording: string? = nil
	local usedOrigin = false
	local ok, failure = pcall(function()
		-- Capture the view before avatar creation yields. A missing camera is also a miss.
		local camera = workspace.CurrentCamera
		local params = RaycastParams.new()
		params.RespectCanCollide = true
		params.IgnoreWater = true
		local hit = if camera then workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 1000, params) else nil
		local model = Players:CreateHumanoidModelFromDescriptionAsync(description, rigType or Enum.HumanoidRigType.R6)
		dummy = model
		assert(not RunService:IsRunning(), "Stop the playtest before spawning a dummy.")
		model.Name = "Dummy"
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		assert(humanoid, "Could not create the dummy's Humanoid.")
		humanoid.DisplayName = "Dummy"
		humanoid.MaxHealth = 100
		humanoid.Health = 100
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
		humanoid.NameDisplayDistance = 1000
		humanoid.HealthDisplayDistance = 1000
		if humanoid.RigType == Enum.HumanoidRigType.R15 then
			normalizeR15(model, humanoid, grey)
		end
		local head = model:FindFirstChild("Head")
		assert(head, "Could not create the dummy's Head.")
		-- Clear inherited head textures before adding one clean classic face.
		if head:IsA("MeshPart") then head.TextureID = "" end
		for _, item in head:GetDescendants() do
			if item:IsA("Decal") or item:IsA("SurfaceAppearance") then
				item:Destroy()
			elseif item:IsA("SpecialMesh") then
				item.TextureId = ""
			end
		end
		local face = Instance.new("Decal")
		face.Name = "face"
		face.Face = Enum.NormalId.Front
		face.Texture = "rbxasset://textures/face.png"
		face.Parent = head
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") then
				item.Anchored = false
				item.Locked = false
			elseif item:IsA("Accessory") or item:IsA("Clothing") or item:IsA("ShirtGraphic") then
				item:Destroy()
			end
		end
		local idle = script:WaitForChild("IdleTemplate"):Clone() :: Script
		idle.Name = "DummyIdle"
		idle.Enabled = true
		idle.Parent = model
		if hit then
			-- Raise the pivot so the feet rest above the surface instead of inside it.
			local bounds, size = model:GetBoundingBox()
			local pivot = model:GetPivot()
			local feetOffset = pivot.Position.Y - (bounds.Position.Y - size.Y / 2)
			model:PivotTo(CFrame.new(hit.Position + Vector3.new(0, feetOffset + 0.05, 0)))
		else
			usedOrigin = true
			model:PivotTo(CFrame.new(0, 0, 0))
		end
		recording = History:TryBeginRecording("CombatForge.SpawnDummy", "Spawn CombatForge Dummy")
		assert(recording, "Could not begin undo recording. Try again.")
		model.Parent = workspace
		History:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Commit)
		recording = nil
	end)
	description:Destroy()
	busy = false
	if not ok then
		if dummy then dummy:Destroy() end
		if recording then
			pcall(function() History:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Cancel) end)
		end
		return false, "Could not spawn dummy: " .. tostring(failure)
	end
	if dummy then pcall(function() Selection:Set({ dummy :: Model }) end) end
	return true, if usedOrigin then "Spawned Dummy at (0, 0, 0): no surface ahead within 1,000 studs." else "Spawned Dummy where the camera is facing. Undo is available."
end

return DummySpawner
