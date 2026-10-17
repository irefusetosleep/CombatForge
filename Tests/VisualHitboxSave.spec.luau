-- VISUAL-HITBOX-05 AC03/04: checked saves with isolated services/history.
return function(Config,loadManager)
 local count=0
 local function check(value,message) assert(value,message); count+=1 end
 local storage=Instance.new("Folder")
 local root=Instance.new("Folder"); root.Name="CombatForge"; root.Parent=storage
 local abilities=Instance.new("Folder"); abilities.Name="Abilities"; abilities.Parent=root
 local config={Name="VisualMelee",Damage=31,Cooldown=0,Range=6,AnimationId=[[asset -- ; , {} ' " \]],HitDelay=.3,HitboxWidth=5,HitboxHeight=5,HitboxOffsetX=0,HitboxOffsetY=0,HitboxOffsetZ=0}
 local target=Instance.new("ModuleScript"); target.Name=config.Name; target.Source=Config.serialize(config); target.Parent=abilities
 local running,allow,failBegin,failCommit,failEditor,bufferConflict=false,true,false,false,false,false
 local commits,cancels,begins=0,0,0
 local recordedSource,recordedName
 local manager=loadManager({ReplicatedStorage=storage,RunService={IsRunning=function() return running end},
  ScriptEditorService={GetEditorSource=function(_,item) return item.Source end,UpdateSourceAsync=function(_,item,callback)
   if failEditor then error("Injected source API failure") end
   local updated=callback(if bufferConflict then item.Source.."\n-- editor changed" else item.Source)
   if updated then item.Source=updated end
  end},
  ChangeHistoryService={TryBeginRecording=function()
   begins+=1; if failBegin then error("Injected begin failure") end; if not allow then return nil end
   recordedSource=target.Source; recordedName=target.Name; return "geometry-recording"
  end,FinishRecording=function(_,id,operation)
   assert(id=="geometry-recording")
   if operation==Enum.FinishRecordingOperation.Commit then if failCommit then error("Injected commit failure") end; commits+=1
   else cancels+=1; target.Source=recordedSource; target.Name=recordedName end
  end},
 })
 local geometry={HitboxWidth=9,HitboxHeight=4,Range=12,HitboxOffsetX=3,HitboxOffsetY=-2,HitboxOffsetZ=5,HitboxRotationX=31,HitboxRotationY=-47,HitboxRotationZ=19}
 local ok,failure=pcall(function()
  local snapshot=assert(manager.read(target))
  check(manager.saveGeometry(snapshot,geometry),"AC03 Save complete visual geometry")
  check(commits==1 and target.Parent==abilities,"AC03 One recording preserves exact module identity")
  local parsed=assert(Config.parse(target.Source))
  for key,value in geometry do check(parsed[key]==value,"AC03 Saved geometry "..key) end
  for _,key in {"Name","Damage","Cooldown","AnimationId","HitDelay"} do check(parsed[key]==config[key],"AC03 Preserve nongeometry "..key) end
  local after=target.Source
  check(not manager.saveGeometry(snapshot,geometry) and target.Source==after,"AC03 Stale source blocked")
  snapshot=assert(manager.read(target)); target.Name="ExplorerRename"
  check(not manager.saveGeometry(snapshot,geometry) and target.Source==after,"AC03 Stale name blocked"); target.Name=config.Name
  snapshot=assert(manager.read(target)); target.Parent=storage
  check(not manager.saveGeometry(snapshot,geometry) and target.Source==after,"AC03 Moved target blocked"); target.Parent=abilities
  snapshot=assert(manager.read(target)); target.Parent=nil
  check(not manager.saveGeometry(snapshot,geometry) and target.Source==after,"AC03 Detached target blocked"); target.Parent=abilities
  for _,bad in {0,-1,0/0,math.huge} do
   local draft=table.clone(geometry); draft.HitboxWidth=bad
   local oldBegins=begins
   check(not manager.saveGeometry(assert(manager.read(target)),draft) and target.Source==after and begins==oldBegins,"AC03 Invalid draft rejected before history")
  end
  local partial=table.clone(geometry); partial.HitboxOffsetY=nil
  check(not manager.saveGeometry(assert(manager.read(target)),partial) and target.Source==after,"AC03 Partial geometry draft refused")
  local partialRotation=table.clone(geometry); partialRotation.HitboxRotationY=nil
  check(not manager.saveGeometry(assert(manager.read(target)),partialRotation) and target.Source==after,"AC04 Partial rotation geometry refused")
  for _,bad in {0/0,math.huge,-math.huge} do
   local invalid=table.clone(geometry); invalid.HitboxRotationZ=bad
   check(not manager.saveGeometry(assert(manager.read(target)),invalid) and target.Source==after,"AC04 Nonfinite rotation save rejected")
  end
  local injected=table.clone(geometry); injected.Name="OverwriteName"; injected.Damage=999
  manager.saveGeometry(assert(manager.read(target)),injected)
  parsed=assert(Config.parse(target.Source))
  check(parsed.Name==config.Name and parsed.Damage==31,"AC03 Geometry API cannot change other fields")
  after=target.Source
  running=true; local oldBegins=begins
  check(not manager.saveGeometry(assert(manager.read(target)),geometry) and target.Source==after and begins==oldBegins,"AC03 Play mode has no mutation/history"); running=false
  allow=false; check(not manager.saveGeometry(assert(manager.read(target)),geometry) and target.Source==after,"AC03 Missing recording refuses mutation"); allow=true
  failBegin=true; check(not manager.saveGeometry(assert(manager.read(target)),geometry) and target.Source==after,"AC03 Begin error refuses mutation"); failBegin=false
  for _,mode in {"commit","editor","buffer"} do
   local oldCancels=cancels
   failCommit=mode=="commit"; failEditor=mode=="editor"; bufferConflict=mode=="buffer"
   local changed=table.clone(geometry); changed.HitboxWidth=10
   check(not manager.saveGeometry(assert(manager.read(target)),changed),"AC03 Failed save reported "..mode)
   check(target.Source==after and cancels==oldCancels+1,"AC03 Failed save cancels recording and preserves source "..mode)
   failCommit=false; failEditor=false; bufferConflict=false
  end
  check(manager.update(assert(manager.read(target)),{Name="CommonRename",Damage="40",Cooldown="1",Range="14"}),"AC04 Common editor remains usable after visual saves")
  parsed=assert(Config.parse(target.Source))
  for _,key in {"HitboxWidth","HitboxHeight","HitboxOffsetX","HitboxOffsetY","HitboxOffsetZ","HitboxRotationX","HitboxRotationY","HitboxRotationZ"} do check(parsed[key]==geometry[key],"AC04 Common save preserves geometry "..key) end
  local tiny=table.clone(geometry); tiny.HitboxWidth=.001
  check(manager.saveGeometry(assert(manager.read(target)),tiny),"AC02 Parser/save retain valid dimensions below handle minimum")
  target.Source="error('never execute during save')"; local unsupported=target.Source
  check(manager.read(target)==nil and not manager.saveGeometry(snapshot,geometry) and target.Source==unsupported,"AC01 Custom source never executed or rewritten")
 end)
 storage:Destroy(); if target.Parent==nil then target:Destroy() end
 assert(ok,failure)
 return tostring(count).." visual hitbox save assertions passed (isolated checked source/history)"
end
