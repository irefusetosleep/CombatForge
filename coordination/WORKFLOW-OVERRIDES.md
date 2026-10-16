# Later user workflow amendments

Task: WORKFLOW-MODELS-02. These later user instructions amend the original
`coordination/TEAM-WORKFLOW.md`, which remains preserved verbatim. This file takes
precedence only where its explicit amendments conflict with the original;
all unaffected original rules remain in force. AGENTS.md, the operating guide
and the role registry apply this same precedence.

## Native role models

- Planner: `model="gpt-6-astra"`, `reasoning_effort="medium"`,
  `fork_turns="none"`; reusable dispatch label `planner`.
- Small Edits: `model="gpt-6.1-sol"`, `fork_turns="none"`; omit the reasoning
  override and inherit the normal harness default. Dispatch label `small_edits`.
- Coordinator, Coder, Tester and Reviewer keep their configured model and
  reasoning defaults. Do not modify global settings. If either requested model
  is unavailable, report that limitation; never silently substitute another.

Dispatch labels describe roles; native handles remain session-scoped and are
not durable app thread IDs. Do not create persistent sidebar role chats or use
retired archive references for assignments. Five specialist definitions are
staged within the unchanged coordinator-plus-three-subagents limit.

## Simple-edit route

Route compact, clearly scoped, low-risk plugin edits to Small Edits, followed by
coordinator diff review and relevant validation. This is the lighter alternative
to the full feature pipeline. Escalate substantial, ambiguous, security, network
or architectural work to Planner -> clarification -> Coder and independent Tester
preparation -> test/fix -> read-only Reviewer -> fix/retest/review. Scope expansion
returns to the coordinator before affected work continues.

Small Edits owns only assigned production edits; it may read tests but must not
weaken, delete or rewrite them to pass. Tester retains test ownership. All workers
remain prohibited from spawning agents, committing, installing the plugin or
mutating a live Studio place. Planner remains planning-only and Reviewer remains
strictly read-only. Coordinator retains assignments, integration, final validation,
STATUS updates, installation and commits.

For this documentation-only setup, Small Edits is explicitly assigned only
`AGENTS.md`, `coordination/threads.json`, `docs/AgentWorkflow.md` and this file.
No production/test changes, plugin build, installation or Studio mutation is
required. Coordinator performs JSON/consistency checks and `git diff --check`,
then handles the commit. Archived chat references remain preserved.
