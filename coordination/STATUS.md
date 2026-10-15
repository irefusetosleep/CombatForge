# Current coordination state

Routing preference: Simple, low-compute edits go to CombatForge Worker - Edits
(configured GPT-6 Luna per the user); coordinator reviews and delivers the result.

Task ID: DUMMY-FACE-03.
Objective: Remove the unwanted black head marking on spawned R15 dummies.
Owner: CombatForge Worker - Edits; owns only Plugin/DummySpawner.luau.
Acceptance: Clean grey R15 head with one classic smile; preserve R6 appearance,
rig selection, idle, unlocked parts, placement, health and undo.
Coordinator owns status, review, package validation, installation and commit.
Status: Accepted after scoped diff review; no active assignments.
Fix: Clear inherited head textures and decals, then add one fresh classic smile.
Checks: git diff --check, Rojo build and package validation passed.
Delivery: Installed with backup and verified hash; live appearance untested.
Upgrade: Spawn a new dummy; existing dummies retain their head appearance.
