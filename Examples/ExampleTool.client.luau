--!strict
local Storage = game:GetService("ReplicatedStorage")
local combatForge = Storage:WaitForChild("CombatForge")
local Hitbox = require(combatForge:WaitForChild("Runtime"):WaitForChild("Hitbox"))
local Config = require(combatForge:WaitForChild("Abilities"):WaitForChild("ExampleSlash"))
local tool = script.Parent :: Tool
local request = tool:WaitForChild("ActivateSkill") :: RemoteEvent
local endpoint = Hitbox.ClientToServer({
    Remote = request,
    Shape = "Box",
    Size = Vector3.new(4, 5, Config.Range),
    Offset = CFrame.new(1.5, 0, -Config.Range / 2),
    Cooldown = math.max(0.05, Config.Cooldown),
    CanHitCaster = false,
    Filter = {},
}, true) -- local prediction preview; never apply damage here

tool.Activated:Connect(function()
    endpoint:Cast() -- reports candidates; the server also runs the regular left box
end)
script.Destroying:Connect(function() endpoint:Destroy() end)
