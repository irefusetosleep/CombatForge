# VISUAL-HITBOX-05 — preview by default, one-sided resize and rotation

Status: Final implementation-ready specification. Supersedes VISUAL-HITBOX-04's
initial Move mode and symmetric resize. Working tree was clean at inspection.

## Outcome and existing behavior

The user requests immediate preview, no initial yellow handles, resize moving only
the dragged face, and a Rotate mode. HitboxEditor currently starts in Move, parents
visible Handles before refresh initializes its proxy, and grows dimensions by twice
the drag distance about a fixed center. UI requires Start Preview. Existing safe
config serialization, snapshot save, offset semantics and cleanup should be reused.
The visible yellow controls are consistent with current always-visible Handles;
actual native visibility/flash behavior still needs Studio verification.

## Interaction and scope

Opening Edit Hitbox immediately attempts to start against the currently selected
valid dummy, in **Preview** mode. The translucent box is visible; all manipulation
handles are hidden. If selection is missing/invalid, retain the page and clear
instructions plus **Start Preview** retry. Selecting a dummy and clicking retry
starts Preview. No automatic dummy creation or SelectionChanged watcher is needed.
Once started, later selection changes never retarget the reference. Expose Preview,
Move, Resize and Rotate controls. Returning to Preview hides all handles without
losing the draft. Keep explicit Save/Cancel and existing lifecycle behavior.

## Geometry and persisted fields

Add optional numeric HitboxRotationX, HitboxRotationY, HitboxRotationZ, in degrees.
They must be either all absent (identity) or a complete finite triple. General
schema accepts any finite degrees; no arbitrary angle restriction. New melee
configs include zeroes. Saving visual geometry writes a complete triple and
preserves every nongeometry setting. Existing all-absent configs stay valid.

Use this exact convention in preview, manipulation and melee runtime:

- `R = CFrame.fromOrientation(rad(X), rad(Y), rad(Z))` (Roblox Y-X-Z orientation).
- `c = Vector3.new(OffsetX, OffsetY, -Range/2 + OffsetZ)` in root-local coordinates.
- `box = root.CFrame * CFrame.new(c) * R`.
- `size = Vector3.new(HitboxWidth, HitboxHeight, Range)`.

Rotation is about the box center; it does not rotate the center offset around the
root. Convert a resulting rotation using `ToOrientation()` (the matching inverse),
then degrees. Equivalent Euler representations at singularities are acceptable;
compare orientation matrices/basis vectors, not raw Euler values. Normalize angles
for calculation/readout to a stable equivalent range such as [-180,180); merely
opening a config must not change its saved source. Reduce finite angles before
conversion to avoid overflow from very large finite degree values.

For move/resize, let `n` be the dragged face's signed unit normal in box-local axes,
and `d` the outward signed distance from mouse-down, as provided by Handles.
Use the mouse-down baseline and captured mode/axis, never accumulated event deltas.

- Move: `cNew = c0 + R0:VectorToWorldSpace(n * d)`, size unchanged.
- Resize: affected dimension `sNew = max(minimum, s0 + d)`; effective change
  `delta = sNew - s0`; `cNew = c0 + R0:VectorToWorldSpace(n * delta/2)`.
  Other dimensions and rotation stay fixed. The opposite face's full plane and
  corners stay fixed; the dragged face moves by delta along its normal.
- Recover root-local offsets after either operation as
  `(cNew.X, cNew.Y, cNew.Z + newRange/2)`. The depth compensation is essential
  even when a rotated box's X or Y face affects root-local Z.
- Rotate: ArcHandles axis is a box-local axis. Capture baseline rotation R0 and
  center c0 on mouse-down; apply `Rnew = R0 * CFrame.fromAxisAngle(axis, angle)`
  from the drag's baseline angle. Center and size remain unchanged. Do not simply
  increment one Euler field during an arbitrary local-axis rotation.

Keep the existing handle minimum 0.05 studs, using effective clamped delta for the
center shift. Preserve smaller valid existing dimensions when opening; do not
resize other dimensions as a side effect. Rotation readouts use degrees; size and
offset readouts remain studs.

## Acceptance criteria

- **AC-01 — Default preview and hidden handles:** Opening the eligible editor with
  valid selection starts one Preview session automatically, showing only the box.
  Invalid selection creates no resources and gives explicit retry guidance. Set
  both Handles and ArcHandles invisible before parenting/Adornee assignment; first
  initialize valid geometry, and expose only the control for the selected mode.
  No handle flash is intended on entry. Preview mode ignores stray drag events.
  Move/Resize show Handles; Rotate shows ArcHandles; mode switch clears baselines.
- **AC-02 — One-sided oriented resize and move:** All six resize faces follow the
  equations above, preserving opposite-face world positions under arbitrary root
  and box rotation. Outward/inward distances and minimum clamping are correct;
  baseline-based repeated events do not accumulate. Move follows oriented box
  axes. Size, center and offsets round-trip consistently through the depth-based
  representation. Invalid/nonfinite drag inputs fail safely without corrupting
  source or generating invalid preview geometry.
- **AC-03 — Rotation UI and math:** Rotate offers visible usable axis rings,
  applies baseline local-axis rotations, preserves center/size, and updates the
  visible box/handle frame and degree readout. Multiple drags on different axes
  compose correctly. Switching back to Move/Resize manipulates the rotated axes;
  switching to Preview retains draft with no handles. Hidden/inactive or stale
  mouse-up/drag events cannot mutate the draft.
- **AC-04 — Config/save/runtime consistency:** Literal schema, serializer,
  template defaults, editor draft/copy/geometry whitelist, AbilityManager's checked
  save and melee GetConfig/Validate/Cast all support the optional complete finite
  rotation triple. All-absent means identity; partial/invalid triples fail closed.
  Per-activation capture includes rotation. Saved preview orientation/position/size
  equals actual runtime Hitbox.Box geometry. Ordinary Update Skills preserves
  rotations; one Save has one native undo record and retains stale-source checks,
  rollback and unrelated settings. Existing four-field/offset-only configs remain
  supported, and existing copied Tools are not rewritten.
- **AC-05 — Lifecycle and preservation:** Automatic entry/retry/mode changes do
  not persist mutations before Save. Retain cleanup on Cancel, successful Save,
  widget hide, navigation, theme rebuild, root/UI destruction, reference loss,
  Play transition, plugin deactivation and unload. Dispose both handle types and
  all callbacks, including half-finished drags. Never restart automatically after
  teardown/deactivation. Retry replaces at most one session. No persistent preview
  objects or dummy changes; preserve projectile/example and editor behavior.
- **AC-06 — Evidence and guidance:** Update interaction instructions and docs,
  including angle convention, rotated local axes, one-sided resize and fresh-Tool/
  manual-port upgrade for older runtime copies. Independently test geometry,
  config/save, UI auto-start and event lifecycle; verify package/build invariants.
  Native handle visibility, pointer direction and rotation-ring usability remain
  not run until performed in Studio; report actual evidence and Reviewer verdict.

## Implementation plan and ownership

Coder edits Plugin/HitboxEditor.luau, UI.luau, AbilityConfig.luau,
AbilityManager.luau, TemplateInstaller.luau, Templates/MeleeSkill.luau and focused
docs as needed. Extend existing pure geometry helpers rather than introducing a
new framework. UI shares one start helper for auto-entry and retry; preserve its
existing button-helper instrumentation seam. Initialize handles hidden, construct
geometry, then set mode. ArcHandles event signatures and parenting/visibility must
be checked against current Roblox API during implementation; existing unparented
proxy and CoreGui preview ownership should remain where supported. No runtime
Hitbox API changes are needed. Tester owns Tests/VisualHitbox*.spec.luau and relevant
harness/runtime/template regressions. Coordinator owns integration, Studio work,
installation and commit. Planner modifies only this specification.

## Validation and constraints

Geometry tests compare opposite-face corners/planes for all six faces, nontrivial
root and box rotations, mixed-axis rotation sequences, negative drag/minimum clamp,
Range compensation, center-preserving rotation and runtime equivalence. Assert
basis vectors rather than Euler equality around 90-degree singularities. Test
missing/partial/nonfinite/large finite rotations, round trip, common-field update,
stale/failed save and exact geometry capture. Lifecycle/UI tests assert auto-start
once, invalid-selection retry, invisible-before-parenting order, initial Preview,
mutually exclusive handles, baseline reset and zero leftover resources.

Run relevant injected-loader suites, `rojo build default.project.json -o
build/CombatForge.rbxmx`, `scripts/Test-PluginPackage.ps1 -Path
build/CombatForge.rbxmx`, and `git diff --check`. No standalone shell Luau test
runner is configured. Actual Studio manual checks: open with valid/invalid selection,
observe no yellow initial handles, switch all modes, drag every face of a rotated
box with opposite face fixed, rotate each ring across repeated drags, Save/Undo/Redo,
then compare Play hit geometry; verify hide/cancel/Play/deactivation cleanup.
Workers may not mutate Studio; coordinator re-lists connections and follows
PROJECT.md limits. Isolated tests do not establish native pointer correctness.

## Open questions

None. Explicit retry after absent initial selection is the smallest reliable
fallback; no automatic selection watcher or persistent dummy is needed. Rotation
is relative to the box center using a documented degree/Euler convention. This
scope changes interaction and adds orientation, without projectile editing,
snapping controls, animation previews or automatic migration of old Tools.
