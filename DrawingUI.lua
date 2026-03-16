local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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
	Toggle = Color3.fromRGB(34, 39, 49),
	ToggleEnabled = Color3.fromRGB(63, 161, 255),
	SliderTrack = Color3.fromRGB(45, 50, 62),
	SliderFill = Color3.fromRGB(63, 161, 255),
	SectionLine = Color3.fromRGB(53, 59, 72),
}

local DEFAULT_WINDOW = {
	Title = "Drawing UI",
	Position = Vector2.new(200, 160),
	Size = Vector2.new(420, 360),
	Visible = true,
	Theme = {},
}

local FONT = 2
local HEADER_HEIGHT = 32
local PADDING = 12
local CONTENT_TOP = HEADER_HEIGHT + 10
local ROW_HEIGHT = 26
local ROW_GAP = 8
local SECTION_HEIGHT = 22
local SLIDER_HEIGHT = 36

local windows = {}
local frameConnection
local inputBeganConnection
local inputEndedConnection

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function lerp(a, b, alpha)
	return a + (b - a) * alpha
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

local function makeBaseControl(window, kind, height)
	return {
		window = window,
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

local function addControl(window, control)
	table.insert(window.controls, control)
	window:UpdateLayout()
	window:RefreshZIndex()
	return control
end

local function styleControlVisibility(control, isVisible)
	control.visible = isVisible

	for _, drawing in pairs(control.drawings) do
		writeProperty(drawing, "Visible", isVisible and control.window.visible)
	end

	if control.refreshVisibility then
		control:refreshVisibility()
	end
end

local function setWindowVisible(window, isVisible)
	window.visible = isVisible

	for _, drawing in pairs(window.drawings) do
		writeProperty(drawing, "Visible", isVisible)
	end

	for _, control in ipairs(window.controls) do
		styleControlVisibility(control, control.visible)
	end
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
		candidate.zBase = baseZ + (index * 20)
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
		if processed then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
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

local Window = {}
Window.__index = Window

function Window:RefreshZIndex()
	local z = self.zBase

	writeProperty(self.drawings.shadow, "ZIndex", z)
	writeProperty(self.drawings.frame, "ZIndex", z + 1)
	writeProperty(self.drawings.header, "ZIndex", z + 2)
	writeProperty(self.drawings.accent, "ZIndex", z + 3)
	writeProperty(self.drawings.title, "ZIndex", z + 4)
	writeProperty(self.drawings.subtitle, "ZIndex", z + 4)

	local controlZ = z + 5

	for _, control in ipairs(self.controls) do
		if control.setZIndex then
			control:setZIndex(controlZ)
		end
	end
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
	writeProperty(self.drawings.subtitle, "Position", position + Vector2.new(size.X - PADDING - 80, 9))
end

function Window:UpdateLayout()
	self:UpdateChrome()

	local y = self.position.Y + CONTENT_TOP
	local contentWidth = self.size.X - (PADDING * 2)

	for _, control in ipairs(self.controls) do
		control.position = Vector2.new(self.position.X + PADDING, y)
		control.size = Vector2.new(contentWidth, control.height)

		if control.layout then
			control:layout()
		end

		y += control.height + ROW_GAP
	end
end

function Window:SetVisible(isVisible)
	setWindowVisible(self, isVisible)
end

function Window:SetTitle(text)
	self.title = text
	writeProperty(self.drawings.title, "Text", text)
end

function Window:SetSubtitle(text)
	writeProperty(self.drawings.subtitle, "Text", text)
end

function Window:SetPosition(position)
	self.position = position
	self:UpdateLayout()
end

function Window:SetSize(size)
	self.size = size
	self:UpdateLayout()
end

function Window:IsPointInHeader(point)
	return pointInRect(point, self.position, Vector2.new(self.size.X, HEADER_HEIGHT))
end

function Window:GetControlAt(point)
	for _, control in ipairs(self.controls) do
		if control.visible and control.hitTest and control:hitTest(point) then
			return control
		end
	end

	return nil
end

function Window:HandleMouseDown(point)
	if self:IsPointInHeader(point) then
		self.dragging = true
		self.dragOffset = point - self.position
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
		self:UpdateLayout()
	end

	local topWindow = topWindowAt(mousePosition)
	local ownsHover = topWindow == self

	for _, control in ipairs(self.controls) do
		if control.onStep then
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

	disconnectLoopIfEmpty()
end

local function addLabel(window, text)
	local control = makeBaseControl(window, "Label", ROW_HEIGHT)
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
		writeProperty(self.drawings.text, "Position", self.position + Vector2.new(0, 4))
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

	return addControl(window, control)
end

local function addSection(window, text)
	local control = makeBaseControl(window, "Section", SECTION_HEIGHT)
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
		local textPosition = self.position + Vector2.new(0, 1)
		local textWidth = (#self.text * 6) + 16
		local lineY = self.position.Y + 12

		writeProperty(self.drawings.text, "Position", textPosition)
		writeProperty(self.drawings.line, "From", Vector2.new(self.position.X + textWidth, lineY))
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

	return addControl(window, control)
end

local function addButton(window, text, callback)
	local control = makeBaseControl(window, "Button", ROW_HEIGHT)
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
		writeProperty(self.drawings.text, "Position", self.position + Vector2.new(10, 4))
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

		local color = self.hovered and self.window.theme.ButtonHover or self.window.theme.Button
		writeProperty(self.drawings.frame, "Color", color)
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

	return addControl(window, control)
end

local function addToggle(window, text, initialValue, callback)
	local control = makeBaseControl(window, "Toggle", ROW_HEIGHT)
	control.text = text
	control.value = initialValue == true
	control.callback = callback or function() end

	control.drawings.box = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.Toggle,
		Thickness = 1,
		Size = Vector2.new(18, 18),
		Position = Vector2.zero,
	})

	control.drawings.mark = createDrawing("Square", {
		Visible = window.visible,
		Filled = true,
		Color = window.theme.ToggleEnabled,
		Thickness = 1,
		Size = Vector2.new(10, 10),
		Position = Vector2.zero,
	})

	control.drawings.outline = createDrawing("Square", {
		Visible = window.visible,
		Filled = false,
		Color = window.theme.Border,
		Thickness = 1,
		Size = Vector2.new(18, 18),
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

	function control:applyValue()
		writeProperty(self.drawings.mark, "Visible", self.value and self.window.visible and self.visible)
		writeProperty(self.drawings.box, "Color", self.value and self.window.theme.ToggleEnabled or self.window.theme.Toggle)
	end

	function control:refreshVisibility()
		writeProperty(self.drawings.box, "Visible", self.visible and self.window.visible)
		writeProperty(self.drawings.outline, "Visible", self.visible and self.window.visible)
		writeProperty(self.drawings.text, "Visible", self.visible and self.window.visible)
		self:applyValue()
	end

	function control:layout()
		local boxPosition = self.position + Vector2.new(0, 4)

		writeProperty(self.drawings.box, "Position", boxPosition)
		writeProperty(self.drawings.outline, "Position", boxPosition)
		writeProperty(self.drawings.mark, "Position", boxPosition + Vector2.new(4, 4))
		writeProperty(self.drawings.text, "Position", self.position + Vector2.new(28, 4))
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.box, "ZIndex", z)
		writeProperty(self.drawings.mark, "ZIndex", z + 1)
		writeProperty(self.drawings.outline, "ZIndex", z + 2)
		writeProperty(self.drawings.text, "ZIndex", z + 3)
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
		self:applyValue()
		self.callback(self.value)
	end

	function control:onStep(mousePosition, ownsHover)
		self.hovered = ownsHover and self:hitTest(mousePosition)
		writeProperty(self.drawings.outline, "Color", self.hovered and self.window.theme.Accent or self.window.theme.Border)
	end

	function control:SetValue(nextValue)
		self.value = nextValue == true
		self:applyValue()
	end

	function control:destroy()
		for _, drawing in pairs(self.drawings) do
			destroyDrawing(drawing)
		end
	end

	control:applyValue()
	return addControl(window, control)
end

local function addSlider(window, text, minimum, maximum, initialValue, callback)
	local control = makeBaseControl(window, "Slider", SLIDER_HEIGHT)
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
		Size = 13,
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
		local fillWidth = math.floor(barWidth * alpha)

		writeProperty(self.drawings.track, "Position", barPosition)
		writeProperty(self.drawings.track, "Size", Vector2.new(barWidth, 6))
		writeProperty(self.drawings.fill, "Position", barPosition)
		writeProperty(self.drawings.fill, "Size", Vector2.new(fillWidth, 6))
		writeProperty(self.drawings.knob, "Position", barPosition + Vector2.new(fillWidth, 3))
		writeProperty(self.drawings.value, "Text", string.format("%.2f", self.value))
	end

	function control:setFromMouse(mousePosition)
		local startX = self.position.X
		local alpha = clamp((mousePosition.X - startX) / self.size.X, 0, 1)
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
		writeProperty(self.drawings.value, "Position", self.position + Vector2.new(self.size.X - 44, 0))
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
		local knobColor = (hovered or self.dragging) and self.window.theme.Accent or self.window.theme.Text
		writeProperty(self.drawings.knob, "Color", knobColor)
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

	return addControl(window, control)
end

function Window:AddLabel(text)
	return addLabel(self, text)
end

function Window:AddSection(text)
	return addSection(self, text)
end

function Window:AddButton(text, callback)
	return addButton(self, text, callback)
end

function Window:AddToggle(text, initialValue, callback)
	return addToggle(self, text, initialValue, callback)
end

function Window:AddSlider(text, minimum, maximum, initialValue, callback)
	return addSlider(self, text, minimum, maximum, initialValue, callback)
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
	self.position = config.Position
	self.size = config.Size
	self.visible = config.Visible
	self.theme = mergeTheme(config.Theme)
	self.controls = {}
	self.dragging = false
	self.dragOffset = Vector2.zero
	self.zBase = 100 + (#windows * 20)

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
			Text = "drag me",
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
