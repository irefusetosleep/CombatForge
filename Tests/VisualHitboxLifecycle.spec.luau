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
  local function same(a,b)
   for key,value in a do if value~=b[key] then return false end end
   for key,value in b do if value~=a[key] then return false end end
   return true
  end
  local function gesture(session,mode,axis,deltas)
   session.setMode(mode)
   local control=if mode=="Rotate" then arcs else handles
   control.MouseButton1Down:Fire(axis)
   for _,delta in deltas do control.MouseDrag:Fire(axis,delta,0) end
   control.MouseButton1Up:Fire(axis)
  end
  selection={}
  local invalid=assert(begin())
  check(not invalid.getState().visible and #core:GetChildren()==0 ,"AC01 Invalid selection retains draft controller without render resources")
  check(not invalid.setPreviewVisible(true) and not invalid.getState().visible,"AC01 Repeated failed retry stays safe")
  selection={first}; check(invalid.setPreviewVisible(true) and invalid.getState().visible,"AC01 Same controller retries valid selection")
  invalid.destroy()
  local source=table.clone(config)
  local beforeRoot=root.CFrame
  local session=assert(begin())
  check(#core:GetChildren()==1,"AC01 Exactly one plugin-owned GUI")
  local gui=core:GetChildren()[1]
  local box=gui:FindFirstChild("HitboxPreview")
  local proxy=handles.Adornee
  check(box and box:IsA("BoxHandleAdornment") and box.Adornee==root and box.Transparency>0,"AC01 Box references captured dummy")
  check(proxy:IsA("Part") and proxy.Parent==nil and not proxy.CanCollide and not proxy.CanTouch and not proxy.CanQuery and proxy.Transparency==1,"AC07 Proxy unparented/inert")
  check(hiddenBeforeParent and geometryBeforeAdornee and not handles.Visible and not arcs.Visible,"AC01 Controls hidden until initialized")
  check(session.getState().mode=="Preview" and session.getState().scaleMode=="Axis" and not session.getState().canUndo,"AC02/03/06 Initial tools/history/scale defaults")
  check(not session.undo(),"AC06 Empty history safe no-op")
  local initial=session.getDraft()
  handles.MouseButton1Down:Fire(Enum.NormalId.Right); handles.MouseDrag:Fire(Enum.NormalId.Right,8)
  check(same(session.getDraft(),initial),"AC02 Hidden stale drag ignored")
  gesture(session,"Move",Enum.NormalId.Right,{1,2,3})
  local moved=session.getDraft()
  check(moved.HitboxOffsetX==3 and session.getState().canUndo,"AC06 Multiple drag events form one completed edit")
  check(session.undo() and same(session.getDraft(),initial) and not session.getState().canUndo,"AC06 One Undo restores exact baseline once")
  gesture(session,"Move",Enum.NormalId.Right,{0})
  check(not session.getState().canUndo and same(session.getDraft(),initial),"AC06 No-op Move adds no history")
  gesture(session,"Rotate",Enum.Axis.X,{0})
  check(not session.getState().canUndo and same(session.getDraft(),initial),"AC06 No-op Rotate preserves exact draft/history")
  gesture(session,"Move",Enum.NormalId.Right,{2})
  local afterMove=session.getDraft()
  gesture(session,"Resize",Enum.NormalId.Front,{2})
  local afterAxis=session.getDraft()
  session.setScaleMode("Uniform")
  gesture(session,"Resize",Enum.NormalId.Top,{1,2})
  local afterUniform=session.getDraft()
  gesture(session,"Rotate",Enum.Axis.Y,{.4,.7})
  local afterRotate=session.getDraft()
  check(session.undo() and same(session.getDraft(),afterUniform),"AC06 Rotate undone exactly")
  check(session.undo() and same(session.getDraft(),afterAxis),"AC06 Uniform resize undone exactly")
  check(session.undo() and same(session.getDraft(),afterMove),"AC06 Axis resize undone exactly")
  check(session.undo() and same(session.getDraft(),initial) and not session.getState().canUndo,"AC06 Move undone last in reverse order")
  gesture(session,"Move",Enum.NormalId.Right,{3})
  local historyDraft=session.getDraft()
  local oldHandles,oldArcs=handles,arcs
  session.setPreviewVisible(false)
  check(not session.getState().visible and session.getState().mode=="Preview" and #core:GetChildren()==0 and oldHandles.destroyed and oldArcs.destroyed,"AC01 Off clears tools/resources")
  check(same(session.getDraft(),historyDraft) and session.getState().canUndo and lastMessage=="Preview Ended","AC01/04 Off retains exact draft/history and exact status")
  oldHandles.MouseButton1Down:Fire(Enum.NormalId.Right); oldHandles.MouseDrag:Fire(Enum.NormalId.Right,10)
  check(same(session.getDraft(),historyDraft),"AC02 Stale disposed controls cannot edit")
  check(session.undo() and same(session.getDraft(),initial) and not session.getState().canUndo,"AC06 Undo while off updates retained draft")
  check(session.setPreviewVisible(true) and #core:GetChildren()==1 and session.getState().mode=="Preview","AC01 On restores single preview with no tool")
  check(same(session.getDraft(),initial) and not handles.Visible and not arcs.Visible,"AC01 On retains exact geometry/history")
  session.setMode("Move"); handles.MouseButton1Down:Fire(Enum.NormalId.Right); handles.MouseDrag:Fire(Enum.NormalId.Right,2)
  check(session.undo() and same(session.getDraft(),initial) and not session.getState().canUndo,"AC06 Midgesture Undo restores current baseline once")
  handles.MouseDrag:Fire(Enum.NormalId.Right,7); handles.MouseButton1Up:Fire(Enum.NormalId.Right)
  check(same(session.getDraft(),initial) and not session.getState().canUndo,"AC06 Interrupted drag callbacks cannot recommit")
  gesture(session,"Move",Enum.NormalId.Top,{1})
  check(session.undo() and same(session.getDraft(),initial),"AC06 New edit after Undo works")
  session.setMode("Resize"); handles.MouseButton1Down:Fire(Enum.NormalId.Right); handles.MouseDrag:Fire(Enum.NormalId.Right,2)
  local beforeScaleSwitch=session.getDraft()
  session.setScaleMode("Axis"); handles.MouseDrag:Fire(Enum.NormalId.Right,5); handles.MouseButton1Up:Fire(Enum.NormalId.Right)
  check(same(session.getDraft(),beforeScaleSwitch),"AC03 Scale choice interrupts drag without applying stale deltas")
  check(session.undo() and same(session.getDraft(),initial) and not session.getState().canUndo,"AC06 Interrupted accepted drag finalized once")
  session.setScaleMode("Uniform"); session.setScaleMode("Axis"); session.setMode("Move"); session.setMode("Preview")
  check(not session.getState().canUndo and same(session.getDraft(),initial),"AC03/06 Tool/scale toggles never add history")
  selection={second}; render:Fire()
  local capturedBox=core:GetChildren()[1]:FindFirstChild("HitboxPreview")
  check(capturedBox.Adornee==root,"AC01 Later selection never retargets captured root")
  session.setPreviewVisible(false); check(session.setPreviewVisible(true),"AC01 Off/on resumes captured reference")
  check(core:GetChildren()[1].HitboxPreview.Adornee==root,"AC01 Retry after off does not retarget another selected dummy")
  for key,value in source do check(config[key]==value,"AC07 Draft preserves config "..key) end
  check(root.CFrame==beforeRoot and #first:GetChildren()==2,"AC07 Preview never changes dummy")
  session.destroy()
  check(#core:GetChildren()==0 and activeConnections==0,"AC07 Destroy disconnects all callbacks")
  check(not session.setMode("Move") and not session.setPreviewVisible(true) and not session.undo(),"AC07 Destroyed controller inert")
  selection={first}
  local rejected=assert(begin()); local rejectBase=rejected.getDraft()
  rejected.setMode("Resize"); handles.MouseButton1Down:Fire(Enum.NormalId.Right); handles.MouseDrag:Fire(Enum.NormalId.Right,100000)
  check(not rejected.getState().visible and same(rejected.getDraft(),rejectBase) and not rejected.getState().canUndo,"AC06/07 First rejected render retains exact draft without phantom undo")
  check(lastMessage:find("render",1,true)~=nil and lastMessage~="Preview Ended","AC04 Render error remains diagnostic")
  rejected.destroy()
  local partial=assert(begin()); local partialBase=partial.getDraft()
  partial.setMode("Resize"); handles.MouseButton1Down:Fire(Enum.NormalId.Right); handles.MouseDrag:Fire(Enum.NormalId.Right,2)
  local lastGood=partial.getDraft()
  handles.MouseDrag:Fire(Enum.NormalId.Right,100000)
  check(not partial.getState().visible and same(partial.getDraft(),lastGood) and partial.getState().canUndo,"AC06/07 Rejected later render keeps accepted portion only")
  check(partial.undo() and same(partial.getDraft(),partialBase) and not partial.getState().canUndo,"AC06 Accepted partial gesture undone exactly once")
  partial.destroy()
  config.HitboxOffsetX=1.234567890123; config.HitboxOffsetY=-2.345678901234; config.HitboxOffsetZ=3.456789012345
  config.HitboxRotationX=31.123456789; config.HitboxRotationY=-47.23456789; config.HitboxRotationZ=19.3456789
  local precision=assert(begin()); local precisionBase=precision.getDraft()
  for _,mode in {"Move","Resize"} do
   gesture(precision,mode,Enum.NormalId.Right,{0})
   check(same(precision.getDraft(),precisionBase) and not precision.getState().canUndo,"AC04/06 Zero gesture preserves arbitrary full-precision geometry "..mode)
  end
  precision.setScaleMode("Uniform"); gesture(precision,"Resize",Enum.NormalId.Top,{0})
  check(same(precision.getDraft(),precisionBase) and not precision.getState().canUndo,"AC04/06 Zero uniform gesture preserves full precision")
  gesture(precision,"Rotate",Enum.Axis.Z,{0}); gesture(precision,"Rotate",Enum.Axis.X,{2*math.pi})
  check(same(precision.getDraft(),precisionBase) and not precision.getState().canUndo,"AC04/06 Zero/fullturn rotate preserves arbitrary baseline exactly")
  precision.destroy()
  config.HitboxOffsetX=nil; config.HitboxOffsetY=nil; config.HitboxOffsetZ=nil
  config.HitboxRotationX=nil; config.HitboxRotationY=nil; config.HitboxRotationZ=nil
  for _,ending in {"replace","deactivation","unload","play","rootLoss","humanoidLoss"} do
   selection={first}; running=false
   local old=assert(begin()); local oldHandles,oldArcs=handles,arcs
   gesture(old,"Move",Enum.NormalId.Right,{2})
   local retained=old.getDraft()
   if ending=="replace" then
    local replacement=assert(begin()); check(oldHandles.destroyed,"AC07 Replacement retires prior render"); replacement.destroy()
   elseif ending=="deactivation" then plugin.Deactivation:Fire()
   elseif ending=="unload" then plugin.Unloading:Fire()
   elseif ending=="play" then running=true; render:Fire(); running=false
   elseif ending=="rootLoss" then root.Parent=nil; render:Fire(); root.Parent=first
   else local humanoid=first:FindFirstChildOfClass("Humanoid"); humanoid.Parent=nil; render:Fire(); humanoid.Parent=first end
   check(oldHandles.destroyed and oldArcs.destroyed and #core:GetChildren()==0,"AC07 Cleanup on "..ending)
   check(not old.getState().visible and same(old.getDraft(),retained),"AC07 Ending retains safe draft without restart "..ending)
   if ending~="replace" and ending~="unload" then check(lastMessage=="Preview Ended","AC04 Normal ending exact status "..ending) end
   old.destroy()
   check(activeConnections==0,"AC07 No remaining listeners after controller disposal "..ending)
  end

 end)
 -- Ensure even assertion failures stop active sessions before destroying fixtures.
 plugin.Unloading:Fire(); world:Destroy(); core:Destroy()
 assert(ok,failure)
 return tostring(count).." visual hitbox lifecycle assertions passed (isolated adornments; injected handle events)"
end
