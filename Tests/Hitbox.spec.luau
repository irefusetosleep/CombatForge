return function(Hitbox)
 local assertions = 0
 local function check(value, message) assert(value, message); assertions += 1 end
 local world = Instance.new("WorldModel")
 world.Name = "CombatForgeHitboxTest"
 world.Parent = workspace
 local detectors = {}
 local function part(parent, position)
  local item = Instance.new("Part")
  item.Anchored = true; item.Size = Vector3.new(1,1,1); item.Position = position; item.Parent = parent
  return item
 end
 local function character(name, position)
  local model = Instance.new("Model"); model.Name = name; model.Parent = world
  local humanoid = Instance.new("Humanoid"); humanoid.Parent = model
  part(model, position); part(model, position + Vector3.new(0,1,0))
  return model, humanoid
 end
 local caster = character("Caster", Vector3.zero)
 local target, humanoid = character("Target", Vector3.new(2,0,0))
 local accessory = Instance.new("Accessory"); accessory.Parent = target
 part(accessory, Vector3.new(2,0,0))
 local object = part(world, Vector3.new(-2,0,0))
 local ignored = part(world, Vector3.new(0,0,2))
 local distant = part(world, Vector3.new(50,0,0))
 local prop = Instance.new("Model"); prop.Parent = world
 part(prop, Vector3.new(0,0,-2)); part(prop, Vector3.new(0,0,-3))
 local notQueryable = part(world, Vector3.zero); notQueryable.CanCollide = false; notQueryable.CanQuery = false
 local function track(detector) table.insert(detectors, detector); return detector end
 local function targets(hits)
  local result = {}; for _, hit in hits do result[hit.Target] = hit end; return result
 end
 local ok, failure = pcall(function()
  task.wait()
  local filter = {ignored}
  local box = track(Hitbox.Box(CFrame.new(), Vector3.new(10,10,10), {Caster = caster, Filter = filter, WorldRoot = world}))
  table.clear(filter) -- Constructor takes a snapshot instead of retaining caller state.
  local events = {}
  box.HitDetected:Connect(function(hit) table.insert(events, hit) end)
  local hits = box:Cast(); task.wait()
  local found = targets(hits)
  check(#hits == 3, "Box returns character, loose part and prop once each")
  check(not found[caster], "Caster excluded by default")
  check(not found[ignored] and not found[distant] and not found[notQueryable], "Filter, bounds and CanQuery")
  check(found[target].Humanoid == humanoid and found[target].Model == target and found[target].Part:IsA("BasePart"), "Character payload")
  check(found[target].Player == nil, "NPC has no player")
  check(found[object].Model == nil and found[object].Humanoid == nil, "Loose object payload")
  check(found[prop].Model == prop, "Model deduplication")
  check(#events == #hits, "One event per returned hit")
  box:Cast(); task.wait(); check(#events == #hits * 2, "New cast permits repeat targets")
  check(#box:Cast(CFrame.new(100,0,0)) == 0, "Origin override")
  local sphere = track(Hitbox.Sphere(Vector3.zero, 5, {Caster = caster, CanHitCaster = true, Filter = {ignored, prop}, WorldRoot = world}))
  found = targets(sphere:Cast())
  check(found[caster] ~= nil and found[target] ~= nil and found[object] ~= nil, "Sphere and caster opt-in")
  check(not found[prop], "Filter excludes model descendants")
  local excludeEvenCaster = track(Hitbox.Sphere(Vector3.zero,5,{Caster=caster,CanHitCaster=true,Filter={caster},WorldRoot=world}))
  check(not targets(excludeEvenCaster:Cast())[caster], "Explicit filter wins over caster opt-in")
  check(targets(sphere:Cast(Vector3.new(50,0,0)))[distant] ~= nil, "Sphere origin override")
  local small = track(Hitbox.Sphere(Vector3.new(20,0,0),1,{Caster=caster,WorldRoot=world}))
  check(#small:Cast() == 0, "Empty region")
  local rotatedTarget = part(world, Vector3.new(100,0,3))
  local corner = part(world, Vector3.new(204.5,0,4.5))
  task.wait()
  local narrow = track(Hitbox.Box(CFrame.new(100,0,0),Vector3.new(8,2,2),{Caster=caster,WorldRoot=world}))
  check(not targets(narrow:Cast())[rotatedTarget], "Unrotated narrow box excludes side")
  check(targets(narrow:Cast(CFrame.new(100,0,0)*CFrame.Angles(0,math.pi/2,0)))[rotatedTarget] ~= nil, "Box respects rotation")
  local cornerBox = track(Hitbox.Box(CFrame.new(200,0,0),Vector3.new(10,10,10),{Caster=caster,WorldRoot=world}))
  local cornerSphere = track(Hitbox.Sphere(Vector3.new(200,0,0),5,{Caster=caster,WorldRoot=world}))
  check(targets(cornerBox:Cast())[corner] ~= nil, "Box includes corner")
  check(not targets(cornerSphere:Cast())[corner], "Sphere excludes box corner outside radius")
  box:Destroy(); box:Destroy()
  check(not pcall(function() box:Cast() end), "Destroyed detector cannot cast")
  for _, radius in {0, -1, math.huge, 0/0} do
   check(not pcall(function() Hitbox.Sphere(Vector3.zero,radius,{Caster=caster}) end), "Reject invalid radius")
  end
  check(not pcall(function() Hitbox.Box(CFrame.new(),Vector3.new(0,1,1),{Caster=caster}) end), "Reject zero box size")
  check(not pcall(function() Hitbox.Sphere(Vector3.zero,5,{}) end), "Require caster")
  check(not pcall(function() Hitbox.Sphere(Vector3.zero,5,{Caster=caster,Filter={false}}) end), "Reject invalid filter")
 end)
 for _, detector in detectors do detector:Destroy() end
 world:Destroy()
 assert(ok, failure)
 return tostring(assertions) .. " hitbox assertions passed using real isolated WorldModel overlap queries"
end
