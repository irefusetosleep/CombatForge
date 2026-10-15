# Current coordination state

Routing preference: Simple, low-compute edits go to CombatForge Worker - Edits
(configured GPT-6 Luna per the user); coordinator reviews and delivers the result.

Task ID: DUMMY-REPAIR-05.
Objective: Repair runtime collapse and UV-distorted face after R15 simplification.
Owner: Runtime worker; exclusive Plugin/DummySpawner.luau and
Runtime/DummyIdle.server.luau. Coordinator owns coordination files and delivery.
Acceptance: Strip other inherited instances and appearance; grey smiling R15,
connected and animated; preserve R6, placement, unlocked parts, health and undo.
Status: Accepted after source review and detached Studio test; no active assignments.
Cause: Generated R15 used AnimationConstraints, removed by whitelist; MeshPart
head UVs distorted the smile. Explicitly rebuild 15 Motor6Ds and use a Part head.
Checks: Detached actual generated R15 normalized successfully: 16 parts,
15 Motor6Ds, zero constraints, health 100, plain Part head, front face.
Test model remained unparented and was destroyed; existing place untouched.
Coordinator Rojo build, package validation and git diff --check passed.
Delivery: Installed with backup and verified hash; live physics/visuals untested.
Upgrade: Spawn new R15 dummies; existing dummies remain unchanged.
