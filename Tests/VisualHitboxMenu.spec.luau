-- Real UI callbacks with an injected preview capability; native handles separate.
return function(UI,actions,Config)
 local count=0
 local function check(value,message) assert(value,message); count+=1 end
 local host=Instance.new("ScreenGui"); host.Enabled=true
 local target=Instance.new("ModuleScript"); target.Name="MenuMelee"
 local data={Name=target.Name,Damage=20,Cooldown=.75,Range=6,AnimationId="",HitDelay=0,HitboxWidth=5,HitboxHeight=5}
 local reads,saves,starts,destroys=0,0,0,0
 local saveMode="fail"
 local lastSnapshot,lastSaved,lastMode
 local draft={HitboxWidth=9,HitboxHeight=7,Range=12,HitboxOffsetX=2,HitboxOffsetY=-1,HitboxOffsetZ=3}
 local alive=false
 local manager={list=function() return {target},nil end,read=function()
  reads+=1; return {module=target,name=target.Name,source=Config.serialize(data),config=table.clone(data)},nil
 end,saveGeometry=function(snapshot,geometry)
  saves+=1; lastSnapshot=snapshot; lastSaved=geometry
  if saveMode=="throw" then error("Injected save exception") end
  if saveMode=="fail" then return false,"Skill changed; reopen." end
  for key,value in geometry do data[key]=value end
  return true,"Saved visual geometry."
 end}
 local function destroy()
  if alive then alive=false; destroys+=1 end
 end
 local startMode="success"
 local capability={isSupported=Config.isMelee,start=function(config,onChanged)
  starts+=1
  if startMode=="failure" then return nil,"Select one valid dummy." end
  check(config.Name==data.Name,"AC01 Preview receives selected config")
  alive=true
  onChanged(table.clone(draft))
  return {getDraft=function() return table.clone(draft) end,setMode=function(mode) lastMode=mode end,destroy=destroy},"Draft preview ready."
 end}
 local ok,failure=pcall(function()
  UI.mount(host,manager,nil,nil,nil,nil,nil,capability)
  local root=host.CombatForgeRoot
  actions.UpdateSkills(); actions.Skill1()
  check(root.EditHitbox.Text=="Edit Hitbox","AC01 Eligible config exposes visual entry")
  actions.EditHitbox()
  check(root.Heading.Text=="Edit Hitbox: MenuMelee" and root.HitboxInstructions.Text:find("studs",1,true),"AC01 Selected ability/instructions shown")
  actions.SaveHitbox(); check(saves==0 and root.HitboxStatus.Text:find("Start Preview",1,true),"AC03 Save cannot run before preview")
  actions.HitboxMove(); check(lastMode==nil,"AC02 Mode guarded before preview")
  startMode="failure"; actions.StartHitboxPreview()
  check(root.HitboxStatus.Text=="Select one valid dummy." and not alive,"AC01 Invalid selection guidance")
  startMode="success"; actions.StartHitboxPreview()
  check(alive and root.HitboxReadout.Text:find("9 x 7 x 12",1,true) and root.HitboxReadout.Text:find("X 2",1,true),"AC02 Current draft dimensions/local offsets displayed")
  actions.HitboxResize(); check(lastMode=="Resize","AC02 Resize dispatch")
  actions.HitboxMove(); check(lastMode=="Move","AC02 Move dispatch")
  actions.SaveHitbox()
  check(saves==1 and alive and root.HitboxStatus.Text=="Skill changed; reopen.","AC03 Save failure preserves draft with error")
  check(lastSnapshot.module==target and lastSaved.HitboxWidth==9 and lastSaved.HitboxOffsetZ==3,"AC03 Save uses exact snapshot and draft")
  saveMode="throw"; actions.SaveHitbox()
  check(alive and root.HitboxStatus.Text:find("Injected save exception",1,true),"AC03 Thrown save failure remains visible")
  local beforeReads=reads
  saveMode="success"; actions.SaveHitbox()
  check(not alive and destroys==1 and reads==beforeReads+1,"AC03 Successful Save closes session and reloads snapshot")
  check(root.RangeInput.Text=="12" and root.Status.Text=="Saved visual geometry.","AC03 Returns to refreshed common editor with success")
  actions.EditHitbox(); actions.StartHitboxPreview(); local beforeSaves=saves
  actions.CancelHitbox()
  check(not alive and destroys==2 and saves==beforeSaves and root.EditHitbox~=nil,"AC05 Cancel ends preview without saving")
  actions.EditHitbox(); actions.StartHitboxPreview(); host.Enabled=false; task.wait()
  check(not alive and destroys==3,"AC05 Widget closure ends preview")
  host.Enabled=true; actions.StartHitboxPreview()
  local beforeDestroy=destroys
  root:Destroy()
  task.wait() -- Studio may dispatch Destroying with deferred signal behavior.
  check(not alive and destroys==beforeDestroy+1,"AC05 Root/UI destruction ends preview")
  -- A fresh mounted view refuses unsupported projectile/mixed settings.
  data.ProjectileSpeed=60
  UI.mount(host,manager,nil,nil,nil,nil,nil,capability)
  root=host.CombatForgeRoot
  actions.UpdateSkills(); actions.Skill1()
  check(root:FindFirstChild("EditHitbox")==nil and root.HitboxHelp.Text:find("not supported",1,true),"AC01 Unsupported config receives guidance without entry")
 end)
 destroy(); host:Destroy(); target:Destroy()
 assert(ok,failure)
 return tostring(count).." visual hitbox UI assertions passed (actual UI callbacks; injected preview capability)"
end
