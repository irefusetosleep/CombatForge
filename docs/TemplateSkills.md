# Template Skills

Open **Template Skills** from the CombatForge main menu. **Empty Melee Skill**
creates a basic forward attack; **Empty Projectile Skill** creates a straight
flying projectile. These are working starting points with no animation asset
required. Existing game content is preserved.

The two-position slider directly below the projectile button selects **Mouse
Aim** or **Body Aim** before creation. Mouse Aim is initially selected and the
selection stays while this UI is mounted. Each generated projectile keeps its
own editable `AimMode` in its linked config; changing the slider does not update
existing Tools.

Each click creates a fresh `StarterPack.CombatForge Melee Skill` or
`StarterPack.CombatForge Projectile Skill` Tool (numeric suffixes avoid occupied
names). Play, equip it and click. Each Tool contains `Client` (LocalScript),
`Server` (Script), `Skill` (ModuleScript) and `ActivateSkill` (RemoteEvent), needs
no Handle, and cannot be dropped. Save your place to keep the generated Tool.

Each Tool has a corresponding ModuleScript in
`ReplicatedStorage.CombatForge.Abilities`: `MeleeSkill` or `ProjectileSkill`, with
numeric suffixes starting at 2 for occupied names (case-insensitive). Refresh
**Update Skills** to edit its Name, Damage, Cooldown and Range. Defaults are 20
damage, 0.75 seconds cooldown and 6 studs melee reach or 80 studs projectile
travel. Cooldown may be zero. Edits take effect on the next Play session because
Roblox caches required modules during Play.

The Tool's `Skill` ModuleScript contains a nested **Config ObjectValue** pointing
to its exact shared ModuleScript. This external reference survives StarterPack
cloning and config renaming; renaming does not rename the Tool. Deleting the
config disables its dependent Tool until that same config is restored (for
example by Undo). Tools are not cascade-deleted. Missing, invalid, detached or
failed-to-load configurations warn and prevent attacks; no other config is used.

All settings live in that linked config ModuleScript. The four **Update Skills**
controls edit Name, Damage, Cooldown and Range, preserving any supported advanced
fields already present. Edit advanced settings directly in the config source:
AnimationId defaults to an empty string and HitDelay to zero. Melee adds
HitboxWidth = 5 and HitboxHeight = 5; Range controls the forward box's depth.
Projectile adds ProjectileSpeed = 60 studs/second, ProjectileRadius = 0.5 studs,
ProjectileLifetime = 3 seconds and AimMode = "Mouse" or "Body". The first of
range, lifetime or impact ends flight. Each activation captures its settings;
changes to source apply on the next Play session.

AnimationId is optional during playback (leave it empty to skip), but its field
must be present in new template configs. IDs must be usable by your experience
and compatible with its rig. Animation failure warns and still allows the attack.
HitDelay aligns the hit/launch with the animation (0-30 seconds). Width, height
and speed must be finite and positive; radius must be positive and at most 256,
and lifetime positive and at most 60. AnimationId accepts at most 1024 bytes and
no ASCII control characters.

The editor accepts only the supported literal fields, refusing executable custom
source intact. Advanced fields are optional for ordinary legacy four-field
abilities, so their existing create/update and update behavior remains valid.
New template runtimes require their complete per-kind settings with no defaults
in the Skill source. Melee installs or reuses matching
`ReplicatedStorage.CombatForge.Runtime.Hitbox`; edited or conflicting dependencies
are preserved and reported. Projectile has no Hitbox dependency: it uses
continuous server spherecasts and an initial overlap check.

Mouse Aim sends only a finite mouse aim point. Body Aim uses the server character's
forward direction at launch. Server code derives the origin, damage and geometry,
validates ownership/equipped/living state and settings, enforces cooldown, and
rechecks delayed work. Projectiles stop at the first queryable contact including
walls, exclude the caster, and damage a living humanoid at most once. Nonqueryable
parts are not collision surfaces. No homing or target-instance reports are used.
Teardown/unequip/death invalidates pending attacks and flight cleans up on its next
update. You can customize filtering or damage policy in Skill without trusting
new client claims.

Generation requires Edit mode and one undo recording. One successful action
includes the Tool, linked config and any newly required folders/runtime module.
Conflicts and
creation failures preserve existing content and roll back created objects. Plugin
updates preserve your previously generated Tools; generate a fresh template to
compare or manually port fixes into customized copies. For old templates, port
the matching new Skill/client/server code, create a complete per-kind config and
add its nested Skill.Config ObjectValue reference. Copy customized advanced
values into that config; remove the old local settings table. Existing saved
Tools/configs are never rewritten automatically. Rolling back the plugin leaves
new configs intact; an older editor may refuse their extended schema. Bundled
scripts remain
disabled inside the plugin and only generated copies are enabled.

## Visual melee hitbox editing

Open **Update Skills**, select a complete melee or projectile config and choose **Edit Hitbox**.
Save any unsaved common-field edits first. Select an existing R6/R15 dummy Model
(or one of its descendants) in Workspace before opening the editor for automatic
Preview. If selection is invalid, select a dummy and use **Toggle Preview**. The dummy
must contain a Humanoid and a BasePart named HumanoidRootPart. Selecting multiple
dummy models is refused. Changing selection after starting does not retarget it.

For melee boxes, choose **Move** to edit the box's root-local offset along rotated box axes, or **Resize** to change its
width (X), height (Y) or Range/depth (Z). Drag a visible handle; the readouts show
size and offsets in studs. Positive X is root-right, positive Y is up, and negative
Z is forward. Resizing moves only the dragged face, keeping the opposite face fixed. Handle drags use a 0.05-stud minimum dimension; opening an existing
smaller positive box does not change its settings. Sizes that Studio cannot
represent in the preview report an error rather than changing the config.

**Save** writes only the geometry into that config and provides one Undo/Redo
action. Other settings are preserved. Stale/moved/renamed configs must be reopened.
**Back** asks before discarding a changed draft. Navigating away, closing the widget, losing the
reference dummy/root, switching the active Studio tool or entering Play removes
the preview. Previewing does not change the dummy, source or change history and
creates no saved workspace Part. The editor supports complete melee boxes and projectile collision spheres; mixed, partial and custom executable configs are outside its scope.

New melee configs contain HitboxOffsetX/Y/Z = 0. For older supported configs,
omitting all three means zero offsets; a partial triple is invalid. The preview
and current melee runtime both use:

```luau
size = Vector3.new(HitboxWidth, HitboxHeight, Range)
box = root.CFrame * CFrame.new(HitboxOffsetX, HitboxOffsetY, -Range/2 + HitboxOffsetZ)
    * CFrame.fromOrientation(math.rad(HitboxRotationX % 360), math.rad(HitboxRotationY % 360), math.rad(HitboxRotationZ % 360))
```

Older copied Skill code does not consume new offsets automatically. Generate a
fresh melee Tool or manually port the current MeleeSkill's offset capture,
validation and Cast transform into the old copy. Existing Tools/configs remain
intact; adding offsets alone cannot update old runtime code.

## Manual Studio verification — not run

1. In Edit mode, open Template Skills. Confirm button labels, Back, and the slider
   directly beneath the projectile button. Confirm initial Mouse Aim, switch Body
   Aim, leave/return and verify the session selection remains.
2. Generate melee twice and projectile once in each mode. Verify fresh names, four
   children, handle/drop settings, enabled copied scripts and captured AimMode.
   Inspect each Skill.Config ObjectValue and its distinct shared config; verify
   full per-kind source and preserve existing Tools/runtime source. Ctrl+Z removes
   one bundle
   per action; Ctrl+Y restores it, including newly created dependencies where used.
3. Edit advanced values in each config's source, including melee width/height,
   projectile speed/radius/lifetime, AimMode and animation/HitDelay. Refresh Update
   Skills, edit each config's Damage/Cooldown/Range and
   rename one config. Play and verify each Tool uses its own edited values,
   including advanced geometry/timing and zero cooldown. Check the cloned Tool
   retains the external reference.
   Stop, delete a config and Play: its Tool warns and cannot attack. Stop, undo
   deletion and verify it works next Play.
4. Play, equip each Tool and click near a living dummy. Blank AnimationId still
   attacks. Melee damages each target once and never the caster. Rapid clicks
   respect cooldown. Unequip or die during nonzero HitDelay: no delayed damage.
5. Fire Mouse Aim in several directions; Body Aim follows the character instead
   of the cursor. Place a thin wall before a dummy and test high projectile speed:
   the projectile stops at the wall and cannot damage through it. Test starting
   overlaps, misses, range/lifetime expiry and teardown: no persistent projectile.
6. Use a permitted rig-compatible animation and nonzero HitDelay. Verify playback
   precedes hit detection, then use an unavailable ID: no stuck activation. Verify
   subsequent valid attacks and resources after unequip, death and respawn.
7. While playing, attempt template generation: expect an error and no mutations.
   In Edit mode, conflict with the melee Hitbox path: creation must report the
   conflict without replacing it. Confirm existing menu/editor actions.

8. Open Edit Hitbox for a current melee config, select R6 then R15 dummies and
   drag all Move/Resize faces. Rotate/move the reference and verify alignment.
   Save, undo/redo and compare actual Play hit geometry. Use Back and Discard changes after dragging and
   confirm unchanged source/history. Close the widget, navigate away, delete the
   reference and enter Play during preview: all temporary visuals must disappear.
   Try a stale source edit and invalid selection. Save/reopen the place and confirm
   no preview instances remain. Native handle/pointer behavior is not proven by
   isolated geometry or lifecycle tests.

These steps require actual Studio input, physics/queries, rendering, animation
permissions and native change history. Isolated tests cannot prove those results.


### Preview, resize and rotation

Edit Hitbox immediately previews the selected dummy, with manipulation handles
hidden. If selection is invalid, select an existing dummy and click Toggle Preview.
Turning a tool off hides controls without losing the draft; Move, Resize and Rotate expose
only their own controls. Resize moves the dragged face while keeping its opposite
face fixed, with a 0.05-stud minimum on the dragged dimension. Move and resize use
the rotated box axes. Rotation rings turn around the box center.

`HitboxRotationX`, `HitboxRotationY` and `HitboxRotationZ` are a complete optional
triple in degrees; all absent means identity. New melee configs use zeroes. The
orientation is `CFrame.fromOrientation(rad(X), rad(Y), rad(Z))` (Y-X-Z), applied
after the root-local center translation. Rotation does not orbit the offset.
The editor displays equivalent normalized degree values. Save writes all geometry
in one undo record; Back can discard the draft after confirmation. Ordinary skill updates preserve
rotation. Existing copied Tools are preserved: generate a fresh melee Tool or
manually port its updated GetConfig, Validate and Cast to consume rotation.


### Preview controls, scaling and draft Undo

Toggle Preview shows the retained draft using the theme accent when on and surface when off. Move, Resize
and Rotate are mutually exclusive toggles; clicking the active tool hides its
handles. Turning preview off clears tools but preserves geometry and draft undo.
Without Shift, Resize moves one face and holds its opposite face fixed. Shift scales all
three dimensions proportionally while holding the opposite face center fixed;
the other corners of that face may move. Release Shift to restore single-axis scaling. Each completed
geometry gesture is one local Undo step. Undo also works with preview off; during
a drag it restores the drag's starting geometry. Preview/tool/scale toggles are not
history edits. Save creates the normal single config Undo record; Back can discard
the draft after confirmation. Neither operation makes local gestures native Studio history.

Numbers display three decimal places without rounding untouched stored values.
Normal preview termination reads `Preview Ended`; errors retain specific guidance
and leave valid draft geometry available for retry or Save.

Configure five local bindings in **CombatForge Settings**: Toggle Preview, Move,
Resize, Rotate and Draft Undo. Defaults are Ctrl+Alt+P/M/S/R/Z. Change captures a
letter or digit with optional Ctrl/Alt; Escape cancels. Clear unassigns one binding;
Reset defaults resets only keybinds. Changes persist immediately independently of
theme settings. Shift is reserved for transforms, duplicate chords are refused,
and Ctrl+Z/Y remain Studio Undo/Redo. No native shortcut is consumed or reassigned;
if a Studio shortcut shares a chord, change one binding. Local shortcuts are inert
outside the visible visual editor, during Play, saves, text editing and discard prompts.


### Shift transforms and navigation

Move/Resize/Rotate and preview toggles use the current theme accent when selected.
Move and Rotate normally follow box-local axes. Hold either Shift for world-aligned
Move/Rotate, or proportional Uniform Resize with the opposite face center anchored.
The box orientation remains unchanged when only switching coordinate space.
Changing Shift or the reference root frame during a drag finishes that gesture;
release and grab the handle again to continue without a jump. Focus loss, hiding,
Play and editor exit reset modifier state. No modifier is saved in the skill.

Home always opens the main menu. Back follows visual editor -> selected skill ->
Update Skills list -> menu; Settings, Create and Templates return to the menu.
Dirty common or visual drafts ask Keep editing or Discard changes and retain the
requested destination. Keep editing preserves draft/history/preview; explicit
Back asks before discarding the visual draft. Save failures retain the page and draft.


### Pinned navigation, reset and snapping

Home and Back stay in a fixed top-left strip while content scrolls. Root menu
navigation is disabled. Settings separates keybinds, snapping, theme controls and
sharing with labeled dividers. Back replaces redundant Cancel navigation; dirty
drafts still offer Keep editing or Discard changes.

Reset Hitbox changes draft geometry only to 5 x 5 x 6 studs with zero offsets and
rotations, so its default center is (0, 0, -3) in root space. A changed reset is one
local Undo action and works with preview off. No-op resets add no history.

Snapping initially defaults off. Configure positive finite Move/Resize increments
in studs and Rotate increment in degrees in Settings; defaults are 1/1/15.
Preferences persist independently of theme/keybinds/configs. Snapping rounds each
signed gesture delta from mouse-down to the nearest increment, with half ties away
from zero. Uniform Resize snaps the selected face distance before scaling ratios;
minimum limits follow rounding. Switching snapping during a drag finalizes it;
grab again for the next gesture. Reset/Undo restore exact values without snapping.

Preview: On/Off reports actual box visibility. Undo shows the configured chord,
such as Undo (Ctrl + Alt + Z), or Undo (Unbound). Runtime setup runs once on Edit
startup, preserves any existing unique Hitbox module verbatim, and never reinstalls
in response to user Undo. Conflicts/errors can be retried through Install Hitbox
Module. Existing differing runtime source may still be incompatible with newly
generated melee templates; template creation keeps its version protection.


### Projectile collision sphere

Complete projectile configs also expose Edit Hitbox. The automatic spherical
preview is centered exactly at the selected dummy HumanoidRootPart.Position,
matching projectile launch. Radius and diameter display three decimal places;
untouched stored precision is preserved. This previews the collision sphere at
launch, not its trajectory or full travel volume. Range remains travel distance
and is edited in the common skill form.

Projectile editing exposes Resize, preview, snapping, Reset Hitbox, Undo and Save.
Move/Rotate controls are absent and their shortcuts do nothing. Sphere resizing
keeps the center fixed; every face changes radius by its outward drag distance.
Shift does not change sphere geometry or handle orientation. Resize snapping rounds
the radius delta before clamping, without dividing by two. Radius is limited to
256 studs; the minimum is min(0.025, the starting radius), preserving smaller
existing valid values. If Studio cannot render a tiny sphere, the draft/source
remain intact and a rendering error is shown.

Reset changes only radius to 0.5 as one undoable draft action. Save writes only
ProjectileRadius through the existing checked source/Undo operation, preserving
Range, speed, lifetime, aim and damage. Preview off retains draft/history and Save
still works. Existing linked projectile Tools consume the saved radius on next
Play without regeneration; custom/unlinked copies are not linked automatically.
Back precedes Home in the fixed navigation strip on every page.
