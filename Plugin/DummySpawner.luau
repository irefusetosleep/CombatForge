--!strict
local Players = game:GetService("Players")
local History = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local DummySpawner = {}
local busy = false

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
