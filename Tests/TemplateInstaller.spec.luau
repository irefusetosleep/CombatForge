-- AC-02/06/07: actual packaged sources, isolated services and unparented instances.
return function(loadInstaller, hitboxSource, templates)
 local count = 0
 local function check(value, message) assert(value, message); count += 1 end
 local storage, pack = Instance.new("Folder"), Instance.new("Folder")
 local hitbox = Instance.new("ModuleScript"); hitbox.Source = hitboxSource
 local running, allow, failCommit = false, true, false
 local begins, commits, cancels = 0, 0, 0
 local installer = loadInstaller({
  ReplicatedStorage = storage, StarterPack = pack,
  RunService = {IsRunning = function() return running end},
  ScriptEditorService = {GetEditorSource = function(_, module) return module.Source end},
  ChangeHistoryService = {
   TryBeginRecording = function() begins += 1; return if allow then "recording" else nil end,
   FinishRecording = function(_, _, operation)
    if operation == Enum.FinishRecordingOperation.Commit then
     if failCommit then error("Injected commit failure") end
     commits += 1
    else cancels += 1 end
   end,
  },
 })
 local function install(kind, mode) return installer.install(hitbox, templates[kind], kind, mode or "Mouse") end
 local function clear() pack:ClearAllChildren(); storage:ClearAllChildren() end
 local ok, failure = pcall(function()
  running = true
  check(not install("Melee") and #pack:GetChildren() == 0 and #storage:GetChildren() == 0, "AC06 Play generation refused")
  running = false; allow = false
  check(not install("Melee") and #pack:GetChildren() == 0 and #storage:GetChildren() == 0, "AC06 Recording unavailable leaves no mutation")
  allow = true
  check(not install("Unknown") and #pack:GetChildren() == 0, "AC06 Invalid kind rejected")
  check(not install("Projectile", "Unknown") and #pack:GetChildren() == 0, "AC06 Invalid aim rejected")
  for _, kind in {"Melee", "Projectile"} do
   for _, mode in {"Mouse", "Body"} do
    local before = commits
    check(install(kind, mode), "AC02 Create " .. kind .. " " .. mode)
    check(commits == before + 1, "AC06 Exactly one commit per creation")
    if kind == "Projectile" then
     local newest = pack:FindFirstChild("CombatForge Projectile Skill" .. (if mode == "Body" then " 2" else ""))
     check(newest and newest.Skill.Config.Value.Source:find('AimMode = "' .. mode .. '"', 1, true), "AC01 Aim stored in linked config source")
    end
   end
  end
  local names = {}
  for _, tool in pack:GetChildren() do
   check(tool:IsA("Tool") and not tool.RequiresHandle and not tool.CanBeDropped, "AC02 Ready Tool properties")
   check(not names[tool.Name], "AC02 Repeated creation has unique names"); names[tool.Name] = true
   for childName, class in {Client="LocalScript", Server="Script", Skill="ModuleScript", ActivateSkill="RemoteEvent"} do
    local child = tool:FindFirstChild(childName)
    check(child and child:IsA(class), "AC02 Correct child " .. childName)
    if child:IsA("BaseScript") then check(child.Enabled, "AC07 Installed script enabled") end
   end
  end
  check(#pack:GetChildren() == 4, "AC02 Each invocation creates a fresh Tool")
  for _, template in templates do
   check(not template.Client.Enabled and not template.Server.Enabled, "AC07 Package templates stay disabled")
  end
  local original = pack:GetChildren()[1]
  original.Skill.Source = "return {DeveloperEdited=true}"
  check(install("Melee") and original.Skill.Source == "return {DeveloperEdited=true}", "AC02 Preserve previous edited Tool")
  clear()
  local collision = Instance.new("StringValue"); collision.Name = "CombatForge Melee Skill"; collision.Parent = pack
  check(install("Melee") and collision.Parent == pack and #pack:GetChildren() == 2, "AC02 Unrelated Tool-name collision gets fresh name")
  clear()
  local wrong = Instance.new("StringValue"); wrong.Name = "CombatForge"; wrong.Parent = storage
  check(not install("Melee") and wrong.Parent == storage and #pack:GetChildren() == 0, "AC06 Conflicting shared root preserved")
  clear()
  check(install("Melee"), "AC06 Shared runtime installed")
  local runtime = storage.CombatForge.Runtime.Hitbox
  runtime.Source = "return {DeveloperEdited=true}"
  local previousTools = #pack:GetChildren()
  check(not install("Melee") and runtime.Source == "return {DeveloperEdited=true}" and #pack:GetChildren() == previousTools, "AC06 Incompatible runtime protected")
  clear(); failCommit = true
  local beforeCancels = cancels
  check(not install("Melee"), "AC06 Commit failure reported")
  check(#pack:GetChildren() == 0 and #storage:GetChildren() == 0 and cancels == beforeCancels + 1, "AC06 Commit failure rolls back complete new bundle")
  failCommit = false
  local malformed = templates.Melee:Clone(); malformed.Client:Destroy()
  local beforeBegins = begins
  check(not installer.install(hitbox, malformed, "Melee", "Mouse") and #pack:GetChildren() == 0 and begins == beforeBegins, "AC06 Malformed template rejected before recording")
  malformed:Destroy()
 end)
 storage:Destroy(); pack:Destroy(); hitbox:Destroy()
 assert(ok, failure)
 return tostring(count) .. " template installer assertions passed (isolated services/instances)"
end
