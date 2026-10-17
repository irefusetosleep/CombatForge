-- VISUAL-HITBOX-05 AC03/04: complete optional finite signed offset triples.
return function(Config)
 local count=0
 local function check(value,message) assert(value,message); count+=1 end
 local base={Name="OffsetMelee",Damage=20,Cooldown=.75,Range=6,AnimationId="",HitDelay=0,HitboxWidth=5,HitboxHeight=5}
 check(Config.validateConfig(base)~=nil,"AC04 All absent offsets retain legacy compatibility")
 local absent=assert(Config.parse(Config.serialize(base)))
 check(absent.HitboxOffsetX==nil and absent.HitboxOffsetY==nil and absent.HitboxOffsetZ==nil,"AC04 General schema preserves optional absence")
 for _,values in {{0,0,0},{-3,4.25,-8},{1e90,-1e90,.000001}} do
  local full=table.clone(base)
  full.HitboxOffsetX=values[1]; full.HitboxOffsetY=values[2]; full.HitboxOffsetZ=values[3]
  local parsed=assert(Config.parse(Config.serialize(full)))
  check(parsed.HitboxOffsetX==values[1] and parsed.HitboxOffsetY==values[2] and parsed.HitboxOffsetZ==values[3],"AC04 Complete signed offsets round-trip without arbitrary bounds")
 end
 for mask=1,6 do
  local partial=table.clone(base)
  if bit32.band(mask,1)~=0 then partial.HitboxOffsetX=0 end
  if bit32.band(mask,2)~=0 then partial.HitboxOffsetY=0 end
  if bit32.band(mask,4)~=0 then partial.HitboxOffsetZ=0 end
  check(Config.validateConfig(partial)==nil,"AC04 Partial offset triple rejected "..mask)
 end
 for _,key in {"HitboxOffsetX","HitboxOffsetY","HitboxOffsetZ"} do
  for _,bad in {0/0,math.huge,-math.huge,"2",false} do
   local full=table.clone(base); full.HitboxOffsetX=0; full.HitboxOffsetY=0; full.HitboxOffsetZ=0; full[key]=bad
   check(Config.validateConfig(full)==nil,"AC04 Invalid offset type/nonfinite rejected "..key)
  end
 end
 check(absent.HitboxRotationX==nil and absent.HitboxRotationY==nil and absent.HitboxRotationZ==nil,"AC04 Absent rotations preserved by schema")
 for _,values in {{0,0,0},{31,-47,19},{90,180,-270},{1e300,-1e300,.000001}} do
  local full=table.clone(base)
  full.HitboxRotationX=values[1]; full.HitboxRotationY=values[2]; full.HitboxRotationZ=values[3]
  local parsed=assert(Config.parse(Config.serialize(full)))
  check(parsed.HitboxRotationX==values[1] and parsed.HitboxRotationY==values[2] and parsed.HitboxRotationZ==values[3],"AC04 Finite degree rotations round-trip without arbitrary bounds")
 end
 for mask=1,6 do
  local partial=table.clone(base)
  if bit32.band(mask,1)~=0 then partial.HitboxRotationX=0 end
  if bit32.band(mask,2)~=0 then partial.HitboxRotationY=0 end
  if bit32.band(mask,4)~=0 then partial.HitboxRotationZ=0 end
  check(Config.validateConfig(partial)==nil,"AC04 Partial rotation triple rejected "..mask)
 end
 for _,key in {"HitboxRotationX","HitboxRotationY","HitboxRotationZ"} do
  for _,bad in {0/0,math.huge,-math.huge,"2",false} do
   local full=table.clone(base); full.HitboxRotationX=0; full.HitboxRotationY=0; full.HitboxRotationZ=0; full[key]=bad
   check(Config.validateConfig(full)==nil,"AC04 Invalid rotation type/nonfinite rejected "..key)
  end
 end
 return tostring(count).." visual hitbox offset schema assertions passed"
end
