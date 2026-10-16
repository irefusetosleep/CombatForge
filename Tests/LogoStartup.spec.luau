-- LOGO-FIX-02. loadMain(plugin, modules, overrides) compiles the real Main source
-- with overrides.game/task, script child tokens and the supplied module map.
-- No network fetch or live plugin UI is used by these deterministic fixtures.
return function(loadMain)
 local count=0
 local function check(value,message) assert(value,message); count+=1 end
 local function signal()
  local listeners={}
  return {Connect=function(_,callback)
   local entry={callback=callback,active=true}; table.insert(listeners,entry)
   return {Disconnect=function() entry.active=false end}
  end,Fire=function()
   for _,entry in listeners do if entry.active then entry.callback() end end
  end}
 end
 local fallback="rbxasset://textures/sparkle.png"
 local logo="rbxassetid://118596951641724"
 for _,mode in {"Failure","Success","throw","unloadDuring","unloadPending"} do
  local click,trigger,unload,changed=signal(),signal(),signal(),signal()
  local jobs={}
  local icon,writes,mounts,preloads,cancels=nil,0,0,0,0
  local toolbarDestroyed,actionDestroyed,widgetDestroyed=false,false,false
  local widget={Enabled=false,Destroy=function() widgetDestroyed=true end,GetPropertyChangedSignal=function() return changed end}
  local button=setmetatable({Click=click,SetActive=function() end},{
   __index=function(_,key) if key=="Icon" then return icon end end,
   __newindex=function(target,key,value)
    if key=="Icon" then writes+=1; icon=value else rawset(target,key,value) end
   end,
  })
  local plugin={Unloading=unload,
   CreateToolbar=function() return {
    CreateButton=function(_,id,_,initial,text)
     check(id=="CombatForge.Toggle" and text=="CombatForge","Stable toolbar identity")
     check(initial==fallback,"Toolbar created immediately with built-in fallback")
     icon=initial; return button
    end,
    Destroy=function() toolbarDestroyed=true end,
   } end,
   CreatePluginAction=function(_,id,_,_,initial,allowBinding)
    check(id=="CombatForge.OpenEditor" and allowBinding and initial==fallback,"Shortcut created with built-in fallback")
    return {Triggered=trigger,Destroy=function() actionDestroyed=true end}
   end,
   CreateDockWidgetPluginGuiAsync=function() return widget end,
  }
  local provider={PreloadAsync=function(_,assets,callback)
   preloads+=1
   check(mounts==1 and assets[1]==logo and #assets==1,"Branding preload occurs after editor mounting")
   if mode=="throw" then error("Injected asset preload error") end
   if mode=="unloadDuring" then unload.Fire() end
   callback(logo,if mode=="Failure" then Enum.AssetFetchStatus.Failure else Enum.AssetFetchStatus.Success)
  end}
  local function enqueue(callback)
   local job={callback=callback,cancelled=false}; table.insert(jobs,job); return job
  end
  loadMain(plugin,{
   UI={mount=function() mounts+=1 end},Theme={new=function() return {} end},AbilityManager={},
   RuntimeInstaller={},ExampleInstaller={},TemplateInstaller={},DummySpawner={},
  },{
   game={GetService=function(_,name) assert(name=="ContentProvider","Unexpected startup service"); return provider end},
   task={defer=enqueue,spawn=enqueue,cancel=function(job) cancels+=1; job.cancelled=true end},
  })
  check(mounts==1 and preloads==0 and icon==fallback,"Startup completes before asynchronous preload result")
  click.Fire(); check(widget.Enabled,"Toolbar works before preload result")
  click.Fire(); trigger.Fire(); check(widget.Enabled and mounts==1,"Shortcut opens the same editor before preload")
  if mode=="unloadPending" then unload.Fire() end
  for _,job in jobs do
   if not job.cancelled then
    local ok,failure=pcall(job.callback)
    check(ok,"Optional asset error cannot escape deferred task: "..tostring(failure))
   end
  end
  if mode=="Success" then
   check(preloads==1 and writes==1 and icon==logo,"Explicit successful preload upgrades toolbar icon")
  else
   check(writes==0 and icon==fallback,"Failure, thrown preload or unload retains fallback")
  end
  if mode=="unloadDuring" or mode=="unloadPending" then
   check(toolbarDestroyed and actionDestroyed and widgetDestroyed and cancels==1,"Unload cleans UI and cancels pending asset task")
   widget.Enabled=false; click.Fire(); trigger.Fire()
   check(not widget.Enabled and writes==0,"Late result and disconnected inputs cannot revive unloaded UI")
  else
   widget.Enabled=false; click.Fire(); check(widget.Enabled,"Toolbar remains usable after preload outcome")
   widget.Enabled=false; trigger.Fire(); check(widget.Enabled,"Shortcut remains usable after preload outcome")
   unload.Fire()
   check(toolbarDestroyed and actionDestroyed and widgetDestroyed,"Normal unload cleanup retained")
  end
 end
 return tostring(count).." logo startup assertions passed (injected ContentProvider and deferred tasks)"
end
