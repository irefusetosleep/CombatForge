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
- Visual melee hitbox authoring: `Plugin/HitboxEditor.luau`, `AbilityManager.saveGeometry`, and Update Skills -> Edit Hitbox. Select an existing R6/R15 dummy; opening Edit Hitbox automatically starts Preview with handles hidden. Toggle Preview retains draft while hiding/showing it; green Move/Resize/Rotate buttons toggle handles. Axis/Uniform scaling and gesture Draft Undo are page-local. Numeric display uses three decimals without reducing untouched precision. Five native PluginActions are user-bindable in Customize Shortcuts. Save or Cancel explicitly. Draft preview is plugin-owned; Save writes size, signed root-local offsets and degree XYZ rotation triples with checked source/history. Range remains depth. Older Tools need fresh generation/manual code port to consume offsets. Native pointer and undo still require manual verification.
- Basic templates: `Templates/*`, `Plugin/TemplateInstaller.luau`,
  `docs/TemplateSkills.md`. Template Skills creates fresh melee/projectile Tools
  in StarterPack; a Mouse Aim/Body Aim slider selects each projectile's mode.
  Each new Tool has its own complete config under CombatForge.Abilities, editable
  through Update Skills. A nested Skill.Config ObjectValue links it by identity;
  all advanced settings live in the linked config ModuleScript. Shared damage/cooldown/
  range apply on the next Play session; existing Tools are not auto-migrated.
  AnimationId is optional; melee uses the shared Hitbox, projectile uses swept
  server spherecasts. Tests/RunTemplateChecks.luau accepts a source table for
  isolated Studio checks, including real WorldModel spatial queries.
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

Latest feature delivery: Template Skills with linked Abilities configs (see docs/TemplateSkills.md).
Previous feature commit: `2da9d52` (basic melee/projectile template generation).
See `git log` for current versions, rather than relying on chat history.
