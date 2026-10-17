-- AC-01: loader captures actual button callbacks without replacing UI behavior.
return function(UI, actions)
 local count = 0
 local function check(value, message) assert(value, message); count += 1 end
 local host = Instance.new("Frame"); host.Size = UDim2.fromOffset(360, 600)
 local calls = {}
 local success = true
 local manager = {list = function() return {}, nil end}
 local ok, failure = pcall(function()
  UI.mount(host, manager, nil, nil, nil, function(kind, mode)
   table.insert(calls, {kind=kind, mode=mode})
   return success, if success then "Created fixture" else "Injected creation conflict"
  end)
  local root = host.CombatForgeRoot
  check(root.TemplateSkills.Text == "Template Skills", "AC01 Main-menu entry")
  actions.TemplateSkills()
  check(root.EmptyMeleeSkill.Text == "Empty Melee Skill" and root.EmptyProjectileSkill.Text == "Empty Projectile Skill", "AC01 Both template choices")
  check(root.ProjectileAimSelector.LayoutOrder == root.EmptyProjectileSkill.LayoutOrder + 1, "AC01 Aim control directly beneath projectile")
  check(root.ProjectileAimSelector:FindFirstChild("MouseAim", true) and root.ProjectileAimSelector:FindFirstChild("BodyAim", true), "AC01 Both visibly labelled aim choices")
  actions.EmptyProjectileSkill()
  check(#calls == 1 and calls[1].kind == "Projectile" and calls[1].mode == "Mouse", "AC01 Initial Mouse selection captured")
  check(root.TemplateStatus.Text == "Created fixture", "AC01 Success feedback")
  actions.BodyAim(); actions.EmptyProjectileSkill()
  check(calls[2].mode == "Body", "AC01 Body selection captured before creation")
  actions.Back(); actions.TemplateSkills(); actions.EmptyProjectileSkill()
  check(calls[3].mode == "Body", "AC01 Selection survives page navigation")
  actions.EmptyMeleeSkill()
  check(calls[4].kind == "Melee", "AC01 Melee dispatch")
  success = false; actions.EmptyProjectileSkill()
  check(root.TemplateStatus.Text == "Injected creation conflict", "AC01 Failure feedback")
  actions.MouseAim(); actions.EmptyProjectileSkill()
  check(calls[6].mode == "Mouse", "AC01 Selection remains usable after error")
  actions.Back()
  check(root.CreateNewSkill and root.UpdateSkills and root.TemplateSkills, "AC07 Existing menu actions retained")
 end)
 host:Destroy()
 assert(ok, failure)
 return tostring(count) .. " template menu assertions passed (actual callbacks, isolated GUI)"
end
