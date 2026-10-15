return function(loadInstaller, loadSkill, loadServer, ConfigParser)
 local count = 0
 local function check(value, message) assert(value, message); count += 1 end
 local storage, pack, previewWorld = Instance.new("Folder"), Instance.new("Folder"), Instance.new("Folder")
 local hitbox, config, template = Instance.new("ModuleScript"), Instance.new("ModuleScript"), Instance.new("Tool")
 hitbox.Source = "return {}"
 config.Source = 'return {Name="ExampleSlash", Damage=20, Cooldown=1, Range=6}'
 template.RequiresHandle = false
 for name, class in {Skill="ModuleScript", Server="Script", Client="LocalScript", ActivateSkill="RemoteEvent"} do
  local child=Instance.new(class); child.Name=name; child.Parent=template
  if child:IsA("BaseScript") then child.Enabled=false end
 end
 local commits, cancels = 0, 0
 local running, failCommit = false, false
 local installer = loadInstaller({
  ReplicatedStorage=storage, StarterPack=pack, RunService={IsRunning=function() return running end},
  ScriptEditorService={GetEditorSource=function(_,module) return module.Source end},
  ChangeHistoryService={TryBeginRecording=function() return "recording" end,FinishRecording=function(_,_,operation)
   if operation==Enum.FinishRecordingOperation.Commit then if failCommit then error("Test commit failure") end; commits+=1 else cancels+=1 end
  end},
 }, ConfigParser)
 local caster=Instance.new("Model")
 local casterHumanoid=Instance.new("Humanoid"); casterHumanoid.Parent=caster
 local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Anchored=true; root.Parent=caster
 local victim=Instance.new("Model"); local humanoid=Instance.new("Humanoid"); humanoid.Parent=victim
 local events, callbacks = {}, {}
 local ok,failure=pcall(function()
  running=true; check(not installer.install(hitbox,config,template),"Block play mode"); running=false
  check(installer.install(hitbox,config,template),"Install example bundle")
  check(commits==1 and pack["CombatForge Example Slash"].RequiresHandle==false,"One undo record and playable Tool")
  check(pack["CombatForge Example Slash"].Server.Enabled and pack["CombatForge Example Slash"].Client.Enabled and not template.Server.Enabled,"Enable installed scripts only")
  check(storage.CombatForge.Runtime.Hitbox.Source==hitbox.Source and storage.CombatForge.Abilities.ExampleSlash.Source==config.Source,"Runtime and editable config")
  storage.CombatForge.Abilities.ExampleSlash.Source='return {Name="ExampleSlash", Damage=35, Cooldown=1, Range=6}'
  check(installer.install(hitbox,config,template) and commits==1,"Repeat install preserves edited config")
  check(ConfigParser.parse(storage.CombatForge.Abilities.ExampleSlash.Source).Damage==35,"Custom damage retained")
  pack:ClearAllChildren()
  local collision=Instance.new("StringValue"); collision.Name="CombatForge Example Slash"; collision.Parent=pack
  check(not installer.install(hitbox,config,template) and #pack:GetChildren()==1,"Collision protection")
  pack:ClearAllChildren(); storage:ClearAllChildren(); failCommit=true
  check(not installer.install(hitbox,config,template),"Install failure caught")
  check(#pack:GetChildren()==0 and #storage:GetChildren()==0 and cancels==1,"Bundle rollback")

  local now=10
  local casts=0
  local server=true
  local settings={Damage=20,Cooldown=1,Range=6}
  local networkOptions, networkEvent
  local skill=loadSkill({
   RunService={IsServer=function() return server end},
   ReplicatedStorage={WaitForChild=function() return {WaitForChild=function(_,name) return {WaitForChild=function() return name end} end} end},
   Debris={AddItem=function(_,part) check(not part.CanQuery and not part.CanCollide,"Preview cannot affect queries"); part:Destroy() end},
  },{
   ClientToServer=function(options,debug)
    networkOptions=options
    check(debug==true and options.Offset==CFrame.new(1.5,0,-3),"Network debug and right-hand geometry")
    networkEvent=Instance.new("BindableEvent"); table.insert(events,networkEvent)
    return {HitDetected=networkEvent.Event,Destroy=function() networkEvent:Destroy() end}
   end,
   Box=function(center,size,options,debug)
    casts+=1
    check(options.Caster==caster and not options.CanHitCaster,"Caster protection")
    check(debug==true and size==Vector3.new(4,5,6) and center==root.CFrame*CFrame.new(-1.5,0,-3),"Configuration drives left-hand geometry and debug")
    local event=Instance.new("BindableEvent"); table.insert(events,event)
    return {HitDetected=event.Event,Cast=function() event:Fire({Target=victim,Humanoid=humanoid}); event:Fire({Target=caster,Humanoid=casterHumanoid}) end,Destroy=function() event:Destroy() end}
   end,
  },settings,previewWorld,function() return now end,function(_,callback) table.insert(callbacks,callback) end)
  check(skill.Activate(caster),"Activate skill")
  task.wait()
  check(humanoid.Health==80 and casterHumanoid.Health==100,"Server damage and no self damage")
  check(not skill.Activate(caster) and casts==1,"Cooldown blocks repeated request")
  now=12; check(skill.Activate(caster),"Cooldown expires")
  task.wait(); check(humanoid.Health==60,"Next activation damages again")
  local tool={Parent=caster,Enabled=true}
  skill.Bind(tool,{})
  check(not networkOptions.Authorize({Character=victim}),"Unequipped user rejected")
  now=14
  check(networkOptions.Authorize({Character=caster}),"One network report starts regular scan")
  networkEvent:Fire({Target=victim,Humanoid=humanoid},{Character=caster})
  task.wait()
  check(humanoid.Health==40,"Both modes damage shared target only once")
  check(not networkOptions.Authorize({Character=caster}),"Both modes share cooldown")
  tool.Enabled=false; now=16
  check(not networkOptions.Authorize({Character=caster}),"Disabled Tool rejected")
  root:Destroy(); now=18; check(not skill.Activate(caster),"Reject missing root")
  server=false; check(not pcall(skill.Activate,caster),"Reject client execution")
  for _,callback in callbacks do callback() end
  check(#previewWorld:GetChildren()==0,"Preview cleanup")

 end)
 for _,event in events do event:Destroy() end
 for _,item in {storage,pack,previewWorld,hitbox,config,template,caster,victim} do item:Destroy() end
 assert(ok,failure)
 return tostring(count).." example assertions passed with isolated services and instances"
end
