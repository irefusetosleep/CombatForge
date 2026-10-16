# Current coordination state

Task: WORKFLOW-MODELS-02 — completed model and simple-edit routing amendment.
Planner: gpt-6-astra, medium reasoning; new native planner_astra instance created.
Small Edits: gpt-6.1-sol, inherited reasoning; native small_edits instance created.
Coordinator, Coder, Tester and Reviewer defaults are preserved. No active tasks.

Planner finalized AC-01 through AC-05; Small Edits implemented the assigned
workflow files, followed by coordinator diff review and targeted guide correction.
The original TEAM-WORKFLOW.md is unchanged. Later amendments live in
WORKFLOW-OVERRIDES.md and take precedence only for specified rules.

Simple, clear, low-risk changes route to Small Edits plus coordinator checks.
Substantial, ambiguous, security, network and architectural work retains the full
Planner/Coder/Tester/Reviewer pipeline. Session handles are recreated as needed;
model overrides use fresh contexts. Existing concurrency limits are unchanged.

Coordinator checks: exact JSON model/effort/fork settings, unchanged other-role
configuration and retired IDs, baseline prompt SHA256, documentation-only scope,
and whitespace validation. Plugin code was not changed, built or reinstalled.

## Previous feature delivery

Task: TEMPLATE-SKILLS-01 — delivered working basic melee/projectile Tool generation.
Specification: coordination/specs/TEMPLATE-SKILLS-01.md; Open questions: none.
User decisions: both functional templates; optional blank animation ID skips;
projectile Mouse Aim / Body Aim slider below creation button, saved per new Tool.

Status: Implementation locally installed with backup and matching package hash.
Real Planner, Coder, Tester and read-only Reviewer participated. No active tasks.
Reviewer verdict: No blocking findings; verification incomplete.
AC-01 through AC-07 implemented/reviewed, with automated evidence below; native
integration portions of AC-06/08 remain not run. No publication or push requested.

Actual coordinator execution in CombatForge Testing passed 247 assertions:
12 template menu, 12 existing menu/form, 23 skill-deletion UI, 11 startup,
30 existing Example, 57 template installer, 72 template runtime, 30 real
WorldModel spatial-query checks (injected clock/Heartbeat). Fixtures cleaned up.
Rojo build, package source/structure/disabled-state validation and diff check passed.
These include ownership/cooldown/delay, optional animation lifecycle via honest
mocks, both aim modes, damage dedupe, thin-wall sweep blocking, initial overlap,
range/lifetime/teardown cleanup and installer rollback/preservation.

Not run: rendered UI/slider, actual Tool input/multiplayer remote dispatch,
owned-animation playback and native Studio undo/redo. Exact manual steps are
in docs/TemplateSkills.md. Do not describe this delivery as fully verified.

Delivery paths: Plugin/TemplateInstaller.luau, Templates/*, UI/Main wiring,
package manifest/checker and docs/TemplateSkills.md. Settings are local Skill.Config
rather than Update Skills configs. Existing example files were left intact.

## Accepted feature history

SKILL-DELETE-08 — accepted; latest feature commit 5833e53.
Red delete button/white trash icon on Update Skills rows; named Cancel/Delete
confirmation; exact target unparented in one history recording, preserving subtree.
AbilityManager.delete(module: ModuleScript, expectedName: string) returns
(boolean, string), validating path/name and Edit mode; Cancel never mutates and
stale targets fail safely. No active feature assignments.
Evidence: 12 menu/form, 23 deletion UI and 49 isolated backend assertions passed;
Rojo build, package validation and git diff --check passed for that delivery.
Installed locally with backup and verified hash.
Limits: Native Ctrl+Z/redo and rendered UI not exercised; undo transitions used
an isolated history service. Existing place skills were not modified. These are
historical checks, not tests rerun or expanded by the workflow migration.
