# Example Slash

Click **Install Example Skill** in edit mode and save your place. The plugin installs the editable `ReplicatedStorage.CombatForge.Abilities.ExampleSlash` configuration, the shared `Runtime.Hitbox` module, and the **CombatForge Example Slash** Tool in StarterPack.

Each click demonstrates both modes together:

- **Left box:** a regular `Hitbox.Box` scan on the server.
- **Right box:** a `Hitbox.ClientToServer` scan on the client, followed by server validation.
- Both use the new final `true` debug parameter. Green snapshots last 0.25 seconds. The right box has a local prediction and a replicated server preview, so these may overlap or separate slightly under latency.
- The boxes overlap by one stud. A shared per-activation target set ensures overlapping targets take damage only once.

The client sends one candidate report through the Tool's ActivateSkill RemoteEvent, including on a miss. The server endpoint checks that the sender has the enabled Tool equipped. Its Authorize callback starts the regular scan and initializes the shared damage set; then the runtime validates the client candidates against the right box on the server. Neither client predictions nor client-supplied damage are used to damage targets.

Add a training dummy, press Play, equip the Tool and click facing it. Default damage is 20, range is six studs, and cooldown is one second. Try targets on the left, right, and middle. The left box works without a client candidate; the right requires a client-reported target that also passes the server query. ForceFields can prevent damage.

Edit Damage, Cooldown or Range through **Update Skills → ExampleSlash**, then restart the playtest. Network cooldown has a minimum of 0.05 seconds. Keep the configuration named ExampleSlash. Skill contains the regular scan, server endpoint and shared damage handling; Client creates the prediction endpoint; Server binds and cleans up the server endpoint. The configuration remains data only.

This example has no animations or wall obstruction checks. The runtime has no latency rewind. See [Hitboxes](Hitboxes.md) for the API and validation limits.

## Updating an existing example

The installer preserves existing Tool code and configuration. To get this revision, stop Play, move the old **CombatForge Example Slash** Tool from StarterPack into ServerStorage as a backup, then click **Install Example Skill**. If the installer reports an outdated Hitbox module, rename it to HitboxBackup and retry. Your supported ExampleSlash configuration is retained. Save and restart the playtest afterward.

Installation supports Studio undo. Git versions the source project separately; see [Versioning](Versioning.md).

## Spawn a test dummy

Click **Spawn Dummy** on CombatForge's main menu in edit mode. It casts a ray 1,000 studs forward from the camera and places a standard R6 dummy above the first collidable surface. If nothing is hit (or no camera exists), the dummy's pivot is placed at exactly `(0, 0, 0)`.

Every body part is unanchored. The dummy has 100 health, the display name **Dummy**, and Roblox's native health bar set to AlwaysOn, with name and health display distances of 1,000 studs. It is selected after spawning, and creation supports Studio undo. Physics applies during Play, so a dummy without ground underneath will fall.

The display uses Roblox's [Humanoid health and name properties](https://create.roblox.com/docs/characters/name-health-display).

Newly spawned dummies include a server-side DummyIdle script that loops the classic R6 idle animation (180435571) during Play. It uses Idle priority so attack animations can override it, and stops on death or removal. Existing dummies need to be respawned to receive the script. Animations do not automatically play in edit mode.
