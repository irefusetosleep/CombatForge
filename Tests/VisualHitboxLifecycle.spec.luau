-- Real isolated preview Instances; injected Handles events and Studio services.
-- Native pointer hit testing/visibility is intentionally not claimed.
return function(loadEditor)
 local count=0
 local function check(value,message) assert(value,message); count+=1 end
 local activeConnections=0
 local function signal()
  local entries={}
  return {Connect=function(_,callback)
   local entry={active=true,callback=callback}; table.insert(entries,entry); activeConnections+=1
   return {Disconnect=function() if entry.active then entry.active=false; activeConnections-=1 end end}
  end,Fire=function(_,...) for _,entry in entries do if entry.active then entry.callback(...) end end end}
 end
 local world,core=Instance.new("WorldModel"),Instance.new("Folder")
 local function dummy(name)
  local model=Instance.new("Model"); model.Name=name; model.Parent=world
  local humanoid=Instance.new("Humanoid"); humanoid.Parent=model
  local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Anchored=true; root.CFrame=CFrame.new(4,3,9)*CFrame.Angles(0,.8,0); root.Parent=model
  return model,root
 end
 local first,root=dummy("FirstDummy")
 local second,secondRoot=dummy("SecondDummy")
 local selection={first}
 local running=false
 local render=signal()
 local handles,arcs
 local hiddenBeforeParent=true
 local geometryBeforeAdornee=true
 local editor=loadEditor({Selection={Get=function() return selection end},RunService={IsRunning=function() return running end,RenderStepped=render},CoreGui=core}, {
  workspace=world,Instance={new=function(class)
   if class~="Handles" and class~="ArcHandles" then return Instance.new(class) end
   local properties={MouseButton1Down=signal(),MouseButton1Up=signal(),MouseDrag=signal(),destroyed=false}
   local control=setmetatable({}, {__index=properties,__newindex=function(_,key,value)
    if key=="Parent" or key=="Adornee" then hiddenBeforeParent=hiddenBeforeParent and properties.Visible==false end
    if key=="Adornee" then
     geometryBeforeAdornee=geometryBeforeAdornee and value.Size==Vector3.new(5,5,6) and (value.Position-(root.CFrame*CFrame.new(0,0,-3)).Position).Magnitude<.00001
    end
    properties[key]=value
   end})
   function control:Destroy() self.destroyed=true end
   if class=="Handles" then handles=control else arcs=control end
   return control
  end},
 })
 local activates,deactivates=0,0
 local plugin={Deactivation=signal(),Unloading=signal(),Activate=function(_,exclusive) check(exclusive,"AC02 Native handle tool acquires mouse ownership"); activates+=1 end}
 function plugin:Deactivate() deactivates+=1; self.Deactivation:Fire() end
 local config={Name="PreviewMelee",Damage=20,Cooldown=.75,Range=6,AnimationId="",HitDelay=0,HitboxWidth=5,HitboxHeight=5}
 local function near(a,b) return (a-b).Magnitude<.00001 end
 local changes,stops=0,0
 local lastMessage
 local function begin()
  return editor.start(plugin,config,function() changes+=1 end,function(message) stops+=1; lastMessage=message end)
 end
 local ok,failure=pcall(function()
  check(editor.selectRoot({})==nil,"AC01 Empty selection rejected")
  check(editor.selectRoot({first,second})==nil,"AC01 Multiple dummy models rejected")
  check(editor.selectRoot({root,first})==root,"AC01 Descendant and Model from same dummy resolve exact root")
  local noHumanoid=Instance.new("Model"); noHumanoid.Parent=world
  check(editor.selectRoot({noHumanoid})==nil,"AC01 Model without Humanoid rejected"); noHumanoid:Destroy()
  root.Parent=nil; check(editor.selectRoot({first})==nil,"AC01 Missing root rejected"); root.Parent=first
  selection={}
  check(begin()==nil and #core:GetChildren()==0 and activeConnections==0,"AC01 Invalid selection creates no preview/resources")
  selection={first}; running=true
  check(begin()==nil and #core:GetChildren()==0,"AC05 Play mode refuses preview"); running=false
  local source=table.clone(config)
  local beforeRoot=root.CFrame
  local session=assert(begin())
  check(#core:GetChildren()==1 and activates==1,"AC02 Preview has one plugin-owned GUI")
  local gui=core:GetChildren()[1]
  local box=gui:FindFirstChild("HitboxPreview")
  local proxy=handles.Adornee
  check(box and box:IsA("BoxHandleAdornment") and box.Adornee==root and box.Transparency>0,"AC02 Translucent box references captured dummy root")
  check(proxy:IsA("Part") and proxy.Parent==nil and not proxy.CanCollide and not proxy.CanTouch and not proxy.CanQuery and proxy.Transparency==1,"AC05 Handle proxy is unparented and cannot affect game physics/query")
  check(not proxy.Archivable and not gui.Archivable and not box.Archivable,"AC05 Preview objects marked transient")
  for _,face in {Enum.NormalId.Left,Enum.NormalId.Right,Enum.NormalId.Top,Enum.NormalId.Bottom,Enum.NormalId.Front,Enum.NormalId.Back} do check(handles.Faces[face.Name],"AC02 Visible handles include face "..face.Name) end
  check(root.CFrame==beforeRoot and #first:GetChildren()==2,"AC05 Opening does not alter dummy")
  check(geometryBeforeAdornee,"AC01 Valid box geometry initialized before control Adornee assignment")
  check(hiddenBeforeParent and handles.Visible==false and arcs.Visible==false,"AC01 Both controls hidden before parent/Adornee assignment and default Preview")
  handles.MouseButton1Down:Fire(Enum.NormalId.Right); handles.MouseDrag:Fire(Enum.NormalId.Right,8)
  arcs.MouseButton1Down:Fire(Enum.Axis.X); arcs.MouseDrag:Fire(Enum.Axis.X,.7,0)
  check(session.getDraft().HitboxOffsetX==0 and session.getDraft().HitboxRotationX==0,"AC01 Preview ignores stray handle events")
  check(session.setMode("Move") and handles.Visible and not arcs.Visible,"AC01 Move exposes only Handles")
  handles.MouseButton1Down:Fire(Enum.NormalId.Right); handles.MouseDrag:Fire(Enum.NormalId.Right,2); handles.MouseDrag:Fire(Enum.NormalId.Right,3)
  check(session.getDraft().HitboxOffsetX==3,"AC02 Live drag uses mouse-down baseline instead of accumulated delta")
  handles.MouseButton1Up:Fire(Enum.NormalId.Right); handles.MouseDrag:Fire(Enum.NormalId.Right,8)
  check(session.getDraft().HitboxOffsetX==3,"AC02 Drag without mouse-down cannot mutate draft")
  check(session.setMode("Resize") and handles.Visible and not arcs.Visible,"AC02 Resize mode available")
  handles.MouseButton1Down:Fire(Enum.NormalId.Front); handles.MouseDrag:Fire(Enum.NormalId.Front,2); handles.MouseButton1Up:Fire(Enum.NormalId.Front)
  local draft=session.getDraft()
  check(draft.Range==8 and draft.HitboxOffsetZ==0,"AC02 Live one-sided front resize preserves opposite face")
  local capturedDraft=session.getDraft(); capturedDraft.Range=999
  check(session.getDraft().Range==8,"AC05 Exposed draft is a copy")
  check(session.setMode("Rotate") and not handles.Visible and arcs.Visible,"AC03 Rotate exposes only ArcHandles")
  local prior=proxy.CFrame
  arcs.MouseButton1Down:Fire(Enum.Axis.Y); arcs.MouseDrag:Fire(Enum.Axis.Y,.4,0); arcs.MouseDrag:Fire(Enum.Axis.Y,.7,0)
  local rotated=proxy.CFrame
  check(near(prior.Position,rotated.Position) and near(rotated.RightVector,(prior.Rotation*CFrame.fromAxisAngle(Vector3.yAxis,.7)).RightVector),"AC03 Arc drag baseline local rotation keeps center fixed")
  local beforeOtherAxis=proxy.CFrame
  arcs.MouseDrag:Fire(Enum.Axis.X,1.2,0)
  check(proxy.CFrame==beforeOtherAxis,"AC03 Axis-mismatched drag ignored")
  arcs.MouseButton1Up:Fire(Enum.Axis.X); arcs.MouseDrag:Fire(Enum.Axis.Y,.9,0)
  check(near(proxy.CFrame.RightVector,(prior.Rotation*CFrame.fromAxisAngle(Vector3.yAxis,.9)).RightVector),"AC03 Stale other-axis mouse-up does not cancel active drag")
  arcs.MouseButton1Up:Fire(Enum.Axis.Y)
  check(session.setMode("Preview") and not handles.Visible and not arcs.Visible,"AC03 Preview hides both controls retaining draft")
  local preserved=session.getDraft().HitboxRotationY
  arcs.MouseButton1Down:Fire(Enum.Axis.Y); arcs.MouseDrag:Fire(Enum.Axis.Y,2,0)
  check(session.getDraft().HitboxRotationY==preserved,"AC03 Hidden ArcHandles cannot change draft")
  session.setMode("Move"); handles.MouseButton1Down:Fire(Enum.NormalId.Top)
  session.setMode("Resize"); handles.MouseDrag:Fire(Enum.NormalId.Top,4)
  check(session.getDraft().HitboxHeight==5,"AC03 Mode switch clears unfinished baseline")
  selection={second}; render:Fire()
  check(box.Adornee==root and session.getDraft().Range==8,"AC01 Later selection never silently retargets session")
  root.CFrame=CFrame.new(9,5,-4)*CFrame.Angles(.1,-1.2,.2); render:Fire()
  check(near(proxy.Position,(root.CFrame*CFrame.new(3,0,-4)).Position),"AC02 Root movement/rotation refreshes preview transform")
  for key,value in source do check(config[key]==value,"AC05 Preview preserves config "..key) end
  session.destroy()
  check(handles.destroyed and arcs.destroyed and #core:GetChildren()==0 and activeConnections==0,"AC05 Cancel destroys preview and disconnects all listeners")
  local afterDestroy=deactivates; session.destroy()
  check(deactivates==afterDestroy,"AC05 Session destroy is idempotent")
  for _,ending in {"replace","deactivation","unload","play","rootLoss","humanoidLoss"} do
   selection={first}; running=false
   local old=assert(begin()); local oldHandles=handles; local oldArcs=arcs
   old.setMode("Rotate"); oldArcs.MouseButton1Down:Fire(Enum.Axis.Z)
   if ending=="replace" then
    local replacement=assert(begin()); check(oldHandles.destroyed,"AC05 Starting another session retires first"); replacement.destroy()
   elseif ending=="deactivation" then plugin.Deactivation:Fire()
   elseif ending=="unload" then plugin.Unloading:Fire()
   elseif ending=="play" then running=true; render:Fire(); running=false
   elseif ending=="rootLoss" then root.Parent=nil; render:Fire(); root.Parent=first
   else local humanoid=first:FindFirstChildOfClass("Humanoid"); humanoid.Parent=nil; render:Fire(); humanoid.Parent=first end
   check(oldHandles.destroyed and oldArcs.destroyed and #core:GetChildren()==0 and activeConnections==0,"AC05 Cleanup on "..ending)
   local oldDraft=old.getDraft(); oldArcs.MouseDrag:Fire(Enum.Axis.Z,2,0)
   check(old.getDraft().HitboxRotationZ==oldDraft.HitboxRotationZ,"AC05 Ended drag callbacks cannot mutate draft")
   check(not old.setMode("Move"),"AC05 Ended session cannot reactivate handles")
  end
  check(stops>=4 and type(lastMessage)=="string" and changes>=4,"AC05 Lifecycle endings provide guidance and draft changes are reported")
 end)
 -- Ensure even assertion failures stop active sessions before destroying fixtures.
 plugin.Unloading:Fire(); world:Destroy(); core:Destroy()
 assert(ok,failure)
 return tostring(count).." visual hitbox lifecycle assertions passed (isolated adornments; injected handle events)"
end
