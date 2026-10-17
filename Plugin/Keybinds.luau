--!strict
-- Independent versioned shortcut preferences; never edits Studio shortcut settings.
local Keybinds = {}
local KEY = "CombatForgeKeybindsV1"
Keybinds.actions = { "TogglePreview", "Move", "Resize", "Rotate", "Undo" }
local function copy(values)
 local result = {}
 for _, action in Keybinds.actions do result[action] = if type(values[action]) == "table" then table.clone(values[action]) else false end
 return result
end
function Keybinds.defaults()
 local result = {}
 for index, key in { "P", "M", "S", "R", "Z" } do result[Keybinds.actions[index]] = { key = key, ctrl = true, alt = true } end
 return result
end
function Keybinds.chord(key, ctrl, alt, shift)
 if shift then return nil, "Shift is reserved for transform modifiers." end
 if type(key) ~= "string" or not (key:match("^[A-Z]$") or key:match("^[0-9]$")) then return nil, "Choose a letter or digit, with optional Ctrl/Alt." end
 if ctrl and not alt and (key == "Z" or key == "Y") then return nil, "Ctrl+Z and Ctrl+Y belong to Studio Undo/Redo." end
 return { key = key, ctrl = ctrl == true, alt = alt == true }, nil
end
function Keybinds.format(binding)
 if not binding then return "Unassigned" end
 return (if binding.ctrl then "Ctrl+" else "") .. (if binding.alt then "Alt+" else "") .. binding.key
end
function Keybinds.validate(values)
 if type(values) ~= "table" then return nil, "Invalid keybind settings." end
 local result, seen, supported = {}, {}, {}
 for _, action in Keybinds.actions do supported[action] = true end
 for key in values do if not supported[key] then return nil, "Unknown keybind action." end end
 for _, action in Keybinds.actions do
  local binding = values[action]
  if binding == false then result[action] = false
  elseif type(binding) == "table" and type(binding.ctrl) == "boolean" and type(binding.alt) == "boolean" then
   for key in binding do if key ~= "key" and key ~= "ctrl" and key ~= "alt" then return nil, "Invalid chord field." end end
   local chord, problem = Keybinds.chord(binding.key, binding.ctrl, binding.alt, false)
   if not chord then return nil, problem end
   local id = Keybinds.format(chord)
   if seen[id] then return nil, "That shortcut is already assigned to " .. seen[id] .. "." end
   seen[id] = action; result[action] = chord
  else return nil, "Missing or invalid keybind: " .. action end
 end
 return result, nil
end
function Keybinds.matches(binding, key, ctrl, alt, shift)
 return type(binding) == "table" and not shift and binding.key == key and binding.ctrl == ctrl and binding.alt == alt
end
function Keybinds.new(pluginRef)
 local current, loadError = Keybinds.defaults(), nil
 if pluginRef then
  local ok, stored = pcall(function() return pluginRef:GetSetting(KEY) end)
  if not ok then loadError = "Could not load keybinds; defaults active."
  elseif stored ~= nil then
   local valid = if type(stored) == "table" and stored.version == 1 then Keybinds.validate(stored.bindings) else nil
   if valid then current = valid else loadError = "Saved keybinds are invalid; defaults active." end
  end
 end
 local api = {}
 function api.get() return copy(current) end
 function api.getError() return loadError end
 function api.save(values)
  local valid, problem = Keybinds.validate(values)
  if not valid then return false, problem end
  if pluginRef then
   local ok, failure = pcall(function()
    pluginRef:SetSetting(KEY, { version = 1, bindings = valid })
    local stored = pluginRef:GetSetting(KEY)
    local readBack = if type(stored) == "table" and stored.version == 1 then Keybinds.validate(stored.bindings) else nil
    assert(readBack, "Could not verify saved keybinds.")
    for _, action in Keybinds.actions do assert(Keybinds.format(readBack[action]) == Keybinds.format(valid[action]), "Keybinds changed in another Studio window.") end
   end)
   if not ok then return false, "Could not save keybinds: " .. tostring(failure) end
  end
  current = valid; loadError = nil; return true, "Keybinds saved."
 end
 function api.set(action, binding)
  local candidate = copy(current)
  candidate[action] = binding
  return api.save(candidate)
 end
 function api.reset() return api.save(Keybinds.defaults()) end
 return api
end
return Keybinds
