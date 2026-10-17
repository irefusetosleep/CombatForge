# Version history

CombatForge is a local Git repository on the main branch. Generated builds, plugin backups and Studio place files are excluded. Git tracks source files; it does not undo edits made directly inside a Roblox place.

Run these commands from this folder in a terminal:

```powershell
git status                 # See uncommitted changes
git diff                   # Review those changes
git log --oneline          # Browse saved versions
git add .
git commit -m "Describe the change"
```

To undo a committed change while keeping its history, use `git revert COMMIT_ID` (replace COMMIT_ID with the ID from git log). This creates a new commit that reverses that change. Commit any work you want to preserve first. To recover one file from an older version, use `git restore --source COMMIT_ID -- path/to/file`, review it, and commit the result; this replaces that file's current uncommitted contents.

After reverting plugin source, run `./scripts/Install-Plugin.ps1` to rebuild and install that version, then restart Studio. Runtime modules and Tools already copied into a place need to be updated separately.

The repository currently has no remote. It provides local history, not off-device backup. The initial snapshot includes the dual-hitbox example edits that were in progress when Git was requested; older development history was not recorded.
