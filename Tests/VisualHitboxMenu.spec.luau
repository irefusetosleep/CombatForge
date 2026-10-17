-- Actual UI callbacks; retained draft controller and input state injected.
return function(UI,actions,Config,guards)
 local count=0
 local function check(value,message) assert(value,message); count+=1 end
 local black=Color3.fromRGB(30,33,40) -- inactive theme surface; palette test separately uses injected themes
 local host=Instance.new("ScreenGui"); host.Enabled=true
 local target=Instance.new("ModuleScript"); target.Name="MenuMelee"
 local data={Name=target.Name,Damage=20.123456789,Cooldown=.750123456,Range=6.987654321,AnimationId="",HitDelay=0,HitboxWidth=5,HitboxHeight=5}
 local reads,saves,starts,destroys=0,0,0,0
 local saveMode="fail"
 local lastSnapshot,lastSaved,lastInputs
 local controller,changed,stateChanged,stopped
 local draft={HitboxWidth=9.123456789,HitboxHeight=7,Range=12.987654321,HitboxOffsetX=-.00001,HitboxOffsetY=-1.234567,HitboxOffsetZ=3,HitboxRotationX=31.456789,HitboxRotationY=-47,HitboxRotationZ=19}
 local state={visible=true,mode="Preview",scaleMode="Axis",canUndo=false}
 local function notify() if changed then changed(table.clone(draft)) end; if stateChanged then stateChanged(table.clone(state)) end end
 local manager={list=function() return {target},nil end,read=function()
  reads+=1; return {module=target,name=target.Name,source=Config.serialize(data),config=table.clone(data)},nil
 end,update=function(_,inputs) lastInputs=inputs; return false,"Injected ordinary save error" end,
 saveGeometry=function(snapshot,geometry)
  saves+=1; lastSnapshot=snapshot; lastSaved=geometry
  if guards and guards.duringSave then guards.duringSave() end
  if saveMode=="throw" then error("Injected save exception") end
  if saveMode=="fail" then return false,"Skill changed; reopen." end
  for key,value in geometry do data[key]=value end
  return true,"Saved visual geometry."
 end}
 local selectionValid=true
 local capability={isSupported=Config.isMelee,start=function(config,onChanged,onStopped,onStateChanged)
  starts+=1
  check(config.Name==data.Name,"AC01 Controller receives selected config")
  changed=onChanged; stateChanged=onStateChanged; stopped=onStopped
  state={visible=selectionValid,mode="Preview",scaleMode="Axis",canUndo=false}
  local ended=false
  controller={getDraft=function() return table.clone(draft) end,getState=function() return table.clone(state) end,
   setPreviewVisible=function(value)
    if ended then return false end
    if value and not selectionValid then return false,"Select one valid dummy." end
    state.visible=value; state.mode="Preview"; notify()
    if not value then onStopped("Preview Ended") end
    return true
   end,
   setMode=function(mode) state.mode=mode; notify(); return true end,
   setShiftHeld=function(value) state.shiftHeld=value; state.space=if value then "Global" else "Local";state.scaleMode=if value then "Uniform" else "Axis";notify();return true end,
   setScaleMode=function(mode) state.scaleMode=mode; notify(); return true end,
   undo=function() if not state.canUndo then return false end; state.canUndo=false; draft.HitboxWidth=8.123456789; notify(); return true end,
   destroy=function() if not ended then ended=true; destroys+=1; state.visible=false end end}
  notify()
  return controller,if selectionValid then "Draft preview ready." else "Select one valid dummy."
 end}
 local mounted
 local ok,failure=pcall(function()
  mounted=UI.mount(host,manager,nil,nil,nil,nil,capability)
  local root=host.CombatForgeRoot
  check(type(mounted)=="table" and type(mounted.invoke)=="function","AC05 UI exposes shared shortcut dispatcher")
  check(not mounted.invoke("Move"),"AC05 Shortcut inert outside hitbox page")
  actions.UpdateSkills(); actions.Skill1()
  check(root.DamageInput.Text=="20.123" and root.CooldownInput.Text=="0.750" and root.RangeInput.Text=="6.988","AC04 Common numeric controls show exactly three decimals")
  root.NameInput.Text="RenamedOnly"; task.wait(); actions.SaveChanges()
  check(tonumber(lastInputs.Damage)==data.Damage and tonumber(lastInputs.Cooldown)==data.Cooldown and tonumber(lastInputs.Range)==data.Range,"AC04 Unchanged rounded numeric fields retain exact original precision")
  root.NameInput.Text=data.Name; task.wait()
  actions.EditHitbox()
  check(starts==1 and state.visible and state.mode=="Preview","AC01 Entry starts one visible preview without tools")
  check(root.ToggleHitboxPreview.Text=="Preview: On" and root:FindFirstChild("StartHitboxPreview")==nil and root:FindFirstChild("HitboxPreview")==nil,"AC01/02 Exact toggle label; obsolete preview buttons removed")
  check(root.ToggleHitboxPreview.BackgroundColor3~=root.HitboxMove.BackgroundColor3,"AC03 Selected/inactive controls distinct palette roles")
  check(root.HitboxReadout.Text:find("9.123 x 7.000 x 12.988",1,true) and root.HitboxReadout.Text:find("X 0.000",1,true) and not root.HitboxReadout.Text:find("-0.000",1,true) and root.HitboxReadout.Text:find("31.457",1,true),"AC04 Size/offset/rotation readouts three decimals with normalized negative zero")
  check(root:FindFirstChild("HitboxScaleAxis")==nil and root:FindFirstChild("HitboxScaleUniform")==nil,"AC05 Explicit scale buttons removed")
  check(not root.UndoHitbox.Active,"AC06 Empty history visibly unavailable")
  actions.HitboxMove(); check(state.mode=="Move","AC02 Move on green")
  actions.HitboxMove(); check(state.mode=="Preview","AC02 Active Move toggles off")
  mounted.invoke("Resize"); check(state.mode=="Resize","AC05 Shortcut uses same Resize transition")
  actions.HitboxRotate(); check(state.mode=="Rotate","AC02 Selecting Rotate disables Resize")
  state.canUndo=true; notify()
  actions.ToggleHitboxPreview()
  check(not state.visible and state.mode=="Preview" and root.HitboxStatus.Text=="Preview Ended" and starts==1 and destroys==0,"AC01/04 Off retains controller and sets exact status")
  actions.UndoHitbox(); check(not state.canUndo and root.HitboxReadout.Text:find("8.123",1,true),"AC06 Undo available while preview off refreshes readout")
  actions.UndoHitbox(); check(not state.canUndo,"AC06 Empty Undo safe no-op")
  mounted.invoke("TogglePreview"); check(state.visible and state.mode=="Preview" and starts==1,"AC01/05 Shortcut resumes same draft controller")
  state.canUndo=true; notify(); mounted.invoke("Undo"); check(not state.canUndo,"AC05/06 Draft Undo shortcut uses shared action")
  if guards then
   guards.focused=true; mounted.invoke("Move"); check(state.mode=="Preview","AC05 Focused textbox guards shortcuts"); guards.focused=false
   guards.running=true; mounted.invoke("Move"); check(state.mode=="Preview","AC05 Play guards shortcuts"); guards.running=false
   guards.duringSave=function() check(not mounted.invoke("TogglePreview") and not state.visible,"AC05 Busy save guards shortcut dispatch") end
  end
  actions.ToggleHitboxPreview(); actions.SaveHitbox()
  check(saves==1 and lastSnapshot.module==target and lastSaved.Range==12.987654321 and lastSaved.HitboxOffsetX==-.00001,"AC01/04 Save while off uses exact unrounded draft")
  check(root.HitboxStatus.Text=="Skill changed; reopen.","AC07 Save conflict remains actionable")
  saveMode="throw"; actions.SaveHitbox(); check(root.HitboxStatus.Text:find("Injected save exception",1,true),"AC07 Specific save exception retained")
  if guards then guards.duringSave=nil end
  saveMode="success"; actions.SaveHitbox()
  check(destroys==1 and root.RangeInput.Text=="12.988" and root.Status.Text=="Saved visual geometry.","AC04/06 Successful Save closes controller and formats common depth")
  check(not mounted.invoke("Move"),"AC05 Dispatcher inert after returning common editor")
  selectionValid=false; actions.EditHitbox()
  check(starts==2 and not state.visible,"AC01 Invalid selection off and retryable")
  actions.ToggleHitboxPreview(); check(not state.visible,"AC01 Failed retry preserves off state")
  selectionValid=true; actions.ToggleHitboxPreview(); check(state.visible and starts==2,"AC01 Valid retry uses retained controller")
  host.Enabled=false; task.wait()
  check(not state.visible and not mounted.invoke("TogglePreview"),"AC05/07 Widget hide hides render and gates shortcuts")
  host.Enabled=true; check(not state.visible,"AC07 Re-enable does not restart preview")
  actions.Back()
  actions.EditHitbox(); local beforeSaves=saves
  actions.Back(); check(destroys==3 and saves==beforeSaves,"AC06/07 Cancel disposes draft without save")
  actions.EditHitbox(); local before=destroys
  root:Destroy(); task.wait()
  check(destroys==before+1 and not mounted.invoke("Move"),"AC05/07 Root destruction disconnects page dispatcher")
 end)
 if mounted and mounted.destroy then mounted.destroy() end
 host:Destroy(); target:Destroy()
 assert(ok,failure)
 return tostring(count).." visual hitbox UI assertions passed (actual callbacks; injected retained controller/input state)"
end
