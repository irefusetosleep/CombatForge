# VISUAL-HITBOX-07 — settings keybinds, theme, navigation and Shift transforms

Status: Final implementation-ready specification. Supersedes VISUAL-HITBOX-06's
native-only keybind configuration, fixed toggle colors and Axis/Uniform buttons.

## Outcome and current behavior

Configure editor shortcuts directly in CombatForge Settings, make active editor
controls follow the chosen theme, distinguish Home from Back, and use Shift for
temporary transform modifiers. Existing Save/Cancel draft semantics and dedicated
Draft Undo remain authoritative; native Studio Ctrl+Z must remain untouched.

Current `Plugin/Main.server.luau` registers five native hitbox PluginActions.
`Plugin/UI.luau` exposes theme Settings, common-form discard prompts, fixed green/
black visual-editor toggles, Axis/Uniform buttons and page-specific Back callbacks.
`Plugin/HitboxEditor.luau` holds a page-local draft/undo history and renders oriented
Handles/ArcHandles against an unparented proxy. Move/Rotate currently use box-local
axes; resize supports both scale choices. Theme.palette already provides accent,
accentText, surface and text. Reuse these seams and existing injected Studio suites.

## Interaction, scope and assumptions

Settings gains five labeled keybind rows: Toggle Preview, Move, Resize, Rotate and
Draft Undo. Each shows its chord and offers Change and Clear; Reset defaults resets
this keybind group only. Change captures the next valid nonmodifier key with held
Ctrl/Alt modifiers. Escape cancels capture without changing the binding. Save each
accepted change immediately through a separate versioned plugin setting; report
save failure and keep the last successfully committed bindings active. Defaults
are Ctrl+Alt+P/M/S/R/Z respectively. These are plugin-local input matches, not
assignments to Studio Customize Shortcuts. Retire the five native hitbox actions
to avoid double dispatch when old native assignments overlap; preserve OpenEditor.

Normalize left/right Ctrl and Alt; require an exact modifier match. Shift is reserved
for transforms and rejected in configurable chords. Permit letters/digits with
optional Ctrl and/or Alt, including an unmodified letter/digit. Reject bare modifier
keys, Unknown, Escape, mouse/gamepad keys, duplicate chords and the exact native
Undo/Redo chords Ctrl+Z and Ctrl+Y. Shift-bearing chords, including Ctrl+Shift+Z,
are already excluded by the reserved modifier rule. Do not claim to detect every
Studio binding or consume native single-key transform shortcuts:
help states that a user-created Studio shortcut using the same chord must be changed
in one place. No global shortcut interception/consumption is promised.

Own input listeners dispatch once per physical press, not repeat, only when the
enabled visual editor is active, not playing, not saving, not prompting to discard,
not capturing a keybind and no text input owns focus. Processed input does not dispatch.
Capture in Settings consumes input for configuration only and never invokes actions.
Cancel capture on navigation, widget hide, focus loss or unload. Corrupt saved data
falls back safely to validated defaults; persistence errors remain visible.

Use palette.accent/accentText for selected controls and palette.surface/text for
inactive controls throughout Update Skills and its visual editor. Retain appropriate
error/destructive semantics and existing theme controls. No new color settings or
preview/handle color overhaul is required. Three-decimal display and precision
preservation continue unchanged.

Provide explicit Home and Back controls on subordinate pages. Home always targets
the root menu; Back follows fixed meaningful parent routes: visual editor -> selected
skill form -> Update Skills list -> root; Create New Skill/Settings/Templates -> root;
delete confirmation -> Update Skills list. Do not build an unbounded visit history
or make Back bounce through refresh/settings rebuilds. Root needs neither control.
Dirty common/visual drafts prompt Keep editing or Discard changes before Home/Back;
the pending destination is retained so Discard goes to the requested page. Keeping
editing preserves draft, history and renderer. Clean drafts navigate immediately.
Explicit visual Cancel remains an intentional discard without an extra prompt.
Save failure keeps the editor and draft. Settings persist accepted keybind changes
immediately, so those changes do not create an unsaved skill prompt.

Remove Axis/Uniform buttons. Without Shift, Resize remains one-sided single-axis.
With either Shift held, Resize uses the existing proportional Uniform formula and
opposite-face-center anchor. Move/Rotate normally use box-local axes; with Shift
they use world/global axes. Show concise current modifier guidance/state. Shift is
temporary and never a saved preference or geometry edit by itself.

For a Shift transition during a drag, finalize any accepted nonzero change as one
undo gesture, invalidate that drag baseline and ignore subsequent events until a
fresh mouse-down. Update handle orientation immediately without changing geometry.
Explain in help: release and grab the handle again after changing Shift mid-drag.
This explicit safe boundary avoids jumps and avoids fabricating continuous drag
rebaselining. Key release, focus loss, widget hide, editor exit, Play, deactivation
and unload reset modifier state. Reconcile actual held keys on fresh focus/gesture
only through available input APIs; never retain a stale latched Shift state.
Release/focus-loss bookkeeping runs even for processed input or during capture;
ordinary action-dispatch guards must not suppress cleanup of held-key state.

## Geometry and handle frames

Keep persisted root-local XYZ offsets, degree XYZ rotation and Range convention.
At mouse-down capture root frame T0, box-local rotation R0, size s0 and root-local
center c0. Let Q0 be T0's rotation and W0 = Q0 * R0. Distances/angles remain measured
from the captured gesture baseline, not accumulated events.

- Local Move: cNew = c0 + R0*n*d, where n is the signed local handle face normal.
- Global Move: cNew = c0 + Q0:VectorToObjectSpace(n*d), where n is the signed world
  X/Y/Z normal. Size and orientation remain unchanged.
- Local Rotate: RNew = R0 * Rot(axis, angle), with center and size fixed.
- Global Rotate: RNew = Q0:Inverse() * Rot(worldAxis, angle) * W0. This is rotation
  about the box's world-space center, not around the world origin or dummy root.
- Resize stays box-local with or without Shift. Reuse existing Axis/Uniform ratio,
  minimum and center-shift equations from VISUAL-HITBOX-06; Shift selects Uniform.
- Recover OffsetZ from cNew.Z + newRange/2 after every operation. Convert RNew using
  matching ToOrientation and retain finite-value validation/normalization.

The visible box always uses its actual rotated frame. The handle proxy is at the
box center with box orientation for Local Move/Rotate and either Resize variant;
Global Move/Rotate proxy uses identity world orientation. Do not rotate the preview
box to make the handles global. Use proxy geometry/orientation consistently for
Handles and ArcHandles. If the reference root frame changes during a gesture,
finish/invalidate it rather than mixing live and captured frames; next gesture
captures a fresh root. This preserves draft root-local semantics without jumps.

## Acceptance criteria

- **AC-01 — Settings and persistence:** All five keybinds can be captured, cleared
  and reset in Settings; defaults, normalization, duplicate/reserved-key validation,
  cancellation, corrupt storage and failed persistence follow the contract. Saved
  bindings reload on a new plugin lifetime without changing theme data.
- **AC-02 — Scoped input:** A configured chord invokes its matching editor action
  exactly once per press. Hidden/noneditor/Play/text/busy/prompt/capture contexts do
  not invoke it. Old five native hitbox actions no longer duplicate dispatch;
  OpenEditor survives. No Ctrl+Z interception or native settings assignment occurs.
  Input resources and pressed-state tracking clean up across all lifecycle paths.
- **AC-03 — Theme:** Update Skills and visual-editor active/inactive controls use
  accent/accentText and surface/text across Dark, Light and Custom themes. Existing
  semantic errors/destructive controls remain distinct. No hardcoded green/black
  selection styling remains in these controls.
- **AC-04 — Home/Back:** Home reaches root and Back reaches each declared parent.
  Dirty common and visual drafts prompt for either route; Keep preserves exact
  draft/history, Discard reaches the intended destination and cleans resources.
  Clean routes, Cancel, Save success/failure and repeated navigation stay coherent.
- **AC-05 — Shift Resize:** Axis/Uniform buttons are absent. Shift selects uniform
  proportional resizing; release restores single-axis behavior. All faces, rotated
  boxes, minimum clamps and opposite-face anchors retain existing math. Modifier
  alone does not mutate the draft or history. Transition mid-drag creates no jump,
  finalizes at most one edit and rejects stale events until fresh mouse-down.
- **AC-06 — Global Move/Rotate:** Shift gives world-aligned handles and correct
  world-axis translation/centered rotation with arbitrary root and box rotations;
  release restores local handles/operations. Root-local save/runtime convention,
  center, size and degree orientation remain correct. Root changes during a gesture
  terminate it safely; undo restores the exact baseline for either frame mode.
- **AC-07 — Regression/lifecycle/evidence:** Retain preview toggles, automatic
  initial preview, three-decimal displays without precision loss, page-local Undo,
  Save source/history checks, widget-hide draft retention and no auto-restart.
  Modifier/capture/input/preview resources reset safely on focus loss, navigation,
  hide, Play, deactivation and unload. No saved preview objects, runtime/schema
  changes or rewritten existing Tools. Distinguish isolated and native evidence.

## Implementation plan and interfaces

Coder owns UI, HitboxEditor, Main and focused docs. A small `Plugin/Keybinds.luau`
module may own validated defaults, chord normalization/matching and independent
versioned GetSetting/SetSetting persistence, following Theme.new's checked-save
pattern. Inject this controller and input service seams into UI/Main for tests.
Keep one shared action dispatch path for button and local keybind behavior. One
input/modifier owner forwards modifier state to the live editor session; a
`setShiftHeld` capability and expanded state (coordinate space/scale) are sufficient.
Keep pure geometry helpers testable with explicit coordinate frame parameters.
Use existing route functions plus a destination-aware discard guard, not a router
framework. Theme requires no schema change. Tester owns Tests only; Planner owns
this spec; coordinator owns integration/STATUS/Studio/install/commit. Workers do
not spawn, install, commit or modify Studio.

## Validation and Studio constraints

Extend geometry, lifecycle, visual menu, common menu, startup and settings tests.
Assert world position/orientation matrices for nontrivial rotated roots; equivalent
Euler triples are acceptable. Cover keyboard duplicate presses, exact modifiers,
capture cancel, invalid stored settings, failed SetSetting/readback, both Shift
keys, lost release/focus, mid-drag transitions, dirty destination prompts and
palette values. Use existing injected-loader Studio harness; no standalone Luau
runner is configured. Coordinator runs Rojo build, package validation with
`scripts/Test-PluginPackage.ps1 -Path build/CombatForge.rbxmx` and `git diff --check`.

Native checks remain not run until performed: local input delivery with viewport
and dock focus, text-field exclusion, Settings capture/persistence, modifier release
after focus changes, global-axis pointer/ring direction, no jump during Shift/root
transition, themed controls and navigation discard flows. Mocks cannot establish
Studio shortcut priority or native input delivery. Re-list Studio connections and
follow PROJECT.md place mutation constraints before coordinator integration checks.

## Open questions

None. Documented implementation choices are fixed parent navigation, immediate
keybind persistence with Ctrl+Alt defaults, retiring duplicate native hitbox actions,
Shift reserved as a temporary transform modifier, and explicit gesture termination
on modifier/root-frame changes. The user's prior dedicated Draft Undo decision
continues; native Ctrl+Z is outside this feature.
