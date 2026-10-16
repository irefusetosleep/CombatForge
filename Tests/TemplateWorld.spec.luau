-- Real Roblox WorldModel spatial queries and Parts/Humanoids, with injected
-- server identity and deterministic Heartbeat. Does not exercise live Tool input,
-- multiplayer transport, animation assets or native Studio undo/redo.
return function(module)
 local count = 0
 local function check(value,message) assert(value,message); count+=1 end
 local world=Instance.new("WorldModel")
 world.Name="CombatForgeTemplateSpatialChecks"
 world.Parent=workspace
 local base=Vector3.new(0,10000,0)
 local function character(name, offset, extraPart)
  local model=Instance.new("Model"); model.Name=name
  local humanoid=Instance.new("Humanoid")
  humanoid.RequiresNeck=false; humanoid.BreakJointsOnDeath=false; humanoid.Parent=model
  local root=Instance.new("Part"); root.Name="HumanoidRootPart"
  root.Anchored=true; root.Size=Vector3.new(2,2,2); root.Position=base+offset; root.Parent=model
  if extraPart then
   local part=root:Clone(); part.Name="SecondBodyPart"; part.Position+=Vector3.new(0,.5,0); part.Parent=model
  end
  model.Parent=world
  return model,humanoid,root
 end
 local function noVisuals()
  for _, item in world:GetDescendants() do if item.Name=="CombatForgeProjectile" then return false end end
  return true
 end
 local ok,failure=pcall(function()
  local hitbox=module("Runtime/Hitbox.luau",nil,nil,{workspace=world})
  local path={WaitForChild=function(self) return self end}
  local melee=module("Templates/MeleeSkill.luau",{RunService={IsServer=function() return true end},ReplicatedStorage=path},{[path]=hitbox},{workspace=world})
  local caster,selfHum=character("Caster",Vector3.zero)
  local _,front=character("Front",Vector3.new(0,0,-4),true)
  local _,rear=character("Rear",Vector3.new(0,0,4))
  local _,distant=character("Distant",Vector3.new(0,0,-20))
  melee.Cast(caster,nil,function() return true end,melee.GetConfig())
  check(front.Health==80,"AC04 Actual melee spatial query damages front target once across multiple parts")
  check(selfHum.Health==100 and rear.Health==100 and distant.Health==100,"AC04 Actual melee query excludes caster/rear/distant")

  local function projectileCase(mode, setup, options)
   world:ClearAllChildren()
   local actor,actorHum,actorRoot=character("Caster",Vector3.zero)
   local targetHum,aim=setup(actorRoot)
   local ticks=0
   local valid=true
   local skill,shared=module("Templates/ProjectileSkill.luau",{
    RunService={IsServer=function() return true end,Heartbeat={Wait=function()
     ticks+=1; assert(ticks<100,"Projectile failed to terminate")
     if options and options.invalidate then valid=false end
     return .1
    end}},
    Debris={AddItem=function(_,visual,lifetime)
     check(visual:IsA("Part") and lifetime>0 and lifetime<math.huge,"AC05 Real projectile has bounded fallback cleanup")
    end},
   },nil,{workspace=world})
   shared.AimMode=mode
   if options then
    if options.range then shared.Range=options.range end
    if options.lifetime then shared.ProjectileLifetime=options.lifetime end
   end
   skill.Cast(actor,aim,function() return valid end,skill.GetConfig())
   check(noVisuals(),"AC05 Actual projectile Part cleaned after completion")
   check(actorHum.Health==100,"AC05 Actual projectile query excludes caster")
   return targetHum,ticks
  end
  local body=projectileCase("Body",function()
   local _,hum=character("BodyTarget",Vector3.new(0,0,-15),true)
   return hum,base+Vector3.new(100,0,0)
  end)
  check(body.Health==80,"AC05 Body projectile uses actual forward swept query and ignores other client aim")
  local mouse=projectileCase("Mouse",function()
   local _,hum=character("MouseTarget",Vector3.new(15,0,0),true)
   return hum,base+Vector3.new(100,0,0)
  end)
  check(mouse.Health==80,"AC05 Mouse projectile actual swept query hits selected direction once")
  local blocked=projectileCase("Body",function()
   local _,hum=character("BehindWall",Vector3.new(0,0,-15))
   local wall=Instance.new("Part"); wall.Name="ThinWall"; wall.Anchored=true
   wall.Size=Vector3.new(12,12,.2); wall.Position=base+Vector3.new(0,0,-5); wall.Parent=world
   return hum,nil
  end)
  check(blocked.Health==100,"AC05 Actual swept query stops at thin world wall before target")
  local overlap,ticks=projectileCase("Body",function()
   local _,hum=character("InitialOverlap",Vector3.zero)
   return hum,nil
  end)
  check(overlap.Health==80 and ticks==0,"AC05 Actual initial-overlap query detects contact before travel")
  local ranged,rangeTicks=projectileCase("Body",function()
   local _,hum=character("BeyondRange",Vector3.new(0,0,-15))
   return hum,nil
  end,{range=5})
  check(ranged.Health==100 and rangeTicks==1,"AC05 Actual projectile range ends before distant target")
  local expired,lifetimeTicks=projectileCase("Body",function()
   local _,hum=character("BeyondLifetime",Vector3.new(0,0,-15))
   return hum,nil
  end,{lifetime=.05})
  check(expired.Health==100 and lifetimeTicks==1,"AC05 Lifetime ends flight with actual query/visual cleanup")
  local cancelled,cancelTicks=projectileCase("Body",function()
   local _,hum=character("AfterTeardown",Vector3.new(0,0,-4))
   return hum,nil
  end,{invalidate=true})
  check(cancelled.Health==100 and cancelTicks==1,"AC05 Teardown before first step prevents damage and destroys actual Part")
 end)
 world:Destroy()
 assert(ok,failure)
 return tostring(count).." template spatial assertions passed (real WorldModel queries; injected clock/Heartbeat)"
end
