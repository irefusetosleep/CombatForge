-- Supply a loader for Main with the mocked plugin/modules below.
return function(loadMain)
 local count = 0
 local function check(value, message) assert(value, message); count += 1 end
 local function signal()
  local connections = {}
  return {
   Connect = function(_, callback)
    local entry = { callback = callback, active = true }
    table.insert(connections, entry)
    return { Disconnect = function() entry.active = false end }
   end,
   Fire = function()
    for _, entry in connections do if entry.active then entry.callback() end end
   end,
  }
 end
 local click, trigger, unload, changed = signal(), signal(), signal(), signal()
 local active, mounts = nil, 0
 local widgetDestroyed, actionDestroyed, toolbarDestroyed = false, false, false
 local nativeActions,dispatches={},{}
 local uiDestroyed=0
 local ensures,statuses=0,0
 local widget = {
  Enabled = false, Destroy = function() widgetDestroyed = true end,
  GetPropertyChangedSignal = function() return changed end,
 }
 local plugin = {
  Unloading = unload,
  CreateToolbar = function()
   return {
    CreateButton = function(_, id, _, icon, text)
     check(id == "CombatForge.Toggle" and text == "CombatForge", "Stable toolbar identity")
     check(icon ~= "", "Non-empty ribbon icon")
     return {Click = click, SetActive = function(_, value) active = value end}
    end,
    Destroy = function() toolbarDestroyed = true end,
   }
  end,
  CreatePluginAction = function(_, id, text, _, icon, allowBinding)
   check(allowBinding,"Native action allows user shortcut binding")
   if id=="CombatForge.OpenEditor" then
    check(text=="Open CombatForge" and icon~="","Bindable open action")
    return {Triggered=trigger,Destroy=function() actionDestroyed=true end}
   end
   error("AC02 Retired native hitbox actions must not be registered: "..id)
  end,
  CreateDockWidgetPluginGuiAsync = function() return widget end,
 }
 local dependencies={
  UI = {mount = function() mounts += 1; return {invoke=function(name) table.insert(dispatches,name) end,destroy=function() uiDestroyed+=1 end,setRuntimeStatus=function(ok,message) statuses+=1;if statuses==1 then check(not ok and message=="Injected runtime collision","AC06 Setup failure visible") end end} end}, AbilityManager = {}, Theme = {new = function() return {} end}, Keybinds={new=function() return {} end},SnapPreferences={new=function()return {} end},
  RuntimeInstaller = {ensure=function() ensures+=1;return false,"Injected runtime collision" end}, DummySpawner = {}, TemplateInstaller = {}, HitboxEditor = {isSupported=function() return false end,start=function() return nil end},
 }
 local flush=loadMain(plugin,dependencies)
 check(ensures==0,"AC06 Runtime setup deferred beyond plugin construction")
 flush();flush();check(ensures==1 and statuses==1,"AC06 Startup ensures exactly once without retry watcher")
 check(mounts == 1 and active == false, "Startup builds editor once")
 click.Fire(); check(widget.Enabled, "Toolbar opens")
 changed.Fire(); check(active == true, "Button follows editor visibility")
 click.Fire(); check(not widget.Enabled, "Toolbar closes")
 trigger.Fire(); check(widget.Enabled and mounts == 1, "Shortcut opens existing editor")
 trigger.Fire(); check(widget.Enabled, "Repeated open never closes editor")
 check(next(nativeActions)==nil,"AC02 Only OpenEditor native action remains")
 unload.Fire(); check(widgetDestroyed and actionDestroyed and toolbarDestroyed, "Unload cleanup")
 check(uiDestroyed==1,"AC05 Page controller disposed on plugin unload")
 local beforeDispatch=#dispatches
 for _,item in nativeActions do check(item.destroyed,"AC05 Owned native action destroyed"); item.Triggered.Fire() end
 check(#dispatches==beforeDispatch,"AC05 Draft shortcut connections disconnected after unload")
 widget.Enabled = false
 trigger.Fire(); click.Fire(); check(not widget.Enabled, "Disconnected inputs after unload")
 local beforeEnsures=ensures
 local skip=loadMain(plugin,dependencies,true);skip()
 check(ensures==beforeEnsures,"VH08 AC06 Play startup skips ensure entirely")
 unload.Fire()
 return tostring(count) .. " startup assertions passed"
end
