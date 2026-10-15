--!strict
-- NPC animations run on the server so every player sees the same idle.
local model = script.Parent
local humanoid = model:WaitForChild("Humanoid") :: Humanoid
if humanoid.Health <= 0 then return end
local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
	animator = Instance.new("Animator")
	animator.Parent = humanoid
end
local animation = Instance.new("Animation")
local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
animation.Name = if isR15 then "R15Idle" else "R6Idle"
animation.AnimationId = if isR15 then "rbxassetid://507766388" else "rbxassetid://180435571"
local ok, result = pcall(function() return animator:LoadAnimation(animation) end)
if not ok then
	animation:Destroy()
	warn("[CombatForge Dummy] Could not load " .. animation.Name .. ": " .. tostring(result))
	return
end
local track = result :: AnimationTrack
track.Priority = Enum.AnimationPriority.Idle
track.Looped = true
local connections: { RBXScriptConnection } = {}
local cleaned = false
local function cleanup()
	if cleaned then return end
	cleaned = true
	for _, connection in connections do connection:Disconnect() end
	track:Stop(0)
	track:Destroy()
	animation:Destroy()
end
table.insert(connections, humanoid.Died:Connect(cleanup))
table.insert(connections, script.Destroying:Connect(cleanup))
table.insert(connections, model.Destroying:Connect(cleanup))
if humanoid.Health > 0 then track:Play(0.2) else cleanup() end
