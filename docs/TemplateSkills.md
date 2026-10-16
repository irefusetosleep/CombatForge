# Template Skills

Open **Template Skills** from the CombatForge main menu. **Empty Melee Skill**
creates a basic forward attack; **Empty Projectile Skill** creates a straight
flying projectile. These are working starting points with no animation asset
required. Existing Example Skill behavior is unchanged.

The two-position slider directly below the projectile button selects **Mouse
Aim** or **Body Aim** before creation. Mouse Aim is initially selected and the
selection stays while this UI is mounted. Each generated projectile keeps its
own editable `AimMode`; changing the slider does not update existing Tools.

Each click creates a fresh `StarterPack.CombatForge Melee Skill` or
`StarterPack.CombatForge Projectile Skill` Tool (numeric suffixes avoid occupied
names). Play, equip it and click. Each Tool contains `Client` (LocalScript),
`Server` (Script), `Skill` (ModuleScript) and `ActivateSkill` (RemoteEvent), needs
no Handle, and cannot be dropped. Save your place to keep the generated Tool.

Edit `Skill.Config` directly in the generated Tool: Damage defaults to 20,
Cooldown to 0.75 seconds, AnimationId to an empty string and HitDelay to zero.
Melee defaults to a 5 wide x 5 high x 6 deep forward box. Projectile defaults to
80 studs range, 60 studs/second, radius 0.5 studs and a 3 second lifetime. The
first of range, lifetime or impact ends flight. Optional animation IDs must be
usable by your experience and compatible with its character rig. Animation
failure warns and still allows the attack; blank IDs skip playback. Set HitDelay
to align the hit/launch with the animation. Server code marks each pipeline stage.

Generated Skill modules are self-contained boilerplate, separate from **Update
Skills** configurations. That editor's schema is unchanged. Melee installs or
reuses the matching `ReplicatedStorage.CombatForge.Runtime.Hitbox`; an edited or
conflicting dependency is preserved and reported. Projectile has no shared runtime
dependency: it uses continuous server spherecasts, with an initial overlap check,
because the existing Hitbox runtime provides static scans rather than travel.

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
includes the Tool and any newly required runtime folders/module. Conflicts and
creation failures preserve existing content and roll back created objects. Plugin
updates preserve your previously generated Tools; generate a fresh template to
compare or manually port fixes into customized copies. Bundled scripts remain
disabled inside the plugin and only generated copies are enabled.

## Manual Studio verification — not run

1. In Edit mode, open Template Skills. Confirm button labels, Back, and the slider
   directly beneath the projectile button. Confirm initial Mouse Aim, switch Body
   Aim, leave/return and verify the session selection remains.
2. Generate melee twice and projectile once in each mode. Verify fresh names, four
   children, handle/drop settings, enabled copied scripts and captured AimMode.
   Confirm existing Tools/runtime source are unchanged. Ctrl+Z removes one bundle
   per action; Ctrl+Y restores it, including newly created dependencies where used.
3. Play, equip each Tool and click near a living dummy. Blank AnimationId still
   attacks. Melee damages each target once and never the caster. Rapid clicks
   respect cooldown. Unequip or die during nonzero HitDelay: no delayed damage.
4. Fire Mouse Aim in several directions; Body Aim follows the character instead
   of the cursor. Place a thin wall before a dummy and test high projectile speed:
   the projectile stops at the wall and cannot damage through it. Test starting
   overlaps, misses, range/lifetime expiry and teardown: no persistent projectile.
5. Use a permitted rig-compatible animation and nonzero HitDelay. Verify playback
   precedes hit detection, then use an unavailable ID: no stuck activation. Verify
   subsequent valid attacks and resources after unequip, death and respawn.
6. While playing, attempt template generation: expect an error and no mutations.
   In Edit mode, conflict with the melee Hitbox path: creation must report the
   conflict without replacing it. Confirm existing menu/editor/example actions.

These steps require actual Studio input, physics/queries, rendering, animation
permissions and native change history. Isolated tests cannot prove those results.
