# TEMPLATE-CONFIGS-02 — shared configurations for template skills

Status: Implemented, independently tested and reviewed, then locally installed.
536 assertions passed; native Play/player cloning and Undo/Redo remain not run.
Supersedes TEMPLATE-SKILLS-01 only
where its self-contained configuration requirement conflicts with this feature.

## Outcome and current behavior

Creating either Template Skill also creates its corresponding editable config
ModuleScript in `ReplicatedStorage.CombatForge.Abilities`. The generated Tool
actually consumes that config, so Update Skills changes affect its next Play run.

Currently TemplateInstaller clones four-child Tools into StarterPack, installing
Hitbox only for melee. Damage, Cooldown and Range live in each Skill.Config;
AbilityConfig/AbilityManager separately support literal Name/Damage/Cooldown/Range
modules. AbilityManager can rename a module while preserving identity, and delete
by detaching it for undo. Its parser intentionally rejects extra fields/custom
code and never executes place modules. Preserve that editor safety contract.

## Interaction, inputs, outputs and failure behavior

Existing melee/projectile buttons and Mouse/Body selector remain the inputs.
Each click creates a fresh Tool plus a fresh config with defaults Damage 20,
Cooldown 0.75, Range 6 for melee or 80 for projectile. Config base names are
`MeleeSkill` and `ProjectileSkill`, with numeric suffixes starting at 2 to avoid
case-insensitive collisions with any object in Abilities. Tool naming retains its
existing spaced names and numeric suffix policy. Names need not share suffixes:
the explicit object reference defines the correspondence.

The config contains exactly the editor-supported four fields, including Name
matching its initial instance name. The generated Skill contains a `Config`
ObjectValue whose Value is the exact config ModuleScript. Nesting this under Skill
preserves the existing four direct Tool children and survives module renaming.
AnimationId, HitDelay, AimMode and geometry/speed/lifetime remain local Skill
settings. Success guidance identifies the shared config and explains where to
edit common versus advanced settings. Update Skills continues its existing
list/Refresh behavior; no automatic navigation is required.

Generation failures report an error and preserve existing objects. Missing,
detached, wrong-type, invalid or failed-to-load config references fail closed:
no attack, no infinite wait, no fallback to old defaults or another module with
the same name. Provide actionable runtime diagnostic feedback. Runtime require
may execute user-owned config in the game; the plugin must never require it.

## Acceptance criteria

- **AC-01 — Paired creation and defaults:** Both template kinds create exactly
  one fresh config ModuleScript under the single Folder path
  ReplicatedStorage.CombatForge.Abilities and one fresh StarterPack Tool. Config
  source parses with existing AbilityConfig.parse and contains only Name,
  Damage, Cooldown, Range with the defaults above. Projectile aim selection and
  existing advanced defaults remain intact.
- **AC-02 — Distinct identity and preservation:** Repeated or mixed generation
  produces distinct Tool/config pairs. Config naming obeys the existing valid
  identifier format and avoids case-insensitive collisions with any object.
  Each nested Skill.Config ObjectValue points to its own config; installed Tool
  cloning retains that external reference. Renaming config via Update Skills or
  Explorer does not break linkage. Existing Tools, configs, custom sources,
  Example content and dependencies are never overwritten or migrated.
- **AC-03 — Actual runtime consumption and editing:** Damage, Cooldown and Range
  from the corresponding shared module drive server damage, activation cooldown
  and melee reach/projectile travel. Local advanced settings remain effective
  and cannot accidentally override these shared fields. Changes made using
  Update Skills apply on the next Play session without regenerating the Tool.
  Supported finite nonnegative Damage/Cooldown and positive Range work, including
  Cooldown 0; preserve default 0.75 and all other authorization/lifecycle checks.
  No live require-cache/source hot reload is required.
- **AC-04 — Safe broken-link behavior:** Missing/detached/wrong-type config
  references or invalid returned settings cannot cause attacks, unbounded
  WaitForChild hangs or substitution of a different config. Normal supported
  rename preserves operation; deletion before the next Play prevents operation;
  undo restoring the same config restores the link for subsequent Play. Existing
  server input validation, equipped/owner checks and delayed-work cancellation
  remain in force. Clearly explain deletion disables its dependent Tool until
  the config is restored; do not cascade-delete Tools.
- **AC-05 — Atomic installation:** Preflight the root and Abilities paths for
  both kinds, rejecting duplicates/non-Folders. Preserve melee Runtime/Hitbox
  compatibility checks; projectile does not acquire a Hitbox dependency. One
  successful history recording includes Tool, config/link and any newly created
  required folders/runtime. Play mode and unavailable recording cause no
  mutation. Any failure rolls back only this attempt's created objects, including
  commit failures and partial-root cases. Existing content remains unchanged.
  Native Undo/Redo removes/restores the complete bundle as one action.
- **AC-06 — Packaging, guidance and evidence:** Keep executable Legacy Script
  package root, disabled bundled scripts and enabled installed copies. Preserve
  ordinary create/update/delete and Example behavior. Update TemplateSkills docs,
  relevant status/help text and PROJECT map to describe shared settings/linkage,
  deletion behavior and fresh-generation/manual-port upgrade path. Independently
  test the above criteria and report actual checks versus unperformed native
  Studio checks, including Reviewer verdict.

## Implementation plan, interfaces and dependencies

1. TemplateInstaller requires existing AbilityConfig for serialized supported
   source. Keep install(hitbox, template, kind, aimMode) -> (boolean, string).
   Preflight root/Abilities for both kinds, Runtime/Hitbox only for melee;
   calculate collision-safe config/Tool names before a single recording.
2. Within the existing transaction, create config, clone Tool, create the nested
   Skill.Config ObjectValue, and assign its Value before enabling/parenting the
   game Tool. Track every newly allocated object for rollback. Bundled templates
   may remain without this installer-added link; no additional direct Tool child
   or broad package structure change is needed.
3. Adapt melee/projectile Skill initialization and shared server validation to
   consume the linked config while retaining local advanced settings. Keep code
   readable and duplication proportionate; no new framework. Use bounded or
   non-yielding reference lookup and protected require/error reporting. Do not
   change AbilityConfig's schema or teach plugin code to execute configurations.
4. Tests own source loaders/fixtures and need to map the new AbilityConfig
   installer dependency and nested config link. Verify generated sources, not
   merely hand-authored stand-ins. Keep source parser/editor regression tests.
5. Coordinator integrates documentation/package validation, native Studio checks
   where authorized, local install and commit. Coder owns production/docs;
   Tester owns Tests; Planner owns only this specification.

## Verification mapping and Studio constraints

AC-01/02/05: isolated installer checks for both modes/kinds, repeated creation,
case-insensitive config collisions of differing classes, existing edited source,
root/Abilities duplicate or wrong-class paths, melee runtime mismatch,
projectile independence, no recording, Play refusal and injected commit failure
with empty and partially existing trees. Assert exact generated links/source and
one recording, not only instance counts.

AC-03/04: execute generated Skill/server sources with independently chosen shared
values to prove damage/cooldown/reach/travel consumption and isolation between
pairs; exercise zero cooldown, local advanced settings, rename, missing/detached
references and invalid config. Verify AbilityManager reads/updates the generated
four-field source and does not erase local advanced settings. Existing runtime
and WorldModel tests remain relevant but do not prove native StarterPack cloning.

AC-05/06: `rojo build default.project.json -o build/CombatForge.rbxmx`,
`scripts/Test-PluginPackage.ps1 -Path build/CombatForge.rbxmx`, and
`git diff --check`. Existing tests are injected-loader Luau functions; no
standalone shell Luau runner is configured. Use the existing isolated harness
when execution is available and disclose limits.

Manual Studio steps (not run until performed): generate both kinds, inspect
linked config, Refresh Update Skills, edit/rename config, then Play/equip/activate
and observe changed damage/cooldown/range for each independent Tool. Verify
StarterPack clone's external ObjectValue reference; delete config in Edit mode,
verify no attack on Play, stop/undo deletion and verify next Play works. Native
Undo/Redo must remove/restore one complete creation, with unrelated content
preserved. Re-list Studio connections; only coordinator may operate Studio under
PROJECT.md authorization. No selection changes or new persisted UI state needed.

## Assumptions and exclusions

Newly generated Tools receive the feature; existing generated Tools remain
unchanged and require fresh generation or manually porting the documented link.
Edits apply on a new Play session under normal ModuleScript require caching.
Config rename does not rename its Tool. Config deletion does not remove its Tool.
No custom config code parsing, schema expansion, animation asset work, client
authority changes, existing Example migration or runtime hot reload is included.

## Open questions

None. Object-reference linkage, supported identifier naming and split common/
advanced settings are internal compatibility choices using existing editor
contracts. Escalate genuinely new product conflicts instead of changing these
criteria silently.
