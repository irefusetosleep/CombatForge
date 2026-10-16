# CombatForge working rules

Read `coordination/PROJECT.md` for the short project map. Read only files needed
for the assigned task; do not load the old development chat by default.
The authoritative team instructions are preserved verbatim in
`coordination/TEAM-WORKFLOW.md`; use `docs/AgentWorkflow.md` for the operating guide.

## Coordinator and native subagents

- This chat coordinates distinct native subagents named **Planner**, **Coder**,
  **Tester**, and **Reviewer** for each feature request. These are staged roles,
  not persistent sidebar chats. Handles are session-scoped; recreate roles from the
  persisted definitions when needed. Use real subagents when available; otherwise
  disclose the limitation and run the roles as separate sequential stages.
  Never claim independent agents ran when they did not.
- The coordinator owns assignments, file ownership, integration, final validation,
  local plugin installation and Git commits. `coordination/threads.json` records
  the current coordinator, native role definitions and retired archive references.
  Do not dispatch work through the retired persistent chats or callback policy.
- Planner inspects and writes planning material only, never implementation/tests.
  Its specification states outcome, current behavior, interactions, inputs,
  outputs, failure behavior, scope/exclusions, numbered acceptance criteria,
  implementation plan, interfaces/data flow/dependencies and Studio constraints.
  Always include **Open questions**, explicitly saying none if there are none.
  Consolidate blocking questions for the user; pause dependent implementation
  until answered while continuing unaffected investigation. Document meaningful
  assumptions; do not invent requirements or manufacture unnecessary questions.
- Coder owns production code. It may read tests but must not weaken, delete or
  rewrite tests to make implementation pass. Contradictory tests go to Tester;
  unresolved product decisions go back to Planner through the coordinator.
- Tester owns tests, fixtures and test-specific helpers, never production fixes.
  Derive expectations from the specification. Prepare tests independently during
  coding, then verify the implementation and rerun affected checks after fixes.
- Reviewer is **strictly read-only**: no file edits/creation/deletion/formatting,
  staging/commits or commands that modify the tree or generate artifacts.
  Inspect files, diffs and existing evidence only; send recommendations to the
  coordinator for Coder or Tester to implement.
- Follow plan -> clarification -> code and independent test preparation ->
  test/fix -> read-only review -> fix/retest/review. Notify all roles and update
  acceptance criteria before continuing work affected by specification changes.
  Continue routine handoffs autonomously after blocking questions are resolved.
- Parallelize only independent work with exclusive file ownership. All agents
  share this checkout and must preserve others' work. The host supports the
  coordinator plus three subagents at once; stage the four roles within that
  limit, normally Coder plus Tester preparation. Do not change model settings.
- Briefs include task ID, objective/specification, relevant paths, allowed files,
  acceptance criteria, validation commands and dependencies. Handoffs summarize
  changed paths, AC mapping, actual checks, limitations and areas needing review.
  Use native subagent messaging/results; no persistent chat callback or keep-alive
  workflow is required. Workers do not spawn more agents, commit, install the
  plugin or modify a live Studio place.
- Map verification evidence to ACs using passed, failed, blocked or not run.
  Label manual Studio steps not run until performed; mocks do not prove Studio
  integration. Review findings include severity (blocker/major/minor/suggestion),
  file/line, AC, impact and correction. End review with **Changes required**,
  **No blocking findings; verification incomplete**, or
  **Approved based on available evidence**. Never approve known blocking defects.
- Finish each feature with implementation, AC status, actual tests/results,
  Reviewer verdict, limitations and manual Studio checks. Keep active assignments
  and decisions in `coordination/STATUS.md`; replace stale status.

## Build and delivery

- Inspect architecture, tooling and tests before planning; do not assume Rojo or a
  test framework is installed. Follow existing Luau style and scope; preserve
  unrelated work and avoid unnecessary refactors, dependencies or architecture.
- Keep the Rojo root an executable Legacy Script. Example and dummy runtime
  Script templates must remain disabled inside the plugin package.
- Run relevant available checks and report exactly what ran. Package validation is
  `scripts/Test-PluginPackage.ps1 -Path build/CombatForge.rbxmx` after a Rojo build.
- `scripts/Install-Plugin.ps1` builds, validates, backs up and installs the local
  plugin. The user's prior authorization for installing new local revisions
  remains separate from publication; use the required filesystem permission
  mechanism for the external Roblox Plugins folder. Do not publish the plugin,
  deploy or push unless the user explicitly requests it.
- Existing in-place runtime modules and example Tools are preserved by installers.
  Explain upgrade steps when changing those templates. Re-list Studio connections
  before use and respect the place mutation limits in `coordination/PROJECT.md`.
- Preserve uncommitted work. Coordinator commits completed, verified changes with
  a concrete message; no remote is configured. Never claim checks passed unless
  they ran or call work fully verified while required checks remain unrun.
- Keep contexts and reviews concise; do not promise token savings without evidence.
