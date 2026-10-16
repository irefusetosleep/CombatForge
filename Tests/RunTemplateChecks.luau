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
  environment.require = function(key) return assert(dependencies and dependencies[key], "Unmapped dependency " .. tostring(key)) end
  return compile(path, environment, override)
 end
 local templates = {}
 local ok, failure = pcall(function()
  local parser = module("Plugin/AbilityConfig.luau")
  local theme = module("Plugin/Theme.luau")
  local colourPicker = module("Plugin/ColourPicker.luau")
  local function uiLoader()
   local actions = {}
   local source = assert(sources["Plugin/UI.luau"])
   local marker = "item.Activated:Connect(function() if not busy then action() end end)"
   local instrumented, replacements = source:gsub(marker:gsub("(%W)", "%%%1"), function()
    return "actions[name] = function() if not busy then action() end end\n  " .. marker
   end)
   assert(replacements == 1, "UI callback instrumentation must match once")
   instrumented = instrumented:gsub("segment%.Activated:Connect%(function%(%)", "captureSegment(segment, function()")
   local ui = module("Plugin/UI.luau", nil, {AbilityConfig=parser, AbilityManager={}, Theme=theme, ColourPicker=colourPicker}, {
    actions=actions, captureSegment=function(segment, callback)
     actions[segment.Name]=callback
     return segment.Activated:Connect(callback)
    end,
   }, instrumented)
   return ui, actions
  end
  for _, path in {"Tests/TemplateMenu.spec.luau", "Tests/Menu.spec.luau", "Tests/SkillDeleteMenu.spec.luau"} do
   local ui, actions = uiLoader()
   table.insert(results, compile(path)(ui, actions))
  end
  table.insert(results, compile("Tests/Startup.spec.luau")(function(plugin, dependencies)
   return module("Plugin/Main.server.luau", nil, dependencies, {plugin=plugin})
  end))
  if sources["Tests/Example.spec.luau"] then
   table.insert(results, compile("Tests/Example.spec.luau")(function(services, configParser)
    return module("Plugin/ExampleInstaller.luau", services, {AbilityConfig=configParser})
   end, function(services, hitbox, settings, previewWorld, clock, delay)
    return module("Examples/ExampleSlash.luau", services, {Runtime=hitbox, Abilities=settings}, {
     workspace=previewWorld, os={clock=clock}, task={delay=delay},
    })
   end, nil, parser))
  end
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
   return module("Plugin/TemplateInstaller.luau", services)
  end, assert(sources["Runtime/Hitbox.luau"]), templates))
  -- Runtime suites receive the same source loader; all callbacks/services are
  -- supplied by the spec, with real isolated Instances where they matter.
  if sources["Tests/TemplateRuntime.spec.luau"] then
   table.insert(results, compile("Tests/TemplateRuntime.spec.luau")(module, sources))
  end
  if sources["Tests/TemplateWorld.spec.luau"] then
   table.insert(results, compile("Tests/TemplateWorld.spec.luau")(module))
  end
 end)
 for _, template in templates do template:Destroy() end
 assert(ok, failure)
 return table.concat(results, "\n")
end
