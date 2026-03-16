local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local DrawingUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/drawing-ui-lib/main/DrawingUI.lua?v=0.11.1"))()

local LocalPlayer = Players.LocalPlayer
local SKELETON_SEGMENTS = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },
	{ "Head", "Torso" },
	{ "Torso", "Left Arm" },
	{ "Torso", "Right Arm" },
	{ "Torso", "Left Leg" },
	{ "Torso", "Right Leg" },
}

local state = {
	aimEnabled = false,
	drawFovCircle = true,
	visibleCheck = false,
	espEnabled = true,
	flags = { "Box", "Name", "Health", "Distance" },
	fov = 140,
	smoothness = 0.2,
	targetPart = "Head",
	themePreset = "Amber",
	accentColor = Color3.fromRGB(255, 155, 66),
	espColor = Color3.fromRGB(255, 170, 90),
	menuBind = {
		kind = "Keyboard",
		code = Enum.KeyCode.RightShift,
	},
	aimBind = {
		kind = "MouseButton2",
	},
	configName = "showcase",
	selectedConfig = "",
}

local overlayEntries = {}
local overlayConnections = {}
local aimHolding = false
local fovCircle = Drawing.new("Circle")
local CORNER_LINE_COUNT = 8

local function round(value)
	return math.floor(value + 0.5)
end

local function bindingMatchesInput(binding, input)
	if binding == nil then
		return false
	end

	if binding.kind == "Keyboard" then
		return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == binding.code
	end

	if binding.kind == "MouseButton1" then
		return input.UserInputType == Enum.UserInputType.MouseButton1
	elseif binding.kind == "MouseButton2" then
		return input.UserInputType == Enum.UserInputType.MouseButton2
	elseif binding.kind == "MouseButton3" then
		return input.UserInputType == Enum.UserInputType.MouseButton3
	end

	return false
end

local function hasFlag(flag)
	for _, value in ipairs(state.flags) do
		if value == flag then
			return true
		end
	end

	return false
end

local function createOverlayEntry()
	local entry = {
		box = Drawing.new("Square"),
		corners = {},
		name = Drawing.new("Text"),
		health = Drawing.new("Text"),
		distance = Drawing.new("Text"),
		skeleton = {},
	}

	for index = 1, CORNER_LINE_COUNT do
		entry.corners[index] = Drawing.new("Line")
	end

	for index = 1, #SKELETON_SEGMENTS do
		entry.skeleton[index] = Drawing.new("Line")
	end

	return entry
end

local function hideOverlayEntry(entry)
	entry.box.Visible = false
	entry.name.Visible = false
	entry.health.Visible = false
	entry.distance.Visible = false

	for _, line in ipairs(entry.corners) do
		line.Visible = false
	end

	for _, line in ipairs(entry.skeleton) do
		line.Visible = false
	end
end

local function applyOverlayTheme(entry)
	entry.box.Filled = false
	entry.box.Thickness = 1
	entry.box.Transparency = 1
	entry.box.Color = state.espColor

	for _, line in ipairs(entry.corners) do
		line.Color = state.espColor
		line.Thickness = 1.5
		line.Transparency = 1
	end

	for _, drawing in ipairs({ entry.name, entry.health, entry.distance }) do
		drawing.Center = true
		drawing.Color = state.espColor
		drawing.Size = 13
		drawing.Font = 0
		drawing.Outline = true
	end

	for _, line in ipairs(entry.skeleton) do
		line.Color = state.espColor
		line.Thickness = 1
		line.Transparency = 1
	end
end

local function getOverlayEntry(target)
	local entry = overlayEntries[target]

	if entry ~= nil then
		return entry
	end

	entry = createOverlayEntry()
	applyOverlayTheme(entry)
	hideOverlayEntry(entry)
	overlayEntries[target] = entry
	return entry
end

local function removeOverlayEntry(target)
	local entry = overlayEntries[target]

	if entry == nil then
		return
	end

	entry.box:Remove()
	entry.name:Remove()
	entry.health:Remove()
	entry.distance:Remove()

	for _, line in ipairs(entry.corners) do
		line:Remove()
	end

	for _, line in ipairs(entry.skeleton) do
		line:Remove()
	end

	overlayEntries[target] = nil
end

local function clearOverlays()
	for target in pairs(overlayEntries) do
		removeOverlayEntry(target)
	end

	for _, connection in ipairs(overlayConnections) do
		connection:Disconnect()
	end

	table.clear(overlayConnections)
	fovCircle:Remove()
end

local function hideAllOverlayEntries()
	for _, entry in pairs(overlayEntries) do
		hideOverlayEntry(entry)
	end
end

local function shouldProcessEsp()
	return state.espEnabled and #state.flags > 0
end

local function iterTargets()
	local targets = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character ~= nil then
			targets[player.Character] = player.Name
		end
	end

	return targets
end

local function getCharacterBounds(model, camera)
	local minX, minY, maxX, maxY

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Transparency < 1 then
			local halfSize = descendant.Size * 0.5
			local cframe = descendant.CFrame

			for x = -1, 1, 2 do
				for y = -1, 1, 2 do
					for z = -1, 1, 2 do
						local worldPoint = cframe:PointToWorldSpace(Vector3.new(halfSize.X * x, halfSize.Y * y, halfSize.Z * z))
						local screenPoint, onScreen = camera:WorldToViewportPoint(worldPoint)

						if onScreen and screenPoint.Z > 0 then
							minX = minX and math.min(minX, screenPoint.X) or screenPoint.X
							minY = minY and math.min(minY, screenPoint.Y) or screenPoint.Y
							maxX = maxX and math.max(maxX, screenPoint.X) or screenPoint.X
							maxY = maxY and math.max(maxY, screenPoint.Y) or screenPoint.Y
						end
					end
				end
			end
		end
	end

	if minX == nil then
		return nil
	end

	return minX, minY, maxX, maxY
end

local function setSkeletonVisible(entry, isVisible)
	for _, line in ipairs(entry.skeleton) do
		line.Visible = false
	end

	if not isVisible then
		return
	end
end

local function updateSkeleton(entry, model, camera, isVisible)
	setSkeletonVisible(entry, false)

	if not isVisible then
		return
	end

	local lineIndex = 1

	for _, segment in ipairs(SKELETON_SEGMENTS) do
		local fromPart = model:FindFirstChild(segment[1])
		local toPart = model:FindFirstChild(segment[2])

		if fromPart ~= nil and toPart ~= nil and lineIndex <= #entry.skeleton then
			local fromScreen, fromVisible = camera:WorldToViewportPoint(fromPart.Position)
			local toScreen, toVisible = camera:WorldToViewportPoint(toPart.Position)

			if fromVisible and toVisible and fromScreen.Z > 0 and toScreen.Z > 0 then
				local line = entry.skeleton[lineIndex]
				line.From = Vector2.new(fromScreen.X, fromScreen.Y)
				line.To = Vector2.new(toScreen.X, toScreen.Y)
				line.Visible = true
				lineIndex += 1
			end
		end
	end
end

local function buildCornerSegments(minX, minY, maxX, maxY)
	local width = maxX - minX
	local height = maxY - minY
	local length = math.clamp(math.min(width, height) * 0.22, 8, 18)

	return {
		{ Vector2.new(minX, minY), Vector2.new(minX + length, minY) },
		{ Vector2.new(minX, minY), Vector2.new(minX, minY + length) },
		{ Vector2.new(maxX - length, minY), Vector2.new(maxX, minY) },
		{ Vector2.new(maxX, minY), Vector2.new(maxX, minY + length) },
		{ Vector2.new(minX, maxY), Vector2.new(minX + length, maxY) },
		{ Vector2.new(minX, maxY - length), Vector2.new(minX, maxY) },
		{ Vector2.new(maxX - length, maxY), Vector2.new(maxX, maxY) },
		{ Vector2.new(maxX, maxY - length), Vector2.new(maxX, maxY) },
	}
end

local function drawCornerBox(entry, minX, minY, maxX, maxY, isVisible)
	local segments = isVisible and buildCornerSegments(minX, minY, maxX, maxY) or nil

	for index, line in ipairs(entry.corners) do
		if segments ~= nil then
			local segment = segments[index]
			line.From = segment[1]
			line.To = segment[2]
			line.Visible = true
		else
			line.Visible = false
		end
	end
end

local function updateOverlayEntry(target, displayName, camera)
	local entry = getOverlayEntry(target)

	if not state.espEnabled then
		hideOverlayEntry(entry)
		return
	end

	local humanoid = target:FindFirstChildOfClass("Humanoid")
	local rootPart = target:FindFirstChild("HumanoidRootPart")

	if humanoid == nil or humanoid.Health <= 0 or rootPart == nil then
		hideOverlayEntry(entry)
		return
	end

	local minX, minY, maxX, maxY = getCharacterBounds(target, camera)

	if minX == nil then
		hideOverlayEntry(entry)
		return
	end

	entry.box.Position = Vector2.new(minX, minY)
	entry.box.Size = Vector2.new(maxX - minX, maxY - minY)
	entry.box.Color = state.espColor
	entry.box.Visible = hasFlag("Box")
	drawCornerBox(entry, minX, minY, maxX, maxY, hasFlag("Corner Box"))

	local centerX = (minX + maxX) * 0.5
	local nextTextY = minY - 14

	if hasFlag("Name") then
		entry.name.Text = displayName
		entry.name.Position = Vector2.new(centerX, nextTextY)
		entry.name.Visible = true
		nextTextY -= 14
	else
		entry.name.Visible = false
	end

	if hasFlag("Health") then
		entry.health.Text = tostring(round(humanoid.Health)) .. " HP"
		entry.health.Position = Vector2.new(centerX, nextTextY)
		entry.health.Visible = true
		nextTextY -= 14
	else
		entry.health.Visible = false
	end

	if hasFlag("Distance") then
		local distance = round((camera.CFrame.Position - rootPart.Position).Magnitude)
		entry.distance.Text = tostring(distance) .. "m"
		entry.distance.Position = Vector2.new(centerX, nextTextY)
		entry.distance.Visible = true
	else
		entry.distance.Visible = false
	end

	updateSkeleton(entry, target, camera, hasFlag("Skeletons"))
end

local function getAimPart(target)
	if state.targetPart == "Head" then
		return target:FindFirstChild("Head")
	end

	return target:FindFirstChild(state.targetPart) or target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
end

local function isTargetVisible(camera, target, aimPart)
	if not state.visibleCheck then
		return true
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = { LocalPlayer.Character }

	local origin = camera.CFrame.Position
	local direction = aimPart.Position - origin
	local result = Workspace:Raycast(origin, direction, raycastParams)

	if result == nil then
		return true
	end

	return result.Instance:IsDescendantOf(target)
end

local function getBestAimTarget(camera, mousePosition)
	local bestDelta
	local bestPosition

	for target in pairs(iterTargets()) do
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		local aimPart = getAimPart(target)

		if humanoid ~= nil and humanoid.Health > 0 and aimPart ~= nil and isTargetVisible(camera, target, aimPart) then
			local screenPoint, onScreen = camera:WorldToViewportPoint(aimPart.Position)

			if onScreen and screenPoint.Z > 0 then
				local position2d = Vector2.new(screenPoint.X, screenPoint.Y)
				local delta = position2d - mousePosition
				local distance = delta.Magnitude

				if distance <= state.fov and (bestDelta == nil or distance < bestDelta) then
					bestDelta = distance
					bestPosition = position2d
				end
			end
		end
	end

	return bestPosition
end

local function updateFovCircle(mousePosition)
	fovCircle.Visible = state.drawFovCircle and state.aimEnabled
	fovCircle.Position = mousePosition
	fovCircle.Radius = state.fov
	fovCircle.Color = state.accentColor
	fovCircle.Thickness = 1
	fovCircle.Filled = false
	fovCircle.NumSides = 42
	fovCircle.Transparency = 1
end

local function updateAim(camera, mousePosition)
	if not state.aimEnabled or not aimHolding then
		return
	end

	local targetPosition = getBestAimTarget(camera, mousePosition)

	if targetPosition == nil then
		return
	end

	local delta = targetPosition - mousePosition
	local stepX = delta.X * state.smoothness
	local stepY = delta.Y * state.smoothness

	if math.abs(stepX) < 1 and math.abs(delta.X) > 1 then
		stepX = delta.X > 0 and 1 or -1
	end

	if math.abs(stepY) < 1 and math.abs(delta.Y) > 1 then
		stepY = delta.Y > 0 and 1 or -1
	end

	if typeof(mousemoverel) == "function" then
		mousemoverel(round(stepX), round(stepY))
	elseif typeof(mousemoveabs) == "function" then
		mousemoveabs(round(targetPosition.X), round(targetPosition.Y))
	end
end

table.insert(overlayConnections, UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if bindingMatchesInput(state.aimBind, input) then
		aimHolding = true
	end
end))

table.insert(overlayConnections, UserInputService.InputEnded:Connect(function(input)
	if bindingMatchesInput(state.aimBind, input) then
		aimHolding = false
	end
end))

table.insert(overlayConnections, RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	local mousePosition = UserInputService:GetMouseLocation()
	local seenTargets = {}

	updateFovCircle(mousePosition)

	if camera ~= nil then
		if shouldProcessEsp() then
			for target, displayName in pairs(iterTargets()) do
				seenTargets[target] = true
				updateOverlayEntry(target, displayName, camera)
			end
		end

		updateAim(camera, mousePosition)
	end

	if shouldProcessEsp() then
		for target, entry in pairs(overlayEntries) do
			if not seenTargets[target] then
				hideOverlayEntry(entry)
			end
		end
	end
end))

local window = DrawingUI.CreateWindow({
	Title = "DrawingUI Showcase v" .. (DrawingUI.Version or "dev"),
	Position = Vector2.new(140, 90),
	Size = Vector2.new(500, 350),
	ConfigId = "drawingui-showcase",
	Theme = DrawingUI.Themes.Amber,
})

window:SetSubtitle("basic showcase")

local aimTab = window:AddTab("Aim")
local visualsTab = window:AddTab("Visuals")
local configTab = window:AddTab("Config")
local miscTab = window:AddTab("Misc")

local applyThemePreset
local applyAccent
local refreshConfigList

aimTab:AddSection("Targeting")

aimTab:AddToggle("Enable Aim", state.aimEnabled, function(value)
	state.aimEnabled = value
end)

aimTab:AddToggle("Draw FOV Circle", state.drawFovCircle, function(value)
	state.drawFovCircle = value
end)

aimTab:AddToggle("Visible Check", state.visibleCheck, function(value)
	state.visibleCheck = value
end)

aimTab:AddSlider("FOV Radius", 40, 400, state.fov, function(value)
	state.fov = round(value)
end)

aimTab:AddSlider("Smoothness", 0.05, 1, state.smoothness, function(value)
	state.smoothness = value
end)

aimTab:AddDropdown("Target Part", { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }, state.targetPart, function(value)
	state.targetPart = value
end)

local aimBindControl = aimTab:AddKeybind("Aim Bind", state.aimBind, function() end, function(binding)
	state.aimBind = binding
end)
aimBindControl:SetAllowMouseInputs(true)

visualsTab:AddSection("Overlay")

visualsTab:AddToggle("Enable ESP", state.espEnabled, function(value)
	state.espEnabled = value

	if not shouldProcessEsp() then
		hideAllOverlayEntries()
	end
end)

visualsTab:AddMultiDropdown("ESP Flags", { "Box", "Corner Box", "Name", "Health", "Distance", "Skeletons" }, state.flags, function(values)
	state.flags = values

	if not shouldProcessEsp() then
		hideAllOverlayEntries()
	end
end)

visualsTab:AddColorPicker("ESP Color", state.espColor, function(color)
	state.espColor = color

	for _, entry in pairs(overlayEntries) do
		applyOverlayTheme(entry)
	end
end)

configTab:AddSection("Customization")
local themeSubTab = configTab:AddSubTab("Theme", true)
local filesSubTab = configTab:AddSubTab("Config Files", true)

local configStatusLabel = filesSubTab:AddLabel("Config Status: Ready")

themeSubTab:AddDropdown("Theme Preset", { "Amber", "Midnight", "Default" }, state.themePreset, function(value)
	applyThemePreset(value)
end)

themeSubTab:AddColorPicker("Accent Color", state.accentColor, function(color)
	applyAccent(color)
end)

local menuBindControl = themeSubTab:AddKeybind("Menu Bind", state.menuBind, function()
	window:SetVisible(not window.visible)
end, function(binding)
	state.menuBind = binding
end)
menuBindControl:SetAllowMouseInputs(true)

local configNameTextbox = filesSubTab:AddTextbox("Config Name", "Type a config name...", function(value)
	state.configName = value ~= "" and value or "showcase"
end)
configNameTextbox:SetText(state.configName)

local configSelector = filesSubTab:AddSearchDropdown("Stored Configs", window:ListConfigs(), nil, 6, function(value)
	state.selectedConfig = value
	if value ~= "No configs" then
		configNameTextbox:SetText(value)
		state.configName = value
	end
end)

refreshConfigList = function(selectedName)
	local names = window:ListConfigs()
	local fallback = #names > 0 and (selectedName or state.selectedConfig or names[1]) or "No configs"
	configSelector:SetOptions(names, fallback, 6)

	if #names == 0 then
		state.selectedConfig = ""
	else
		state.selectedConfig = fallback
	end
end

filesSubTab:AddButtonRow({
	{
		text = "Save",
		callback = function()
			local name = state.configName ~= "" and state.configName or "showcase"
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
			if state.selectedConfig == "" or state.selectedConfig == "No configs" then
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
			if state.selectedConfig == "" or state.selectedConfig == "No configs" then
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
	{
		text = "Refresh",
		callback = function()
			refreshConfigList(state.selectedConfig)
			configStatusLabel:SetText("Config Status: Refreshed")
		end,
	},
})

miscTab:AddSection("Actions")

local unloadButton = miscTab:AddButton("Unload UI", function()
	clearOverlays()
	DrawingUI.ClearAll()
end)
unloadButton:SetActivationBinding({
	kind = "Keyboard",
	code = Enum.KeyCode.End,
})

applyThemePreset = function(preset)
	state.themePreset = preset

	if preset == "Midnight" then
		window:SetTheme(DrawingUI.Themes.Midnight)
	elseif preset == "Default" then
		window:SetTheme(DrawingUI.Themes.Default)
	else
		window:SetTheme(DrawingUI.Themes.Amber)
	end

	applyAccent(state.accentColor)
end

applyAccent = function(color)
	state.accentColor = color
	fovCircle.Color = color
	window:SetTheme({
		Accent = color,
		ToggleEnabled = color,
		SliderFill = color,
	})
end

refreshConfigList()
window:SetActiveTab("Aim")
