local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DrawingUI = {}
DrawingUI.__index = DrawingUI

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
	Tab = Color3.fromRGB(24, 29, 38),
	TabHover = Color3.fromRGB(33, 39, 50),
	TabActive = Color3.fromRGB(36, 44, 56),
	Toggle = Color3.fromRGB(48, 54, 67),
	ToggleEnabled = Color3.fromRGB(63, 161, 255),
	SliderTrack = Color3.fromRGB(45, 50, 62),
	SliderFill = Color3.fromRGB(63, 161, 255),
	SectionLine = Color3.fromRGB(53, 59, 72),
}

local DEFAULT_WINDOW = {
	Title = "Drawing UI",
	Position = Vector2.new(200, 160),
	Size = Vector2.new(470, 360),
	Visible = true,
	Theme = {},
}

local FONT = 2
local HEADER_HEIGHT = 32
local TAB_HEIGHT = 24
local TAB_GAP = 6
local PADDING = 12
local CONTENT_GAP = 10
local ROW_HEIGHT = 24
local ROW_GAP = 8
local BUTTON_HEIGHT = 28
local TOGGLE_HEIGHT = 24
local SECTION_HEIGHT = 18
local SLIDER_HEIGHT = 38
local WINDOW_MARGIN = 8

local windows = {}
local frameConnection
local inputBeganConnection
local inputEndedConnection

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

local function makeBaseControl(window, tab, kind, height)
	return {
		window = window,
		tab = tab,
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
	return clamp(24 + (#name * 7), 66, 140)
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
		if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		local mousePosition = getMousePosition()
		local window = topWindowAt(mousePosition)

		if window == nil then
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
	return self.visible and control.visible and self:IsTabActive(control.tab)
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
	local maxX = viewport.X - width - WINDOW_MARGIN
	local maxY = viewport.Y - height - WINDOW_MARGIN

	self.size = Vector2.new(width, height)
	self.position = Vector2.new(
		clamp(self.position.X, WINDOW_MARGIN, math.max(WINDOW_MARGIN, maxX)),
		clamp(self.position.Y, WINDOW_MARGIN, math.max(WINDOW_MARGIN, maxY))
	)
end

function Window:GetActiveControls()
	local list = {}

	for _, control in ipairs(self.controls) do
		if self:IsTabActive(control.tab) then
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
			height += control.height

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
	writeProperty(self.drawings.title, "Position", position + Vector2.new(PADDING, 7))
	writeProperty(self.drawings.subtitle, "Position", position + Vector2.new(size.X - 100, 9))
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
		writeProperty(tab.drawings.text, "Position", tab.position + Vector2.new(10, 5))
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
			control.size = Vector2.new(contentWidth, control.height)

			if control.layout then
				control:layout()
			end

			if control.visible then
				y += control.height + ROW_GAP
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

	self:UpdateLayout()
end

function Window:HandleMouseDown(point)
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
		control:onMouseDown(point)
	end
end

function Window:HandleMouseUp(point)
	self.dragging = false

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
	end

	self:UpdateTabVisuals(mousePosition)

	local topWindow = topWindowAt(mousePosition)
	local ownsHover = topWindow == self

	for _, control in ipairs(self.controls) do
		if self:IsControlDisplayed(control) and control.onStep then
			control:onStep(mousePosition, ownsHover)
		end
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

	function control:setZIndex(z)
		writeProperty(self.drawings.text, "ZIndex", z)
		writeProperty(self.drawings.line, "ZIndex", z)
	end

	function control:destroy()
		destroyDrawing(self.drawings.text)
		destroyDrawing(self.drawings.line)
	end

	return addControl(window, tab, control)
end

local function addButton(window, tab, text, callback)
	local control = makeBaseControl(window, tab, "Button", BUTTON_HEIGHT)
	control.text = text
	control.callback = callback or function() end

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
		writeProperty(self.drawings.text, "Position", self.position + Vector2.new(10, 5))
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

	function control:onStep(mousePosition, ownsHover)
		self.hovered = ownsHover and self:hitTest(mousePosition)
		writeProperty(self.drawings.frame, "Color", self.hovered and self.window.theme.ButtonHover or self.window.theme.Button)
	end

	function control:SetText(nextText)
		self.text = nextText
		writeProperty(self.drawings.text, "Text", nextText)
	end

	function control:destroy()
		destroyDrawing(self.drawings.frame)
		destroyDrawing(self.drawings.outline)
		destroyDrawing(self.drawings.text)
	end

	return addControl(window, tab, control)
end

local function addToggle(window, tab, text, initialValue, callback)
	local control = makeBaseControl(window, tab, "Toggle", TOGGLE_HEIGHT)
	control.text = text
	control.value = initialValue == true
	control.callback = callback or function() end

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
		local activeColor = self.value and self.window.theme.ToggleEnabled or self.window.theme.Toggle

		writeProperty(self.drawings.trackLeft, "Color", activeColor)
		writeProperty(self.drawings.trackRight, "Color", activeColor)
		writeProperty(self.drawings.trackCenter, "Color", activeColor)
		writeProperty(self.drawings.state, "Text", self.value and "ON" or "OFF")
		writeProperty(self.drawings.state, "Color", self.value and self.window.theme.Accent or self.window.theme.SubText)
	end

	function control:refreshVisibility(shouldShow)
		for _, drawing in pairs(self.drawings) do
			writeProperty(drawing, "Visible", shouldShow)
		end
	end

	function control:layout()
		local switchWidth = 34
		local switchPosition = self.position + Vector2.new(self.size.X - switchWidth, 4)
		local knobX = self.value and switchPosition.X + 26 or switchPosition.X + 8

		writeProperty(self.drawings.text, "Position", self.position + Vector2.new(0, 3))
		writeProperty(self.drawings.state, "Position", self.position + Vector2.new(self.size.X - 72, 4))
		writeProperty(self.drawings.trackLeft, "Position", switchPosition + Vector2.new(8, 8))
		writeProperty(self.drawings.trackRight, "Position", switchPosition + Vector2.new(switchWidth - 8, 8))
		writeProperty(self.drawings.trackCenter, "Position", switchPosition + Vector2.new(8, 0))
		writeProperty(self.drawings.trackCenter, "Size", Vector2.new(switchWidth - 16, 16))
		writeProperty(self.drawings.knob, "Position", Vector2.new(knobX, switchPosition.Y + 8))

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

	function control:onStep(mousePosition, ownsHover)
		self.hovered = ownsHover and self:hitTest(mousePosition)
		writeProperty(self.drawings.knob, "Color", self.hovered and self.window.theme.Text or Color3.fromRGB(245, 247, 250))
	end

	function control:SetValue(nextValue)
		self.value = nextValue == true
		self:layout()
	end

	function control:destroy()
		for _, drawing in pairs(self.drawings) do
			destroyDrawing(drawing)
		end
	end

	return addControl(window, tab, control)
end

local function addSlider(window, tab, text, minimum, maximum, initialValue, callback)
	local control = makeBaseControl(window, tab, "Slider", SLIDER_HEIGHT)
	control.text = text
	control.minimum = minimum
	control.maximum = maximum
	control.value = clamp(initialValue or minimum, minimum, maximum)
	control.callback = callback or function() end
	control.dragging = false

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

	function control:updateVisuals()
		local barPosition = self.position + Vector2.new(0, 24)
		local barWidth = self.size.X
		local alpha = self:getAlpha()
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
		writeProperty(self.drawings.value, "Position", self.position + Vector2.new(self.size.X - 52, 1))
		self:updateVisuals()
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.label, "ZIndex", z)
		writeProperty(self.drawings.value, "ZIndex", z)
		writeProperty(self.drawings.track, "ZIndex", z)
		writeProperty(self.drawings.fill, "ZIndex", z + 1)
		writeProperty(self.drawings.knob, "ZIndex", z + 2)
	end

	function control:hitTest(point)
		return pointInRect(point, self.position + Vector2.new(0, 18), Vector2.new(self.size.X, 14))
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

		local hovered = ownsHover and self:hitTest(mousePosition)
		writeProperty(self.drawings.knob, "Color", (hovered or self.dragging) and self.window.theme.Accent or self.window.theme.Text)
	end

	function control:SetValue(nextValue)
		self.value = clamp(nextValue, self.minimum, self.maximum)
		self:updateVisuals()
	end

	function control:destroy()
		for _, drawing in pairs(self.drawings) do
			destroyDrawing(drawing)
		end
	end

	return addControl(window, tab, control)
end

function Tab:AddLabel(text)
	return addLabel(self.window, self, text)
end

function Tab:AddSection(text)
	return addSection(self.window, self, text)
end

function Tab:AddButton(text, callback)
	return addButton(self.window, self, text, callback)
end

function Tab:AddToggle(text, initialValue, callback)
	return addToggle(self.window, self, text, initialValue, callback)
end

function Tab:AddSlider(text, minimum, maximum, initialValue, callback)
	return addSlider(self.window, self, text, minimum, maximum, initialValue, callback)
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

function Window:AddSection(text)
	return addSection(self, nil, text)
end

function Window:AddButton(text, callback)
	return addButton(self, nil, text, callback)
end

function Window:AddToggle(text, initialValue, callback)
	return addToggle(self, nil, text, initialValue, callback)
end

function Window:AddSlider(text, minimum, maximum, initialValue, callback)
	return addSlider(self, nil, text, minimum, maximum, initialValue, callback)
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
	self.theme = mergeTheme(config.Theme)
	self.controls = {}
	self.tabs = {}
	self.activeTab = nil
	self.dragging = false
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

function DrawingUI.ClearAll()
	for index = #windows, 1, -1 do
		windows[index]:Destroy()
	end

	if typeof(cleardrawcache) == "function" then
		cleardrawcache()
	end
end

return DrawingUI