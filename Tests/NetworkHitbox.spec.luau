-- loadHitbox(server, remote, player, world) supplies isolated service/remote adapters.
return function(loadHitbox)
	local world = Instance.new("WorldModel")
	world.Parent = workspace
	local endpoints = {}
	local checks = 0
	local function check(value, message) assert(value, message); checks += 1 end
	local function part(parent, x)
		local p = Instance.new("Part")
		p.Anchored = true; p.Size = Vector3.one; p.Position = Vector3.new(x, 0, 0); p.Parent = parent
		return p
	end
	local character = Instance.new("Model"); character.Parent = world
	local root = part(character, 0); root.Name = "HumanoidRootPart"
	Instance.new("Humanoid", character)
	local target = part(world, 2)
	local far = part(world, 100)
	local player = { Character = character }
	local handler, sent
	local disconnected = false
	local remote = {
		IsA = function(_, name) return name == "RemoteEvent" end,
		OnServerEvent = { Connect = function(_, callback)
			handler = callback
			return { Disconnect = function() disconnected = true end }
		end },
		FireServer = function(_, targets) sent = targets end,
	}
	local ok, failure = pcall(function()
		local server = loadHitbox(true, remote, player, world)
		local function setup(extra)
			local options = { Remote = remote, Shape = "Box", Size = Vector3.new(8,8,8), Authorize = function() return true end }
			for k,v in extra or {} do options[k] = v end
			local endpoint = server.ClientToServer(options)
			table.insert(endpoints, endpoint)
			local hits = {}
			endpoint.HitDetected:Connect(function(hit, caster) table.insert(hits, hit); check(caster == player, "server supplies sender") end)
			return endpoint, hits
		end
		local endpoint, hits = setup()
		handler(player, {target, target, far, character}); task.wait()
		check(#hits == 1 and hits[1].Target == target, "accept overlap once; reject distant and caster")
		handler(player, {target}); task.wait(); check(#hits == 1, "rate limit replay")
		check(not pcall(function() endpoint:Cast() end), "server cannot report client casts")
		endpoint:Destroy(); check(disconnected, "disconnect remote")
		handler(player, {target}); task.wait(); check(#hits == 1, "destroyed handler inert")
		local _, filtered = setup({Filter = {target}})
		handler(player, {target}); task.wait(); check(#filtered == 0, "server filter wins")
		local _, denied = setup({Authorize = function() return false end})
		handler(player, {target}); task.wait(); check(#denied == 0, "authorization required")
		local _, invalid = setup({ValidateHit = function() return false end})
		handler(player, {target}); task.wait(); check(#invalid == 0, "custom target validation")
		local _, malformed = setup()
		handler(player, {target, "fake"}); task.wait(); check(#malformed == 0, "malformed batch rejected atomically")
		local _, oversized = setup()
		handler(player, table.create(65, target)); task.wait(); check(#oversized == 0, "bounded payload")
		local _, sphere = setup({Shape = "Sphere", Radius = 4})
		handler(player, {target}); task.wait(); check(#sphere == 1, "sphere server validation")
		check(not pcall(function() server.ClientToServer({Remote=remote, Shape="Sphere", Radius=4}) end), "mandatory Authorize")
		check(not pcall(function() setup({Cooldown=0}) end), "minimum rate limit")
		local client = loadHitbox(false, remote, player, world)
		local prediction = client.ClientToServer({Remote=remote, Shape="Sphere", Radius=4})
		table.insert(endpoints, prediction)
		check(prediction.HitDetected == nil and prediction.CandidateDetected ~= nil, "predictions not confirmed hits")
		local candidates = prediction:Cast()
		check(#candidates == 1 and sent[1] == target, "client detects and sends targets only")
		check(#prediction:Cast() == 0, "client throttles")
		prediction:Destroy(); prediction:Destroy()
		check(not pcall(function() prediction:Cast() end), "destroy prevents cast")
	end)
	for _, endpoint in endpoints do endpoint:Destroy() end
	world:Destroy()
	assert(ok, failure)
	return tostring(checks) .. " network assertions passed (mock transport, real overlap queries)"
end
