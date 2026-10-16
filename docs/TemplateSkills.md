# Template Skills

Open **Template Skills** from the CombatForge main menu. **Empty Melee Skill**
creates a basic forward attack; **Empty Projectile Skill** creates a straight
flying projectile. These are working starting points with no animation asset
required. Existing Example Skill behavior is unchanged.

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
abilities, so their existing create/update and Example behavior remains valid.
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
   conflict without replacing it. Confirm existing menu/editor/example actions.

These steps require actual Studio input, physics/queries, rendering, animation
permissions and native change history. Isolated tests cannot prove those results.
