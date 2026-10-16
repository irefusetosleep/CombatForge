-- VISUAL-HITBOX-04 AC01/02/04: pure editor math compared with actual melee Cast.
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
 for _,entry in {{Enum.NormalId.Right,"HitboxWidth",5},{Enum.NormalId.Left,"HitboxWidth",5},{Enum.NormalId.Top,"HitboxHeight",4},{Enum.NormalId.Bottom,"HitboxHeight",4},{Enum.NormalId.Front,"Range",6},{Enum.NormalId.Back,"Range",6}} do
  local resized=assert(Editor.drag(draft,"Resize",entry[1],2))
  check(resized[entry[2]]==entry[3]+4,"AC02 Resize face moves symmetrically around center")
  local resizedCenter=Editor.transform(root,resized)
  check(near(center.Position,resizedCenter.Position),"AC02 Resize preserves current box center")
 end
 local depth=assert(Editor.drag(draft,"Resize",Enum.NormalId.Front,2))
 check(depth.Range==10 and depth.HitboxOffsetZ==2,"AC02 Depth resize adjusts additive Z offset")
 local shrunk=assert(Editor.drag(draft,"Resize",Enum.NormalId.Right,-100))
 check(shrunk.HitboxWidth>0 and math.abs(shrunk.HitboxWidth-.05)<.00001,"AC02 Handle clamps only dragged dimension to positive minimum")
 local tiny=table.clone(base); tiny.HitboxWidth=.001; tiny.HitboxHeight=.002; tiny.Range=.003
 local tinyDraft=assert(Editor.newDraft(tiny))
 check(tinyDraft.HitboxWidth==.001 and tinyDraft.HitboxHeight==.002 and tinyDraft.Range==.003,"AC02 Opening preserves existing smaller positive dimensions")
 for _,bad in {0/0,math.huge,-math.huge} do check(Editor.drag(draft,"Move",Enum.NormalId.Right,bad)==nil,"AC02 Nonfinite drag rejected") end
 check(Editor.drag(draft,"Rotate",Enum.NormalId.Right,1)==nil,"AC02 Unsupported drag mode refused")
 local moved=assert(Editor.drag(draft,"Move",Enum.NormalId.Right,2))
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
  skill.Cast(caster,nil,function() return true end,assert(skill.GetConfig()))
  check(near(observedCenter.Position,expectedCenter.Position) and near(observedCenter.LookVector,expectedCenter.LookVector) and observedSize==expectedSize,"AC04 Actual runtime matches editor transform under rotated root and nonzero offsets")
  shared.HitboxOffsetX=nil; shared.HitboxOffsetY=nil; shared.HitboxOffsetZ=nil
  local old=assert(skill.GetConfig())
  check(old.HitboxOffsetX==0 and old.HitboxOffsetY==0 and old.HitboxOffsetZ==0,"AC04 Old all-absent offsets capture as zero")
  shared.HitboxOffsetX=1
  check(skill.GetConfig()==nil,"AC04 Runtime rejects partially specified offset triple")
 end)
 caster:Destroy(); assert(ok,failure)
 return tostring(count).." visual hitbox geometry assertions passed (pure transforms and actual runtime source)"
end
