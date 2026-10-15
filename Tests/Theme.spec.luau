return function(Theme, UI, actions)
 local count = 0
 local function check(value, message) assert(value, message); count += 1 end
 local stored = nil
 local failWrite = false
 local plugin = {
  GetSetting = function() return stored end,
  SetSetting = function(_, _, value) if failWrite then error("Test write failure") end; stored = table.clone(value) end,
 }
 check(Theme.hex(" #aabbcc ") == "AABBCC", "Normalise hex")
 for _, value in { "#abc", "GGGGGG", "1234567", "", 123 } do check(Theme.hex(value) == nil, "Reject invalid hex") end
 local settings = Theme.new(plugin)
 check(settings.get().mode == "Dark", "Default Dark")
 local draft = settings.get(); draft.mode = "Light"
 check(settings.get().mode == "Dark", "Settings copy isolation")
 check(settings.save(draft), "Save Light")
 check(Theme.new(plugin).get().mode == "Light", "Reload persistence")
 failWrite = true; draft.mode = "Dark"
 check(not settings.save(draft) and settings.get().mode == "Light", "Write failure retains active settings")
 failWrite = false
 local host = Instance.new("Frame")
 local ok, failure = pcall(function()
  UI.mount(host, {}, settings)
  local root = host.CombatForgeRoot
  check(root.BackgroundColor3 == Theme.palette(settings.get()).background, "Initial saved theme")
  actions.Settings()
  check(root.CurrentTheme.Text == "Current theme: Light", "Settings screen")
  actions.ThemeDark()
  check(settings.get().mode == "Dark" and root.BackgroundColor3 == Color3.fromRGB(24,27,33), "Apply Dark")
  root.ThemeBackgroundInput.Text = "invalid"
  actions.SaveCustomTheme()
  check(settings.get().mode == "Dark" and root.CustomStatus.Text ~= "", "Invalid custom stays in form")
  root.ThemeBackgroundInput.Text = "#112233"
  root.ThemeSurfaceInput.Text = "#223344"
  root.ThemeTextInput.Text = "#FFFFFF"
  root.ThemeAccentInput.Text = "#FFCC00"
  actions.SaveCustomTheme()
  check(settings.get().mode == "Custom" and root.BackgroundColor3 == Color3.fromRGB(17,34,51), "Custom applied")
  actions.Back()
  check(root.CreateNewSkill.BackgroundColor3 == Color3.fromRGB(255,204,0), "Menu accent")
  actions.CreateNewSkill()
  check(root.NameInput.BackgroundColor3 == Color3.fromRGB(34,51,68) and root.NameInput.TextColor3 == Color3.new(1,1,1), "Form colour propagation")
  actions.Back(); actions.Settings(); actions.ThemeLight(); actions.ThemeCustom()
  check(settings.get().background == "112233" and root.BackgroundColor3 == Color3.fromRGB(17,34,51), "Custom retained across presets")
  check(Theme.new(plugin).get().accent == "FFCC00", "Custom persisted")
 end)
 host:Destroy()
 assert(ok, failure)
 stored = {mode = "Unknown"}
 check(Theme.new(plugin).get().mode == "Dark", "Corrupt settings fallback")
 return tostring(count) .. " theme assertions passed"
end
