# CombatForge

## Opening the editor

Use the **CombatForge** button in Studio's Plugins ribbon. It now includes an icon so the control is identifiable in compact ribbon layouts. If Studio hides the ribbon button, go to **File → Customize Shortcuts**, search for **Open CombatForge**, and assign an unused shortcut. The shortcut opens the same editor without resetting your current form. A closed editor window is different from a plugin failing to load; the former can be reopened without reinstalling.

## Playable example skill

Click **Install Example Skill** on the main menu. This adds a playable **CombatForge Example Slash** Tool to StarterPack, an **ExampleSlash** configuration to the skill editor, and the Hitbox runtime if missing. Installation uses one undo recording and preserves existing edited examples. The bundled Tool scripts are disabled inside the plugin and enabled only in the installed game copy.

Press Play, equip the Tool, face a nearby training dummy and click. A green box flashes, dealing 20 damage with a one-second cooldown. Stop Play and use **Update Skills → ExampleSlash** to change its damage, cooldown and range. [Example code structure and testing instructions](docs/ExampleSkill.md) explain the client request, server ownership check, cooldown, hit event and cleanup. Save your place after installing.

## Hitbox module

Choose **Install Hitbox Module** from the main menu to install `ReplicatedStorage.CombatForge.Runtime.Hitbox` into the current place, with undo support and protection for existing custom modules. Require it from server-side skill code to create box or sphere detectors, connect `HitDetected`, and call `Cast()` at the attack's hit timing. Caster hits are disabled by default; Filter excludes listed instances and descendants. See [Hitbox API, examples and test steps](docs/Hitboxes.md).

`Runtime/Hitbox.luau` is bundled inside the plugin as `Main.HitboxTemplate`. `Plugin/RuntimeInstaller.luau` installs the independent runtime; no plugin APIs are used by the installed Hitbox module. Spatial tests ran against a temporary WorldModel in Studio and removed it afterward. Installer error cases use isolated services; installed-runtime undo/redo should be checked in Studio.

## Development updates on this machine

The installed local plugin is `C:\Users\lewis\AppData\Local\Roblox\Plugins\CombatForge.rbxmx`. After future changes, use this command from the project directory to build and replace that same file:

```powershell
.\scripts\Install-Plugin.ps1
```

The installer builds first, backs up a changed installation under `build/plugin-backups`, replaces only CombatForge.rbxmx, and verifies its hash. Identical builds are skipped. Codex needs permission to access the Plugins folder outside the workspace. No manual importing or Save as Local Plugin is needed after installation. If Studio retains the old version, save your place and restart Studio. This command updates on demand; it does not run a background watcher.

## Appearance settings

Choose **Settings** from the main menu, then **Dark**, **Light** or **Custom**. Changes apply to CombatForge's menu, skill list, forms and settings page. Studio's own window title bar remains controlled by Studio.

For each custom colour, click **Choose colour** to expand a visual picker. Click or drag along the Red, Green and Blue gradient bars, or choose one of eight quick swatches. The coloured Choose colour button previews the selected colour immediately. Hex entry remains optional. Click **Save Custom Theme** to apply the palette. Invalid values show an error without changing the active theme. Unsaved colour edits are discarded when leaving Settings or selecting a preset. Saved custom colours are kept when switching between Light and Dark, so selecting Custom restores them. Primary button text adjusts for accent brightness; choose contrasting text/background colours for the remaining controls.

Under **Import / export custom theme**, click **Export custom theme** to generate and select a share code from the current custom colour controls (including unsaved edits). Press Ctrl+C to copy it; you can paste it into a message or save it as text outside Studio. To import, paste a code into the box and click **Import theme as draft**. Inspect the loaded colours, then Save Custom Theme to apply. Import/export uses versioned JSON text, not a file save dialog or automatic clipboard access. It does not execute imported code or make network requests. Invalid, unsupported or oversized codes leave the draft and saved settings untouched.

`Plugin/Theme.luau` owns palettes, validation and preferences. Preferences use Roblox's [Plugin GetSetting/SetSetting API](https://create.roblox.com/docs/reference/engine/classes/Plugin), are local to the plugin installation, and do not modify your place or its undo history. Invalid saved preferences fall back to Dark; storage failures appear in the settings page.

After replacing the local plugin, keeping all bundled children under the entry Script:

1. Open Settings and switch between Dark and Light. Visit both skill screens to check colours throughout.
2. Save a custom palette, switch to a preset, then select Custom to restore it.
3. Enter an invalid hex colour and verify the error leaves the current theme unchanged.
4. Restart Studio and confirm the chosen theme persists. Actual local settings persistence still needs this installed-plugin check.
5. Open each colour picker and test click/drag selection, quick swatches, preview and scrolling in a narrow dock. Save and reopen to verify the selected colours.
6. Export a palette, copy the code, change the draft, paste/import the code, and confirm importing alone does not change the active theme. Save to apply it. Try invalid text and confirm it reports an error without changing the controls.

CombatForge now opens to a main menu with **Create New Skill** and **Update Skills**. Create uses the existing form; Update lists saved skills and lets you change their name, damage, cooldown and range. Creation and its Studio undo behavior have been confirmed by the user. A standalone box/sphere hitbox runtime is now available; automatic skill execution remains a future milestone.

## Source layout

- `Plugin/Main.server.luau`: plugin startup, toolbar, docking, visibility and cleanup.
- `Plugin/UI.luau`: native Roblox GUI construction.
- `Plugin/AbilityConfig.luau`: input validation, safe reading of literal configurations and Luau serialization.
- `Plugin/AbilityManager.luau`: listing, reading, creation and updating in ReplicatedStorage with undo recording.
- `default.project.json`: Rojo model mapping. The UI ModuleScript becomes a child of the Main Script, so `require(script.UI)` resolves correctly.
- `build/CombatForge.rbxmx`: generated installable model, excluded from Git.

Opening the editor creates no game objects. Clicking Create Skill creates a configuration ModuleScript. Update edits the selected ModuleScript in place, recording its source and name change together. Its stable widget ID lets Studio restore docking and visibility. Closing the window updates the toolbar toggle and preserves the current form until the plugin unloads. No runtime framework or dependencies are required.

## Build

From this directory in PowerShell:

```powershell
New-Item -ItemType Directory -Force build
rojo build default.project.json -o build/CombatForge.rbxmx
```

## Install locally

1. Open a disposable Baseplate in Roblox Studio in edit mode.
2. Right-click ServerStorage in Explorer and choose **Insert from File**. Select `build/CombatForge.rbxmx` from this project.
3. Select the inserted **CombatForge Script**, keeping all bundled ModuleScripts and the ExampleToolTemplate Tool intact, and choose **Save as Local Plugin** from the right-click menu or Plugins menu. Name it CombatForge and save it, replacing the previous local version. The entry script's source file is Main.server.luau; it is now the root of the built model, without a Folder wrapper.
4. Look for CombatForge in the Plugins toolbar. If it has not appeared, restart Studio.
5. Remove the imported CombatForge Script from ServerStorage after installation; the installed plugin has its own copy.
6. Click the CombatForge toolbar button to open the window. Do not press Play to launch the plugin.

Local installation does not publish anything to the Creator Store. Keep these disk files as the source of truth. After changes, rebuild and repeat installation, replacing the same local plugin rather than installing a second copy. Restart Studio if it still runs the old version.

## Phase 1 acceptance check

- Open Output and check there are no CombatForge errors on startup.
- Click the toolbar button: the dark CombatForge window appears with the main menu.
- Click again: it hides. Click again: it reopens.
- Close using the window's X, then reopen using the toolbar button.
- Float, dock and resize the window; text should wrap and remain readable at minimum size.
- Restart Studio and verify its docking and visibility restore; the toolbar still toggles it correctly.
- Confirm only one CombatForge toolbar button/window exists after reinstalling.

## Phase 2 acceptance check

1. Rebuild/reinstall as above. Choose Create New Skill. In edit mode, create `LightAttack` with damage `20`, cooldown `0.5` seconds and range `5` studs.
2. Inspect `ReplicatedStorage.CombatForge.Abilities.LightAttack` in Explorer. Its source should return those four settings. The configuration alone does not execute an attack.
3. Move keyboard focus out of the text fields, then use Studio Undo: the new ability and any folders created for it should disappear together. Redo should restore them.
4. Try the same name again, including different capitalization. Creation must be rejected without changing the existing ability.
5. Try an empty/invalid name, negative damage/cooldown, zero range, text instead of a number, and `1e999`. Each must show a helpful error without creating anything. Zero damage and cooldown are allowed; range must be positive. Names use 1–64 ASCII letters, numbers or underscores and cannot begin with a number.
6. Create a second, differently named ability; undo must leave the first ability intact.
7. In a disposable place, test a non-Folder named CombatForge or Abilities in the expected path. Creation should report the conflict without replacing it.
8. During Play, creation must be blocked. Stop Play and try again.
9. Resize to the minimum window height and scroll: all fields, the button and feedback must remain accessible.
10. Save your place, reopen it and verify the configuration remains in ReplicatedStorage.

## Menu and skill editing acceptance check

1. Replace the local plugin using the rebuilt model, keeping all bundled children under the entry Script. Restart Studio if the old UI remains.
2. Confirm the main menu offers Create New Skill and Update Skills. Create should show the existing four-field form.
3. Choose Update Skills. Existing ModuleScripts under `ReplicatedStorage.CombatForge.Abilities` appear alphabetically, including skills created with the previous version. Use Refresh list after external changes or undo/redo.
4. Select a skill. Check all four fields are populated, change each value, and Save Changes. Check the same ModuleScript now has the new name and values.
5. Move focus out of the fields and use Studio Undo/Redo. Both the source and name should revert/restore together. Go back and reopen the skill afterward to load the current values.
6. Return to the list and reopen the saved skill; check its values. Try renaming to another skill's name: the save must be blocked without overwriting either skill.
7. Change a field and click Back. Keep editing should preserve the draft; Discard changes should return without saving. Closing/reopening the dock itself keeps the current draft during the session.
8. Open a skill, edit its source separately in Studio, then attempt Save Changes. The plugin should reject the stale save and ask you to reopen it.
9. Check the empty list in a disposable place, smaller window scrolling, and persistence after saving/reopening your place.

The editor reads literal four-field configurations without executing ModuleScripts. It refuses custom logic, unknown fields and unsupported syntax so a form save cannot erase those additions. Such modules remain listed with an explanatory message when selected; edit them directly in Studio. Generated configurations from the previous version are supported. Renaming updates the module and its Name field; references in other scripts are not rewritten.

Rojo building validates packaging, not live Studio behavior. The specs in `Tests` cover creation, parsing, update conflicts, rename collisions, transaction failures and menu/form navigation. They ran in Studio with isolated instances and stubbed storage/history/editor services; the UI test harness registers the real button callbacks for direct invocation. 165 assertions passed, including theme validation, persistence through a stubbed settings store, save failures and colour propagation. Real installed-plugin interaction and update undo/redo require the checks above.

## Official references

- [Studio plugin installation](https://create.roblox.com/docs/studio/plugins)
- [Plugin API and CreateDockWidgetPluginGuiAsync](https://create.roblox.com/docs/reference/engine/classes/Plugin)
- [DockWidgetPluginGuiInfo and state restoration](https://create.roblox.com/docs/reference/engine/datatypes/DockWidgetPluginGuiInfo)
- [ChangeHistoryService recording API](https://create.roblox.com/docs/reference/engine/classes/ChangeHistoryService)
- [ScriptEditorService source reading and updating](https://create.roblox.com/docs/reference/engine/classes/ScriptEditorService)





Version control: see [Versioning](docs/Versioning.md) for saving and undoing changes with Git.
