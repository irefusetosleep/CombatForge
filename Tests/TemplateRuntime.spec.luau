-- Deterministic service/signal doubles verify actual source logic, not live input,
-- Roblox physics, animation asset access, or native Studio undo integration.
return function(module)
 local count = 0
 local function check(value, message) assert(value, message); count += 1 end
 local function signal()
  local listeners = {}
  return {Connect=function(_, callback)
   local entry={active=true, callback=callback}; table.insert(listeners,entry)
   return {Disconnect=function() entry.active=false end}
  end, Fire=function(_, ...)
   for _, entry in listeners do if entry.active then entry.callback(...) end end
  end}
 end
 -- Server authorization and delayed revalidation use the actual Server source.
 local now, casts, waits, animations, destroyedAnimations = 10, 0, 0, 0, 0
 local jobs = {}
 local delayed, tracks = {}, {}
 local animationFails = true
 local world = {}
 local root = {Parent=nil, IsA=function(_,class) return class=="BasePart" end}
 local humanoid = {Health=100, Parent=nil, Died=signal(), FindFirstChildOfClass=function() return {LoadAnimation=function()
  if animationFails then error("Injected asset failure") end
  local track={Ended=signal(), plays=0, stops=0, destroys=0}
  function track:Play() self.plays+=1 end
  function track:Stop() self.stops+=1 end
  function track:Destroy() self.destroys+=1 end
  table.insert(tracks,track); return track
 end} end}
 local hasRoot=true
 local caster = {FindFirstChildOfClass=function() return humanoid end, FindFirstChild=function() return if hasRoot then root else nil end, IsDescendantOf=function(_, parent) return parent==world end}
 humanoid.Parent=caster; root.Parent=caster
 local remote={OnServerEvent=signal()}
 local tool={Parent=caster, Enabled=true, Unequipped=signal(), AncestryChanged=signal(), Destroying=signal(), WaitForChild=function(_,name) return name=="Skill" and "Skill" or remote end}
 local scriptObject={Parent=tool, Destroying=signal()}
 local shared={Damage=20,Cooldown=.75,Range=6}
 local config={HitDelay=0, AnimationId=""}
 local retrieved,validated,castConfigs={},{},{}
 local lastDelay
 local skill={GetConfig=function()
  local result=table.clone(config); for key,value in shared do result[key]=value end
  retrieved[result]=true; return result
 end, Validate=function(settings)
  check(retrieved[settings],"ALL-CONFIG AC04 Validate receives the obtained per-activation config")
  validated[settings]=true; return true
 end, Cast=function(_, _, valid,settings)
  check(valid(),"AC04 Cast receives current authorization")
  check(validated[settings],"ALL-CONFIG AC04 Cast receives the same validated config")
  table.insert(castConfigs,settings); casts+=1
 end}
 module("Templates/ToolServer.server.luau", {}, {Skill=skill}, {
  script=scriptObject, workspace=world, os={clock=function() return now end},
  task={spawn=function(callback) table.insert(jobs,callback) end, wait=function(delay) waits+=1; lastDelay=delay; check(type(delay)=="number" and delay>=0,"AC03 Finite configured delay") end,
   delay=function(seconds,callback) check(seconds>0 and seconds<math.huge,"AC03 Bounded animation cleanup"); table.insert(delayed,callback) end},
  Instance={new=function(class)
   assert(class=="Animation", "Unexpected animation fixture class")
   animations+=1; return {Destroy=function() destroyedAnimations+=1 end}
  end}, warn=function() end,
 })
 local player={Character=caster}
 local function fire(aim) remote.OnServerEvent:Fire(player,aim) end
 local function drain() local pending=jobs; jobs={}; for _, callback in pending do callback() end end
 fire(); drain()
 check(casts==1 and animations==0 and waits==0,"AC03 Blank animation attacks without setup or delay")
 fire(); drain(); check(casts==1,"AC04 Cooldown rejects repeat")
 now+=1; tool.Enabled=false; fire(); tool.Enabled=true
 player.Character={}; fire(); player.Character=caster
 humanoid.Health=0; fire(); humanoid.Health=100
 hasRoot=false; fire(); hasRoot=true
 drain(); check(casts==1,"AC04 Disabled/unauthorized/dead/missing-root requests do not cast")
 now+=1; shared.Damage=0/0; fire(); shared.Damage=20
 shared.Range=math.huge; fire(); shared.Range=6
 shared.Cooldown=-1; fire(); shared.Cooldown=.75
 config.AimMode="Mouse"
 for _, aim in {"wrong", Vector3.new(0/0,0,0), Vector3.new(math.huge,0,0)} do fire(aim) end
 drain(); check(casts==1,"AC04/05 Nonfinite settings and malformed aim rejected")
 fire(Vector3.new(10,0,0)); drain(); check(casts==2,"AC05 Invalid requests do not block later valid input")
 now+=1; config.AimMode=nil; config.HitDelay=.1
 fire(); tool.Unequipped:Fire(); drain()
 check(casts==2 and waits==1 and lastDelay==.1,"AC04 Unequip invalidates delayed activation after configured wait")
 now+=1; fire(); humanoid.Health=0; drain(); humanoid.Health=100
 check(casts==2,"AC04 Death invalidates delayed activation")
 now+=1; fire(); player.Character={}; drain(); player.Character=caster
 check(casts==2,"AC04 Character replacement invalidates delayed activation")
 now+=1; config.AnimationId="rbxassetid://1"; fire(); drain()
 check(casts==3 and animations==1 and destroyedAnimations==1,"AC03 Animation failure still attacks and destroys transient animation")
 animationFails=false; config.HitDelay=0; now+=1; fire(); drain()
 check(casts==4 and tracks[1].plays==1 and tracks[1].stops==0 and tracks[1].destroys==0,"AC03 Instant melee hit does not truncate animation")
 tracks[1].Ended:Fire()
 check(tracks[1].stops==1 and tracks[1].destroys==1,"AC03 Natural animation completion releases track")
 now+=1; fire(); drain(); humanoid.Died:Fire()
 check(tracks[2].destroys==1,"AC03 Death cleans playing animation")
 now+=1; fire(); drain(); tool.Unequipped:Fire()
 check(tracks[3].destroys==1,"AC03 Unequip cleans playing animation")
 now+=1; fire(); drain(); delayed[#delayed]()
 check(tracks[4].destroys==1,"AC03 Fallback cleans animation if completion never arrives")
 shared.Cooldown=0; config.AnimationId=""; now+=1
 local beforeZero=casts
 fire(); fire(); drain()
 check(casts==beforeZero+2,"TEMPLATE-CONFIGS AC03 Zero shared cooldown permits consecutive activations")
 shared.Cooldown=.75; config.HitDelay=.3; now+=1
 fire(); shared.Damage=88; config.HitDelay=2; drain()
 check(lastDelay==.3 and castConfigs[#castConfigs].Damage==20 and castConfigs[#castConfigs].HitDelay==.3,"ALL-CONFIG AC04 Delayed work uses captured scalar settings")
 shared.Damage=20; config.HitDelay=0; config.AnimationId="rbxassetid://1"
 local beforeDestroyCasts=casts
 now+=1; fire(); tool.Destroying:Fire(); drain(); now+=1; fire(); drain()
 check(casts==beforeDestroyCasts and tracks[5].destroys==1,"AC04 Tool teardown cancels pending, cleans animation and disconnects future requests")

 local sent={}
 local input=signal()
 local clientRemote={FireServer=function(_,...) table.insert(sent,table.pack(...)) end}
 local clientTool={Enabled=true, Activated=input, WaitForChild=function(_,name) return name=="Skill" and "Skill" or clientRemote end}
 local clientScript={Parent=clientTool, Destroying=signal()}
 local clientConfig={AimMode="Mouse"}
 local mouse={Hit=CFrame.new(30,4,8)}
 module("Templates/ToolClient.client.luau", {Players={LocalPlayer={GetMouse=function() return mouse end}}}, {Skill={GetConfig=function() return table.clone(clientConfig) end,Validate=function(config) return config.AimMode=="Mouse" or config.AimMode=="Body" end}}, {script=clientScript})
 input:Fire()
 check(#sent==1 and sent[1].n==1 and sent[1][1]==mouse.Hit.Position,"AC03/05 Mouse input sends only aim point")
 clientConfig.AimMode="Body"; input:Fire()
 check(#sent==2 and sent[2].n==0,"AC05 Body input sends no client origin/damage/target")
 clientTool.Enabled=false; input:Fire()
 check(#sent==2,"AC03 Disabled Tool input ignored")
 clientTool.Enabled=true; clientScript.Destroying:Fire(); input:Fire()
 check(#sent==2,"AC03 Client teardown disconnects input")

 local casterModel, victim, dead = Instance.new("Model"), Instance.new("Model"), Instance.new("Model")
 local rootPart=Instance.new("Part"); rootPart.Name="HumanoidRootPart"; rootPart.CFrame=CFrame.new(4,2,3); rootPart.Parent=casterModel
 local selfHum=Instance.new("Humanoid"); selfHum.Parent=casterModel
 local targetHum=Instance.new("Humanoid"); targetHum.Parent=victim
 local deadHum=Instance.new("Humanoid"); deadHum.Health=0; deadHum.Parent=dead
 local victimPart=Instance.new("Part"); victimPart.Parent=victim
 local ok, failure = pcall(function()
  local cleaned, scans=0,0
  local hitbox={Box=function(center,size,options)
   scans+=1
   check(center==rootPart.CFrame*CFrame.new(0,0,-3) and size==Vector3.new(5,5,6),"AC04 Server default forward geometry")
   check(options.Caster==casterModel,"AC04 Caster filter supplied")
   return {Cast=function() return {{Target=victim,Humanoid=targetHum},{Target=victim,Humanoid=targetHum},{Target=casterModel,Humanoid=selfHum},{Target=dead,Humanoid=deadHum}} end, Destroy=function() cleaned+=1 end}
  end}
  local path={WaitForChild=function(self) return self end}
  local melee,meleeShared=module("Templates/MeleeSkill.luau", {RunService={IsServer=function() return true end}, ReplicatedStorage=path}, {[path]=hitbox})
  melee.Cast(casterModel,nil,function() return true end, melee.GetConfig())
  check(targetHum.Health==80 and selfHum.Health==100 and deadHum.Health==0,"AC04 Living targets damaged once; self/dead excluded")
  check(cleaned==1,"AC04 Detector destroyed after scan")
  melee.Cast(casterModel,nil,function() return false end, melee.GetConfig())
  check(scans==1,"AC04 Invalidated activation skips scan")
  meleeShared.HitboxWidth=0/0; check(not melee.Validate(meleeShared),"AC04 Invalid shared geometry rejected")

  -- Projectile geometry is actual Vector3/CFrame math; deterministic world double
  -- records swept segments and supplies controlled initial/impact results.
  local sweep, visuals, removed, steps= {}, {}, 0, 0
  local initial, hit, invalidateAfterWait, queryFails = {}, nil, false, false
  local valid = true
  local fakeWorld={GetPartsInPart=function() if queryFails then error("Injected overlap failure") end; return initial end, Spherecast=function(_, origin,radius,delta,params)
   table.insert(sweep,{origin=origin,delta=delta})
   check(params.FilterDescendantsInstances[1]==casterModel,"AC05 Swept query excludes caster")
   return hit
  end}
  local projectile,projectileShared=module("Templates/ProjectileSkill.luau", {
   RunService={IsServer=function() return true end, Heartbeat={Wait=function() steps+=1; assert(steps<50,"Unbounded projectile"); if invalidateAfterWait then valid=false end; return .1 end}},
   Debris={AddItem=function(_,_,lifetime) check(lifetime>0 and lifetime<math.huge,"AC05 Finite fallback cleanup") end},
  }, nil, {workspace=fakeWorld,
   RaycastParams={new=function() return {} end}, OverlapParams={new=function() return {} end},
   Instance={new=function(class)
    assert(class=="Part"); local visual={Destroy=function() removed+=1 end}; table.insert(visuals,visual); return visual
   end},
  })
  local function reset() sweep={}; steps=0; valid=true; initial={}; hit=nil; invalidateAfterWait=false; queryFails=false end
  projectileShared.AimMode="Body"; projectileShared.Range=10
  projectile.Cast(casterModel, Vector3.new(999,0,0),function() return valid end, projectile.GetConfig())
  check(#sweep==2 and sweep[1].origin==rootPart.Position,"AC05 Body origin is server root")
  check(sweep[1].delta.Unit==rootPart.CFrame.LookVector and math.abs(sweep[1].delta.Magnitude+sweep[2].delta.Magnitude-10)<.001,"AC05 Body direction ignores client and stops at range")
  check(removed==#visuals,"AC05 Range completion destroys visual")
  reset(); projectileShared.AimMode="Mouse"
  projectile.Cast(casterModel,rootPart.Position+Vector3.new(100,0,0),function() return true end, projectile.GetConfig())
  check(sweep[1].delta.Unit==Vector3.xAxis,"AC05 Mouse aim computes direction from server origin")
  reset(); local before=#visuals
  projectile.Cast(casterModel,rootPart.Position,function() return true end, projectile.GetConfig())
  check(#visuals==before and #sweep==0,"AC05 Degenerate mouse aim safe without resources")
  reset(); hit={Instance=victimPart,Position=rootPart.Position+Vector3.new(2,0,0)}
  projectile.Cast(casterModel,rootPart.Position+Vector3.xAxis*100,function() return true end, projectile.GetConfig())
  check(#sweep==1 and targetHum.Health==60,"AC05 First swept impact damages once and terminates")
  reset(); hit={Instance=rootPart,Position=rootPart.Position}
  projectile.Cast(casterModel,rootPart.Position+Vector3.xAxis*100,function() return true end, projectile.GetConfig())
  check(#sweep==1 and selfHum.Health==100,"AC05 Caster cannot receive projectile damage")
  reset(); hit={Instance=Instance.new("Part"),Position=rootPart.Position+Vector3.xAxis}
  local wall=hit.Instance
  projectile.Cast(casterModel,rootPart.Position+Vector3.xAxis*100,function() return true end, projectile.GetConfig())
  wall:Destroy()
  check(#sweep==1 and targetHum.Health==60,"AC05 World collision terminates without target damage")
  reset(); initial={victimPart}
  projectile.Cast(casterModel,rootPart.Position+Vector3.xAxis*100,function() return true end, projectile.GetConfig())
  check(#sweep==0 and targetHum.Health==40,"AC05 Initial overlap cannot tunnel past target")
  reset(); invalidateAfterWait=true
  projectile.Cast(casterModel,rootPart.Position+Vector3.xAxis*100,function() return valid end, projectile.GetConfig())
  check(#sweep==0 and removed==#visuals,"AC05 Teardown before travel prevents query and cleans visual")
  reset(); projectileShared.Range=1000; projectileShared.ProjectileLifetime=.15
  projectile.Cast(casterModel,rootPart.Position+Vector3.xAxis*100,function() return true end, projectile.GetConfig())
  local distance=0; for _, segment in sweep do distance+=segment.delta.Magnitude end
  check(steps==2 and math.abs(distance-9)<.001,"AC05 Lifetime caps final segment travel")
  reset(); queryFails=true
  check(not pcall(projectile.Cast,casterModel,rootPart.Position+Vector3.xAxis*100,function() return true end, projectile.GetConfig()) and removed==#visuals,"AC05 Query failure cleans visual before propagation")
  projectileShared.ProjectileSpeed=math.huge; check(not projectile.Validate(projectileShared),"AC05 Infinite shared speed rejected")
 end)
 casterModel:Destroy(); victim:Destroy(); dead:Destroy()
 assert(ok,failure)
 return tostring(count).." template runtime assertions passed (injected server, hitbox and projectile world)"
end
