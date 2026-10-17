--!strict
-- Plugin-only draft editor. No place code is evaluated and no workspace object is created.
local AbilityConfig = require(script.Parent.AbilityConfig)
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HitboxEditor = {}
local activeSession = nil
local geometryKeys = { "HitboxWidth", "HitboxHeight", "Range", "HitboxOffsetX", "HitboxOffsetY", "HitboxOffsetZ", "HitboxRotationX", "HitboxRotationY", "HitboxRotationZ" }
local function finite(value): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function copy(draft)
	local result = {}
	for _, key in geometryKeys do result[key] = draft[key] or 0 end
	return result
end
local function validGeometry(draft): boolean
	if type(draft) ~= "table" then return false end
	for _, key in geometryKeys do if not finite(draft[key]) and not (key:match("^HitboxRotation") and draft[key] == nil) then return false end end
	local count = 0
	for _, key in { "HitboxRotationX", "HitboxRotationY", "HitboxRotationZ" } do if draft[key] ~= nil then count += 1 end end
	return (count == 0 or count == 3) and draft.HitboxWidth > 0 and draft.HitboxHeight > 0 and draft.Range > 0
end
local function rotation(draft)
	return CFrame.fromOrientation(math.rad((draft.HitboxRotationX or 0) % 360), math.rad((draft.HitboxRotationY or 0) % 360), math.rad((draft.HitboxRotationZ or 0) % 360))
end
local function center(draft)
	return Vector3.new(draft.HitboxOffsetX, draft.HitboxOffsetY, -draft.Range / 2 + draft.HitboxOffsetZ)
end
local function setCenter(draft, value)
	draft.HitboxOffsetX = value.X; draft.HitboxOffsetY = value.Y; draft.HitboxOffsetZ = value.Z + draft.Range / 2
end
function HitboxEditor.isSupported(config): boolean
	return AbilityConfig.isMelee(config)
end
function HitboxEditor.newDraft(config)
	if not HitboxEditor.isSupported(config) then return nil, "Edit Hitbox supports complete melee box configs only; projectile/custom configs are not supported." end
	return {
		HitboxWidth = config.HitboxWidth, HitboxHeight = config.HitboxHeight, Range = config.Range,
		HitboxOffsetX = config.HitboxOffsetX or 0, HitboxOffsetY = config.HitboxOffsetY or 0, HitboxOffsetZ = config.HitboxOffsetZ or 0,
		HitboxRotationX = (((config.HitboxRotationX or 0) % 360) + 180) % 360 - 180, HitboxRotationY = (((config.HitboxRotationY or 0) % 360) + 180) % 360 - 180, HitboxRotationZ = (((config.HitboxRotationZ or 0) % 360) + 180) % 360 - 180,
	}, nil
end
function HitboxEditor.transform(rootCFrame: CFrame, draft): (CFrame, Vector3)
	assert(validGeometry(draft), "Invalid hitbox geometry")
	return rootCFrame * CFrame.new(center(draft)) * rotation(draft),
		Vector3.new(draft.HitboxWidth, draft.HitboxHeight, draft.Range)
end
function HitboxEditor.drag(baseline, mode: string, face: Enum.NormalId, distance: number, scaleMode: string?)
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
	if distance == 0 and (mode == "Move" or mode == "Resize") then return draft, nil end
	local normal = if axis == "X" then Vector3.new(sign, 0, 0) elseif axis == "Y" then Vector3.new(0, sign, 0) else Vector3.new(0, 0, sign)
	local displacement
	if mode == "Move" then
		displacement = distance
	elseif mode == "Resize" then
		local key = if axis == "X" then "HitboxWidth" elseif axis == "Y" then "HitboxHeight" else "Range"
		if scaleMode == "Uniform" then
			local ratio = (baseline[key] + distance) / baseline[key]
			local minimumRatio = math.max(math.min(0.05, baseline.HitboxWidth) / baseline.HitboxWidth, math.min(0.05, baseline.HitboxHeight) / baseline.HitboxHeight, math.min(0.05, baseline.Range) / baseline.Range)
			ratio = math.max(minimumRatio, ratio)
			draft.HitboxWidth = baseline.HitboxWidth * ratio; draft.HitboxHeight = baseline.HitboxHeight * ratio; draft.Range = baseline.Range * ratio
		elseif scaleMode == nil or scaleMode == "Axis" then
			draft[key] = math.max(0.05, baseline[key] + distance)
		else return nil, "Choose Axis or Uniform scaling." end
		if draft.HitboxWidth == baseline.HitboxWidth and draft.HitboxHeight == baseline.HitboxHeight and draft.Range == baseline.Range then return draft, nil end
		displacement = (draft[key] - baseline[key]) / 2
	else return nil, "Choose Move or Resize." end
	setCenter(draft, center(baseline) + rotation(baseline):VectorToWorldSpace(normal * displacement))
	if not validGeometry(draft) then return nil, "Dragged geometry is not finite." end
	return draft, nil
end
function HitboxEditor.rotate(baseline, axis: Enum.Axis, angle: number)
	if not validGeometry(baseline) or not finite(angle) then return nil, "Rotation must be finite." end
	local direction = if axis == Enum.Axis.X then Vector3.xAxis elseif axis == Enum.Axis.Y then Vector3.yAxis elseif axis == Enum.Axis.Z then Vector3.zAxis else nil
	if not direction then return nil, "Unknown rotation axis." end
	local result = copy(baseline)
	if angle % (2 * math.pi) == 0 then return result, nil end
	local x, y, z = (rotation(baseline) * CFrame.fromAxisAngle(direction, angle % (2 * math.pi))):ToOrientation()
	result.HitboxRotationX = (math.deg(x) + 180) % 360 - 180
	result.HitboxRotationY = (math.deg(y) + 180) % 360 - 180
	result.HitboxRotationZ = (math.deg(z) + 180) % 360 - 180
	return result, nil
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
	if not selectedModel then return nil, "Select a dummy Model or one of its parts, then Toggle Preview." end
	local root = selectedModel:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return nil, "The selected dummy needs a BasePart HumanoidRootPart." end
	return root, nil
end
function HitboxEditor.start(plugin, config, onChanged, onStopped, onStateChanged)
	if activeSession then activeSession.destroy() end
	local draft, problem = HitboxEditor.newDraft(config)
	if not draft then return nil, problem end
	local session = {}
	local reference, model, humanoid
	local objects, connections, lifetime = {}, {}, {}
	local ended, visible = false, false
	local mode, scaleMode = "Preview", "Axis"
	local baseline, dragAxis, dragMode, dragScale
	local history = {}
	local gui, proxy, box, handles, arcs
	local function equal(a, b)
		for _, key in geometryKeys do if a[key] ~= b[key] then return false end end
		return true
	end
	local function notify()
		if onChanged then onChanged(copy(draft)) end
		if onStateChanged then onStateChanged(session.getState()) end
	end
	local function finishGesture()
		if baseline and not equal(baseline, draft) then table.insert(history, baseline) end
		baseline = nil; dragAxis = nil; dragMode = nil; dragScale = nil
	end
	function session.getDraft() return copy(draft) end
	function session.getState()
		return { visible = visible, mode = mode, scaleMode = scaleMode, canUndo = baseline ~= nil and not equal(baseline, draft) or #history > 0 }
	end
	local function stopRendering(message)
		finishGesture()
		visible = false; mode = "Preview"
		for _, connection in connections do connection:Disconnect() end
		table.clear(connections)
		for index = #objects, 1, -1 do objects[index]:Destroy() end
		table.clear(objects)
		gui = nil; proxy = nil; box = nil; handles = nil; arcs = nil
		pcall(function() plugin:Deactivate() end)
		if message and onStopped then onStopped(message) end
		notify()
	end
	function session.destroy()
		if ended then return end
		stopRendering()
		ended = true
		for _, connection in lifetime do connection:Disconnect() end
		table.clear(lifetime); table.clear(history)
		if activeSession == session then activeSession = nil end
	end
	local function refresh()
		local frame, size = HitboxEditor.transform(reference.CFrame, draft)
		for _, component in { frame:GetComponents() } do assert(finite(component), "Preview transform cannot be rendered.") end
		proxy.Size = size
		assert(proxy.Size == size, "This hitbox size is outside Studio preview limits; edit its config source instead.")
		proxy.CFrame = frame; box.Size = size
		box.CFrame = CFrame.new(center(draft)) * rotation(draft)
	end
	local function renderDraft()
		if not visible then return true end
		local ok, failure = pcall(refresh)
		if not ok then stopRendering("Could not render preview: " .. tostring(failure)) end
		return ok
	end
	function session.setMode(value)
		if ended or not visible then return false end
		if value ~= "Preview" and value ~= "Move" and value ~= "Resize" and value ~= "Rotate" then return false end
		finishGesture(); mode = value
		handles.Visible = mode == "Move" or mode == "Resize"; arcs.Visible = mode == "Rotate"
		handles.Style = if mode == "Move" then Enum.HandlesStyle.Movement else Enum.HandlesStyle.Resize
		notify(); return true
	end
	function session.setScaleMode(value)
		if ended or (value ~= "Axis" and value ~= "Uniform") then return false end
		finishGesture(); scaleMode = value; notify(); return true
	end
	function session.undo()
		if ended then return false end
		if baseline and not equal(baseline, draft) then
			draft = copy(baseline); baseline = nil; dragAxis = nil; dragMode = nil; dragScale = nil
		else
			baseline = nil; dragAxis = nil; dragMode = nil; dragScale = nil
			if #history == 0 then return false end
			draft = table.remove(history)
		end
		renderDraft(); notify(); return true
	end
	local function own(item)
		table.insert(objects, item); item.Archivable = false; return item
	end
	local function listen(signal, callback) table.insert(connections, signal:Connect(callback)) end
	local function beginGesture(axis, rotationGesture)
		if ended or not visible or (rotationGesture and mode ~= "Rotate") or (not rotationGesture and mode ~= "Move" and mode ~= "Resize") then return end
		finishGesture(); baseline = copy(draft); dragAxis = axis; dragMode = mode; dragScale = scaleMode
	end
	local function endGesture(axis, rotationGesture)
		if not visible or dragAxis ~= axis or dragMode ~= mode or (rotationGesture and mode ~= "Rotate") or (not rotationGesture and mode ~= "Move" and mode ~= "Resize") then return end
		finishGesture(); notify()
	end
	local function drag(axis, amount, rotationGesture)
		if ended or not visible or not baseline or dragAxis ~= axis or dragMode ~= mode or dragScale ~= scaleMode
			or (rotationGesture and mode ~= "Rotate") or (not rotationGesture and mode ~= "Move" and mode ~= "Resize") then return end
		local changed, failure
		if rotationGesture then changed, failure = HitboxEditor.rotate(baseline, axis, amount)
		else changed, failure = HitboxEditor.drag(baseline, mode, axis, amount, scaleMode) end
		if not changed then stopRendering(failure); return end
		local previous = draft; draft = changed
		local rendered, renderError = pcall(refresh)
		if not rendered then
			draft = previous
			stopRendering("Could not render preview: " .. tostring(renderError))
			return
		end
		notify()
	end
	function session.setPreviewVisible(value)
		if ended then return false, "The editor is closed." end
		if not value then stopRendering("Preview Ended"); return true, "Preview Ended" end
		if visible then return true, "Preview active." end
		if RunService:IsRunning() then return false, "Stop the playtest before previewing a hitbox." end
		if not reference then
			local selectionError
			reference, selectionError = HitboxEditor.selectRoot(Selection:Get())
			if not reference then return false, selectionError end
			model = reference.Parent; humanoid = model:FindFirstChildOfClass("Humanoid")
		end
		if not reference:IsDescendantOf(workspace) or reference.Parent ~= model or not humanoid or humanoid.Parent ~= model then
			return false, "The reference dummy or root was removed. Reopen Edit Hitbox with a valid dummy selected."
		end
		local ok, failure = pcall(function()
			gui = own(Instance.new("ScreenGui")); gui.Name = "CombatForgeHitboxPreview"; gui.Parent = CoreGui
			proxy = own(Instance.new("Part")); proxy.Name = "CombatForgeHitboxHandleProxy"
			proxy.Anchored = true; proxy.CanCollide = false; proxy.CanTouch = false; proxy.CanQuery = false; proxy.Transparency = 1
			box = own(Instance.new("BoxHandleAdornment")); box.Name = "HitboxPreview"; box.Adornee = reference
			box.Color3 = Color3.fromRGB(80, 210, 255); box.Transparency = 0.65; box.AlwaysOnTop = true; box.ZIndex = 1; box.Parent = gui
			refresh()
			handles = own(Instance.new("Handles")); handles.Name = "HitboxHandles"; handles.Visible = false
			handles.Adornee = proxy; handles.Color3 = Color3.fromRGB(255, 190, 70)
			handles.Faces = Faces.new(Enum.NormalId.Right, Enum.NormalId.Left, Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Back)
			handles.Style = Enum.HandlesStyle.Movement; handles.Parent = gui
			arcs = own(Instance.new("ArcHandles")); arcs.Name = "HitboxRotationHandles"; arcs.Visible = false
			arcs.Axes = Axes.new(Enum.Axis.X, Enum.Axis.Y, Enum.Axis.Z); arcs.Adornee = proxy; arcs.Parent = gui
			listen(handles.MouseButton1Down, function(axis) beginGesture(axis, false) end)
			listen(handles.MouseButton1Up, function(axis) endGesture(axis, false) end)
			listen(handles.MouseDrag, function(axis, distance) drag(axis, distance, false) end)
			listen(arcs.MouseButton1Down, function(axis) beginGesture(axis, true) end)
			listen(arcs.MouseButton1Up, function(axis) endGesture(axis, true) end)
			listen(arcs.MouseDrag, function(axis, angle) drag(axis, angle, true) end)
			listen(RunService.RenderStepped, function()
				if RunService:IsRunning() then stopRendering("Preview Ended"); return end
				if not reference:IsDescendantOf(workspace) or reference.Parent ~= model or humanoid.Parent ~= model then stopRendering("Preview Ended"); return end
				renderDraft()
			end)
			listen(plugin.Deactivation, function() if visible then stopRendering("Preview Ended") end end)
			visible = true; mode = "Preview"; plugin:Activate(true)
		end)
		if not ok then stopRendering("Could not start preview: " .. tostring(failure)); return false, "Could not start preview: " .. tostring(failure) end
		notify(); return true, "Preview active. Choose Move, Resize or Rotate."
	end
	table.insert(lifetime, plugin.Unloading:Connect(function() session.destroy() end))
	activeSession = session
	local _, message = session.setPreviewVisible(true)
	notify()
	return session, message
end
return HitboxEditor
