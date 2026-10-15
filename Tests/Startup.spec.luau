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
   check(id == "CombatForge.OpenEditor" and text == "Open CombatForge" and allowBinding and icon ~= "", "Bindable open action")
   return {Triggered = trigger, Destroy = function() actionDestroyed = true end}
  end,
  CreateDockWidgetPluginGuiAsync = function() return widget end,
 }
 loadMain(plugin, {
  UI = {mount = function() mounts += 1 end}, AbilityManager = {}, Theme = {new = function() return {} end},
  RuntimeInstaller = {}, ExampleInstaller = {},
 })
 check(mounts == 1 and active == false, "Startup builds editor once")
 click.Fire(); check(widget.Enabled, "Toolbar opens")
 changed.Fire(); check(active == true, "Button follows editor visibility")
 click.Fire(); check(not widget.Enabled, "Toolbar closes")
 trigger.Fire(); check(widget.Enabled and mounts == 1, "Shortcut opens existing editor")
 trigger.Fire(); check(widget.Enabled, "Repeated open never closes editor")
 unload.Fire(); check(widgetDestroyed and actionDestroyed and toolbarDestroyed, "Unload cleanup")
 widget.Enabled = false
 trigger.Fire(); click.Fire(); check(not widget.Enabled, "Disconnected inputs after unload")
 return tostring(count) .. " startup assertions passed"
end
