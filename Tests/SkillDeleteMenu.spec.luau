-- Uses the same instrumented UI/actions loader as Menu.spec.luau.
return function(UI, actions)
 local count = 0
 local function check(value, message) assert(value, message); count += 1 end
 local host = Instance.new("Frame")
 host.Size = UDim2.fromOffset(280, 420)
 local first = Instance.new("ModuleScript"); first.Name = "Slash"
 local second = Instance.new("ModuleScript"); second.Name = "Dash"
 local skills = {first, second}
 local calls, reads, lists = 0, 0, 0
 local mode = "reject"
 local receivedModule, receivedName
 local reenter
 local manager = {
  list = function() lists += 1; return table.clone(skills), nil end,
  read = function() reads += 1; error("Trash must not open a skill") end,
  delete = function(module, expectedName)
   calls += 1
   receivedModule, receivedName = module, expectedName
   if reenter then reenter() end
   if mode == "reject" then return false, "Skill was renamed. Refresh the list." end
   if mode == "throw" then error("Delete unavailable") end
   for index, skill in skills do
    if skill == module then table.remove(skills, index); break end
   end
   return true, "Deleted " .. expectedName .. "."
  end,
 }
 local ok, failure = pcall(function()
  UI.mount(host, manager)
  local root = host.CombatForgeRoot
  actions.UpdateSkills()
  local row = root.SkillRow1
  check(row.Skill1.Text == "Slash" and row.DeleteSkill1 ~= nil, "Separate open and trash buttons")
  check(row.Skill1.Size.X.Offset == -50 and row.DeleteSkill1.Size.X.Offset == 42, "Fixed trash width leaves room for skill text")
  check(row.DeleteSkill1.BackgroundColor3 == Color3.fromRGB(190, 45, 55), "Trash has dark red fill")
  local parts = row.DeleteSkill1:GetChildren()
  check(#parts == 7, "Bin icon uses GUI primitives")
  for _, part in parts do
   check(part:IsA("Frame") and part.BackgroundColor3 == Color3.new(1, 1, 1), "Bin icon is white")
  end
  actions.DeleteSkill1()
  check(root.Heading.Text == "Delete Slash?" and calls == 0 and reads == 0, "First click only prompts")
  check(root.ConfirmDelete.BackgroundColor3 == Color3.fromRGB(190, 45, 55)
   and root.ConfirmDelete.TextColor3 == Color3.new(1, 1, 1), "Confirm has readable white on dark red")
  local cancelledConfirm = actions.ConfirmDelete
  actions.Back()
  cancelledConfirm()
  check(calls == 0 and #skills == 2 and root.SkillRow1.Skill1.Text == "Slash", "Cancel and stale confirm cannot delete")
  actions.DeleteSkill1()
  first.Name = "RenamedSlash"
  actions.ConfirmDelete()
  check(calls == 1 and receivedModule == first and receivedName == "Slash", "Confirm passes captured identity and original name")
  check(root:FindFirstChild("ConfirmDelete") ~= nil and root.DeleteStatus.Text == "Skill was renamed. Refresh the list.", "Failure retains confirmation and backend error")
  mode = "throw"
  actions.ConfirmDelete()
  check(calls == 2 and root.DeleteStatus.Text:find("Delete unavailable", 1, true), "Thrown failure is visible and retry stays available")
  actions.Back()
  actions.DeleteSkill1()
  mode = "success"
  local confirmOnce = actions.ConfirmDelete
  reenter = confirmOnce
  local beforeLists = lists
  confirmOnce(); confirmOnce()
  reenter = nil
  check(calls == 3 and receivedModule == first and receivedName == "RenamedSlash", "Busy/reentrant and repeated confirmation delete exactly once")
  check(lists == beforeLists + 1 and root.SkillRow1.Skill1.Text == "Dash", "Success refreshes surviving skills")
  check(root.Status.Text == "Deleted RenamedSlash.", "Success message is retained")
  actions.DeleteSkill1()
  actions.ConfirmDelete()
  check(calls == 4 and receivedModule == second and receivedName == "Dash", "Last skill uses correct identity")
  check(#skills == 0 and root:FindFirstChild("SkillRow1") == nil, "Last deletion removes all rows")
  check(root.Status.Text:find("Deleted Dash.", 1, true) and root.Status.Text:find("No CombatForge skills yet.", 1, true), "Empty list retains success and empty guidance")
 end)
 host:Destroy(); first:Destroy(); second:Destroy()
 assert(ok, failure)
 return tostring(count) .. " skill deletion menu assertions passed"
end
