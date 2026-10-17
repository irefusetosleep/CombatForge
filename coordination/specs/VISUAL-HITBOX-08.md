# VISUAL-HITBOX-08 — editor usability and package cleanup

Status: Final implementation-ready specification. Coordinator verified the branding
thumbnail resolver route in Studio; no guessed asset replacement is authorized.

## Outcome and existing behavior

Provide clear Settings sections, persistent navigation, reset/snapping controls,
accurate button labels and automatic safe runtime setup; remove the legacy Example
feature completely from the distributed plugin. Preserve basic melee/projectile
templates, existing place content, theme/keybind preferences and draft Save/Undo.

UI currently puts Home/Back in its ScrollingFrame alongside options, has redundant
visual/delete Cancel buttons, fixed Undo and Toggle Preview labels and parenthetical
skill-field constraints. HitboxEditor already owns transient geometry/history and
local/global/Uniform gesture math. Basic melee defaults in TemplateInstaller are
5 x 5 x 6, zero offsets/rotations. RuntimeInstaller uses native history and preserves
conflicting existing content, but is invoked manually. Main/default.project.json
still package ExampleInstaller and Examples templates; these are independent of
the retained basic Template Skills feature. Existing injected tests cover UI,
geometry, lifecycle, installers, startup and package invariants.

## Interaction and decisions

Create a non-scrolling top-left navigation strip containing Home and Back, visually
distinct from page actions. Keep it visible while page content scrolls. Use themed
surfaces/accent treatment and reserve layout space so it never overlays content.
Root displays both unavailable or otherwise clearly inert; subordinate pages retain
the established fixed parent routes. Buttons use the same destination-aware dirty
draft guard. Remove redundant Cancel navigation buttons, including visual editor
and delete confirmation; Back replaces them. Do not remove Escape/cancel semantics
for keybind capture or Keep editing/Discard changes prompts.

Settings sections get consistent labeled dividers separating keybinds, transform
snapping, theme selection/customization and theme sharing. Use layout helpers and
theme colors, not decoration that obscures existing controls. Skill form captions
become Skill name, Damage, Cooldown in seconds and Range in studs; retain validation
and actionable error messages, but remove their parenthetical constraint text.

Visual editor adds Reset Hitbox. It resets only geometry to width 5, height 5,
Range 6, and all offsets/rotations zero. This is a draft action, adds exactly one
undo snapshot when changed, and can be undone. It does not change Damage, Cooldown,
name or other config. Default center is consequently root-local (0,0,-3), not zero.
Reset works with preview off, and already-default reset is an exact no-op. Finish
any active gesture before reset; invalidate stale events. Save persists normally.

Add a themed Snapping on/off toggle to the visual editor, initially off. Settings
contains separate editable positive finite increments: Move 1 stud, Resize 1 stud,
Rotate 15 degrees by default. Persist increments and enabled preference under an
independent versioned plugin setting; invalid storage uses defaults, failed saves
report an error without activating an uncommitted preference. Turning snapping on
does not immediately change geometry. The editor shows whether snapping is on and
the active mode's increment; Shift modifiers still select existing coordinate/scale
behavior. Settings changes affect subsequent gestures. No config schema changes.

Snap signed mouse-down-relative distance/angle to nearest increment before applying
existing Move/Resize/Rotate math. Use symmetric half-away-from-zero ties so negative
and positive gestures agree. Rotation converts increment degrees to radians at the
helper boundary. Uniform resize snaps the dragged axis's distance, then computes
the existing proportional ratio and anchor; do not independently round dimensions.
Minimum clamping follows snapping. Preserve exact baseline on a snapped-zero delta
to avoid numerical/Euler no-op history. Repeated native events never accumulate.
Changing snap state during a drag finalizes its accepted change once and requires
a fresh mouse-down, matching Shift-transition behavior. Reset/undo never resnap.

Preview toggle label reflects actual visibility as **Preview: On** or **Preview: Off**.
Undo shows **Undo (Ctrl + Alt + Z)** for default bindings; use the actual formatted
configured chord after customization and **Undo (Unbound)** when cleared. Labels
describe current state/binding, not a stale hardcoded promise. Existing Preview Ended
status, disabled Undo state, three-decimal readout and precision preservation remain.

## Automatic Hitbox installation

On one edit-mode plugin startup attempt, ensure
ReplicatedStorage.CombatForge.Runtime.Hitbox exists. Reuse RuntimeInstaller's folder
validation, checked creation and rollback; expose an ensure operation if manual
strict-version install semantics need to remain unchanged. Missing path creation
is one named native undo record. Existing unique ModuleScript, including edited or
older source, is preserved verbatim and treated as present; report that differing
content was preserved rather than silently replacing or claiming an upgrade.
Wrong-class/duplicate path collisions fail visibly without mutation. Identical/
preserved existing content creates no history record. Never run in Play, watch for
deletion or reinstall automatically after user Undo. No render-loop retry; startup
failure can be retried explicitly through the existing install control. Startup in
Play skips safely; user can retry after stopping or on next plugin startup.

Keep automatic setup separate from skill creation/save history. Do not append it
to an unrelated user's waypoint or reset history. Record failure must leave no
partial folders/modules. Availability failures do not prevent opening CombatForge.
Existing TemplateInstaller compatibility checks remain; preserving an edited module
does not falsely guarantee that a newly generated melee template supports it.

## Legacy Example removal and logo

Remove Install Example Skill UI/callback, Main require/injection, ExampleInstaller,
Examples source files, ExampleConfigTemplate/ExampleToolTemplate package entries,
feature-specific active documentation and obsolete tests/harness/package checks.
Update remaining active references/help and test fixtures without weakening retained
features. Historical coordination specs and verbatim original team instructions are
historical records, not production references; do not rewrite them. Preserve all
already-installed game Examples, Tools, modules and user edits. Retain basic melee/
projectile Template Skills and runtime Hitbox. New explicit removal request overrides
the old requirement to keep legacy Example templates packaged; remaining executable
templates must still be disabled inside the executable Legacy Script plugin root.

Coordinator's native probe found direct asset IDs 118596951641724 and 95933009796699
returned preload Failure while the Asset thumbnail route for 118596951641724
returned Success at both 150 and 420 resolutions. Use
`rbxthumb://type=Asset&id=118596951641724&w=150&h=150` for the toolbar branding path.
This preserves the existing artwork; no upload/repaint or new ID is required. The
underlying direct-asset failure cause is unconfirmed; do not claim pending moderation.
Toolbar availability must not depend on remote image loading. Keep a usable fallback
if the branded image cannot load. Native Studio visual evidence is required for
claiming the actual logo is fixed; asset failure is reported separately.

## Acceptance criteria

- **AC-01 — Layout/navigation:** Settings sections have consistent dividers. Home/
  Back remain pinned top-left outside the scroll canvas on every page, with correct
  root disabled state, routes and dirty prompts. Redundant Cancel buttons disappear;
  Back safely leaves delete confirmation and dirty editor via existing safeguards.
  Long content, narrow widget and theme changes do not overlay/hide navigation.
- **AC-02 — Labels/theme:** Preview: On/Off matches actual visibility. Undo displays
  actual chord with default exact suffix (Ctrl + Alt + Z), or Unbound. Parenthetical
  skill-field constraints are removed without weakening validation. New controls,
  dividers and navigation follow existing theme palette and clear disabled states.
- **AC-03 — Reset:** Reset produces 5 x 5 x 6, zero offsets/rotations and proper
  root-local center while preserving unrelated fields. One changed reset is one draft
  undo; no-op reset adds none. Off-preview reset, active gesture interruption, Undo,
  Save and Back-discard paths retain correct geometry/history and stale-event guards.
- **AC-04 — Snapping preferences:** Toggle and three unit-labeled increments are
  editable/persisted with defaults off/1/1/15, validated positive finite input,
  corruption fallback and truthful failed-save behavior. No schema or unrelated
  preference mutation. Changing preferences alone never changes draft geometry.
- **AC-05 — Snapping geometry:** Baseline-relative signed snapping, symmetric ties,
  zero/no-op preservation and minimum clamping work for all Move/Resize faces and
  Rotate axes, including arbitrary root/box rotations, Shift Global/Uniform and
  repeated events. Mode/modifier/snap transitions do not jump or duplicate history.
  Reset and Undo restore exact geometry independently of current snap settings.
- **AC-06 — Runtime ensure:** One safe edit-mode startup attempt creates only a
  missing runtime in one undoable operation. Existing edited/identical modules are
  preserved; conflicts/Play/recording failures produce no partial mutations. Undo
  is not counteracted by a watcher/retry. UI remains usable after setup failure.
- **AC-07 — Example removal:** No active production/package/UI dependency on the
  legacy Example feature remains; obsolete source/docs/test wiring are removed or
  updated. Existing place content is never removed/migrated. Basic Template Skills,
  shared runtime, executable root and disabled remaining template invariants pass.
- **AC-08 — Logo/evidence/regressions:** Use the coordinator-verified 150px Asset
  thumbnail resolver for existing branding, with no new artwork/upload/asset ID,
  with usable fallback and nonblocking startup. Preserve prior keybind/Shift/global
  math, draft lifecycle/Save checks and package behavior. Map isolated and native
  evidence separately, including actual logo visibility and snapping pointer checks.

## Implementation interfaces and ownership

Coder owns affected production/UI/Main/HitboxEditor/RuntimeInstaller, focused
preferences module, default.project.json, legacy Example production removal and
active feature docs. Tester owns Tests/harness/fixtures and test-specific package
expectations; coordinator assigns shared validation-script ownership explicitly.
Coordinator owns branding investigation, PROJECT/STATUS integration, Studio tests,
local install and commit. Planner writes only this spec; workers do not spawn or
mutate Studio/install/commit.

Retain UI.mount capability injection but remove the example argument coherently
across Main/test call sites. Introduce a navigation host separate from existing
scroll content; preserve the button action-instrumentation seam with updated test
locations. Hitbox session gains reset and snapping preference/state capabilities;
pure snap helper takes signed amount/increment so Tester can verify independently.
Follow Theme/Keybinds checked GetSetting/SetSetting patterns for snap preferences.
Share geometry defaults only if a small existing seam fits; do not refactor the
whole schema/template system. Source removal must not touch live Studio copies.

## Validation and constraints

Run affected injected geometry/lifecycle/UI/settings/startup/runtime/template
regressions and updated package tests. No standalone Luau runner is configured.
Coordinator runs Rojo build, `scripts/Test-PluginPackage.ps1 -Path
build/CombatForge.rbxmx` and `git diff --check`; search active source/package/docs
for stale Example references. Tests for removed behavior may be retired by Tester,
but retained template/runtime checks must remain meaningful.

Native checks are not run until observed: pinned nav scrolling/narrow layout,
actual toolbar logo, Snap/Shift interactions on native handles/rings, Settings
persistence across reload, startup runtime creation and Undo without reinstallation,
edited-runtime preservation, dirty Back/Home paths and no retained resources.
Coordinator re-lists Studio and honors PROJECT.md mutation limits before execution.

## Open questions

None. Coordinator resolved the toolbar logo loading route through native probes.
Decisions:
reset affects draft geometry only, snapping uses gesture-relative deltas, labels
reflect actual bindings/state, and automatic runtime ensure runs once without
overwriting existing modules or counteracting Undo.
