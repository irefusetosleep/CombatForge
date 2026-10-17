--!strict
local SnapPreferences = {}
local KEY = "CombatForgeSnapV1"
function SnapPreferences.defaults() return { enabled = false, move = 1, resize = 1, rotate = 15 } end
function SnapPreferences.validate(values)
 if type(values) ~= "table" or type(values.enabled) ~= "boolean" then return nil, "Invalid snapping settings." end
 local allowed = { enabled = true, move = true, resize = true, rotate = true }
 for key in values do if not allowed[key] then return nil, "Unknown snapping setting." end end
 for _, key in { "move", "resize", "rotate" } do
  local value = values[key]
  if type(value) ~= "number" or value ~= value or value <= 0 or value == math.huge then return nil, key .. " increment must be positive and finite." end
 end
 return table.clone(values), nil
end
function SnapPreferences.new(pluginRef)
 local current, loadError = SnapPreferences.defaults(), nil
 if pluginRef then
  local ok, saved = pcall(function() return pluginRef:GetSetting(KEY) end)
  if not ok then loadError = "Could not load snapping settings; defaults active."
  elseif saved ~= nil then
   local valid = if type(saved) == "table" and saved.version == 1 then SnapPreferences.validate(saved.values) else nil
   if valid then current = valid else loadError = "Saved snapping settings are invalid; defaults active." end
  end
 end
 local api = {}
 function api.get() return table.clone(current) end
 function api.getError() return loadError end
 function api.save(values)
  local valid, problem = SnapPreferences.validate(values)
  if not valid then return false, problem end
  if pluginRef then
   local ok, failure = pcall(function()
    pluginRef:SetSetting(KEY, { version = 1, values = valid })
    local saved = pluginRef:GetSetting(KEY)
    local readBack = if type(saved) == "table" and saved.version == 1 then SnapPreferences.validate(saved.values) else nil
    assert(readBack, "Could not verify saved snapping settings.")
    for key, value in valid do assert(readBack[key] == value, "Snapping settings changed in another Studio window.") end
   end)
   if not ok then return false, "Could not save snapping settings: " .. tostring(failure) end
  end
  current = valid; loadError = nil; return true, "Snapping settings saved."
 end
 return api
end
return SnapPreferences
