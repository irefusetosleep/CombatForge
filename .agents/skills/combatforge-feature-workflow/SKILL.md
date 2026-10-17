---
name: combatforge-feature-workflow
description: Coordinate feature planning, implementation, tests, and review for the CombatForge Roblox Studio plugin using its project workflow. Use for CombatForge feature requests and substantial bug fixes.
---

# Combatforge Feature Workflow

Use this skill when implementing a feature or substantial bug fix in the CombatForge repository. The repository's instructions remain authoritative; this skill routes the work and makes sure those instructions are applied.

## Before assigning work

- Read `AGENTS.md`, `coordination/PROJECT.md`, `coordination/WORKFLOW-OVERRIDES.md`, and `docs/AgentWorkflow.md`. Read `coordination/TEAM-WORKFLOW.md` when role details or precedence need clarification.
- Inspect relevant code, available checks, current `coordination/STATUS.md`, and the working tree. Preserve unrelated changes. Do not load old development chats by default.
- If the user has not provided a feature or problem, ask what they want the team to tackle first.
- Follow the override's routing: compact, clearly specified, low-risk edits use Small Edits and coordinator review; substantial, ambiguous, security, network, or architectural work uses the full pipeline. For other work, use judgment and explain the route briefly.

## Full feature pipeline

1. Have Planner inspect and write a concise implementation-ready specification only. Include current behavior, outcome, interactions and failure behavior, scope/exclusions, numbered acceptance criteria, implementation plan, interfaces/data flow/dependencies, Studio constraints, meaningful assumptions, and an **Open questions** section (write "None" when empty).
2. Consolidate blocking questions for the user. Pause only dependent implementation until answered; continue unaffected investigation. Do not invent product behavior or ask questions already answered by the request or project conventions.
3. After clarification, have Coder implement production code from the agreed specification. Tester may independently prepare specification-derived tests in parallel only with exclusive file ownership. Tester owns test code; Coder owns production fixes.
4. Have Tester verify the actual implementation, map evidence to each acceptance criterion, report defects with reproduction details, and rerun affected checks after fixes.
5. Have Reviewer compare the final specification, implementation, tests, and evidence. Reviewer is strictly read-only and returns findings in the project's required format and verdict. Route fixes to Coder or Tester, then repeat the relevant checks and review.

Use real native subagents when available; otherwise disclose the limitation and run distinct sequential role stages without claiming independent work. Apply the exact model and reasoning settings in `coordination/WORKFLOW-OVERRIDES.md`; report unavailable requested models instead of substituting. Do not create persistent role chats or use retired archive references. Workers do not spawn agents, commit, install the plugin, or mutate a live Studio place.

## Verification and delivery

- Inspect existing tooling before choosing checks. Do not assume Rojo or a standalone Luau test runner exists. Mocks do not establish Roblox Studio integration.
- Map every acceptance criterion to **passed**, **failed**, **blocked**, or **not run** evidence. Give exact Studio steps and expected results for manual checks, and label them **not run** until performed.
- Keep project-specific Studio constraints and authorized place mutations in `coordination/PROJECT.md`. Re-list Studio connections before use. Do not mutate another place without the required confirmation.
- The coordinator owns integration, final validation, status updates, local installation, and commits. Follow `AGENTS.md` for package validation and installation. Do not publish, deploy, or push without an explicit user request.
- Finish with a concise report of implementation, acceptance-criteria status, checks actually run, Reviewer verdict, limitations, and manual Studio checks still not run. Never claim verification that the evidence does not support.
