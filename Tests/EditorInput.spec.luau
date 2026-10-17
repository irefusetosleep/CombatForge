-- VH07 actual mounted UI; isolated preferences/input events and controller.
return function(uiLoader,Keys,Theme,Config)
 local count=0
 local function check(v,m) assert(v,m);count+=1 end
 local running,focusedBox=false,false
 local runEntries={}
 local runSignal={Connect=function(_,fn)local e={fn=fn,active=true};table.insert(runEntries,e);return {Disconnect=function()e.active=false end} end,Fire=function()for _,e in runEntries do if e.active then e.fn() end end end}
 local held={}
 local ui,actions,services=uiLoader({UserInputService={GetFocusedTextBox=function()return if focusedBox then {} else nil end,IsKeyDown=function(_,key)return held[key]==true end},RunService={IsRunning=function()return running end,GetPropertyChangedSignal=function(_,name)check(name=="RunState","AC07 Watch Play transition");return runSignal end}})
 local input=services.UserInputService
 local function press(key,processed) held[key]=true; input.InputBegan:Fire({KeyCode=key},processed==true) end
 local function release(key) held[key]=nil;input.InputEnded:Fire({KeyCode=key},true) end
 local function tap(key,processed) press(key,processed);release(key) end
 local function chord(key) press(Enum.KeyCode.LeftControl);press(Enum.KeyCode.RightAlt);tap(key);release(Enum.KeyCode.RightAlt);release(Enum.KeyCode.LeftControl) end
 local host=Instance.new("ScreenGui");host.Enabled=true
 local module=Instance.new("ModuleScript");module.Name="InputSkill"
 local config={Name=module.Name,Damage=20,Cooldown=.75,Range=6,AnimationId="",HitDelay=0,HitboxWidth=5,HitboxHeight=5}
 local saveHook
 local manager={list=function()return {module} end,read=function()return {module=module,name=module.Name,source=Config.serialize(config),config=table.clone(config)} end,saveGeometry=function()if saveHook then saveHook() end;return false,"Expected conflict" end}
 local draft,state,changed,update,session,destroys,modes
 destroys=0;modes=0
 local capability={isSupported=Config.isMelee,start=function(_,onChanged,_,onState)
  draft={HitboxWidth=5,HitboxHeight=5,Range=6,HitboxOffsetX=0,HitboxOffsetY=0,HitboxOffsetZ=0,HitboxRotationX=0,HitboxRotationY=0,HitboxRotationZ=0}
  state={visible=true,mode="Preview",shiftHeld=false,space="Local",scaleMode="Axis",canUndo=false}
  changed=onChanged;update=onState
  session={getDraft=function()return table.clone(draft) end,getState=function()return table.clone(state) end,
   setMode=function(mode)modes+=1;state.mode=mode;onState(state);return true end,
   setShiftHeld=function(value)state.shiftHeld=value;state.space=if value then "Global" else "Local";state.scaleMode=if value then "Uniform" else "Axis";onState(state);return true end,
   setPreviewVisible=function(value)state.visible=value;state.mode="Preview";onState(state);return true end,
   undo=function()return false end,destroy=function()destroys+=1;state.visible=false;state.shiftHeld=false end}
  onChanged(draft);onState(state);return session,"Preview active"
 end}
 local stored,writes,fail=nil,0,false
 local keyprefs=Keys.new({GetSetting=function()return stored end,SetSetting=function(_,_,value)writes+=1;if fail then error("save rejected")end;stored=value end})
 local themeSettings={mode="Custom",background="112233",surface="334455",text="EEEEEE",accent="DDAA33"}
 local preferences={get=function()return table.clone(themeSettings) end,save=function(value)themeSettings=table.clone(value);return true,"Saved" end}
 local mounted
 local ok,problem=pcall(function()
  mounted=ui.mount(host,manager,preferences,nil,nil,nil,function()return true,"Created" end,capability,keyprefs)
  local root=host.CombatForgeRoot
  check(input.InputBegan.Count()==1 and input.InputEnded.Count()==1 and input.WindowFocused.Count()==1 and input.WindowFocusReleased.Count()==1,"AC02 One input owner per mount")
  actions.Settings()
  for _,action in Keys.actions do check(root:FindFirstChild("ChangeKeybind"..action) and root:FindFirstChild("ClearKeybind"..action) and root:FindFirstChild("Keybind"..action),"AC01 Five editable settings rows") end
  actions.ChangeKeybindMove();tap(Enum.KeyCode.Escape);tap(Enum.KeyCode.B)
  check(writes==0 and keyprefs.get().Move.key=="M","AC01 Escape cancels capture")
  actions.ChangeKeybindMove();tap(Enum.KeyCode.F1);check(writes==0,"AC01 Unsupported key rejected")
  tap(Enum.KeyCode.B);check(keyprefs.get().Move.key=="B" and writes==1,"AC01 Capture letter with optional no modifiers")
  actions.ChangeKeybindRotate();tap(Enum.KeyCode.B);check(writes==1 and keyprefs.get().Rotate.key=="R","AC01 Duplicate capture rejected")
  tap(Enum.KeyCode.Escape)
  fail=true;actions.ChangeKeybindMove();tap(Enum.KeyCode.C);check(keyprefs.get().Move.key=="B" and root.KeybindStatus.Text:find("save",1,true),"AC01 Persistence failure visible and active chord retained");fail=false
  tap(Enum.KeyCode.Escape)
  actions.ClearKeybindMove();check(keyprefs.get().Move==false and root.KeybindMove.Text:find("Unassigned",1,true),"AC01 Clear updates label")
  actions.ResetKeybinds();check(keyprefs.get().Move.key=="M" and themeSettings.accent=="DDAA33","AC01 Reset bindings only")
  actions.ChangeKeybindMove();local before=writes
  running=true;runSignal.Fire();tap(Enum.KeyCode.D)
  check(writes==before,"AC07 Play transition cancels settings capture before key save")
  running=false;runSignal.Fire();tap(Enum.KeyCode.E)
  check(writes==before,"AC07 Capture stays canceled after Play")
  actions.ChangeKeybindMove();input.WindowFocusReleased:Fire();tap(Enum.KeyCode.F)
  check(writes==before,"AC07 Focus loss cancels capture");input.WindowFocused:Fire()
  actions.ChangeKeybindMove();actions.Home();tap(Enum.KeyCode.G);check(writes==before,"AC01/04 Navigation cancels capture")
  check(root:FindFirstChild("CreateNewSkill")~=nil,"AC04 Settings Home returns root")
  actions.UpdateSkills();actions.Skill1();actions.EditHitbox()
  check(root:FindFirstChild("HitboxScaleAxis")==nil and root:FindFirstChild("HitboxScaleUniform")==nil,"AC05 Scale buttons removed")
  chord(Enum.KeyCode.M);check(state.mode=="Move","AC02 RightAlt LeftCtrl normalized chord dispatch")
  press(Enum.KeyCode.LeftControl);press(Enum.KeyCode.LeftAlt);press(Enum.KeyCode.M);press(Enum.KeyCode.M)
  check(state.mode=="Preview","AC02 Physical repeat invokes once")
  release(Enum.KeyCode.M);release(Enum.KeyCode.LeftAlt);release(Enum.KeyCode.LeftControl)
  press(Enum.KeyCode.LeftControl);tap(Enum.KeyCode.M);release(Enum.KeyCode.LeftControl);check(state.mode=="Preview","AC02 Missing modifier does not match")
  press(Enum.KeyCode.LeftControl);press(Enum.KeyCode.LeftAlt);tap(Enum.KeyCode.M,true);release(Enum.KeyCode.LeftAlt);release(Enum.KeyCode.LeftControl);check(state.mode=="Preview","AC02 Processed input ignored")
  focusedBox=true;chord(Enum.KeyCode.M);check(state.mode=="Preview","AC02 Text input excludes dispatch");focusedBox=false
  saveHook=function()chord(Enum.KeyCode.M);check(state.mode=="Preview","AC02 Busy save excludes dispatch")end
  actions.SaveHitbox();saveHook=nil
  press(Enum.KeyCode.LeftShift);check(state.shiftHeld and state.scaleMode=="Uniform","AC05 LeftShift modifier forwarded")
  release(Enum.KeyCode.LeftShift);press(Enum.KeyCode.RightShift);check(state.shiftHeld,"AC05 RightShift modifier forwarded")
  input.WindowFocusReleased:Fire();check(not state.shiftHeld,"AC07 Focus loss resets Shift")
  held[Enum.KeyCode.RightShift]=nil;input.WindowFocused:Fire();check(not state.shiftHeld,"AC07 Focus regain no stale latch")
  running=true;runSignal.Fire();press(Enum.KeyCode.LeftShift);check(not state.shiftHeld,"AC07 Shift press during Play cannot relatch")
  release(Enum.KeyCode.LeftShift);chord(Enum.KeyCode.M);check(state.mode=="Preview","AC02 Play action guarded")
  running=false;runSignal.Fire()
  draft.HitboxWidth=7;state.canUndo=true;changed(draft);update(state)
  actions.Back();check(root.DiscardPrompt.Visible,"AC04 Dirty visual Back prompts")
  local countModes=modes;chord(Enum.KeyCode.M);check(modes==countModes,"AC02 Discard prompt blocks shortcuts")
  actions.KeepEditing();check(draft.HitboxWidth==7 and state.canUndo and state.visible,"AC04 Keep preserves exact draft/history/render")
  actions.Home();actions.DiscardChanges();check(root:FindFirstChild("CreateNewSkill") and destroys==1,"AC04 Visual Home discard reaches root and cleans")
  actions.UpdateSkills();actions.Skill1();actions.EditHitbox();actions.Back();check(root:FindFirstChild("DamageInput"),"AC04 Clean visual Back reaches selected form")
  root.DamageInput.Text="21";task.wait();actions.Home();check(root.DiscardPrompt.Visible,"AC04 Dirty common Home prompts")
  actions.KeepEditing();check(root.DamageInput.Text=="21","AC04 Keep common form")
  actions.Home();actions.DiscardChanges();check(root:FindFirstChild("CreateNewSkill"),"AC04 Common Home discard targets root")
  actions.UpdateSkills();actions.Skill1();actions.Back();check(root:FindFirstChild("SkillRow1"),"AC04 Common Back targets list")
  actions.Back();check(root:FindFirstChild("CreateNewSkill"),"AC04 List Back root")
  for _,mode in {"Dark","Light","Custom"} do
   themeSettings.mode=mode
   actions.UpdateSkills();local palette=Theme.palette(themeSettings)
   check(root.SkillRow1.Skill1.BackgroundColor3==palette.surface and root.SkillRow1.Skill1.TextColor3==palette.text,"AC03 List uses palette "..mode)
   actions.Skill1();actions.EditHitbox()
   check(root.ToggleHitboxPreview.BackgroundColor3==palette.accent and root.ToggleHitboxPreview.TextColor3==palette.accentText and root.HitboxMove.BackgroundColor3==palette.surface and root.HitboxMove.TextColor3==palette.text,"AC03 Editor palette roles "..mode)
   actions.HitboxMove();check(root.HitboxMove.BackgroundColor3==palette.accent and root.HitboxResize.BackgroundColor3==palette.surface,"AC03 Selected mode palette "..mode)
   actions.CancelHitbox();actions.Home()
  end
  actions.Settings();actions.Back();actions.Settings();actions.Home()
  check(input.InputBegan.Count()==1,"AC02 Reopen Settings/pages do not multiply listeners")
  mounted.destroy();check(input.InputBegan.Count()==0 and input.InputEnded.Count()==0 and input.WindowFocused.Count()==0 and input.WindowFocusReleased.Count()==0,"AC07 Dispose all input connections")
  for _,entry in runEntries do check(not entry.active,"AC07 RunState watcher disposed") end
 end)
 if mounted then mounted.destroy() end;host:Destroy();module:Destroy()
 assert(ok,problem)
 return tostring(count).." editor input/settings/navigation/theme assertions passed"
end
