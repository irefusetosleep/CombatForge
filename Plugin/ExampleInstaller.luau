--!strict
local History = game:GetService("ChangeHistoryService")
local Storage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local RunService = game:GetService("RunService")
local Editor = game:GetService("ScriptEditorService")
local AbilityConfig = require(script.Parent.AbilityConfig)
local ExampleInstaller = {}

local function unique(parent: Instance, name: string, class: string): Instance?
	local found: Instance? = nil
	for _, child in parent:GetChildren() do
		if child.Name == name then
			assert(not found and child:IsA(class), parent:GetFullName() .. "." .. name .. " is occupied by conflicting objects")
			found = child
		end
	end
	return found
end

function ExampleInstaller.install(hitbox: ModuleScript, config: ModuleScript, tool: Tool): (boolean, string)
	if RunService:IsRunning() then return false, "Stop the playtest before installing the example." end
	local recording: string? = nil
	local created: { Instance } = {}
	local ok, failure = pcall(function()
		local root = unique(Storage, "CombatForge", "Folder")
		local runtime = if root then unique(root, "Runtime", "Folder") else nil
		local abilities = if root then unique(root, "Abilities", "Folder") else nil
		local existingHitbox = if runtime then unique(runtime, "Hitbox", "ModuleScript") else nil
		local existingConfig = if abilities then unique(abilities, "ExampleSlash", "ModuleScript") else nil
		local existingTool = unique(StarterPack, "CombatForge Example Slash", "Tool")
		if existingHitbox then
			assert(Editor:GetEditorSource(existingHitbox :: ModuleScript) == hitbox.Source, "Existing Hitbox differs from the example's runtime; back it up and rename it before installing.")
		end
		if existingConfig then
			assert(AbilityConfig.parse(Editor:GetEditorSource(existingConfig :: ModuleScript)), "Existing ExampleSlash is not a supported configuration; back it up and rename it first.")
		end
		if existingTool then
			-- Do not overwrite a developer's edited example. An existing complete tool is left intact.
			for _, child in tool:GetChildren() do
				local found = unique(existingTool, child.Name, child.ClassName)
				assert(found, "Existing example Tool is incomplete; back it up and rename it before reinstalling.")
			end
		end
		if existingHitbox and existingConfig and existingTool then return end
		recording = History:TryBeginRecording("CombatForge.InstallExample", "Install CombatForge Example Slash")
		assert(recording, "Could not begin undo recording. Try again.")
		local function makeFolder(parent: Instance, name: string): Instance
			local item = Instance.new("Folder"); table.insert(created, item)
			item.Name = name; item.Parent = parent; return item
		end
		local function copy(template: Instance, parent: Instance, name: string)
			local item = template:Clone(); table.insert(created, item)
			-- Bundled scripts stay disabled inside the plugin; enable only the game copy.
			if item:IsA("Tool") then
				for _, child in item:GetChildren() do
					if child:IsA("BaseScript") then child.Enabled = true end
				end
			end
			item.Name = name; item.Parent = parent
		end
		root = root or makeFolder(Storage, "CombatForge")
		runtime = runtime or makeFolder(root, "Runtime")
		abilities = abilities or makeFolder(root, "Abilities")
		if not existingHitbox then copy(hitbox, runtime, "Hitbox") end
		if not existingConfig then copy(config, abilities, "ExampleSlash") end
		if not existingTool then copy(tool, StarterPack, "CombatForge Example Slash") end
		History:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Commit)
		recording = nil
	end)
	if not ok then
		for _, item in created do item:Destroy() end
		if recording then
			local cancelled, problem = pcall(function() History:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Cancel) end)
			if not cancelled then warn("[CombatForge] Example rollback failed: " .. tostring(problem)) end
		end
		return false, tostring(failure)
	end
	return true, "Example ready! Play, equip CombatForge Example Slash, then click near a dummy. Edit ExampleSlash in Update Skills. Save your place."
end

return ExampleInstaller
