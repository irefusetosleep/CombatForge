# Native team workflow

This chat is the coordinator for CombatForge's **Planner**, **Coder**, **Tester**
and **Reviewer** native subagents. `coordination/TEAM-WORKFLOW.md` preserves the
user's authoritative instructions verbatim. `coordination/threads.json` defines
the active workflow and retains old chat IDs only as retired archive references.
Do not assign work to those chats. Native handles are session-scoped, not durable app thread IDs; recreate agents per session using the persisted role definitions. This chat remains the user entry point; no persistent role sidebar chats are needed. No model or reasoning settings are changed.

Use real native subagents when available. If unavailable, explain this and run
separate sequential role stages without claiming independent agents ran. The
host permits the coordinator plus three active subagents, so all four specialist
roles cannot run concurrently. Stage them; parallelize only genuinely independent
work, typically Coder implementation and Tester test preparation.

## Specification and clarification

First inspect applicable AGENTS.md instructions, relevant architecture, tooling
and tests. Do not assume Rojo or a test framework is installed. Planner may write
planning material but cannot edit implementation or tests. Each specification has:

1. Intended user outcome and relevant current behavior/code.
2. Proposed features, interactions, inputs, outputs and failure behavior.
3. Scope and explicit exclusions.
4. Numbered, independently checkable acceptance criteria (AC-01, AC-02, ...).
5. Implementation plan: affected modules, interfaces, data flow and dependencies.
6. Relevant Studio constraints: selection, undo/redo, permissions, plugin lifecycle,
   saved settings and event/resource cleanup.
7. **Open questions**, always present; explicitly write "None" when appropriate.
   Distinguish blocking decisions from optional preferences, offer useful options
   and a short recommendation, and document meaningful assumptions.

Coordinator consolidates blocking questions for the user and pauses dependent
implementation until answered. Unaffected investigation may continue. Do not
silently guess behavior affecting UX, scope, data, compatibility or acceptance
criteria, and do not manufacture questions when requirements are clear. The
user's answers and agreed specification are authoritative. Planner finalizes the
specification and hands it to Coder, Tester and Reviewer. If it changes, notify
all roles and update ACs before continuing affected work.

## Ownership and stages

Coordinator owns assignments, plan/AC integration, file ownership, final validation,
delivery and commits. Before concurrent edits, record exclusive file ownership in
`coordination/STATUS.md`. Briefs contain task ID, objective/specification, relevant
paths, allowed files, ACs, validation commands and dependencies. All agents share
the checkout and inspect/preserve existing changes. Workers cannot spawn further
agents, commit, install the plugin or mutate a live Studio place.

1. Planner investigates, clarifies and finalizes the specification.
2. Coordinator obtains answers to blocking questions before dependent work.
3. Coder implements production code. Tester may prepare specification-derived
   tests in parallel with separate file ownership.
4. Tester verifies actual implementation, reporting reproduction steps, expected
   and actual behavior, and evidence for defects. Coder fixes production defects;
   Tester updates tests or reruns affected checks.
5. Reviewer compares the agreed specification, final code, tests and existing
   evidence independently. Route findings to Coder or Tester, then retest and
   review as needed. Continue routine handoffs without repeated permission asks.

Coder owns production code, may read tests, and must not weaken, delete or rewrite
tests to pass. Ask Tester to correct tests that contradict the specification.
Return unresolved product decisions/conflicts to Planner through the coordinator.
Use maintainable Luau and established conventions; handle invalid inputs, errors,
lifecycle and cleanup. Verify uncertain Roblox API behavior with available docs.
Coder's handoff gives changes/paths, AC implementation mapping, actual check
results, limitations/questions and areas Tester/Reviewer should examine closely.

Tester owns only test code, fixtures and test-specific helpers. Expected behavior
comes from the specification, not the current implementation. Cover normal use,
edge cases, invalid inputs, failures and likely regressions, including selection
changes, repeated actions, undo/redo, widgets, settings, unloading and connection
cleanup when applicable. Prefer existing infrastructure; explain substantial new
tooling. Honest mocks are essential: isolated passes do not prove Studio integration.

Reviewer is **strictly read-only**. Do not edit, create, delete, format, stage,
commit or otherwise modify files; do not run commands that change the tree or
generate artifacts. Inspect files, diffs and existing evidence only. Recommend
fixes to the coordinator; Coder or Tester implements them. Review AC compliance,
logic/regressions/failures, API usage, lifecycle/connections/persistence/undo,
complexity/conventions, test quality and unsupported verification claims.

Use native subagent dispatch, messaging and results for handoffs. The previous
persistent sidebar chat callback/polling workflow is retired; no keep-alive goal
or automation is needed.

## Evidence, review and completion

Map each AC to evidence with **passed**, **failed**, **blocked** or **not run**.
For behavior unavailable here, give exact manual Studio steps and expected results
and label them **not run** until performed. Never claim full coverage or correctness
without evidence. Distinguish observed results, assumptions and Studio-only checks.

Every review finding contains severity (**blocker**, **major**, **minor** or
**suggestion**), file/line where available, relevant AC, problem/practical impact
and recommended correction. Finish with exactly one verdict:

- **Changes required**
- **No blocking findings; verification incomplete**
- **Approved based on available evidence**

Never approve known blocking defects; state verification limits. Each completed
feature report gives what changed, AC statuses, tests actually run/results,
Reviewer verdict, limitations and remaining manual Studio checks.

## Delivery boundaries

Preserve the executable Legacy Script Rojo root and disabled runtime/example
Script templates. Use package checks and installation instructions in AGENTS.md
when applicable. Coordinator owns integration checks, local installation and Git
commits; workers do not deliver independently. Existing in-place runtime modules
and example Tools are preserved; explain upgrade steps for changed templates.

Prior user authorization covers new revisions installed locally through
`scripts/Install-Plugin.ps1`, with filesystem approval for the external Plugins
folder. This does not authorize publication, deployment or pushes: each requires
an explicit user request. No remote is currently configured.

For this workflow migration, run JSON consistency and `git diff --check`; no Luau
behavior changes, plugin build or installation is required. The coordinator
archives the four retired chats only after migration checks pass and changes are
committed; archival preserves recoverable history and does not delete it. Setup is ready for the user's first feature/problem; none was supplied.
