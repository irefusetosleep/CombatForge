-- VH07 independent preference validation and checked persistence.
return function(Keys)
 local count=0
 local function check(v,m) assert(v,m); count+=1 end
 local defaults=Keys.defaults()
 for action,key in {TogglePreview="P",Move="M",Resize="S",Rotate="R",Undo="Z"} do check(Keys.format(defaults[action])=="Ctrl+Alt+"..key,"AC01 Default "..action) end
 check(Keys.validate(defaults)~=nil,"AC01 Defaults valid")
 for _,key in {"A","Z","0","9"} do for _,ctrl in {false,true} do for _,alt in {false,true} do
  if not (ctrl and not alt and key=="Z") then
   local chord=assert(Keys.chord(key,ctrl,alt,false))
   check(Keys.matches(chord,key,ctrl,alt,false),"AC01 Exact valid chord")
   check(not Keys.matches(chord,key,not ctrl,alt,false) and not Keys.matches(chord,key,ctrl,alt,true),"AC01 Extra/missing modifiers rejected")
  end
 end end end
 for _,key in {"Unknown","Escape","LeftShift","RightControl","MouseButton1","ButtonA","a","F1","","10"} do check(Keys.chord(key,false,false,false)==nil,"AC01 Invalid key "..key) end
 check(Keys.chord("Z",true,false,false)==nil and Keys.chord("Y",true,false,false)==nil,"AC01 Native Undo/Redo reserved")
 check(Keys.chord("A",false,false,true)==nil,"AC01 Shift reserved")
 local candidate=Keys.defaults(); candidate.Move=table.clone(candidate.Rotate)
 check(Keys.validate(candidate)==nil,"AC01 Duplicate chord rejected")
 candidate=Keys.defaults(); candidate.Extra=false; check(Keys.validate(candidate)==nil,"AC01 Unknown action rejected")
 candidate=Keys.defaults(); candidate.Move=nil; check(Keys.validate(candidate)==nil,"AC01 Missing action rejected")
 candidate=Keys.defaults(); candidate.Move={key="A",ctrl=false,alt=false,shift=false}; check(Keys.validate(candidate)==nil,"AC01 Unknown chord field rejected")
 local stored,reads,writes=nil,0,0
 local failRead,failWrite,mismatch=false,false,false
 local theme={mode="Custom",accent="ABCDEF"}
 local plugin={GetSetting=function(_,key)
  check(key=="CombatForgeKeybindsV1","AC01 Dedicated safe setting key")
  reads+=1; if failRead then error("read failed") end
  if mismatch and stored then return {version=1,bindings=Keys.defaults()} end
  return stored
 end,SetSetting=function(_,key,value)
  check(key=="CombatForgeKeybindsV1","AC01 No theme or Studio shortcut setting mutation")
  writes+=1; if failWrite then error("write failed") end; stored=value
 end}
 local api=Keys.new(plugin)
 check(api.getError()==nil,"AC01 Missing storage loads defaults")
 check(api.set("Move",assert(Keys.chord("7",false,true,false))),"AC01 Persist changed chord")
 check(stored.version==1 and stored.bindings.Move.key=="7" and Keys.new(plugin).get().Move.key=="7","AC01 Reload new lifetime")
 local copy=api.get(); copy.Move.key="X"; check(api.get().Move.key=="7","AC01 Caller cannot mutate active binding")
 failWrite=true; check(not api.set("Move",false) and api.get().Move.key=="7","AC01 Failed write keeps active previous binding"); failWrite=false
 mismatch=true; check(not api.set("Move",false) and api.get().Move.key=="7","AC01 Failed readback keeps active previous binding"); mismatch=false
 check(api.set("Move",false) and api.get().Move==false and Keys.format(false)=="Unassigned","AC01 Clear persists")
 check(api.reset() and Keys.format(api.get().Move)=="Ctrl+Alt+M","AC01 Reset group defaults")
 check(theme.mode=="Custom" and theme.accent=="ABCDEF","AC01 Theme data retained")
 for _,bad in {false,{}, {version=2,bindings=defaults},{version=1,bindings={Move=false}}} do
  stored=bad; local loaded=Keys.new(plugin)
  check(loaded.getError()~=nil and Keys.format(loaded.get().Move)=="Ctrl+Alt+M","AC01 Corrupt storage falls back with error")
 end
 failRead=true; local loaded=Keys.new(plugin); check(loaded.getError()~=nil and loaded.get().Move.key=="M","AC01 Read failure defaults safely")
 return tostring(count).." keybind preference assertions passed"
end
