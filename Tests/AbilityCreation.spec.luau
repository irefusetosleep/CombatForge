-- Run with the development harness: supplies the modules with isolated services.
-- These tests do not install a plugin or modify the open place.
return function(Config, loadManager)
	local assertions = 0
	local function check(value, message)
		assert(value, message)
		assertions += 1
	end
	local function inputs(overrides)
		local result = { Name = "LightAttack", Damage = "20", Cooldown = "0.5", Range = "5" }
		for key, value in overrides or {} do
			result[key] = value
		end
		return result
	end
	local config = Config.validate(inputs({ Name = "  HeavySlash  " }))
	check(config and config.Name == "HeavySlash", "Trim ability name")
	check(config.Damage == 20 and config.Cooldown == 0.5 and config.Range == 5, "Parse values")
	for _, name in { "", "   ", "1Attack", "Heavy Slash", "a\"b", string.rep("a", 65) } do
		check(Config.validate(inputs({ Name = name })) == nil, "Reject invalid name: " .. name)
	end
	for _, field in { "Damage", "Cooldown", "Range" } do
		for _, value in { "", "abc", "-1", "1e999", "nan" } do
			check(Config.validate(inputs({ [field] = value })) == nil, "Reject " .. field .. "=" .. value)
		end
	end
	check(Config.validate(inputs({ Range = "0" })) == nil, "Reject zero range")
	check(Config.validate(inputs({ Damage = "0", Cooldown = "0" })) ~= nil, "Allow zero damage/cooldown")
	local generated = assert(loadstring(Config.serialize(config)))()
	check(generated.Name == config.Name and generated.Cooldown == config.Cooldown, "Generated source round trip")

	local storage = Instance.new("Folder")
	storage.Name = "IsolatedStorage"
	local running = false
	local allowRecording = true
	local failCommit = false
	local begins, commits, cancels = 0, 0, 0
	local services = {
		ScriptEditorService = {},
		ReplicatedStorage = storage,
		RunService = { IsRunning = function() return running end },
		ChangeHistoryService = {
			TryBeginRecording = function()
				begins += 1
				return if allowRecording then "test-recording" else nil
			end,
			FinishRecording = function(_, _, operation)
				if operation == Enum.FinishRecordingOperation.Commit then
					if failCommit then error("Injected commit failure") end
					commits += 1
				else
					cancels += 1
				end
			end,
		},
	}
	local manager = loadManager(services)
	local ok, failure = pcall(function()
		check(not manager.create(inputs({ Damage = "oops" })), "Invalid input fails")
		check(#storage:GetChildren() == 0 and begins == 0, "Validation makes no changes")
		running = true
		check(not manager.create(inputs()), "Reject play mode")
		running = false
		allowRecording = false
		check(not manager.create(inputs()), "Reject unavailable recording")
		check(#storage:GetChildren() == 0, "No folders on unavailable recording")
		allowRecording = true
		check(manager.create(inputs()), "Create ability")
		local abilities = storage.CombatForge.Abilities
		local module = abilities.LightAttack
		check(module:IsA("ModuleScript"), "Correct instance type and path")
		local data = assert(loadstring(module.Source))()
		check(data.Name == "LightAttack" and data.Damage == 20 and data.Range == 5, "Correct saved data")
		check(commits == 1, "Single undo commit")
		check(not manager.create(inputs({ Name = "lightattack" })), "Reject case-insensitive duplicate")
		check(#abilities:GetChildren() == 1 and commits == 1, "Duplicate does not mutate")
		local collision = Instance.new("StringValue")
		collision.Name = "HeavySlash"
		collision.Parent = abilities
		check(not manager.create(inputs({ Name = "HeavySlash" })), "Protect non-module collision")
		failCommit = true
		check(not manager.create(inputs({ Name = "FailedAttack" })), "Handle commit failure")
		check(not abilities:FindFirstChild("FailedAttack") and abilities.LightAttack == module, "Rollback preserves existing abilities")
		check(cancels == 1, "Failed transaction cancelled")
		storage:ClearAllChildren()
		check(not manager.create(inputs()), "Handle failure on first creation")
		check(#storage:GetChildren() == 0, "Rollback new folders")
		failCommit = false
		local wrongRoot = Instance.new("StringValue")
		wrongRoot.Name = "CombatForge"
		wrongRoot.Parent = storage
		check(not manager.create(inputs()) and wrongRoot.Parent == storage, "Protect conflicting root")
		wrongRoot:Destroy()
		local root = Instance.new("Folder")
		root.Name = "CombatForge"
		root.Parent = storage
		local wrongAbilities = Instance.new("StringValue")
		wrongAbilities.Name = "Abilities"
		wrongAbilities.Parent = root
		check(not manager.create(inputs()), "Protect conflicting Abilities")
		wrongAbilities:Destroy()
		local duplicateRoot = root:Clone()
		duplicateRoot.Parent = storage
		check(not manager.create(inputs()), "Reject ambiguous root")
	end)
	storage:Destroy()
	assert(ok, failure)
	return tostring(assertions) .. " assertions passed (isolated services; live Studio undo/redo still needs manual testing)."
end
