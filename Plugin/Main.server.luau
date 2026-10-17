--!strict
-- Runs as an installed Studio plugin, not as a game server script.
if not plugin then
	warn("[CombatForge] Install this as a local Studio plugin to run it.")
	return
end

local UI = require(script.UI)
local AbilityManager = require(script.AbilityManager)
local Theme = require(script.Theme)
local RuntimeInstaller = require(script.RuntimeInstaller)
local TemplateInstaller = require(script.TemplateInstaller)
local DummySpawner = require(script.DummySpawner)
local HitboxEditor = require(script.HitboxEditor)
local Keybinds = require(script.Keybinds)
local SnapPreferences = require(script.SnapPreferences)
local toolbar = plugin:CreateToolbar("CombatForge")
local icon = "rbxasset://textures/sparkle.png"
local logo = "rbxthumb://type=Asset&id=118596951641724&w=150&h=150"
local button = toolbar:CreateButton("CombatForge.Toggle", "Open or close CombatForge", icon, "CombatForge")
button.ClickableWhenViewportHidden = true
-- A shortcut action provides a second entry point if Studio hides the ribbon button.
local openAction = plugin:CreatePluginAction("CombatForge.OpenEditor", "Open CombatForge", "Open the CombatForge skill editor", icon, true)

local connections: { RBXScriptConnection } = {}
local widget: DockWidgetPluginGui? = nil
local unloaded = false
local editorUI = nil
local iconTask: thread? = nil
local runtimeTask: thread? = nil

local function cleanup()
	if unloaded then
		return
	end
	unloaded = true
	if runtimeTask then pcall(task.cancel, runtimeTask); runtimeTask = nil end
	if iconTask then
		pcall(task.cancel, iconTask)
		iconTask = nil
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if editorUI then editorUI.destroy(); editorUI = nil end
	if widget then
		widget:Destroy()
	end
	toolbar:Destroy()
	openAction:Destroy()
end

table.insert(connections, plugin.Unloading:Connect(cleanup))

local success, failure = pcall(function()
	local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 360, 420, 280, 240)
	-- Keep this identifier stable so Studio can restore docking and visibility.
	local createdWidget = plugin:CreateDockWidgetPluginGuiAsync("CombatForge.Editor", info)
	if unloaded then
		createdWidget:Destroy()
		return
	end
	widget = createdWidget
	createdWidget.Title = "CombatForge"
	editorUI = UI.mount(createdWidget, AbilityManager, Theme.new(plugin), function()
		return RuntimeInstaller.ensure(script.HitboxTemplate)
	end, function(rigType: Enum.HumanoidRigType)
		return DummySpawner.spawn(rigType)
	end, function(kind: string, aimMode: string)
		local template = if kind == "Melee" then script.MeleeToolTemplate else script.ProjectileToolTemplate
		return TemplateInstaller.install(script.HitboxTemplate, template, kind, aimMode)
	end, {
		isSupported = HitboxEditor.isSupported,
		start = function(config, onChanged, onStopped, onStateChanged, getShiftHeld, snapValues)
			return HitboxEditor.start(plugin, config, onChanged, onStopped, onStateChanged, getShiftHeld, snapValues)
		end,
	}, Keybinds.new(plugin), SnapPreferences.new(plugin))

	local function syncButton()
		button:SetActive(createdWidget.Enabled)
	end
	table.insert(connections, button.Click:Connect(function()
		createdWidget.Enabled = not createdWidget.Enabled
	end))
	table.insert(connections, openAction.Triggered:Connect(function()
		createdWidget.Enabled = true
	end))
	table.insert(connections, createdWidget:GetPropertyChangedSignal("Enabled"):Connect(syncButton))
	-- Studio's default close action disables the widget; the listener updates the button.
	syncButton()
end)

if not success then
	cleanup()
	warn("[CombatForge] Could not start the plugin: " .. tostring(failure))
end

-- One startup attempt only: never counteract a user's runtime Undo/deletion.
if success and not unloaded then
 pcall(function()
  runtimeTask = task.defer(function()
   if unloaded then return end
   if game:GetService("RunService"):IsRunning() then
    if editorUI then editorUI.setRuntimeStatus(true, "Runtime startup setup skipped in Play. Stop Play and retry Install Hitbox Module, or reopen Studio in Edit mode.") end
    runtimeTask = nil; return
   end
   local ok, installed, message = pcall(RuntimeInstaller.ensure, script.HitboxTemplate)
   if not ok then message = "Could not ensure runtime: " .. tostring(installed) end
   if not unloaded and editorUI then editorUI.setRuntimeStatus(ok and installed, message) end
   if not ok or not installed then warn("[CombatForge] " .. tostring(message)) end
   runtimeTask = nil
  end)
 end)
end

-- Optional branding must never delay or prevent the editor from opening.
if success and not unloaded then
	pcall(function()
		iconTask = task.defer(function()
			pcall(function()
				if unloaded then return end
				local loaded = false
				game:GetService("ContentProvider"):PreloadAsync({ logo }, function(_, status)
					if status == Enum.AssetFetchStatus.Success then loaded = true end
				end)
				if loaded and not unloaded then button.Icon = logo end
			end)
			iconTask = nil
		end)
	end)
end
