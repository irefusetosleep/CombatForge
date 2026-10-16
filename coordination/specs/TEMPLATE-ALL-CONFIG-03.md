# TEMPLATE-ALL-CONFIG-03 — all template settings in the linked config

Status: Final implementation-ready specification. Replaces TEMPLATE-CONFIGS-02's
local advanced-settings requirement only. Investigation started from a clean tree.

## Outcome and current behavior

The user wants all existing skill configuration, including hitbox dimensions, in
its corresponding ReplicatedStorage.CombatForge.Abilities config ModuleScript.
New templates currently put Damage/Cooldown/Range there but retain advanced
Skill.Config tables in each Tool. The client reads local AimMode; the server merges
shared/common fields with local settings. AbilityConfig accepts only four literal
fields and AbilityManager.update serializes only those four, so preserving advanced
fields requires a safe, bounded schema extension, not just moving defaults.

Keep the current buttons and four Update Skills controls. Generate a full config
for each new template, write the selected projectile aim into that config, and
edit advanced fields directly in its ModuleScript. All edits apply next Play.
Existing saved Tools/configs and Example copies remain untouched.

## Fields, defaults and validation

Name remains the existing 1–64 character identifier. Damage/Cooldown remain finite
nonnegative numbers, including zero; Range remains finite and positive. Retain
Damage 20, Cooldown 0.75, melee Range 6 and projectile Range 80.

Both generated kinds add AnimationId = "" and HitDelay = 0. Melee adds
HitboxWidth = 5 and HitboxHeight = 5. Projectile adds ProjectileSpeed = 60,
ProjectileRadius = 0.5, ProjectileLifetime = 3 and AimMode = the selected Mouse or
Body value. This is the complete scope: do not turn hard-coded visual styling or
other implementation constants into new configuration settings.

Optional schema fields have these constraints when present:

- HitboxWidth, HitboxHeight, ProjectileSpeed: finite numbers greater than zero.
- ProjectileRadius: finite number greater than zero and at most 256.
- ProjectileLifetime: finite number greater than zero and at most 60.
- HitDelay: finite number from zero through 30 inclusive.
- AimMode: exactly "Mouse" or "Body".
- AnimationId: string, empty allowed; bounded to 1024 bytes and no ASCII control
  characters (bytes 0–31 or 127). Ordinary punctuation is data, not syntax.

Advanced fields are optional in the general parser/serializer for compatibility
with existing four-field abilities and Example configs. A generated melee runtime
requires its complete melee field set; a generated projectile runtime requires its
complete projectile set. No kind discriminator or defaults inferred from names.

## Acceptance criteria

- **AC-01 — Full generated config:** Each newly generated melee/projectile config
  contains common fields and all its advanced fields with the defaults above.
  Selected projectile AimMode is serialized into the config, without source
  string replacement. Template Skill sources contain no local settings/default
  configuration table. Retain each unique config, nested Skill.Config ObjectValue,
  four direct Tool children, naming/collision rules and existing creation rollback.
- **AC-02 — Literal-only supported schema:** AbilityConfig parses, validates and
  serializes exactly the common fields plus the explicit optional field whitelist
  above. Preserve existing four-field round trips. Accept normal single/double
  quoted strings, handling escaped quotes/backslashes correctly; comment markers,
  commas, semicolons and braces inside a string must remain string data. Only
  actual line comments outside strings may be ignored. Unsupported escapes,
  unterminated strings, control characters and invalid types/domains fail clearly.
  Reject duplicate/unknown keys, expressions, calls, nested tables, trailing
  executable content and unsupported syntax without executing it. The plugin must
  never require/loadstring/evaluate a place config. Serialized strings must round
  trip exactly and cannot inject code. Name's existing identifier rule remains.
- **AC-03 — Editor preservation:** Update Skills keeps its four controls and can
  read/update/rename both legacy and extended supported configs. Saving common
  fields preserves every present supported advanced field and its value, including
  optional absence; it does not populate unrelated fields. Existing stale-source,
  rename collision, Play refusal and undo safeguards remain. Unsupported custom
  source is refused intact rather than rewritten or stripped.
- **AC-04 — Runtime reads one complete config:** Both client and server obtain
  settings through Skill.GetConfig. Client reads shared AimMode to send aim intent;
  server independently validates authoritative settings and request data. Pass the
  obtained config to Skill.Validate(config), and pass that same per-activation
  captured config to Cast. Shared advanced values actually drive melee dimensions,
  animation/delay and projectile speed/radius/lifetime/aim; shared common values
  continue driving damage/cooldown/range. No local fallback values or old local
  Skill.Config reads remain. Each activation uses a shallow snapshot of supported
  scalar values so delayed work does not reread a mutable required table.
- **AC-05 — Failure behavior and compatibility:** Invalid/missing required settings,
  broken/detached/wrong-type links or failed require prevent activation and provide
  useful diagnostics without an unbounded missing-config wait or same-name fallback.
  Preserve stable linkage on rename, deletion/undo behavior, server authority,
  optional-animation failure handling, delayed-work cancellation and cleanup.
  Existing ordinary four-field creation/editing and Example behavior still work.
  Existing generated Tools/configs are not migrated or rewritten.
- **AC-06 — Delivery evidence and guidance:** Document that all settings now live
  in the linked Abilities module, four common fields remain editable in Update
  Skills, advanced settings are edited in source, and changes apply next Play.
  Include fresh-generation/manual-port guidance for older templates. Preserve
  executable package root and disabled bundled scripts. Independently verify
  relevant parser/editor/installer/client/server regressions, build/package checks
  and report unperformed native Studio steps as not run plus Reviewer verdict.

## Implementation plan and interfaces

1. Extend AbilityConfig.Config with optional typed fields and a fixed field list.
   Keep validate's four-control input contract; provide internal or additional
   validation suitable for full parsed configs. Use a small literal scanner that
   knows quote/comment boundaries, not global comment removal or delimiter-only
   splitting. No general Lua parser dependency or evaluator is needed.
2. AbilityManager.update merges newly validated common inputs with parsed advanced
   fields from its checked snapshot/source before serialization. Preserve existing
   source conflict protection, recording and instance identity on rename.
3. TemplateInstaller builds the full typed defaults table for each kind and
   serializes it. Remove the projectile source AimMode substitution. Keep its
   current transactional installer interface and links.
4. MeleeSkill/ProjectileSkill GetConfig resolves the existing ObjectValue and
   validates/clones the linked table, without local defaults. Validate(config)
   checks the relevant complete field set. ToolClient gets validated shared config
   before choosing aim intent; ToolServer passes captured config into validation
   and existing Cast pipeline. No new client authority or shared runtime API.
5. Update focused documentation/PROJECT map and success guidance. Coder owns
   production/docs; Tester owns Tests; coordinator owns integration, installation,
   live Studio checks and commits. Planner changes only this specification.

## Verification and Studio constraints

AC-01: inspect/parse actual generated configs for both kinds and both aim modes;
assert complete defaults and distinct references, no source marker substitution,
unchanged prior copies, and existing collision/rollback checks.

AC-02/03: round-trip each optional field, numeric bounds/NaN/infinity, plain and
escaped quoted strings, punctuation including `--`, comma, semicolon, braces and
backslash, controls/oversized strings, malformed syntax and executable payloads.
Verify rejection without mutation/execution. Update common fields and rename full
melee/projectile configs, proving advanced values survive exactly; retain old
four-field, stale-source and Example regression checks.

AC-04/05: execute actual generated sources with distinct advanced values, proving
consumption (including client Mouse versus Body dispatch) and captured-config
behavior. Verify missing/wrong/invalid fields fail closed, no hidden defaults,
settings validation, zero cooldown, runtime authority/cancellation and cleanup.
Mocks and isolated WorldModel checks do not prove native replication or animation.

AC-06: run relevant injected-loader Luau suites where available, then
`rojo build default.project.json -o build/CombatForge.rbxmx`,
`scripts/Test-PluginPackage.ps1 -Path build/CombatForge.rbxmx`, and
`git diff --check`. No standalone shell Luau runner is configured.

Manual Studio checks, not run until performed: generate both types, inspect all
fields in Abilities, edit advanced fields and common fields via their respective
paths, rename through Update Skills, then Play and verify dimensions, both aim
modes, projectile speed/radius/lifetime and optional animation/HitDelay. Verify
native Undo/Redo and old copies remain intact. Coordinator must re-list Studio
connections and respect PROJECT.md mutation limits.

## Assumptions, scope and Open questions

No new advanced GUI controls, schema kind/version tag, hot reload, automatic old
Tool migration, new settings or unrelated refactor. A small explicitly supported
literal-string subset is intentional; arbitrary Luau remains unsupported by the
editor. Existing animation asset permission/rig constraints remain unchanged.

Open questions: None. The requested move is clear; schema preservation and runtime
validation are necessary implementation details. Escalate new product conflicts
rather than silently expanding this scope.
