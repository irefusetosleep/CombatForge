-- Coordinator runs this with repository sources keyed by normalized relative path.
-- Sources are compiled in isolated environments; no generated scripts are parented
-- into a live game service and no require() executes a game copy.
return function(sources)
 local results = {}
 local function compile(path, globals, override)
  local source = override or assert(sources[path], "Missing source " .. path)
  local chunk, problem = loadstring(source, "@" .. path)
  assert(chunk, problem)
  local environment = setmetatable(globals or {}, {__index = getfenv()})
  setfenv(chunk, environment)
  return chunk()
 end
 local function module(path, services, dependencies, globals, override)
  local environment = globals or {}
  environment.game = {GetService = function(_, name)
   if services and services[name] ~= nil then return services[name] end
   return game:GetService(name)
  end}
  local parent = setmetatable({}, {__index = function(_, name) return name end})
  environment.script = environment.script or setmetatable({Parent = parent}, {__index = function(_, name) return name end})
  environment.require = function(key)
   if type(dependencies) == "function" then return dependencies(key) end
   return assert(dependencies and dependencies[key], "Unmapped dependency " .. tostring(key))
  end
  return compile(path, environment, override)
 end
 local templates = {}
 local fixtures = {}
 local ok, failure = pcall(function()
  local parser = module("Plugin/AbilityConfig.luau")
  if sources["Tests/VisualHitboxConfig.spec.luau"] then table.insert(results,compile("Tests/VisualHitboxConfig.spec.luau")(parser)) end
  if sources["Tests/VisualHitboxSave.spec.luau"] then table.insert(results,compile("Tests/VisualHitboxSave.spec.luau")(parser,function(services)
   return module("Plugin/AbilityManager.luau",services,{AbilityConfig=parser})
  end)) end
  if sources["Tests/TemplateAllConfig.spec.luau"] then
   table.insert(results,compile("Tests/TemplateAllConfig.spec.luau")(parser,function(services)
    return module("Plugin/AbilityManager.luau",services,{AbilityConfig=parser})
   end))
  end
  -- Existing attack tests now get honest shared-config objects. The new paired
  -- generation suite below separately consumes actual installer-created links.
  local function linkedModule(path, services, dependencies, globals)
   if path ~= "Templates/MeleeSkill.luau" and path ~= "Templates/ProjectileSkill.luau" then
    return module(path, services, dependencies, globals)
   end
   local storage=Instance.new("Folder"); table.insert(fixtures,storage)
   local root=Instance.new("Folder"); root.Name="CombatForge"; root.Parent=storage
   local abilities=Instance.new("Folder"); abilities.Name="Abilities"; abilities.Parent=root
   local shared=Instance.new("ModuleScript"); shared.Name="TestSkill"; shared.Parent=abilities
   local common={Name="TestSkill",Damage=20,Cooldown=.75,Range=if path:find("Melee",1,true) then 6 else 80,AnimationId="",HitDelay=0}
   if path:find("Melee",1,true) then common.HitboxWidth=5; common.HitboxHeight=5
   else common.ProjectileSpeed=60; common.ProjectileRadius=.5; common.ProjectileLifetime=3; common.AimMode="Mouse" end
   shared.Source=parser.serialize(common)
   local scriptObject=Instance.new("ModuleScript"); scriptObject.Name="Skill"; scriptObject.Parent=root
   local link=Instance.new("ObjectValue"); link.Name="Config"; link.Value=shared; link.Parent=scriptObject
   local mapped={[shared]=common}
   if path:find("Melee",1,true) then
    local runtime=Instance.new("Folder"); runtime.Name="Runtime"; runtime.Parent=root
    local hitbox=Instance.new("ModuleScript"); hitbox.Name="Hitbox"; hitbox.Parent=runtime
    local _, supplied=next(dependencies); mapped[hitbox]=supplied
   end
   local actualServices=table.clone(services or {}); actualServices.ReplicatedStorage=storage
   local actualGlobals=table.clone(globals or {}); actualGlobals.script=scriptObject
   return module(path,actualServices,mapped,actualGlobals),common
  end
  local theme = module("Plugin/Theme.luau")
  local keybinds=module("Plugin/Keybinds.luau")
  local snapPrefs=module("Plugin/SnapPreferences.luau")
  if sources["Tests/Snapping.spec.luau"] then table.insert(results,compile("Tests/Snapping.spec.luau")(snapPrefs,function(services)return module("Plugin/RuntimeInstaller.luau",services)end)) end
  if sources["Tests/Keybinds.spec.luau"] then table.insert(results,compile("Tests/Keybinds.spec.luau")(keybinds)) end
  if sources["Tests/VisualHitboxGeometry.spec.luau"] then
   local editor=module("Plugin/HitboxEditor.luau",{Selection={},RunService={},CoreGui={}},{AbilityConfig=parser})
   table.insert(results,compile("Tests/VisualHitboxGeometry.spec.luau")(editor,parser,linkedModule))
  end
  if sources["Tests/VisualHitboxLifecycle.spec.luau"] then
   table.insert(results,compile("Tests/VisualHitboxLifecycle.spec.luau")(function(services,globals)
    return module("Plugin/HitboxEditor.luau",services,{AbilityConfig=parser},globals)
   end))
  end
  local colourPicker = module("Plugin/ColourPicker.luau")
  local function uiLoader(services)
   services=services or {}
   local function signal()
    local entries={}
    return {Connect=function(_,callback) local e={callback=callback,active=true};table.insert(entries,e); return {Disconnect=function()e.active=false end} end,
     Fire=function(_,...) for _,e in entries do if e.active then e.callback(...) end end end,
     Count=function()local n=0;for _,e in entries do if e.active then n+=1 end end;return n end}
   end
   local input=services.UserInputService or {GetFocusedTextBox=function()return nil end}
   for _,key in {"InputBegan","InputEnded","WindowFocusReleased","WindowFocused"} do input[key]=input[key] or signal() end
   input.IsKeyDown=input.IsKeyDown or function()return false end
   services.UserInputService=input
   local run=services.RunService or {IsRunning=function()return false end}
   run.GetPropertyChangedSignal=run.GetPropertyChangedSignal or function()return signal() end
   services.RunService=run
   local actions = {}
   local source = assert(sources["Plugin/UI.luau"])
   local marker = "item.Activated:Connect(function() if not busy then action() end end)"
   local instrumented, replacements = source:gsub(marker:gsub("(%W)", "%%%1"), function()
    return "actions[name] = function() if not busy then action() end end\n  " .. marker
   end)
   assert(replacements == 1, "UI callback instrumentation must match once")
   instrumented = instrumented:gsub("segment%.Activated:Connect%(function%(%)", "captureSegment(segment, function()")
   local ui = module("Plugin/UI.luau", services, {AbilityConfig=parser, AbilityManager={}, Theme=theme, ColourPicker=colourPicker, Keybinds=keybinds, SnapPreferences=snapPrefs}, {
    actions=actions, captureSegment=function(segment, callback)
     actions[segment.Name]=callback
     return segment.Activated:Connect(callback)
    end,
   }, instrumented)
   return ui, actions, services
  end
  for _, path in {"Tests/TemplateMenu.spec.luau", "Tests/Menu.spec.luau", "Tests/SkillDeleteMenu.spec.luau"} do
   local ui, actions = uiLoader()
   table.insert(results, compile(path)(ui, actions))
  end
  if sources["Tests/VisualHitboxMenu.spec.luau"] then
   local guards={focused=false,running=false}
   local ui,actions=uiLoader({UserInputService={GetFocusedTextBox=function() return if guards.focused then {} else nil end},RunService={IsRunning=function() return guards.running end}})
   table.insert(results,compile("Tests/VisualHitboxMenu.spec.luau")(ui,actions,parser,guards))
  end
  if sources["Tests/ProjectileEditor.spec.luau"] then
   table.insert(results,compile("Tests/ProjectileEditor.spec.luau")(parser,function(services)return module("Plugin/AbilityManager.luau",services,{AbilityConfig=parser})end,function(services,globals)return module("Plugin/HitboxEditor.luau",services,{AbilityConfig=parser},globals)end,uiLoader,linkedModule))
  end
  if sources["Tests/EditorInput.spec.luau"] then table.insert(results,compile("Tests/EditorInput.spec.luau")(uiLoader,keybinds,theme,parser)) end
  table.insert(results, compile("Tests/Startup.spec.luau")(function(plugin, dependencies, playing)
   local jobs={}
   module("Plugin/Main.server.luau", {RunService={IsRunning=function()return playing==true end},ContentProvider={PreloadAsync=function(_,assets,callback)callback(assets[1],Enum.AssetFetchStatus.Failure)end}}, dependencies, {plugin=plugin,task={defer=function(callback)local job={callback=callback};table.insert(jobs,job);return job end,cancel=function(job)job.cancelled=true end}})
   return function()for _,job in jobs do if not job.cancelled and not job.ran then job.ran=true;job.callback() end end end
  end))
  for _, kind in {"Melee", "Projectile"} do
   local tool = Instance.new("Tool"); tool.Name = kind
   tool.RequiresHandle = false; tool.CanBeDropped = false
   templates[kind] = tool
   for name, class in {Client="LocalScript", Server="Script", Skill="ModuleScript", ActivateSkill="RemoteEvent"} do
    local child = Instance.new(class); child.Name = name
    if child:IsA("BaseScript") then child.Enabled = false end
    if child:IsA("LuaSourceContainer") then
     local path = if name == "Skill" then "Templates/" .. kind .. "Skill.luau" else "Templates/Tool" .. name .. (if name == "Client" then ".client.luau" else ".server.luau")
     child.Source = assert(sources[path], "Missing template source " .. path)
    end
    child.Parent = tool
   end
  end
  table.insert(results, compile("Tests/TemplateInstaller.spec.luau")(function(services)
   return module("Plugin/TemplateInstaller.luau", services, {AbilityConfig=parser})
  end, assert(sources["Runtime/Hitbox.luau"]), templates))
  -- Runtime suites receive the same source loader; all callbacks/services are
  -- supplied by the spec, with real isolated Instances where they matter.
  if sources["Tests/TemplateRuntime.spec.luau"] then
   table.insert(results, compile("Tests/TemplateRuntime.spec.luau")(linkedModule, sources))
  end
  if sources["Tests/TemplateWorld.spec.luau"] then
   table.insert(results, compile("Tests/TemplateWorld.spec.luau")(linkedModule))
  end
  if sources["Tests/TemplateSharedConfig.spec.luau"] then
   table.insert(results,compile("Tests/TemplateSharedConfig.spec.luau")(module,parser,templates,assert(sources["Runtime/Hitbox.luau"])))
  end
  for _, path in {"Tests/AbilityCreation.spec.luau","Tests/AbilityUpdate.spec.luau","Tests/AbilityDelete.spec.luau"} do
   if sources[path] then table.insert(results,compile(path)(parser,function(services)
    return module("Plugin/AbilityManager.luau",services,{AbilityConfig=parser})
   end)) end
  end
 end)
 for _, template in templates do template:Destroy() end
 for _, fixture in fixtures do fixture:Destroy() end
 assert(ok, failure)
 return table.concat(results, "\n")
end
