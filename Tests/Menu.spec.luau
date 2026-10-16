-- Harness registers the actual button callbacks while retaining normal signal connections.
return function(UI, actions)
 local count = 0
 local function check(value, message) assert(value, message); count += 1 end
 local host = Instance.new("Frame")
 local skill = Instance.new("ModuleScript"); skill.Name = "Slash"
 local data = { Name = "Slash", Damage = 20, Cooldown = 0.5, Range = 5 }
 local creates, updates = 0, 0
 local manager = {
  list = function() return {skill}, nil end,
  read = function() return { module = skill, name = skill.Name, source = "", config = data }, nil end,
  create = function() creates += 1; return true, "Created" end,
  update = function(_, values)
   updates += 1
   data = { Name = values.Name, Damage = tonumber(values.Damage), Cooldown = tonumber(values.Cooldown), Range = tonumber(values.Range) }
   skill.Name = data.Name
   return true, "Saved"
  end,
 }
 local ok, failure = pcall(function()
  UI.mount(host, manager)
  local root = host.CombatForgeRoot
  check(root.CreateNewSkill and root.UpdateSkills, "Two main menu actions")
  actions.CreateNewSkill()
  check(root.NameInput.Text == "LightAttack" and root.DamageInput.Text == "20", "Existing create defaults")
  actions.CreateAbility(); check(creates == 1 and root.Status.Text == "Created", "Create delegates")
  actions.Back(); actions.UpdateSkills()
  check(root.SkillRow1.Skill1.Text == "Slash", "Saved list")
  actions.Skill1()
  check(root.NameInput.Text == "Slash" and root.CooldownInput.Text == "0.5", "Populate edit fields")
  root.DamageInput.Text = "45"
  task.wait()
  actions.Back(); check(root.DiscardPrompt.Visible, "Unsaved-change confirmation")
  actions.KeepEditing(); check(not root.DiscardPrompt.Visible and root.DamageInput.Text == "45", "Keep edits")
  root.NameInput.Text = "HeavySlash"
  actions.SaveChanges()
  check(updates == 1 and data.Damage == 45 and skill.Name == "HeavySlash", "Save all fields and name")
  actions.Back(); check(root.SkillRow1.Skill1.Text == "HeavySlash", "List reflects renamed skill")
  actions.Refresh(); actions.Skill1()
  check(root.DamageInput.Text == "45", "Reopen saved values")
  root.RangeInput.Text = "10"; task.wait()
  actions.Back(); actions.DiscardChanges()
  check(root.SkillRow1.Skill1 ~= nil and data.Range == 5, "Discard does not save")
  actions.Back(); check(root.CreateNewSkill ~= nil, "Return to main menu")
 end)
 host:Destroy(); skill:Destroy()
 assert(ok, failure)
 return tostring(count) .. " menu/form assertions passed"
end
