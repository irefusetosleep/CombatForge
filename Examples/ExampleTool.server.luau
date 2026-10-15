--!strict
local tool = script.Parent :: Tool
local request = tool:WaitForChild("ActivateSkill") :: RemoteEvent
local Skill = require(tool:WaitForChild("Skill"))
-- The network endpoint validates the report and starts the regular scan too.
-- Do not also connect the old activation handler: that would create a second attack.
local endpoint = Skill.Bind(tool, request)
script.Destroying:Connect(function() endpoint:Destroy() end)
