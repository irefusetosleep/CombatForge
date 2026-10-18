# PROJECTILE-TRAJECTORY-01 — quadratic paths and moving preview

Status: Final implementation-ready specification. No blocking user questions.

## Outcome and current behavior

Extend the projectile editor with editable Straight/Quadratic Bezier paths and a
moving collision-sphere preview, using the same trajectory calculation as generated
projectile Tools. Current editor supports radius only; runtime starts at root.Position,
travels straight toward server-captured Body/Mouse aim, checks initial overlap then
spherecasts, and stops on impact, traveled Range or lifetime. Configs are literal
scalar tables; save is checked against source/path/name and has native rollback.
Templates contain four direct Tool children and link Skill.Config to an ability.

## Scope and interaction

Projectile editor adds Trajectory: Straight / Bezier (quadratic), numeric Control X,
Y and Z offsets in studs, Projectile Speed (studs/second), Lifetime (seconds), and
Range (maximum traveled studs). Preserve radius Resize, reset, snapping, Undo and
Save. Show control fields only for Bezier; X is right, Y up and Z forward relative
to the launch aim frame. The single control point is offset from the forward midpoint.
Default Bezier offsets are (0,10,0); switching modes is one undoable draft edit.
Keep control edits when switching to Straight within the page, while runtime ignores
them. Numeric field application is a committed valid edit (focus loss/Enter), one
undo entry; invalid/nonfinite input shows a precise error and leaves accepted draft
unchanged. Do not apply a partial triple as transient saved geometry. Retain original
numeric precision when an unchanged formatted input is committed.

Draw the reachable path as a bounded plugin-owned line/adornment chain plus a
control marker. Add **Play Preview** / **Stop Preview** for a one-shot moving sphere;
Play restarts at launch, Stop returns to launch, completion leaves sphere at its
reachable endpoint until replay/stop. No automatic looping, damage, physics or place
objects. Start preview auto-shows the static path/sphere with handles hidden; motion
starts only explicitly. Editing geometry/path/speed/lifetime, dragging, Reset or Undo
stops playback and redraws from launch. Playback and view toggles never dirty config
or add undo history. Preview off/widget hide/lifecycle teardown stops animation.

The editor uses the selected root's forward direction as a clearly labeled sample
aim for both aim modes; it does not capture a live mouse target. Runtime Mouse Aim
rotates the same authored path toward the validated aim point. During playback,
capture launch frame once; if the reference frame changes, stop and redraw rather
than warping a flying preview. Show only the reachable path prefix under Range and
speed*Lifetime. A separate intended endpoint/control marker may be shown, but must
be labeled as such and not look like reachable travel. Help states: curved routes
can stop before their intended endpoint because Range limits traveled distance.

Reset Hitbox retains its existing radius-only reset to 0.5; it does not silently
reset trajectory/speed/lifetime/Range. Mode switching/default controls provide a
simple initial curve; no additional trajectory reset button is required.

## Schema and geometry contract

Add optional scalar fields `ProjectileTrajectory` (Straight or Bezier),
`ProjectileControlX`, `ProjectileControlY`, `ProjectileControlZ`. All absent means
legacy Straight. Explicit Straight may omit the control triple; any supplied triple
must be complete, finite and within [-10000,10000] studs per component. Bezier requires
all three. Reject partial/unknown types, and reject projectile trajectory fields in
melee eligibility. Newly generated projectile configs use explicit Straight and
(0,10,0), while ordinary updates preserve absent legacy fields unless trajectory
editing explicitly saves them. Existing Range/speed/radius/lifetime validations stay.

Let origin O be root.Position and forward F be the normalized validated launch aim.
Construct a deterministic orthonormal right/up/forward frame from F and root.UpVector;
when parallel, choose the least-aligned world basis as fallback. Share this exact
frame builder in runtime and preview. Capture it once per launch; never retarget
from later caster/mouse movement. Body uses root.LookVector. Mouse uses aimPoint-O;
reject nonfinite or effectively zero direction before any runtime objects spawn.

P0=O, P2=O+F*Range, P1=(P0+P2)/2 + right*X + up*Y + F*Z.
Bezier B(t)=(1-t)^2 P0+2(1-t)t P1+t^2 P2. Straight is the P0/P2 segment.
This is intentionally one quadratic curve, not cubic/spline/ballistic/homing support.

Approximate Bezier deterministically using 128 equal parameter intervals, compute
cumulative chord lengths and advance by distance, not by raw parameter t. Preview
and runtime use the identical samples and interpolation; label this a sampled
Bezier path rather than claim exact analytic arc length. Range caps cumulative
distance, speed controls traveled studs/second and lifetime caps elapsed seconds.
Radius remains constant; orientation is irrelevant to the spherical collider.
Skip zero-length chords safely; reject nonfinite sample positions/lengths or an
unusable path before accepting/rendering/launching it. Bound point count at 129.

Runtime sweeps every crossed chord portion in order, splitting each sweep to at
most 1024 studs. Never sweep one chord directly across multiple curve corners.
Use a shared advancement iterator with a maximum 256 sweep portions per Heartbeat/
preview frame. If required work exceeds this budget, end the shot/preview safely
with a clear diagnostic; do not skip collisions, extend lifetime, or run an unbounded
catch-up loop. This only constrains extreme frame stalls/speeds/paths; tests must
exercise the failure path. RemainingTime=min(dt,lifetime-elapsed) and remaining
Range bound the frame distance; reject invalid dt. Stop at first impact and damage
at most one target, retaining existing filtering/cancellation/initial-overlap rules.
On impact position the visual sphere center using origin+unitDirection*hit.Distance,
not hit.Position (which is a surface contact point). Cleanup occurs on every exit.

## Shared module, persistence and compatibility

Create pure `Runtime/ProjectileTrajectory.luau` with validation/default resolution,
aim-frame construction, sampling, cumulative-distance lookup and bounded advancement
helpers. Package that same source as plugin root `ProjectileTrajectory` and
`ProjectileToolTemplate.Skill.Trajectory`; no new global runtime-install dependency
or modification of an existing Hitbox module is required. Four direct Tool children
remain unchanged. Generated Skill requires its child Trajectory; plugin uses its
own packaged copy. TemplateInstaller validates/clones that dependency transactionally.

Expand the existing `AbilityManager.saveGeometry` projectile draft save whitelist
to radius, Range, ProjectileSpeed,
ProjectileLifetime and the trajectory fields only. Keep Damage, Cooldown, AimMode,
AnimationId and HitDelay untouched. Snapshot classification and literal parser
remain authoritative; no arbitrary fields/source execution. One explicit Save is
one checked recording with existing rollback/stale-source protections. One numeric
commit, control/mode change or radius drag is one local Undo operation; no native
Ctrl+Z interception. Melee save whitelist remains unchanged.

Projectile session snapshots consistently contain ProjectileRadius, Range,
ProjectileSpeed, ProjectileLifetime, ProjectileTrajectory and the three control
values. Resolve legacy absent trajectory to Straight/(0,10,0) in memory; opening
alone never writes source. Manager accepts this complete projectile contract and
rejects missing/extra keys. UI submits the complete snapshot through saveGeometry;
do not create a parallel save implementation. Suggested session methods are
`commitProjectile(fields)`, `playPreview()` and `stopPreview()`; exact names may
follow local conventions but updates must validate atomically before history/change
notification. Shared helper API must provide path construction, distance lookup and
ordered frame-advance portions; Coder may choose names and report them to Tester.

Existing copied projectile Skill modules do not consume curves. Do not automatically
overwrite them. Editor/help and delivery docs must clearly warn that trajectory
playback requires a newly generated projectile Tool or manually replacing the old
Skill implementation plus its Trajectory child while preserving the Config link.
Radius/Range/speed/lifetime still work on old linked implementations; curves do not.
No claim that saving alone upgrades an old Tool. Existing absent-field configs run
Straight when consumed by the new template. New runtime helper missing/invalid must
fail clearly without spawning a partially functioning projectile.

## Acceptance criteria

- **AC-01 — Editor controls/schema:** Straight and quadratic Bezier, editable
  control XYZ/speed/lifetime/Range and radius are supported with units, defaults,
  bounded finite validation, complete triples and precision-safe display. Legacy
  absent trajectory fields resolve Straight. Mixed/melee/custom configurations stay
  protected. Invalid form commits preserve the last valid draft.
- **AC-02 — Path/aim math:** Shared frame/sampling/interpolation produces identical
  preview/runtime positions, including rotated roots, Mouse/Body direction, vertical
  aim, signed controls, zero-length samples and nonlinear curves. Distance-based
  speed, Range truncation and lifetime cutoff are explicit and correct; point/sweep
  budgets fail safely rather than generating unbounded work.
- **AC-03 — Moving preview:** Static reachable path and control marker render with
  the actual sphere radius. Play/Stop/replay/end behavior follows the contract;
  playback is damage-free and unpersisted. Editing, reference movement, hide, Play,
  deactivation and unload stop playback and clean objects/connections. No false live
  Mouse Aim or collision simulation claims; preview is collision-free path motion.
- **AC-04 — Runtime collision:** Initial overlap and ordered spherecast portions
  detect first collision along the sampled curve without crossing corners or
  skipping portions. Range/lifetime/server-validity caps, 1024 sweep maximum,
  256-per-frame budget, safe impact center and cleanup hold under frame stalls,
  tiny/large values, cancellation and query failures. No extra damage/multi-hit mode.
- **AC-05 — Draft/save/history:** All accepted edits use exact local snapshots,
  one history entry per action; no-op/playback events do not. Save persists only the
  projectile whitelist, retains unrelated fields and checked conflict/rollback
  behavior. Back/Home dirty prompts, preview-off Save, radius-only Reset and native
  saved-config Undo remain correct. Melee controls/math/save do not regress.
- **AC-06 — Packaging/compatibility:** Identical pure trajectory source is packaged
  in plugin and new projectile Skill child without a new global runtime dependency.
  Fresh templates include valid defaults/dependency; install failures rollback all
  created objects. Legacy configs remain Straight in new templates and existing
  Tools remain untouched. Upgrade guidance makes old-Tool curve limitation explicit.
- **AC-07 — Verification/evidence:** Independent deterministic math, runtime world/
  mock collision, UI/lifecycle/config/save/package tests cover the above. Report
  native path/animation/input/collision checks separately from injected evidence;
  no claim of fully verified Studio interaction when those checks are unrun.

## Ownership, implementation and validation

Coder owns shared module, focused AbilityConfig/AbilityManager/HitboxEditor/UI/Main,
projectile template/installer/package and active docs. Tester owns tests/harness/
fixtures; coordinator assigns shared validation-script ownership explicitly and
owns integration, STATUS/PROJECT, Studio work, install and commit. Planner writes
only this spec. No worker spawns, installs, commits or mutates Studio.

Reuse page/session/history seams; a small trajectory-specific view/controller helper
is acceptable if it avoids expanding unrelated melee code. Inject pure trajectory
dependency for tests. Expose draft patch/commit and playback capabilities with state
notifications rather than letting UI mutate session tables. Do not introduce an
arbitrary config execution surface or a full animation/timeline framework.

Extend ProjectileEditor, VisualHitboxConfig/Save/Lifecycle/Menu, TemplateRuntime/
TemplateWorld/Installer/SharedConfig and harness/package checks. Compare shared
samples at known traveled distances, exact endpoint/truncated positions, uneven
dt, crossings over multiple corners, first obstacles on curved portions, lifetime
partial frames and budget exhaustion. Test edited/absent/malformed helper and safe
template rollback. Run affected injected Studio suites, Rojo build, package validator
and git diff --check. No standalone Luau runner is configured.

Native checks not run until observed: visible path/markers and moving sphere,
field commit/Undo/navigation behavior, local preview versus new Tool motion in Play,
curved obstacles and lifecycle cleanup. Coordinator re-lists Studio and follows
PROJECT.md mutation limits before integration. No publish/push or existing-Tool
automatic migration is authorized.

## Open questions

None. Meaningful choices: one quadratic Bezier control point, sampled constant-speed
travel, retained maximum traveled Range (curves may truncate), collision-free preview
using dummy forward as sample aim, radius-only Reset, nested shared helper and
explicit existing-Tool upgrade guidance. These provide the requested custom paths
and motion preview without unrelated projectile behaviors.
