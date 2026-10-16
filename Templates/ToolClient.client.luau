--!strict
-- Input only. The server owns all attack settings and damage.
local Players = game:GetService("Players")
local tool = script.Parent :: Tool
local remote = tool:WaitForChild("ActivateSkill") :: RemoteEvent
local Skill = require(tool:WaitForChild("Skill"))
local mouse = Players.LocalPlayer:GetMouse()
local connection = tool.Activated:Connect(function()
	if not tool.Enabled then return end
	if Skill.Config.AimMode == "Mouse" then
		remote:FireServer(mouse.Hit.Position) -- aim intent, never a target or damage
	else
		remote:FireServer()
	end
end)
script.Destroying:Connect(function() connection:Disconnect() end)
