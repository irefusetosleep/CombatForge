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
local ExampleInstaller = require(script.ExampleInstaller)
local DummySpawner = require(script.DummySpawner)
local toolbar = plugin:CreateToolbar("CombatForge")
local icon = "rbxasset://textures/sparkle.png"
local button = toolbar:CreateButton("CombatForge.Toggle", "Open or close CombatForge", icon, "CombatForge")
button.ClickableWhenViewportHidden = true
-- A shortcut action provides a second entry point if Studio hides the ribbon button.
local openAction = plugin:CreatePluginAction("CombatForge.OpenEditor", "Open CombatForge", "Open the CombatForge skill editor", icon, true)

local connections: { RBXScriptConnection } = {}
local widget: DockWidgetPluginGui? = nil
local unloaded = false

local function cleanup()
	if unloaded then
		return
	end
	unloaded = true
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
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
	UI.mount(createdWidget, AbilityManager, Theme.new(plugin), function()
		return RuntimeInstaller.install(script.HitboxTemplate)
	end, function()
		return ExampleInstaller.install(script.HitboxTemplate, script.ExampleConfigTemplate, script.ExampleToolTemplate)
	end, function()
		return DummySpawner.spawn()
	end)

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
