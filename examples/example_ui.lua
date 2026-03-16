local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local DrawingUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/drawing-ui-lib/v2/DrawingUI.lua?v=2.0.0"))()

local LocalPlayer = Players.LocalPlayer
local function formatInputBinding(binding)
	if binding == nil then
		return "NONE"
	end

	if binding.kind == "Keyboard" and binding.code ~= nil then
		return binding.code.Name
	end

	return binding.kind or "NONE"
end

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
	themePreset = "Circuit",
	accentColor = Color3.fromRGB(196, 104, 255),
	espColor = Color3.fromRGB(210, 128, 255),
	menuBind = {
		kind = "Keyboard",
		code = Enum.KeyCode.RightShift,
	},
	aimBind = {
		kind = "MouseButton2",
	},
	configName = "showcase",
	selectedConfig = "",
	flagLookup = {},
}

local overlayEntries = {}
local overlayConnections = {}
local cachedTargets = {}
local cachedTargetList = {}
local aimHolding = false
local fovCircle = Drawing.new("Circle")
local CORNER_LINE_COUNT = 8
local TARGET_REFRESH_INTERVAL = 0.3
local ESP_MAX_TARGET_UPDATES_PER_FRAME = 8
local lastTargetRefresh = 0
local espUpdateCursor = 1
local visibilityRaycastParams = RaycastParams.new()
local visibilityFilterCharacter = nil

visibilityRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

local function rebuildFlagLookup(values)
	table.clear(state.flagLookup)

	for _, value in ipairs(values or state.flags) do
		state.flagLookup[value] = true
	end
end

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
	return state.flagLookup[flag] == true
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

local function shouldTrackTargets()
	return state.aimEnabled or shouldProcessEsp()
end

local function buildTargetData(player)
	local character = player.Character

	if character == nil then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoid == nil or rootPart == nil then
		return nil
	end

	local targetData = {
		character = character,
		displayName = player.Name,
		humanoid = humanoid,
		rootPart = rootPart,
		head = character:FindFirstChild("Head"),
		aimParts = {
			Head = character:FindFirstChild("Head"),
			UpperTorso = character:FindFirstChild("UpperTorso"),
			LowerTorso = character:FindFirstChild("LowerTorso"),
			HumanoidRootPart = rootPart,
		},
		skeletonParts = {},
	}

	for index, segment in ipairs(SKELETON_SEGMENTS) do
		local fromPart = character:FindFirstChild(segment[1])
		local toPart = character:FindFirstChild(segment[2])

		if fromPart ~= nil and toPart ~= nil then
			targetData.skeletonParts[index] = { fromPart, toPart }
		end
	end

	return targetData
end

local function refreshTargetCache(force)
	local now = os.clock()

	if not force and (now - lastTargetRefresh) < TARGET_REFRESH_INTERVAL then
		return cachedTargets
	end

	local targets = {}
	local targetList = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local targetData = buildTargetData(player)

			if targetData ~= nil then
				targets[targetData.character] = targetData
				table.insert(targetList, targetData)
			end
		end
	end

	cachedTargets = targets
	cachedTargetList = targetList
	lastTargetRefresh = now
	espUpdateCursor = math.clamp(espUpdateCursor, 1, math.max(1, #cachedTargetList))
	return cachedTargets
end

local function getTrackedTargets()
	if not shouldTrackTargets() then
		return cachedTargets
	end

	return refreshTargetCache(false)
end

local function getTrackedTargetList()
	if not shouldTrackTargets() then
		return cachedTargetList
	end

	refreshTargetCache(false)
	return cachedTargetList
end

local function getCharacterBounds(targetData, camera)
	local humanoid = targetData.humanoid
	local rootPart = targetData.rootPart

	if humanoid == nil or rootPart == nil or humanoid.Parent == nil or rootPart.Parent == nil then
		return nil
	end

	local head = targetData.head
	local rootPosition = rootPart.Position
	local headPosition = head ~= nil and head.Parent ~= nil and head.Position or (rootPosition + Vector3.new(0, 1.6, 0))
	local topOffset = math.max(2.6, (headPosition.Y - rootPosition.Y) + 0.75)
	local bottomOffset = math.max(2.8, humanoid.HipHeight + (rootPart.Size.Y * 0.5) + 0.75)
	local topScreen, topVisible = camera:WorldToViewportPoint(rootPosition + Vector3.new(0, topOffset, 0))
	local bottomScreen, bottomVisible = camera:WorldToViewportPoint(rootPosition - Vector3.new(0, bottomOffset, 0))

	if topScreen.Z <= 0 or bottomScreen.Z <= 0 or (not topVisible and not bottomVisible) then
		return nil
	end

	local height = math.abs(bottomScreen.Y - topScreen.Y)

	if height < 2 then
		return nil
	end

	local width = math.max(6, height * 0.55)
	local centerX = (topScreen.X + bottomScreen.X) * 0.5
	local minY = math.min(topScreen.Y, bottomScreen.Y)
	local maxY = math.max(topScreen.Y, bottomScreen.Y)
	return centerX - (width * 0.5), minY, centerX + (width * 0.5), maxY
end

local function setSkeletonVisible(entry, isVisible)
	for _, line in ipairs(entry.skeleton) do
		line.Visible = false
	end

	if not isVisible then
		return
	end
end

local function updateSkeleton(entry, targetData, camera, isVisible)
	setSkeletonVisible(entry, false)

	if not isVisible then
		return
	end

	local lineIndex = 1

	for index = 1, #SKELETON_SEGMENTS do
		local segmentParts = targetData.skeletonParts[index]

		if segmentParts ~= nil then
			local fromPart = segmentParts[1]
			local toPart = segmentParts[2]

			if fromPart ~= nil and toPart ~= nil and fromPart.Parent ~= nil and toPart.Parent ~= nil and lineIndex <= #entry.skeleton then
				local fromScreen, fromVisible = camera:WorldToViewportPoint(fromPart.Position)
				local toScreen, toVisible = camera:WorldToViewportPoint(toPart.Position)

				if fromVisible and toVisible and fromScreen.Z > 0 and toScreen.Z > 0 then
					local line = entry.skeleton[lineIndex]
					line.From = Vector2.new(fromScreen.X, fromScreen.Y)
					line.To = Vector2.new(toScreen.X, toScreen.Y)
					line.Visible = true
					lineIndex = lineIndex + 1
				end
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

local function updateOverlayEntry(targetData, camera, cameraPosition)
	local target = targetData.character
	local entry = getOverlayEntry(target)

	if not state.espEnabled then
		hideOverlayEntry(entry)
		return
	end

	local humanoid = targetData.humanoid
	local rootPart = targetData.rootPart

	if humanoid == nil or rootPart == nil or humanoid.Parent == nil or rootPart.Parent == nil or humanoid.Health <= 0 then
		hideOverlayEntry(entry)
		return
	end

	local minX, minY, maxX, maxY = getCharacterBounds(targetData, camera)

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
		entry.name.Text = targetData.displayName
		entry.name.Position = Vector2.new(centerX, nextTextY)
		entry.name.Visible = true
		nextTextY = nextTextY - 14
	else
		entry.name.Visible = false
	end

	if hasFlag("Health") then
		entry.health.Text = tostring(round(humanoid.Health)) .. " HP"
		entry.health.Position = Vector2.new(centerX, nextTextY)
		entry.health.Visible = true
		nextTextY = nextTextY - 14
	else
		entry.health.Visible = false
	end

	if hasFlag("Distance") then
		local distance = round((cameraPosition - rootPart.Position).Magnitude)
		entry.distance.Text = tostring(distance) .. "m"
		entry.distance.Position = Vector2.new(centerX, nextTextY)
		entry.distance.Visible = true
	else
		entry.distance.Visible = false
	end

	updateSkeleton(entry, targetData, camera, hasFlag("Skeletons"))
end

local function getAimPart(targetData)
	if state.targetPart == "Head" then
		return targetData.aimParts.Head or targetData.rootPart
	end

	return targetData.aimParts[state.targetPart] or targetData.rootPart or targetData.aimParts.Head
end

local function updateVisibilityRaycastFilter()
	local character = LocalPlayer.Character

	if visibilityFilterCharacter == character then
		return
	end

	visibilityFilterCharacter = character
	visibilityRaycastParams.FilterDescendantsInstances = character ~= nil and { character } or {}
end

local function isTargetVisible(camera, targetData, aimPart)
	if not state.visibleCheck then
		return true
	end

	updateVisibilityRaycastFilter()

	local origin = camera.CFrame.Position
	local direction = aimPart.Position - origin
	local result = Workspace:Raycast(origin, direction, visibilityRaycastParams)

	if result == nil then
		return true
	end

	return result.Instance:IsDescendantOf(targetData.character)
end

local function getBestAimTarget(camera, mousePosition)
	local targetList = getTrackedTargetList()
	local bestDistanceSquared
	local bestPosition
	local fovSquared = state.fov * state.fov

	for index = 1, #targetList do
		local targetData = targetList[index]
		local humanoid = targetData.humanoid
		local aimPart = getAimPart(targetData)

		if humanoid ~= nil and humanoid.Parent ~= nil and humanoid.Health > 0 and aimPart ~= nil and aimPart.Parent ~= nil then
			local screenPoint, onScreen = camera:WorldToViewportPoint(aimPart.Position)

			if onScreen and screenPoint.Z > 0 then
				local deltaX = screenPoint.X - mousePosition.X
				local deltaY = screenPoint.Y - mousePosition.Y
				local distanceSquared = (deltaX * deltaX) + (deltaY * deltaY)

				if distanceSquared <= fovSquared and isTargetVisible(camera, targetData, aimPart) and (bestDistanceSquared == nil or distanceSquared < bestDistanceSquared) then
					bestDistanceSquared = distanceSquared
					bestPosition = Vector2.new(screenPoint.X, screenPoint.Y)
				end
			end
		end
	end

	return bestPosition
end

rebuildFlagLookup()

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

local function updateEsp(camera)
	local targets = getTrackedTargets()
	local targetList = getTrackedTargetList()
	local targetCount = #targetList
	local cameraPosition = camera.CFrame.Position

	if targetCount == 0 then
		for _, entry in pairs(overlayEntries) do
			hideOverlayEntry(entry)
		end

		return
	end

	local updatesThisFrame = math.min(targetCount, ESP_MAX_TARGET_UPDATES_PER_FRAME)

	for offset = 0, updatesThisFrame - 1 do
		local index = ((espUpdateCursor + offset - 1) % targetCount) + 1
		updateOverlayEntry(targetList[index], camera, cameraPosition)
	end

	espUpdateCursor = ((espUpdateCursor + updatesThisFrame - 1) % targetCount) + 1

	for target, entry in pairs(overlayEntries) do
		if targets[target] == nil then
			hideOverlayEntry(entry)
		end
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

	updateFovCircle(mousePosition)

	if camera ~= nil then
		if shouldProcessEsp() then
			updateEsp(camera)
		end

		updateAim(camera, mousePosition)
	end
end))

local window = DrawingUI.CreateApp({
	Title = "DrawingUI Showcase v" .. (DrawingUI.Version or "dev"),
	ConfigId = "drawingui-showcase-v2",
	Theme = DrawingUI.Themes.Circuit,
})

window:SetHeader({
	title = "DrawingUI Control Deck",
	subtitle = "workspace shell showcase",
	actions = {
		{
			text = "Hide",
			callback = function()
				window:SetVisible(false)
			end,
		},
		{
			text = "Unload",
			callback = function()
				clearOverlays()
				DrawingUI.ClearAll()
			end,
		},
	},
})

local overviewPage = window:AddPage({
	id = "overview",
	label = "Overview",
	icon = "O",
	badge = "LIVE",
})

local aimPage = window:AddPage({
	id = "aim",
	label = "Aim",
	icon = "A",
})

local visualsPage = window:AddPage({
	id = "visuals",
	label = "Visuals",
	icon = "V",
})

local configPage = window:AddPage({
	id = "configs",
	label = "Configs",
	icon = "C",
})

local settingsPage = window:AddPage({
	id = "settings",
	label = "Settings",
	icon = "S",
})

local applyThemePreset
local applyAccent
local refreshConfigList

local overviewHero = overviewPage:AddSection({
	title = "Workspace Summary",
	description = "Fast launch controls and live configuration state.",
	columnSpan = 7,
})

local quickActions = overviewHero:AddGroup({
	title = "Quick Actions",
	defaultOpen = true,
})

quickActions:AddButtonRow({
	{
		text = "Toggle ESP",
		callback = function()
			state.espEnabled = not state.espEnabled
		end,
	},
	{
		text = "Toggle Aim",
		callback = function()
			state.aimEnabled = not state.aimEnabled
		end,
	},
	{
		text = "Hide UI",
		callback = function()
			window:SetVisible(false)
		end,
	},
})

local statusGroup = overviewHero:AddGroup({
	title = "Live Status",
	defaultOpen = true,
})

local statusAim = statusGroup:AddLabel("Aim Enabled: " .. tostring(state.aimEnabled))
local statusEsp = statusGroup:AddLabel("ESP Enabled: " .. tostring(state.espEnabled))
local statusTarget = statusGroup:AddLabel("Target Part: " .. state.targetPart)

local overviewProfiles = overviewPage:AddSection({
	title = "Preset Snapshot",
	description = "Theme, binds, and target settings at a glance.",
	columnSpan = 5,
})

overviewProfiles:AddParagraph("Theme", "Preset: " .. state.themePreset)
overviewProfiles:AddParagraph("Aim Bind", formatInputBinding(state.aimBind))
overviewProfiles:AddParagraph("Menu Bind", formatInputBinding(state.menuBind))

overviewPage:SetAside(function(aside)
	local asideSection = aside:AddSection({
		title = "Telemetry",
		description = "Right-side utility rail content.",
	})

	asideSection:AddParagraph("FOV Radius", tostring(state.fov))
	asideSection:AddParagraph("Smoothness", string.format("%.2f", state.smoothness))
	asideSection:AddParagraph("ESP Flags", table.concat(state.flags, ", "))
end)

local aimMain = aimPage:AddSection({
	title = "Targeting Controls",
	description = "Primary aim-assist controls for the current workspace.",
	columnSpan = 7,
})

aimMain:AddToggle("Enable Aim", state.aimEnabled, function(value)
	state.aimEnabled = value
	statusAim:SetText("Aim Enabled: " .. tostring(value))
end)

aimMain:AddToggle("Draw FOV Circle", state.drawFovCircle, function(value)
	state.drawFovCircle = value
end)

aimMain:AddToggle("Visible Check", state.visibleCheck, function(value)
	state.visibleCheck = value
end)

aimMain:AddSlider("FOV Radius", 40, 400, state.fov, function(value)
	state.fov = round(value)
end)

aimMain:AddSlider("Smoothness", 0.05, 1, state.smoothness, function(value)
	state.smoothness = value
end)

aimMain:AddDropdown("Target Part", { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }, state.targetPart, function(value)
	state.targetPart = value
	statusTarget:SetText("Target Part: " .. value)
end)

local aimBindControl = aimMain:AddKeybind("Aim Bind", state.aimBind, function() end, function(binding)
	state.aimBind = binding
end)
aimBindControl:SetAllowMouseInputs(true)

local aimPreview = aimPage:AddSection({
	title = "Assist Preview",
	description = "Shell-side context for current assist state.",
	columnSpan = 5,
})

aimPreview:AddParagraph("Assist Mode", "Hold the configured bind to engage smoothing.")
aimPreview:AddParagraph("Target Part", state.targetPart)
aimPreview:AddParagraph("Visible Check", tostring(state.visibleCheck))

local visualsMain = visualsPage:AddSection({
	title = "Overlay Controls",
	description = "ESP rendering and highlight settings.",
	columnSpan = 8,
})

visualsMain:AddToggle("Enable ESP", state.espEnabled, function(value)
	state.espEnabled = value
	statusEsp:SetText("ESP Enabled: " .. tostring(value))

	if not shouldProcessEsp() then
		hideAllOverlayEntries()
	end
end)

visualsMain:AddMultiDropdown("ESP Flags", { "Box", "Corner Box", "Name", "Health", "Distance", "Skeletons" }, state.flags, function(values)
	state.flags = values
	rebuildFlagLookup(values)

	if not shouldProcessEsp() then
		hideAllOverlayEntries()
	end
end)

visualsMain:AddColorPicker("ESP Color", state.espColor, function(color)
	state.espColor = color

	for _, entry in pairs(overlayEntries) do
		applyOverlayTheme(entry)
	end
end)

local visualsSide = visualsPage:AddSection({
	title = "Legend",
	description = "What each ESP flag surfaces in the overlay.",
	columnSpan = 4,
})

visualsSide:AddParagraph("Box", "Full body box around the target.")
visualsSide:AddParagraph("Corner Box", "Corner-only frame with lighter visual weight.")
visualsSide:AddParagraph("Skeletons", "Bone chain lines for posture read.")

local configMain = configPage:AddSection({
	title = "Theme & Persistence",
	description = "Control deck customization and saved config workflow.",
	columnSpan = 8,
})

local themeSubTab = configMain:AddGroup({
	title = "Theme",
	defaultOpen = true,
})

local filesSubTab = configMain:AddGroup({
	title = "Config Files",
	defaultOpen = true,
})

local configStatusLabel = filesSubTab:AddLabel("Config Status: Ready")

themeSubTab:AddDropdown("Theme Preset", { "Circuit", "Amber", "Midnight", "Default" }, state.themePreset, function(value)
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

configPage:SetAside(function(aside)
	local asideSection = aside:AddSection({
		title = "Stored State",
		description = "Config index and current selection.",
	})

	asideSection:AddParagraph("Selected", state.selectedConfig ~= "" and state.selectedConfig or "None")
	asideSection:AddParagraph("Config Folder", window:GetConfigFolder())
end)

local settingsMain = settingsPage:AddSection({
	title = "Shell Settings",
	description = "Density, motion, and system actions for the v2 workspace.",
	columnSpan = 7,
})

settingsMain:AddDropdown("Density", { "comfortable", "compact" }, "comfortable", function(value)
	window:SetDensity(value)
end)

settingsMain:AddDropdown("Motion Mode", { "full", "reduced", "off" }, "full", function(value)
	window:SetMotion(value)
end)

local unloadButton = settingsMain:AddButton("Unload UI", function()
	clearOverlays()
	DrawingUI.ClearAll()
end)

unloadButton:SetActivationBinding({
	kind = "Keyboard",
	code = Enum.KeyCode.End,
})

local settingsDiagnostics = settingsPage:AddSection({
	title = "Diagnostics",
	description = "Basic shell and input state.",
	columnSpan = 5,
})

settingsDiagnostics:AddParagraph("Menu Bind", formatInputBinding(state.menuBind))
settingsDiagnostics:AddParagraph("Aim Bind", formatInputBinding(state.aimBind))
settingsDiagnostics:AddParagraph("Visibility Check", tostring(state.visibleCheck))

applyThemePreset = function(preset)
	state.themePreset = preset

	if preset == "Midnight" then
		window:SetTheme(DrawingUI.Themes.Midnight)
	elseif preset == "Circuit" then
		window:SetTheme(DrawingUI.Themes.Circuit)
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
window:SetActivePage("overview")
