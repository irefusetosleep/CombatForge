-- PROJECTILE-EDITOR-01 independent eligibility, checked radius saves and spherical sessions.
return function(Config,loadManager,loadEditor,uiLoader,linkedModule)
 local count=0
 local function check(v,m)assert(v,m);count+=1 end
 local base={Name="AnyName",Damage=31,Cooldown=.75,Range=87.123456789,AnimationId="",HitDelay=.1,ProjectileSpeed=60,ProjectileRadius=.5,ProjectileLifetime=3,AimMode="Body"}
 local editor=loadEditor({Selection={},RunService={},CoreGui={}})
 check(editor.isSupported(base),"AC02 Complete projectile recognized by fields")
 local draft=assert(editor.newDraft(base));local fields=0;for key,value in draft do fields+=1;check(key=="ProjectileRadius" and value==.5,"AC02 Projectile draft narrow field")end
 check(fields==1,"AC02 Exactly one projectile geometry key")
 for _,key in {"AnimationId","HitDelay","ProjectileSpeed","ProjectileRadius","ProjectileLifetime","AimMode"} do
  local partial=table.clone(base);partial[key]=nil;check(not editor.isSupported(partial),"AC02 Missing projectile field rejected "..key)
 end
 for _,key in {"HitboxWidth","HitboxHeight","HitboxOffsetX","HitboxOffsetY","HitboxOffsetZ","HitboxRotationX","HitboxRotationY","HitboxRotationZ"} do
  local mixed=table.clone(base);mixed[key]=if key=="HitboxWidth" or key=="HitboxHeight" then 5 else 0
  check(not editor.isSupported(mixed),"AC02 Mixed geometry rejected "..key)
 end
 for _,prefix in {"HitboxOffset","HitboxRotation"} do
  local mixed=table.clone(base);mixed[prefix.."X"]=0;mixed[prefix.."Y"]=0;mixed[prefix.."Z"]=0
  check(not editor.isSupported(mixed),"AC02 Complete valid melee triple still excludes projectile "..prefix)
 end
 for _,bad in {0,-1,0/0,math.huge,-math.huge,257,".5"} do local invalid=table.clone(base);invalid.ProjectileRadius=bad;check(not editor.isSupported(invalid),"AC02 Invalid radius fails closed") end
 local storage=Instance.new("Folder");local rootFolder=Instance.new("Folder");rootFolder.Name="CombatForge";rootFolder.Parent=storage
 local abilities=Instance.new("Folder");abilities.Name="Abilities";abilities.Parent=rootFolder
 local target=Instance.new("ModuleScript");target.Name=base.Name;target.Source=Config.serialize(base);target.Parent=abilities
 local running,allow,failCommit,failEditor,conflict=false,true,false,false,false
 local begins,commits,cancels=0,0,0
 local original
 local manager=loadManager({ReplicatedStorage=storage,RunService={IsRunning=function()return running end},
  ScriptEditorService={GetEditorSource=function(_,item)return item.Source end,UpdateSourceAsync=function(_,item,callback)
   if failEditor then error("Editor failure")end
   local changed=callback(if conflict then item.Source.."-- external" else item.Source);if changed then item.Source=changed end
  end},ChangeHistoryService={TryBeginRecording=function()begins+=1;original=target.Source;return if allow then "radius" else nil end,
   FinishRecording=function(_,_,operation)if operation==Enum.FinishRecordingOperation.Commit then if failCommit then error("Commit failure")end;commits+=1 else cancels+=1;target.Source=original end end}})
 local world,core=Instance.new("WorldModel"),Instance.new("Folder")
 local model=Instance.new("Model");model.Parent=world;local humanoid=Instance.new("Humanoid");humanoid.Parent=model
 local root=Instance.new("Part");root.Name="HumanoidRootPart";root.CFrame=CFrame.new(8,4,-13)*CFrame.Angles(.3,-1.1,.4);root.Parent=model
 local connections=0
 local function signal()
  local entries={}
  return {Connect=function(_,fn)local e={active=true,fn=fn};table.insert(entries,e);connections+=1;return {Disconnect=function()if e.active then e.active=false;connections-=1 end end}end,
   Fire=function(_,...)for _,e in entries do if e.active then e.fn(...)end end end}
 end
 local handles,arcs
 local selection={model};local render=signal();local lastMessage
 local renderEditor=loadEditor({Selection={Get=function()return selection end},RunService={IsRunning=function()return running end,RenderStepped=render},CoreGui=core},{workspace=world,Instance={new=function(class)
  if class~="Handles" and class~="ArcHandles" then return Instance.new(class)end
  local control={MouseButton1Down=signal(),MouseButton1Up=signal(),MouseDrag=signal(),destroyed=false}
  function control:Destroy()self.destroyed=true end
  if class=="Handles" then handles=control else arcs=control end
  return control
 end}})
 local plugin={Deactivation=signal(),Unloading=signal(),Activate=function()end}
 function plugin:Deactivate()self.Deactivation:Fire()end
 local function start(config)return assert(renderEditor.start(plugin,config or base,nil,function(message)lastMessage=message end))end
 local function sameRadius(value,radius)
  local keys=0;for key in value do keys+=1;check(key=="ProjectileRadius","AC02 Session draft never acquires box fields")end
  return keys==1 and value.ProjectileRadius==radius
 end
 local function drag(session,face,distances)
  check(session.setMode("Resize"),"AC03 Resize supported")
  handles.MouseButton1Down:Fire(face);for _,amount in distances do handles.MouseDrag:Fire(face,amount)end;handles.MouseButton1Up:Fire(face)
 end
 local session
 local ok,problem=pcall(function()
  local snapshot=assert(manager.read(target))
  check(manager.saveGeometry(snapshot,{ProjectileRadius=2.123456789}) and commits==1,"AC05 One radius Save recording")
  local parsed=assert(Config.parse(target.Source));check(parsed.ProjectileRadius==2.123456789,"AC05 Radius exact precision persisted")
  for key,value in base do if key~="ProjectileRadius" then check(parsed[key]==value,"AC05 All unrelated values preserved "..key)end end
  local source=target.Source
  check(not manager.saveGeometry(snapshot,{ProjectileRadius=1}) and target.Source==source,"AC05 Stale source blocked")
  for _,extra in {"Range","Damage","HitboxWidth","HitboxOffsetX","HitboxRotationZ","Kind"} do
   local injected={ProjectileRadius=1};injected[extra]=2
   local prior=begins;check(not manager.saveGeometry(assert(manager.read(target)),injected) and target.Source==source and begins==prior,"AC05 Extra geometry input rejected "..extra)
  end
  for _,bad in {0,-1,0/0,math.huge,-math.huge,257,"1"} do local prior=begins;check(not manager.saveGeometry(assert(manager.read(target)),{ProjectileRadius=bad}) and target.Source==source and begins==prior,"AC05 Invalid radius refused before history")end
  snapshot=assert(manager.read(target));target.Name="ExternalRename";check(not manager.saveGeometry(snapshot,{ProjectileRadius=1}),"AC05 Name conflict blocked");target.Name=base.Name
  snapshot=assert(manager.read(target));target.Parent=storage;check(not manager.saveGeometry(snapshot,{ProjectileRadius=1}),"AC05 Moved config blocked");target.Parent=abilities
  running=true;local before=begins;check(not manager.saveGeometry(assert(manager.read(target)),{ProjectileRadius=1}) and begins==before,"AC05 Play save rejected");running=false
  allow=false;check(not manager.saveGeometry(assert(manager.read(target)),{ProjectileRadius=1}) and target.Source==source,"AC05 No recording means no mutation");allow=true
  for _,mode in {"commit","editor","conflict"} do
   failCommit=mode=="commit";failEditor=mode=="editor";conflict=mode=="conflict";local prior=cancels
   check(not manager.saveGeometry(assert(manager.read(target)),{ProjectileRadius=1}) and target.Source==source and cancels==prior+1,"AC05 Failure rollback "..mode)
  end
  failCommit=false;failEditor=false;conflict=false
  local beforeSource=target.Source
  session=start()
  local gui=core:GetChildren()[1];local sphere=gui:FindFirstChild("HitboxPreview")
  check(sphere and sphere:IsA("SphereHandleAdornment") and sphere.Adornee==root and sphere.Radius==.5,"AC03 Actual sphere with configured radius")
  check((root.CFrame*sphere.CFrame).Position==root.Position,"AC03 Sphere centered at root, not melee forward offset")
  check(handles.Adornee.Size==Vector3.one and handles.Adornee.Position==root.Position and not handles.Visible and (not arcs or not arcs.Visible),"AC03 Diameter proxy and no initial controls")
  check(not session.setMode("Move") and not session.setMode("Rotate") and sameRadius(session.getDraft(),.5),"AC03 Unsupported modes safe no-op")
  for _,face in {Enum.NormalId.Right,Enum.NormalId.Left,Enum.NormalId.Top,Enum.NormalId.Bottom,Enum.NormalId.Front,Enum.NormalId.Back} do
   drag(session,face,{.2,.7});check(sameRadius(session.getDraft(),1.2),"AC04 Every face r0+d baseline without doubling")
   check(handles.Adornee.Position==root.Position and math.abs(sphere.Radius-1.2)<.00001,"AC04 Resize keeps fixed center and actual sphere radius")
   check(session.undo() and sameRadius(session.getDraft(),.5) and not session.getState().canUndo,"AC04 One undo per repeated gesture")
  end
  session.setShiftHeld(true);drag(session,Enum.NormalId.Right,{.2});check(sameRadius(session.getDraft(),.7),"AC04 Shift radius math unchanged");session.undo();session.setShiftHeld(false)
  session.setSnapPreferences({enabled=true,move=1,resize=.25,rotate=15})
  drag(session,Enum.NormalId.Top,{-.125});check(sameRadius(session.getDraft(),.25),"AC04 Signed half-away snap distance before radius clamp");session.undo()
  drag(session,Enum.NormalId.Top,{.12});check(sameRadius(session.getDraft(),.5) and not session.getState().canUndo,"AC04 Snapped-zero exact no-op")
  drag(session,Enum.NormalId.Back,{1000});check(sameRadius(session.getDraft(),256),"AC04 Upper radius limit");session.undo()
  drag(session,Enum.NormalId.Front,{-1000});check(sameRadius(session.getDraft(),.025),"AC04 Lower radius handle limit");session.undo()
  session.setSnapPreferences({enabled=false,move=1,resize=1,rotate=15});drag(session,Enum.NormalId.Right,{.7})
  session.setPreviewVisible(false);check(session.getDraft().ProjectileRadius==1.2 and session.getState().canUndo,"AC06 Off retains draft/history")
  check(session.reset() and sameRadius(session.getDraft(),.5),"AC04 Reset off restores only .5")
  check(session.undo() and sameRadius(session.getDraft(),1.2),"AC04 Reset one undo exact")
  check(target.Source==beforeSource and base.ProjectileRadius==.5,"AC05 Preview edits never mutate config source/input before Save")
  check(manager.saveGeometry(assert(manager.read(target)),session.getDraft()),"AC05 Off-preview radius save works")
  check(Config.parse(target.Source).Range==base.Range and Config.parse(target.Source).ProjectileRadius==1.2,"AC05 Save preserves travel Range")
  local saved=assert(Config.parse(target.Source));local sweptRadius,visualDiameter,visualRemoved,ticks
  local projectile,shared=linkedModule("Templates/ProjectileSkill.luau",{RunService={IsServer=function()return true end,Heartbeat={Wait=function()ticks=(ticks or 0)+1;assert(ticks<10);return 1 end}},Debris={AddItem=function(_,visual)visualDiameter=visual.Size.X end}},nil,
   {workspace={GetPartsInPart=function()return {}end,Spherecast=function(_,_,radius)sweptRadius=radius;return nil end},RaycastParams={new=function()return {}end},OverlapParams={new=function()return {}end},Instance={new=function()return {Destroy=function()visualRemoved=true end}end}})
  for key,value in saved do shared[key]=value end
  local captured=assert(projectile.GetConfig());projectile.Cast(model,nil,function()return true end,captured)
  check(sweptRadius==saved.ProjectileRadius and math.abs(visualDiameter/2-saved.ProjectileRadius)<.00001 and visualRemoved,"AC05 Parsed edited config -> GetConfig -> Spherecast radius equals visual diameter/2")
  session.undo();check(sameRadius(session.getDraft(),.5) and not session.getState().canUndo,"AC04 Undo independent snapping state")
  session.reset();check(not session.getState().canUndo,"AC04 Already-default Reset no history")
  session.setPreviewVisible(true);session.setMode("Resize");local stale=handles
  handles.MouseButton1Down:Fire(Enum.NormalId.Right);handles.MouseDrag:Fire(Enum.NormalId.Right,.2);session.reset();stale.MouseDrag:Fire(Enum.NormalId.Right,3);stale.MouseButton1Up:Fire(Enum.NormalId.Right)
  check(sameRadius(session.getDraft(),.5),"AC04 Reset invalidates unfinished drag")
  session.destroy();session=nil;check(#core:GetChildren()==0 and connections==0,"AC06 Session disposal removes resources")
  local tiny=table.clone(base);tiny.ProjectileRadius=.001
  session=start(tiny);check(sameRadius(session.getDraft(),.001),"AC04 Valid tiny source radius preserved even renderer rejects")
  if session.getState().visible then drag(session,Enum.NormalId.Left,{-1});check(sameRadius(session.getDraft(),.001) and not session.getState().canUndo,"AC04 Tiny baseline no clamp jump")else check(type(lastMessage)=="string","AC04 Tiny rendering failure diagnostic")end
  session.destroy();session=nil
  for _,ending in {"missing","play","reference","deactivate","unload"} do
   selection=if ending=="missing" then {} else {model};running=false;session=start()
   if ending=="missing" then check(not session.getState().visible,"AC06 Missing selection retained retry");selection={model};check(session.setPreviewVisible(true),"AC06 Valid retry")
   elseif ending=="play" then running=true;render:Fire();running=false
   elseif ending=="reference" then root.Parent=nil;render:Fire();root.Parent=model
   elseif ending=="deactivate" then plugin.Deactivation:Fire()
   else plugin.Unloading:Fire()end
   if ending~="missing" then check(not session.getState().visible and #core:GetChildren()==0,"AC06 Render cleanup "..ending)end
   session.destroy();session=nil;check(connections==0,"AC06 Listener cleanup "..ending)
  end
  local ui,actions=uiLoader()
  local host=Instance.new("ScreenGui");host.Enabled=true
  local viewDraft,viewState,onViewChanged,onViewState
  local capability={isSupported=renderEditor.isSupported,start=function(config,onChanged,_,onState)
   viewDraft={ProjectileRadius=config.ProjectileRadius};viewState={kind="Projectile",visible=true,mode="Preview",canUndo=false,shiftHeld=false,snapping=false,snapIncrement=1}
   onViewChanged=onChanged;onViewState=onState
   local controller={getDraft=function()return table.clone(viewDraft)end,getState=function()return table.clone(viewState)end,
    setShiftHeld=function()return true end,setMode=function(mode)if mode=="Move" or mode=="Rotate" then return false end;viewState.mode=mode;onState(viewState);return true end,
    setPreviewVisible=function(value)viewState.visible=value;viewState.mode="Preview";onState(viewState);return true end,
    setSnapPreferences=function(values)viewState.snapping=values.enabled;onState(viewState);return true end,
    reset=function()viewDraft.ProjectileRadius=.5;viewState.canUndo=true;onChanged(viewDraft);onState(viewState);return true end,
    undo=function()return false end,destroy=function()viewState.visible=false end}
   onChanged(viewDraft);onState(viewState);return controller,"Preview active"
  end}
  local mounted=ui.mount(host,manager,nil,nil,nil,nil,capability)
  local content=host.CombatForgeRoot;local navigation=host.CombatForgeNavigation
  check(navigation.Back.Position.X.Offset<navigation.Home.Position.X.Offset and not navigation.Back.Active and not navigation.Home.Active,"AC01 Back before Home even disabled root")
  actions.UpdateSkills();check(navigation.Back.Position.X.Offset<navigation.Home.Position.X.Offset,"AC01 List nav order")
  actions.Skill1();check(content:FindFirstChild("EditHitbox")~=nil,"AC02 UI exposes projectile Edit Hitbox")
  actions.EditHitbox()
  check(content:FindFirstChild("HitboxMove")==nil and content:FindFirstChild("HitboxRotate")==nil and content:FindFirstChild("HitboxResize")~=nil,"AC03 Projectile modes restricted to Resize")
  check(content.HitboxReadout.Text:find("Radius",1,true) and content.HitboxReadout.Text:find("1.200",1,true) and content.HitboxReadout.Text:find("2.400",1,true),"AC03 Radius/diameter readout three decimals")
  check(content.HitboxInstructions.Text:lower():find("launch",1,true) and content.HitboxInstructions.Text:find("Range",1,true),"AC03 Help launch sphere distinct from travel Range")
  mounted.invoke("Move");mounted.invoke("Rotate");check(viewState.mode=="Preview" and viewDraft.ProjectileRadius==1.2,"AC03 Unsupported shortcuts no-op")
  viewDraft.ProjectileRadius=2.3456789;viewState.canUndo=true;onViewChanged(viewDraft);onViewState(viewState)
  actions.Back();check(content.DiscardPrompt.Visible,"AC06 Dirty radius Back prompts")
  actions.KeepEditing();check(viewDraft.ProjectileRadius==2.3456789 and viewState.canUndo,"AC06 Keep preserves radius/history")
  actions.ToggleHitboxPreview();actions.SaveHitbox()
  local afterUI=assert(Config.parse(target.Source))
  check(afterUI.ProjectileRadius==2.3456789 and afterUI.Range==base.Range and content:FindFirstChild("RangeInput"),"AC05 Actual UI saves precise radius while off without changing Range")
  actions.Back();actions.Back();check(content:FindFirstChild("CreateNewSkill"),"AC01 Preserved form/list/root routes")
  mounted.destroy();host:Destroy()
  check(beforeSource~=target.Source,"AC05 Only explicit Save changed config")
 end)
 if session then session.destroy()end;plugin.Unloading:Fire();world:Destroy();core:Destroy();storage:Destroy()
 assert(ok,problem)
 return tostring(count).." projectile editor eligibility/save/sphere lifecycle assertions passed"
end
