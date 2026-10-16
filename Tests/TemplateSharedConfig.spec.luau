-- TEMPLATE-CONFIGS-02: generated sources and exact object references, with
-- isolated services/history. Native history and StarterPack cloning remain manual.
return function(module, Config, templates, hitboxSource)
 local count=0
 local function check(value,message) assert(value,message); count+=1 end
 local storage,pack=Instance.new("Folder"),Instance.new("Folder")
 local hitbox=Instance.new("ModuleScript"); hitbox.Source=hitboxSource
 local running,allow,failBegin,failCommit=false,true,false,false
 local commits,cancels,begins=0,0,0
 local warnings={}
 local spatialWorld
 local services={ReplicatedStorage=storage,StarterPack=pack,RunService={IsRunning=function() return running end,IsServer=function() return true end},
  ScriptEditorService={GetEditorSource=function(_,target) return target.Source end,UpdateSourceAsync=function(_,target,callback) local source=callback(target.Source); if source then target.Source=source end end},
  ChangeHistoryService={TryBeginRecording=function() begins+=1; if failBegin then error("Injected begin failure") end; return if allow then "recording" else nil end,
   FinishRecording=function(_,_,operation) if operation==Enum.FinishRecordingOperation.Commit then if failCommit then error("Injected commit failure") end; commits+=1 else cancels+=1 end end},
 }
 local installer=module("Plugin/TemplateInstaller.luau",services,{AbilityConfig=Config})
 local manager=module("Plugin/AbilityManager.luau",services,{AbilityConfig=Config})
 local function install(kind,mode) return installer.install(hitbox,templates[kind],kind,mode or "Mouse") end
 local function clear() pack:ClearAllChildren(); storage:ClearAllChildren() end
 local function folder(parent,name) local item=Instance.new("Folder"); item.Name=name; item.Parent=parent; return item end
 local function exactChildren(parent)
  local snapshot={}; for _,item in parent:GetDescendants() do snapshot[item]={parent=item.Parent,source=if item:IsA("LuaSourceContainer") then item.Source else nil} end; return snapshot
 end
 local function unchanged(snapshot,parent)
  local current=parent:GetDescendants(); local size=0
  for item,state in snapshot do size+=1; if item.Parent~=state.parent or (state.source and item.Source~=state.source) then return false end end
  return #current==size
 end
 local ok,failure=pcall(function()
  local pairs={}
  for _,kind in {"Melee","Projectile","Melee","Projectile"} do
   local before=commits
   check(install(kind,if #pairs==3 then "Body" else "Mouse"),"AC01 Create paired "..kind)
   check(commits==before+1,"AC05 Pair commits exactly once")
   local latest
   for _,tool in pack:GetChildren() do
    local known=false; for _,pair in pairs do if pair.tool==tool then known=true end end
    if not known then latest=tool end
   end
   check(latest and #latest:GetChildren()==4,"AC01 Four direct Tool children retained")
   local link=latest.Skill:FindFirstChild("Config")
   check(link and link:IsA("ObjectValue") and link.Value and link.Value:IsA("ModuleScript"),"AC02 Nested explicit config reference")
   local target=link.Value
   check(target.Parent==storage.CombatForge.Abilities,"AC01 Shared config exact parent")
   local parsed=assert(Config.parse(target.Source))
   local keys=0; for _ in parsed do keys+=1 end
   check(keys==4 and parsed.Name==target.Name and parsed.Damage==20 and parsed.Cooldown==.75 and parsed.Range==(if kind=="Melee" then 6 else 80),"AC01 Exact four editor-supported default fields")
   for _,pair in pairs do check(pair.target~=target and pair.tool~=latest,"AC02 Mixed/repeated pairs stay distinct") end
   local clone=latest:Clone()
   check(clone.Skill.Config.Value==target,"AC02 Explicit Tool clone retains external shared reference")
   clone:Destroy()
   table.insert(pairs,{tool=latest,target=target,kind=kind})
  end
  check(#storage.CombatForge.Abilities:GetChildren()==4,"AC01 Exactly one config per creation")
  local first=pairs[1]
  local originalAdvanced=first.tool.Skill.Source
  local snapshot=assert(manager.read(first.target))
  check(manager.update(snapshot,{Name="RenamedMelee",Damage="37",Cooldown="0",Range="12"}),"AC03 Update Skills accepts generated config including zero cooldown")
  check(first.tool.Skill.Config.Value==first.target and first.target.Name=="RenamedMelee" and first.tool.Skill.Source==originalAdvanced,"AC02/03 Editor rename preserves link and advanced source")
  check(Config.parse(pairs[3].target.Source).Damage==20,"AC02 Editing one pair leaves other pair unchanged")
  -- Load the actual installer-produced Skill.Source, permitting only explicit
  -- linked config/runtime requires; this executes generated literal source.
  local runtimeStub
  local function load(pair,requireOverride)
   local path="Templates/"..pair.kind.."Skill.luau"
   return module(path,services,function(key)
    if requireOverride then return requireOverride(key) end
    if runtimeStub and storage:FindFirstChild("CombatForge") and storage.CombatForge:FindFirstChild("Runtime") and key==storage.CombatForge.Runtime.Hitbox then return runtimeStub end
    assert(key==pair.target,"Runtime must require own exact config reference")
    local chunk=assert(loadstring(key.Source)); return chunk()
   end,{script=pair.tool.Skill,warn=function(message) table.insert(warnings,message) end},pair.tool.Skill.Source)
  end
  for _,pair in pairs do
   local skill=load(pair)
   local expected=assert(Config.parse(pair.target.Source))
   local settings=assert(skill.GetConfig())
   check(settings.Damage==expected.Damage and settings.Cooldown==expected.Cooldown and settings.Range==expected.Range,"AC03 Actual generated Skill consumes own shared values")
   check(skill.Config.Damage==nil and skill.Config.Cooldown==nil and skill.Config.Range==nil,"AC03 Common settings absent from advanced defaults")
   skill.Config.Damage=999; skill.Config.Cooldown=999; skill.Config.Range=999; skill.Config.HitDelay=.2
   local merged=assert(skill.GetConfig())
   check(merged.Damage==expected.Damage and merged.Cooldown==expected.Cooldown and merged.Range==expected.Range and merged.HitDelay==.2,"AC03 Local shadows cannot override shared values; advanced setting remains")
   if pair.kind=="Projectile" then check(merged.AimMode==(if pair==pairs[4] then "Body" else "Mouse"),"AC01 Baked aim setting retained") end
   local oldName=pair.target.Name; pair.target.Name="ExplorerRename"
   check(skill.GetConfig()~=nil,"AC02 Explorer rename preserves reference identity")
   pair.target.Name=oldName
   local parent=pair.target.Parent
   pair.target.Parent=nil
   local sameName=Instance.new("ModuleScript"); sameName.Name=oldName; sameName.Source=pair.target.Source; sameName.Parent=parent
   check(skill.GetConfig()==nil,"AC04 Detached reference fails closed without same-name substitution")
   sameName:Destroy(); pair.target.Parent=parent
   check(skill.GetConfig()~=nil,"AC04 Restoring exact detached identity restores shared settings")
   pair.target.Parent=storage
   check(skill.GetConfig()==nil,"AC04 Wrong-parent config rejected")
   pair.target.Parent=parent
   local link=pair.tool.Skill.Config
   link.Value=nil; check(skill.GetConfig()==nil,"AC04 Missing config Value fails closed"); link.Value=pair.target
   local wrong=Instance.new("Folder"); wrong.Parent=parent; link.Value=wrong
   check(skill.GetConfig()==nil,"AC04 Wrong-type target fails closed")
   link.Value=pair.target; wrong:Destroy()
   link.Parent=nil; check(skill.GetConfig()==nil,"AC04 Missing link fails closed without waiting")
   local wrongLink=Instance.new("StringValue"); wrongLink.Name="Config"; wrongLink.Parent=pair.tool.Skill
   check(skill.GetConfig()==nil,"AC04 Wrong link class fails closed"); wrongLink:Destroy(); link.Parent=pair.tool.Skill
   local failing=load(pair,function() error("Injected config load failure") end)
   check(failing.GetConfig()==nil,"AC04 Runtime require failure fails closed")
   for _,bad in {false,{Name="Broken",Damage=0/0,Cooldown=0,Range=6},{Name="Broken",Damage=20,Cooldown=-1,Range=6},{Name="Broken",Damage=20,Cooldown=0,Range=0},{Name="Broken",Damage=20,Cooldown=0,Range=math.huge}} do
    local invalid=load(pair,function() return bad end)
    check(invalid.GetConfig()==nil,"AC04 Invalid returned common settings fail closed")
   end
  end
  check(#warnings>0 and warnings[1]:find("Restore",1,true),"AC04 Broken references emit actionable diagnostics")
  -- Combine actual generated Skill and actual Server script. The server receives
  -- no handwritten common-settings substitute; it resolves the updated source.
  local actor=Instance.new("Model"); actor.Name="RuntimeCaster"; actor.Parent=storage
  local actorHum=Instance.new("Humanoid"); actorHum.Parent=actor
  local actorRoot=Instance.new("Part"); actorRoot.Name="HumanoidRootPart"; actorRoot.Anchored=true; actorRoot.Parent=actor
  local enemy=Instance.new("Model"); enemy.Parent=storage
  local enemyHum=Instance.new("Humanoid"); enemyHum.Parent=enemy
  local scans=0
  runtimeStub={Box=function(center,size,options)
   scans+=1
   check(center==actorRoot.CFrame*CFrame.new(0,0,-6) and size==Vector3.new(9,5,12),"AC03 Generated shared Range and local advanced width drive actual Cast")
   check(options.Caster==actor,"AC03 Existing caster protection retained")
   return {Cast=function() return {{Target=enemy,Humanoid=enemyHum},{Target=enemy,Humanoid=enemyHum}} end,Destroy=function() end}
  end}
  local runtimeSkill=load(first)
  runtimeSkill.Config.HitboxWidth=9; runtimeSkill.Config.Damage=999; runtimeSkill.Config.Cooldown=999; runtimeSkill.Config.Range=999
  local callback
  local noopSignal={Connect=function() return {Disconnect=function() end} end}
  local remote={OnServerEvent={Connect=function(_,handler) callback=handler; return {Disconnect=function() callback=nil end} end}}
  local tool={Parent=actor,Enabled=true,Unequipped=noopSignal,AncestryChanged=noopSignal,Destroying=noopSignal,
   WaitForChild=function(_,name) return if name=="Skill" then "Skill" else remote end}
  module("Templates/ToolServer.server.luau",services,{Skill=runtimeSkill},{script={Parent=tool,Destroying=noopSignal},workspace=storage,
   os={clock=function() return 10 end},task={spawn=function(job) job() end,wait=function() error("Default delay must remain zero") end},
  })
  callback({Character=actor}); callback({Character=actor})
  check(scans==2 and enemyHum.Health==26 and actorHum.Health==100,"AC03 Actual generated shared Damage37/Cooldown0 drive two server requests without local shadow authority")
  local activeParent=first.target.Parent; first.target.Parent=nil
  callback({Character=actor})
  check(scans==2 and enemyHum.Health==26,"AC04 Actual Server fails closed on detached shared config")
  first.target.Parent=activeParent
  actor:Destroy(); enemy:Destroy(); runtimeStub=nil
  -- A generated projectile consumes its edited external config in real spatial
  -- queries. Reload source for each simulated new Play; no hot reload claim.
  local projectilePair=pairs[2]
  local projectileSnapshot=assert(manager.read(projectilePair.target))
  check(manager.update(projectileSnapshot,{Name=projectilePair.target.Name,Damage="13",Cooldown="1.25",Range="7"}),"AC03 Editor updates generated projectile common settings")
  spatialWorld=Instance.new("WorldModel"); spatialWorld.Name="CombatForgeSharedConfigSpatialChecks"; spatialWorld.Parent=workspace
  local projectileCaster=Instance.new("Model"); projectileCaster.Parent=spatialWorld
  local projectileRoot=Instance.new("Part"); projectileRoot.Name="HumanoidRootPart"; projectileRoot.Anchored=true; projectileRoot.Position=Vector3.new(0,11000,0); projectileRoot.Parent=projectileCaster
  local projectileTarget=Instance.new("Model"); projectileTarget.Parent=spatialWorld
  local projectileHum=Instance.new("Humanoid"); projectileHum.RequiresNeck=false; projectileHum.Parent=projectileTarget
  local projectilePart=Instance.new("Part"); projectilePart.Anchored=true; projectilePart.Size=Vector3.new(2,2,2); projectilePart.Position=projectileRoot.Position+Vector3.new(0,0,-12); projectilePart.Parent=projectileTarget
  local ticks=0
  local projectileServices=table.clone(services)
  projectileServices.RunService={IsServer=function() return true end,Heartbeat={Wait=function() ticks+=1; assert(ticks<20,"Unbounded shared projectile"); return .1 end}}
  projectileServices.Debris={AddItem=function() end}
  local function castGeneratedProjectile()
   local skill=module("Templates/ProjectileSkill.luau",projectileServices,function(key)
    assert(key==projectilePair.target,"Projectile requires own exact external module")
    return assert(loadstring(key.Source))()
   end,{script=projectilePair.tool.Skill,workspace=spatialWorld},projectilePair.tool.Skill.Source)
   skill.Config.Damage=999; skill.Config.Range=999
   local settings=assert(skill.GetConfig())
   skill.Cast(projectileCaster,projectileRoot.Position+Vector3.new(0,0,-100),function() return true end,settings)
   check(#spatialWorld:GetChildren()==2,"AC03 Generated projectile cleans actual visual")
  end
  castGeneratedProjectile()
  check(ticks==2 and projectileHum.Health==100,"AC03 Generated shared Range7 stops real projectile short of target")
  projectileSnapshot=assert(manager.read(projectilePair.target))
  check(manager.update(projectileSnapshot,{Name=projectilePair.target.Name,Damage="13",Cooldown="1.25",Range="20"}),"AC03 Shared projectile reach editable without regenerating Tool")
  ticks=0; castGeneratedProjectile()
  check(projectileHum.Health==87,"AC03 Next-load generated shared Range20/Damage13 reach and damage actual target")
  spatialWorld:Destroy(); spatialWorld=nil
  -- AbilityManager deletion keeps the exact link; model history restoration by
  -- restoring Parent only, never claim native Ctrl+Z was exercised.
  local parent=first.target.Parent
  check(manager.delete(first.target,first.target.Name) and first.tool.Parent==pack and first.tool.Skill.Config.Value==first.target,"AC04 Delete config preserves Tool and exact reference")
  check(load(first).GetConfig()==nil,"AC04 Deleted generated config disables its Tool settings")
  first.target.Parent=parent
  check(load(first).GetConfig().Damage==37,"AC04 Simulated undo identity restores next-load operation")
  clear()
  local root=folder(storage,"CombatForge"); local abilities=folder(root,"Abilities")
  local occupied=Instance.new("StringValue"); occupied.Name="mElEeSkIlL"; occupied.Parent=abilities
  local occupied2=Instance.new("Folder"); occupied2.Name="MELEESKILL2"; occupied2.Parent=abilities
  check(install("Melee"),"AC02 Case-insensitive occupied config names skipped")
  local generated=pack:GetChildren()[1].Skill.Config.Value
  check(generated.Name=="MeleeSkill3" and occupied.Parent==abilities and occupied2.Parent==abilities,"AC02 Numeric valid identifier avoids objects of every class")
  clear()
  check(install("Projectile"),"AC05 Projectile installs shared config without melee")
  check(storage.CombatForge:FindFirstChild("Runtime")==nil,"AC05 Projectile has no Hitbox dependency")
  clear()
  -- Every path conflict is rejected for both kinds before beginning history.
  for _,kind in {"Melee","Projectile"} do
   for _,conflict in {"rootClass","rootDuplicate","abilitiesClass","abilitiesDuplicate"} do
    clear(); local conflictRoot
    if conflict=="rootClass" then local item=Instance.new("StringValue"); item.Name="CombatForge"; item.Parent=storage
    else conflictRoot=folder(storage,"CombatForge") end
    if conflict=="rootDuplicate" then folder(storage,"CombatForge") end
    if conflict=="abilitiesClass" then local item=Instance.new("StringValue"); item.Name="Abilities"; item.Parent=conflictRoot end
    if conflict=="abilitiesDuplicate" then folder(conflictRoot,"Abilities"); folder(conflictRoot,"Abilities") end
    local old=exactChildren(storage); local oldBegins=begins
    check(not install(kind) and begins==oldBegins and unchanged(old,storage) and #pack:GetChildren()==0,"AC05 "..kind.." preserves conflicting "..conflict)
   end
  end
  for _,kind in {"Melee","Projectile"} do
   for _,partial in {"empty","root","abilities"} do
    clear()
    if partial~="empty" then local r=folder(storage,"CombatForge"); if partial=="abilities" then folder(r,"Abilities") end end
    local marker=Instance.new("StringValue"); marker.Name="Unrelated"; marker.Parent=storage
    local old=exactChildren(storage)
    failCommit=true; local oldCancels=cancels
    check(not install(kind),"AC05 Commit error reported "..kind.."/"..partial)
    check(unchanged(old,storage) and #pack:GetChildren()==0 and cancels==oldCancels+1,"AC05 Only attempt objects rolled back "..kind.."/"..partial)
    failCommit=false
    allow=false; check(not install(kind) and unchanged(old,storage) and #pack:GetChildren()==0,"AC05 No recording no mutation "..kind); allow=true
    failBegin=true; check(not install(kind) and unchanged(old,storage) and #pack:GetChildren()==0,"AC05 Begin exception no mutation "..kind); failBegin=false
    running=true; check(not install(kind) and unchanged(old,storage) and #pack:GetChildren()==0,"AC05 Play blocked "..kind); running=false
   end
  end
 end)
 storage:Destroy(); pack:Destroy(); hitbox:Destroy()
 if spatialWorld then spatialWorld:Destroy() end
 assert(ok,failure)
 return tostring(count).." shared template config assertions passed (generated sources, isolated services/history)"
end
