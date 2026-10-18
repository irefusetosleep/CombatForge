# BEZIER-SLIDERS-01 — Bezier sliders and concise editor copy

## Outcome and current behavior

Add easy, themed X/Y/Z control-offset sliders to projectile Bezier editing while
keeping precise numeric entry. Reduce repetitive explanatory copy in Edit Hitbox.
Base: `6beb98d`; no runtime, template, trajectory-math or config-schema changes.

`Plugin/UI.luau` currently exposes three control-offset TextBoxes only in Bezier
mode, commits on FocusLost, and displays three decimals without rounding untouched
stored values. `Plugin/HitboxEditor.luau` validates each `commit(patch)` and pushes
one draft-history entry per changed commit. Its native handle gestures already use
a baseline and `finishGesture()` to group updates. Copy in HitboxInstructions,
HitboxShortcuts, ProjectilePathHelp and HitboxModifier repeats button behavior.

## Interactions, assumptions and failure behavior

- Each Bezier axis has a visible slider and its existing numeric entry/caption:
  X right, Y up, Z forward; offsets are studs. Keep existing TextBox names so
  current UI callers and test expectations remain usable.
- Use a linear symmetric range per axis, initially `[-100, 100]`. Expand its bound
  to `min(10000, max(100, abs(acceptedValue)))` when needed to represent an existing
  or newly typed legal value. Bounds may remain expanded during the page visit;
  freeze bounds during each drag to avoid moving the coordinate scale under the
  pointer. Opening, displaying, expanding or changing modes never clamps or edits
  values. Numeric entry retains the entire existing `[-10000, 10000]` legal range.
- Pointer down on the track starts a gesture and chooses the bounded coordinate;
  movement updates that one axis continuously, synchronizing its numeric display,
  marker, sampled path and control marker. The other fields retain exact values.
  Slider movement need not impose additional snapping or rounding. The numeric
  display remains three decimals; untouched entries preserve stored precision.
- One changed drag produces exactly one draft Undo step; no-op gestures produce
  none. Undo during a drag restores its baseline and invalidates the capture.
  Ordinary numeric/mode commits remain individual existing Undo operations.
- Leaving the track ends the drag; movement resumes editing only after a fresh
  pointer down. Use track MouseButton1Down/MouseMoved GUI coordinates rather than
  mixing screen/global coordinates, which may differ for docked/floating widgets.
  Global InputEnded is a completion fallback, not a source of track coordinates.
  Mouse release outside the track/widget, window focus loss, widget hide, Preview
  hide/deactivation, run-state changes, navigation/prompt, other draft actions and
  disposal terminate capture. Preserve accepted values as one completed gesture;
  no later pointer movement can mutate them until a new intentional pointer down.
  Navigation retains the existing dirty-draft prompt. Disposal retains no listeners.
- Slider edits may update a valid draft with Preview off just as numeric edits do;
  they do not start Preview implicitly. With Preview on, each accepted update
  renders immediately and stops current projectile playback as current edits do.
- Use existing validation/render failure behavior and concise status errors; reject
  invalid/nonfinite numeric input without corrupting draft/history. An invalid or
  ended session cannot start/update gestures. No opening-only dirty state or Save.
- Copy cleanup is confined to Edit Hitbox. Keep action labels, axis meaning,
  units, errors, dirty/discard feedback and useful current state. Replace repetitive
  paragraphs with short copy retaining: launch sphere/radius distinction; sample
  aim from dummy forward; no collision simulation; Range caps traveled distance
  and speed/lifetime also bound preview travel; old Tools need regeneration or
  manual Skill + Trajectory replacement preserving Config for curves. Keep a
  compact Shift/snapping state for melee; remove projectile Shift repetition.

These are implementation choices within the requested sliders/copy change; no new
settings persistence, keyboard binding, runtime behavior or place data is added.

## Acceptance criteria

1. **AC-01:** Bezier shows themed X/Y/Z sliders alongside precise numeric entries
   with axis direction and studs. Straight hides all three slider/input/caption
   groups, retaining exact authored controls across mode changes.
2. **AC-02:** Pointer coordinates map linearly and clamp to the current per-axis
   bounds, including endpoints and zero. Existing/typed legal values outside
   +/-100 expand the display up to +/-10000 without mutation or precision loss;
   numeric full-range validation and unchanged-value precision remain intact.
3. **AC-03:** Repeated drag updates alter only the selected control axis and update
   display/path live. Exactly one Undo restores all values before the drag;
   no-op drag adds no history. Numeric commits, mode changes, Reset, native Resize
   and Save retain existing semantics and do not accidentally merge gestures.
4. **AC-04:** Track leave, outside release, focus loss, widget/preview hide, deactivation, Play
   transition, navigation/discard prompt, Undo and unloading/disposal end capture.
   Stale movement cannot edit the draft; repeated visits/disposal leak no listeners.
5. **AC-05:** Editor copy is materially shorter without losing sample-aim,
   collision-free, travel-cap, old-Tool upgrade, axis/unit, error or discard meaning.
   Existing buttons remain discoverable; other pages are outside this copy edit.
6. **AC-06:** Only explicit Save writes source. Legacy absent trajectory defaults,
   exact numeric values, existing configs/Tools and runtime/schema/math behavior
   remain compatible. Rojo root remains an executable Script; package validates.

## Implementation and interfaces

Coder owns `Plugin/UI.luau` and `Plugin/HitboxEditor.luau`; avoid a general slider
framework or unrelated ColourPicker changes. Tester owns affected specs and the
isolated loader/harness under `Tests/`. Coordinator owns STATUS/project delivery.

1. Extract/share the existing projectile candidate validation/application logic
   inside HitboxEditor so ordinary commits and drag updates validate identically.
2. Add a small explicit session gesture API, recommended names
   `beginControlDrag(key)`, `updateControlDrag(value)` and
   `endControlDrag()`. Begin whitelists X/Y/Z and Bezier; update uses the same
   candidate validation but does not push intermediate history. End pushes one
   changed baseline. Reuse existing lifecycle finalization without merging native
   handle and slider baselines. Undo cancels active capture, so UI must observe
   ended gesture state or a generation/token before applying later movement.
3. UI owns current pointer/track and local ranges. Route track down/MouseMoved and
   track leave/release/global release through those methods. Reuse mount-level input lifecycle
   hooks and explicit page cleanup; terminate before actions/navigate inspect the
   draft. Session lifecycle termination must also invalidate UI capture. Size-zero
   tracks do not divide by zero or start a value edit. Do not use global movement
   coordinates to calculate positions inside docked/floating plugin widgets.
4. `changed(draft)` synchronizes range/marker/TextBox and group visibility;
   `updateState` synchronizes availability/capture. Use Theme palette colors.
5. Slim only editor copy, then retain relevant existing UI regression assertions
   by checking preserved meaning rather than old full paragraphs.

Dependencies are existing Theme, UserInputService and editor validation; no new
runtime modules, dependencies, packages, settings, permissions or schema fields.
Roblox dock-widget pointer/global-event behavior needs native manual verification;
an isolated signal mock does not prove capture outside the widget in Studio.

## Validation and Studio constraints

Rojo is available on this host; no standalone `luau` or `lune` command was found.
Existing `Tests/RunTemplateChecks.luau` loads isolated sources and real Instances in
Studio with service/signal substitutions. Extend its UI loader only as needed for
track pointer events and global release; run projectile editor, trajectory, editor
input and relevant existing UI/geometry regressions. Assert history boundaries,
large exact values, invalid values, untouched axes, stale input and listener cleanup.

Coordinator runs `rojo build default.project.json -o build/CombatForge.rbxmx`,
`scripts/Test-PluginPackage.ps1 -Path build/CombatForge.rbxmx`, and
`git diff --check`. Workers neither install nor mutate Studio. Coordinator must
re-list connections before authorized isolated tests in **CombatForge Testing**
(98128576921103), clean fixtures, and report AC evidence passed/failed/blocked/not
run. Plugin install/commit remains coordinator-owned; no publish/deploy/push.

Manual Studio checks — **not run** at specification time:

1. Open projectile Edit Hitbox with valid dummy; select Bezier. Drag each axis
   across center/endpoints; confirm theme, readable layout, live marker/path,
   one Undo, and exact typed large values. Switch Straight/back; controls survive.
2. In docked and floating widgets, drag beyond track/widget and release; resume
   movement without a new down (including moving back over the track).
   Repeat with focus loss, hide/show, preview hide, native deactivation, Play,
   Undo, Back/Keep editing and unload/reopen. Values must stop at termination and
   no stale movement or repeated-visit handler changes may occur.
3. Check narrow and wide widget widths; captions, numbers, track and marker remain
   usable. Confirm concise travel/sample/upgrade warning meaning. Save and reopen
   exact values; verify melee handles, shortcuts, Shift and snapping still work.

## Open questions

None.
