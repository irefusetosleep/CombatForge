--!strict
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local AbilityConfig = require(script.Parent.AbilityConfig)

local AbilityManager = {}

-- Reject ambiguous paths and non-folder collisions instead of changing existing content.
local function findFolder(parent: Instance, name: string): (Folder?, string?)
	local found: Folder? = nil
	for _, child in parent:GetChildren() do
		if child.Name == name then
			if found or not child:IsA("Folder") then
				return nil, parent:GetFullName() .. "." .. name .. " must be a single Folder. Rename the conflicting objects first."
			end
			found = child
		end
	end
	return found, nil
end

function AbilityManager.create(inputs: AbilityConfig.Inputs): (boolean, string)
	if RunService:IsRunning() then
		return false, "Stop the playtest before creating an ability so it can be saved in your place."
	end
	local config, validationError = AbilityConfig.validate(inputs)
	if not config then
		return false, validationError or "Invalid ability settings."
	end

	local root, rootError = findFolder(ReplicatedStorage, "CombatForge")
	if rootError then
		return false, rootError
	end
	local abilities: Folder? = nil
	if root then
		local folderError
		abilities, folderError = findFolder(root, "Abilities")
		if folderError then
			return false, folderError
		end
	end
	if abilities then
		for _, child in abilities:GetChildren() do
			if string.lower(child.Name) == string.lower(config.Name) then
				return false, "An object named " .. child.Name .. " already exists in Abilities. Choose a different name."
			end
		end
	end

	local recording: string? = nil
	local created: { Instance } = {}
	local success, failure = pcall(function()
		recording = ChangeHistoryService:TryBeginRecording("CombatForge.CreateAbility", "Create ability " .. config.Name)
		if not recording then
			error("Studio could not start an undo recording. Finish the current operation and try again.", 0)
		end

		-- This transaction does not yield. Build new instances before parenting them.
		local module = Instance.new("ModuleScript")
		table.insert(created, module)
		module.Name = config.Name
		-- Direct source assignment is safe here: this is a new, unopened ModuleScript.
		module.Source = AbilityConfig.serialize(config)
		if not root then
			root = Instance.new("Folder")
			table.insert(created, root)
			root.Name = "CombatForge"
			root.Parent = ReplicatedStorage
		end
		if not abilities then
			abilities = Instance.new("Folder")
			table.insert(created, abilities)
			abilities.Name = "Abilities"
			abilities.Parent = root
		end
		module.Parent = abilities
		ChangeHistoryService:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Commit)
		recording = nil
	end)

	if not success then
		-- Remove only instances created by this attempt, including unparented ones.
		for _, instance in created do
			instance:Destroy()
		end
		if recording then
			local cancelled, cancelError = pcall(function()
				ChangeHistoryService:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Cancel)
			end)
			if not cancelled then
				warn("[CombatForge] Could not cancel undo recording: " .. tostring(cancelError))
			end
		end
		warn("[CombatForge] Create failed: " .. tostring(failure))
		return false, "Could not create the ability. " .. tostring(failure)
	end

	return true, "Created " .. config.Name .. " in ReplicatedStorage.CombatForge.Abilities. Save your place to keep it."
end

export type Snapshot = { module: ModuleScript, name: string, source: string, config: AbilityConfig.Config }

local function getAbilities(): (Folder?, string?)
	local root, rootError = findFolder(ReplicatedStorage, "CombatForge")
	if rootError or not root then return nil, rootError end
	return findFolder(root, "Abilities")
end

function AbilityManager.list(): ({ ModuleScript }, string?)
	local folder, folderError = getAbilities()
	local result: { ModuleScript } = {}
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("ModuleScript") then table.insert(result, child) end
		end
	end
	table.sort(result, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)
	return result, folderError
end

function AbilityManager.delete(module: ModuleScript, expectedName: string): (boolean, string)
	local function checkTarget(): (Folder?, string?)
		if RunService:IsRunning() then return nil, "Stop the playtest before deleting a skill." end
		if typeof(module) ~= "Instance" or not module:IsA("ModuleScript") then
			return nil, "Select a ModuleScript skill to delete."
		end
		local folder, folderError = getAbilities()
		if not folder or module.Parent ~= folder or module.Name ~= expectedName then
			return nil, folderError or "This skill was moved, deleted or renamed. Refresh the list and confirm again."
		end
		return folder, nil
	end
	local originalParent, targetError = checkTarget()
	if not originalParent then return false, targetError or "Could not find this skill." end
	local recording: string? = nil
	local detached = false
	local success, failure = pcall(function()
		recording = ChangeHistoryService:TryBeginRecording("CombatForge.DeleteAbility", "Delete skill " .. expectedName)
		if not recording then error("Studio could not start an undo recording. Try again.", 0) end
		local latestParent, latestError = checkTarget()
		if latestParent ~= originalParent then error(latestError or "The skill folder changed. Confirm again.", 0) end
		-- Unparent, never Destroy: history retains the exact instance and its complete
		-- subtree, including non-Archivable children. A failed commit can reparent it.
		-- No yielding or source evaluation is needed in this transaction.
		module.Parent = nil
		detached = true
		ChangeHistoryService:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Commit)
		recording = nil
	end)
	if not success then
		if recording then
			local cancelled, cancelError = pcall(function()
				ChangeHistoryService:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Cancel)
			end)
			if not cancelled then warn("[CombatForge] Could not cancel deletion: " .. tostring(cancelError)) end
		end
		-- If cancellation itself fails (or fails to restore), the instance is still
		-- writable. Restore only our detached target; never overwrite another edit.
		if detached and module.Parent == nil then
			local restored, restoreError = pcall(function() module.Parent = originalParent end)
			if not restored then
				return false, "Could not delete or restore the skill. " .. tostring(failure) .. " Restore failed: " .. tostring(restoreError)
			end
		end
		return false, "Could not delete the skill. " .. tostring(failure)
	end
	return true, "Deleted " .. expectedName .. ". Undo is available. Save your place to keep this change."
end

function AbilityManager.read(module: ModuleScript): (Snapshot?, string?)
	local folder, folderError = getAbilities()
	if not folder or module.Parent ~= folder then return nil, folderError or "This skill was moved or deleted. Refresh the list." end
	local ok, source = pcall(function() return ScriptEditorService:GetEditorSource(module) end)
	if not ok then return nil, "Could not read this skill: " .. tostring(source) end
	local config, parseError = AbilityConfig.parse(source)
	if not config then return nil, parseError end
	-- Explorer's instance name is authoritative if the user renamed it manually.
	config.Name = module.Name
	return { module = module, name = module.Name, source = source, config = config }, nil
end

function AbilityManager.update(snapshot: Snapshot, inputs: AbilityConfig.Inputs): (boolean, string)
	if RunService:IsRunning() then return false, "Stop the playtest before updating a skill." end
	local config, validationError = AbilityConfig.validate(inputs)
	if not config then return false, validationError or "Invalid settings." end
	-- Parse the checked source again rather than trusting mutable UI snapshot data.
	-- Only common controls change; optional advanced fields retain their presence/value.
	local previous, parseError = AbilityConfig.parse(snapshot.source)
	if not previous then return false, parseError or "Unsupported skill source." end
	for key, value in previous do
		if key ~= "Name" and key ~= "Damage" and key ~= "Cooldown" and key ~= "Range" then
			(config :: any)[key] = value
		end
	end
	local module = snapshot.module
	local function checkTarget(): string?
		local folder, folderError = getAbilities()
		if not folder or module.Parent ~= folder or module.Name ~= snapshot.name then
			return folderError or "This skill was moved, deleted or renamed. Go back and reopen it."
		end
		for _, child in folder:GetChildren() do
			if child ~= module and string.lower(child.Name) == string.lower(config.Name) then
				return "Another object already uses that skill name. Choose a different name."
			end
		end
		return nil
	end
	local targetError = checkTarget()
	if targetError then return false, targetError end
	local recording: string? = nil
	local success, failure = pcall(function()
		if ScriptEditorService:GetEditorSource(module) ~= snapshot.source then
			error("This skill changed since you opened it. Go back and reopen it before saving.", 0)
		end
		recording = ChangeHistoryService:TryBeginRecording("CombatForge.UpdateAbility", "Update skill " .. snapshot.name)
		if not recording then error("Studio could not start an undo recording. Try again.", 0) end
		local conflict: string? = nil
		ScriptEditorService:UpdateSourceAsync(module, function(currentSource: string)
			conflict = checkTarget()
			if currentSource ~= snapshot.source then conflict = "This skill changed while saving. Go back and reopen it." end
			if RunService:IsRunning() then conflict = "Stop the playtest before saving." end
			if conflict then return nil end
			return AbilityConfig.serialize(config)
		end)
		if conflict then error(conflict, 0) end
		local latestError = checkTarget()
		if latestError then error(latestError, 0) end
		module.Name = config.Name
		ChangeHistoryService:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Commit)
		recording = nil
	end)
	if not success then
		if recording then
			local cancelled, cancelError = pcall(function()
				ChangeHistoryService:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Cancel)
			end)
			if not cancelled then warn("[CombatForge] Could not cancel update: " .. tostring(cancelError)) end
		end
		return false, "Could not save. " .. tostring(failure)
	end
	return true, "Saved " .. config.Name .. ". Save your place to keep these changes."
end

-- Narrow visual-editor save: only the six box geometry values may change.
function AbilityManager.saveGeometry(snapshot: Snapshot, geometry): (boolean, string)
	if RunService:IsRunning() then return false, "Stop the playtest before saving hitbox geometry." end
	local config, parseError = AbilityConfig.parse(snapshot.source)
	if not config or not AbilityConfig.isMelee(config) then return false, parseError or "Reopen a supported melee config." end
	local keys = { "HitboxWidth", "HitboxHeight", "Range", "HitboxOffsetX", "HitboxOffsetY", "HitboxOffsetZ" }
	local allowed = {}
	for _, key in keys do allowed[key] = true end
	if type(geometry) ~= "table" then return false, "Invalid hitbox geometry." end
	for key in geometry do if not allowed[key] then return false, "Only hitbox geometry may be saved here." end end
	for _, key in keys do
		if type(geometry[key]) ~= "number" then return false, "Missing numeric geometry: " .. key end
		(config :: any)[key] = geometry[key]
	end
	local valid, validationError = AbilityConfig.validateConfig(config)
	if not valid then return false, validationError or "Invalid hitbox geometry." end
	local source = AbilityConfig.serialize(valid)
	local module = snapshot.module
	local function checkTarget(): string?
		if RunService:IsRunning() then return "Stop the playtest before saving hitbox geometry." end
		local folder, folderError = getAbilities()
		if not folder or module.Parent ~= folder or module.Name ~= snapshot.name then
			return folderError or "This skill was moved, deleted or renamed. Reopen it before saving."
		end
		return nil
	end
	local targetError = checkTarget()
	if targetError then return false, targetError end
	local recording: string? = nil
	local wrote = false
	local success, failure = pcall(function()
		if ScriptEditorService:GetEditorSource(module) ~= snapshot.source then error("This skill changed. Reopen it before saving.", 0) end
		recording = ChangeHistoryService:TryBeginRecording("CombatForge.SaveHitbox", "Edit hitbox " .. snapshot.name)
		if not recording then error("Studio could not start an undo recording. Try again.", 0) end
		local conflict: string? = nil
		ScriptEditorService:UpdateSourceAsync(module, function(currentSource: string)
			conflict = checkTarget()
			if currentSource ~= snapshot.source then conflict = "This skill changed while saving. Reopen it." end
			if conflict then return nil end
			wrote = true
			return source
		end)
		if conflict then error(conflict, 0) end
		wrote = true
		local latestError = checkTarget()
		if latestError then error(latestError, 0) end
		ChangeHistoryService:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Commit)
		recording = nil
	end)
	if not success then
		if recording then
			local cancelled, cancelError = pcall(function() ChangeHistoryService:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Cancel) end)
			if not cancelled then warn("[CombatForge] Could not cancel hitbox save: " .. tostring(cancelError)) end
		end
		-- Cancellation normally restores source. If not, restore only our exact write;
		-- never replace content changed by a concurrent editor.
		if wrote then
			local restored, restoreError = pcall(function()
				ScriptEditorService:UpdateSourceAsync(module, function(currentSource: string)
					if currentSource == source then return snapshot.source end
					return nil
				end)
			end)
			if not restored then return false, "Could not save or restore hitbox source. Reopen the skill. " .. tostring(restoreError) end
		end
		return false, "Could not save hitbox. " .. tostring(failure)
	end
	return true, "Saved hitbox for " .. snapshot.name .. ". Undo is available; changes apply next Play."
end

return AbilityManager
