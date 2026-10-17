# VISUAL-HITBOX-06 — editor toggles, scaling, precision and draft undo

Status: Final implementation-ready specification. User chose to keep Save/Cancel
drafts and use an Undo button with a separately assigned shortcut instead of native
Ctrl+Z. No blocking questions. Planner owns this specification only.

## Outcome and current behavior

Make the visual hitbox editor behave consistently as an interactive draft editor:
preview can be shown/hidden, transform tools toggle, scaling can affect one axis
or all axes proportionally, numbers are readable, and transform edits can be undone.

`Plugin/HitboxEditor.luau` currently starts an ephemeral CoreGui preview against a
captured dummy root. A Lua table holds geometry; Handles and ArcHandles manipulate
it from mouse-down baselines. Axis resize preserves the opposite face. Destroying
the session loses its draft. There is no draft undo. `Plugin/UI.luau` immediately
starts preview, offers Start Preview plus Preview/Move/Resize/Rotate buttons, uses
four significant digits in the readout, and requires a live session to Save.
Common Range is displayed using tostring. `Main.server.luau` injects the editor
capability. AbilityManager already saves geometry with checked source/history.

Existing injectable suites are `Tests/VisualHitboxGeometry.spec.luau`,
`VisualHitboxLifecycle.spec.luau`, `VisualHitboxMenu.spec.luau` and save/config suites.
They run through the Studio harness; no standalone Luau test runner is configured.
Rojo is present at `C:\Program Files (x86)\Rojo\rojo.exe`.

## Interactions and assumptions

Opening Edit Hitbox still attempts preview automatically, with handles hidden.
Replace Start Preview with the exact label **Toggle Preview**. Its background is
green when the box is visible and black when off; text must remain legible. Remove
the separate Preview mode button. Move, Resize and Rotate are mutually exclusive
toggles: active background green, inactive black. Clicking the active tool hides
its handles; clicking another selects that tool. An internal no-handles mode may
remain named Preview. Turning preview off clears the selected tool and hides all
adornments; turning it on resumes the same draft with handles hidden. Toggling is
never a Save, Cancel or history reset. On initial invalid selection, off state
remains usable for retry; retry captures a valid current selection. Once a reference
is captured, ordinary selection changes do not retarget it.

Hiding the dock widget suspends rendering and releases preview resources while
retaining the page's draft and undo history in memory. All shortcuts are inert
while the widget is disabled. Showing it again does not restart preview automatically;
Toggle Preview resumes it explicitly. Closing or navigating away from the editor
(including Cancel, successful Save, Back or root destruction) discards the page's
draft/history. Widget hiding therefore differs from closing the editor page.

Expose **Axis** and **Uniform** scale choices near Resize, with one visibly selected.
Axis is the default and retains the current one-sided behavior. Uniform uses the
same six face handles, scales all three dimensions by one positive ratio, and
anchors the opposite face center (not all of that face's corners). This explicit
definition avoids pretending proportional scaling can keep the full opposite face
unchanged. Choosing a scale option is not a geometry edit. It clears a live drag
baseline to prevent a drag from changing interpretation halfway through.

Display numeric editor values with exactly three decimal places, including common
Damage/Cooldown/Range and all size/offset/rotation values. Normalize displayed
negative zero to 0.000. This is display rounding, not an instruction to quantize
stored geometry. Opening and saving unrelated fields must preserve the original
precision of untouched numeric fields; track unchanged display text against its
original numeric value rather than reparsing the rounded text unconditionally.

Normal preview termination status is exactly **Preview Ended** (capitalization
included), covering explicit off and lifecycle termination. Genuine input/render/
save errors remain actionable diagnostic messages; do not hide failures under a
generic success-looking termination status. A failure after a valid draft exists
retains that draft on the page for safe retry/Save. Closing the editor discards it.

Add an **Undo** button that restores the previous completed geometry gesture.
Empty history is visibly unavailable and a safe no-op. Preview/tool/scale choices
are not undone. Undo works while preview is off. No redo UI is required.

Keybinds invoke the same action callbacks as buttons. Prefer native PluginActions
registered once per plugin lifetime: Toggle Preview, Move, Resize, Rotate and Draft Undo.
These appear in Studio Customize Shortcuts; document recommended bindings
Ctrl+Alt+P, Ctrl+Alt+M, Ctrl+Alt+S, Ctrl+Alt+R and Ctrl+Alt+Z respectively, not automatic
defaults. Draft Undo must not replace Studio Ctrl+Z.
The public documented PluginAction API offers no writable default shortcut.
Do not claim defaults are installed. Actions must be inert outside an enabled
Edit Hitbox page, during Play, busy saves and text editing. Native binding conflict
management belongs to Customize Shortcuts. No hidden global single-letter handlers
or interception of Studio's existing transform shortcuts.

## Geometry

Retain the established orientation and center convention from VISUAL-HITBOX-05:
R = fromOrientation(degree XYZ), c = (OffsetX, OffsetY, -Range/2 + OffsetZ).
For selected axis a, baseline dimension s[a], signed outward face distance d,
and local signed face normal n:

- Axis: sNew[a] = max(0.05, s[a] + d); other dimensions unchanged.
- Uniform: qDesired = (s[a] + d) / s[a]. Clamp q to a positive ratio such that
  each resulting dimension meets min(0.05, its baseline dimension); this preserves
  pre-existing subminimum geometry without an initial jump. sNew = s * q.
- Both: cNew = c + R:VectorToWorldSpace(n * (sNew[a] - s[a]) / 2).
- Recover offsets using new Range: (cNew.X, cNew.Y, cNew.Z + sNew.Z/2).

Uniform anchor is c - R*n*s[a]/2. Ratios and orientation stay fixed; all six faces,
rotated roots/boxes, inward drags and clamping obey this equation. Reject nonfinite
results before accepting a draft. Use the captured baseline rather than accumulating
MouseDrag deltas. No runtime/template/schema changes are needed.

## Acceptance criteria

- **AC-01 — Preview toggle:** Automatic valid entry shows one box and no handles;
  Toggle Preview uses green/on and black/off. Off/on preserves exact geometry and
  draft history, clears tools and does not persist or duplicate resources. Missing
  selection gives retry guidance. Repeated failed/successful retries remain safe.
- **AC-02 — Tool toggles:** No Preview mode button remains. Move/Resize/Rotate
  show exactly one green active button, black inactive buttons, and only appropriate
  handles. Clicking the active tool hides handles and makes every tool inactive.
  Hidden, stale and interrupted drag events cannot mutate geometry.
- **AC-03 — Scale choices:** Axis default matches existing six-face one-sided
  resize. Uniform preserves dimension ratios and opposite face center per equations,
  including arbitrary root/box rotations, repeated delta events and minimum limits.
  Toggling scale alone never changes geometry or adds undo history.
- **AC-04 — Precision/text:** Numeric editor displays use three decimal places,
  including common Range and visual Range/depth, with no displayed negative zero.
  Untouched underlying values keep full precision through normal saves. Lifecycle
  status reads exactly Preview Ended; useful errors remain specific.
- **AC-05 — Keyboard actions:** Five visible native shortcut-bindable actions
  call the same transitions as buttons; help explains Customize Shortcuts and the
  recommended keys. Page visibility, Play, busy and text-entry guards apply.
  Bindings/connections do not multiply across reopen/rebuild and release on unload.
  No automatic default assignment or native shortcut consumption is claimed without
  supported API and actual evidence.
- **AC-06 — Draft Undo:** A completed nonzero Move/Axis Resize/Uniform Resize/
  Rotate drag is one undoable edit, regardless of MouseDrag event count. Undo button
  and its separate shortcut restore the exact previous draft/readout/preview without
  changing any Studio history or saved config. No-op drags/toggles add no history.
  Multiple edits undo in reverse order. Mid-drag undo ends the current gesture and
  restores its starting geometry once. Empty history is a safe no-op. Preview off/on
  retains history; Undo while off updates the next visible preview. Save still creates
  the existing one config undo record; Cancel never saves; both end draft history.
  Never listen to global OnUndo to pop local history or bind over Studio Ctrl+Z.
- **AC-07 — Lifecycle/preservation/evidence:** Maintain cleanup on page close,
  widget hide, reference removal, Play, tool deactivation and unload. No preview or
  undo metadata is serialized into the place; no dummy/source changes before Save.
  Widget hide releases rendering resources but retains page-local draft/history;
  shortcuts stay inert while hidden and showing never automatically resumes preview.
  Page close/navigation, Cancel, successful Save and root destruction discard history.
  Preserve stale-source checks, save rollback, themes, unrelated config, projectile
  behavior and package invariants. Report native checks separately from mocks.

## Implementation plan, interfaces and ownership

Coder owns Plugin/HitboxEditor.luau, Plugin/UI.luau, Plugin/Main.server.luau and
focused editor documentation; AbilityManager changes only if necessary for
preserving untouched common numeric values. Tester owns Tests and independent
AC evidence. Coordinator owns Studio experiments, integration, STATUS, local
installation and commit. No worker creates agents, installs or mutates Studio.

Separate draft ownership from preview visibility: a page-scoped editor controller
retains geometry/history while optional rendering resources are active. Suggested
capabilities are getDraft, setPreviewVisible, setMode, setScaleMode, undo and destroy,
with an onStateChanged notification so buttons/readouts reflect the same state.
Exact names may follow existing conventions. Preserve capability injection for
tests. Centralize begin/end-gesture handling; interruption finalizes an accepted
nonzero gesture once, and stale mouse-up never adds another entry. Keep snapshots
as copied geometry tables. Save reads the page's draft even while preview is off.

Register PluginActions at startup and route them only to a live page controller.
Destroy/disconnect only owned actions/resources, never global Studio bindings or
history. Do not call ResetWaypoints/SetEnabled to manipulate native undo globally.

## Undo decision and evidence

The user explicitly chose to keep Save/Cancel drafts and add an Undo button with
a separately assigned shortcut, replacing the original native Ctrl+Z request.
Use page-local copied geometry snapshots with no ChangeHistoryService calls for
individual drags. Ctrl+Z remains Studio's normal saved/world-history action.

Coordinator's isolated probe successfully recorded a CoreGui NumberValue change
after the MCP outer recording finished, but GetCanUndo still identified the previous
world waypoint instead of the probe. No Undo was invoked; owned objects were cleaned
up. CoreGui-only draft history therefore did not establish native recording support
in current Studio. OnUndo also fires after world undo, so it cannot safely substitute
local snapshots for native history. No broader history/storage redesign is needed.

Primary API references inspected:

- [ChangeHistoryService](https://create.roblox.com/docs/reference/engine/classes/ChangeHistoryService)
- [PluginAction](https://create.roblox.com/docs/reference/engine/classes/PluginAction)
- [CreatePluginAction](https://create.roblox.com/docs/reference/engine/classes/Plugin/CreatePluginAction)
- [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService)

## Validation

Extend existing isolated suites for toggle state, exact display, preserved numeric
precision, scale math, gesture history, no-op/interrupted gestures and lifecycle
cleanup. Run existing save/config/common form regressions. Build with `rojo build
default.project.json -o build/CombatForge.rbxmx`, validate with
`scripts/Test-PluginPackage.ps1 -Path build/CombatForge.rbxmx`, and `git diff --check`.
Native checks not run until actually performed: shortcut delivery with viewport
and dock focus; text-entry isolation; handle pointer direction; proportional
resize anchor; dedicated Draft Undo shortcut and normal Studio Ctrl+Z separation;
save Undo/Redo; off/on/close cleanup.

## Open questions

None. The user resolved the only blocking choice in favor of draft Save/Cancel,
Undo button and a separate user-assigned shortcut. Uniform opposite-face-center
anchor, Axis default, display-only rounding and native user-assigned action bindings
are documented choices based on existing behavior and public API constraints.
All ACs are ready for implementation and independent test preparation.
