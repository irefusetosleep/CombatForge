--!strict
local History = game:GetService("ChangeHistoryService")
local Storage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local RunService = game:GetService("RunService")
local Editor = game:GetService("ScriptEditorService")
local AbilityConfig = require(script.Parent.AbilityConfig)
local Installer = {}

local function unique(parent: Instance, name: string, class: string): Instance?
	local found: Instance? = nil
	for _, child in parent:GetChildren() do
		if child.Name == name then
			assert(not found and child:IsA(class), parent:GetFullName() .. "." .. name .. " has conflicting objects")
			found = child
		end
	end
	return found
end

function Installer.install(hitbox: ModuleScript, template: Tool, kind: string, aimMode: string): (boolean, string)
	if RunService:IsRunning() then return false, "Stop the playtest before creating a template skill." end
	local recording: string? = nil
	local created: { Instance } = {}
	local name = ""
	local configName = ""
	local ok, failure = pcall(function()
		assert(kind == "Melee" or kind == "Projectile", "Unknown template kind")
		assert(aimMode == "Mouse" or aimMode == "Body", "Choose Mouse Aim or Body Aim")
		assert(template:IsA("Tool") and not template.RequiresHandle and not template.CanBeDropped, "Invalid template Tool")
		assert(#template:GetChildren() == 4, "Template Tool must contain exactly four children")
		for _, entry in { { "Client", "LocalScript" }, { "Server", "Script" }, { "Skill", "ModuleScript" }, { "ActivateSkill", "RemoteEvent" } } do
			assert(unique(template, entry[1], entry[2]), "Template is missing " .. entry[1])
		end
		local source = (template:FindFirstChild("Skill") :: ModuleScript).Source
		if kind == "Projectile" then
			local count
			source, count = string.gsub(source, 'AimMode = "Mouse", %-%- TEMPLATE_AIM_MODE', 'AimMode = "' .. aimMode .. '", -- TEMPLATE_AIM_MODE')
			assert(count == 1, "Projectile template aim setting is missing or ambiguous")
		end
		local root = unique(Storage, "CombatForge", "Folder")
		local abilities = if root then unique(root, "Abilities", "Folder") else nil
		local runtime: Instance? = nil
		local existing: Instance? = nil
		if kind == "Melee" then
			assert(hitbox:IsA("ModuleScript"), "Hitbox template must be a ModuleScript")
			runtime = if root then unique(root, "Runtime", "Folder") else nil
			existing = if runtime then unique(runtime, "Hitbox", "ModuleScript") else nil
			if existing then
				assert(Editor:GetEditorSource(existing :: ModuleScript) == hitbox.Source, "Existing Hitbox differs; back it up and rename it before creating a melee template. It was not overwritten.")
			end
		end
		local configBase = kind .. "Skill"
		configName = configBase
		local configSuffix = 2
		local occupied = {}
		if abilities then
			for _, child in abilities:GetChildren() do occupied[string.lower(child.Name)] = true end
		end
		while occupied[string.lower(configName)] do
			configName = configBase .. configSuffix; configSuffix += 1
		end
		local configSource = AbilityConfig.serialize({ Name = configName, Damage = 20, Cooldown = 0.75, Range = if kind == "Melee" then 6 else 80 })
		local base = "CombatForge " .. kind .. " Skill"
		name = base
		local suffix = 2
		while StarterPack:FindFirstChild(name) do name = base .. " " .. suffix; suffix += 1 end
		recording = History:TryBeginRecording("CombatForge.CreateTemplate", "Create " .. name)
		assert(recording, "Could not begin undo recording. Try again.")
		local function folder(parent: Instance, folderName: string): Instance
			local item = Instance.new("Folder"); table.insert(created, item)
			item.Name = folderName; item.Parent = parent; return item
		end
		root = root or folder(Storage, "CombatForge")
		abilities = abilities or folder(root :: Instance, "Abilities")
		if kind == "Melee" then
			runtime = runtime or folder(root :: Instance, "Runtime")
			if not existing then
				local module = hitbox:Clone(); table.insert(created, module)
				module.Name = "Hitbox"; module.Parent = runtime
			end
		end
		local config = Instance.new("ModuleScript"); table.insert(created, config)
		config.Name = configName; config.Source = configSource; config.Parent = abilities
		local tool = template:Clone(); table.insert(created, tool)
		tool.Name = name
		local skill = tool:FindFirstChild("Skill") :: ModuleScript
		skill.Source = source
		assert(not skill:FindFirstChild("Config"), "Template Skill already contains a Config link")
		local link = Instance.new("ObjectValue"); table.insert(created, link)
		link.Name = "Config"; link.Value = config; link.Parent = skill
		for _, child in tool:GetChildren() do
			if child:IsA("BaseScript") then child.Enabled = true end
		end
		tool.Parent = StarterPack
		History:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Commit)
		recording = nil
	end)
	if not ok then
		for index = #created, 1, -1 do created[index]:Destroy() end
		if recording then
			local cancelled, problem = pcall(function() History:FinishRecording(recording :: string, Enum.FinishRecordingOperation.Cancel) end)
			if not cancelled then warn("[CombatForge] Template rollback failed: " .. tostring(problem)) end
		end
		return false, tostring(failure)
	end
	return true, "Created StarterPack." .. name .. " with ReplicatedStorage.CombatForge.Abilities." .. configName .. ". Refresh Update Skills to edit damage, cooldown and range; edit the Tool Skill for advanced settings. Changes apply next Play. Save your place."
end

return Installer
