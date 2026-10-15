return function(loadInstaller)
 local assertions = 0
 local function check(value, message) assert(value,message); assertions += 1 end
 local storage = Instance.new("Folder")
 local template = Instance.new("ModuleScript"); template.Source = "return {}"
 local running, allow, failCommit = false,true,false
 local commits,cancels = 0,0
 local services = {
  ReplicatedStorage = storage,
  RunService = {IsRunning = function() return running end},
  ScriptEditorService = {GetEditorSource = function(_, module) return module.Source end},
  ChangeHistoryService = {
   TryBeginRecording = function() return if allow then "recording" else nil end,
   FinishRecording = function(_,_,operation)
    if operation == Enum.FinishRecordingOperation.Commit then
     if failCommit then error("Test commit failure") end
     commits += 1
    else cancels += 1 end
   end,
  },
 }
 local installer = loadInstaller(services)
 local ok,failure = pcall(function()
  running=true; check(not installer.install(template),"Reject play mode"); running=false
  allow=false; check(not installer.install(template) and #storage:GetChildren()==0,"No recording means no changes"); allow=true
  check(installer.install(template),"Install")
  local installed = storage.CombatForge.Runtime.Hitbox
  check(installed:IsA("ModuleScript") and installed.Source == template.Source,"Correct module path and source")
  check(installed ~= template and commits==1,"Clone and single undo recording")
  check(installer.install(template) and commits==1,"Idempotent repeated installation")
  installed.Source="return { Custom = true }"
  check(not installer.install(template) and installed.Source=="return { Custom = true }","Protect existing custom module")
  installed:Destroy()
  local collision=Instance.new("Folder"); collision.Name="Hitbox"; collision.Parent=storage.CombatForge.Runtime
  check(not installer.install(template) and collision.Parent~=nil,"Protect conflicting path")
  storage:ClearAllChildren()
  failCommit=true; check(not installer.install(template),"Catch commit failure")
  check(#storage:GetChildren()==0 and cancels==1,"Rollback newly created tree")
  failCommit=false
  local wrong=Instance.new("StringValue"); wrong.Name="CombatForge"; wrong.Parent=storage
  check(not installer.install(template) and wrong.Parent==storage,"Protect non-folder root")
 end)
 template:Destroy(); storage:Destroy()
 assert(ok,failure)
 return tostring(assertions).." runtime installer assertions passed"
end
