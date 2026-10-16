-- TEMPLATE-ALL-CONFIG-03: pure literal parsing plus isolated editor preservation.
return function(Config,loadManager)
 local count=0
 local function check(value,message) assert(value,message); count+=1 end
 local common={Name="AllSettings",Damage=20,Cooldown=0,Range=12}
 local advanced={HitboxWidth=9,HitboxHeight=7,AnimationId="",HitDelay=.2,ProjectileSpeed=35,ProjectileRadius=2,ProjectileLifetime=4,AimMode="Body"}
 local full=table.clone(common); for key,value in advanced do full[key]=value end
 local function roundtrip(value)
  local source=Config.serialize(value)
  local parsed=assert(Config.parse(source))
  for key,expected in value do check(parsed[key]==expected,"AC02 Round-trip "..key) end
  for key in parsed do check(value[key]~=nil,"AC02 No unrequested field "..key) end
  return source
 end
 roundtrip(common); roundtrip(full)
 check(Config.parse("return {Name='Comment',Damage=20--adjacent\n,Cooldown=0,Range=1}")~=nil,"AC02 Numeric token permits adjacent line comment")
 check(Config.parse("--[label] a normal line comment\nreturn {Name='Comment',Damage=20,Cooldown=0,Range=1}")~=nil,"AC02 Bracket label is ordinary line comment")
 check(Config.parse("--[[long comment]] return {Name='Comment',Damage=20,Cooldown=0,Range=1}")==nil,"AC02 Unsupported long comment refused")
 check(Config.parse("--[=[long comment]=]\nreturn {Name='Comment',Damage=20,Cooldown=0,Range=1}")==nil,"AC02 Unsupported equals long comment refused")
 for _,bad in {0/0,math.huge,-math.huge} do
  for _,key in {"Damage","Cooldown","Range","HitboxWidth","HitboxHeight","ProjectileSpeed","ProjectileRadius","ProjectileLifetime","HitDelay"} do
   local config=table.clone(full); config[key]=bad
   check(Config.validateConfig(config)==nil,"AC02 Typed nonfinite rejected "..key)
  end
 end
 for _,value in {"rbxassetid://123",[[data -- comma, semi; braces{} "double" 'single' slash\]],[["}; error('must not execute'); --]],string.rep("a",1024)} do
  local config=table.clone(common); config.AnimationId=value; roundtrip(config)
 end
 local prefix="return {Name='Literal',Damage=0,Cooldown=0,Range=1,"
 local function parseField(field, literal) return Config.parse(prefix..field.."="..literal.."}") end
 for _,entry in {{"HitboxWidth","0.001"},{"HitboxHeight","1e2"},{"ProjectileSpeed","2.5"},{"ProjectileRadius","256"},{"ProjectileLifetime","60"},{"HitDelay","0"},{"HitDelay","30"},{"AimMode",[["Mouse"]]},{"AimMode",[['Body']]} } do
  check(parseField(entry[1],entry[2])~=nil,"AC02 Accept supported boundary "..entry[1]..entry[2])
 end
 for _,entry in {{"HitboxWidth","0"},{"HitboxHeight","-1"},{"ProjectileSpeed","0"},{"ProjectileRadius","256.001"},{"ProjectileRadius","0"},{"ProjectileLifetime","60.01"},{"ProjectileLifetime","0"},{"HitDelay","-0.1"},{"HitDelay","30.01"},{"AimMode",[['mouse']]},{"AnimationId","123"},{"HitboxWidth",[['5']]},{"ProjectileSpeed","1e309"},{"HitDelay","true"}} do
  check(parseField(entry[1],entry[2])==nil,"AC02 Reject invalid field domain/type "..entry[1]..entry[2])
 end
 for byte=0,31 do check(parseField("AnimationId",'"a'..string.char(byte)..'b"')==nil,"AC02 Reject ASCII control "..byte) end
 check(parseField("AnimationId",'"a'..string.char(127)..'b"')==nil,"AC02 Reject DEL")
 check(parseField("AnimationId",'"'..string.rep("a",1025)..'"')==nil,"AC02 AnimationId maximum byte length")
 local quoted=assert(Config.parse([=[-- outside comment
 return { Name="Literal"; Damage=20, Cooldown=0; Range=1,
 AnimationId='one -- data, ; {} "quoted" \'single\' \\ tail', -- actual comment
 AimMode="Body" } -- outside comment
 ]=]))
 check(quoted.AnimationId==[[one -- data, ; {} "quoted" 'single' \ tail]],"AC02 Quote-aware scanner preserves punctuation/backslash data")
 local double=assert(parseField("AnimationId",[=["double \" quote \\ slash 'single' -- ; , {} "]=]))
 check(double.AnimationId==[[double " quote \ slash 'single' -- ; , {} ]],"AC02 Escaped double quote/backslash decoded exactly")
 for _,source in {
  prefix..[[AnimationId="bad\n"}]],prefix..[[AnimationId="bad\q"}]],prefix..[[AnimationId="unfinished}]],
  prefix..[[AnimationId='broken\'}]],prefix..[[AnimationId="a".."b"}]],prefix..[[AnimationId=string.char(65)}]],
  prefix..[[AnimationId={}}]],prefix..[[Extra=1}]],prefix..[[AimMode="Body",AimMode="Mouse"}]],
  prefix..[[Damage=22}]],prefix..[[HitDelay=math.random()}]],prefix..[[HitDelay=(1)}]],
  prefix..[[HitDelay=1+2}]],prefix..[[["HitDelay"]=1}]],prefix..[=[AnimationId=[[x]]}]=],
  prefix..[[AnimationId="safe"}; error("never execute")]],prefix..[[AnimationId="safe"}()]],
  [[return setmetatable({}, {})]],[[return {Name='Bad Name',Damage=1,Cooldown=0,Range=1}]],
 } do check(Config.parse(source)==nil,"AC02 Refuse unsupported syntax without evaluation") end
 local storage=Instance.new("Folder")
 local root=Instance.new("Folder"); root.Name="CombatForge"; root.Parent=storage
 local abilities=Instance.new("Folder"); abilities.Name="Abilities"; abilities.Parent=root
 local target=Instance.new("ModuleScript"); target.Name=full.Name; target.Source=Config.serialize(full); target.Parent=abilities
 local manager=loadManager({ReplicatedStorage=storage,RunService={IsRunning=function() return false end},
  ScriptEditorService={GetEditorSource=function(_,item) return item.Source end,UpdateSourceAsync=function(_,item,callback) local source=callback(item.Source); if source then item.Source=source end end},
  ChangeHistoryService={TryBeginRecording=function() return "recording" end,FinishRecording=function() end},
 })
 local ok,failure=pcall(function()
  local snapshot=assert(manager.read(target))
  snapshot.config.HitDelay=29; snapshot.config.AnimationId="mutated snapshot must not be authority"
  check(manager.update(snapshot,{Name="PreservedAdvanced",Damage="31",Cooldown="0",Range="22"}),"AC03 Common controls update extended config")
  local saved=assert(Config.parse(target.Source))
  check(saved.Name=="PreservedAdvanced" and saved.Damage==31 and saved.Range==22 and saved.Cooldown==0,"AC03 Common edits and rename applied")
  for key,value in advanced do check(saved[key]==value,"AC03 Preserve advanced field "..key) end
  local previous=target.Source
  check(not manager.update(snapshot,{Name="Stale",Damage="1",Cooldown="0",Range="1"}) and target.Source==previous,"AC03 Stale snapshot preserves extended config")
  target.Source=Config.serialize(common); target.Name=common.Name
  check(manager.update(assert(manager.read(target)),{Name="LegacyRenamed",Damage="5",Cooldown="0",Range="3"}),"AC03 Legacy four-field update remains supported")
  local legacy=assert(Config.parse(target.Source))
  local keys=0; for _ in legacy do keys+=1 end
  check(keys==4,"AC03 Legacy optional absence remains absent")
  target.Source=Config.serialize(full).."\nerror('must never execute')"
  local original=target.Source
  check(manager.read(target)==nil and target.Source==original,"AC03 Unsupported source remains intact without evaluation")
 end)
 storage:Destroy(); assert(ok,failure)
 return tostring(count).." all-config schema/editor assertions passed (literal parser; isolated services)"
end
