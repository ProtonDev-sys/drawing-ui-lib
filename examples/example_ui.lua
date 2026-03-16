local DrawingUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/drawing-ui-lib/main/DrawingUI.lua?v=0.10.5"))()

local state = {
	enabled = false,
	showFov = true,
	showBoxes = false,
	showNames = true,
	flags = { "Box", "Name" },
	fov = 140,
	smoothness = 0.2,
	targetPart = "Head",
	searchTarget = "Head",
	profileName = "Legit",
	clanTag = "ORBIT",
	menuBind = {
		kind = "Keyboard",
		code = Enum.KeyCode.RightShift,
	},
	accentColor = Color3.fromRGB(255, 155, 66),
	themePreset = "Amber",
	selectedConfig = "",
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
	Title = "Example Hub v" .. (DrawingUI.Version or "dev"),
	Position = Vector2.new(140, 90),
	Size = Vector2.new(510, 350),
	ConfigId = "example-hub",
	Theme = DrawingUI.Themes.Amber,
})

window:SetSubtitle("tabbed example")

local combatTab = window:AddTab("Combat")
local visualsTab = window:AddTab("Visuals")
local configTab = window:AddTab("Config")
local miscTab = window:AddTab("Misc")
local applyThemePreset
local applyAccent
local refreshConfigList

combatTab:AddSection("Aim Assist")
combatTab:AddParagraph("Overview", "Tabs, buttons, sliders, dropdowns, textboxes, keybinds and theme-driven colors are all exposed by the library.")

local enabledLabel = combatTab:AddLabel("Enabled: false")
local fovLabel = combatTab:AddLabel("FOV Radius: " .. tostring(state.fov))
local smoothnessLabel = combatTab:AddLabel("Smoothness: " .. formatNumber(state.smoothness))

local masterToggle = combatTab:AddToggle("Master Toggle", state.enabled, function(value)
	state.enabled = value
	enabledLabel:SetText("Enabled: " .. tostring(value))
	window:SetTitle(value and "Example Hub [ON]" or "Example Hub [OFF]")
end)

local fovSlider = combatTab:AddSlider("FOV Radius", 40, 400, state.fov, function(value)
	state.fov = math.floor(value + 0.5)
	fovLabel:SetText("FOV Radius: " .. tostring(state.fov))
end)

local smoothnessSlider = combatTab:AddSlider("Smoothness", 0.05, 1, state.smoothness, function(value)
	state.smoothness = value
	smoothnessLabel:SetText("Smoothness: " .. formatNumber(value))
end)

local targetDropdown = combatTab:AddDropdown("Target Part", { "Head", "Torso", "Closest" }, state.targetPart, function(value)
	state.targetPart = value
	window:SetSubtitle("targeting " .. string.lower(value))
end)

local searchTargetDropdown = combatTab:AddSearchDropdown("Search Target", { "Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart", "Closest" }, state.searchTarget, function(value)
	state.searchTarget = value
	window:SetSubtitle("search " .. string.lower(value))
end)

visualsTab:AddSection("ESP")

local visualsLabel = visualsTab:AddLabel("Draw helpers for targets")

local fovToggle = visualsTab:AddToggle("Draw FOV Circle", state.showFov, function(value)
	state.showFov = value
	visualsLabel:SetText(value and "Draw helpers for targets" or "Circle overlay disabled")
end)

local boxesToggle = visualsTab:AddToggle("Boxes", state.showBoxes, function(value)
	state.showBoxes = value
end)

local namesToggle = visualsTab:AddToggle("Names", state.showNames, function(value)
	state.showNames = value
end)

local flagsDropdown = visualsTab:AddMultiDropdown("ESP Flags", { "Box", "Name", "Health", "Distance", "Weapon" }, state.flags, function(values)
	state.flags = values
	visualsLabel:SetText(#values > 0 and ("Flags: " .. table.concat(values, ", ")) or "No flags selected")
end)

configTab:AddSection("Configuration")
local profileSubTab = configTab:AddSubTab("Profile", true)
local storageSubTab = configTab:AddSubTab("Config Files", true)
local profileLabel = profileSubTab:AddLabel("Profile: " .. state.profileName)
local bindLabel = profileSubTab:AddLabel("Menu Bind: " .. formatBinding(state.menuBind))
local configStatusLabel = storageSubTab:AddLabel("Config Status: Ready")

local profileTextbox = profileSubTab:AddTextbox("Profile Name", "Type a profile name...", function(value)
	state.profileName = value ~= "" and value or "Legit"
	profileLabel:SetText("Profile: " .. state.profileName)
end)

local clanTextbox = profileSubTab:AddTextbox("Clan Tag", "Optional clan tag...", function(value)
	state.clanTag = value ~= "" and value or "ORBIT"
end)

local themeDropdown = profileSubTab:AddDropdown("Theme Preset", { "Amber", "Midnight", "Default" }, "Amber", function(value)
	state.themePreset = value
	if value == "Midnight" then
		window:SetTheme(DrawingUI.Themes.Midnight)
	elseif value == "Default" then
		window:SetTheme(DrawingUI.Themes.Default)
	else
		window:SetTheme(DrawingUI.Themes.Amber)
	end
end)

local menuBindControl = profileSubTab:AddKeybind("Menu Bind", state.menuBind, function()
	window:SetVisible(not window.visible)
end, function(binding)
	state.menuBind = binding
	bindLabel:SetText("Menu Bind: " .. formatBinding(binding))
end)
menuBindControl:SetAllowMouseInputs(true)

local configNameTextbox = storageSubTab:AddTextbox("Config Name", "Type config name...", function(value)
	state.selectedConfig = value
end)

local configSelector = storageSubTab:AddSearchDropdown("Stored Configs", window:ListConfigs(), nil, function(value)
	state.selectedConfig = value
	configNameTextbox:SetText(value)
end)

applyThemePreset = function(preset)
	state.themePreset = preset

	if preset == "Midnight" then
		window:SetTheme(DrawingUI.Themes.Midnight)
	elseif preset == "Default" then
		window:SetTheme(DrawingUI.Themes.Default)
	else
		window:SetTheme(DrawingUI.Themes.Amber)
	end
end

applyAccent = function(color)
	state.accentColor = color
	window:SetTheme({
		Accent = color,
		ToggleEnabled = color,
		SliderFill = color,
	})
end

local accentPicker

refreshConfigList = function(selectedName)
	local names = window:ListConfigs()
	configSelector:SetOptions(names, selectedName or state.selectedConfig or names[1] or "No configs")

	if #names == 0 then
		state.selectedConfig = ""
	else
		state.selectedConfig = selectedName or state.selectedConfig ~= "" and state.selectedConfig or names[1]
	end
end

storageSubTab:AddButtonRow({
	{
		text = "Create",
		callback = function()
	local name = state.selectedConfig ~= "" and state.selectedConfig or state.profileName
	local ok, result = window:SaveConfig(name)
	configStatusLabel:SetText(ok and ("Config Status: Saved " .. result) or ("Config Status: " .. result))

	if ok then
		state.selectedConfig = result
		refreshConfigList(result)
	end
		end,
	},
	{
		text = "Load",
		callback = function()
			if state.selectedConfig == "" then
				configStatusLabel:SetText("Config Status: Nothing selected")
				return
			end

			local ok, result = window:LoadConfig(state.selectedConfig, true)
			configStatusLabel:SetText(ok and ("Config Status: Loaded " .. result) or ("Config Status: " .. result))
		end,
	},
	{
		text = "Delete",
		callback = function()
			if state.selectedConfig == "" then
				configStatusLabel:SetText("Config Status: Nothing selected")
				return
			end

			local ok, result = window:DeleteConfig(state.selectedConfig)
			configStatusLabel:SetText(ok and ("Config Status: Deleted " .. result) or ("Config Status: " .. result))

			if ok then
				state.selectedConfig = ""
				refreshConfigList("")
			end
		end,
	},
})

miscTab:AddSection("Actions")
accentPicker = miscTab:AddColorPicker("Accent Color", state.accentColor, function(color)
	applyAccent(color)
end)

local unloadButton = miscTab:AddButton("Unload UI", function()
	DrawingUI.ClearAll()
end)
unloadButton:SetActivationBinding({
	kind = "Keyboard",
	code = Enum.KeyCode.End,
})
boxesToggle:SetActivationBinding({
	kind = "Keyboard",
	code = Enum.KeyCode.B,
})

refreshConfigList()
window:SetActiveTab("Combat")
