# Current coordination state

Routing preference: Simple, low-compute edits go to CombatForge Worker - Edits
(configured GPT-6 Luna per the user); coordinator reviews and delivers the result.

Task ID: SKILL-DELETE-08.
Objective: Red delete button with white trash icon on Update Skills rows;
explicit confirmation names target skill; Studio Ctrl+Z restores deletion.
UI worker owns Plugin/UI.luau. Runtime worker owns Plugin/AbilityManager.luau
and Tests/AbilityDelete.spec.luau. Coordinator owns coordination files/delivery.
Contract: AbilityManager.delete(module: ModuleScript, expectedName: string)
returns (boolean, string); validates target path/name and Edit mode before deletion.
Acceptance: Cancel never mutates; confirmed deletion is one undo recording;
no accidental opening/deleting other rows, stale targets fail safely, errors shown.
Status: Accepted after scoped review and isolated Studio tests; no active assignments.
Result: Red/white trash controls, named Cancel/Delete confirmation; exact target
unparented inside one change-history recording, preserving original subtree.
Checks: 12 menu/form, 23 deletion UI and 49 isolated backend assertions passed.
Rojo build, package validation and git diff --check passed.
Delivery: Installed with backup and verified hash.
Limit: Native Ctrl+Z/redo and rendered UI not exercised; undo transitions tested
using isolated history service. Existing place skills were not modified.
