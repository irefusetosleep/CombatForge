# Later user workflow amendments

Task: WORKFLOW-MODELS-03. These later user instructions amend the original
`coordination/TEAM-WORKFLOW.md`, which remains preserved verbatim. This file takes
precedence only where its explicit amendments conflict with the original;
all unaffected original rules remain in force. AGENTS.md, the operating guide
and the role registry apply this same precedence.

## Native role models

- Planner, Coder, Tester, Reviewer and Small Edits all explicitly use
  `model="gpt-6.1-sol"`, `reasoning_effort="medium"` and `fork_turns="none"`.
  Planner's reusable dispatch label is `planner`; Small Edits uses `small_edits`.
- This later user amendment supersedes WORKFLOW-MODELS-02's model and reasoning
  policy for all five subagent roles.
- Coordinator keeps its configured model and reasoning defaults. Do not modify
  global settings. If the requested model is unavailable, report that limitation;
  never silently substitute another.

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
