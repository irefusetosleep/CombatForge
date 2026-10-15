# Current coordination state

Routing preference: Simple, low-compute edits go to CombatForge Worker - Edits
(configured GPT-6 Luna per the user); coordinator reviews and delivers the result.

Task ID: DUMMY-PROPORTIONS-07.
Objective: Correct oversized R15 classic head and inconsistent body proportions.
Owner: CombatForge Worker - Edits; exclusive Plugin/DummySpawner.luau.
Acceptance: Standard block R15 proportions and R6-style head with sensible size;
preserve front smile, 15 Motor6Ds, attachments, grey and spawn behavior.
Coordinator owns status, review, validation, installation and commit.
Status: Accepted after scoped review and detached Studio test; no active assignments.
Result: Classic head Part 2x1x1, explicit standard block R15 scales;
resized attachments preserve neck world position.
Checks: Detached generated R15 has 15 joints, health 100, head 2x1x1,
upper torso 2x1.6x1, lower torso 2x0.4x1; neck position error <0.000001 studs.
Test rig remained unparented and was destroyed; existing place untouched.
Rojo build, package validation and git diff --check passed.
Delivery: Installed with backup and verified hash; live appearance untested.
Upgrade: Spawn a new R15 dummy to get corrected proportions.
