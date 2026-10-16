-- Contract: spec(Config, loadManager); loadManager(services) loads AbilityManager
-- with these isolated services
-- and its real AbilityConfig dependency. All Instances stay outside the live place.
return function(_Config, loadManager)
	local count = 0
	local function check(value, message) assert(value, message); count += 1 end
	local storage = Instance.new("Folder")
	local root = Instance.new("Folder"); root.Name = "CombatForge"; root.Parent = storage
	local folder = Instance.new("Folder"); folder.Name = "Abilities"; folder.Parent = root
	local target = Instance.new("ModuleScript")
	target.Name = "Slash"; target.Source = "error('must never execute')"; target.Archivable = false; target.Parent = folder
	target:SetAttribute("Custom", "preserve")
	local child = Instance.new("ModuleScript")
	child.Name = "Child"; child.Source = "return 'child source'"; child.Archivable = false; child.Parent = target
	local sibling = Instance.new("ModuleScript"); sibling.Name = "Other"; sibling.Parent = folder
	local running, allowRecording, failBegin, failCommit, failCancel = false, true, false, false, false
	local begins, commits, cancels = 0, 0, 0
	local activeParent, undoParent, beginHook
	local services = {
		ReplicatedStorage = storage,
		ScriptEditorService = {}, -- Deletion must neither read nor execute source.
		RunService = { IsRunning = function() return running end },
		ChangeHistoryService = {
			TryBeginRecording = function(_, name, displayName)
				begins += 1
				assert(name == "CombatForge.DeleteAbility" and displayName == "Delete skill Slash", "Named deletion recording")
				if failBegin then error("Injected begin failure") end
				if not allowRecording then return nil end
				activeParent = target.Parent
				if beginHook then beginHook() end
				return "delete-recording"
			end,
			FinishRecording = function(_, identifier, operation)
				assert(identifier == "delete-recording", "Use this transaction's identifier")
				if operation == Enum.FinishRecordingOperation.Commit then
					if failCommit then error("Injected commit failure") end
					check(target.Parent == nil and sibling.Parent == folder, "Only exact target detached before commit")
					commits += 1
					undoParent = activeParent
				else
					assert(operation == Enum.FinishRecordingOperation.Cancel, "No unrelated history operations")
					cancels += 1
					if failCancel then error("Injected cancellation failure") end
					-- Only model the parent change being recorded, never clone/recreate.
					if target.Parent == nil then target.Parent = activeParent end
				end
			end,
		},
	}
	local manager = loadManager(services)
	local function intact()
		return target.Parent == folder and target.Name == "Slash"
			and target.Source == "error('must never execute')" and not target.Archivable
			and target:GetAttribute("Custom") == "preserve" and child.Parent == target
			and child.Source == "return 'child source'" and not child.Archivable
			and sibling.Parent == folder and #folder:GetChildren() == 2
	end
	local function rejectBeforeRecording(module, name, message)
		local oldBegins = begins
		check(not manager.delete(module, name), message)
		check(begins == oldBegins, "Rejected target starts no recording: " .. message)
	end
	local ok, failure = pcall(function()
		running = true; rejectBeforeRecording(target, "Slash", "Reject Play"); running = false
		rejectBeforeRecording(target, "slash", "Confirmation name must match exactly")
		rejectBeforeRecording(child, "Child", "Reject nested module")
		rejectBeforeRecording(folder, "Abilities", "Reject wrong instance class")
		rejectBeforeRecording(nil, "Slash", "Reject missing instance")
		rejectBeforeRecording({}, "Slash", "Reject non-instance")
		target.Name = "Renamed"; rejectBeforeRecording(target, "Slash", "Reject renamed target"); target.Name = "Slash"
		target.Parent = storage; rejectBeforeRecording(target, "Slash", "Reject outside target"); target.Parent = folder
		target.Parent = nil; rejectBeforeRecording(target, "Slash", "Reject missing target"); target.Parent = folder
		local collision = Instance.new("Folder"); collision.Name = "CombatForge"; collision.Parent = storage
		rejectBeforeRecording(target, "Slash", "Reject duplicate root"); collision:Destroy()
		collision = Instance.new("StringValue"); collision.Name = "CombatForge"; collision.Parent = storage
		rejectBeforeRecording(target, "Slash", "Reject root class collision"); collision:Destroy()
		collision = Instance.new("Folder"); collision.Name = "Abilities"; collision.Parent = root
		rejectBeforeRecording(target, "Slash", "Reject duplicate Abilities"); collision:Destroy()
		collision = Instance.new("StringValue"); collision.Name = "Abilities"; collision.Parent = root
		rejectBeforeRecording(target, "Slash", "Reject Abilities class collision"); collision:Destroy()
		folder.Parent = nil; rejectBeforeRecording(target, "Slash", "Reject absent Abilities"); folder.Parent = root
		root.Parent = nil; rejectBeforeRecording(target, "Slash", "Reject absent root"); root.Parent = storage
		check(intact(), "All validation refusals preserve subtree and siblings")
		allowRecording = false
		check(not manager.delete(target, "Slash") and intact() and cancels == 0, "Unavailable recording preserves original")
		allowRecording = true; failBegin = true
		check(not manager.delete(target, "Slash") and intact() and cancels == 0, "Thrown begin preserves original")
		failBegin = false
		beginHook = function() target.Name = "ExternalRename" end
		check(not manager.delete(target, "Slash"), "Revalidate target after beginning recording")
		check(target.Parent == folder and target.Name == "ExternalRename" and cancels == 1, "Do not delete renamed target")
		target.Name = "Slash"
		beginHook = function() running = true end
		check(not manager.delete(target, "Slash") and intact() and cancels == 2, "Recheck Edit mode after recording starts")
		running = false; beginHook = nil
		failCommit = true
		check(not manager.delete(target, "Slash"), "Commit failure returned")
		check(intact() and cancels == 3 and commits == 0, "Cancel restores same non-Archivable instance and descendants")
		failCancel = true
		check(not manager.delete(target, "Slash"), "Commit plus cancellation failure returned")
		check(intact() and cancels == 4 and commits == 0, "Fallback reparents original when cancellation throws")
		failCommit = false; failCancel = false
		sibling.Name = "Slash" -- Duplicate module names must not redirect identity-based deletion.
		local oldBegins = begins
		check(manager.delete(target, "Slash"), "Delete custom skill without parsing source")
		check(begins == oldBegins + 1 and commits == 1 and cancels == 4, "One successful recording and commit")
		check(target.Parent == nil and #folder:GetChildren() == 1 and sibling.Parent == folder, "Exact target removed; folder and sibling retained")
		-- Simulate history's recorded parent transition. Real Ctrl+Z/redo requires Studio.
		target.Parent = undoParent
		check(intact(), "Undo parent transition restores original identity, source, properties and child")
		target.Parent = nil
		check(#manager.list() == 1 and child.Parent == target, "Redo parent transition removes complete subtree again")
		rejectBeforeRecording(target, "Slash", "Repeated delete of detached target rejected")
		target.Parent = undoParent
		check(intact(), "Original remains writable; Destroy was never used")
	end)
	storage:Destroy()
	if target.Parent == nil then target:Destroy() end
	assert(ok, failure)
	return tostring(count) .. " deletion assertions passed (isolated services; native Studio undo/redo still needs validation)."
end
