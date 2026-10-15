return function(Theme, ColourPicker, UI, actions, pickerActions)
 local count = 0
 local function check(value, message) assert(value, message); count += 1 end
 local settings = Theme.new()
 local original = settings.get()
 local code = assert(Theme.export(original))
 local imported = assert(Theme.import(code))
 check(imported.background == original.background and imported.accent == original.accent and imported.mode == "Custom", "Round trip")
 for _, value in { "", "not json", "[]", '{"format":"Other","version":1}', '{"format":"CombatForgeTheme","version":2,"colours":{}}', string.rep("x",4097), '{"format":"CombatForgeTheme","version":1,"colours":{"background":"bad"}}' } do
  check(Theme.import(value) == nil, "Reject invalid import")
 end
 local host = Instance.new("Frame")
 local panel = Instance.new("Frame"); panel.Size = UDim2.fromOffset(300,154)
 local picked = nil
 local ok, failure = pcall(function()
  local picker = ColourPicker.mount(panel, Color3.fromRGB(10,20,30), function(value) picked = value end)
  check(panel.RedValue.Text == "R  10" and panel.BlueValue.Text == "B  30", "Initial channel labels")
  task.wait()
  local bar = panel.RedSlider
  local events = pickerActions[bar]
  local left, width = bar.AbsolutePosition.X, bar.AbsoluteSize.X
  assert(width > 0, "Slider geometry")
  events.MouseButton1Down(left + width / 2)
  check(math.abs(picked.R - 128/255) < 0.001, "Slider midpoint")
  events.MouseMoved(left + width)
  check(picked.R == 1, "Slider drag")
  events.MouseLeave(); events.MouseMoved(left)
  check(picked.R == 1, "Leaving stops drag")
  events.MouseButton1Down(left - 10)
  check(picked.R == 0, "Clamp slider coordinate")
  events.MouseButton1Up(); events.MouseMoved(left + width)
  check(picked.R == 0, "Release stops drag")
  pickerActions[panel.Swatch3].Activated()
  check(picked == Color3.fromHex("EF4444"), "Swatch updates selected colour")
  picker.setColour(Color3.new(0,1,0))
  check(panel.GreenValue.Text == "G  255" and panel.RedSlider.Marker.Position.X.Scale == 0, "Set colour updates markers")
  UI.mount(host, {}, settings)
  local root = host.CombatForgeRoot
  actions.Settings()
  actions.ThemeAccentChoose()
  check(root.ThemeAccentPicker.Visible, "Open picker")
  pickerActions[root.ThemeAccentPicker.Swatch8].Activated()
  check(root.ThemeAccentInput.Text == "#8B5CF6" and root.ThemeAccentChoose.BackgroundColor3 == Color3.fromHex("8B5CF6"), "Picker updates draft and preview")
  actions.SaveCustomTheme()
  check(settings.get().accent == "8B5CF6", "Save picked colour")
  root.ThemeCodeInput.Text = code
  actions.ImportTheme()
  check(root.ThemeAccentInput.Text == "#" .. original.accent and settings.get().accent == "8B5CF6", "Import only loads draft")
  root.ThemeCodeInput.Text = "bad"
  actions.ImportTheme()
  check(root.ThemeAccentInput.Text == "#" .. original.accent and root.ShareStatus.Text ~= "", "Bad import leaves draft intact")
  actions.SaveCustomTheme()
  check(settings.get().accent == original.accent, "Apply imported draft")
  actions.ExportTheme()
  check(Theme.import(root.ThemeCodeInput.Text).accent == original.accent, "Export fills valid share code")
 end)
 host:Destroy(); panel:Destroy()
 assert(ok, failure)
 return tostring(count) .. " colour picker/sharing assertions passed"
end
