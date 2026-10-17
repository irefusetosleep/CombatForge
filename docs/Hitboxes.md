# Hitbox runtime

Click **Install Hitbox Module** on CombatForge's main menu in edit mode. It installs a standalone ModuleScript at `ReplicatedStorage.CombatForge.Runtime.Hitbox`. Save your place afterward. Installation supports Studio undo; repeating it is a no-op when the module is identical. It refuses to overwrite a different/custom module. The plugin does not need to be installed for the resulting game to run.

## Box example

Use this from a server Script or server-required skill module. Validate ability ownership, cooldown and attack timing on the server before calling it; the hitbox module supplies detection only.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hitbox = require(ReplicatedStorage.CombatForge.Runtime.Hitbox)

local function slash(caster: Model)
    local root = caster:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return end

    local box = Hitbox.Box(
        root.CFrame * CFrame.new(0, 0, -3), -- box centre and rotation
        Vector3.new(5, 5, 6),              -- full dimensions in studs
        {
            Caster = caster,              -- character Model or Player (required)
            CanHitCaster = false,         -- default
            Filter = {},                  -- instances and descendants to exclude
        }
    )

    box.HitDetected:Connect(function(hit)
        print("Hit:", hit.Target, "via part:", hit.Part)
        if hit.Humanoid and hit.Humanoid.Health > 0 then
            hit.Humanoid:TakeDamage(20)
        end
    end)

    local hits = box:Cast() -- one scan now; also returns the hit records
    -- Keep it alive until event handlers have been delivered. This is not an active window.
    task.delay(1, function() box:Destroy() end)
    return hits
end
```

## Sphere example

```lua
local sphere = Hitbox.Sphere(root.Position, 8, {
    Caster = character,
    Filter = { workspace.Decorations }, -- omit if this folder does not exist
    CanHitCaster = false,
})

sphere.HitDetected:Connect(function(hit)
    print(hit.Target, hit.Humanoid, hit.Player)
end)
sphere:Cast()
task.delay(1, function() sphere:Destroy() end)
```

## Debug visualization

All three constructors accept an optional final boolean `showDebug`, defaulting to false:

```lua
local box = Hitbox.Box(root.CFrame, Vector3.new(4, 5, 6), { Caster = character }, true)
local sphere = Hitbox.Sphere(root.Position, 6, { Caster = character }, true)
local network = Hitbox.ClientToServer(networkOptions, true)
```

Each actual scan displays a translucent green box or sphere for 0.25 seconds at the queried position, rotation and dimensions. Sphere diameter is twice its radius. `Cast(newOrigin)` displays the overridden position. Creating a detector alone does not draw anything. Pass false or omit the argument to disable visualization.

The previews cannot collide, touch, or appear in hitbox queries, and clean themselves up even if the detector is immediately destroyed. They show a snapshot of the query area, not a moving or persistent hitbox.

For ClientToServer, enable the flag independently on each side: the client shows its predicted scan locally; the server shows its validation scan to all players. Denied or throttled requests that never reach a scan draw nothing. This flag is not sent over the remote and cannot enable server previews from the client.

## API and behaviour

- `Hitbox.Box(cframe, size, options)` and `Hitbox.Sphere(position, radius, options)` create detectors; constructors do not scan or fire events.
- Connect `detector.HitDetected` before `detector:Cast()`. Each callback receives one record: `Target`, `Part`, `Model`, `Humanoid`, `Player`. Optional fields are nil when they do not apply. `Part` is a representative overlapping BasePart, not necessarily the closest part.
- `Target` is the containing character Model when a Humanoid ancestor exists; otherwise the closest containing Model, or the loose BasePart. One record/event is emitted per Target per cast, preventing multiple limb/accessory hits on the same character. NPCs have no Player; loose parts have no Model or Humanoid. Models used only as organisation containers will also group hits.
- `Caster` is required. A Player's current Character is resolved for each cast; a Model refers to that exact Model. With `CanHitCaster` omitted or false, its descendants are excluded. `CanHitCaster = true` allows self hits, but an explicit Filter entry can still exclude the caster.
- `Filter` is an exclusion list, copied at construction. Listing a Model or Folder excludes its descendants too. Create a new detector to change options or filters.
- `Cast(newOrigin)` optionally changes the origin for that scan only: CFrame for boxes, Vector3 for spheres. The original origin is retained for later argument-free casts. Each cast resets deduplication, so repeated scans can hit the same target again. Use your own per-attack hit set if polling across multiple frames.
- `Destroy()` disconnects listeners and releases the event; repeat calls are safe. Casting afterward raises an error. Do not destroy immediately after Cast if you need deferred event listeners to run. For immediate cleanup, process the returned hit array instead of events, then Destroy.
- Sizes/radii must be positive finite values. Origins must be finite. Optional `WorldRoot` supports a WorldModel; it defaults to Workspace.

These are Roblox **bounding-box overlap queries** using [GetPartBoundsInBox and GetPartBoundsInRadius](https://create.roblox.com/docs/reference/engine/classes/WorldRoot), not exact mesh contact tests. They respect CanQuery and the default collision group's query rules, do not test line of sight, and can report geometry behind walls. Result order is unspecified. With debugging disabled, the runtime creates no visible hitbox parts, applies no damage itself and starts no background loop.

The module can be required on either side for detection, but damage decisions should use server queries. Client streaming can omit targets. The four-field skill configuration remains data; put attack behaviour in a separate server module rather than adding code to configurations managed by the editor.

## Client detection with server validation

Use `Hitbox.ClientToServer(options)` on both sides with the **same dedicated RemoteEvent**. Keep using `Box` / `Sphere` for regular hitboxes. This is a code-level choice per skill, not a plugin-wide setting.

Create a RemoteEvent named `SlashHits` in ReplicatedStorage. Create one endpoint per side and keep it alive for the skill's lifetime. The server owns its configuration; changing client settings cannot expand the server hitbox.

Server Script:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hitbox = require(ReplicatedStorage.CombatForge.Runtime.Hitbox)
local slash = Hitbox.ClientToServer({
    Remote = ReplicatedStorage:WaitForChild("SlashHits"),
    Shape = "Box", -- or "Sphere" with Radius = 6 instead of Size
    Size = Vector3.new(4, 5, 6),
    Offset = CFrame.new(0, 0, -3), -- relative to caster HumanoidRootPart
    Cooldown = 1,
    Filter = {},
    CanHitCaster = false,
    Authorize = function(player)
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local tool = character and character:FindFirstChild("YourSkillTool")
        -- Add your game's stun, resource, ownership and attack-window checks here.
        return humanoid ~= nil and humanoid.Health > 0
            and tool ~= nil and tool:IsA("Tool") and tool.Enabled
    end,
    -- Optional: ValidateHit = function(player, hit) return ... end
    -- Use this for team, invulnerability or raycast/line-of-sight rules.
})
slash.HitDetected:Connect(function(hit, player)
    if hit.Humanoid and hit.Humanoid.Health > 0 then
        hit.Humanoid:TakeDamage(20) -- server-selected damage
    end
end)
script.Destroying:Connect(function() slash:Destroy() end)
```

LocalScript inside the player's Tool:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hitbox = require(ReplicatedStorage.CombatForge.Runtime.Hitbox)
local slash = Hitbox.ClientToServer({
    Remote = ReplicatedStorage:WaitForChild("SlashHits"),
    Shape = "Box",
    Size = Vector3.new(4, 5, 6),
    Offset = CFrame.new(0, 0, -3),
    Cooldown = 1,
})
slash.CandidateDetected:Connect(function(hit)
    -- Optional predicted effects only. This is NOT confirmation or damage.
end)
script.Parent.Activated:Connect(function() slash:Cast() end)
script.Destroying:Connect(function() slash:Destroy() end)
```

When adapting an existing Tool, replace its activation wiring with this pattern; running both would apply two attacks.

- `Cast()` is client-only: one local scan, up to 64 candidate targets, and one report (including misses). It returns the reported hit records. It accepts no origin override: both sides derive the origin from their current character and `Offset`.
- Server `HitDetected(hit, player)` fires only for reported targets also overlapping the server's current hitbox. The server creates the hit record; clients cannot supply damage, caster, size, radius or hit records. Duplicated targets fire once per accepted report.
- Client `CandidateDetected(hit)` is prediction only. There is no confirmation message back to the client. The server endpoint has no CandidateDetected signal; the client endpoint has no HitDetected signal.
- `Authorize(player)` is required on the server and must return exactly true. `ValidateHit(player, hit)` optionally adds per-target rules. Callback errors reject the attack/hit. Keep both callbacks non-yielding.
- `Cooldown` defaults to 0.25 seconds and must be at least 0.05. The server limits each player independently, including malformed or denied reports. Use one server endpoint per dedicated RemoteEvent; duplicate listeners could apply damage twice.
- `Filter`, `CanHitCaster`, `Shape`, `Size`/`Radius`, `Offset`, and `Cooldown` are captured at construction. Network queries use Workspace and a living character with HumanoidRootPart. Destroy and recreate to change configuration.
- `Destroy()` disconnects the remote listener and events without destroying the shared RemoteEvent. Wait for deferred event delivery before destroying after a cast.
- Validation uses current server positions, with **no rewind or latency tolerance**. Moving targets may be rejected under latency, and streaming may omit client targets. Queries do not block hits through walls; add a server raycast in ValidateHit if needed. Character movement integrity remains your game's responsibility.

Existing places keep their installed module. To upgrade, rename the old `ReplicatedStorage.CombatForge.Runtime.Hitbox` to `HitboxBackup`, then click **Install Hitbox Module**. This preserves custom code and installs the new API at the original path. Stop playtesting first; restart the playtest after upgrading to clear require caches.

## Studio acceptance checks

1. Install once and inspect the module path. Undo/redo the installation. Reinstall and verify there is only one module.
2. In a server test, connect the event and cast near an NPC and a loose Part. Check the character produces one hit despite multiple limbs, and the Part is reported separately.
3. Test box rotation, sphere radius, Filter entries, and both values of CanHitCaster.
4. Verify a second cast can hit again, and Destroy prevents later casts.
5. Save/reopen the place and check the runtime remains usable without the plugin.

