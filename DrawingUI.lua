local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local DrawingUI = {}
DrawingUI.__index = DrawingUI
local VERSION = "0.10.0"

local DEFAULT_THEME = {
	WindowBackground = Color3.fromRGB(19, 22, 28),
	HeaderBackground = Color3.fromRGB(27, 32, 40),
	Border = Color3.fromRGB(70, 76, 89),
	Accent = Color3.fromRGB(63, 161, 255),
	Muted = Color3.fromRGB(123, 130, 145),
	Text = Color3.fromRGB(240, 242, 245),
	SubText = Color3.fromRGB(176, 182, 192),
	Button = Color3.fromRGB(31, 36, 45),
	ButtonHover = Color3.fromRGB(39, 46, 58),
	Input = Color3.fromRGB(24, 28, 35),
	InputHover = Color3.fromRGB(31, 36, 45),
	InputFocused = Color3.fromRGB(35, 42, 53),
	Tab = Color3.fromRGB(24, 29, 38),
	TabHover = Color3.fromRGB(33, 39, 50),
	TabActive = Color3.fromRGB(36, 44, 56),
	Toggle = Color3.fromRGB(48, 54, 67),
	ToggleEnabled = Color3.fromRGB(63, 161, 255),
	SliderTrack = Color3.fromRGB(45, 50, 62),
	SliderFill = Color3.fromRGB(63, 161, 255),
	SectionLine = Color3.fromRGB(53, 59, 72),
	Font = 1,
	TitleSize = 16,
	TextSize = 14,
	SmallTextSize = 13,
}

local DEFAULT_WINDOW = {
	Title = "Drawing UI",
	Position = Vector2.new(200, 160),
	Size = Vector2.new(470, 360),
	Visible = true,
	DragAnywhere = true,
	Theme = {},
}

local FONT = 1
local HEADER_HEIGHT = 34
local TAB_HEIGHT = 26
local TAB_GAP = 6
local PADDING = 14
local CONTENT_GAP = 12
local ROW_HEIGHT = 24
local ROW_GAP = 10
local BUTTON_HEIGHT = 30
local TOGGLE_HEIGHT = 24
local SECTION_HEIGHT = 20
local SLIDER_HEIGHT = 40
local INPUT_HEIGHT = 28
local DROPDOWN_OPTION_HEIGHT = 24
local LABELED_INPUT_HEIGHT = 44
local SEARCH_DROPDOWN_CLOSED_HEIGHT = 44
local WINDOW_MARGIN = 8

local windows = {}
local frameConnection
local inputBeganConnection
local inputEndedConnection
local activeTextbox
local listeningKeybind
local inputBlockBound = false
local updateInputBlocker

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function lerp(a, b, alpha)
	return a + (b - a) * alpha
end

local function round(value)
	return math.floor(value + 0.5)
end

local function colorLerp(a, b, alpha)
	return Color3.new(
		lerp(a.R, b.R, alpha),
		lerp(a.G, b.G, alpha),
		lerp(a.B, b.B, alpha)
	)
end

local function mergeTheme(overrides)
	local theme = {}

	for key, value in pairs(DEFAULT_THEME) do
		theme[key] = value
	end

	for key, value in pairs(overrides or {}) do
		theme[key] = value
	end

	return theme
end

local function getViewportSize()
	local camera = Workspace.CurrentCamera

	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1280, 720)
end

local function writeProperty(drawing, property, value)
	if typeof(setrenderproperty) == "function" then
		setrenderproperty(drawing, property, value)
	else
		drawing[property] = value
	end
end

local function createDrawing(className, properties)
	local drawing = Drawing.new(className)

	for property, value in pairs(properties) do
		writeProperty(drawing, property, value)
	end

	return drawing
end

local function destroyDrawing(drawing)
	if drawing == nil then
		return
	end

	if typeof(isrenderobj) == "function" and not isrenderobj(drawing) then
		return
	end

	drawing:Remove()
end

local function pointInRect(point, position, size)
	return point.X >= position.X
		and point.X <= position.X + size.X
		and point.Y >= position.Y
		and point.Y <= position.Y + size.Y
end

local function getMousePosition()
	return UserInputService:GetMouseLocation()
end

local function formatKeyCode(keyCode)
	if keyCode == nil or keyCode == Enum.KeyCode.Unknown then
		return "NONE"
	end

	local name = keyCode.Name

	if #name == 1 then
		return string.upper(name)
	end

	if name == "LeftShift" then
		return "LShift"
	elseif name == "RightShift" then
		return "RShift"
	elseif name == "LeftControl" then
		return "LCtrl"
	elseif name == "RightControl" then
		return "RCtrl"
	elseif name == "Backquote" then
		return "`"
	elseif name == "MouseButton1" then
		return "Mouse1"
	elseif name == "MouseButton2" then
		return "Mouse2"
	end

	return name
end

local function formatInputBinding(binding)
	if binding == nil then
		return "NONE"
	end

	if binding.kind == "Keyboard" then
		return formatKeyCode(binding.code)
	elseif binding.kind == "MouseButton1" then
		return "Mouse1"
	elseif binding.kind == "MouseButton2" then
		return "Mouse2"
	elseif binding.kind == "MouseButton3" then
		return "Mouse3"
	end

	return tostring(binding.kind)
end

local function makeBindingFromInput(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return {
			kind = "Keyboard",
			code = input.KeyCode,
		}
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		return { kind = "MouseButton1" }
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		return { kind = "MouseButton2" }
	elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
		return { kind = "MouseButton3" }
	end

	return nil
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

local function getCharacterForInput(input)
	if input.KeyCode == Enum.KeyCode.Space then
		return " "
	end

	local character = UserInputService:GetStringForKeyCode(input.KeyCode)

	if character == "" then
		return nil
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
		return string.upper(character)
	end

	return character
end

local function wrapText(text, maxCharacters)
	local lines = {}
	local current = ""

	for word in string.gmatch(text, "%S+") do
		local candidate = current == "" and word or (current .. " " .. word)

		if #candidate > maxCharacters and current ~= "" then
			table.insert(lines, current)
			current = word
		else
			current = candidate
		end
	end

	if current ~= "" then
		table.insert(lines, current)
	end

	if #lines == 0 then
		table.insert(lines, text)
	end

	return table.concat(lines, "\n"), #lines
end

local function sanitizeFileName(name)
	local cleaned = tostring(name or "default"):gsub("[<>:\"/\\|%?%*]", "_")
	cleaned = cleaned:gsub("%s+", "_")
	return cleaned ~= "" and cleaned or "default"
end

local function hasFilesystem()
	return typeof(writefile) == "function"
		and typeof(readfile) == "function"
		and typeof(listfiles) == "function"
		and typeof(isfolder) == "function"
		and typeof(makefolder) == "function"
end

local function makeBaseControl(window, tab, kind, height)
	return {
		window = window,
		tab = tab,
		parentGroup = nil,
		kind = kind,
		height = height,
		visible = true,
		drawings = {},
		position = Vector2.zero,
		size = Vector2.zero,
		hovered = false,
		pressing = false,
	}
end

local function addControl(window, tab, control)
	table.insert(window.controls, control)

	if tab ~= nil then
		table.insert(tab.controls, control)
	end

	window:UpdateLayout()
	window:RefreshZIndex()

	return control
end

local function getTabWidth(name)
	return clamp(30 + (#name * 7), 72, 150)
end

local function bringWindowToFront(window)
	for index, candidate in ipairs(windows) do
		if candidate == window then
			table.remove(windows, index)
			break
		end
	end

	table.insert(windows, window)

	local baseZ = 100

	for index, candidate in ipairs(windows) do
		candidate.zBase = baseZ + (index * 24)
		candidate:RefreshZIndex()
	end
end

local function topWindowAt(point)
	for index = #windows, 1, -1 do
		local window = windows[index]

		if window.visible and pointInRect(point, window.position, window.size) then
			return window
		end
	end

	return nil
end

local function clearTextboxFocus(submit)
	if activeTextbox ~= nil then
		activeTextbox:Blur(submit)
		activeTextbox = nil
	end

	updateInputBlocker()
end

local function clearKeybindListening()
	if listeningKeybind ~= nil then
		listeningKeybind:SetListening(false)
		listeningKeybind = nil
	end

	updateInputBlocker()
end

local function shouldBlockGameInput()
	return activeTextbox ~= nil or listeningKeybind ~= nil
end

updateInputBlocker = function()
	local shouldBind = true

	if shouldBind and not inputBlockBound then
		ContextActionService:BindActionAtPriority(
			"DrawingUIBlockInput",
			function(_, inputState, inputObject)
				if inputState ~= Enum.UserInputState.Begin then
					return Enum.ContextActionResult.Pass
				end

				local mousePosition = getMousePosition()
				local overWindow = topWindowAt(mousePosition) ~= nil
				local keyboardFocused = shouldBlockGameInput()

				if keyboardFocused then
					return Enum.ContextActionResult.Sink
				end

				if inputObject.UserInputType == Enum.UserInputType.MouseButton1
					or inputObject.UserInputType == Enum.UserInputType.MouseButton2
					or inputObject.UserInputType == Enum.UserInputType.MouseButton3
				then
					return overWindow and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
				end

				return Enum.ContextActionResult.Pass
			end,
			false,
			Enum.ContextActionPriority.High.Value,
			Enum.UserInputType.Keyboard,
			Enum.UserInputType.MouseButton1,
			Enum.UserInputType.MouseButton2,
			Enum.UserInputType.MouseButton3
		)
		inputBlockBound = true
	elseif not shouldBind and inputBlockBound then
		ContextActionService:UnbindAction("DrawingUIBlockInput")
		inputBlockBound = false
	end
end

local function handleBoundInput(input)
	if activeTextbox ~= nil then
		activeTextbox:HandleKeyboardInput(input)
		return
	end

	if listeningKeybind ~= nil then
		listeningKeybind:CaptureInput(input)
		return
	end

	for _, window in ipairs(windows) do
		for _, control in ipairs(window.controls) do
			if control.kind == "Keybind" and bindingMatchesInput(control.binding, input) then
				control.callback(control.binding)
			elseif control.activationBinding ~= nil and bindingMatchesInput(control.activationBinding, input) and control.TriggerActivation then
				control:TriggerActivation()
			end
		end
	end
end

local function ensureLoop()
	if frameConnection ~= nil then
		return
	end

	frameConnection = RunService.RenderStepped:Connect(function()
		local mousePosition = getMousePosition()

		for _, window in ipairs(windows) do
			window:Step(mousePosition)
		end
	end)

	inputBeganConnection = UserInputService.InputBegan:Connect(function(input, processed)
		local mousePosition = getMousePosition()
		local overWindow = topWindowAt(mousePosition) ~= nil

		if processed and not shouldBlockGameInput() and not overWindow then
			return
		end

		if listeningKeybind ~= nil then
			listeningKeybind:CaptureInput(input)
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.MouseButton3
		then
			handleBoundInput(input)
		end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		local window = topWindowAt(mousePosition)

		if window == nil then
			clearTextboxFocus(true)
			clearKeybindListening()
			return
		end

		bringWindowToFront(window)
		window:HandleMouseDown(mousePosition)
	end)

	inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		local mousePosition = getMousePosition()

		for _, window in ipairs(windows) do
			window:HandleMouseUp(mousePosition)
		end
	end)
end

local function disconnectLoopIfEmpty()
	if #windows > 0 then
		return
	end

	if frameConnection ~= nil then
		frameConnection:Disconnect()
		frameConnection = nil
	end

	if inputBeganConnection ~= nil then
		inputBeganConnection:Disconnect()
		inputBeganConnection = nil
	end

	if inputEndedConnection ~= nil then
		inputEndedConnection:Disconnect()
		inputEndedConnection = nil
	end

	updateInputBlocker()
end

function Window:HasTabs()
	return #self.tabs > 0
end

function Window:IsTabActive(tab)
	if tab == nil then
		return not self:HasTabs()
	end

	return self.activeTab == tab
end

function Window:IsControlDisplayed(control)
	local groupVisible = control.parentGroup == nil or control.parentGroup.expanded
	return self.visible and control.visible and self:IsTabActive(control.tab) and groupVisible
end

function Window:SyncControlVisibility(control)
	local shouldShow = self:IsControlDisplayed(control)

	for _, drawing in pairs(control.drawings) do
		writeProperty(drawing, "Visible", shouldShow)
	end

	if control.refreshVisibility then
		control:refreshVisibility(shouldShow)
	end
end

function Window:SyncAllControlVisibility()
	for _, control in ipairs(self.controls) do
		self:SyncControlVisibility(control)
	end
end

function Window:ClampToViewport()
	local viewport = getViewportSize()
	local maxWidth = math.max(280, viewport.X - (WINDOW_MARGIN * 2))
	local maxHeight = math.max(220, viewport.Y - (WINDOW_MARGIN * 2))
	local width = clamp(self.size.X, self.minimumSize.X, maxWidth)
	local height = clamp(self.size.Y, self.minimumSize.Y, maxHeight)

	self.size = Vector2.new(width, height)
end

function Window:GetActiveControls()
	local list = {}

	for _, control in ipairs(self.controls) do
		if self:IsTabActive(control.tab) and (control.parentGroup == nil or control.parentGroup.expanded) then
			table.insert(list, control)
		end
	end

	return list
end

function Window:GetRequiredHeight()
	local height = HEADER_HEIGHT + CONTENT_GAP + PADDING

	if self:HasTabs() then
		height += TAB_HEIGHT + CONTENT_GAP
	end

	local activeControls = self:GetActiveControls()

	for index, control in ipairs(activeControls) do
		if control.visible then
			height += control.GetHeight and control:GetHeight() or control.height

			if index < #activeControls then
				height += ROW_GAP
			end
		end
	end

	return math.max(self.minimumSize.Y, height)
end

function Window:UpdateChrome()
	local position = self.position
	local size = self.size

	writeProperty(self.drawings.shadow, "Position", position + Vector2.new(6, 6))
	writeProperty(self.drawings.shadow, "Size", size)
	writeProperty(self.drawings.frame, "Position", position)
	writeProperty(self.drawings.frame, "Size", size)
	writeProperty(self.drawings.header, "Position", position)
	writeProperty(self.drawings.header, "Size", Vector2.new(size.X, HEADER_HEIGHT))
	writeProperty(self.drawings.accent, "From", position + Vector2.new(0, HEADER_HEIGHT))
	writeProperty(self.drawings.accent, "To", position + Vector2.new(size.X, HEADER_HEIGHT))
	writeProperty(self.drawings.title, "Position", position + Vector2.new(PADDING, 6))
	writeProperty(self.drawings.subtitle, "Position", position + Vector2.new(size.X - 112, 8))
	writeProperty(self.drawings.title, "Font", self.theme.Font)
	writeProperty(self.drawings.subtitle, "Font", self.theme.Font)
	writeProperty(self.drawings.title, "Size", self.theme.TitleSize)
	writeProperty(self.drawings.subtitle, "Size", self.theme.SmallTextSize)
end

function Window:LayoutTabs()
	local y = self.position.Y + HEADER_HEIGHT + CONTENT_GAP
	local nextTabX = self.position.X + PADDING

	for _, tab in ipairs(self.tabs) do
		local width = getTabWidth(tab.name)
		tab.position = Vector2.new(nextTabX, y)
		tab.size = Vector2.new(width, TAB_HEIGHT)
		nextTabX += width + TAB_GAP

		writeProperty(tab.drawings.background, "Position", tab.position)
		writeProperty(tab.drawings.background, "Size", tab.size)
		writeProperty(tab.drawings.outline, "Position", tab.position)
		writeProperty(tab.drawings.outline, "Size", tab.size)
		writeProperty(tab.drawings.text, "Position", tab.position + Vector2.new(12, 5))
		writeProperty(tab.drawings.background, "Visible", self.visible)
		writeProperty(tab.drawings.outline, "Visible", self.visible)
		writeProperty(tab.drawings.text, "Visible", self.visible)
	end

	if self:HasTabs() then
		return y + TAB_HEIGHT + CONTENT_GAP
	end

	return self.position.Y + HEADER_HEIGHT + CONTENT_GAP
end

function Window:UpdateTabVisuals(mousePosition)
	for _, tab in ipairs(self.tabs) do
		local hovered = self.visible and pointInRect(mousePosition, tab.position, tab.size)
		local active = self.activeTab == tab
		local backgroundColor = active and self.theme.TabActive or hovered and self.theme.TabHover or self.theme.Tab
		local outlineColor = active and self.theme.Accent or self.theme.Border
		local textColor = active and self.theme.Text or hovered and self.theme.Text or self.theme.SubText

		writeProperty(tab.drawings.background, "Color", backgroundColor)
		writeProperty(tab.drawings.outline, "Color", outlineColor)
		writeProperty(tab.drawings.text, "Color", textColor)
	end
end

function Window:UpdateLayout()
	self.size = Vector2.new(self.size.X, self:GetRequiredHeight())
	self:ClampToViewport()
	self:UpdateChrome()

	local y = self:LayoutTabs()
	local contentWidth = self.size.X - (PADDING * 2)

	for _, control in ipairs(self.controls) do
		if self:IsTabActive(control.tab) then
			control.position = Vector2.new(self.position.X + PADDING, y)
			control.size = Vector2.new(contentWidth, control.GetHeight and control:GetHeight() or control.height)

			if control.layout then
				control:layout()
			end

			if control.visible then
				y += (control.GetHeight and control:GetHeight() or control.height) + ROW_GAP
			end
		end
	end

	self:SyncAllControlVisibility()
	self:UpdateTabVisuals(getMousePosition())
end

function Window:RefreshZIndex()
	local z = self.zBase

	writeProperty(self.drawings.shadow, "ZIndex", z)
	writeProperty(self.drawings.frame, "ZIndex", z + 1)
	writeProperty(self.drawings.header, "ZIndex", z + 2)
	writeProperty(self.drawings.accent, "ZIndex", z + 3)
	writeProperty(self.drawings.title, "ZIndex", z + 4)
	writeProperty(self.drawings.subtitle, "ZIndex", z + 4)

	for _, tab in ipairs(self.tabs) do
		writeProperty(tab.drawings.background, "ZIndex", z + 5)
		writeProperty(tab.drawings.outline, "ZIndex", z + 6)
		writeProperty(tab.drawings.text, "ZIndex", z + 7)
	end

	local controlZ = z + 8

	for _, control in ipairs(self.controls) do
		if control.setZIndex then
			control:setZIndex(controlZ)
		end
	end
end

function Window:SetVisible(isVisible)
	self.visible = isVisible

	if not isVisible then
		if activeTextbox ~= nil and activeTextbox.window == self then
			clearTextboxFocus(true)
		end

		if listeningKeybind ~= nil and listeningKeybind.window == self then
			clearKeybindListening()
		end

		self:CloseDropdowns(nil)
	end

	for _, drawing in pairs(self.drawings) do
		writeProperty(drawing, "Visible", isVisible)
	end

	for _, tab in ipairs(self.tabs) do
		for _, drawing in pairs(tab.drawings) do
			writeProperty(drawing, "Visible", isVisible)
		end
	end

	self:SyncAllControlVisibility()
end

function Window:CloseDropdowns(exceptControl)
	for _, control in ipairs(self.controls) do
		if control.kind == "Dropdown" and control ~= exceptControl then
			control:SetOpen(false)
		end
	end
end

function Window:SetTitle(text)
	self.title = text
	writeProperty(self.drawings.title, "Text", text)
end

function Window:SetSubtitle(text)
	self.subtitle = text
	writeProperty(self.drawings.subtitle, "Text", text)
end

function Window:SetPosition(position)
	self.position = position
	self:UpdateLayout()
end

function Window:SetSize(size)
	self.minimumSize = size
	self.size = size
	self:UpdateLayout()
end

function Window:SetTheme(themeOverrides)
	local mergedTheme = {}

	for key, value in pairs(self.theme) do
		mergedTheme[key] = value
	end

	for key, value in pairs(themeOverrides or {}) do
		mergedTheme[key] = value
	end

	self.theme = mergeTheme(mergedTheme)
	writeProperty(self.drawings.frame, "Color", self.theme.WindowBackground)
	writeProperty(self.drawings.header, "Color", self.theme.HeaderBackground)
	writeProperty(self.drawings.accent, "Color", self.theme.Accent)
	writeProperty(self.drawings.title, "Color", self.theme.Text)
	writeProperty(self.drawings.subtitle, "Color", self.theme.Muted)

	for _, tab in ipairs(self.tabs) do
		writeProperty(tab.drawings.text, "Font", self.theme.Font)
		writeProperty(tab.drawings.text, "Size", self.theme.TextSize)
	end

	for _, control in ipairs(self.controls) do
		if control.applyTheme then
			control:applyTheme()
		end
	end

	self:UpdateLayout()
end

function Window:GetConfigId()
	return sanitizeFileName(self.configId or self.title)
end

function Window:GetConfigFolder()
	return (self.configRoot or "drawing-ui-lib-configs") .. "/" .. self:GetConfigId()
end

function Window:EnsureConfigFolder()
	if not hasFilesystem() then
		return false
	end

	local folder = self:GetConfigFolder()
	if not isfolder(folder) then
		makefolder(folder)
	end

	return true
end

function Window:BuildConfig()
	local data = {}

	for _, control in ipairs(self.controls) do
		if control.configKey ~= nil and control.GetConfigValue then
			data[control.configKey] = control:GetConfigValue()
		end
	end

	return data
end

function Window:ApplyConfig(config, fireCallbacks)
	for _, control in ipairs(self.controls) do
		if control.configKey ~= nil and control.ApplyConfigValue and config[control.configKey] ~= nil then
			control:ApplyConfigValue(config[control.configKey], fireCallbacks)
		end
	end
end

function Window:ListConfigs()
	if not self:EnsureConfigFolder() then
		return {}
	end

	local names = {}
	for _, path in ipairs(listfiles(self:GetConfigFolder())) do
		local name = path:match("([^\\/]+)%.json$")
		if name then
			table.insert(names, name)
		end
	end

	table.sort(names)
	return names
end

function Window:SaveConfig(name)
	if not self:EnsureConfigFolder() then
		return false, "filesystem unavailable"
	end

	local safeName = sanitizeFileName(name)
	local path = self:GetConfigFolder() .. "/" .. safeName .. ".json"
	writefile(path, HttpService:JSONEncode(self:BuildConfig()))
	return true, safeName
end

function Window:LoadConfig(name, fireCallbacks)
	if not self:EnsureConfigFolder() then
		return false, "filesystem unavailable"
	end

	local safeName = sanitizeFileName(name)
	local path = self:GetConfigFolder() .. "/" .. safeName .. ".json"

	if typeof(isfile) ~= "function" or not isfile(path) then
		return false, "missing file"
	end

	local decoded = HttpService:JSONDecode(readfile(path))
	self:ApplyConfig(decoded, fireCallbacks)
	return true, safeName
end

function Window:DeleteConfig(name)
	if not self:EnsureConfigFolder() then
		return false, "filesystem unavailable"
	end

	local safeName = sanitizeFileName(name)
	local path = self:GetConfigFolder() .. "/" .. safeName .. ".json"

	if typeof(delfile) ~= "function" then
		return false, "delete unavailable"
	end

	if typeof(isfile) == "function" and not isfile(path) then
		return false, "missing file"
	end

	delfile(path)
	return true, safeName
end

function Window:IsPointInHeader(point)
	return pointInRect(point, self.position, Vector2.new(self.size.X, HEADER_HEIGHT))
end

function Window:GetTabAt(point)
	for _, tab in ipairs(self.tabs) do
		if pointInRect(point, tab.position, tab.size) then
			return tab
		end
	end

	return nil
end

function Window:GetControlAt(point)
	for index = #self.controls, 1, -1 do
		local control = self.controls[index]

		if self:IsControlDisplayed(control) and control.hitTest and control:hitTest(point) then
			return control
		end
	end

	return nil
end

function Window:SetActiveTab(nameOrTab)
	if typeof(nameOrTab) == "table" then
		self.activeTab = nameOrTab
	else
		for _, tab in ipairs(self.tabs) do
			if tab.name == nameOrTab then
				self.activeTab = tab
				break
			end
		end
	end

	clearTextboxFocus(true)
	clearKeybindListening()
	self:CloseDropdowns(nil)
	self:UpdateLayout()
end

function Window:HandleMouseDown(point)
	if self.dragAnywhere or self:IsPointInHeader(point) then
		self.pendingDrag = true
		self.dragOffset = point - self.position
	end

	if self:IsPointInHeader(point) then
		self.dragging = true
		self.dragOffset = point - self.position
		return
	end

	local tab = self:GetTabAt(point)

	if tab ~= nil then
		self:SetActiveTab(tab)
		return
	end

	local control = self:GetControlAt(point)

	if control ~= nil and control.onMouseDown then
		if control.blocksWindowDrag then
			self.pendingDrag = false
		end

		if control.kind ~= "Textbox" then
			clearTextboxFocus(true)
		end

		if control.kind ~= "Keybind" then
			clearKeybindListening()
		end

		if control.kind ~= "Dropdown" then
			self:CloseDropdowns(nil)
		end

		control:onMouseDown(point)
	else
		clearTextboxFocus(true)
		clearKeybindListening()
		self:CloseDropdowns(nil)
	end
end

function Window:HandleMouseUp(point)
	self.dragging = false
	self.pendingDrag = false

	for _, control in ipairs(self.controls) do
		if control.onMouseUp then
			control:onMouseUp(point)
		end
	end
end

function Window:Step(mousePosition)
	if not self.visible then
		return
	end

	if self.dragging then
		self.position = mousePosition - self.dragOffset
		self:ClampToViewport()
		self:UpdateLayout()
	elseif self.pendingDrag and (mousePosition - (self.position + self.dragOffset)).Magnitude > 4 then
		self.dragging = true
	end

	self:UpdateTabVisuals(mousePosition)

	local topWindow = topWindowAt(mousePosition)
	local ownsHover = topWindow == self
	local needsLayout = false

	for _, control in ipairs(self.controls) do
		if self:IsControlDisplayed(control) and control.onStep then
			needsLayout = control:onStep(mousePosition, ownsHover) or needsLayout
		end
	end

	if needsLayout then
		self:UpdateLayout()
	end
end

function Window:Destroy()
	for _, control in ipairs(self.controls) do
		if control.destroy then
			control:destroy()
		end
	end

	for _, tab in ipairs(self.tabs) do
		for _, drawing in pairs(tab.drawings) do
			destroyDrawing(drawing)
		end
	end

	for _, drawing in pairs(self.drawings) do
		destroyDrawing(drawing)
	end

	for index, candidate in ipairs(windows) do
		if candidate == self then
			table.remove(windows, index)
			break
		end
	end

	self.controls = {}
	self.tabs = {}

	disconnectLoopIfEmpty()
end

local function addLabel(window, tab, text)
	local control = makeBaseControl(window, tab, "Label", ROW_HEIGHT)
	control.text = text

	control.drawings.text = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = 13,
		Font = FONT,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	function control:layout()
		writeProperty(self.drawings.text, "Position", self.position + Vector2.new(0, 3))
	end

	function control:applyTheme()
		writeProperty(self.drawings.text, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.text, "Font", self.window.theme.Font)
		writeProperty(self.drawings.text, "Size", self.window.theme.TextSize)
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.text, "ZIndex", z)
	end

	function control:SetText(nextText)
		self.text = nextText
		writeProperty(self.drawings.text, "Text", nextText)
	end

	function control:destroy()
		destroyDrawing(self.drawings.text)
	end

	control:applyTheme()
	return addControl(window, tab, control)
end

local function addParagraph(window, tab, title, text)
	local control = makeBaseControl(window, tab, "Paragraph", ROW_HEIGHT * 2)
	control.title = title
	control.text = text
	control.lineCount = 1

	control.drawings.title = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = window.theme.TextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = title,
		Position = Vector2.zero,
	})

	control.drawings.body = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	function control:GetHeight()
		return 22 + (self.lineCount * 14)
	end

	function control:layout()
		local wrapped, lines = wrapText(self.text, math.max(18, math.floor(self.size.X / 7)))
		self.lineCount = lines
		writeProperty(self.drawings.title, "Position", self.position)
		writeProperty(self.drawings.body, "Position", self.position + Vector2.new(0, 16))
		writeProperty(self.drawings.body, "Text", wrapped)
	end

	function control:applyTheme()
		writeProperty(self.drawings.title, "Color", self.window.theme.Text)
		writeProperty(self.drawings.body, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.title, "Font", self.window.theme.Font)
		writeProperty(self.drawings.body, "Font", self.window.theme.Font)
		writeProperty(self.drawings.title, "Size", self.window.theme.TextSize)
		writeProperty(self.drawings.body, "Size", self.window.theme.SmallTextSize)
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.title, "ZIndex", z)
		writeProperty(self.drawings.body, "ZIndex", z)
	end

	function control:SetText(nextText)
		self.text = nextText
		self.window:UpdateLayout()
	end

	function control:destroy()
		destroyDrawing(self.drawings.title)
		destroyDrawing(self.drawings.body)
	end

	control:applyTheme()
	return addControl(window, tab, control)
end

local function addSection(window, tab, text)
	local control = makeBaseControl(window, tab, "Section", SECTION_HEIGHT)
	control.text = text

	control.drawings.text = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = 14,
		Font = FONT,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	control.drawings.line = createDrawing("Line", {
		Visible = window.visible,
		Color = window.theme.SectionLine,
		Thickness = 1,
		From = Vector2.zero,
		To = Vector2.zero,
	})

	function control:layout()
		local textWidth = (#self.text * 7) + 12
		local lineStartX = math.min(self.position.X + textWidth, self.position.X + self.size.X)
		local lineY = self.position.Y + 10

		writeProperty(self.drawings.text, "Position", self.position)
		writeProperty(self.drawings.line, "From", Vector2.new(lineStartX, lineY))
		writeProperty(self.drawings.line, "To", Vector2.new(self.position.X + self.size.X, lineY))
	end

	function control:applyTheme()
		writeProperty(self.drawings.text, "Color", self.window.theme.Text)
		writeProperty(self.drawings.line, "Color", self.window.theme.SectionLine)
		writeProperty(self.drawings.text, "Font", self.window.theme.Font)
		writeProperty(self.drawings.text, "Size", self.window.theme.TextSize + 1)
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.text, "ZIndex", z)
		writeProperty(self.drawings.line, "ZIndex", z)
	end

	function control:destroy()
		destroyDrawing(self.drawings.text)
		destroyDrawing(self.drawings.line)
	end

	control:applyTheme()
	return addControl(window, tab, control)
end

local function addSubTab(window, tab, text, expanded)
	local group = makeBaseControl(window, tab, "SubTab", SECTION_HEIGHT + 2)
	group.text = text
	group.expanded = expanded ~= false
	group.children = {}
	group.configKey = nil

	group.drawings.text = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = window.theme.TextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	group.drawings.arrow = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = expanded ~= false and "v" or ">",
		Position = Vector2.zero,
	})

	group.drawings.line = createDrawing("Line", {
		Visible = window.visible,
		Color = window.theme.SectionLine,
		Thickness = 1,
		From = Vector2.zero,
		To = Vector2.zero,
	})

	function group:applyTheme()
		writeProperty(self.drawings.text, "Color", self.window.theme.Text)
		writeProperty(self.drawings.arrow, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.line, "Color", self.window.theme.SectionLine)
		writeProperty(self.drawings.text, "Font", self.window.theme.Font)
		writeProperty(self.drawings.arrow, "Font", self.window.theme.Font)
		writeProperty(self.drawings.text, "Size", self.window.theme.TextSize)
		writeProperty(self.drawings.arrow, "Size", self.window.theme.SmallTextSize)
	end

	function group:layout()
		local lineY = self.position.Y + 11
		writeProperty(self.drawings.arrow, "Position", self.position)
		writeProperty(self.drawings.text, "Position", self.position + Vector2.new(14, 0))
		writeProperty(self.drawings.arrow, "Text", self.expanded and "v" or ">")
		writeProperty(self.drawings.line, "From", Vector2.new(self.position.X + 92, lineY))
		writeProperty(self.drawings.line, "To", Vector2.new(self.position.X + self.size.X, lineY))
	end

	function group:hitTest(point)
		return pointInRect(point, self.position, self.size)
	end

	function group:onMouseDown(point)
		if self:hitTest(point) then
			self.pressing = true
		end
	end

	function group:onMouseUp(point)
		if self.pressing and self:hitTest(point) then
			self.expanded = not self.expanded
			self.window:UpdateLayout()
		end
		self.pressing = false
	end

	function group:setZIndex(z)
		writeProperty(self.drawings.text, "ZIndex", z)
		writeProperty(self.drawings.arrow, "ZIndex", z)
		writeProperty(self.drawings.line, "ZIndex", z)
	end

	function group:destroy()
		destroyDrawing(self.drawings.text)
		destroyDrawing(self.drawings.arrow)
		destroyDrawing(self.drawings.line)
	end

	function group:addChild(control)
		control.parentGroup = self
		table.insert(self.children, control)
		return control
	end

	function group:AddSection(label)
		return self:addChild(addSection(self.window, self.tab, label))
	end

	function group:AddLabel(label)
		return self:addChild(addLabel(self.window, self.tab, label))
	end

	function group:AddParagraph(titleText, bodyText)
		return self:addChild(addParagraph(self.window, self.tab, titleText, bodyText))
	end

	function group:AddButton(label, callback)
		return self:addChild(addButton(self.window, self.tab, label, callback))
	end

	function group:AddButtonRow(buttons)
		return self:addChild(addButtonRow(self.window, self.tab, buttons))
	end

	function group:AddToggle(label, initialValue, callback)
		return self:addChild(addToggle(self.window, self.tab, label, initialValue, callback))
	end

	function group:AddSlider(label, minimum, maximum, initialValue, callback)
		return self:addChild(addSlider(self.window, self.tab, label, minimum, maximum, initialValue, callback))
	end

	function group:AddDropdown(label, options, defaultValue, callback)
		return self:addChild(addDropdown(self.window, self.tab, label, options, defaultValue, callback))
	end

	function group:AddSearchDropdown(label, options, defaultValue, callback)
		return self:addChild(addSearchDropdown(self.window, self.tab, label, options, defaultValue, callback))
	end

	function group:AddMultiDropdown(label, options, defaultValues, callback)
		return self:addChild(addMultiDropdown(self.window, self.tab, label, options, defaultValues, callback))
	end

	function group:AddColorPicker(label, defaultColor, callback)
		return self:addChild(addColorPicker(self.window, self.tab, label, defaultColor, callback))
	end

	function group:AddTextbox(label, placeholder, callback)
		return self:addChild(addTextbox(self.window, self.tab, label, placeholder, callback))
	end

	function group:AddKeybind(label, defaultKey, callback, changedCallback)
		return self:addChild(addKeybind(self.window, self.tab, label, defaultKey, callback, changedCallback))
	end

	group:applyTheme()
	return addControl(window, tab, group)
end

local function addButton(window, tab, text, callback)
	local control = makeBaseControl(window, tab, "Button", BUTTON_HEIGHT)
	control.text = text
	control.callback = callback or function() end
	control.blocksWindowDrag = true
	control.activationBinding = nil

	control.drawings.frame = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.Button,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.outline = createDrawing("Square", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Border,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.text = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = 13,
		Font = FONT,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	function control:layout()
		writeProperty(self.drawings.frame, "Position", self.position)
		writeProperty(self.drawings.frame, "Size", self.size)
		writeProperty(self.drawings.outline, "Position", self.position)
		writeProperty(self.drawings.outline, "Size", self.size)
		writeProperty(self.drawings.text, "Position", self.position + Vector2.new(12, 6))
	end

	function control:applyTheme()
		writeProperty(self.drawings.text, "Color", self.window.theme.Text)
		writeProperty(self.drawings.outline, "Color", self.window.theme.Border)
		writeProperty(self.drawings.text, "Font", self.window.theme.Font)
		writeProperty(self.drawings.text, "Size", self.window.theme.TextSize)
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.frame, "ZIndex", z)
		writeProperty(self.drawings.outline, "ZIndex", z + 1)
		writeProperty(self.drawings.text, "ZIndex", z + 2)
	end

	function control:hitTest(point)
		return pointInRect(point, self.position, self.size)
	end

	function control:onMouseDown(point)
		if self:hitTest(point) then
			self.pressing = true
		end
	end

	function control:onMouseUp(point)
		local shouldFire = self.pressing and self:hitTest(point)
		self.pressing = false

		if shouldFire then
			self.callback()
		end
	end

	function control:TriggerActivation()
		self.callback()
	end

	function control:onStep(mousePosition, ownsHover)
		self.hovered = ownsHover and self:hitTest(mousePosition)
		writeProperty(self.drawings.frame, "Color", self.hovered and self.window.theme.ButtonHover or self.window.theme.Button)
	end

	function control:SetText(nextText)
		self.text = nextText
		writeProperty(self.drawings.text, "Text", nextText)
	end

	function control:SetActivationBinding(binding)
		self.activationBinding = binding
	end

	function control:destroy()
		destroyDrawing(self.drawings.frame)
		destroyDrawing(self.drawings.outline)
		destroyDrawing(self.drawings.text)
	end

	control:applyTheme()
	return addControl(window, tab, control)
end

local function addButtonRow(window, tab, buttons)
	local control = makeBaseControl(window, tab, "ButtonRow", BUTTON_HEIGHT)
	control.buttons = buttons or {}
	control.drawings = {}
	control.hitIndex = nil

	for index, definition in ipairs(control.buttons) do
		control.drawings[index] = {
			frame = createDrawing("Square", {
				Visible = window.visible,
				Filled = true,
				Color = window.theme.Button,
				Thickness = 1,
				Size = Vector2.zero,
				Position = Vector2.zero,
			}),
			outline = createDrawing("Square", {
				Visible = window.visible,
				Filled = false,
				Color = window.theme.Border,
				Thickness = 1,
				Size = Vector2.zero,
				Position = Vector2.zero,
			}),
			text = createDrawing("Text", {
				Visible = window.visible,
				Color = window.theme.Text,
				Size = window.theme.TextSize,
				Font = window.theme.Font,
				Outline = true,
				Text = definition.text or ("Button " .. index),
				Position = Vector2.zero,
			}),
		}
	end

	function control:applyTheme()
		for _, drawingSet in ipairs(self.drawings) do
			writeProperty(drawingSet.outline, "Color", self.window.theme.Border)
			writeProperty(drawingSet.text, "Color", self.window.theme.Text)
			writeProperty(drawingSet.text, "Font", self.window.theme.Font)
			writeProperty(drawingSet.text, "Size", self.window.theme.TextSize)
		end
	end

	function control:getButtonRect(index)
		local count = math.max(1, #self.buttons)
		local gap = 8
		local width = math.floor((self.size.X - ((count - 1) * gap)) / count)
		local x = self.position.X + ((index - 1) * (width + gap))
		return Vector2.new(x, self.position.Y), Vector2.new(width, self.size.Y)
	end

	function control:layout()
		for index, definition in ipairs(self.buttons) do
			local buttonPosition, buttonSize = self:getButtonRect(index)
			local drawingSet = self.drawings[index]

			writeProperty(drawingSet.frame, "Position", buttonPosition)
			writeProperty(drawingSet.frame, "Size", buttonSize)
			writeProperty(drawingSet.outline, "Position", buttonPosition)
			writeProperty(drawingSet.outline, "Size", buttonSize)
			writeProperty(drawingSet.text, "Position", buttonPosition + Vector2.new(12, 6))
			writeProperty(drawingSet.text, "Text", definition.text or ("Button " .. index))
		end
	end

	function control:refreshVisibility(shouldShow)
		for _, drawingSet in ipairs(self.drawings) do
			writeProperty(drawingSet.frame, "Visible", shouldShow)
			writeProperty(drawingSet.outline, "Visible", shouldShow)
			writeProperty(drawingSet.text, "Visible", shouldShow)
		end
	end

	function control:hitTest(point)
		for index = 1, #self.buttons do
			local buttonPosition, buttonSize = self:getButtonRect(index)
			if pointInRect(point, buttonPosition, buttonSize) then
				self.hitIndex = index
				return true
			end
		end

		self.hitIndex = nil
		return false
	end

	function control:onMouseDown(point)
		self:hitTest(point)
		self.pressing = self.hitIndex ~= nil
	end

	function control:onMouseUp(point)
		if not self.pressing then
			return
		end

		self.pressing = false

		if not self:hitTest(point) or self.hitIndex == nil then
			return
		end

		local definition = self.buttons[self.hitIndex]
		if definition and definition.callback then
			definition.callback()
		end
	end

	function control:onStep(mousePosition, ownsHover)
		for index, drawingSet in ipairs(self.drawings) do
			local buttonPosition, buttonSize = self:getButtonRect(index)
			local hovered = ownsHover and pointInRect(mousePosition, buttonPosition, buttonSize)
			writeProperty(drawingSet.frame, "Color", hovered and self.window.theme.ButtonHover or self.window.theme.Button)
		end
	end

	function control:setZIndex(z)
		for index, drawingSet in ipairs(self.drawings) do
			writeProperty(drawingSet.frame, "ZIndex", z + index)
			writeProperty(drawingSet.outline, "ZIndex", z + index + 1)
			writeProperty(drawingSet.text, "ZIndex", z + index + 2)
		end
	end

	function control:destroy()
		for _, drawingSet in ipairs(self.drawings) do
			destroyDrawing(drawingSet.frame)
			destroyDrawing(drawingSet.outline)
			destroyDrawing(drawingSet.text)
		end
	end

	control:applyTheme()
	return addControl(window, tab, control)
end

local function addToggle(window, tab, text, initialValue, callback)
	local control = makeBaseControl(window, tab, "Toggle", TOGGLE_HEIGHT)
	control.text = text
	control.configKey = text
	control.value = initialValue == true
	control.callback = callback or function() end
	control.toggleAlpha = control.value and 1 or 0
	control.blocksWindowDrag = true
	control.activationBinding = nil

	control.drawings.text = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = 13,
		Font = FONT,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	control.drawings.state = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = 12,
		Font = FONT,
		Outline = true,
		Text = "OFF",
		Position = Vector2.zero,
	})

	control.drawings.trackLeft = createDrawing("Circle", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.Toggle,
		Thickness = 1,
		NumSides = 20,
		Radius = 8,
		Position = Vector2.zero,
	})

	control.drawings.trackRight = createDrawing("Circle", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.Toggle,
		Thickness = 1,
		NumSides = 20,
		Radius = 8,
		Position = Vector2.zero,
	})

	control.drawings.trackCenter = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.Toggle,
		Thickness = 1,
		Size = Vector2.new(18, 16),
		Position = Vector2.zero,
	})

	control.drawings.knob = createDrawing("Circle", {
		Visible = window.visible,
		Filled = true,
		Color = Color3.fromRGB(245, 247, 250),
		Thickness = 1,
		NumSides = 20,
		Radius = 6,
		Position = Vector2.zero,
	})

	function control:applyValue()
		local activeColor = colorLerp(self.window.theme.Toggle, self.window.theme.ToggleEnabled, self.toggleAlpha)

		writeProperty(self.drawings.trackLeft, "Color", activeColor)
		writeProperty(self.drawings.trackRight, "Color", activeColor)
		writeProperty(self.drawings.trackCenter, "Color", activeColor)
		writeProperty(self.drawings.state, "Text", self.value and "ON" or "OFF")
		writeProperty(self.drawings.state, "Color", colorLerp(self.window.theme.SubText, self.window.theme.Accent, self.toggleAlpha))
	end

	function control:refreshVisibility(shouldShow)
		for _, drawing in pairs(self.drawings) do
			writeProperty(drawing, "Visible", shouldShow)
		end
	end

	function control:layout()
		local switchWidth = 34
		local switchPosition = self.position + Vector2.new(self.size.X - switchWidth, 4)
		local knobX = lerp(switchPosition.X + 8, switchPosition.X + 26, self.toggleAlpha)

		writeProperty(self.drawings.text, "Position", self.position + Vector2.new(0, 3))
		writeProperty(self.drawings.state, "Position", self.position + Vector2.new(self.size.X - 72, 4))
		writeProperty(self.drawings.trackLeft, "Position", switchPosition + Vector2.new(8, 8))
		writeProperty(self.drawings.trackRight, "Position", switchPosition + Vector2.new(switchWidth - 8, 8))
		writeProperty(self.drawings.trackCenter, "Position", switchPosition + Vector2.new(8, 0))
		writeProperty(self.drawings.trackCenter, "Size", Vector2.new(switchWidth - 16, 16))
		writeProperty(self.drawings.knob, "Position", Vector2.new(knobX, switchPosition.Y + 8))

		self:applyValue()
	end

	function control:applyTheme()
		writeProperty(self.drawings.text, "Color", self.window.theme.Text)
		writeProperty(self.drawings.text, "Font", self.window.theme.Font)
		writeProperty(self.drawings.state, "Font", self.window.theme.Font)
		writeProperty(self.drawings.text, "Size", self.window.theme.TextSize)
		writeProperty(self.drawings.state, "Size", self.window.theme.SmallTextSize)
		self:applyValue()
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.text, "ZIndex", z)
		writeProperty(self.drawings.state, "ZIndex", z)
		writeProperty(self.drawings.trackLeft, "ZIndex", z + 1)
		writeProperty(self.drawings.trackRight, "ZIndex", z + 1)
		writeProperty(self.drawings.trackCenter, "ZIndex", z + 1)
		writeProperty(self.drawings.knob, "ZIndex", z + 2)
	end

	function control:hitTest(point)
		return pointInRect(point, self.position, self.size)
	end

	function control:onMouseDown(point)
		if self:hitTest(point) then
			self.pressing = true
		end
	end

	function control:onMouseUp(point)
		if not self.pressing then
			return
		end

		self.pressing = false

		if not self:hitTest(point) then
			return
		end

		self.value = not self.value
		self:layout()
		self.callback(self.value)
	end

	function control:TriggerActivation()
		self.value = not self.value
		self:layout()
		self.callback(self.value)
	end

	function control:onStep(mousePosition, ownsHover)
		self.hovered = ownsHover and self:hitTest(mousePosition)
		writeProperty(self.drawings.knob, "Color", self.hovered and self.window.theme.Text or Color3.fromRGB(245, 247, 250))
		local target = self.value and 1 or 0
		local nextAlpha = lerp(self.toggleAlpha, target, 0.25)

		if math.abs(nextAlpha - self.toggleAlpha) > 0.001 then
			self.toggleAlpha = nextAlpha
			self:layout()
		else
			self.toggleAlpha = target
		end
	end

	function control:SetValue(nextValue)
		self.value = nextValue == true
		self:layout()
	end

	function control:GetConfigValue()
		return self.value
	end

	function control:ApplyConfigValue(nextValue, fireCallback)
		self:SetValue(nextValue == true)
		if fireCallback ~= false then
			self.callback(self.value)
		end
	end

	function control:SetActivationBinding(binding)
		self.activationBinding = binding
	end

	function control:destroy()
		for _, drawing in pairs(self.drawings) do
			destroyDrawing(drawing)
		end
	end

	control:applyTheme()
	return addControl(window, tab, control)
end

local function addSlider(window, tab, text, minimum, maximum, initialValue, callback)
	local control = makeBaseControl(window, tab, "Slider", SLIDER_HEIGHT)
	control.text = text
	control.configKey = text
	control.minimum = minimum
	control.maximum = maximum
	control.value = clamp(initialValue or minimum, minimum, maximum)
	control.displayValue = control.value
	control.callback = callback or function() end
	control.dragging = false
	control.blocksWindowDrag = true

	control.drawings.label = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = 13,
		Font = FONT,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	control.drawings.value = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = 12,
		Font = FONT,
		Outline = true,
		Text = tostring(control.value),
		Position = Vector2.zero,
	})

	control.drawings.track = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.SliderTrack,
		Thickness = 1,
		Size = Vector2.new(100, 6),
		Position = Vector2.zero,
	})

	control.drawings.fill = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.SliderFill,
		Thickness = 1,
		Size = Vector2.new(0, 6),
		Position = Vector2.zero,
	})

	control.drawings.knob = createDrawing("Circle", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.Text,
		Thickness = 1,
		NumSides = 18,
		Radius = 5,
		Position = Vector2.zero,
	})

	function control:getAlpha()
		local span = self.maximum - self.minimum

		if span == 0 then
			return 0
		end

		return (self.value - self.minimum) / span
	end

	function control:getDisplayAlpha()
		local span = self.maximum - self.minimum

		if span == 0 then
			return 0
		end

		return (self.displayValue - self.minimum) / span
	end

	function control:updateVisuals()
		local barPosition = self.position + Vector2.new(0, 24)
		local barWidth = self.size.X
		local alpha = self:getDisplayAlpha()
		local fillWidth = clamp(round(barWidth * alpha), 0, barWidth)

		writeProperty(self.drawings.track, "Position", barPosition)
		writeProperty(self.drawings.track, "Size", Vector2.new(barWidth, 6))
		writeProperty(self.drawings.fill, "Position", barPosition)
		writeProperty(self.drawings.fill, "Size", Vector2.new(fillWidth, 6))
		writeProperty(self.drawings.knob, "Position", barPosition + Vector2.new(fillWidth, 3))
		writeProperty(self.drawings.value, "Text", string.format("%.2f", self.value))
	end

	function control:setFromMouse(mousePosition)
		local alpha = clamp((mousePosition.X - self.position.X) / self.size.X, 0, 1)
		local nextValue = lerp(self.minimum, self.maximum, alpha)

		if math.abs(nextValue - self.value) < 0.001 then
			return
		end

		self.value = nextValue
		self:updateVisuals()
		self.callback(self.value)
	end

	function control:layout()
		writeProperty(self.drawings.label, "Position", self.position)
		writeProperty(self.drawings.value, "Position", self.position + Vector2.new(self.size.X - 56, 1))
		self:updateVisuals()
	end

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.window.theme.Text)
		writeProperty(self.drawings.value, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.track, "Color", self.window.theme.SliderTrack)
		writeProperty(self.drawings.fill, "Color", self.window.theme.SliderFill)
		writeProperty(self.drawings.label, "Font", self.window.theme.Font)
		writeProperty(self.drawings.value, "Font", self.window.theme.Font)
		writeProperty(self.drawings.label, "Size", self.window.theme.TextSize)
		writeProperty(self.drawings.value, "Size", self.window.theme.SmallTextSize)
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.label, "ZIndex", z)
		writeProperty(self.drawings.value, "ZIndex", z)
		writeProperty(self.drawings.track, "ZIndex", z)
		writeProperty(self.drawings.fill, "ZIndex", z + 1)
		writeProperty(self.drawings.knob, "ZIndex", z + 2)
	end

	function control:hitTest(point)
		return pointInRect(point, self.position, self.size)
	end

	function control:onMouseDown(point)
		if self:hitTest(point) then
			self.dragging = true
			self:setFromMouse(point)
		end
	end

	function control:onMouseUp()
		self.dragging = false
	end

	function control:onStep(mousePosition, ownsHover)
		if self.dragging then
			self:setFromMouse(mousePosition)
		end

		self.displayValue = lerp(self.displayValue, self.value, self.dragging and 0.45 or 0.25)

		if math.abs(self.displayValue - self.value) < 0.001 then
			self.displayValue = self.value
		end

		self:updateVisuals()

		local hovered = ownsHover and self:hitTest(mousePosition)
		writeProperty(self.drawings.knob, "Color", (hovered or self.dragging) and self.window.theme.Accent or self.window.theme.Text)
	end

	function control:SetValue(nextValue)
		self.value = clamp(nextValue, self.minimum, self.maximum)
		self.displayValue = self.value
		self:updateVisuals()
	end

	function control:GetConfigValue()
		return self.value
	end

	function control:ApplyConfigValue(nextValue, fireCallback)
		self:SetValue(nextValue)
		if fireCallback ~= false then
			self.callback(self.value)
		end
	end

	function control:destroy()
		for _, drawing in pairs(self.drawings) do
			destroyDrawing(drawing)
		end
	end

	control:applyTheme()
	return addControl(window, tab, control)
end

local function addDropdown(window, tab, text, options, defaultValue, callback)
	local control = makeBaseControl(window, tab, "Dropdown", LABELED_INPUT_HEIGHT)
	control.text = text
	control.configKey = text
	control.options = table.clone(options or {})
	control.value = defaultValue or control.options[1] or "Select"
	control.callback = callback or function() end
	control.open = false
	control.openAlpha = 0
	control.hoverIndex = nil
	control.blocksWindowDrag = true

	control.drawings.label = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = window.theme.TextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	control.drawings.frame = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.Input,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.outline = createDrawing("Square", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Border,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.value = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = tostring(control.value),
		Position = Vector2.zero,
	})

	control.drawings.arrow = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = "v",
		Position = Vector2.zero,
	})

	control.optionDrawings = {}

	for _, option in ipairs(control.options) do
		table.insert(control.optionDrawings, {
			frame = createDrawing("Square", {
				Visible = false,
				Filled = true,
				Color = window.theme.Input,
				Thickness = 1,
				Size = Vector2.zero,
				Position = Vector2.zero,
			}),
			outline = createDrawing("Square", {
				Visible = false,
				Filled = false,
				Color = window.theme.Border,
				Thickness = 1,
				Size = Vector2.zero,
				Position = Vector2.zero,
			}),
			text = createDrawing("Text", {
				Visible = false,
				Color = window.theme.Text,
				Size = window.theme.SmallTextSize,
				Font = window.theme.Font,
				Outline = true,
				Text = tostring(option),
				Position = Vector2.zero,
			}),
		})
	end

	function control:GetHeight()
		return LABELED_INPUT_HEIGHT + round((#self.options * DROPDOWN_OPTION_HEIGHT) * self.openAlpha)
	end

	function control:SetOpen(isOpen)
		self.open = isOpen and #self.options > 0

		if self.open then
			self.window:CloseDropdowns(self)
		end
	end

	function control:SetValue(nextValue)
		self.value = nextValue
		writeProperty(self.drawings.value, "Text", tostring(nextValue))
	end

	function control:GetConfigValue()
		return self.value
	end

	function control:ApplyConfigValue(nextValue, fireCallback)
		self:SetValue(nextValue)
		if fireCallback ~= false then
			self.callback(self.value)
		end
	end

	function control:SetSearchText(nextText)
		self.searchText = tostring(nextText or "")
		self:updateFilter()
		self.window:UpdateLayout()
	end

	function control:SetOptions(nextOptions, nextValue)
		self.options = table.clone(nextOptions or {})
		self.searchText = ""
		self:rebuildOptions()
		self:updateFilter()
		self:SetValue(nextValue or self.options[1] or "Select")
		self.window:RefreshZIndex()
		self.window:UpdateLayout()
	end

	function control:SetOptions(nextOptions, nextValue)
		for _, drawingSet in ipairs(self.optionDrawings) do
			destroyDrawing(drawingSet.frame)
			destroyDrawing(drawingSet.outline)
			destroyDrawing(drawingSet.text)
		end

		self.options = table.clone(nextOptions or {})
		self.optionDrawings = {}

		for _, option in ipairs(self.options) do
			table.insert(self.optionDrawings, {
				frame = createDrawing("Square", {
					Visible = false,
					Filled = true,
					Color = self.window.theme.Input,
					Thickness = 1,
					Size = Vector2.zero,
					Position = Vector2.zero,
				}),
				outline = createDrawing("Square", {
					Visible = false,
					Filled = false,
					Color = self.window.theme.Border,
					Thickness = 1,
					Size = Vector2.zero,
					Position = Vector2.zero,
				}),
				text = createDrawing("Text", {
					Visible = false,
					Color = self.window.theme.Text,
					Size = self.window.theme.SmallTextSize,
					Font = self.window.theme.Font,
					Outline = true,
					Text = tostring(option),
					Position = Vector2.zero,
				}),
			})
		end

		self:SetValue(nextValue or self.options[1] or "Select")
		self.window:RefreshZIndex()
	end

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.window.theme.Text)
		writeProperty(self.drawings.value, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.arrow, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.outline, "Color", self.window.theme.Border)
		writeProperty(self.drawings.label, "Font", self.window.theme.Font)
		writeProperty(self.drawings.value, "Font", self.window.theme.Font)
		writeProperty(self.drawings.arrow, "Font", self.window.theme.Font)
		writeProperty(self.drawings.label, "Size", self.window.theme.TextSize)
		writeProperty(self.drawings.value, "Size", self.window.theme.SmallTextSize)
		writeProperty(self.drawings.arrow, "Size", self.window.theme.SmallTextSize)

		for _, drawingSet in ipairs(self.optionDrawings) do
			writeProperty(drawingSet.outline, "Color", self.window.theme.Border)
			writeProperty(drawingSet.text, "Color", self.window.theme.Text)
			writeProperty(drawingSet.text, "Font", self.window.theme.Font)
			writeProperty(drawingSet.text, "Size", self.window.theme.SmallTextSize)
		end
	end

	function control:layout()
		local basePosition = self.position + Vector2.new(0, 16)
		local baseSize = Vector2.new(self.size.X, INPUT_HEIGHT)
		local visibleCount = round(#self.options * self.openAlpha)

		writeProperty(self.drawings.label, "Position", self.position)
		writeProperty(self.drawings.frame, "Position", basePosition)
		writeProperty(self.drawings.frame, "Size", baseSize)
		writeProperty(self.drawings.outline, "Position", basePosition)
		writeProperty(self.drawings.outline, "Size", baseSize)
		writeProperty(self.drawings.value, "Position", basePosition + Vector2.new(10, 6))
		writeProperty(self.drawings.arrow, "Position", basePosition + Vector2.new(baseSize.X - 16, 6))
		writeProperty(self.drawings.arrow, "Text", self.openAlpha > 0.5 and "^" or "v")

		for index, option in ipairs(self.options) do
			local drawingSet = self.optionDrawings[index]
			local rowPosition = basePosition + Vector2.new(0, INPUT_HEIGHT + ((index - 1) * DROPDOWN_OPTION_HEIGHT))
			local isVisible = self.window:IsControlDisplayed(self) and index <= visibleCount and self.openAlpha > 0.02

			writeProperty(drawingSet.frame, "Position", rowPosition)
			writeProperty(drawingSet.frame, "Size", Vector2.new(self.size.X, DROPDOWN_OPTION_HEIGHT))
			writeProperty(drawingSet.outline, "Position", rowPosition)
			writeProperty(drawingSet.outline, "Size", Vector2.new(self.size.X, DROPDOWN_OPTION_HEIGHT))
			writeProperty(drawingSet.text, "Position", rowPosition + Vector2.new(10, 5))
			writeProperty(drawingSet.text, "Text", tostring(option))
			writeProperty(drawingSet.frame, "Visible", isVisible)
			writeProperty(drawingSet.outline, "Visible", isVisible)
			writeProperty(drawingSet.text, "Visible", isVisible)
		end
	end

	function control:refreshVisibility(shouldShow)
		for key, drawing in pairs(self.drawings) do
			writeProperty(drawing, "Visible", shouldShow)
		end

		for index, drawingSet in ipairs(self.optionDrawings) do
			local rowVisible = shouldShow and self.openAlpha > 0.02 and (index <= round(#self.options * self.openAlpha))
			writeProperty(drawingSet.frame, "Visible", rowVisible)
			writeProperty(drawingSet.outline, "Visible", rowVisible)
			writeProperty(drawingSet.text, "Visible", rowVisible)
		end
	end

	function control:getBaseRect()
		local basePosition = self.position + Vector2.new(0, 16)
		return basePosition, Vector2.new(self.size.X, INPUT_HEIGHT)
	end

	function control:getOptionIndex(point)
		local basePosition = self.position + Vector2.new(0, 16 + INPUT_HEIGHT)

		for index = 1, #self.options do
			local rowPosition = basePosition + Vector2.new(0, (index - 1) * DROPDOWN_OPTION_HEIGHT)

			if pointInRect(point, rowPosition, Vector2.new(self.size.X, DROPDOWN_OPTION_HEIGHT)) then
				return index
			end
		end

		return nil
	end

	function control:hitTest(point)
		local basePosition, baseSize = self:getBaseRect()

		if pointInRect(point, basePosition, baseSize) then
			return true
		end

		return self.openAlpha > 0.02 and self:getOptionIndex(point) ~= nil
	end

	function control:onMouseDown(point)
		local basePosition, baseSize = self:getBaseRect()

		if pointInRect(point, basePosition, baseSize) then
			self:SetOpen(not self.open)
			return
		end

		local optionIndex = self:getOptionIndex(point)

		if optionIndex ~= nil then
			self:SetValue(self.options[optionIndex])
			self:SetOpen(false)
			self.callback(self.value)
		end
	end

	function control:onStep(mousePosition, ownsHover)
		local basePosition, baseSize = self:getBaseRect()
		local targetAlpha = self.open and 1 or 0
		local nextAlpha = lerp(self.openAlpha, targetAlpha, 0.25)
		local needsLayout = false

		if math.abs(nextAlpha - self.openAlpha) > 0.001 then
			self.openAlpha = nextAlpha
			needsLayout = true
		else
			self.openAlpha = targetAlpha
		end

		self.hovered = ownsHover and pointInRect(mousePosition, basePosition, baseSize)
		writeProperty(self.drawings.frame, "Color", self.hovered and self.window.theme.InputHover or self.window.theme.Input)
		writeProperty(self.drawings.outline, "Color", self.open and self.window.theme.Accent or self.window.theme.Border)

		for index, drawingSet in ipairs(self.optionDrawings) do
			local hoveredOption = ownsHover and self:getOptionIndex(mousePosition) == index
			local selected = self.options[index] == self.value
			local rowColor = selected and self.window.theme.TabActive or hoveredOption and self.window.theme.InputHover or self.window.theme.Input

			writeProperty(drawingSet.frame, "Color", rowColor)
		end

		return needsLayout
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.label, "ZIndex", z)
		writeProperty(self.drawings.frame, "ZIndex", z)
		writeProperty(self.drawings.outline, "ZIndex", z + 1)
		writeProperty(self.drawings.value, "ZIndex", z + 2)
		writeProperty(self.drawings.arrow, "ZIndex", z + 2)

		for index, drawingSet in ipairs(self.optionDrawings) do
			writeProperty(drawingSet.frame, "ZIndex", z + 3 + index)
			writeProperty(drawingSet.outline, "ZIndex", z + 4 + index)
			writeProperty(drawingSet.text, "ZIndex", z + 5 + index)
		end
	end

	function control:destroy()
		for _, drawing in pairs(self.drawings) do
			destroyDrawing(drawing)
		end

		for _, drawingSet in ipairs(self.optionDrawings) do
			destroyDrawing(drawingSet.frame)
			destroyDrawing(drawingSet.outline)
			destroyDrawing(drawingSet.text)
		end
	end

	control:applyTheme()
	return addControl(window, tab, control)
end

local function addSearchDropdown(window, tab, text, options, defaultValue, callback)
	local control = makeBaseControl(window, tab, "SearchDropdown", SEARCH_DROPDOWN_CLOSED_HEIGHT)
	control.text = text
	control.configKey = text
	control.options = table.clone(options or {})
	control.filteredIndices = {}
	control.value = defaultValue or control.options[1] or "Select"
	control.searchText = ""
	control.callback = callback or function() end
	control.open = false
	control.openAlpha = 0
	control.blocksWindowDrag = true
	control.focused = false
	control.cursorVisible = false
	control.lastBlink = os.clock()
	control.optionDrawings = {}

	control.drawings.label = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = window.theme.TextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	control.drawings.frame = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.Input,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.outline = createDrawing("Square", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Border,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.value = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = tostring(control.value),
		Position = Vector2.zero,
	})

	control.drawings.arrow = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = "v",
		Position = Vector2.zero,
	})

	control.drawings.searchFrame = createDrawing("Square", {
		Visible = false,
		Filled = true,
		Color = window.theme.Input,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.searchOutline = createDrawing("Square", {
		Visible = false,
		Filled = false,
		Color = window.theme.Border,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.searchText = createDrawing("Text", {
		Visible = false,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = "",
		Position = Vector2.zero,
	})

	function control:rebuildOptions()
		for _, drawingSet in ipairs(self.optionDrawings) do
			destroyDrawing(drawingSet.frame)
			destroyDrawing(drawingSet.outline)
			destroyDrawing(drawingSet.text)
		end

		self.optionDrawings = {}

		for _ = 1, #self.options do
			table.insert(self.optionDrawings, {
				frame = createDrawing("Square", {
					Visible = false,
					Filled = true,
					Color = self.window.theme.Input,
					Thickness = 1,
					Size = Vector2.zero,
					Position = Vector2.zero,
				}),
				outline = createDrawing("Square", {
					Visible = false,
					Filled = false,
					Color = self.window.theme.Border,
					Thickness = 1,
					Size = Vector2.zero,
					Position = Vector2.zero,
				}),
				text = createDrawing("Text", {
					Visible = false,
					Color = self.window.theme.Text,
					Size = self.window.theme.SmallTextSize,
					Font = self.window.theme.Font,
					Outline = true,
					Text = "",
					Position = Vector2.zero,
				}),
			})
		end
	end

	function control:updateFilter()
		self.filteredIndices = {}
		local needle = string.lower(self.searchText)

		for index, option in ipairs(self.options) do
			local textValue = tostring(option)
			if needle == "" or string.find(string.lower(textValue), needle, 1, true) then
				table.insert(self.filteredIndices, index)
			end
		end
	end

	function control:GetHeight()
		local optionHeight = round((#self.filteredIndices * DROPDOWN_OPTION_HEIGHT) * self.openAlpha)
		return SEARCH_DROPDOWN_CLOSED_HEIGHT + round(INPUT_HEIGHT * self.openAlpha) + optionHeight
	end

	function control:SetOpen(isOpen)
		self.open = isOpen and #self.options > 0

		if self.open then
			self.window:CloseDropdowns(self)
			activeTextbox = self
			self.focused = true
			self.cursorVisible = true
			self.lastBlink = os.clock()
		else
			if activeTextbox == self then
				activeTextbox = nil
			end
			self.focused = false
			self.cursorVisible = false
			self.searchText = ""
			self:updateFilter()
		end

		updateInputBlocker()
	end

	function control:Blur()
		self.searchText = ""
		self:updateFilter()
		self:SetOpen(false)
	end

	function control:SetValue(nextValue)
		self.value = nextValue
		writeProperty(self.drawings.value, "Text", tostring(nextValue))
	end

	function control:GetConfigValue()
		return self.value
	end

	function control:ApplyConfigValue(nextValue, fireCallback)
		self.searchText = ""
		self:updateFilter()
		self:SetValue(nextValue)
		self.window:UpdateLayout()
		if fireCallback ~= false then
			self.callback(self.value)
		end
	end

	function control:HandleKeyboardInput(input)
		if input.KeyCode == Enum.KeyCode.Return then
			if #self.filteredIndices > 0 then
				self:SetValue(self.options[self.filteredIndices[1]])
				self.callback(self.value)
			end
			self:SetOpen(false)
			return
		elseif input.KeyCode == Enum.KeyCode.Escape then
			self:SetOpen(false)
			return
		elseif input.KeyCode == Enum.KeyCode.Backspace then
			self.searchText = string.sub(self.searchText, 1, math.max(0, #self.searchText - 1))
			self:updateFilter()
			self.window:UpdateLayout()
			return
		end

		local character = getCharacterForInput(input)

		if character == nil then
			return
		end

		self.searchText = self.searchText .. character
		self:updateFilter()
		self.window:UpdateLayout()
	end

	function control:applyTheme()
		for _, key in ipairs({ "label", "value", "arrow", "searchText" }) do
			writeProperty(self.drawings[key], "Font", self.window.theme.Font)
		end

		writeProperty(self.drawings.label, "Color", self.window.theme.Text)
		writeProperty(self.drawings.value, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.arrow, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.outline, "Color", self.window.theme.Border)
		writeProperty(self.drawings.searchOutline, "Color", self.window.theme.Border)
		writeProperty(self.drawings.label, "Size", self.window.theme.TextSize)
		writeProperty(self.drawings.value, "Size", self.window.theme.SmallTextSize)
		writeProperty(self.drawings.arrow, "Size", self.window.theme.SmallTextSize)
		writeProperty(self.drawings.searchText, "Size", self.window.theme.SmallTextSize)

		for _, drawingSet in ipairs(self.optionDrawings) do
			writeProperty(drawingSet.outline, "Color", self.window.theme.Border)
			writeProperty(drawingSet.text, "Color", self.window.theme.Text)
			writeProperty(drawingSet.text, "Font", self.window.theme.Font)
			writeProperty(drawingSet.text, "Size", self.window.theme.SmallTextSize)
		end
	end

	function control:getBaseRect()
		local basePosition = self.position + Vector2.new(0, 16)
		return basePosition, Vector2.new(self.size.X, INPUT_HEIGHT)
	end

	function control:getSearchRect()
		local basePosition = self.position + Vector2.new(0, 16 + INPUT_HEIGHT)
		return basePosition, Vector2.new(self.size.X, INPUT_HEIGHT)
	end

	function control:getOptionIndex(point)
		local optionStart = self.position + Vector2.new(0, 16 + INPUT_HEIGHT + INPUT_HEIGHT)

		for index = 1, #self.filteredIndices do
			local rowPosition = optionStart + Vector2.new(0, (index - 1) * DROPDOWN_OPTION_HEIGHT)

			if pointInRect(point, rowPosition, Vector2.new(self.size.X, DROPDOWN_OPTION_HEIGHT)) then
				return index
			end
		end

		return nil
	end

	function control:layout()
		local basePosition, baseSize = self:getBaseRect()
		local searchPosition, searchSize = self:getSearchRect()
		local visibleCount = round(#self.filteredIndices * self.openAlpha)
		local searchDisplay = self.searchText

		if self.focused and self.cursorVisible then
			searchDisplay = searchDisplay .. "|"
		end

		if searchDisplay == "" then
			searchDisplay = "Type to filter..."
		end

		writeProperty(self.drawings.label, "Position", self.position)
		writeProperty(self.drawings.frame, "Position", basePosition)
		writeProperty(self.drawings.frame, "Size", baseSize)
		writeProperty(self.drawings.outline, "Position", basePosition)
		writeProperty(self.drawings.outline, "Size", baseSize)
		writeProperty(self.drawings.value, "Position", basePosition + Vector2.new(10, 6))
		writeProperty(self.drawings.arrow, "Position", basePosition + Vector2.new(baseSize.X - 16, 6))
		writeProperty(self.drawings.arrow, "Text", self.openAlpha > 0.5 and "^" or "v")

		local searchVisible = self.window:IsControlDisplayed(self) and self.openAlpha > 0.02
		writeProperty(self.drawings.searchFrame, "Position", searchPosition)
		writeProperty(self.drawings.searchFrame, "Size", searchSize)
		writeProperty(self.drawings.searchOutline, "Position", searchPosition)
		writeProperty(self.drawings.searchOutline, "Size", searchSize)
		writeProperty(self.drawings.searchText, "Position", searchPosition + Vector2.new(10, 6))
		writeProperty(self.drawings.searchText, "Text", searchDisplay)
		writeProperty(self.drawings.searchText, "Color", self.searchText == "" and not self.focused and self.window.theme.Muted or self.window.theme.SubText)
		writeProperty(self.drawings.searchFrame, "Visible", searchVisible)
		writeProperty(self.drawings.searchOutline, "Visible", searchVisible)
		writeProperty(self.drawings.searchText, "Visible", searchVisible)

		for index, optionIndex in ipairs(self.filteredIndices) do
			local drawingSet = self.optionDrawings[index]
			local option = self.options[optionIndex]
			local rowPosition = searchPosition + Vector2.new(0, INPUT_HEIGHT + ((index - 1) * DROPDOWN_OPTION_HEIGHT))
			local isVisible = self.window:IsControlDisplayed(self) and index <= visibleCount and self.openAlpha > 0.02

			writeProperty(drawingSet.frame, "Position", rowPosition)
			writeProperty(drawingSet.frame, "Size", Vector2.new(self.size.X, DROPDOWN_OPTION_HEIGHT))
			writeProperty(drawingSet.outline, "Position", rowPosition)
			writeProperty(drawingSet.outline, "Size", Vector2.new(self.size.X, DROPDOWN_OPTION_HEIGHT))
			writeProperty(drawingSet.text, "Position", rowPosition + Vector2.new(10, 5))
			writeProperty(drawingSet.text, "Text", tostring(option))
			writeProperty(drawingSet.frame, "Visible", isVisible)
			writeProperty(drawingSet.outline, "Visible", isVisible)
			writeProperty(drawingSet.text, "Visible", isVisible)
		end

		for index = #self.filteredIndices + 1, #self.optionDrawings do
			local drawingSet = self.optionDrawings[index]
			writeProperty(drawingSet.frame, "Visible", false)
			writeProperty(drawingSet.outline, "Visible", false)
			writeProperty(drawingSet.text, "Visible", false)
		end
	end

	function control:refreshVisibility(shouldShow)
		for _, drawing in pairs(self.drawings) do
			writeProperty(drawing, "Visible", shouldShow and drawing ~= self.drawings.searchFrame and drawing ~= self.drawings.searchOutline and drawing ~= self.drawings.searchText)
		end

		local searchVisible = shouldShow and self.openAlpha > 0.02
		writeProperty(self.drawings.searchFrame, "Visible", searchVisible)
		writeProperty(self.drawings.searchOutline, "Visible", searchVisible)
		writeProperty(self.drawings.searchText, "Visible", searchVisible)

		for index, drawingSet in ipairs(self.optionDrawings) do
			local rowVisible = shouldShow and self.openAlpha > 0.02 and (index <= round(#self.filteredIndices * self.openAlpha))
			writeProperty(drawingSet.frame, "Visible", rowVisible)
			writeProperty(drawingSet.outline, "Visible", rowVisible)
			writeProperty(drawingSet.text, "Visible", rowVisible)
		end
	end

	function control:hitTest(point)
		local basePosition, baseSize = self:getBaseRect()
		local searchPosition, searchSize = self:getSearchRect()

		if pointInRect(point, basePosition, baseSize) then
			return true
		end

		if self.openAlpha > 0.02 and pointInRect(point, searchPosition, searchSize) then
			return true
		end

		return self.openAlpha > 0.02 and self:getOptionIndex(point) ~= nil
	end

	function control:onMouseDown(point)
		local basePosition, baseSize = self:getBaseRect()
		local searchPosition, searchSize = self:getSearchRect()

		if pointInRect(point, basePosition, baseSize) then
			self:SetOpen(not self.open)
			return
		end

		if self.openAlpha > 0.02 and pointInRect(point, searchPosition, searchSize) then
			activeTextbox = self
			self.focused = true
			self.cursorVisible = true
			self.lastBlink = os.clock()
			updateInputBlocker()
			return
		end

		local optionIndex = self:getOptionIndex(point)

		if optionIndex ~= nil then
			self:SetValue(self.options[self.filteredIndices[optionIndex]])
			self.callback(self.value)
			self:SetOpen(false)
		end
	end

	function control:onStep(mousePosition, ownsHover)
		local basePosition, baseSize = self:getBaseRect()
		local targetAlpha = self.open and 1 or 0
		local nextAlpha = lerp(self.openAlpha, targetAlpha, 0.25)
		local needsLayout = false

		if math.abs(nextAlpha - self.openAlpha) > 0.001 then
			self.openAlpha = nextAlpha
			needsLayout = true
		else
			self.openAlpha = targetAlpha
		end

		if self.focused and os.clock() - self.lastBlink >= 0.5 then
			self.lastBlink = os.clock()
			self.cursorVisible = not self.cursorVisible
			needsLayout = true
		end

		self.hovered = ownsHover and pointInRect(mousePosition, basePosition, baseSize)
		writeProperty(self.drawings.frame, "Color", self.hovered and self.window.theme.InputHover or self.window.theme.Input)
		writeProperty(self.drawings.outline, "Color", self.open and self.window.theme.Accent or self.window.theme.Border)
		writeProperty(self.drawings.searchFrame, "Color", self.focused and self.window.theme.InputFocused or self.window.theme.Input)
		writeProperty(self.drawings.searchOutline, "Color", self.focused and self.window.theme.Accent or self.window.theme.Border)

		for index, drawingSet in ipairs(self.optionDrawings) do
			local hoveredOption = ownsHover and self:getOptionIndex(mousePosition) == index
			local selected = self.filteredIndices[index] ~= nil and self.options[self.filteredIndices[index]] == self.value
			local rowColor = selected and self.window.theme.TabActive or hoveredOption and self.window.theme.InputHover or self.window.theme.Input
			writeProperty(drawingSet.frame, "Color", rowColor)
		end

		return needsLayout
	end

	function control:setZIndex(z)
		for _, key in ipairs({ "label", "frame", "outline", "value", "arrow", "searchFrame", "searchOutline", "searchText" }) do
			writeProperty(self.drawings[key], "ZIndex", z)
		end

		for index, drawingSet in ipairs(self.optionDrawings) do
			writeProperty(drawingSet.frame, "ZIndex", z + 2 + index)
			writeProperty(drawingSet.outline, "ZIndex", z + 3 + index)
			writeProperty(drawingSet.text, "ZIndex", z + 4 + index)
		end
	end

	function control:destroy()
		for _, drawing in pairs(self.drawings) do
			destroyDrawing(drawing)
		end

		for _, drawingSet in ipairs(self.optionDrawings) do
			destroyDrawing(drawingSet.frame)
			destroyDrawing(drawingSet.outline)
			destroyDrawing(drawingSet.text)
		end
	end

	control:rebuildOptions()
	control:updateFilter()
	control:applyTheme()
	return addControl(window, tab, control)
end

local function addTextbox(window, tab, text, placeholder, callback)
	local control = makeBaseControl(window, tab, "Textbox", LABELED_INPUT_HEIGHT)
	control.text = ""
	control.title = text
	control.configKey = text
	control.placeholder = placeholder or "Enter text..."
	control.callback = callback or function() end
	control.focused = false
	control.cursorVisible = true
	control.lastBlink = os.clock()
	control.maxLength = 64
	control.blocksWindowDrag = true

	control.drawings.label = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = window.theme.TextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	control.drawings.frame = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.Input,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.outline = createDrawing("Square", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Border,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.value = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = control.placeholder,
		Position = Vector2.zero,
	})

	function control:getDisplayText()
		if self.text == "" and not self.focused then
			return self.placeholder, self.window.theme.Muted
		end

		local display = self.text

		if self.focused and self.cursorVisible then
			display = display .. "|"
		end

		return display, self.window.theme.SubText
	end

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.window.theme.Text)
		writeProperty(self.drawings.label, "Font", self.window.theme.Font)
		writeProperty(self.drawings.value, "Font", self.window.theme.Font)
		writeProperty(self.drawings.label, "Size", self.window.theme.TextSize)
		writeProperty(self.drawings.value, "Size", self.window.theme.SmallTextSize)
	end

	function control:layout()
		local basePosition = self.position + Vector2.new(0, 16)
		local displayText, displayColor = self:getDisplayText()

		writeProperty(self.drawings.label, "Position", self.position)
		writeProperty(self.drawings.frame, "Position", basePosition)
		writeProperty(self.drawings.frame, "Size", Vector2.new(self.size.X, INPUT_HEIGHT))
		writeProperty(self.drawings.outline, "Position", basePosition)
		writeProperty(self.drawings.outline, "Size", Vector2.new(self.size.X, INPUT_HEIGHT))
		writeProperty(self.drawings.value, "Position", basePosition + Vector2.new(10, 6))
		writeProperty(self.drawings.value, "Text", displayText)
		writeProperty(self.drawings.value, "Color", displayColor)
	end

	function control:hitTest(point)
		return pointInRect(point, self.position + Vector2.new(0, 16), Vector2.new(self.size.X, INPUT_HEIGHT))
	end

	function control:onMouseDown()
		if activeTextbox ~= nil and activeTextbox ~= self then
			activeTextbox:Blur(true)
		end

		activeTextbox = self
		self.focused = true
		self.cursorVisible = true
		self.lastBlink = os.clock()
		updateInputBlocker()
		self:layout()
	end

	function control:Blur(submit)
		self.focused = false
		self.cursorVisible = false
		self:layout()
		updateInputBlocker()

		if submit then
			self.callback(self.text)
		end
	end

	function control:HandleKeyboardInput(input)
		if input.KeyCode == Enum.KeyCode.Return then
			clearTextboxFocus(true)
			return
		elseif input.KeyCode == Enum.KeyCode.Escape then
			clearTextboxFocus(false)
			return
		elseif input.KeyCode == Enum.KeyCode.Backspace then
			self.text = string.sub(self.text, 1, math.max(0, #self.text - 1))
			self:layout()
			return
		end

		local character = getCharacterForInput(input)

		if character == nil or #self.text >= self.maxLength then
			return
		end

		self.text = self.text .. character
		self:layout()
	end

	function control:SetText(nextText)
		self.text = tostring(nextText)
		self:layout()
	end

	function control:GetConfigValue()
		return self.text
	end

	function control:ApplyConfigValue(nextValue, fireCallback)
		self:SetText(nextValue)
		if fireCallback ~= false then
			self.callback(self.text)
		end
	end

	function control:onStep(mousePosition, ownsHover)
		self.hovered = ownsHover and self:hitTest(mousePosition)
		if os.clock() - self.lastBlink >= 0.5 then
			self.lastBlink = os.clock()
			self.cursorVisible = not self.cursorVisible
			if self.focused then
				self:layout()
			end
		end

		local frameColor = self.focused and self.window.theme.InputFocused or self.hovered and self.window.theme.InputHover or self.window.theme.Input
		writeProperty(self.drawings.frame, "Color", frameColor)
		writeProperty(self.drawings.outline, "Color", self.focused and self.window.theme.Accent or self.window.theme.Border)
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.label, "ZIndex", z)
		writeProperty(self.drawings.frame, "ZIndex", z)
		writeProperty(self.drawings.outline, "ZIndex", z + 1)
		writeProperty(self.drawings.value, "ZIndex", z + 2)
	end

	function control:destroy()
		for _, drawing in pairs(self.drawings) do
			destroyDrawing(drawing)
		end
	end

	control:applyTheme()
	return addControl(window, tab, control)
end

local function addColorPicker(window, tab, text, defaultColor, callback)
	local control = makeBaseControl(window, tab, "ColorPicker", 148)
	control.text = text
	control.configKey = text
	control.callback = callback or function() end
	control.color = defaultColor or Color3.fromRGB(255, 255, 255)
	control.hue = 0
	control.sat = 1
	control.val = 1
	control.dragMode = nil
	control.blocksWindowDrag = true
	control.hueCells = {}
	control.svCells = {}

	local hue, sat, val = control.color:ToHSV()
	control.hue = hue
	control.sat = sat
	control.val = val

	control.drawings.label = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = window.theme.TextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	control.drawings.preview = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = control.color,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.previewOutline = createDrawing("Square", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Border,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.hex = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = "#FFFFFF",
		Position = Vector2.zero,
	})

	control.drawings.areaOutline = createDrawing("Square", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Border,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.hueOutline = createDrawing("Square", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Border,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.hueMarker = createDrawing("Square", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Text,
		Thickness = 2,
		Size = Vector2.new(16, 6),
		Position = Vector2.zero,
	})

	control.drawings.svMarker = createDrawing("Circle", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Text,
		Thickness = 2,
		NumSides = 18,
		Radius = 4,
		Position = Vector2.zero,
	})

	for index = 1, 96 do
		control.hueCells[index] = createDrawing("Square", {
			Visible = window.visible,
			Filled = true,
			Color = Color3.fromHSV((index - 1) / 96, 1, 1),
			Thickness = 0,
			Size = Vector2.zero,
			Position = Vector2.zero,
		})
	end

	for index = 1, 900 do
		control.svCells[index] = createDrawing("Square", {
			Visible = window.visible,
			Filled = true,
			Color = Color3.new(1, 1, 1),
			Thickness = 0,
			Size = Vector2.zero,
			Position = Vector2.zero,
		})
	end

	function control:getAreaRect()
		local position = self.position + Vector2.new(0, 22)
		local size = 108
		return position, size
	end

	function control:getHueRect()
		local areaPosition, areaSize = self:getAreaRect()
		return areaPosition + Vector2.new(areaSize + 10, 0), 18, areaSize
	end

	function control:applyColor()
		self.color = Color3.fromHSV(self.hue, self.sat, self.val)
		writeProperty(self.drawings.preview, "Color", self.color)
		writeProperty(self.drawings.hex, "Text", string.format("#%02X%02X%02X", round(self.color.R * 255), round(self.color.G * 255), round(self.color.B * 255)))
	end

	function control:SetColor(nextColor)
		self.color = nextColor
		self.hue, self.sat, self.val = nextColor:ToHSV()
		self:layout()
	end

	function control:GetConfigValue()
		return {
			r = self.color.R,
			g = self.color.G,
			b = self.color.B,
		}
	end

	function control:ApplyConfigValue(nextValue, fireCallback)
		if type(nextValue) == "table" and nextValue.r and nextValue.g and nextValue.b then
			self:SetColor(Color3.new(nextValue.r, nextValue.g, nextValue.b))
		end

		if fireCallback ~= false then
			self.callback(self.color)
		end
	end

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.window.theme.Text)
		writeProperty(self.drawings.hex, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.label, "Font", self.window.theme.Font)
		writeProperty(self.drawings.hex, "Font", self.window.theme.Font)
		writeProperty(self.drawings.label, "Size", self.window.theme.TextSize)
		writeProperty(self.drawings.hex, "Size", self.window.theme.SmallTextSize)
		writeProperty(self.drawings.previewOutline, "Color", self.window.theme.Border)
		writeProperty(self.drawings.areaOutline, "Color", self.window.theme.Border)
		writeProperty(self.drawings.hueOutline, "Color", self.window.theme.Border)
		writeProperty(self.drawings.hueMarker, "Color", self.window.theme.Text)
		writeProperty(self.drawings.svMarker, "Color", self.window.theme.Text)
	end

	function control:refreshVisibility(shouldShow)
		for _, drawing in pairs(self.drawings) do
			writeProperty(drawing, "Visible", shouldShow)
		end

		for _, cell in ipairs(self.hueCells) do
			writeProperty(cell, "Visible", shouldShow)
		end

		for _, cell in ipairs(self.svCells) do
			writeProperty(cell, "Visible", shouldShow)
		end
	end

	function control:updateHueStrip()
		local huePosition, hueWidth, hueHeight = self:getHueRect()
		local cellHeight = hueHeight / #self.hueCells

		for index, cell in ipairs(self.hueCells) do
			local alpha = (index - 1) / (#self.hueCells - 1)
			writeProperty(cell, "Position", huePosition + Vector2.new(0, alpha * (hueHeight - cellHeight)))
			writeProperty(cell, "Size", Vector2.new(hueWidth, cellHeight + 1))
			writeProperty(cell, "Color", Color3.fromHSV(alpha, 1, 1))
		end

		writeProperty(self.drawings.hueMarker, "Position", huePosition + Vector2.new(-1, self.hue * hueHeight - 3))
		writeProperty(self.drawings.hueMarker, "Size", Vector2.new(hueWidth + 2, 6))
	end

	function control:updateSvBox()
		local boxPosition, boxSize = self:getAreaRect()
		local cellSize = boxSize / 30

		for row = 0, 29 do
			for column = 0, 29 do
				local index = (row * 30) + column + 1
				local cell = self.svCells[index]
				local sat = column / 29
				local val = 1 - (row / 29)

				writeProperty(cell, "Position", boxPosition + Vector2.new(column * cellSize, row * cellSize))
				writeProperty(cell, "Size", Vector2.new(cellSize + 1, cellSize + 1))
				writeProperty(cell, "Color", Color3.fromHSV(self.hue, sat, val))
			end
		end

		writeProperty(self.drawings.svMarker, "Position", boxPosition + Vector2.new(self.sat * boxSize, (1 - self.val) * boxSize))
	end

	function control:setHueFromMouse(mousePosition)
		local huePosition, _, hueHeight = self:getHueRect()
		self.hue = clamp((mousePosition.Y - huePosition.Y) / hueHeight, 0, 1)
	end

	function control:setSvFromMouse(mousePosition)
		local boxPosition, boxSize = self:getAreaRect()
		self.sat = clamp((mousePosition.X - boxPosition.X) / boxSize, 0, 1)
		self.val = 1 - clamp((mousePosition.Y - boxPosition.Y) / boxSize, 0, 1)
	end

	function control:layout()
		local areaPosition, areaSize = self:getAreaRect()
		local huePosition, hueWidth, hueHeight = self:getHueRect()
		local previewPosition = huePosition + Vector2.new(hueWidth + 14, 0)

		writeProperty(self.drawings.label, "Position", self.position)
		writeProperty(self.drawings.preview, "Position", previewPosition)
		writeProperty(self.drawings.preview, "Size", Vector2.new(36, 36))
		writeProperty(self.drawings.previewOutline, "Position", previewPosition)
		writeProperty(self.drawings.previewOutline, "Size", Vector2.new(36, 36))
		writeProperty(self.drawings.hex, "Position", previewPosition + Vector2.new(0, 44))
		writeProperty(self.drawings.areaOutline, "Position", areaPosition)
		writeProperty(self.drawings.areaOutline, "Size", Vector2.new(areaSize, areaSize))
		writeProperty(self.drawings.hueOutline, "Position", huePosition)
		writeProperty(self.drawings.hueOutline, "Size", Vector2.new(hueWidth, hueHeight))

		self:updateHueStrip()
		self:updateSvBox()
		self:applyColor()
	end

	function control:isInHueStrip(point)
		local huePosition, hueWidth, hueHeight = self:getHueRect()
		return pointInRect(point, huePosition, Vector2.new(hueWidth, hueHeight))
	end

	function control:isInSvBox(point)
		local boxPosition, boxSize = self:getAreaRect()
		return pointInRect(point, boxPosition, Vector2.new(boxSize, boxSize))
	end

	function control:hitTest(point)
		return self:isInHueStrip(point) or self:isInSvBox(point)
	end

	function control:onMouseDown(point)
		if self:isInHueStrip(point) then
			self.dragMode = "hue"
			self:setHueFromMouse(point)
		elseif self:isInSvBox(point) then
			self.dragMode = "sv"
			self:setSvFromMouse(point)
		end

		if self.dragMode ~= nil then
			self:layout()
			self.callback(self.color)
		end
	end

	function control:onMouseUp()
		self.dragMode = nil
	end

	function control:onStep(mousePosition, ownsHover)
		if self.dragMode == "hue" then
			self:setHueFromMouse(mousePosition)
			self:layout()
			self.callback(self.color)
		elseif self.dragMode == "sv" then
			self:setSvFromMouse(mousePosition)
			self:layout()
			self.callback(self.color)
		end

		writeProperty(self.drawings.hueMarker, "Color", self.dragMode == "hue" and self.window.theme.Accent or self.window.theme.Text)
		writeProperty(self.drawings.svMarker, "Color", self.dragMode == "sv" and self.window.theme.Accent or self.window.theme.Text)
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.label, "ZIndex", z)
		writeProperty(self.drawings.preview, "ZIndex", z)
		writeProperty(self.drawings.previewOutline, "ZIndex", z + 1)
		writeProperty(self.drawings.hex, "ZIndex", z + 1)
		writeProperty(self.drawings.areaOutline, "ZIndex", z + 1)
		writeProperty(self.drawings.hueOutline, "ZIndex", z + 1)
		writeProperty(self.drawings.hueMarker, "ZIndex", z + 2)
		writeProperty(self.drawings.svMarker, "ZIndex", z + 2)

		for _, cell in ipairs(self.hueCells) do
			writeProperty(cell, "ZIndex", z)
		end

		for _, cell in ipairs(self.svCells) do
			writeProperty(cell, "ZIndex", z)
		end
	end

	function control:destroy()
		for _, drawing in pairs(self.drawings) do
			destroyDrawing(drawing)
		end

		for _, cell in ipairs(self.hueCells) do
			destroyDrawing(cell)
		end

		for _, cell in ipairs(self.svCells) do
			destroyDrawing(cell)
		end
	end

	control:applyTheme()
	control:applyColor()
	return addControl(window, tab, control)
end

local function addMultiDropdown(window, tab, text, options, defaultValues, callback)
	local control = makeBaseControl(window, tab, "MultiDropdown", LABELED_INPUT_HEIGHT)
	control.text = text
	control.configKey = text
	control.options = table.clone(options or {})
	control.values = {}
	control.selected = {}
	control.callback = callback or function() end
	control.open = false
	control.openAlpha = 0
	control.blocksWindowDrag = true

	for _, value in ipairs(defaultValues or {}) do
		control.selected[value] = true
		table.insert(control.values, value)
	end

	control.drawings.label = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = window.theme.TextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	control.drawings.frame = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.Input,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.outline = createDrawing("Square", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Border,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.value = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = "None",
		Position = Vector2.zero,
	})

	control.drawings.arrow = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = "v",
		Position = Vector2.zero,
	})

	control.optionDrawings = {}

	for _, option in ipairs(control.options) do
		table.insert(control.optionDrawings, {
			frame = createDrawing("Square", {
				Visible = false,
				Filled = true,
				Color = window.theme.Input,
				Thickness = 1,
				Size = Vector2.zero,
				Position = Vector2.zero,
			}),
			outline = createDrawing("Square", {
				Visible = false,
				Filled = false,
				Color = window.theme.Border,
				Thickness = 1,
				Size = Vector2.zero,
				Position = Vector2.zero,
			}),
			check = createDrawing("Text", {
				Visible = false,
				Color = window.theme.Accent,
				Size = window.theme.SmallTextSize,
				Font = window.theme.Font,
				Outline = true,
				Text = "+",
				Position = Vector2.zero,
			}),
			text = createDrawing("Text", {
				Visible = false,
				Color = window.theme.Text,
				Size = window.theme.SmallTextSize,
				Font = window.theme.Font,
				Outline = true,
				Text = tostring(option),
				Position = Vector2.zero,
			}),
		})
	end

	function control:GetHeight()
		return LABELED_INPUT_HEIGHT + round((#self.options * DROPDOWN_OPTION_HEIGHT) * self.openAlpha)
	end

	function control:getDisplayText()
		if #self.values == 0 then
			return "None"
		end

		local joined = table.concat(self.values, ", ")

		if #joined > 26 then
			return tostring(#self.values) .. " selected"
		end

		return joined
	end

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.window.theme.Text)
		writeProperty(self.drawings.value, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.arrow, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.label, "Font", self.window.theme.Font)
		writeProperty(self.drawings.value, "Font", self.window.theme.Font)
		writeProperty(self.drawings.arrow, "Font", self.window.theme.Font)
		writeProperty(self.drawings.label, "Size", self.window.theme.TextSize)
		writeProperty(self.drawings.value, "Size", self.window.theme.SmallTextSize)
		writeProperty(self.drawings.arrow, "Size", self.window.theme.SmallTextSize)

		for _, drawingSet in ipairs(self.optionDrawings) do
			writeProperty(drawingSet.outline, "Color", self.window.theme.Border)
			writeProperty(drawingSet.text, "Color", self.window.theme.Text)
			writeProperty(drawingSet.check, "Color", self.window.theme.Accent)
			writeProperty(drawingSet.text, "Font", self.window.theme.Font)
			writeProperty(drawingSet.check, "Font", self.window.theme.Font)
			writeProperty(drawingSet.text, "Size", self.window.theme.SmallTextSize)
			writeProperty(drawingSet.check, "Size", self.window.theme.SmallTextSize)
		end
	end

	function control:SetOpen(isOpen)
		self.open = isOpen and #self.options > 0
		if self.open then
			self.window:CloseDropdowns(self)
		end
	end

	function control:getBaseRect()
		local basePosition = self.position + Vector2.new(0, 16)
		return basePosition, Vector2.new(self.size.X, INPUT_HEIGHT)
	end

	function control:getOptionIndex(point)
		local basePosition = self.position + Vector2.new(0, 16 + INPUT_HEIGHT)

		for index = 1, #self.options do
			local rowPosition = basePosition + Vector2.new(0, (index - 1) * DROPDOWN_OPTION_HEIGHT)

			if pointInRect(point, rowPosition, Vector2.new(self.size.X, DROPDOWN_OPTION_HEIGHT)) then
				return index
			end
		end

		return nil
	end

	function control:toggleValue(option)
		if self.selected[option] then
			self.selected[option] = nil

			for index, value in ipairs(self.values) do
				if value == option then
					table.remove(self.values, index)
					break
				end
			end
		else
			self.selected[option] = true
			table.insert(self.values, option)
		end

		self.callback(table.clone(self.values))
	end

	function control:SetValues(nextValues)
		self.values = {}
		self.selected = {}

		for _, option in ipairs(nextValues or {}) do
			self.selected[option] = true
			table.insert(self.values, option)
		end

		self:layout()
	end

	function control:GetConfigValue()
		return table.clone(self.values)
	end

	function control:ApplyConfigValue(nextValues, fireCallback)
		self:SetValues(nextValues or {})
		if fireCallback ~= false then
			self.callback(table.clone(self.values))
		end
	end

	function control:layout()
		local basePosition = self.position + Vector2.new(0, 16)
		local baseSize = Vector2.new(self.size.X, INPUT_HEIGHT)
		local visibleCount = round(#self.options * self.openAlpha)

		writeProperty(self.drawings.label, "Position", self.position)
		writeProperty(self.drawings.frame, "Position", basePosition)
		writeProperty(self.drawings.frame, "Size", baseSize)
		writeProperty(self.drawings.outline, "Position", basePosition)
		writeProperty(self.drawings.outline, "Size", baseSize)
		writeProperty(self.drawings.value, "Position", basePosition + Vector2.new(10, 6))
		writeProperty(self.drawings.value, "Text", self:getDisplayText())
		writeProperty(self.drawings.arrow, "Position", basePosition + Vector2.new(baseSize.X - 16, 6))
		writeProperty(self.drawings.arrow, "Text", self.openAlpha > 0.5 and "^" or "v")

		for index, option in ipairs(self.options) do
			local drawingSet = self.optionDrawings[index]
			local rowPosition = basePosition + Vector2.new(0, INPUT_HEIGHT + ((index - 1) * DROPDOWN_OPTION_HEIGHT))
			local isVisible = self.window:IsControlDisplayed(self) and index <= visibleCount and self.openAlpha > 0.02

			writeProperty(drawingSet.frame, "Position", rowPosition)
			writeProperty(drawingSet.frame, "Size", Vector2.new(self.size.X, DROPDOWN_OPTION_HEIGHT))
			writeProperty(drawingSet.outline, "Position", rowPosition)
			writeProperty(drawingSet.outline, "Size", Vector2.new(self.size.X, DROPDOWN_OPTION_HEIGHT))
			writeProperty(drawingSet.check, "Position", rowPosition + Vector2.new(8, 5))
			writeProperty(drawingSet.check, "Text", self.selected[option] and "+" or "-")
			writeProperty(drawingSet.text, "Position", rowPosition + Vector2.new(24, 5))
			writeProperty(drawingSet.text, "Text", tostring(option))
			writeProperty(drawingSet.frame, "Visible", isVisible)
			writeProperty(drawingSet.outline, "Visible", isVisible)
			writeProperty(drawingSet.check, "Visible", isVisible)
			writeProperty(drawingSet.text, "Visible", isVisible)
		end
	end

	function control:refreshVisibility(shouldShow)
		for _, drawing in pairs(self.drawings) do
			writeProperty(drawing, "Visible", shouldShow)
		end

		for index, drawingSet in ipairs(self.optionDrawings) do
			local rowVisible = shouldShow and self.openAlpha > 0.02 and (index <= round(#self.options * self.openAlpha))
			writeProperty(drawingSet.frame, "Visible", rowVisible)
			writeProperty(drawingSet.outline, "Visible", rowVisible)
			writeProperty(drawingSet.check, "Visible", rowVisible)
			writeProperty(drawingSet.text, "Visible", rowVisible)
		end
	end

	function control:hitTest(point)
		local basePosition, baseSize = self:getBaseRect()

		if pointInRect(point, basePosition, baseSize) then
			return true
		end

		return self.openAlpha > 0.02 and self:getOptionIndex(point) ~= nil
	end

	function control:onMouseDown(point)
		local basePosition, baseSize = self:getBaseRect()

		if pointInRect(point, basePosition, baseSize) then
			self:SetOpen(not self.open)
			return
		end

		local optionIndex = self:getOptionIndex(point)

		if optionIndex ~= nil then
			self:toggleValue(self.options[optionIndex])
		end
	end

	function control:onStep(mousePosition, ownsHover)
		local basePosition, baseSize = self:getBaseRect()
		local targetAlpha = self.open and 1 or 0
		local nextAlpha = lerp(self.openAlpha, targetAlpha, 0.25)
		local needsLayout = false

		if math.abs(nextAlpha - self.openAlpha) > 0.001 then
			self.openAlpha = nextAlpha
			needsLayout = true
		else
			self.openAlpha = targetAlpha
		end

		self.hovered = ownsHover and pointInRect(mousePosition, basePosition, baseSize)
		writeProperty(self.drawings.frame, "Color", self.hovered and self.window.theme.InputHover or self.window.theme.Input)
		writeProperty(self.drawings.outline, "Color", self.open and self.window.theme.Accent or self.window.theme.Border)

		for index, drawingSet in ipairs(self.optionDrawings) do
			local option = self.options[index]
			local hoveredOption = ownsHover and self:getOptionIndex(mousePosition) == index
			local selected = self.selected[option]
			local rowColor = selected and self.window.theme.TabActive or hoveredOption and self.window.theme.InputHover or self.window.theme.Input

			writeProperty(drawingSet.frame, "Color", rowColor)
		end

		return needsLayout
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.label, "ZIndex", z)
		writeProperty(self.drawings.frame, "ZIndex", z)
		writeProperty(self.drawings.outline, "ZIndex", z + 1)
		writeProperty(self.drawings.value, "ZIndex", z + 2)
		writeProperty(self.drawings.arrow, "ZIndex", z + 2)

		for index, drawingSet in ipairs(self.optionDrawings) do
			writeProperty(drawingSet.frame, "ZIndex", z + 3 + index)
			writeProperty(drawingSet.outline, "ZIndex", z + 4 + index)
			writeProperty(drawingSet.check, "ZIndex", z + 5 + index)
			writeProperty(drawingSet.text, "ZIndex", z + 5 + index)
		end
	end

	function control:destroy()
		for _, drawing in pairs(self.drawings) do
			destroyDrawing(drawing)
		end

		for _, drawingSet in ipairs(self.optionDrawings) do
			destroyDrawing(drawingSet.frame)
			destroyDrawing(drawingSet.outline)
			destroyDrawing(drawingSet.check)
			destroyDrawing(drawingSet.text)
		end
	end

	control:applyTheme()
	return addControl(window, tab, control)
end

local function addKeybind(window, tab, text, defaultKey, callback, changedCallback)
	local control = makeBaseControl(window, tab, "Keybind", LABELED_INPUT_HEIGHT)
	control.text = text
	control.configKey = text
	control.binding = typeof(defaultKey) == "EnumItem" and {
		kind = "Keyboard",
		code = defaultKey,
	} or defaultKey
	control.callback = callback or function() end
	control.changedCallback = changedCallback or function() end
	control.listening = false
	control.blocksWindowDrag = true
	control.allowMouseInputs = false

	control.drawings.label = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.Text,
		Size = window.theme.TextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = text,
		Position = Vector2.zero,
	})

	control.drawings.frame = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.Input,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.outline = createDrawing("Square", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Border,
		Thickness = 1,
		Size = Vector2.zero,
		Position = Vector2.zero,
	})

	control.drawings.value = createDrawing("Text", {
		Visible = window.visible,
		Color = window.theme.SubText,
		Size = window.theme.SmallTextSize,
		Font = window.theme.Font,
		Outline = true,
		Text = formatInputBinding(control.binding),
		Position = Vector2.zero,
	})

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.window.theme.Text)
		writeProperty(self.drawings.value, "Color", self.window.theme.SubText)
		writeProperty(self.drawings.label, "Font", self.window.theme.Font)
		writeProperty(self.drawings.value, "Font", self.window.theme.Font)
		writeProperty(self.drawings.label, "Size", self.window.theme.TextSize)
		writeProperty(self.drawings.value, "Size", self.window.theme.SmallTextSize)
	end

	function control:layout()
		local basePosition = self.position + Vector2.new(0, 16)

		writeProperty(self.drawings.label, "Position", self.position)
		writeProperty(self.drawings.frame, "Position", basePosition)
		writeProperty(self.drawings.frame, "Size", Vector2.new(self.size.X, INPUT_HEIGHT))
		writeProperty(self.drawings.outline, "Position", basePosition)
		writeProperty(self.drawings.outline, "Size", Vector2.new(self.size.X, INPUT_HEIGHT))
		writeProperty(self.drawings.value, "Position", basePosition + Vector2.new(10, 6))
		writeProperty(self.drawings.value, "Text", self.listening and "Press a key..." or formatInputBinding(self.binding))
	end

	function control:hitTest(point)
		return pointInRect(point, self.position + Vector2.new(0, 16), Vector2.new(self.size.X, INPUT_HEIGHT))
	end

	function control:SetListening(isListening)
		self.listening = isListening
		updateInputBlocker()
		self:layout()
	end

	function control:SetBinding(nextBinding)
		self.binding = nextBinding
		self:layout()
	end

	function control:SetAllowMouseInputs(allowMouse)
		self.allowMouseInputs = allowMouse == true
	end

	function control:GetConfigValue()
		return self.binding
	end

	function control:ApplyConfigValue(nextBinding, fireCallback)
		self:SetBinding(nextBinding)
		if fireCallback ~= false then
			self.changedCallback(self.binding)
		end
	end

	function control:CaptureInput(input)
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
			self.binding = nil
		else
			local nextBinding = makeBindingFromInput(input)

			if nextBinding == nil then
				return
			end

			if nextBinding.kind ~= "Keyboard" and not self.allowMouseInputs then
				return
			end

			self.binding = nextBinding
		end

		self:SetListening(false)
		listeningKeybind = nil
		self.changedCallback(self.binding)
	end

	function control:onMouseDown()
		clearTextboxFocus(true)
		if listeningKeybind ~= nil and listeningKeybind ~= self then
			listeningKeybind:SetListening(false)
		end

		listeningKeybind = self
		self:SetListening(true)
	end

	function control:onStep(mousePosition, ownsHover)
		self.hovered = ownsHover and self:hitTest(mousePosition)
		local frameColor = self.listening and self.window.theme.InputFocused or self.hovered and self.window.theme.InputHover or self.window.theme.Input
		writeProperty(self.drawings.frame, "Color", frameColor)
		writeProperty(self.drawings.outline, "Color", self.listening and self.window.theme.Accent or self.window.theme.Border)
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.label, "ZIndex", z)
		writeProperty(self.drawings.frame, "ZIndex", z)
		writeProperty(self.drawings.outline, "ZIndex", z + 1)
		writeProperty(self.drawings.value, "ZIndex", z + 2)
	end

	function control:destroy()
		for _, drawing in pairs(self.drawings) do
			destroyDrawing(drawing)
		end
	end

	control:applyTheme()
	return addControl(window, tab, control)
end

function Tab:AddLabel(text)
	return addLabel(self.window, self, text)
end

function Tab:AddParagraph(title, text)
	return addParagraph(self.window, self, title, text)
end

function Tab:AddSection(text)
	return addSection(self.window, self, text)
end

function Tab:AddSubTab(text, expanded)
	return addSubTab(self.window, self, text, expanded)
end

function Tab:AddButton(text, callback)
	return addButton(self.window, self, text, callback)
end

function Tab:AddButtonRow(buttons)
	return addButtonRow(self.window, self, buttons)
end

function Tab:AddToggle(text, initialValue, callback)
	return addToggle(self.window, self, text, initialValue, callback)
end

function Tab:AddSlider(text, minimum, maximum, initialValue, callback)
	return addSlider(self.window, self, text, minimum, maximum, initialValue, callback)
end

function Tab:AddDropdown(text, options, defaultValue, callback)
	return addDropdown(self.window, self, text, options, defaultValue, callback)
end

function Tab:AddSearchDropdown(text, options, defaultValue, callback)
	return addSearchDropdown(self.window, self, text, options, defaultValue, callback)
end

function Tab:AddMultiDropdown(text, options, defaultValues, callback)
	return addMultiDropdown(self.window, self, text, options, defaultValues, callback)
end

function Tab:AddColorPicker(text, defaultColor, callback)
	return addColorPicker(self.window, self, text, defaultColor, callback)
end

function Tab:AddTextbox(text, placeholder, callback)
	return addTextbox(self.window, self, text, placeholder, callback)
end

function Tab:AddKeybind(text, defaultKey, callback, changedCallback)
	return addKeybind(self.window, self, text, defaultKey, callback, changedCallback)
end

function Tab:Select()
	self.window:SetActiveTab(self)
end

function Window:AddTab(name)
	local tab = setmetatable({
		window = self,
		name = name,
		controls = {},
		position = Vector2.zero,
		size = Vector2.zero,
		drawings = {
			background = createDrawing("Square", {
				Visible = self.visible,
				Filled = true,
				Color = self.theme.Tab,
				Thickness = 1,
				Position = Vector2.zero,
				Size = Vector2.zero,
			}),
			outline = createDrawing("Square", {
				Visible = self.visible,
				Filled = false,
				Color = self.theme.Border,
				Thickness = 1,
				Position = Vector2.zero,
				Size = Vector2.zero,
			}),
			text = createDrawing("Text", {
				Visible = self.visible,
				Color = self.theme.SubText,
				Size = 13,
				Font = FONT,
				Outline = true,
				Text = name,
				Position = Vector2.zero,
			}),
		},
	}, Tab)

	table.insert(self.tabs, tab)

	if self.activeTab == nil then
		self.activeTab = tab
	end

	self:UpdateLayout()
	self:RefreshZIndex()

	return tab
end

function Window:AddLabel(text)
	return addLabel(self, nil, text)
end

function Window:AddParagraph(title, text)
	return addParagraph(self, nil, title, text)
end

function Window:AddSection(text)
	return addSection(self, nil, text)
end

function Window:AddSubTab(text, expanded)
	return addSubTab(self, nil, text, expanded)
end

function Window:AddButton(text, callback)
	return addButton(self, nil, text, callback)
end

function Window:AddButtonRow(buttons)
	return addButtonRow(self, nil, buttons)
end

function Window:AddToggle(text, initialValue, callback)
	return addToggle(self, nil, text, initialValue, callback)
end

function Window:AddSlider(text, minimum, maximum, initialValue, callback)
	return addSlider(self, nil, text, minimum, maximum, initialValue, callback)
end

function Window:AddDropdown(text, options, defaultValue, callback)
	return addDropdown(self, nil, text, options, defaultValue, callback)
end

function Window:AddSearchDropdown(text, options, defaultValue, callback)
	return addSearchDropdown(self, nil, text, options, defaultValue, callback)
end

function Window:AddMultiDropdown(text, options, defaultValues, callback)
	return addMultiDropdown(self, nil, text, options, defaultValues, callback)
end

function Window:AddColorPicker(text, defaultColor, callback)
	return addColorPicker(self, nil, text, defaultColor, callback)
end

function Window:AddTextbox(text, placeholder, callback)
	return addTextbox(self, nil, text, placeholder, callback)
end

function Window:AddKeybind(text, defaultKey, callback, changedCallback)
	return addKeybind(self, nil, text, defaultKey, callback, changedCallback)
end

function DrawingUI.new(options)
	local config = {}

	for key, value in pairs(DEFAULT_WINDOW) do
		config[key] = value
	end

	for key, value in pairs(options or {}) do
		config[key] = value
	end

	local self = setmetatable({}, Window)
	self.title = config.Title
	self.subtitle = "drag me"
	self.position = config.Position
	self.size = config.Size
	self.minimumSize = config.Size
	self.visible = config.Visible
	self.dragAnywhere = config.DragAnywhere ~= false
	self.configId = config.ConfigId
	self.configRoot = config.ConfigRoot
	self.theme = mergeTheme(config.Theme)
	self.controls = {}
	self.tabs = {}
	self.activeTab = nil
	self.dragging = false
	self.pendingDrag = false
	self.dragOffset = Vector2.zero
	self.zBase = 100 + (#windows * 24)

	self.drawings = {
		shadow = createDrawing("Square", {
			Visible = self.visible,
			Filled = true,
			Color = Color3.fromRGB(7, 9, 12),
			Transparency = 0.55,
			Thickness = 1,
			Position = Vector2.zero,
			Size = Vector2.zero,
		}),
		frame = createDrawing("Square", {
			Visible = self.visible,
			Filled = true,
			Color = self.theme.WindowBackground,
			Thickness = 1,
			Position = Vector2.zero,
			Size = Vector2.zero,
		}),
		header = createDrawing("Square", {
			Visible = self.visible,
			Filled = true,
			Color = self.theme.HeaderBackground,
			Thickness = 1,
			Position = Vector2.zero,
			Size = Vector2.zero,
		}),
		accent = createDrawing("Line", {
			Visible = self.visible,
			Color = self.theme.Accent,
			Thickness = 1,
			From = Vector2.zero,
			To = Vector2.zero,
		}),
		title = createDrawing("Text", {
			Visible = self.visible,
			Color = self.theme.Text,
			Size = 15,
			Font = FONT,
			Outline = true,
			Text = self.title,
			Position = Vector2.zero,
		}),
		subtitle = createDrawing("Text", {
			Visible = self.visible,
			Color = self.theme.Muted,
			Size = 12,
			Font = FONT,
			Outline = true,
			Text = self.subtitle,
			Position = Vector2.zero,
		}),
	}

	table.insert(windows, self)
	ensureLoop()
	bringWindowToFront(self)
	self:UpdateLayout()

	return self
end

DrawingUI.CreateWindow = DrawingUI.new
DrawingUI.CreateTheme = mergeTheme
DrawingUI.Version = VERSION
DrawingUI.Themes = {
	Default = mergeTheme(),
	Amber = mergeTheme({
		Accent = Color3.fromRGB(255, 155, 66),
		ToggleEnabled = Color3.fromRGB(255, 155, 66),
		SliderFill = Color3.fromRGB(255, 155, 66),
		HeaderBackground = Color3.fromRGB(30, 24, 18),
		WindowBackground = Color3.fromRGB(20, 18, 16),
		ButtonHover = Color3.fromRGB(54, 42, 31),
	}),
	Midnight = mergeTheme({
		Accent = Color3.fromRGB(102, 187, 255),
		ToggleEnabled = Color3.fromRGB(102, 187, 255),
		SliderFill = Color3.fromRGB(102, 187, 255),
		HeaderBackground = Color3.fromRGB(19, 25, 38),
		WindowBackground = Color3.fromRGB(14, 18, 27),
	}),
}

function DrawingUI.ClearAll()
	for index = #windows, 1, -1 do
		windows[index]:Destroy()
	end

	if typeof(cleardrawcache) == "function" then
		cleardrawcache()
	end
end

return DrawingUI
