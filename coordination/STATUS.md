# Current coordination state

Task: TEMPLATE-ALL-CONFIG-03 — consolidate all existing template settings in Abilities configs.
Specification: coordination/specs/TEMPLATE-ALL-CONFIG-03.md; no open questions.
Small Edits investigated and escalated the schema/editor compatibility scope.
Existing Astra Medium Planner finalized six ACs; existing Coder and Tester reused.
Reviewer will remain read-only. No new role agents created for this task.

Ownership: Coder owns AbilityConfig, AbilityManager, TemplateInstaller, Templates,
necessary UI help and TemplateSkills docs. Tester owns Tests and source-table harness.
Planner owns spec. Coordinator owns STATUS/PROJECT, integration, Studio, install and Git.

Current readers/writers: AbilityConfig literal parser/serializer and AbilityManager
editor updates; TemplateInstaller creates configs; template client/server read them.
New data: existing four common fields plus optional whitelisted scalar advanced fields.
New generated template runtimes require their complete per-kind settings in the linked
module. Update Skills keeps four controls and preserves advanced values on save.

Compatibility: old four-field configs and Example continue working; existing generated
Tools/configs are not rewritten. New templates have no local Skill.Config defaults.
Forward path: expand safe schema, generate full configs, verify both schemas and all
runtime readers. Rollback: revert/reinstall plugin without deleting game data; older
plugin versions may refuse extended configs for editing, preserving their source.
No destructive migration or later contraction is authorized by this task.

Planned checks: literal parser round trips and rejection, advanced-value preservation,
generated configuration/runtime consumption, existing regressions and package validation.
Native UI/Play/StarterPack/Undo checks remain distinct from isolated test evidence.
Prior delivery: 2e1c042, linked common configs; 536 assertions passed with recorded limits.

LOGO-01: Small Edits owns Main.server.luau icon URI only; coordinator owns supplied PNG, review and installation. Uploaded supplied image as rbxassetid://95933009796699. Release built from committed HEAD plus logo edit to avoid delivering unfinished TEMPLATE-ALL-CONFIG-03 changes.
LOGO-01 complete: coordinator approved one-line icon diff; isolated committed-source release built, package validation passed, installed with backup and matching hash. Toolbar/action reference uploaded image. Visual rendering after Studio restart not run. Config consolidation remains unfinished as recorded above.
LOGO-FIX-02 active: actual Studio ContentProvider callback reports Failure for logo asset 95933009796699; CombatForgeRoot exists, so startup succeeded. Small Edits owns Main only; Tester owns new LogoStartup spec. Coordinator owns integration and committed-source isolated release. Required AC: built-in toolbar available on asset failure, success may upgrade icon, unload safe, startup/shortcut unaffected.
LOGO-FIX-02 complete: coordinator review approved fallback startup and guarded optional async branding. Actual Studio asset probes: custom logo Failure; built-in sparkle Success. 11 existing startup assertions + 56 injected logo startup assertions passed in Studio. Isolated committed-source release built and package validated; backup/hash-verified local install complete. Native ribbon appearance after reload remains not run; user should restart Studio. Unfinished template configuration work preserved.
LOGO-CROP-03: tighter transparent logo uploaded as 118596951641724. Small Edits owns Main URI, Tester owns expected URI in LogoStartup spec; coordinator owns asset/release/validation. Existing all-config work remains separate.
LOGO-CROP-03 complete: coordinator approved URI-only diff and tighter image. 11 startup + 56 logo checks passed in Studio; package validation, backup and hash verification passed on isolated committed-source install. New asset preload currently Failure; fallback remains available during processing. Native ribbon size after new asset readiness/restart not run.
TEMPLATE-ALL-CONFIG-03 complete: final Studio harness825 assertions passed (103 runtime,232 shared,other totals as earlier792run). Build/package and diff checks passed; reviewer no blocking findings, native verification incomplete. Manual Play/replication/animation/Undo not run. VISUAL-HITBOX-04 planning approved; implementation follows separately.
