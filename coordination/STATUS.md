# Current coordination state

Task: VISUAL-HITBOX-04 — visual melee box authoring.
Specification: coordination/specs/VISUAL-HITBOX-04.md. Open questions: none blocking.
Planner (existing Astra Medium role) finalized the six acceptance criteria.
Coder owns production modules, UI/startup wiring, project/package wiring and user docs.
Tester owns Tests and isolated harness only; prepares independently while Coder works.
Reviewer will review read-only after implementation and executed evidence.
Coordinator owns integration, Studio checks, installation and commits.

Scope: select supported melee config and existing R6/R15 dummy, explicit preview,
Move/Resize handles, readouts, checked Save or Cancel. Add signed local offset triple;
all-absent compatibility means zero. No projectile/rotation editor, no automatic
saved-Tool migration, no persistent preview or dummy creation. Config Save must
preserve nongeometry fields, reject conflicts and support one undo recording.
Cleanup on navigation/theme/hide/unload/Play/reference loss. Preview and runtime match.

Previous task TEMPLATE-ALL-CONFIG-03 committed e7e60a7: final825 isolated Studio
assertions passed. Build/package/diff checks passed. Reviewer found no blockers;
manual native Play/replication/animation/StarterPack/Undo remains not run.
Existing Tool/runtime copies are preserved; fresh generation/manual port needed.
Logo history: uploaded tight icon118596951641724, protected async fallback remains.

Planned evidence: offset schema/save/editor/runtime tests, existing regressions,
Rojo/package validation and read-only review. Native pointer/handles and Undo checks
will remain explicitly not run unless actually performed. Studio place mutation
limits remain in PROJECT.md; no permanent test content authorized by this task.
Final evidence:1019 full harness assertions +56 logo startup=1075 passed in Studio. One UI test required waiting for deferred Destroying dispatch; exact assertion retained. Actual native Handles/BoxAdornment factory,Resize mode and cleanup passed on temporary isolated WorldModel,removed afterward. Native pointer/render,real Play and Undo/Redo remain not run. Current Rojo/package/diff gates passed. Final Reviewer requested; local install next.
Delivery: Reviewer verdict No blocking findings; verification incomplete (native pointer/Play/persistence/Undo not run). Installed through Install-Plugin.ps1 with backup and matching hash. AC01-05 implemented and covered by isolated/native factory evidence; AC06 automated/package/docs passed with native manual verification outstanding. User reloads Studio, generates fresh melee Tool, selects dummy and opens Update Skills -> skill -> Edit Hitbox.
