--!strict
-- Pure sampled trajectories shared verbatim by plugin preview and generated Tools.
local Trajectory = {}
Trajectory.INTERVALS = 128
Trajectory.MAX_PORTIONS = 256
Trajectory.MAX_SWEEP = 1024
local function finite(value)
 return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function vector(value)
 return typeof(value) == "Vector3" and finite(value.X) and finite(value.Y) and finite(value.Z)
end
function Trajectory.resolve(config)
 if type(config) ~= "table" then return nil, "Trajectory settings must be a table." end
 local mode = config.ProjectileTrajectory
 if mode ~= nil and mode ~= "Straight" and mode ~= "Bezier" then return nil, "ProjectileTrajectory must be Straight or Bezier." end
 local count = 0
 for _, key in { "ProjectileControlX", "ProjectileControlY", "ProjectileControlZ" } do
  if config[key] ~= nil then
   count += 1
   if not finite(config[key]) or math.abs(config[key]) > 10000 then return nil, key .. " must be finite and between -10000 and 10000 studs." end
  end
 end
 if count ~= 0 and count ~= 3 then return nil, "Supply all three projectile control offsets or omit all three." end
 if mode == "Bezier" and count ~= 3 then return nil, "Bezier requires all three projectile control offsets." end
 return { ProjectileTrajectory = mode or "Straight", ProjectileControlX = config.ProjectileControlX or 0, ProjectileControlY = config.ProjectileControlY or 10, ProjectileControlZ = config.ProjectileControlZ or 0 }, nil
end
function Trajectory.frame(origin, forward, up)
 if not vector(origin) or not vector(forward) or not vector(up) or not finite(forward.Magnitude) or forward.Magnitude < 0.001 then return nil, "Launch origin and aim must be finite; aim must have nonzero length." end
 local f = forward.Unit
 local projected = up - f * up:Dot(f)
 if not finite(projected.Magnitude) then return nil, "Launch frame is not finite." end
 if projected.Magnitude < 0.001 then
  local fallback = Vector3.xAxis
  for _, axis in { Vector3.yAxis, Vector3.zAxis } do if math.abs(f:Dot(axis)) < math.abs(f:Dot(fallback)) then fallback = axis end end
  projected = fallback - f * fallback:Dot(f)
 end
 local right = f:Cross(projected.Unit).Unit
 local correctedUp = right:Cross(f).Unit
 if not vector(right) or not vector(correctedUp) then return nil, "Launch frame is unusable." end
 return { origin = origin, forward = f, right = right, up = correctedUp }, nil
end
function Trajectory.build(config, origin, forward, up)
 local settings, problem = Trajectory.resolve(config)
 if not settings then return nil, problem end
 for _, key in { "Range", "ProjectileSpeed", "ProjectileLifetime" } do
  if not finite(config[key]) or config[key] <= 0 then return nil, key .. " must be positive and finite." end
 end
 local frame, frameError = Trajectory.frame(origin, forward, up)
 if not frame then return nil, frameError end
 local endpoint = origin + frame.forward * config.Range
 local control = origin + frame.forward * (config.Range / 2) + frame.right * settings.ProjectileControlX + frame.up * settings.ProjectileControlY + frame.forward * settings.ProjectileControlZ
 if not vector(endpoint) or not vector(control) then return nil, "Trajectory endpoint/control is not finite." end
 local points, distances = { origin }, { 0 }
 local count = if settings.ProjectileTrajectory == "Bezier" then Trajectory.INTERVALS else 1
 local total = 0
 for index = 1, count do
  local t = index / count
  local point = if count == 1 then endpoint else origin * ((1-t)*(1-t)) + control * (2*(1-t)*t) + endpoint * (t*t)
  local length = (point - points[#points]).Magnitude
  if not vector(point) or not finite(length) or not finite(total + length) then return nil, "Trajectory sample is not finite." end
  total += length; table.insert(points, point); table.insert(distances, total)
 end
 if total <= 0 then return nil, "Trajectory has no usable length." end
 local timeDistance = config.ProjectileSpeed * config.ProjectileLifetime
 local limit = math.min(total, config.Range, timeDistance)
 if not finite(limit) or limit <= 0 then return nil, "Trajectory has no reachable distance." end
 return { points = points, distances = distances, length = total, limit = limit, control = control, frame = frame, settings = settings }, nil
end
function Trajectory.position(path, distance)
 if not finite(distance) then return nil, "Travel distance must be finite." end
 distance = math.clamp(distance, 0, path.length)
 for index = 2, #path.points do
  local start, finish = path.distances[index-1], path.distances[index]
  if finish > start and distance <= finish then return path.points[index-1]:Lerp(path.points[index], (distance-start)/(finish-start)), nil end
 end
 return path.points[#path.points], nil
end
function Trajectory.advance(path, fromDistance, toDistance)
 if not finite(fromDistance) or not finite(toDistance) or fromDistance < 0 or toDistance < fromDistance or toDistance > path.limit then return nil, "Invalid bounded trajectory distance." end
 local portions = {}
 for index = 2, #path.points do
  local low = math.max(fromDistance, path.distances[index-1])
  local high = math.min(toDistance, path.distances[index])
  if high > low then
   local chord = path.distances[index] - path.distances[index-1]
   if chord > 0 then
    local from = path.points[index-1]:Lerp(path.points[index], (low-path.distances[index-1])/chord)
    local finish = path.points[index-1]:Lerp(path.points[index], (high-path.distances[index-1])/chord)
    local fullDelta = finish-from
    if not vector(fullDelta) or not finite(fullDelta.Magnitude) then return nil, "Trajectory portion is not finite." end
    -- An entire logical interval may round to one representable Vector3 position.
    if fullDelta.Magnitude > 0 then
     local direction = fullDelta.Unit
     local remaining = high-low
     while remaining > 0 do
      if #portions >= Trajectory.MAX_PORTIONS then return nil, "Trajectory frame exceeds the bounded sweep budget; shot stopped safely." end
      local length = math.min(Trajectory.MAX_SWEEP, remaining)
      local nextPoint, delta
      for attempt = 1, 32 do
       nextPoint = if length == remaining then finish else from + direction * length
       delta = nextPoint-from
       if not vector(delta) or not finite(delta.Magnitude) then return nil, "Trajectory portion is not finite." end
       if delta.Magnitude <= Trajectory.MAX_SWEEP then break end
       length /= 2
      end
      local actualLength = delta.Magnitude
      if actualLength > Trajectory.MAX_SWEEP or (actualLength == 0 and length < remaining) then return nil, "Trajectory cannot represent a bounded sweep at these coordinates." end
      if actualLength > 0 then table.insert(portions, { origin = from, direction = delta, length = actualLength, finish = nextPoint }) end
      from = nextPoint; remaining -= length
     end
    end
   end
  end
 end
 return portions, nil
end
function Trajectory.step(path, distance, elapsed, dt, speed, lifetime)
 if not finite(dt) or dt < 0 or not finite(elapsed) or elapsed < 0 or not finite(speed) or speed <= 0 or not finite(lifetime) or lifetime <= 0 then return nil, "Trajectory frame time/settings must be finite and nonnegative." end
 local time = math.min(dt, math.max(0, lifetime-elapsed))
 local travel = math.min(path.limit-distance, speed*time)
 local target = math.min(path.limit, distance + travel)
 local portions, problem = Trajectory.advance(path, distance, target)
 if not portions then return nil, problem end
 local nextElapsed = elapsed + time
 return { distance = target, elapsed = nextElapsed, position = Trajectory.position(path, target), portions = portions, done = target >= path.limit or nextElapsed >= lifetime }, nil
end
return Trajectory
