local DrawingUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/drawing-ui-lib/main/DrawingUI.lua?v=ae2a9b1"))()

local state = {
	enabled = false,
	showFov = true,
	showBoxes = false,
	showNames = true,
	flags = { "Box", "Name" },
	fov = 140,
	smoothness = 0.2,
	targetPart = "Head",
	profileName = "Legit",
	menuBind = {
		kind = "Keyboard",
		code = Enum.KeyCode.RightShift,
	},
	accentColor = Color3.fromRGB(255, 155, 66),
	status = "Idle",
}

local function formatNumber(value)
	return string.format("%.2f", value)
end

local function formatBinding(binding)
	if binding == nil then
		return "NONE"
	end

	if binding.kind == "Keyboard" then
		return binding.code.Name
	end

	return binding.kind
end

local window = DrawingUI.CreateWindow({
	Title = "Example Hub",
	Position = Vector2.new(140, 90),
	Size = Vector2.new(510, 350),
	Theme = DrawingUI.Themes.Amber,
})

window:SetSubtitle("tabbed example")

local combatTab = window:AddTab("Combat")
local visualsTab = window:AddTab("Visuals")
local configTab = window:AddTab("Config")
local miscTab = window:AddTab("Misc")

combatTab:AddSection("Aim Assist")
combatTab:AddParagraph("Overview", "Tabs, buttons, sliders, dropdowns, textboxes, keybinds and theme-driven colors are all exposed by the library.")

local enabledLabel = combatTab:AddLabel("Enabled: false")
local fovLabel = combatTab:AddLabel("FOV Radius: " .. tostring(state.fov))
local smoothnessLabel = combatTab:AddLabel("Smoothness: " .. formatNumber(state.smoothness))

combatTab:AddToggle("Master Toggle", state.enabled, function(value)
	state.enabled = value
	enabledLabel:SetText("Enabled: " .. tostring(value))
	window:SetTitle(value and "Example Hub [ON]" or "Example Hub [OFF]")
end)

combatTab:AddSlider("FOV Radius", 40, 400, state.fov, function(value)
	state.fov = math.floor(value + 0.5)
	fovLabel:SetText("FOV Radius: " .. tostring(state.fov))
end)

combatTab:AddSlider("Smoothness", 0.05, 1, state.smoothness, function(value)
	state.smoothness = value
	smoothnessLabel:SetText("Smoothness: " .. formatNumber(value))
end)

combatTab:AddDropdown("Target Part", { "Head", "Torso", "Closest" }, state.targetPart, function(value)
	state.targetPart = value
	window:SetSubtitle("targeting " .. string.lower(value))
end)

visualsTab:AddSection("ESP")

local visualsLabel = visualsTab:AddLabel("Draw helpers for targets")

visualsTab:AddToggle("Draw FOV Circle", state.showFov, function(value)
	state.showFov = value
	visualsLabel:SetText(value and "Draw helpers for targets" or "Circle overlay disabled")
end)

visualsTab:AddToggle("Boxes", state.showBoxes, function(value)
	state.showBoxes = value
end)

visualsTab:AddToggle("Names", state.showNames, function(value)
	state.showNames = value
end)

visualsTab:AddMultiDropdown("ESP Flags", { "Box", "Name", "Health", "Distance", "Weapon" }, state.flags, function(values)
	state.flags = values
	visualsLabel:SetText(#values > 0 and ("Flags: " .. table.concat(values, ", ")) or "No flags selected")
end)

visualsTab:AddColorPicker("Accent Color", state.accentColor, function(color)
	state.accentColor = color
	window:SetTheme({
		Accent = color,
		ToggleEnabled = color,
		SliderFill = color,
	})
end)

configTab:AddSection("Configuration")

local profileLabel = configTab:AddLabel("Profile: " .. state.profileName)
local bindLabel = configTab:AddLabel("Menu Bind: " .. formatBinding(state.menuBind))

configTab:AddTextbox("Profile Name", "Type a profile name...", function(value)
	state.profileName = value ~= "" and value or "Legit"
	profileLabel:SetText("Profile: " .. state.profileName)
end)

configTab:AddDropdown("Theme Preset", { "Amber", "Midnight", "Default" }, "Amber", function(value)
	if value == "Midnight" then
		window:SetTheme(DrawingUI.Themes.Midnight)
	elseif value == "Default" then
		window:SetTheme(DrawingUI.Themes.Default)
	else
		window:SetTheme(DrawingUI.Themes.Amber)
	end
end)

configTab:AddKeybind("Menu Bind", state.menuBind, function()
	window:SetVisible(not window.visible)
end, function(binding)
	state.menuBind = binding
	bindLabel:SetText("Menu Bind: " .. formatBinding(binding))
end)

miscTab:AddSection("Actions")

local statusLabel = miscTab:AddLabel("Status: " .. state.status)

miscTab:AddButton("Inject Config", function()
	state.status = "Loaded preset at " .. os.date("%X")
	statusLabel:SetText("Status: " .. state.status)
end)

miscTab:AddButton("Move Window", function()
	window:SetPosition(Vector2.new(220, 120))
	state.status = "Window moved"
	statusLabel:SetText("Status: " .. state.status)
end)

miscTab:AddButton("Use Midnight Theme", function()
	window:SetTheme(DrawingUI.Themes.Midnight)
	state.status = "Theme swapped"
	statusLabel:SetText("Status: " .. state.status)
end)

miscTab:AddButton("Hide For 3 Seconds", function()
	state.status = "Temporarily hidden"
	statusLabel:SetText("Status: " .. state.status)
	window:SetVisible(false)

	task.delay(3, function()
		window:SetVisible(true)
		state.status = "Visible again"
		statusLabel:SetText("Status: " .. state.status)
	end)
end)

miscTab:AddButton("Unload UI", function()
	DrawingUI.ClearAll()
end)

window:SetActiveTab("Combat")
