# Project context

CombatForge is a Roblox Studio plugin for authoring combat skills. Repository:
`C:\Users\lewis\Documents\CombatForge`. PowerShell, Rojo, Luau. Git branch main;
no remote. Builds and plugin backups are ignored. Local installed plugin:
`C:\Users\lewis\AppData\Local\Roblox\Plugins\CombatForge.rbxmx`.

## Read by task

- UI/theme/editor: `Plugin/UI.luau`, `Theme.luau`, `ColourPicker.luau`,
  `AbilityConfig.luau`, `AbilityManager.luau`.
  Update Skills includes per-skill trash buttons, named delete confirmation and
  change-history deletion supporting Studio undo; Refresh reloads restored skills.
- Plugin startup and package: `Plugin/Main.server.luau`, `default.project.json`,
  `scripts/Test-PluginPackage.ps1`, `scripts/Install-Plugin.ps1`.
- Runtime hitboxes: `Runtime/Hitbox.luau`, `docs/Hitboxes.md`.
  Box/Sphere scan locally; ClientToServer reports client candidates and validates
  on the server. Optional final boolean draws short-lived debug previews.
- Example: `Examples/*`, `Plugin/ExampleInstaller.luau`, `docs/ExampleSkill.md`.
  One click runs a regular left box and validated client/server right box;
  shared per-activation hit tracking prevents double damage.
- Dummy: `Plugin/DummySpawner.luau`, `Runtime/DummyIdle.server.luau`.
  Camera-facing unanchored grey R6/R15 dummy, selected beneath Spawn Dummy;
  classic smile, unlocked parts, void fallback origin, native name/health;
  rig-specific default idle runs on the server during Play.
- Existing checks: `Tests/*.spec.luau`. These return functions accepting isolated
  dependencies/loaders; they are not a ready-to-run shell test suite. Studio MCP
  can execute Luau. No standalone Luau test runner is currently configured.

Persistent game paths: `ReplicatedStorage.CombatForge.Abilities` and
`ReplicatedStorage.CombatForge.Runtime.Hitbox`. Installers protect edited copies.
Plugin loading previously failed with a Folder root; preserve the Script root.

The user authorized temporary isolated hitbox tests with cleanup in the Studio
place **CombatForge Testing**, place ID 98128576921103. Re-list Studio connections
before use. Obtain confirmation for other place mutations not already authorized.

Latest plugin feature commit: `5833e53` (confirmed skill deletion with Studio undo support).
See `git log` for current versions, rather than relying on chat history.
