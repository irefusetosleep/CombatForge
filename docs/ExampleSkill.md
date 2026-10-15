# Example Slash

In the plugin's main menu, click **Install Example Skill** in edit mode, then save your place. Installation adds:

```text
ReplicatedStorage
  CombatForge
    Abilities
      ExampleSlash                 -- editable four-field configuration
    Runtime
      Hitbox                       -- standalone detection module
StarterPack
  CombatForge Example Slash        -- Tool; RequiresHandle = false
    ActivateSkill                  -- RemoteEvent; activation requests only
    Client                         -- LocalScript; sends a request when clicked
    Server                         -- Script; verifies equipped player
    Skill                          -- ModuleScript; cooldown, hitbox and damage
```

## Try it

1. Add a Roblox rig/training dummy with a Humanoid to Workspace using Studio's rig builder. Put it near the player spawn. Use an NPC rig rather than another player's character for the first test.
2. Press **Play**, equip **CombatForge Example Slash** from the hotbar, face the dummy and click while within six studs.
3. A green box flashes in front of you. The dummy takes 20 damage once per activation; the cooldown is one second. Output prints each damaged target. A dummy with a ForceField may resist damage.
4. Stop Play. Open **Update Skills → ExampleSlash** and change Damage, Cooldown or Range. Save, then start a new playtest to try those values. The config is required once per game session.
5. Read `StarterPack.CombatForge Example Slash.Skill` for the commented implementation. `Client` and `Server` show the activation request and ownership check.

Keep the configuration ModuleScript named **ExampleSlash**, since Skill requires that path. If you rename it, update the require path in Skill. The plugin editor accepts literal configuration data; keep executable behaviour in the separate Skill module.

## What it demonstrates

The client requests activation without sending a target, damage or position. The server verifies the Tool is equipped by the requesting player's current character. The skill rejects dead/missing characters and applies a per-Humanoid cooldown using server time. It constructs a box from the server's character position and the configuration's Range, connects to HitDetected, and casts once. The hitbox groups character limbs into one target. The listener applies configured damage to living Humanoids and excludes self damage. The detector is cleaned up after event delivery; a short-lived, non-queryable Part shows the scan's position.

This is a minimal attack example: it has no animation or wall obstruction test. Each activation scans immediately; the visible box is a preview, not a continuous attack. See [Hitbox documentation](Hitboxes.md) for sphere examples and detection limits. To use a sphere, replace Hitbox.Box with Hitbox.Sphere(root.Position, Config.Range, options).

Installation is undoable and installs a missing Hitbox dependency automatically. Reinstalling a complete example preserves edited configuration and Tool code. Conflicting names or incompatible runtime/configuration objects are reported before changes are made. Back up and rename a conflicting object to install a fresh copy. To remove the example, delete its StarterPack Tool and ExampleSlash configuration; keep the shared Hitbox module if other skills use it.
