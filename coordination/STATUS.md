# Current coordination state

Routing preference: Simple, low-compute edits go to CombatForge Worker - Edits
(configured GPT-6 Luna per the user); coordinator reviews and delivers the result.

Task ID: DUMMY-STRIP-04.
Objective: Simplify R15 dummy to BaseParts, Humanoid, Attachments, Animate/idle
scripts and one face decal. User explicitly permits required Motor6Ds/Animator.
Owner: Runtime worker; exclusive Plugin/DummySpawner.luau and
Runtime/DummyIdle.server.luau. Coordinator owns coordination files and delivery.
Acceptance: Strip other inherited instances and appearance; grey smiling R15,
connected and animated; preserve R6, placement, unlocked parts, health and undo.
Status: Accepted after coordinator scoped review; no active assignments.
Result: R15 retains direct body BaseParts, Humanoid, Attachments, valid Motor6Ds
and one Animator; adds one fresh face and trusted DummyIdle animation controller.
Inherited scripts, appearance objects, meshes as children and scale values removed.
Checks: Coordinator Rojo build, package validation and git diff --check passed.
Delivery: Installed with backup and verified hash; live appearance unverified.
Upgrade: Spawn new R15 dummies; existing dummies remain unchanged.
