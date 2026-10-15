# Current coordination state

Routing preference: Simple, low-compute edits go to CombatForge Worker - Edits
(configured GPT-6 Luna per the user); coordinator reviews and delivers the result.

Task ID: DUMMY-RIG-02.
Objective: R6/R15 segmented selector directly beneath Spawn Dummy, themed like
the supplied reference; selected rig controls newly spawned grey smiling dummies.
Plugin UI worker owns Plugin/UI.luau and Plugin/Main.server.luau.
Runtime worker owns Plugin/DummySpawner.luau and Runtime/DummyIdle.server.luau.
Contract: spawnDummy(rigType: Enum.HumanoidRigType); DummySpawner.spawn accepts
optional Enum.HumanoidRigType defaulting to R6. UI defaults R6.
Coordinator owns coordination files; reviews, validates, installs and commits.
Acceptance: Clear themed selected state, both rigs spawn and idle correctly;
preserve grey smile, unlocked parts, placement, health and undo.
Status: Both implementations accepted after scoped and integrated diff review.
Checks: git diff --check, Rojo build and package validation passed.
Delivery: Installed with backup; installed hash verified. No active assignments.
Limit: Live Studio visual and animation playback checks were not performed.
Upgrade: Spawn new dummies to use the selected rig and rig-specific idle;
existing dummies retain their current rig and embedded idle script.
