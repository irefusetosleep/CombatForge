# PROJECTILE-EDITOR-01 — projectile radius editing and navigation order

Status: Final implementation-ready specification. No blocking questions.

## Outcome and inspected behavior

Place pinned Back before Home and let supported projectile skills edit their
actual spherical collision size through Edit Hitbox. Keep the existing projectile
runtime contract rather than introducing an unrelated box representation.

UI currently positions Home at x=12 and Back at x=112. HitboxEditor and
AbilityManager.saveGeometry accept complete melee configs only; nine box geometry
fields are whitelisted. AbilityConfig already validates ProjectileRadius as a
finite number greater than zero and at most 256. TemplateInstaller supplies radius
0.5, speed 60, lifetime 3 and Mouse/Body aim. ProjectileSkill starts at root.Position,
uses a visual ball of diameter 2*radius and sweeps Spherecast with that radius.
Range is travel distance, limited also by lifetime/speed and obstacles. No projectile
offset/rotation fields are consumed. Existing tests cover schema/save failures,
injected native handles, UI lifecycle and actual projectile spherecasts.

## Interaction and scope

Every pinned navigation strip shows **Back**, then **Home**, left to right,
including root's disabled controls. Preserve positions relative to content, theme,
routes and dirty-discard prompts; this is order only, not a navigation redesign.

Expose Edit Hitbox for complete supported projectile configs as well as melee.
Classification uses fields, never skill names. A projectile requires validated
common fields plus AnimationId, HitDelay, ProjectileSpeed, ProjectileRadius,
ProjectileLifetime and AimMode, with no melee width/height/offset/rotation fields.
Partial, mixed or custom configs remain unsupported with truthful guidance.
Do not execute user config source. Keep common dirty-form guard before entry.

Projectile entry auto-previews a translucent sphere centered exactly on the selected
dummy HumanoidRootPart.Position. Its radius equals the draft ProjectileRadius;
the rendered diameter equals 2*radius. Root orientation does not affect a sphere.
Use a real spherical adornment/representation, not a box labeled as a sphere.
The existing selection rules and retained reference semantics apply. Explain that
this is the projectile's collision sphere at launch, not a path simulation or
full travel-volume preview, and Range remains editable in the common skill form.

Expose Preview: On/Off, Resize, snapping, Reset Hitbox, Undo and Save with existing
state labels/theme/bindings. Hide Move/Rotate controls for this shape; their shortcuts
are safe no-ops and must not activate handles or dirty the draft. Explain that a
sphere has no directional orientation and launch position is runtime-defined.
Initial handles remain hidden. Resize toggles six face handles on a centered proxy
whose size is the sphere diameter. Any dragged face changes radius uniformly while
keeping center fixed; Shift does not change projectile behavior. Do not claim
one-sided resize for a sphere. Readout shows Radius and Diameter in studs to three
decimal places, preserving full stored precision. No independent numeric input is
required; visual handle dragging provides the requested editing interaction.

For baseline radius r0 and native signed outward face distance d, compute
rNew = clamp(r0 + d, min(0.025, r0), 256). The lower bound corresponds to the existing
0.05-stud proxy diameter limit while preserving smaller valid source radii without
an opening/clamp jump. If renderer limitations reject a valid tiny radius, preserve
its draft/source and report a render error rather than silently changing it.
All six faces use the same outward-distance convention. With snapping enabled,
snap d using the existing Resize stud increment before clamping; this represents
radius movement at the dragged surface, so no division by two. Zero/clamped no-op
results preserve exact baseline and add no undo entry. Repeated events use baseline.

Reset Hitbox restores radius 0.5 only, as one undoable draft change; already-default
reset is a no-op. Do not reset Range, speed, lifetime, aim, Damage or other fields.
One completed changed resize gesture is one undo entry. Existing snap/modifier/root
transition cancellation rules may safely end the gesture, but Shift never changes
the radius math or handle frame. Preview off/widget hide retains draft/history;
Back/Home prompts before discarding changes; Save is available with preview off.

Save only ProjectileRadius for projectile snapshots. Reject injected Range, box
geometry or other keys at the manager boundary. Reuse stale-source/name/path checks,
checked UpdateSourceAsync, one native Save recording and rollback. Save updates
the existing linked config; ProjectileSkill already consumes this field on the
next Play session, so no runtime/schema/template migration is required. Existing
linked projectile Tools benefit without regeneration; custom/unlinked copies do
not gain a link automatically. Draft Undo remains separate from Studio Ctrl+Z.

## Acceptance criteria

- **AC-01 — Navigation order:** Back precedes Home on all pages, remains pinned
  during scroll, and preserves root-disabled state, theme, parent routes and dirty
  confirmation behavior.
- **AC-02 — Eligibility/model:** Complete supported projectile configs expose
  Edit Hitbox. Partial/mixed/custom configs fail closed. Projectile draft/copy/
  equality/reset/save use ProjectileRadius only; melee retains its existing geometry
  contract. Existing radius validation remains finite, >0 and <=256.
- **AC-03 — Spherical preview/UI:** Valid selection auto-shows a radius-correct
  sphere at root.Position with no initial handles. Preview toggle and three-decimal
  radius/diameter readout reflect actual state. Resize works; Move/Rotate controls
  are absent and corresponding shortcuts do nothing. Help distinguishes launch
  sphere from travel Range/path and describes uniform centered resizing.
- **AC-04 — Resize/snap/reset/Undo:** Every face applies baseline r0+d, correct
  bounds, signed snapping and fixed center. Root rotation and Shift cannot deform
  or reorient a sphere. Repeated events, tiny radii, maximum clamp, no-op gestures,
  stale events and interrupted gestures are safe. Reset sets radius 0.5 and preserves
  all unrelated settings. Undo restores exact radius with one entry per actual edit.
- **AC-05 — Checked persistence/runtime parity:** Projectile save accepts exactly
  one radius field, preserves Range and all other config values, and retains stale
  target/source/conflict/history/rollback protections. Saved radius equals runtime
  Spherecast radius and visual diameter/2; next-Play linked config use needs no new
  fields or regenerated Tool. No config mutation occurs before Save.
- **AC-06 — Lifecycle/regression/evidence:** Missing selection/retry, preview hide,
  widget hide/show, reference removal, Play, deactivation, navigation and unload
  preserve established cleanup/draft semantics. No persistent preview instances or
  source evaluation. Melee, settings/keybinds/snapping, automatic runtime ensure and
  package invariants remain intact. Native interaction evidence stays separate from
  injected tests.

## Implementation plan and interfaces

Coder owns focused AbilityConfig, AbilityManager, HitboxEditor, UI changes and
active editor/template docs; Main only if injection must change. Introduce a small
shape classification/capability seam (for example kind Melee/Projectile and supported
modes) and shape-specific geometry keys/defaults. Reuse the existing session,
history, snapping and lifecycle rather than duplicating a whole editor. Pure radius
resize helper accepts baseline radius/distance; tests need not manufacture box fields.
Manager chooses its whitelist from the validated snapshot, not caller-provided kind.
Do not broaden the melee whitelist to accept arbitrary projectile fields. Render
sphere via SphereHandleAdornment (coordinator's isolated native Radius/CFrame/
Transparency/AlwaysOnTop property probe passed and cleaned up); use existing
unparented handle proxy and plugin-owned CoreGui lifetime. UI dirty comparison,
readout, help and controls follow shape capabilities. Retain existing action
instrumentation and dependency injection for tests.

Tester owns Tests, fixtures/harness and independent AC expectations; Planner only
this specification. Coordinator owns STATUS/PROJECT, integration, Studio tests,
local install and commit. Workers do not spawn, commit, install or mutate Studio.
No runtime damage logic, trajectory editing, aiming, offsets, rotation, box projectile
collision, numeric advanced-settings editor or schema migration is in scope.

## Validation and constraints

Extend VisualHitboxConfig/Geometry/Lifecycle/Menu/Save and navigation tests for both
shapes; cover 0, negative, nonfinite, >256 radius and mixed-field input. Test all
faces, positive/negative distances, snap ties, clamps, tiny valid baselines, rotated
dummy, reset/undo, off-preview saves and rejected extra save keys. Test injected
recording/editor failures and concurrent changes for projectile save. Reuse
TemplateRuntime/TemplateWorld assertions that Spherecast and ball size consume
the saved radius; no runtime implementation changes are expected.

Coordinator runs affected injected-loader Studio suites, Rojo build,
`scripts/Test-PluginPackage.ps1 -Path build/CombatForge.rbxmx`, and `git diff --check`.
No standalone Luau runner is configured. Native checks are not run until observed:
sphere visibility at root (including occlusion), six-face handle hit testing and
outward/inward direction, snap/undo/reset, navigation order and scrolling, Save then
next-Play projectile collision size. Re-list Studio and follow PROJECT.md mutation
limits; mocked handles cannot prove pointer behavior or real Studio Undo.

## Open questions

None. The user's request maps to the existing projectile spherecast radius. Scope
assumptions are radius-only hitbox editing, centered launch preview, hidden unsupported
Move/Rotate controls, reset to template radius 0.5, and unchanged Range/trajectory.
These preserve current runtime behavior while making the collision size editable.
