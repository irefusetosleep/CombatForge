--!strict
local ColourPicker = {}

function ColourPicker.mount(parent: Frame, initial: Color3, onChanged: (Color3) -> ())
	local colour = initial
	local rows: { { bar: TextButton, gradient: UIGradient, marker: Frame, label: TextLabel } } = {}
	local function values(): { number } return { colour.R, colour.G, colour.B } end
	local function render()
		local channels = values()
		for index, row in rows do
			local low, high = table.clone(channels), table.clone(channels)
			low[index] = 0; high[index] = 1
			row.gradient.Color = ColorSequence.new(Color3.new(low[1], low[2], low[3]), Color3.new(high[1], high[2], high[3]))
			row.marker.Position = UDim2.new(channels[index], 0, 0, -2)
			row.label.Text = ({ "R", "G", "B" })[index] .. "  " .. math.round(channels[index] * 255)
		end
	end
	for index, channel in { "Red", "Green", "Blue" } do
		local label = Instance.new("TextLabel")
		label.Name = channel .. "Value"
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(240, 244, 250)
		label.Font = Enum.Font.Gotham
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Position = UDim2.fromOffset(10, 8 + (index - 1) * 36)
		label.Size = UDim2.fromOffset(52, 26)
		label.Parent = parent
		local bar = Instance.new("TextButton")
		bar.Name = channel .. "Slider"
		bar.Text = ""
		bar.AutoButtonColor = false
		bar.BorderSizePixel = 0
		bar.BackgroundColor3 = Color3.new(1, 1, 1)
		bar.Position = UDim2.new(0, 66, 0, 8 + (index - 1) * 36)
		bar.Size = UDim2.new(1, -78, 0, 26)
		bar.Parent = parent
		local gradient = Instance.new("UIGradient"); gradient.Parent = bar
		local marker = Instance.new("Frame")
		marker.Name = "Marker"
		marker.Size = UDim2.new(0, 3, 1, 4)
		marker.AnchorPoint = Vector2.new(0.5, 0)
		marker.BackgroundColor3 = Color3.new(1, 1, 1)
		marker.BorderColor3 = Color3.new(0, 0, 0)
		marker.Parent = bar
		table.insert(rows, { bar = bar, gradient = gradient, marker = marker, label = label })
		local dragging = false
		local function choose(x: number)
			if bar.AbsoluteSize.X <= 0 then return end
			local channels = values()
			channels[index] = math.round(math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1) * 255) / 255
			colour = Color3.new(channels[1], channels[2], channels[3])
			render(); onChanged(colour)
		end
		bar.MouseButton1Down:Connect(function(x) dragging = true; choose(x) end)
		bar.MouseMoved:Connect(function(x) if dragging then choose(x) end end)
		bar.MouseButton1Up:Connect(function() dragging = false end)
		bar.MouseLeave:Connect(function() dragging = false end)
	end
	for index, hex in { "FFFFFF", "000000", "EF4444", "F59E0B", "FACC15", "22C55E", "38BDF8", "8B5CF6" } do
		local swatch = Instance.new("TextButton")
		swatch.Name = "Swatch" .. index
		swatch.Text = ""
		swatch.BackgroundColor3 = Color3.fromHex(hex)
		swatch.BorderColor3 = Color3.fromRGB(120, 120, 120)
		swatch.Position = UDim2.new((index - 1) / 8, 5, 0, 120)
		swatch.Size = UDim2.new(1 / 8, -10, 0, 24)
		swatch.Parent = parent
		swatch.Activated:Connect(function()
			colour = swatch.BackgroundColor3
			render(); onChanged(colour)
		end)
	end
	render()
	return { setColour = function(value: Color3) colour = value; render() end }
end

return ColourPicker
