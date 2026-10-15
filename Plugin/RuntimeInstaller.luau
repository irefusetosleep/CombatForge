--!strict
local History = game:GetService("ChangeHistoryService")
local Storage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Editor = game:GetService("ScriptEditorService")
local RuntimeInstaller = {}

local function folder(parent: Instance, name: string): Folder?
	local result: Folder? = nil
	for _, child in parent:GetChildren() do
		if child.Name == name then
			assert(not result and child:IsA("Folder"), parent:GetFullName() .. "." .. name .. " must be a single Folder")
			result = child :: Folder
		end
	end
	return result
end

function RuntimeInstaller.install(template: ModuleScript): (boolean, string)
	if RunService:IsRunning() then return false, "Stop the playtest before installing the runtime." end
	local recording: string? = nil
	local created: { Instance } = {}
	local changed = false
	local ok, failure = pcall(function()
		local root = folder(Storage, "CombatForge")
		local runtime = if root then folder(root, "Runtime") else nil
		if runtime then
			local matches: { Instance } = {}
			for _, child in runtime:GetChildren() do
				if child.Name == "Hitbox" then table.insert(matches, child) end
			end
			if #matches > 0 then
				assert(#matches == 1 and matches[1]:IsA("ModuleScript"), "Hitbox path is occupied by conflicting objects.")
				assert(Editor:GetEditorSource(matches[1] :: ModuleScript) == template.Source, "An existing Hitbox module differs from this version. Back it up and rename it before installing; it has not been overwritten.")
				return
			end
		end
		recording = History:TryBeginRecording("CombatForge.InstallHitbox", "Install CombatForge Hitbox")
		assert(recording, "Could not begin undo recording. Try again.")
		local function makeFolder(parent: Instance, name: string): Folder
			local item = Instance.new("Folder")
			table.insert(created, item)
			item.Name = name; item.Parent = parent
			return item
		end
		root = root or makeFolder(Storage, "CombatForge")
		runtime = runtime or makeFolder(root, "Runtime")
		local module = template:Clone()
		table.insert(created, module)
		module.Name = "Hitbox"
		module.Parent = runtime
		History:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Commit)
		recording = nil
		changed = true
	end)
	if not ok then
		for _, instance in created do instance:Destroy() end
		if recording then
			local cancelled, problem = pcall(function() History:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Cancel) end)
			if not cancelled then warn("[CombatForge] Install rollback failed: " .. tostring(problem)) end
		end
		return false, tostring(failure)
	end
	return true, (if changed then "Installed" else "Already installed") .. " at ReplicatedStorage.CombatForge.Runtime.Hitbox. Save your place to keep it."
end

return RuntimeInstaller
