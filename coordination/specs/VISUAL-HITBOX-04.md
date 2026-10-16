# VISUAL-HITBOX-04 — visually edit a melee box on a dummy

Status: Implementation-ready plan; dependent on completed TEMPLATE-ALL-CONFIG-03.
All current in-flight production/test edits belong to that task and are preserved.

## Outcome, current behavior and scope

Let the user select a supported melee config, preview its box relative to a dummy,
drag handles to move/resize it, and explicitly save dimensions/offsets back to the
linked config. Current melee geometry is Width x Height x Range, with center at
HumanoidRootPart.CFrame * CFrame.new(0, 0, -Range / 2). Projectile uses swept
spheres and different travel settings. This first editor supports the existing
melee box only; projectile shapes, rotation, multiple hitboxes, animation timelines
and arbitrary custom Skill code are excluded. Existing Spawn Dummy can provide an
R6/R15 reference model; editing must not spawn or modify a persistent dummy.

AbilityConfig now has a safe scalar whitelist/parser, AbilityManager has checked
snapshots/source updates, and UI's Update Skills page identifies individual modules.
Reuse those contracts. Never execute a place config to preview or edit it.

## Interaction and data contract

From Update Skills, a supported melee config offers **Edit Hitbox**. Support means
safe parsed common fields plus valid melee Width/Height, AnimationId and HitDelay,
and no projectile-specific settings; don't infer support from its name. The editor
shows the selected ability name and instructions to select an existing dummy Model
(or its descendant) containing a Humanoid and BasePart HumanoidRootPart in Workspace.
An explicit **Start Preview** captures that reference. Invalid/multiple-model
selection produces guidance without mutation. Expose **Move**, **Resize**, **Save**,
and **Cancel**; show current size and local offset values as readouts. No advanced
numeric form is required. Cancel returns to the skill editor; Save reports success
and returns there with a fresh snapshot. Changing Studio selection never silently
retargets the running session.

Resize edits HitboxWidth (X), HitboxHeight (Y), Range (Z/depth). Move edits new scalar
HitboxOffsetX, HitboxOffsetY, HitboxOffsetZ. These are additive offsets in the dummy/
caster root's local axes, not absolute world coordinates. Both preview and runtime:

`size = Vector3.new(HitboxWidth, HitboxHeight, Range)`
`center = root.CFrame * CFrame.new(HitboxOffsetX, HitboxOffsetY, -Range/2 + HitboxOffsetZ)`

Positive X is root-right, positive Y up, negative Z forward. Zero offsets retain
the existing forward box behavior. On resize keep the current box center fixed and
adjust saved Z offset when depth changes; dragging a resize face changes only its
corresponding dimension. The opposite faces move symmetrically around that center.
Use mouse-down geometry plus current drag distance rather than accumulating deltas.
Explain size/offset units are studs. No rotation handles are needed.

New melee configs include all three offsets as zero. The general literal schema
allows these optional finite signed numbers. Existing configs with all offsets
absent use zero for runtime/editor compatibility. Reject a partially specified
triple or invalid number; don't silently hide malformed settings. A visual Save
writes a complete triple and dimensions while preserving every other supported
field, including Name, Damage, Cooldown, AnimationId and HitDelay.

## Acceptance criteria

- **AC-01 — Eligible entry and reference:** The supported melee config can open
  Edit Hitbox and explicitly start preview against one valid selected dummy/root.
  Unsupported/custom/projectile configs and invalid selection receive clear
  guidance without source/dummy mutation. Works with R6/R15 root frames. No
  arbitrary place code executes during eligibility, preview or Save.
- **AC-02 — Visible manipulable draft:** A translucent, non-colliding preview
  displays the actual oriented box relative to the dummy. Move and Resize offer
  visible draggable axis/face handles with readouts. Dragging updates an in-memory
  draft only using the stated axes, center/resize behavior and transform. Reject
  nonfinite values and prevent nonpositive dimensions; for handles use a small
  positive minimum such as 0.05 studs, without changing parser/runtime acceptance
  of existing smaller positive dimensions. Do not clamp valid existing configs
  merely by opening them. Reference-root movement updates the preview correctly.
- **AC-03 — Safe explicit Save:** Save validates the complete draft and updates
  only Width/Height/Range and the three offsets in the exact snapshotted config.
  Preserve other supported values and module identity. Use ScriptEditorService
  checked source update and one ChangeHistoryService recording, so one native
  Undo/Redo restores/reapplies the config. Stale source/name, moved/deleted config,
  Play mode, invalid draft or unavailable recording prevent overwrite and report
  a useful error. Failed Save leaves existing config unchanged and cancels its
  recording; retain draft where safe for retry or tell the user to reopen.
- **AC-04 — Runtime geometry matches:** New melee template GetConfig captures
  and validates the offset triple, supporting all-absent as zero for older configs.
  Cast uses exactly the preview transform and dimensions. Common editor updates
  preserve offsets. New melee generation includes zero offsets. Existing no-offset
  behavior, projectile behavior, collision/damage authority and delayed activation
  safety remain unchanged. Existing copied Tools are preserved; docs explain that
  old Skill code needs fresh generation or manual porting to consume offsets.
- **AC-05 — Preview isolation and lifecycle:** Opening, dragging and Cancel do
  not alter config, dummy, existing game objects or history. Use plugin-owned
  nonpersistent adornments/preview geometry; no saved game Part, scripts or dummy
  are created. Preview does not collide, query, run damage or survive into Play.
  End the session and dispose all handles, temporary objects and connections on
  Cancel, successful Save, navigation away, theme/UI rebuild, widget closure/destruction, plugin
  unload, Play transition or reference dummy/root deletion. At most one editor
  session exists; repeat open/close does not accumulate resources. Avoid stealing
  selection for preview; do not move the real dummy or its parts.
- **AC-06 — Evidence and delivery:** Cover geometry math in rotated roots, drag
  baselines/minimums, optional offset schema/preservation, stale/failed Save,
  repeated lifecycle cleanup and runtime geometry equivalence. Preserve existing
  all-config/template/editor/example tests and package invariants. Document the
  workflow, offset convention, supported scope, old-Tool upgrade and manual native
  checks; report actual checks and Reviewer verdict without calling mocks native
  Studio verification.

## Implementation plan, interfaces and dependencies

1. After ALL-CONFIG-03 completes, extend AbilityConfig's explicit scalar fields,
   validation and serializer with the offset triple. Extend TemplateInstaller's
   melee defaults and MeleeSkill snapshot/validation/Cast transform. No Hitbox
   runtime API change is needed.
2. Add a focused plugin HitboxEditor module owning session/draft, geometry,
   adornments/Handles and lifecycle. Use appropriate native Studio handles for
   move/resize; verify current API parenting/visibility and plugin mouse ownership
   before choosing primitives. Keep preview instances outside serialized place
   content; Archivable=false alone is not proof of nonpersistent editor effects.
   Separate pure geometry calculations enough for direct independent testing.
3. Add a narrow AbilityManager save-geometry operation or shared internal checked
   save helper, taking a Snapshot and only geometry inputs. Reuse the existing
   source/name/parent checks and recording pattern. Do not weaken four-control
   update behavior or expose an unchecked arbitrary table/source replacement API.
4. Wire UI Edit Hitbox entry, selection instructions, Move/Resize/readouts and
   Save/Cancel controls. Main passes plugin/lifecycle capability as needed, and
   widget hide/unload cleanup terminates the session. Preserve existing mount
   callers with optional dependencies. Preserve the existing button-helper test instrumentation seam. Extend Rojo packaging for the new module.
5. Coder owns production/docs; Tester owns tests and isolated harness adaptations.
   Coordinator integrates after ALL-CONFIG-03, runs native verification where
   authorized, installs and commits. Planner edits this specification only.

## Failure behavior and Studio constraints

Edit mode only. Editing a draft never marks a config saved. A config changed by
another editor during the session must be reopened rather than overwritten.
Reference loss cancels preview with guidance; ordinary selection changes are not
reference loss. Capture source through GetEditorSource so open editor buffers count
as changes. Undo applies only to successful persistent config changes, not each
mouse move. Generated config values are authoring data; runtime remains server
validated. Use no arbitrary new numeric offset bounds beyond finiteness; handle
unrenderable/unsupported preview sizes with an error rather than corrupting data.

Manual Studio checks (not run until performed): generate a current melee Tool,
spawn/select an R6 then R15 dummy, open its supported config, move/resize all axes,
verify rotated/moved dummy alignment, Save, inspect values, undo/redo and compare
actual Play hit geometry. Cancel after dragging and compare source/history; close
widget, navigate away, delete dummy and enter Play during a session, verifying no
preview artifacts/connections remain. Test stale source edits and missing root.
Check saved/reopened place has no preview instances. Coordinator re-lists Studio
connections and respects PROJECT.md authorization; workers do not mutate Studio.

Run relevant isolated Luau suites, `rojo build default.project.json -o
build/CombatForge.rbxmx`, `scripts/Test-PluginPackage.ps1 -Path
build/CombatForge.rbxmx`, and `git diff --check`. Native handles, pointer feel,
replication/Play and Undo/Redo require actual Studio verification.

## Open questions

None blocking. Melee-only box support and additive local offsets are the smallest
coherent implementation of the accepted visual-editing request, preserving existing
range/depth behavior. No rotation/projectile editor or persistent preview-dummy
creation is included. Escalate discovered product conflicts before scope changes.

