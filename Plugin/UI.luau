--!strict
local UI = {}
local AbilityConfig = require(script.Parent.AbilityConfig)
local AbilityManager = require(script.Parent.AbilityManager)
local Theme = require(script.Parent.Theme)
local ColourPicker = require(script.Parent.ColourPicker)

function UI.mount(widget: DockWidgetPluginGui, manager: typeof(AbilityManager), preferences: typeof(Theme.new())?, installHitbox: (() -> (boolean, string))?, installExample: (() -> (boolean, string))?)
 local settings = preferences or Theme.new()
 local palette = Theme.palette(settings.get())
 local root = Instance.new("ScrollingFrame")
 root.Name = "CombatForgeRoot"
 root.Size = UDim2.fromScale(1, 1)
 root.BackgroundColor3 = palette.background
 root.BorderSizePixel = 0
 root.CanvasSize = UDim2.fromOffset(0, 0)
 root.AutomaticCanvasSize = Enum.AutomaticSize.Y
 root.ScrollingDirection = Enum.ScrollingDirection.Y
 root.ScrollBarThickness = 6
 root.Parent = widget
 local green = palette.success
 local red = palette.error
 local busy = false
 local order = 0
 local function reset()
  palette = Theme.palette(settings.get())
  green = palette.success
  red = palette.error
  root.BackgroundColor3 = palette.background
  root.ScrollBarImageColor3 = palette.text
  root:ClearAllChildren()
  root.CanvasPosition = Vector2.zero
  order = 0
  local padding = Instance.new("UIPadding")
  padding.PaddingTop = UDim.new(0, 20)
  padding.PaddingBottom = UDim.new(0, 20)
  padding.PaddingLeft = UDim.new(0, 20)
  padding.PaddingRight = UDim.new(0, 20)
  padding.Parent = root
  local layout = Instance.new("UIListLayout")
  layout.SortOrder = Enum.SortOrder.LayoutOrder
  layout.Padding = UDim.new(0, 12)
  layout.Parent = root
 end
 local function place(item: GuiObject, name: string)
  order += 1
  item.Name = name
  item.LayoutOrder = order
  item.Parent = root
 end
 local function label(name: string, text: string, size: number): TextLabel
  local item = Instance.new("TextLabel")
  item.BackgroundTransparency = 1
  item.Size = UDim2.new(1, -8, 0, 0)
  item.AutomaticSize = Enum.AutomaticSize.Y
  item.Font = Enum.Font.Gotham
  item.TextSize = size
  item.TextColor3 = palette.text
  item.TextXAlignment = Enum.TextXAlignment.Left
  item.TextYAlignment = Enum.TextYAlignment.Top
  item.TextWrapped = true
  item.Text = text
  place(item, name)
  return item
 end
 local function button(name: string, text: string, action: () -> (), primary: boolean?): TextButton
  local item = Instance.new("TextButton")
  item.Size = UDim2.new(1, -8, 0, 42)
  item.BackgroundColor3 = if primary then palette.accent else palette.surface
  item.BorderSizePixel = 0
  item.TextColor3 = if primary then palette.accentText else palette.text
  item.Font = Enum.Font.GothamBold
  item.TextSize = 14
  item.TextTruncate = Enum.TextTruncate.AtEnd
  item.Text = text
  place(item, name)
  item.Activated:Connect(function() if not busy then action() end end)
  return item
 end
 local function field(name: string, caption: string, initial: string): TextBox
  label(name .. "Label", caption, 14)
  local input = Instance.new("TextBox")
  input.Size = UDim2.new(1, -8, 0, 36)
  input.BackgroundColor3 = palette.surface
  input.BorderSizePixel = 0
  input.TextColor3 = palette.text
  input.Font = Enum.Font.Gotham
  input.TextSize = 14
  input.TextXAlignment = Enum.TextXAlignment.Left
  input.ClearTextOnFocus = false
  input.MultiLine = false
  input.Text = initial
  local inset = Instance.new("UIPadding")
  inset.PaddingLeft = UDim.new(0, 10)
  inset.PaddingRight = UDim.new(0, 10)
  inset.Parent = input
  place(input, name .. "Input")
  return input
 end
 local showMenu: () -> ()
 local showList: () -> ()
 local showForm: (AbilityManager.Snapshot?) -> ()
 local showSettings: (string?) -> ()
 showSettings = function(message)
  reset()
  label("Heading", "Settings", 24)
  button("Back", "Main menu", showMenu)
  local current = settings.get()
  label("CurrentTheme", "Current theme: " .. current.mode, 16)
  local status = label("Status", message or "Choose a theme. Custom colours are applied when you save.", 14)
  for _, mode in { "Dark", "Light", "Custom" } do
   button("Theme" .. mode, mode .. (if mode == current.mode then " (selected)" else ""), function()
    local candidate = settings.get()
    candidate.mode = mode
    local ok, result = settings.save(candidate)
    if ok then showSettings(result) else status.Text = result; status.TextColor3 = red end
   end)
  end
  label("CustomHeading", "Custom theme", 20)
  label("CustomHelp", "Choose colours using sliders or swatches. Hex entry is optional. Save to apply; leaving this page or selecting a preset discards unsaved edits.", 14)
  local function colourField(name: string, caption: string, hex: string): TextBox
   local input = field(name, caption .. " (optional hex)", "#" .. hex)
   local panel: Frame
   local toggle = button(name .. "Choose", "Choose colour", function()
    panel.Visible = not panel.Visible
   end)
   panel = Instance.new("Frame")
   panel.Size = UDim2.new(1, -8, 0, 154)
   panel.BackgroundColor3 = Color3.fromRGB(30, 34, 42)
   panel.BorderSizePixel = 0
   panel.Visible = false
   place(panel, name .. "Picker")
   local function preview(value: Color3)
    toggle.BackgroundColor3 = value
    toggle.TextColor3 = if value.R * 0.299 + value.G * 0.587 + value.B * 0.114 > 0.55 then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
   end
   local picker = ColourPicker.mount(panel, Color3.fromHex(hex), function(value)
    input.Text = "#" .. value:ToHex():upper()
    preview(value)
   end)
   preview(Color3.fromHex(hex))
   input:GetPropertyChangedSignal("Text"):Connect(function()
    local valid = Theme.hex(input.Text)
    if valid then local value = Color3.fromHex(valid); picker.setColour(value); preview(value) end
   end)
   return input
  end
  local background = colourField("ThemeBackground", "Background", current.background)
  local surface = colourField("ThemeSurface", "Buttons and inputs", current.surface)
  local text = colourField("ThemeText", "Text", current.text)
  local accent = colourField("ThemeAccent", "Accent", current.accent)
  local function draft(): Theme.Settings
   return { mode = "Custom", background = background.Text, surface = surface.Text, text = text.Text, accent = accent.Text }
  end
  local feedback = label("CustomStatus", "", 14)
  button("SaveCustomTheme", "Save Custom Theme", function()
   local ok, result = settings.save(draft())
   if ok then showSettings(result) else feedback.Text = result; feedback.TextColor3 = red end
  end, true)
  label("ShareHeading", "Import / export custom theme", 20)
  label("ShareHelp", "Export fills the box with your current custom colours, including unsaved edits. Copy the code to share it. Paste a code and import to load a draft, then Save Custom Theme to apply it.", 14)
  local share = field("ThemeCode", "Theme code", "")
  share.Size = UDim2.new(1, -8, 0, 120)
  share.MultiLine = true
  share.TextWrapped = true
  share.TextYAlignment = Enum.TextYAlignment.Top
  share.TextSize = 12
  local shareStatus = label("ShareStatus", "", 14)
  button("ExportTheme", "Export custom theme", function()
   local code, problem = Theme.export(draft())
   if not code then shareStatus.Text = problem or "Could not export."; shareStatus.TextColor3 = red; return end
   share.Text = code
   share:CaptureFocus()
   share.CursorPosition = #code + 1
   share.SelectionStart = 1
   shareStatus.Text = "Code selected. Press Ctrl+C to copy it."
   shareStatus.TextColor3 = palette.text
  end)
  button("ImportTheme", "Import theme as draft", function()
   local imported, problem = Theme.import(share.Text)
   if not imported then shareStatus.Text = problem or "Could not import."; shareStatus.TextColor3 = red; return end
   background.Text = "#" .. imported.background
   surface.Text = "#" .. imported.surface
   text.Text = "#" .. imported.text
   accent.Text = "#" .. imported.accent
   shareStatus.Text = "Theme loaded into the colour controls above. Save Custom Theme to apply it."
   shareStatus.TextColor3 = palette.text
  end)
 end
 showForm = function(snapshot)
  reset()
  label("Heading", if snapshot then "Update Skill" else "Create New Skill", 24)
  local initial = if snapshot then snapshot.config else { Name = "LightAttack", Damage = 20, Cooldown = 0.5, Range = 5 }
  local dirty = false
  local confirmation: { GuiObject } = {}
  button("Back", if snapshot then "Back to skills" else "Main menu", function()
   if dirty then
    for _, item in confirmation do item.Visible = true end
    root.CanvasPosition = Vector2.zero
   else
    if snapshot then showList() else showMenu() end
   end
  end)
  table.insert(confirmation, label("DiscardPrompt", "You have unsaved changes. Discard them?", 14))
  table.insert(confirmation, button("KeepEditing", "Keep editing", function()
   for _, item in confirmation do item.Visible = false end
  end))
  table.insert(confirmation, button("DiscardChanges", "Discard changes", function()
   if snapshot then showList() else showMenu() end
  end))
  for _, item in confirmation do item.Visible = false end
  local name = field("Name", "Skill name", initial.Name)
  local damage = field("Damage", "Damage (0 or greater)", tostring(initial.Damage))
  local cooldown = field("Cooldown", "Cooldown in seconds (0 or greater)", tostring(initial.Cooldown))
  local range = field("Range", "Range in studs (greater than 0)", tostring(initial.Range))
  local function values(): AbilityConfig.Inputs
   return { Name = name.Text, Damage = damage.Text, Cooldown = cooldown.Text, Range = range.Text }
  end
  local baseline = values()
  for _, input in { name, damage, cooldown, range } do
   input:GetPropertyChangedSignal("Text"):Connect(function()
    local current = values()
    dirty = current.Name ~= baseline.Name or current.Damage ~= baseline.Damage or current.Cooldown ~= baseline.Cooldown or current.Range ~= baseline.Range
   end)
  end
  local status: TextLabel
  local save: TextButton
  save = button(if snapshot then "SaveChanges" else "CreateAbility", if snapshot then "Save Changes" else "Create Skill", function()
   busy = true
   save.Text = "Saving..."
   local inputs = values()
   for _, input in { name, damage, cooldown, range } do input.TextEditable = false end
   local ok, saved, message = pcall(function()
    if snapshot then return manager.update(snapshot, inputs) end
    return manager.create(inputs)
   end)
   busy = false
   if not root.Parent then return end
   for _, input in { name, damage, cooldown, range } do input.TextEditable = true end
   save.Text = if snapshot then "Save Changes" else "Create Skill"
   status.Text = if ok then message else "An unexpected error occurred: " .. tostring(saved)
   status.TextColor3 = if ok and saved then green else red
   if ok and saved then
    dirty = false
    baseline = values()
    for _, item in confirmation do item.Visible = false end
    if snapshot then
     local refreshed, readError = manager.read(snapshot.module)
     if refreshed then snapshot = refreshed else
      status.Text = message .. " Reopen the skill before editing again. " .. (readError or "")
     end
    end
   end
  end, true)
  status = label("Status", if snapshot then "Edit any field, then save your changes." else "Creates a ModuleScript in ReplicatedStorage.CombatForge.Abilities.", 14)
 end
 showList = function()
  reset()
  label("Heading", "Update Skills", 24)
  button("Back", "Main menu", showMenu)
  button("Refresh", "Refresh list", showList)
  local status = label("Status", "Select a skill to edit its settings.", 14)
  local skills, listError = manager.list()
  if listError then status.Text = listError; status.TextColor3 = red; return end
  if #skills == 0 then
   status.Text = "No CombatForge skills yet. Create your first skill from the main menu."
   return
  end
  for index, module in skills do
   button("Skill" .. index, module.Name, function()
    local snapshot, readError = manager.read(module)
    if snapshot then showForm(snapshot) else
     status.Text = readError or "Could not open this skill."
     status.TextColor3 = red
     root.CanvasPosition = Vector2.zero
    end
   end)
  end
 end
 showMenu = function()
  reset()
  label("Heading", "CombatForge", 26)
  label("Introduction", "Create and manage your combat skills.", 14)
  button("CreateNewSkill", "Create New Skill", function() showForm(nil) end, true)
  button("UpdateSkills", "Update Skills", showList)
  button("Settings", "Settings", function() showSettings(nil) end)
  if installExample then
   local status: TextLabel
   button("InstallExample", "Install Example Skill", function()
    local ok, installed, message = pcall(installExample)
    status.Text = if ok then message else "Could not install example: " .. tostring(installed)
    status.TextColor3 = if ok and installed then green else red
   end)
   status = label("ExampleStatus", "A playable slash Tool with editable damage, cooldown and range. Includes the hitbox runtime.", 14)
  end
  if installHitbox then
   local status: TextLabel
   button("InstallHitbox", "Install Hitbox Module", function()
    local ok, installed, message = pcall(installHitbox)
    status.Text = if ok then message else "Could not install: " .. tostring(installed)
    status.TextColor3 = if ok and installed then green else red
   end)
   status = label("RuntimeStatus", "Install the runtime once per place to use box and sphere hitboxes in scripts.", 14)
  end
 end
 showMenu()
end
return UI
