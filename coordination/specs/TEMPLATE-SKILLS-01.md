# TEMPLATE-SKILLS-01 — working basic skill Tools

Status: Implemented and locally installed after independent tests and read-only
review. 247 assertions passed; remaining native integration checks are documented
as not run in docs/TemplateSkills.md and coordination/STATUS.md.

## Outcome and confirmed decisions

Make fighting-game skill creation easier by generating readable, customizable
Tools with input -> optional animation -> hitbox -> damage already connected.
Both Empty Melee Skill and Empty Projectile Skill generate working attacks.
No animation asset was supplied: a blank AnimationId skips playback and still
attacks. The user requested a slider offering Mouse Aim or Body Aim.

## Current behavior and scope

`Plugin/UI.luau` renders menu pages, with installer callbacks supplied by
`Plugin/Main.server.luau`. `Plugin/ExampleInstaller.luau` already demonstrates
StarterPack Tool cloning, protected shared runtime paths, one undo recording and
rollback. The example combines two hitboxes; the new basic templates should be
simpler and leave the example intact. `Runtime/Hitbox.luau` provides Box/Sphere
scans and client/server candidate validation, not a projectile travel primitive.

The existing configuration editor accepts only Name, Damage, Cooldown and Range.
Keep template configuration and behavior self-contained in each generated Skill
ModuleScript; do not expand that editor or add generated templates to its list.
Exclude new animation assets, visual effects systems, advanced targeting,
homing/combos and changes to existing example/runtime APIs.

## Acceptance criteria

- **AC-01 — Menu and aim selection:** Add a Template Skills main-menu button.
  Its page contains Empty Melee Skill and Empty Projectile Skill buttons, a
  return control, and status/error feedback. Directly beneath the projectile
  button, show a two-position slider visibly labelled Mouse Aim and Body Aim.
  The selection applies to subsequent projectile creation and is written into
  the generated Skill settings. Documented assumption: Mouse Aim is the initial
  selection, following the user's first-named option. Retain the selected value
  during the current mounted UI session; no new persisted plugin preference.
- **AC-02 — Fresh editable Tools:** Each creation produces a fresh uniquely named
  Tool in StarterPack, containing Client (LocalScript), Server (Script), Skill
  (ModuleScript) and an activation RemoteEvent. Tools require no Handle and
  cannot be dropped, following the example convention. Repeated creation never
  overwrites earlier Tools or unrelated objects. Settings, including Damage,
  Cooldown, Range, AnimationId, HitDelay, hitbox dimensions and projectile speed
  where applicable, are clearly commented in Skill. Preserve existing editor
  compatibility by keeping these settings separate from its configurations.
- **AC-03 — Working optional-animation pipeline:** Equipped Tool activation
  follows input -> optional animation -> configurable HitDelay -> hit detection
  -> server damage. With default blank AnimationId, attacks work without setup.
  Animation setup/playback failure does not leave an activation stuck or leak
  resources. Provide usable default damage, cooldown, geometry/range and speed;
  document chosen defaults in source. HitDelay defaults to zero. These are basic
  source-customization templates, with clearly identified pipeline stages.
- **AC-04 — Melee authority and safety:** A basic forward melee hitbox damages
  eligible living humanoids once per activation, excludes its caster, and uses
  server-owned settings. The server verifies request ownership, Tool equipped/
  enabled state, living character/root, valid settings and cooldown. Recheck
  delayed activation state before hit detection. Invalid or unauthorized
  requests do not damage targets or break subsequent valid activations.
- **AC-05 — Both projectile aim modes:** Body Aim uses the server's current
  character-forward direction. Mouse Aim reads the local mouse aim point and
  sends only aim intent; the server validates its Vector3 type and finite
  components, handles invalid/degenerate aim safely, and derives origin,
  direction limits, range, speed and damage from server character/settings.
  Never trust client target instances, hit claims, origins or damage. Projectile
  contact detection must cover travel between updates, stop at relevant world
  collision/first valid impact, exclude the caster, and damage a target at most
  once. Enforce finite travel range/lifetime and clean up projectile resources
  on completion or Tool/character teardown. Use simple readable behavior.
- **AC-06 — Safe creation and undo:** Creation is blocked during Play. Preflight
  template inputs/shared dependency paths, preserve existing edited modules and
  objects, and report clear conflicts. Treat each successful creation plus any
  newly required dependencies as one ChangeHistoryService recording. Refuse to
  mutate if recording cannot begin. Roll back newly created objects on failure;
  preserve unrelated content. Actual Studio undo/redo restores/removes the
  generated bundle as one action.
- **AC-07 — Packaging and regressions:** Preserve the executable Legacy Script
  package root. New bundled Script/LocalScript templates remain disabled inside
  the plugin; enable only installed game copies. Preserve existing Example
  installation and all skill/editor/theme/dummy contracts. Package validation
  checks new sources, Tool structure and disabled states.
- **AC-08 — Evidence:** Independently test menu/slider dispatch and mode capture,
  both generated structures, repeated creation, collision/rollback/recording,
  optional animation, delayed activation, authorization/cooldown, damage
  deduplication, projectile aim validation/travel termination and cleanup. Map
  results to these ACs. Clearly distinguish injected-service checks from live
  Studio integration. Provide exact manual steps labelled not run for any
  unperformed Tool input, animation, projectile collision, rendering or native
  undo/redo checks. Report Reviewer verdict and remaining verification limits.

## Implementation plan and interfaces

1. Add separate basic template sources (suggested `Templates/`) and a dedicated
   `Plugin/TemplateInstaller.luau`; keep the existing example sources unchanged.
   Installer accepts the selected template kind, aim mode and packaged sources/
   dependencies, returning `(boolean, string)` using existing installer style.
2. Extend UI.mount with an optional template-creation callback; main wiring
   supplies it. UI owns current slider selection; creation captures that value.
   Keep existing mount arguments/tests compatible. Implement slider interaction
   using current UI/theme conventions and dispose event connections on teardown.
3. Installer clones a Tool, writes its independent settings/source, enables only
   game scripts and installs/reuses necessary compatible runtime dependencies in
   one transaction. Use fresh collision-safe names; do not overwrite source in
   an existing developer-edited Tool or shared runtime. Tool becomes playable on
   the next Play session through StarterPack.
4. Client handles Tool.Activated and mouse intent. Server owns RemoteEvent binding,
   authorization and cleanup; Skill exposes the editable attack behavior/settings.
   Avoid duplicating accepted activation or granting client damage authority.
   Coder may choose exact internal names/interfaces consistently with this flow.
5. Update `default.project.json` and `scripts/Test-PluginPackage.ps1`. Tester owns
   new/changed `Tests/*.spec.luau` and test-only harnesses. Document generated
   layout, customization and manual checks in focused docs.

## Studio constraints and validation

Use ChangeHistoryService recording with rollback; refuse Play-mode generation.
Handle Tool unequip/destruction, death/character replacement, deferred hit timing,
RemoteEvent connection cleanup and animation permissions/rig compatibility.
Keep UI/theme lifecycle behavior consistent with existing pages. No requirement
to change Studio selection or open generated scripts automatically.

Rojo and Git were confirmed available by the coordinator. Existing specs return
functions accepting isolated loaders/dependencies; no standalone Luau runner is
configured. Relevant checks: isolated Luau specs where execution is available,
`rojo build default.project.json -o build/CombatForge.rbxmx`,
`scripts/Test-PluginPackage.ps1 -Path build/CombatForge.rbxmx`, and
`git diff --check`. Coordinator owns live Studio access, installation and commits;
re-list Studio connections and respect PROJECT.md place mutation authorization.

## Open questions

None. Mouse Aim initial selection and session-local slider state are documented
implementation assumptions; both requested modes must work. Escalate newly
discovered product conflicts rather than changing this specification silently.
