# Current coordination state

Task VISUAL-HITBOX-06: uniform/axis scale, preview and mode toggles, three-decimal
numeric display, shorter lifecycle message, keyboard actions and draft Undo.
Planner Astra Medium inspecting/writing spec. Coder/Tester/Reviewer follow in stages.
Coordinator owns integration, actual Studio checks, installation and commit.

User clarified undo: keep Save/Cancel drafts; add Undo button with separately assigned
shortcut. Native Ctrl+Z remains saved-world undo, not intercepted. Actual guarded
CoreGui-only history probe committed no undoable waypoint (top remained existing
CombatForge.SaveHitbox); no Undo invoked, GUI removed. No world changes performed.

Preserve per-session drafts when preview is toggled off, current safe Save/history,
source conflicts, offset/rotation compatibility, no persistent preview geometry.
Shortcut actions should be assignable through Studio Customize Shortcuts; do not
claim programmatic default chords unsupported by PluginAction API. Numeric formatting
must not silently reduce stored precision of untouched values.

Base aee65c4 passed1441 checks with native pointer/Undo manually not run. Current task
needs independent tests and final build/package/review before local installation.
Final Planner spec sevenAC,noOpenquestions; user-selecteddraftUndo replacesCtrlZ. Coder owns HitboxEditor/UI/Main and TemplateSkills docs (Manager onlyifprecisionneeded); Tester ownsTests. Preview controller retainsdraft/history independentlyofvisibility; native5PluginActions assigned byuserCustomizeShortcuts. Uniform oppositefacecenter anchor; rawprecisionpreserved beneath3decimaldisplay.

Completed VISUAL-HITBOX-06. AC01-07 implemented and covered by isolated tests.
Final1830 fullharness assertions plus116LogoStartup=1946 passed inStudio. Latest
focusedUI42assertions retested improvedbusyguard. Native engine controller factory,
Resize/Uniform selection, off/on exactdraftretention and cleanup passed with isolated
WorldModel removed. Build/package/defaultdiffcheck passed. Reviewer: Approved based
on available evidence. Native shortcutdelivery/textfocus, pointerdrag and saved
Undo/Redo not run. Installed via Install-Plugin.ps1 with backup/hash verification.
User binds five actions via Customize Shortcuts; defaults not silently installed.
User-approved dedicated draft Undo preserves Save/Cancel; Studio Ctrl+Z untouched.
