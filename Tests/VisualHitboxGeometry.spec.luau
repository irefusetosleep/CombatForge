-- VISUAL-HITBOX-05 AC01/02/04: pure editor math compared with actual melee Cast.
return function(Editor,Config,linkedModule)
 local count=0
 local function check(value,message) assert(value,message); count+=1 end
 local function near(a,b) return (a-b).Magnitude<.00001 end
 local base={Name="Geometry",Damage=20,Cooldown=.75,Range=6,AnimationId="",HitDelay=0,HitboxWidth=5,HitboxHeight=4}
 check(Config.isMelee(base),"AC01 Eligible legacy melee with absent offsets")
 local projectile=table.clone(base); projectile.ProjectileSpeed=60
 check(not Config.isMelee(projectile),"AC01 Any projectile-specific setting excludes visual melee editing")
 local legacy={Name="Legacy",Damage=20,Cooldown=.75,Range=6}
 check(not Config.isMelee(legacy),"AC01 Four-field-only ability lacks supported melee geometry")
 local draft=assert(Editor.newDraft(base))
 check(draft.HitboxOffsetX==0 and draft.HitboxOffsetY==0 and draft.HitboxOffsetZ==0,"AC04 Missing offsets initialize draft to zero")
 check(base.HitboxOffsetX==nil,"AC05 Opening draft never modifies config")
 for _,angle in {730,-730,1e300,-1e300} do
  local full=table.clone(base); full.HitboxRotationX=angle; full.HitboxRotationY=-angle; full.HitboxRotationZ=angle
  local source=Config.serialize(full)
  local normalized=assert(Editor.newDraft(full))
  for _,key in {"HitboxRotationX","HitboxRotationY","HitboxRotationZ"} do
   check(normalized[key]>=-180 and normalized[key]<180,"AC03 Initial draft readout normalizes finite angles")
  end
  local frame=Editor.transform(CFrame.identity,normalized)
  local expected=CFrame.fromOrientation(math.rad(angle%360),math.rad((-angle)%360),math.rad(angle%360))
  check(near(frame.RightVector,expected.RightVector) and near(frame.UpVector,expected.UpVector),"AC04 Huge normalized angles preserve equivalent orientation")
  check(Config.serialize(full)==source and full.HitboxRotationX==angle,"AC05 Opening normalization never changes saved source or input table")
 end
 local root=CFrame.new(8,3,-10)*CFrame.Angles(.2,math.pi/2,-.15)
 local center,size=Editor.transform(root,draft)
 check(near(center.Position,(root*CFrame.new(0,0,-3)).Position) and size==Vector3.new(5,4,6),"AC02 Oriented preview uses root-local forward geometry")
 check(near(center.LookVector,root.LookVector) and near(center.UpVector,root.UpVector),"AC02 Preview preserves reference-root orientation")
 local faceAxes={
  {Enum.NormalId.Right,"HitboxOffsetX",2},{Enum.NormalId.Left,"HitboxOffsetX",-2},
  {Enum.NormalId.Top,"HitboxOffsetY",2},{Enum.NormalId.Bottom,"HitboxOffsetY",-2},
  {Enum.NormalId.Back,"HitboxOffsetZ",2},{Enum.NormalId.Front,"HitboxOffsetZ",-2},
 }
 for _,entry in faceAxes do
  local moved=assert(Editor.drag(draft,"Move",entry[1],2))
  check(moved[entry[2]]==entry[3],"AC02 Move handle applies correct signed local axis")
  check(moved.HitboxWidth==5 and moved.HitboxHeight==4 and moved.Range==6,"AC02 Move does not resize")
 end
 local one=assert(Editor.drag(draft,"Move",Enum.NormalId.Right,2))
 local two=assert(Editor.drag(draft,"Move",Enum.NormalId.Right,3))
 check(one.HitboxOffsetX==2 and two.HitboxOffsetX==3 and draft.HitboxOffsetX==0,"AC02 Absolute drag distances use unmodified mouse-down baseline")
 local axes={
  {Enum.NormalId.Right,"HitboxWidth",Vector3.xAxis},{Enum.NormalId.Left,"HitboxWidth",-Vector3.xAxis},
  {Enum.NormalId.Top,"HitboxHeight",Vector3.yAxis},{Enum.NormalId.Bottom,"HitboxHeight",-Vector3.yAxis},
  {Enum.NormalId.Back,"Range",Vector3.zAxis},{Enum.NormalId.Front,"Range",-Vector3.zAxis},
 }
 local oriented=table.clone(draft)
 oriented.HitboxRotationX=31; oriented.HitboxRotationY=-47; oriented.HitboxRotationZ=19
 oriented.HitboxOffsetX=2; oriented.HitboxOffsetY=-3; oriented.HitboxOffsetZ=4
 local function sameFrame(a,b) return near(a.Position,b.Position) and near(a.RightVector,b.RightVector) and near(a.UpVector,b.UpVector) and near(a.LookVector,b.LookVector) end
 for _,initial in {draft,oriented} do
  local initialCenter,initialSize=Editor.transform(root,initial)
  for _,entry in axes do
   for _,distance in {2,-1,-100} do
    local resized=assert(Editor.drag(initial,"Resize",entry[1],distance))
    local expected=math.max(.05,initial[entry[2]]+distance)
    check(math.abs(resized[entry[2]]-expected)<.00001,"AC02 One-sided resize changes dimension by outward distance")
    local resizedCenter,resizedSize=Editor.transform(root,resized)
    local normal=entry[3]
    local axis=Vector3.new(math.abs(normal.X),math.abs(normal.Y),math.abs(normal.Z))
    local tangentA=if axis.X==1 then Vector3.yAxis else Vector3.xAxis
    local tangentB=axis:Cross(tangentA)
    for _,sa in {-1,1} do for _,sb in {-1,1} do
     local oldCorner=(-normal+tangentA*sa+tangentB*sb)*initialSize/2
     local newCorner=(-normal+tangentA*sa+tangentB*sb)*resizedSize/2
     check(near(initialCenter:PointToWorldSpace(oldCorner),resizedCenter:PointToWorldSpace(newCorner)),"AC02 Opposite face corner fixed under arbitrary root/box rotation and clamping")
    end end
    check(near(resizedCenter.RightVector,initialCenter.RightVector) and near(resizedCenter.UpVector,initialCenter.UpVector),"AC02 Resize preserves orientation")
    local effective=expected-initial[entry[2]]
    check(near(resizedCenter.Position,initialCenter.Position+initialCenter:VectorToWorldSpace(normal*effective/2)),"AC02 Effective clamped delta shifts center half along selected normal")
   end
   local moved=assert(Editor.drag(initial,"Move",entry[1],2))
   local movedCenter,movedSize=Editor.transform(root,moved)
   check(near(movedCenter.Position,initialCenter.Position+initialCenter:VectorToWorldSpace(entry[3]*2)) and movedSize==initialSize,"AC02 Move follows rotated box axes and preserves dimensions")
  end
 end
 -- VISUAL06 AC03 proportional scale independently checks ratios and opposite-face center.
 for _,initial in {draft,oriented,{HitboxWidth=.001,HitboxHeight=.002,Range=.003,HitboxOffsetX=2,HitboxOffsetY=-3,HitboxOffsetZ=4,HitboxRotationX=31,HitboxRotationY=-47,HitboxRotationZ=19}} do
  local oldFrame,oldSize=Editor.transform(root,initial)
  for _,entry in axes do
   for _,distance in {2,-.0001,-100,0} do
    local changed=assert(Editor.drag(initial,"Resize",entry[1],distance,"Uniform"))
    local newFrame,newSize=Editor.transform(root,changed)
    local minimumRatio=math.max(math.min(.05,initial.HitboxWidth)/initial.HitboxWidth,math.min(.05,initial.HitboxHeight)/initial.HitboxHeight,math.min(.05,initial.Range)/initial.Range)
    local ratio=math.max(minimumRatio,(initial[entry[2]]+distance)/initial[entry[2]])
    check(near(newSize,oldSize*ratio),"VISUAL06 AC03 Uniform all dimensions use one clamped ratio")
    check(near(oldFrame:PointToWorldSpace(-entry[3]*initial[entry[2]]/2),newFrame:PointToWorldSpace(-entry[3]*changed[entry[2]]/2)),"VISUAL06 AC03 Opposite-face center anchored for all rotated faces")
    check(near(oldFrame.RightVector,newFrame.RightVector) and near(oldFrame.UpVector,newFrame.UpVector),"VISUAL06 AC03 Uniform orientation preserved")
    if distance==0 then
     for key,value in initial do check(changed[key]==value,"VISUAL06 AC03 Uniform zero drag preserves exact geometry "..key) end
    end
   end
  end
 end
 check(Editor.drag(oriented,"Resize",Enum.NormalId.Right,1,"Bogus")==nil,"VISUAL06 AC03 Invalid scale mode rejected")
 for _,bad in {0/0,math.huge,-math.huge} do
  check(Editor.drag(oriented,"Resize",Enum.NormalId.Top,bad,"Uniform")==nil,"VISUAL06 AC03 Nonfinite uniform distance rejected")
 end
 local depth=assert(Editor.drag(draft,"Resize",Enum.NormalId.Front,2))
 check(depth.Range==8 and depth.HitboxOffsetZ==0,"AC02 Front face extends outward while opposite back face stays fixed")
 local firstResize=assert(Editor.drag(oriented,"Resize",Enum.NormalId.Right,2))
 local secondResize=assert(Editor.drag(oriented,"Resize",Enum.NormalId.Right,3))
 check(firstResize.HitboxWidth==7 and secondResize.HitboxWidth==8 and oriented.HitboxWidth==5,"AC02 Repeated resize events use baseline")
 for _,angles in {{31,-47,19},{90,22,-73},{1e300,-1e300,1e300}} do
  local current=table.clone(oriented)
  current.HitboxRotationX=angles[1]; current.HitboxRotationY=angles[2]; current.HitboxRotationZ=angles[3]
  local currentCenter,currentSize=Editor.transform(root,current)
  for _,entry in {{Enum.Axis.X,Vector3.xAxis,.4},{Enum.Axis.Y,Vector3.yAxis,-.7},{Enum.Axis.Z,Vector3.zAxis,1.2}} do
   local rotated=assert(Editor.rotate(current,entry[1],entry[3]))
   local actual,actualSize=Editor.transform(root,rotated)
   local expectedRotation=currentCenter.Rotation*CFrame.fromAxisAngle(entry[2],entry[3])
   check(sameFrame(actual,CFrame.new(currentCenter.Position)*expectedRotation) and actualSize==currentSize,"AC03 Local-axis rotation composes from baseline without orbiting center")
   local again=assert(Editor.rotate(current,entry[1],entry[3]))
   check(sameFrame(Editor.transform(root,again),actual),"AC03 Repeated rotate event does not accumulate")
   current=rotated; currentCenter=actual
  end
 end
 for _,bad in {0/0,math.huge,-math.huge} do check(Editor.rotate(oriented,Enum.Axis.X,bad)==nil,"AC03 Nonfinite rotation input rejected") end
 check(Editor.rotate(oriented,Enum.NormalId.Top,1)==nil,"AC03 Invalid rotation axis rejected")
 local shrunk=assert(Editor.drag(draft,"Resize",Enum.NormalId.Right,-100))
 check(shrunk.HitboxWidth>0 and math.abs(shrunk.HitboxWidth-.05)<.00001,"AC02 Handle clamps only dragged dimension to positive minimum")
 local tiny=table.clone(base); tiny.HitboxWidth=.001; tiny.HitboxHeight=.002; tiny.Range=.003
 local tinyDraft=assert(Editor.newDraft(tiny))
 check(tinyDraft.HitboxWidth==.001 and tinyDraft.HitboxHeight==.002 and tinyDraft.Range==.003,"AC02 Opening preserves existing smaller positive dimensions")
 for _,bad in {0/0,math.huge,-math.huge} do check(Editor.drag(draft,"Move",Enum.NormalId.Right,bad)==nil,"AC02 Nonfinite drag rejected") end
 check(Editor.drag(draft,"Rotate",Enum.NormalId.Right,1)==nil,"AC02 Unsupported drag mode refused")
 local moved=assert(Editor.drag(oriented,"Move",Enum.NormalId.Right,2))
 moved=assert(Editor.drag(moved,"Move",Enum.NormalId.Top,-1))
 moved=assert(Editor.drag(moved,"Move",Enum.NormalId.Front,1))
 local caster=Instance.new("Model")
 local casterRoot=Instance.new("Part"); casterRoot.Name="HumanoidRootPart"; casterRoot.CFrame=root; casterRoot.Parent=caster
 local expectedCenter,expectedSize=Editor.transform(root,moved)
 local observedCenter,observedSize
 local hitbox={Box=function(cframe,dimensions)
  observedCenter=cframe; observedSize=dimensions
  return {Cast=function() return {} end,Destroy=function() end}
 end}
 local marker={}
 local ok,failure=pcall(function()
  local skill,shared=linkedModule("Templates/MeleeSkill.luau",{RunService={IsServer=function() return true end}},{[marker]=hitbox})
  for key,value in moved do shared[key]=value end
  local captured=assert(skill.GetConfig())
  shared.HitboxRotationX=170; shared.HitboxRotationY=75; shared.HitboxRotationZ=-23
  skill.Cast(caster,nil,function() return true end,captured)
  check(near(observedCenter.Position,expectedCenter.Position) and near(observedCenter.LookVector,expectedCenter.LookVector) and near(observedCenter.UpVector,expectedCenter.UpVector) and observedSize==expectedSize,"AC04 Actual runtime matches editor transform under rotated root and nonzero offsets")
  shared.HitboxRotationX=nil; shared.HitboxRotationY=nil; shared.HitboxRotationZ=nil
  local noRotation=assert(skill.GetConfig())
  check((noRotation.HitboxRotationX or 0)==0 and (noRotation.HitboxRotationY or 0)==0 and (noRotation.HitboxRotationZ or 0)==0,"AC04 Legacy absent rotation captured as identity")
  shared.HitboxRotationX=1
  check(skill.GetConfig()==nil,"AC04 Runtime rejects partial rotations")
  shared.HitboxRotationX=math.huge; shared.HitboxRotationY=0; shared.HitboxRotationZ=0
  check(skill.GetConfig()==nil,"AC04 Runtime rejects nonfinite rotation")
  shared.HitboxRotationX=nil; shared.HitboxRotationY=nil; shared.HitboxRotationZ=nil
  shared.HitboxOffsetX=nil; shared.HitboxOffsetY=nil; shared.HitboxOffsetZ=nil
  local old=assert(skill.GetConfig())
  check(old.HitboxOffsetX==0 and old.HitboxOffsetY==0 and old.HitboxOffsetZ==0,"AC04 Old all-absent offsets capture as zero")
  shared.HitboxOffsetX=1
  check(skill.GetConfig()==nil,"AC04 Runtime rejects partially specified offset triple")
 end)
 caster:Destroy(); assert(ok,failure)
 return tostring(count).." visual hitbox geometry assertions passed (pure transforms and actual runtime source)"
end
