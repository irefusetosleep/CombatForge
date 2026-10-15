# Coordinator and worker workflow

Use the **CombatForge Coordinator** chat for new features and bugs. It owns the
plan, integration, validation, plugin installation and final Git commit.

The persistent worker chats are **CombatForge Worker - Edits**,
**CombatForge Worker - Plugin UI** and **CombatForge Worker - Runtime**.
They start with short project context, rather
than inheriting the full development conversation. Thread IDs are recorded in
`coordination/threads.json` after setup.

The Edits worker handles simple, low-compute changes, such as unlocking spawned
dummy parts, using its configured GPT-6 Luna model as requested by the user.
Keep its assignments and coordinator reviews brief; avoid duplicate implementation.
The Plugin UI worker normally handles editor, theme and plugin interface work.
The Runtime worker normally handles hitboxes, examples and dummy behavior. These
are starting scopes: each assignment defines its exact allowed files. Shared
files belong to the coordinator unless explicitly assigned.

Persistent chats are independent peers. The user authorized assignment and callback
messages between these designated workflow chats. The coordinator dispatches a
short brief with `send_message_to_thread` and returns instead of waiting. Each
worker sends one completion callback to the coordinator, which starts a review
turn. If criteria are unmet, the coordinator sends a focused correction to that
same worker; otherwise it marks the task accepted and integrates it. Blockers also
produce a callback rather than a waiting loop. Idle workers do not poll or run a
background loop. No automation or keep-alive goal is installed.

For each substantial task, the coordinator writes a compact assignment in
`coordination/STATUS.md`, identifies independent work, and delegates only what
benefits from separate context. Each worker receives the objective, relevant paths,
allowed files, acceptance criteria and checks. It returns a short result. The
coordinator reviews the combined diff and runs necessary integration checks once.
Small changes go to the Edits worker, followed by a focused coordinator review.
At most two workers run concurrently.

This aims to reduce repeated context and duplicated effort. It does not guarantee
lower total tokens: worker startup and coordination also consume tokens. Model
selection remains at its configured default. Coordinator reasoning is High;
Plugin UI and Runtime worker reasoning is Medium, matching the transcript's
mature-project pattern. Preserve the Edits chat's configured settings.
No API service or paid integration
is required for this local setup.

The TikTok page was inaccessible during setup; the user supplied its transcript.
The workflow follows that transcript's callback/review strategy. The anecdotal
model/token results in the video have not been independently measured here.
