-- VH08 independent snapping preferences and non-destructive runtime ensure.
return function(Prefs,loadRuntime)
 local count=0
 local function check(v,m)assert(v,m);count+=1 end
 local defaults=Prefs.defaults()
 check(defaults.enabled==false and defaults.move==1 and defaults.resize==1 and defaults.rotate==15,"AC04 Off/1/1/15 defaults")
 for _,key in {"move","resize","rotate"} do for _,bad in {0,-1,0/0,math.huge,-math.huge,"1",false} do
  local values=Prefs.defaults();values[key]=bad;check(Prefs.validate(values)==nil,"AC04 Positive finite increments "..key)
 end end
 local extra=Prefs.defaults();extra.other=1;check(Prefs.validate(extra)==nil,"AC04 Unknown field rejected")
 local stored,fail,mismatch=nil,false,false
 local plugin={GetSetting=function(_,key)check(key=="CombatForgeSnapV1","AC04 Independent settings key");if mismatch then return {version=1,values=Prefs.defaults()} end;return stored end,
  SetSetting=function(_,_,value)if fail then error("save failed") end;stored=value end}
 local api=Prefs.new(plugin);local changed={enabled=true,move=.125,resize=2.5,rotate=7.5}
 check(api.save(changed) and Prefs.new(plugin).get().rotate==7.5,"AC04 Persist/reload preferences")
 local copy=api.get();copy.move=99;check(api.get().move==.125,"AC04 Returned copy isolated")
 fail=true;check(not api.save(defaults) and api.get().enabled,"AC04 Failed write does not activate");fail=false
 mismatch=true;check(not api.save(changed) and api.get().move==.125,"AC04 Failed verification preserves active values");mismatch=false
 for _,bad in {false,{}, {version=2,values=changed},{version=1,values={enabled=true}}} do
  stored=bad;local loaded=Prefs.new(plugin);check(loaded.getError()~=nil and not loaded.get().enabled and loaded.get().move==1,"AC04 Corruption defaults with error")
 end
 local storage=Instance.new("Folder")
 local template=Instance.new("ModuleScript");template.Source="return {Version=8}"
 local begins,commits,cancels=0,0,0
 local running,allow,failCommit=false,true,false
 local runtime=loadRuntime({ReplicatedStorage=storage,RunService={IsRunning=function()return running end},ScriptEditorService={GetEditorSource=function(_,module)return module.Source end},
  ChangeHistoryService={TryBeginRecording=function()begins+=1;return if allow then "ensure" else nil end,FinishRecording=function(_,_,operation)
   if operation==Enum.FinishRecordingOperation.Commit then if failCommit then error("commit failed")end;commits+=1 else cancels+=1 end
  end}})
 local ok,problem=pcall(function()
  running=true;check(not runtime.ensure(template) and #storage:GetChildren()==0 and begins==0,"AC06 Play refuses without mutation/history");running=false
  allow=false;check(not runtime.ensure(template) and #storage:GetChildren()==0,"AC06 Missing recording leaves no folders");allow=true
  failCommit=true;check(not runtime.ensure(template) and #storage:GetChildren()==0 and cancels==1,"AC06 Commit failure rolls back all created objects");failCommit=false
  check(runtime.ensure(template) and storage.CombatForge.Runtime.Hitbox.Source==template.Source and commits==1,"AC06 Missing runtime created once")
  local module=storage.CombatForge.Runtime.Hitbox;local prior=begins
  check(runtime.ensure(template) and begins==prior,"AC06 Identical existing module has no recording")
  module.Source="return {Edited=true}";local custom=module.Source
  check(runtime.ensure(template) and module.Source==custom and begins==prior,"AC06 Existing edited source preserved verbatim without history")
  local twin=module:Clone();twin.Parent=module.Parent
  check(not runtime.ensure(template) and module.Source==custom and begins==prior,"AC06 Duplicate module conflict without mutation");twin:Destroy()
  local parent=module.Parent;module.Parent=nil
  local wrong=Instance.new("Folder");wrong.Name="Hitbox";wrong.Parent=parent
  check(not runtime.ensure(template) and wrong.Parent==parent and begins==prior,"AC06 Wrong-class collision preserved");wrong:Destroy();module.Parent=parent
  storage:ClearAllChildren()
  for _,path in {"CombatForge","Runtime"} do
   local root=Instance.new(if path=="CombatForge" then "StringValue" else "Folder");root.Name="CombatForge";root.Parent=storage
   if path=="Runtime" then local child=Instance.new("StringValue");child.Name="Runtime";child.Parent=root end
   prior=begins;check(not runtime.ensure(template) and begins==prior,"AC06 Folder collision protected "..path);storage:ClearAllChildren()
  end
 end)
 storage:Destroy();template:Destroy();assert(ok,problem)
 return tostring(count).." snapping preferences/runtime ensure assertions passed"
end
