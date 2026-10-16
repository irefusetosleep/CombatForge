--!strict
-- Plugin-only draft editor. No place code is evaluated and no workspace object is created.
local AbilityConfig = require(script.Parent.AbilityConfig)
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HitboxEditor = {}
local activeSession = nil
local geometryKeys = { "HitboxWidth", "HitboxHeight", "Range", "HitboxOffsetX", "HitboxOffsetY", "HitboxOffsetZ" }
local function finite(value): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function copy(draft)
	local result = {}
	for _, key in geometryKeys do result[key] = draft[key] end
	return result
end
local function validGeometry(draft): boolean
	if type(draft) ~= "table" then return false end
	for _, key in geometryKeys do if not finite(draft[key]) then return false end end
	return draft.HitboxWidth > 0 and draft.HitboxHeight > 0 and draft.Range > 0
end
function HitboxEditor.isSupported(config): boolean
	return AbilityConfig.isMelee(config)
end
function HitboxEditor.newDraft(config)
	if not HitboxEditor.isSupported(config) then return nil, "Edit Hitbox supports complete melee box configs only; projectile/custom configs are not supported." end
	return {
		HitboxWidth = config.HitboxWidth, HitboxHeight = config.HitboxHeight, Range = config.Range,
		HitboxOffsetX = config.HitboxOffsetX or 0, HitboxOffsetY = config.HitboxOffsetY or 0, HitboxOffsetZ = config.HitboxOffsetZ or 0,
	}, nil
end
function HitboxEditor.transform(rootCFrame: CFrame, draft): (CFrame, Vector3)
	assert(validGeometry(draft), "Invalid hitbox geometry")
	return rootCFrame * CFrame.new(draft.HitboxOffsetX, draft.HitboxOffsetY, -draft.Range / 2 + draft.HitboxOffsetZ),
		Vector3.new(draft.HitboxWidth, draft.HitboxHeight, draft.Range)
end
function HitboxEditor.drag(baseline, mode: string, face: Enum.NormalId, distance: number)
	if not validGeometry(baseline) or not finite(distance) then return nil, "Drag geometry must be finite and positive." end
	local axis, sign
	if face == Enum.NormalId.Right then axis = "X"; sign = 1
	elseif face == Enum.NormalId.Left then axis = "X"; sign = -1
	elseif face == Enum.NormalId.Top then axis = "Y"; sign = 1
	elseif face == Enum.NormalId.Bottom then axis = "Y"; sign = -1
	elseif face == Enum.NormalId.Back then axis = "Z"; sign = 1
	elseif face == Enum.NormalId.Front then axis = "Z"; sign = -1
	else return nil, "Unknown hitbox face." end
	local draft = copy(baseline)
	if mode == "Move" then
		local key = "HitboxOffset" .. axis
		draft[key] += sign * distance
	elseif mode == "Resize" then
		local key = if axis == "X" then "HitboxWidth" elseif axis == "Y" then "HitboxHeight" else "Range"
		draft[key] = math.max(0.05, baseline[key] + 2 * distance)
		-- Resize symmetrically around the mouse-down center, including depth changes.
		if axis == "Z" then draft.HitboxOffsetZ = baseline.HitboxOffsetZ + (draft.Range - baseline.Range) / 2 end
	else return nil, "Choose Move or Resize." end
	if not validGeometry(draft) then return nil, "Dragged geometry is not finite." end
	return draft, nil
end
function HitboxEditor.selectRoot(selection)
	local selectedModel: Model? = nil
	for _, item in selection do
		local candidate: Instance? = item
		while candidate and candidate ~= workspace do
			if candidate:IsA("Model") and candidate:FindFirstChildOfClass("Humanoid") then break end
			candidate = candidate.Parent
		end
		if not candidate or candidate == workspace or not candidate:IsA("Model") or not candidate:IsDescendantOf(workspace) then
			return nil, "Select one existing dummy Model or its descendant in Workspace."
		end
		if selectedModel and selectedModel ~= candidate then return nil, "Select only one dummy Model." end
		selectedModel = candidate
	end
	if not selectedModel then return nil, "Select a dummy Model or one of its parts, then Start Preview." end
	local root = selectedModel:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return nil, "The selected dummy needs a BasePart HumanoidRootPart." end
	return root, nil
end
function HitboxEditor.start(plugin, config, onChanged, onStopped)
	if activeSession then activeSession.destroy() end
	if RunService:IsRunning() then return nil, "Stop the playtest before previewing a hitbox." end
	local draft, problem = HitboxEditor.newDraft(config)
	if not draft then return nil, problem end
	local reference, selectionError = HitboxEditor.selectRoot(Selection:Get())
	if not reference then return nil, selectionError end
	local model = reference.Parent
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local objects = {}
	local connections = {}
	local ended = false
	local mode = "Move"
	local baseline = nil
	local session = {}
	local gui, proxy, box, handles
	local function own(item)
		table.insert(objects, item)
		item.Archivable = false
		return item
	end
	local function listen(signal, callback) table.insert(connections, signal:Connect(callback)) end
	function session.destroy(message)
		if ended then return end
		ended = true
		for _, connection in connections do connection:Disconnect() end
		table.clear(connections)
		for index = #objects, 1, -1 do objects[index]:Destroy() end
		table.clear(objects)
		if activeSession == session then activeSession = nil end
		pcall(function() plugin:Deactivate() end)
		if message and onStopped then onStopped(message) end
	end
	function session.getDraft() return copy(draft) end
	function session.setMode(value)
		if ended then return false end
		if value ~= "Move" and value ~= "Resize" then return false end
		mode = value; baseline = nil
		handles.Style = if mode == "Move" then Enum.HandlesStyle.Movement else Enum.HandlesStyle.Resize
		return true
	end
	local function refresh()
		local center, size = HitboxEditor.transform(reference.CFrame, draft)
		for _, component in { center:GetComponents() } do assert(finite(component), "Preview transform cannot be rendered.") end
		proxy.Size = size
		assert(proxy.Size == size, "This hitbox size is outside Studio preview limits; edit its config source instead.")
		proxy.CFrame = center
		box.Size = size
		box.CFrame = CFrame.new(draft.HitboxOffsetX, draft.HitboxOffsetY, -draft.Range / 2 + draft.HitboxOffsetZ)
	end
	local ok, failure = pcall(function()
		gui = own(Instance.new("ScreenGui")); gui.Name = "CombatForgeHitboxPreview"; gui.Parent = CoreGui
		proxy = own(Instance.new("Part")); proxy.Name = "CombatForgeHitboxHandleProxy"
		proxy.Anchored = true; proxy.CanCollide = false; proxy.CanTouch = false; proxy.CanQuery = false; proxy.Transparency = 1
		-- The handle proxy deliberately remains unparented; it is never serialized with the place.
		box = own(Instance.new("BoxHandleAdornment")); box.Name = "HitboxPreview"
		box.Adornee = reference; box.Color3 = Color3.fromRGB(80, 210, 255); box.Transparency = 0.65
		box.AlwaysOnTop = true; box.ZIndex = 1; box.Parent = gui
		handles = own(Instance.new("Handles")); handles.Name = "HitboxHandles"
		handles.Adornee = proxy; handles.Color3 = Color3.fromRGB(255, 190, 70)
		handles.Faces = Faces.new(Enum.NormalId.Right, Enum.NormalId.Left, Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Back)
		handles.Style = Enum.HandlesStyle.Movement; handles.Parent = gui
		refresh()
		listen(handles.MouseButton1Down, function() baseline = copy(draft) end)
		listen(handles.MouseButton1Up, function() baseline = nil end)
		listen(handles.MouseDrag, function(face, distance)
			if ended or not baseline then return end
			local changed, dragError = HitboxEditor.drag(baseline, mode, face, distance)
			if not changed then session.destroy(dragError); return end
			draft = changed
			local rendered, renderError = pcall(refresh)
			if not rendered then session.destroy(tostring(renderError)); return end
			if onChanged then onChanged(copy(draft)) end
		end)
		listen(RunService.RenderStepped, function()
			if RunService:IsRunning() then session.destroy("Preview ended for Play. Reopen Edit Hitbox in Edit mode."); return end
			if not reference:IsDescendantOf(workspace) or reference.Parent ~= model or humanoid.Parent ~= model then
				session.destroy("The reference dummy or root was removed. Select a dummy and start again."); return
			end
			local rendered, renderError = pcall(refresh)
			if not rendered then session.destroy(tostring(renderError)) end
		end)
		listen(plugin.Deactivation, function() session.destroy("Preview ended because the active Studio tool changed.") end)
		listen(plugin.Unloading, function() session.destroy() end)
		plugin:Activate(true)
	end)
	if not ok then session.destroy(); return nil, "Could not start preview: " .. tostring(failure) end
	activeSession = session
	if onChanged then onChanged(copy(draft)) end
	return session, "Drag the handles. Size and root-local offsets are measured in studs."
end
return HitboxEditor
