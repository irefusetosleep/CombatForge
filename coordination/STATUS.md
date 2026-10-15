# Current coordination state

Routing preference: Simple, low-compute edits go to CombatForge Worker - Edits
(configured GPT-6 Luna per the user); coordinator reviews and delivers the result.

Task ID: DUMMY-HEAD-06.
Objective: Add classic SpecialMesh to R15 Part head to visually match R6.
Owner: CombatForge Worker - Edits; exclusive Plugin/DummySpawner.luau.
Acceptance: R6-style head mesh; preserve front smile, 15 repaired R15 Motor6Ds,
attachments, grey appearance and existing spawn behavior. User permits this mesh.
Coordinator owns status, review, validation, installation and commit.
Status: Accepted after scoped diff review; no active assignments.
Result: Classic Head SpecialMesh, scale 1.25, blank texture, added after whitelist.
Checks: git diff --check, Rojo build and package validation passed.
Delivery: Installed with backup and verified hash; live appearance untested.
Upgrade: Spawn new R15 dummies to receive the head mesh.
