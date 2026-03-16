local HttpService = game:GetService("HttpService")
local DrawingUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/drawing-ui-lib/main/DrawingUI.lua?v=0.9.0"))()

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

local CONFIG_FOLDER = "drawing-ui-lib-configs"

local function hasFilesystem()
	return typeof(writefile) == "function"
		and typeof(readfile) == "function"
		and typeof(listfiles) == "function"
		and typeof(isfolder) == "function"
		and typeof(makefolder) == "function"
end

local function ensureConfigFolder()
	if not hasFilesystem() then
		return false
	end

	if not isfolder(CONFIG_FOLDER) then
		makefolder(CONFIG_FOLDER)
	end

	return true
end

local function getConfigNames()
	if not ensureConfigFolder() then
		return {}
	end

	local results = {}

	for _, path in ipairs(listfiles(CONFIG_FOLDER)) do
		local name = path:match("([^\\/]+)%.json$")
		if name then
			table.insert(results, name)
		end
	end

	table.sort(results)
	return results
end

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
local applyConfig

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

local profileLabel = configTab:AddLabel("Profile: " .. state.profileName)
local bindLabel = configTab:AddLabel("Menu Bind: " .. formatBinding(state.menuBind))
local configStatusLabel = configTab:AddLabel("Config Status: Ready")

local profileTextbox = configTab:AddTextbox("Profile Name", "Type a profile name...", function(value)
	state.profileName = value ~= "" and value or "Legit"
	profileLabel:SetText("Profile: " .. state.profileName)
end)

local clanTextbox = configTab:AddTextbox("Clan Tag", "Optional clan tag...", function(value)
	state.clanTag = value ~= "" and value or "ORBIT"
end)

local themeDropdown = configTab:AddDropdown("Theme Preset", { "Amber", "Midnight", "Default" }, "Amber", function(value)
	state.themePreset = value
	if value == "Midnight" then
		window:SetTheme(DrawingUI.Themes.Midnight)
	elseif value == "Default" then
		window:SetTheme(DrawingUI.Themes.Default)
	else
		window:SetTheme(DrawingUI.Themes.Amber)
	end
end)

local menuBindControl = configTab:AddKeybind("Menu Bind", state.menuBind, function()
	window:SetVisible(not window.visible)
end, function(binding)
	state.menuBind = binding
	bindLabel:SetText("Menu Bind: " .. formatBinding(binding))
end)

local configNameTextbox = configTab:AddTextbox("Config Name", "Type config name...", function(value)
	state.selectedConfig = value
end)

local configSelector = configTab:AddSearchDropdown("Stored Configs", getConfigNames(), nil, function(value)
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
	local names = getConfigNames()
	configSelector:SetOptions(names, selectedName or state.selectedConfig or names[1] or "No configs")

	if #names == 0 then
		state.selectedConfig = ""
	else
		state.selectedConfig = selectedName or state.selectedConfig ~= "" and state.selectedConfig or names[1]
	end
end

local function collectConfig()
	return {
		enabled = state.enabled,
		showFov = state.showFov,
		showBoxes = state.showBoxes,
		showNames = state.showNames,
		flags = state.flags,
		fov = state.fov,
		smoothness = state.smoothness,
		targetPart = state.targetPart,
		searchTarget = state.searchTarget,
		profileName = state.profileName,
		clanTag = state.clanTag,
		menuBind = state.menuBind,
		themePreset = state.themePreset,
		accentColor = {
			r = state.accentColor.R,
			g = state.accentColor.G,
			b = state.accentColor.B,
		},
	}
end

applyConfig = function(config)
	state.enabled = config.enabled == true
	state.showFov = config.showFov ~= false
	state.showBoxes = config.showBoxes == true
	state.showNames = config.showNames ~= false
	state.flags = config.flags or {}
	state.fov = config.fov or 140
	state.smoothness = config.smoothness or 0.2
	state.targetPart = config.targetPart or "Head"
	state.searchTarget = config.searchTarget or state.targetPart
	state.profileName = config.profileName or "Legit"
	state.clanTag = config.clanTag or "ORBIT"
	state.menuBind = config.menuBind or state.menuBind
	applyThemePreset(config.themePreset or "Amber")

	if config.accentColor then
		applyAccent(Color3.new(config.accentColor.r, config.accentColor.g, config.accentColor.b))
	end

	masterToggle:SetValue(state.enabled)
	fovToggle:SetValue(state.showFov)
	boxesToggle:SetValue(state.showBoxes)
	namesToggle:SetValue(state.showNames)
	fovSlider:SetValue(state.fov)
	smoothnessSlider:SetValue(state.smoothness)
	targetDropdown:SetValue(state.targetPart)
	searchTargetDropdown:SetValue(state.searchTarget)
	flagsDropdown:SetValues(state.flags)
	profileTextbox:SetText(state.profileName)
	clanTextbox:SetText(state.clanTag)
	themeDropdown:SetValue(state.themePreset)
	menuBindControl:SetBinding(state.menuBind)
	accentPicker:SetColor(state.accentColor)
	enabledLabel:SetText("Enabled: " .. tostring(state.enabled))
	fovLabel:SetText("FOV Radius: " .. tostring(state.fov))
	smoothnessLabel:SetText("Smoothness: " .. formatNumber(state.smoothness))
	profileLabel:SetText("Profile: " .. state.profileName)
	bindLabel:SetText("Menu Bind: " .. formatBinding(state.menuBind))
	window:SetTitle(state.enabled and ("Example Hub v" .. (DrawingUI.Version or "dev") .. " [ON]") or ("Example Hub v" .. (DrawingUI.Version or "dev")))
end

configTab:AddButton("Create Config", function()
	if not ensureConfigFolder() then
		configStatusLabel:SetText("Config Status: Filesystem unavailable")
		return
	end

	local name = state.selectedConfig ~= "" and state.selectedConfig or state.profileName
	local path = CONFIG_FOLDER .. "/" .. name .. ".json"
	writefile(path, HttpService:JSONEncode(collectConfig()))
	configStatusLabel:SetText("Config Status: Saved " .. name)
	refreshConfigList(name)
end)

configTab:AddButton("Load Config", function()
	if not ensureConfigFolder() or state.selectedConfig == "" then
		configStatusLabel:SetText("Config Status: Nothing selected")
		return
	end

	local path = CONFIG_FOLDER .. "/" .. state.selectedConfig .. ".json"
	if typeof(isfile) ~= "function" or not isfile(path) then
		configStatusLabel:SetText("Config Status: Missing file")
		return
	end

	local decoded = HttpService:JSONDecode(readfile(path))
	applyConfig(decoded)
	configStatusLabel:SetText("Config Status: Loaded " .. state.selectedConfig)
end)

configTab:AddButton("Delete Config", function()
	if not ensureConfigFolder() or state.selectedConfig == "" then
		configStatusLabel:SetText("Config Status: Nothing selected")
		return
	end

	local path = CONFIG_FOLDER .. "/" .. state.selectedConfig .. ".json"
	if typeof(delfile) == "function" and (typeof(isfile) ~= "function" or isfile(path)) then
		delfile(path)
		configStatusLabel:SetText("Config Status: Deleted " .. state.selectedConfig)
		state.selectedConfig = ""
		refreshConfigList("")
	else
		configStatusLabel:SetText("Config Status: Delete unavailable")
	end
end)

miscTab:AddSection("Actions")
accentPicker = miscTab:AddColorPicker("Accent Color", state.accentColor, function(color)
	applyAccent(color)
end)

miscTab:AddButton("Unload UI", function()
	DrawingUI.ClearAll()
end)

refreshConfigList()
window:SetActiveTab("Combat")
