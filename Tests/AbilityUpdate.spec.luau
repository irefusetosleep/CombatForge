return function(Config, loadManager)
 local count = 0
 local function check(value, message) assert(value, message); count += 1 end
 local function inputs(name, damage) return { Name = name or "Slash", Damage = damage or "20", Cooldown = "0.5", Range = "5" } end
 local config = assert(Config.validate(inputs()))
 check(Config.parse(Config.serialize(config)).Name == "Slash", "Read existing generated format")
 check(Config.parse("return { Range=5; Name='Slash'; Cooldown=0.5; Damage=20 }").Damage == 20, "Order and whitespace")
 for _, source in {
  "error('do not execute')", "return {Name='Slash', Damage=20, Cooldown=0.5, Range=5, Extra=1}",
  "return {Name='Slash', Damage=20, Damage=30, Cooldown=0.5, Range=5}",
  "return {Name='Slash', Damage=math.random(), Cooldown=0.5, Range=5}",
  "return {Name='Slash', Damage=20, Cooldown=0.5, Range=5}; print('unsafe')",
 } do check(Config.parse(source) == nil, "Refuse custom source") end
 local storage = Instance.new("Folder")
 local root = Instance.new("Folder"); root.Name = "CombatForge"; root.Parent = storage
 local folder = Instance.new("Folder"); folder.Name = "Abilities"; folder.Parent = root
 local module = Instance.new("ModuleScript"); module.Name = "Slash"; module.Source = Config.serialize(config); module.Parent = folder
 local running, failCommit, conflict = false, false, false
 local originalName, originalSource
 local commits, cancels = 0, 0
 local services = {
  ReplicatedStorage = storage,
  RunService = { IsRunning = function() return running end },
  ScriptEditorService = {
   GetEditorSource = function(_, target) return target.Source end,
   UpdateSourceAsync = function(_, target, callback)
    local updated = callback(if conflict then target.Source .. "\n-- External change" else target.Source)
    if updated then target.Source = updated end
   end,
  },
  ChangeHistoryService = {
   TryBeginRecording = function() originalName = module.Name; originalSource = module.Source; return "recording" end,
   FinishRecording = function(_, _, operation)
    if operation == Enum.FinishRecordingOperation.Commit then
     if failCommit then error("Injected commit failure") end
     commits += 1
    else module.Name = originalName; module.Source = originalSource; cancels += 1 end
   end,
  },
 }
 local manager = loadManager(services)
 local ok, failure = pcall(function()
  local list = manager.list(); check(#list == 1 and list[1] == module, "List legacy skill")
  local snapshot = assert(manager.read(module))
  check(snapshot.config.Damage == 20, "Read fields")
  check(manager.update(snapshot, inputs("HeavySlash", "45")), "Save rename and fields")
  check(module.Name == "HeavySlash" and Config.parse(module.Source).Damage == 45, "Updated same module")
  check(#folder:GetChildren() == 1 and commits == 1, "One record, no duplicate module")
  check(not manager.update(snapshot, inputs()), "Stale rename rejected")
  snapshot = assert(manager.read(module))
  check(manager.update(snapshot, inputs("HeavySlash", "50")), "Repeated save after reloading")
  snapshot = assert(manager.read(module))
  module.Source ..= "\n-- manual change"
  check(not manager.update(snapshot, inputs()), "External source edit rejected")
  snapshot = assert(manager.read(module))
  local collision = Instance.new("StringValue"); collision.Name = "SLASH"; collision.Parent = folder
  check(not manager.update(snapshot, inputs()), "Case-insensitive rename collision")
  collision:Destroy()
  running = true; check(not manager.update(snapshot, inputs()), "Play-mode blocked"); running = false
  conflict = true; check(not manager.update(snapshot, inputs()), "Callback conflict rejected"); conflict = false
  check(module.Name == snapshot.name and module.Source == snapshot.source, "Conflict preserves skill")
  failCommit = true; check(not manager.update(snapshot, inputs()), "Commit failure caught"); failCommit = false
  check(module.Name == snapshot.name and module.Source == snapshot.source and cancels == 2, "Cancellation requested and rollback respected")
  module.Parent = nil
  check(not manager.update(snapshot, inputs()), "Moved skill rejected")
  check(manager.read(module) == nil, "Moved skill cannot open")
  module.Parent = folder
  module.Source = "error('must never run')"
  check(manager.read(module) == nil, "Unsafe script rejected without executing")
  module:Destroy()
  check(#manager.list() == 0, "Empty list")
 end)
 storage:Destroy()
 if module.Parent == nil then module:Destroy() end
 assert(ok, failure)
 return tostring(count) .. " update assertions passed"
end
