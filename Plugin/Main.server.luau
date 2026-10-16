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
local TemplateInstaller = require(script.TemplateInstaller)
local DummySpawner = require(script.DummySpawner)
local HitboxEditor = require(script.HitboxEditor)
local toolbar = plugin:CreateToolbar("CombatForge")
local icon = "rbxasset://textures/sparkle.png"
local logo = "rbxassetid://118596951641724"
local button = toolbar:CreateButton("CombatForge.Toggle", "Open or close CombatForge", icon, "CombatForge")
button.ClickableWhenViewportHidden = true
-- A shortcut action provides a second entry point if Studio hides the ribbon button.
local openAction = plugin:CreatePluginAction("CombatForge.OpenEditor", "Open CombatForge", "Open the CombatForge skill editor", icon, true)

local connections: { RBXScriptConnection } = {}
local widget: DockWidgetPluginGui? = nil
local unloaded = false
local iconTask: thread? = nil

local function cleanup()
	if unloaded then
		return
	end
	unloaded = true
	if iconTask then
		pcall(task.cancel, iconTask)
		iconTask = nil
	end
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
	end, function(rigType: Enum.HumanoidRigType)
		return DummySpawner.spawn(rigType)
	end, function(kind: string, aimMode: string)
		local template = if kind == "Melee" then script.MeleeToolTemplate else script.ProjectileToolTemplate
		return TemplateInstaller.install(script.HitboxTemplate, template, kind, aimMode)
	end, {
		isSupported = HitboxEditor.isSupported,
		start = function(config, onChanged, onStopped)
			return HitboxEditor.start(plugin, config, onChanged, onStopped)
		end,
	})

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
