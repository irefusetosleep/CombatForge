-- PROJECTILE-TRAJECTORY-01: independent analytic sampling and runtime ordered sweeps.
return function(T,Config,linkedModule)
 local count=0
 local function check(v,m)assert(v,m);count+=1 end
 local function near(a,b)return (a-b).Magnitude<.0002 end
 local config={Name="Curve",Damage=20,Cooldown=.75,Range=100,AnimationId="",HitDelay=0,ProjectileSpeed=20,ProjectileRadius=.5,ProjectileLifetime=10,AimMode="Body"}
 local resolved=assert(T.resolve(config))
 check(resolved.ProjectileTrajectory=="Straight" and resolved.ProjectileControlX==0 and resolved.ProjectileControlY==10 and resolved.ProjectileControlZ==0,"AC01 Legacy defaults resolved in memory")
 local parsed=assert(Config.parse(Config.serialize(config)));check(parsed.ProjectileTrajectory==nil and parsed.ProjectileControlX==nil,"AC01 Opening/ordinary serialization preserves legacy absence")
 local curve=table.clone(config);curve.ProjectileTrajectory="Bezier";curve.ProjectileControlX=12;curve.ProjectileControlY=25;curve.ProjectileControlZ=-8
 check(Config.parse(Config.serialize(curve)).ProjectileControlZ==-8,"AC01 Signed control triple roundtrip")
 for mask=1,6 do
  local bad=table.clone(config);bad.ProjectileTrajectory="Bezier"
  if bit32.band(mask,1)~=0 then bad.ProjectileControlX=0 end;if bit32.band(mask,2)~=0 then bad.ProjectileControlY=10 end;if bit32.band(mask,4)~=0 then bad.ProjectileControlZ=0 end
  check(Config.validateConfig(bad)==nil and T.resolve(bad)==nil,"AC01 Partial Bezier controls rejected")
 end
 for _,mode in {false,1,"Quadratic","Unknown"} do local bad=table.clone(curve);bad.ProjectileTrajectory=mode;check(Config.validateConfig(bad)==nil and T.resolve(bad)==nil,"AC01 Invalid mode rejected")end
 for _,key in {"ProjectileControlX","ProjectileControlY","ProjectileControlZ"} do for _,value in {0/0,math.huge,-math.huge,10001,-10001,"1"}do local bad=table.clone(curve);bad[key]=value;check(Config.validateConfig(bad)==nil and T.resolve(bad)==nil,"AC01 Bounded finite controls")end end
 local melee={Name="Melee",Damage=20,Cooldown=.75,Range=6,AnimationId="",HitDelay=0,HitboxWidth=5,HitboxHeight=5,ProjectileTrajectory="Straight"}
 check(not Config.isMelee(melee),"AC01 Trajectory fields exclude melee eligibility")
 local origin=Vector3.new(7,3,-11);local root=CFrame.new(origin)*CFrame.Angles(.3,.8,-.4)
 for _,direction in {root.LookVector,Vector3.yAxis,-Vector3.yAxis,Vector3.new(.2,.9,-.4).Unit} do
  local frame=assert(T.frame(origin,direction,Vector3.yAxis))
  check(near(frame.forward,direction) and math.abs(frame.right:Dot(frame.up))<.00001 and math.abs(frame.up:Dot(direction))<.00001 and math.abs(frame.right.Magnitude-1)<.00001,"AC02 Deterministic orthonormal aim frame including vertical fallback")
  local again=assert(T.frame(origin,direction,Vector3.yAxis));check(near(frame.right,again.right) and near(frame.up,again.up),"AC02 Repeated aim frame deterministic")
  local path=assert(T.build(curve,origin,direction,Vector3.yAxis))
  check(#path.points==129 and #path.distances==129,"AC02 Fixed128 intervals bound129points")
  local control=origin+direction*curve.Range/2+frame.right*12+frame.up*25+direction*(-8)
  local cumulative=0
  for index=1,129 do
   local t=(index-1)/128;local expected=origin*(1-t)^2+control*(2*(1-t)*t)+(origin+direction*100)*t^2
   check(near(path.points[index],expected),"AC02 Quadratic samples match independent polynomial")
   if index>1 then cumulative+=(path.points[index]-path.points[index-1]).Magnitude end
   check(math.abs(path.distances[index]-cumulative)<.001,"AC02 Cumulative sampled chord distances")
  end
  check(path.length>100 and math.abs(path.limit-100)<.001,"AC02 Curved route truncated by traveled Range")
  local first=path.points[1];local nextPoint=path.points[2];local half=(nextPoint-first).Magnitude/2
  check(near(T.position(path,half),(first+nextPoint)/2),"AC02 Distance lookup interpolates chord not raw parameter")
  local portions=assert(T.advance(path,0,path.limit));check(#portions<=256,"AC02 Bounded ordered portions")
  local total=0;local cursor=origin
  for _,part in portions do
   check(near(part.origin,cursor) and part.length<=1024.0001 and math.abs(part.direction.Magnitude-part.length)<.001,"AC02 Ordered contiguous bounded sweeps")
   total+=part.length;cursor=part.finish
  end
  check(math.abs(total-100)<.001 and near(cursor,T.position(path,100)),"AC02 Advance covers exact traveled prefix")
  local step=assert(T.step(path,0,0,.125,20,10));check(math.abs(step.distance-2.5)<.00001 and near(step.position,T.position(path,2.5)),"AC02 Speed distance based")
  local final=assert(T.step(path,0,0,10,20,.2));check(math.abs(final.distance-4)<.00001 and final.done,"AC02 Lifetime partial frame bounds travel")
 end
 local highConfig=table.clone(config);highConfig.Range=1000;highConfig.ProjectileSpeed=1
 local highPath=assert(T.build(highConfig,Vector3.new(1e8,0,0),Vector3.xAxis,Vector3.yAxis))
 local tinyPortions=assert(T.advance(highPath,0,.001))
 for _,part in tinyPortions do check(part.direction.Magnitude>0 and part.direction.X==part.direction.X,"AC04 High-coordinate subresolution progress never emits zero/NaN sweep")end
 local tinyStep=assert(T.step(highPath,0,0,.001,1,10));check(tinyStep.distance==.001 and tinyStep.position.X==tinyStep.position.X,"AC02 Quantized zero displacement still bounded logical progress")
 local straight=assert(T.build(config,origin,Vector3.zAxis,Vector3.yAxis))
 check(near(T.position(straight,100),origin+Vector3.zAxis*100),"AC02 Legacy Straight endpoint")
 for _,bad in {0/0,math.huge,-math.huge,-1}do check(T.step(straight,0,0,bad,20,10)==nil,"AC04 Invalid dt fails safely")end
 check(T.frame(origin,Vector3.zero,Vector3.yAxis)==nil,"AC02 Zero aim rejected")
 local zeroChord={points={origin,origin,origin+Vector3.zAxis*10},distances={0,0,10},length=10,limit=10}
 check(near(T.position(zeroChord,5),origin+Vector3.zAxis*5) and #assert(T.advance(zeroChord,2,7))==1,"AC02 Zero-length sampled chords skipped safely")
 local enormous=table.clone(config);enormous.Range=1000000;enormous.ProjectileSpeed=1000000
 local hugePath=assert(T.build(enormous,origin,Vector3.zAxis,Vector3.yAxis))
 local portions=assert(T.advance(hugePath,0,4096));check(#portions==4,"AC04 Straight frame splits into <=1024 sweeps")
 check(T.advance(hugePath,0,1000000)==nil,"AC04 Work over256 budget fails whole frame without skipping")
 -- Actual runtime gets the same helper via real nested module in harness.
 local caster=Instance.new("Model");local casterRoot=Instance.new("Part");casterRoot.Name="HumanoidRootPart";casterRoot.CFrame=root;casterRoot.Parent=caster
 local victim=Instance.new("Model");local humanoid=Instance.new("Humanoid");humanoid.Parent=victim;local victimPart=Instance.new("Part");victimPart.Parent=victim
 local casts,visuals,destroyed={}, {},0
 local hitAt,throwQuery,cancelAfterWait=3,false,false
 local hitAtActualEnd,onWait=false,nil
 local valid=true
 local skill,shared=linkedModule("Templates/ProjectileSkill.luau",{RunService={IsServer=function()return true end,Heartbeat={Wait=function()if onWait then local hook=onWait;onWait=nil;hook()end;if cancelAfterWait then valid=false end;return 1 end}},Debris={AddItem=function()end}},nil,
  {workspace={GetPartsInPart=function()return {}end,Spherecast=function(_,position,radius,delta)
   if throwQuery then error("Query failure")end
   table.insert(casts,{origin=position,radius=radius,delta=delta})
   if hitAt and #casts==hitAt then return {Instance=victimPart,Distance=if hitAtActualEnd then delta.Magnitude else delta.Magnitude/2,Position=Vector3.new(999,999,999)}end
   return nil
  end},RaycastParams={new=function()return {}end},OverlapParams={new=function()return {}end},Instance={new=function()local visual={Destroy=function()destroyed+=1 end};table.insert(visuals,visual);return visual end}})
 local ok,problem=pcall(function()
  for key,value in curve do shared[key]=value end
  local captured=assert(skill.GetConfig());local path=assert(T.build(captured,root.Position,root.LookVector,root.UpVector))
  local expected=assert(T.advance(path,0,20))
  onWait=function()casterRoot.CFrame=CFrame.new(999,7,31);shared.ProjectileControlX=9999 end
  skill.Cast(caster,nil,function()return valid end,captured)
  check(#casts==3 and humanoid.Health==80 and destroyed==1,"AC04 Curved sweep stops first impact and damages once")
  for i=1,3 do check(near(casts[i].origin,expected[i].origin) and near(casts[i].delta,expected[i].direction) and casts[i].radius==.5,"AC04 Runtime follows shared ordered curve portions")end
  local last=casts[3];check(near(visuals[1].Position,last.origin+last.delta.Unit*(last.delta.Magnitude/2)),"AC04 Impact center uses distance not surface hit.Position")
  casterRoot.CFrame=CFrame.new(1e8,0,0)*CFrame.Angles(0,-math.pi/2,0)
  for key,value in config do shared[key]=value end;shared.Range=1000;shared.ProjectileSpeed=60
  casts={};hitAt=1;hitAtActualEnd=true
  local rounded=assert(skill.GetConfig());skill.Cast(caster,nil,function()return true end,rounded)
  check(#casts==1 and math.abs(casts[1].delta.Magnitude-60)<9 and visuals[#visuals].Position.X==visuals[#visuals].Position.X and humanoid.Health==60,"AC04 Impact at actual rounded cast length remains valid")
  hitAtActualEnd=false;casterRoot.CFrame=root
  casts={};hitAt=nil;shared.Range=1000000;shared.ProjectileSpeed=1000000;shared.ProjectileTrajectory="Straight";shared.ProjectileLifetime=3
  local oversized=assert(skill.GetConfig())
  check(not pcall(skill.Cast,caster,nil,function()return true end,oversized) and #casts==0 and destroyed==3,"AC04 Budget failure stops before sweeping any partial frame and cleans visual")
  for key,value in curve do shared[key]=value end
  casts={};hitAt=nil;cancelAfterWait=true;valid=true
  skill.Cast(caster,nil,function()return valid end,captured);check(#casts==0 and destroyed==4,"AC04 Cancellation before swept work cleans visual")
  cancelAfterWait=false;valid=true;throwQuery=true
  check(not pcall(skill.Cast,caster,nil,function()return true end,captured) and destroyed==5,"AC04 Query failure cleans visual")
  throwQuery=false;casts={};shared.AimMode="Mouse";shared.ProjectileSpeed=20;local mouseConfig=assert(skill.GetConfig())
  hitAt=1;skill.Cast(caster,root.Position+Vector3.yAxis*100,function()return true end,mouseConfig)
  local mousePath=assert(T.build(mouseConfig,root.Position,Vector3.yAxis,root.UpVector))
  local mouseExpected=assert(T.advance(mousePath,0,20));check(near(casts[1].delta,mouseExpected[1].direction),"AC04 Mouse aim rotates authored curve with deterministic vertical frame")
 end)
 caster:Destroy();victim:Destroy();assert(ok,problem)
 return tostring(count).." projectile trajectory schema/math/runtime assertions passed"
end
