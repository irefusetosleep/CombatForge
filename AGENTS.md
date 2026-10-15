# CombatForge working rules

Read `coordination/PROJECT.md` for the short project map. Read only files needed
for the assigned task; do not load the old development chat by default.

## Coordinator and workers

- The user requested a coordinator/worker workflow. Use one coordinator and at
  most two concurrent workers when a task has independent, substantial parts.
  Complete small or dependent tasks with one agent to avoid delegation overhead.
- The coordinator owns the task plan, acceptance criteria, file ownership,
  integration, final validation, plugin installation and Git commits.
- Workers receive a compact brief: objective, relevant paths, files they may
  edit, acceptance criteria, validation command and dependencies. Do not copy the
  full chat. Return changed paths, result, checks and remaining issues, normally
  within 200 words. Include extra detail only for an actionable blocker.
- Persistent specialist chats are listed in `coordination/threads.json`.
  The user explicitly requested the callback strategy in the supplied video
  transcript: the coordinator assigns these workers tasks, each worker messages
  this coordinator on completion, and the coordinator can send corrections until
  the result is accepted. That authorization is limited to these workflow chats
  and their assigned CombatForge work; it does not authorize unrelated messages.
- Use `send_message_to_thread` to dispatch an assignment or callback. After
  dispatching, do other useful work or end the turn with a short status. Do not
  poll, use a waiting loop, or launch a goal to keep a thread running. A callback
  starts the coordinator's review turn. A completion notification is a claim to
  verify: inspect the diff and relevant checks, return a focused correction to
  the same worker if needed, then approve only when acceptance criteria are met.
- Only one worker may edit a given file at a time. The coordinator assigns
  shared files such as `default.project.json` explicitly. All chats use the same
  checkout, so each worker must inspect current changes and preserve others' work.
- Workers do not spawn further agents, commit, install the plugin, or modify a
  live Studio place. They send one compact callback with the task ID and stop.
  Include acceptance status, changed paths, checks and blockers in the callback.
- Record active assignments and relevant decisions in `coordination/STATUS.md`.
  Keep it current and short; replace stale status instead of appending transcripts.

## Build and delivery

- Keep the Rojo root an executable Legacy Script. Example and dummy runtime
  Script templates must remain disabled inside the plugin package.
- Run checks relevant to the change. Package validation is
  `scripts/Test-PluginPackage.ps1 -Path build/CombatForge.rbxmx` after a Rojo build.
- `scripts/Install-Plugin.ps1` builds, validates, backs up and installs the local
  plugin. This user has requested installation of new revisions. Use the required
  filesystem permission mechanism for the external Roblox Plugins folder.
- Existing in-place runtime modules and example Tools are preserved by installers.
  Explain upgrade steps when changing those templates.
- Preserve uncommitted work. Commit completed, verified changes with a concrete
  message; do not claim tests passed unless they ran. No remote is configured.
- Do not change model settings or promise token savings without evidence. Use
  short contexts and avoid duplicate work; additional agents consume tokens too.
