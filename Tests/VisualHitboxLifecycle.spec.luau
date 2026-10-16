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
 local handles
 local editor=loadEditor({Selection={Get=function() return selection end},RunService={IsRunning=function() return running end,RenderStepped=render},CoreGui=core}, {
  workspace=world,Instance={new=function(class)
   if class~="Handles" then return Instance.new(class) end
   handles={MouseButton1Down=signal(),MouseButton1Up=signal(),MouseDrag=signal(),destroyed=false}
   function handles:Destroy() self.destroyed=true end
   return handles
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
  handles.MouseButton1Down:Fire(); handles.MouseDrag:Fire(Enum.NormalId.Right,2); handles.MouseDrag:Fire(Enum.NormalId.Right,3)
  check(session.getDraft().HitboxOffsetX==3,"AC02 Live drag uses mouse-down baseline instead of accumulated delta")
  handles.MouseButton1Up:Fire(); handles.MouseDrag:Fire(Enum.NormalId.Right,8)
  check(session.getDraft().HitboxOffsetX==3,"AC02 Drag without mouse-down cannot mutate draft")
  check(session.setMode("Resize"),"AC02 Resize mode available")
  handles.MouseButton1Down:Fire(); handles.MouseDrag:Fire(Enum.NormalId.Front,2); handles.MouseButton1Up:Fire()
  local draft=session.getDraft()
  check(draft.Range==10 and draft.HitboxOffsetZ==2,"AC02 Live resize depth keeps box center")
  local capturedDraft=session.getDraft(); capturedDraft.Range=999
  check(session.getDraft().Range==10,"AC05 Exposed draft is a copy")
  selection={second}; render:Fire()
  check(box.Adornee==root and session.getDraft().Range==10,"AC01 Later selection never silently retargets session")
  root.CFrame=CFrame.new(9,5,-4)*CFrame.Angles(.1,-1.2,.2); render:Fire()
  check(near(proxy.Position,(root.CFrame*CFrame.new(3,0,-3)).Position),"AC02 Root movement/rotation refreshes preview transform")
  for key,value in source do check(config[key]==value,"AC05 Preview preserves config "..key) end
  session.destroy()
  check(handles.destroyed and #core:GetChildren()==0 and activeConnections==0,"AC05 Cancel destroys preview and disconnects all listeners")
  local afterDestroy=deactivates; session.destroy()
  check(deactivates==afterDestroy,"AC05 Session destroy is idempotent")
  for _,ending in {"replace","deactivation","unload","play","rootLoss","humanoidLoss"} do
   selection={first}; running=false
   local old=assert(begin()); local oldHandles=handles
   if ending=="replace" then
    local replacement=assert(begin()); check(oldHandles.destroyed,"AC05 Starting another session retires first"); replacement.destroy()
   elseif ending=="deactivation" then plugin.Deactivation:Fire()
   elseif ending=="unload" then plugin.Unloading:Fire()
   elseif ending=="play" then running=true; render:Fire(); running=false
   elseif ending=="rootLoss" then root.Parent=nil; render:Fire(); root.Parent=first
   else local humanoid=first:FindFirstChildOfClass("Humanoid"); humanoid.Parent=nil; render:Fire(); humanoid.Parent=first end
   check(oldHandles.destroyed and #core:GetChildren()==0 and activeConnections==0,"AC05 Cleanup on "..ending)
   check(not old.setMode("Move"),"AC05 Ended session cannot reactivate handles")
  end
  check(stops>=4 and type(lastMessage)=="string" and changes>=4,"AC05 Lifecycle endings provide guidance and draft changes are reported")
 end)
 -- Ensure even assertion failures stop active sessions before destroying fixtures.
 plugin.Unloading:Fire(); world:Destroy(); core:Destroy()
 assert(ok,failure)
 return tostring(count).." visual hitbox lifecycle assertions passed (isolated adornments; injected handle events)"
end
