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
- Visual melee/projectile hitbox authoring: `Plugin/HitboxEditor.luau`, `Plugin/Keybinds.luau`, `AbilityManager.saveGeometry`, and Update Skills -> Edit Hitbox. Settings configures persistent plugin-local keybinds. Controls use the theme; pinned top-left Back precedes Home; Home reaches root and Back follows parent pages with dirty-draft prompts. Settings has section dividers and independent persistent Move/Resize stud and Rotate degree snap increments. Snapping is optional, defaults off, and preserves Shift modifiers. Reset Hitbox restores draft geometry to 5 x 5 x 6 with zero offsets/rotation in one undo step. Hold Shift for Uniform Resize or Global Axis Move/Rotate; release returns to local axes. Changing Shift or the reference frame during a drag ends that gesture; start a new drag. Preview/draft Undo remain page-local. Save writes root-local size/offset/rotation without runtime schema changes. Projectile configs edit radius, Range/speed/lifetime and Straight/Quadratic Bezier control XYZ using themed sliders plus precise numeric entries (one Undo per drag, expanding symmetric bounds up to 10000) with centered Resize, snapping, radius-only reset to 0.5, Undo and checked Save; Move/Rotate are absent. A bounded sampled reachable path, control marker and Play/Stop sphere preview use dummy-forward sample aim without collisions/damage. Range stays maximum traveled distance, so curves can truncate. Runtime/ProjectileTrajectory.luau is shared verbatim by plugin and nested new Skill.Trajectory. Existing linked Tools consume radius/travel values next Play, but curves require fresh Tool generation or manual Skill+Trajectory upgrade preserving Config. Three-decimal display preserves untouched precision. Older copied Tools require fresh generation/manual port for offsets/rotation. Native input and Undo need manual verification.
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
`ReplicatedStorage.CombatForge.Runtime.Hitbox`. Installers protect edited copies. Startup ensures a missing Hitbox once in Edit, preserving existing edited modules and never reinstalling after Undo. Legacy Example generation was removed; existing place copies are preserved. Toolbar branding uses the verified Asset thumbnail resolver with a safe fallback.
Plugin loading previously failed with a Folder root; preserve the Script root.

The user authorized temporary isolated hitbox tests with cleanup in the Studio
place **CombatForge Testing**, place ID 98128576921103. Re-list Studio connections
before use. Obtain confirmation for other place mutations not already authorized.

Latest feature delivery: Template Skills with linked Abilities configs (see docs/TemplateSkills.md).
Previous feature commit: `2da9d52` (basic melee/projectile template generation).
See `git log` for current versions, rather than relying on chat history.
