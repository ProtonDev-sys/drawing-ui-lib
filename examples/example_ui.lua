local DrawingUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/drawing-ui-lib/main/DrawingUI.lua"))()

local state = {
	enabled = false,
	showFov = true,
	fov = 140,
	smoothness = 0.2,
	status = "Idle",
}

local function formatNumber(value)
	return string.format("%.2f", value)
end

local window = DrawingUI.CreateWindow({
	Title = "Example Hub",
	Position = Vector2.new(140, 90),
	Size = Vector2.new(460, 420),
	Theme = {
		Accent = Color3.fromRGB(255, 155, 66),
		ToggleEnabled = Color3.fromRGB(255, 155, 66),
		SliderFill = Color3.fromRGB(255, 155, 66),
		HeaderBackground = Color3.fromRGB(30, 24, 18),
		WindowBackground = Color3.fromRGB(20, 18, 16),
		ButtonHover = Color3.fromRGB(54, 42, 31),
	},
})

window:SetSubtitle("example menu")

window:AddSection("Aim Assist")

local enabledLabel = window:AddLabel("Enabled: false")
local fovLabel = window:AddLabel("FOV Radius: " .. tostring(state.fov))
local smoothnessLabel = window:AddLabel("Smoothness: " .. formatNumber(state.smoothness))

window:AddToggle("Master Toggle", state.enabled, function(value)
	state.enabled = value
	enabledLabel:SetText("Enabled: " .. tostring(value))
	window:SetTitle(value and "Example Hub [ON]" or "Example Hub [OFF]")
end)

window:AddToggle("Draw FOV Circle", state.showFov, function(value)
	state.showFov = value
	window:SetSubtitle(value and "fov visible" or "fov hidden")
end)

window:AddSlider("FOV Radius", 40, 400, state.fov, function(value)
	state.fov = math.floor(value + 0.5)
	fovLabel:SetText("FOV Radius: " .. tostring(state.fov))
end)

window:AddSlider("Smoothness", 0.05, 1, state.smoothness, function(value)
	state.smoothness = value
	smoothnessLabel:SetText("Smoothness: " .. formatNumber(value))
end)

window:AddSection("Actions")

local statusLabel = window:AddLabel("Status: " .. state.status)

window:AddButton("Inject Config", function()
	state.status = "Loaded preset at " .. os.date("%X")
	statusLabel:SetText("Status: " .. state.status)
end)

window:AddButton("Move Window", function()
	window:SetPosition(Vector2.new(220, 120))
	state.status = "Window moved"
	statusLabel:SetText("Status: " .. state.status)
end)

window:AddButton("Hide For 3 Seconds", function()
	state.status = "Temporarily hidden"
	statusLabel:SetText("Status: " .. state.status)
	window:SetVisible(false)

	task.delay(3, function()
		window:SetVisible(true)
		state.status = "Visible again"
		statusLabel:SetText("Status: " .. state.status)
	end)
end)

window:AddButton("Unload UI", function()
	DrawingUI.ClearAll()
end)
