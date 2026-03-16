local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local DrawingUI = {}
DrawingUI.__index = DrawingUI

local VERSION = "2.0.0"

local DEFAULT_THEME = {
	Accent = Color3.fromRGB(74, 196, 255),
	AccentSoft = Color3.fromRGB(46, 121, 168),
	WindowBackground = Color3.fromRGB(12, 16, 22),
	HeaderBackground = Color3.fromRGB(18, 24, 31),
	CanvasBackground = Color3.fromRGB(10, 13, 18),
	SidebarBackground = Color3.fromRGB(14, 18, 24),
	AsideBackground = Color3.fromRGB(15, 19, 26),
	Card = Color3.fromRGB(20, 26, 34),
	CardHover = Color3.fromRGB(24, 31, 40),
	Panel = Color3.fromRGB(17, 23, 30),
	PanelHeader = Color3.fromRGB(22, 28, 37),
	Input = Color3.fromRGB(13, 18, 25),
	InputHover = Color3.fromRGB(18, 24, 32),
	InputFocused = Color3.fromRGB(21, 29, 39),
	Button = Color3.fromRGB(24, 31, 40),
	ButtonHover = Color3.fromRGB(30, 39, 50),
	Border = Color3.fromRGB(47, 60, 74),
	InnerBorder = Color3.fromRGB(28, 36, 45),
	SoftBorder = Color3.fromRGB(34, 44, 55),
	Shadow = Color3.fromRGB(5, 8, 12),
	Text = Color3.fromRGB(241, 247, 252),
	SubText = Color3.fromRGB(163, 178, 192),
	Muted = Color3.fromRGB(118, 131, 143),
	HighlightText = Color3.fromRGB(168, 220, 255),
	Nav = Color3.fromRGB(16, 21, 28),
	NavHover = Color3.fromRGB(23, 30, 39),
	NavActive = Color3.fromRGB(31, 44, 58),
	NavText = Color3.fromRGB(229, 237, 244),
	Toggle = Color3.fromRGB(37, 47, 58),
	ToggleEnabled = Color3.fromRGB(74, 196, 255),
	SliderTrack = Color3.fromRGB(35, 45, 56),
	SliderFill = Color3.fromRGB(74, 196, 255),
	SectionLine = Color3.fromRGB(36, 48, 60),
	Success = Color3.fromRGB(97, 211, 143),
	Warning = Color3.fromRGB(255, 196, 92),
	Danger = Color3.fromRGB(255, 109, 109),
	Font = 2,
	TitleFont = 3,
	AppTitleSize = 22,
	TitleSize = 18,
	SectionTitleSize = 14,
	TextSize = 13,
	SmallTextSize = 11,
}

local THEMES = {
	Default = {},
	Amber = {
		Accent = Color3.fromRGB(255, 165, 73),
		AccentSoft = Color3.fromRGB(169, 98, 38),
		HeaderBackground = Color3.fromRGB(27, 22, 17),
		SidebarBackground = Color3.fromRGB(19, 15, 12),
		Card = Color3.fromRGB(28, 22, 18),
		CardHover = Color3.fromRGB(34, 27, 21),
		ButtonHover = Color3.fromRGB(44, 33, 25),
		InputFocused = Color3.fromRGB(41, 28, 20),
		ToggleEnabled = Color3.fromRGB(255, 165, 73),
		SliderFill = Color3.fromRGB(255, 165, 73),
		HighlightText = Color3.fromRGB(255, 226, 164),
	},
	Midnight = {
		Accent = Color3.fromRGB(124, 164, 255),
		AccentSoft = Color3.fromRGB(78, 112, 190),
		WindowBackground = Color3.fromRGB(9, 11, 18),
		HeaderBackground = Color3.fromRGB(13, 16, 25),
		CanvasBackground = Color3.fromRGB(7, 9, 15),
		SidebarBackground = Color3.fromRGB(11, 14, 23),
		Card = Color3.fromRGB(17, 20, 31),
		CardHover = Color3.fromRGB(21, 26, 38),
		Input = Color3.fromRGB(11, 14, 23),
		InputFocused = Color3.fromRGB(17, 21, 32),
		Border = Color3.fromRGB(48, 58, 83),
		InnerBorder = Color3.fromRGB(28, 34, 48),
	},
	Circuit = {
		Accent = Color3.fromRGB(67, 224, 255),
		AccentSoft = Color3.fromRGB(36, 118, 145),
		WindowBackground = Color3.fromRGB(11, 16, 20),
		HeaderBackground = Color3.fromRGB(15, 23, 29),
		CanvasBackground = Color3.fromRGB(8, 12, 16),
		SidebarBackground = Color3.fromRGB(10, 17, 22),
		Card = Color3.fromRGB(16, 24, 31),
		CardHover = Color3.fromRGB(21, 30, 38),
		Border = Color3.fromRGB(45, 70, 81),
		InnerBorder = Color3.fromRGB(24, 38, 46),
		HighlightText = Color3.fromRGB(165, 237, 255),
	},
}

local DEFAULT_OPTIONS = {
	Title = "Drawing UI",
	Position = nil,
	Size = nil,
	MinSize = Vector2.new(860, 560),
	Visible = true,
	DragAnywhere = false,
	Theme = nil,
	ConfigRoot = "drawing-ui-lib-configs",
	ConfigId = nil,
	Density = "comfortable",
	MotionMode = "full",
}

local DENSITY = {
	comfortable = {
		cardPadding = 18,
		cardGap = 18,
		itemGap = 14,
		groupGap = 12,
		rowHeight = 34,
		inputHeight = 34,
		headerInset = 18,
	},
	compact = {
		cardPadding = 14,
		cardGap = 14,
		itemGap = 11,
		groupGap = 10,
		rowHeight = 30,
		inputHeight = 30,
		headerInset = 14,
	},
}

local MOTION_TOKENS = {
	micro = 0.09,
	fast = 0.14,
	standard = 0.18,
	emphasized = 0.24,
	panel = 0.30,
	open = 0.22,
}

local SHELL = {
	HeaderHeight = 56,
	SidebarWidth = 248,
	SidebarCollapsedWidth = 68,
	AsideWidth = 280,
	OuterPadding = 24,
	GridGap = 16,
	MinWidth = 860,
	MinHeight = 560,
	ResizeEdge = 8,
	NavItemHeight = 40,
	TopActionHeight = 30,
}

local apps = {}
local frameConnection
local inputBeganConnection
local inputChangedConnection
local inputEndedConnection
local activeTextbox
local listeningKeybind
local inputBlockBound = false

local App = {}
App.__index = App

local Page = {}
Page.__index = Page

local Section = {}
Section.__index = Section

local Group = {}
Group.__index = Group

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function lerp(a, b, alpha)
	return a + ((b - a) * alpha)
end

local function colorLerp(a, b, alpha)
	return Color3.new(
		lerp(a.R, b.R, alpha),
		lerp(a.G, b.G, alpha),
		lerp(a.B, b.B, alpha)
	)
end

local function round(value)
	return math.floor(value + 0.5)
end

local function shallowCopy(source)
	local target = {}
	for key, value in pairs(source or {}) do
		target[key] = value
	end
	return target
end

local function mergeTheme(overrides)
	local theme = shallowCopy(DEFAULT_THEME)
	for key, value in pairs(overrides or {}) do
		theme[key] = value
	end
	return theme
end

local function getViewportSize()
	local camera = Workspace.CurrentCamera
	if camera ~= nil then
		return camera.ViewportSize
	end
	return Vector2.new(1280, 720)
end

local function computeDefaultSize()
	local viewport = getViewportSize()
	return Vector2.new(
		clamp(math.floor(viewport.X * 0.72), 920, 1180),
		clamp(math.floor(viewport.Y * 0.74), 600, 760)
	)
end

local function computeDefaultPosition(size)
	local viewport = getViewportSize()
	return Vector2.new(
		math.floor((viewport.X - size.X) * 0.5),
		math.floor((viewport.Y - size.Y) * 0.5)
	)
end

local function sanitizeFileName(name)
	local value = tostring(name or "config")
	value = value:gsub("[<>:\"/\\|%?%*]", "-")
	value = value:gsub("^%s+", ""):gsub("%s+$", "")
	return value ~= "" and value or "config"
end

local function hasFilesystem()
	return typeof(writefile) == "function"
		and typeof(readfile) == "function"
		and typeof(isfile) == "function"
		and typeof(makefolder) == "function"
		and typeof(isfolder) == "function"
		and typeof(listfiles) == "function"
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

local function setDrawingVisibility(drawing, visible, transparency)
	writeProperty(drawing, "Visible", visible)
	if transparency ~= nil then
		writeProperty(drawing, "Transparency", transparency)
	end
end

local function pointInRect(point, position, size)
	return point.X >= position.X
		and point.X <= position.X + size.X
		and point.Y >= position.Y
		and point.Y <= position.Y + size.Y
end

local function pointInBounds(point, bounds)
	return pointInRect(point, bounds.position, bounds.size)
end

local function getMousePosition()
	return UserInputService:GetMouseLocation()
end

local function fitDrawingText(drawing, text, maxWidth)
	local value = tostring(text or "")
	writeProperty(drawing, "Text", value)
	if maxWidth == nil or drawing.TextBounds.X <= maxWidth then
		return value
	end

	local ellipsis = "..."
	for length = #value - 1, 0, -1 do
		local candidate = string.sub(value, 1, length) .. ellipsis
		writeProperty(drawing, "Text", candidate)
		if drawing.TextBounds.X <= maxWidth then
			return candidate
		end
	end

	writeProperty(drawing, "Text", ellipsis)
	return ellipsis
end

local function wrapText(text, maxCharacters)
	local value = tostring(text or "")
	if value == "" then
		return { "" }
	end

	local lines = {}
	local current = ""

	for word in value:gmatch("%S+") do
		if current == "" then
			current = word
		elseif #current + 1 + #word <= maxCharacters then
			current = current .. " " .. word
		else
			table.insert(lines, current)
			current = word
		end
	end

	if current ~= "" then
		table.insert(lines, current)
	end

	if #lines == 0 then
		table.insert(lines, "")
	end

	return lines
end

local function animateToward(current, target, duration, dt)
	if duration <= 0 then
		return target
	end
	local alpha = clamp(dt / duration, 0, 1)
	local nextValue = lerp(current, target, alpha)
	if math.abs(nextValue - target) < 0.001 then
		return target
	end
	return nextValue
end

local function getMotionDuration(app, token)
	if app.motionMode == "off" then
		return 0
	end
	if app.motionMode == "reduced" then
		if token == "panel" or token == "emphasized" then
			return MOTION_TOKENS.fast
		end
		return MOTION_TOKENS.micro
	end
	return MOTION_TOKENS[token] or MOTION_TOKENS.standard
end

local function shouldUseTranslation(app)
	return app.motionMode == "full"
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
	elseif name == "MouseButton3" then
		return "Mouse3"
	end

	return name
end

local function formatInputBinding(binding)
	if binding == nil then
		return "NONE"
	end

	if binding.kind == "Keyboard" then
		return formatKeyCode(binding.code)
	end

	if binding.kind == "MouseButton1" then
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
		if input.KeyCode == Enum.KeyCode.Unknown then
			return nil
		end
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

local function serializeInputBinding(binding)
	if binding == nil then
		return nil
	end

	if binding.kind == "Keyboard" then
		return {
			kind = "Keyboard",
			code = binding.code and binding.code.Name or nil,
		}
	end

	if binding.kind == "MouseButton1" or binding.kind == "MouseButton2" or binding.kind == "MouseButton3" then
		return {
			kind = binding.kind,
		}
	end

	return nil
end

local function deserializeInputBinding(value)
	if value == nil then
		return nil
	end

	if typeof(value) == "EnumItem" then
		return {
			kind = "Keyboard",
			code = value,
		}
	end

	if type(value) ~= "table" then
		return nil
	end

	if value.kind == "Keyboard" and type(value.code) == "string" and Enum.KeyCode[value.code] ~= nil then
		return {
			kind = "Keyboard",
			code = Enum.KeyCode[value.code],
		}
	end

	if value.kind == "MouseButton1" or value.kind == "MouseButton2" or value.kind == "MouseButton3" then
		return { kind = value.kind }
	end

	return nil
end

local function clearTextboxFocus(submit)
	if activeTextbox ~= nil then
		activeTextbox:Blur(submit)
		activeTextbox = nil
	end
end

local function clearKeybindListening()
	if listeningKeybind ~= nil then
		listeningKeybind:SetListening(false)
		listeningKeybind = nil
	end
end

local function shouldBlockGameInput()
	return activeTextbox ~= nil or listeningKeybind ~= nil
end

local function updateInputBlocker()
	if shouldBlockGameInput() then
		if inputBlockBound then
			return
		end

		ContextActionService:BindActionAtPriority(
			"DrawingUIInputBlock",
			function(_, inputState, inputObject)
				if inputState ~= Enum.UserInputState.Begin then
					return Enum.ContextActionResult.Pass
				end

				if inputObject.UserInputType == Enum.UserInputType.MouseButton1
					or inputObject.UserInputType == Enum.UserInputType.MouseButton2
					or inputObject.UserInputType == Enum.UserInputType.MouseButton3
					or inputObject.UserInputType == Enum.UserInputType.Keyboard
				then
					return Enum.ContextActionResult.Sink
				end

				return Enum.ContextActionResult.Pass
			end,
			false,
			3100,
			Enum.UserInputType.MouseButton1,
			Enum.UserInputType.MouseButton2,
			Enum.UserInputType.MouseButton3,
			Enum.UserInputType.Keyboard
		)
		inputBlockBound = true
	else
		if not inputBlockBound then
			return
		end
		ContextActionService:UnbindAction("DrawingUIInputBlock")
		inputBlockBound = false
	end
end

local function bringAppToFront(app)
	for index, candidate in ipairs(apps) do
		if candidate == app then
			table.remove(apps, index)
			break
		end
	end

	table.insert(apps, app)

	for index, candidate in ipairs(apps) do
		candidate.zBase = 100 + ((index - 1) * 500)
		if candidate.RefreshZIndex ~= nil then
			candidate:RefreshZIndex()
		end
	end
end

local function destroyDrawings(drawings)
	for _, drawing in pairs(drawings) do
		destroyDrawing(drawing)
	end
end

local function setItemVisibility(item, visible)
	if item.drawings ~= nil then
		for _, drawing in pairs(item.drawings) do
			writeProperty(drawing, "Visible", visible)
		end
	end
	if item.optionDrawings ~= nil then
		for _, row in ipairs(item.optionDrawings) do
			writeProperty(row.frame, "Visible", visible)
			writeProperty(row.outline, "Visible", visible)
			writeProperty(row.text, "Visible", visible)
			if row.check ~= nil then
				writeProperty(row.check, "Visible", visible)
			end
		end
	end
	if item.svCells ~= nil then
		for _, cell in ipairs(item.svCells) do
			writeProperty(cell, "Visible", visible)
		end
	end
	if item.hueCells ~= nil then
		for _, cell in ipairs(item.hueCells) do
			writeProperty(cell, "Visible", visible)
		end
	end
	if item.buttons ~= nil then
		for _, button in ipairs(item.buttons) do
			writeProperty(button.frame, "Visible", visible)
			writeProperty(button.outline, "Visible", visible)
			writeProperty(button.textDrawing, "Visible", visible)
		end
	end
	if item.items ~= nil then
		for _, child in ipairs(item.items) do
			setItemVisibility(child, visible)
		end
	end
end

local function makeRect(position, size)
	return {
		position = position,
		size = size,
	}
end

local function topAppAt(point)
	for index = #apps, 1, -1 do
		local app = apps[index]
		if app.visible and app:HasPoint(point) then
			return app
		end
	end
	return nil
end

local function makeBaseControl(host, kind, height)
	local control = {
		host = host,
		app = host.app,
		page = host.page,
		kind = kind,
		height = height,
		drawings = {},
		visible = true,
		alpha = 1,
		position = Vector2.zero,
		size = Vector2.zero,
		hovered = false,
		configKey = nil,
	}

	function control:IsDisplayed()
		return self.visible and self.host:IsDisplayed()
	end

	function control:GetHeight()
		return self.height
	end

	function control:setZIndex(z)
		for _, drawing in pairs(self.drawings) do
			writeProperty(drawing, "ZIndex", z)
		end
	end

	function control:destroy()
		destroyDrawings(self.drawings)
	end

return control
end

local function addHostChild(host, child)
	table.insert(host.items, child)
	host:MarkLayoutDirty()
	return child
end

local function getItemGap(host)
	return host.app.density.itemGap
end

local function addLabel(host, text)
	local control = makeBaseControl(host, "Label", host.app.theme.TextSize + 6)
	control.text = tostring(text or "")

	control.drawings.text = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.SubText,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Outline = false,
		Text = control.text,
		Position = Vector2.zero,
		Transparency = 1,
	})

	function control:layout()
		local fitted = fitDrawingText(self.drawings.text, self.text, self.size.X)
		self.height = self.drawings.text.TextBounds.Y + 2
		writeProperty(self.drawings.text, "Text", fitted)
		writeProperty(self.drawings.text, "Position", self.position)
	end

	function control:applyTheme()
		writeProperty(self.drawings.text, "Color", self.app.theme.SubText)
		writeProperty(self.drawings.text, "Size", self.app.theme.TextSize)
		writeProperty(self.drawings.text, "Font", self.app.theme.Font)
	end

	function control:SetText(nextText)
		self.text = tostring(nextText or "")
		self.app:MarkLayoutDirty()
	end

	control:applyTheme()
	return addHostChild(host, control)
end

local function addParagraph(host, title, text)
	local control = makeBaseControl(host, "Paragraph", 0)
	control.title = tostring(title or "")
	control.body = tostring(text or "")

	control.drawings.title = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.Text,
		Size = host.app.theme.SectionTitleSize,
		Font = host.app.theme.Font,
		Outline = false,
		Text = control.title,
		Position = Vector2.zero,
		Transparency = 1,
	})

	control.drawings.body = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.SubText,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Outline = false,
		Text = control.body,
		Position = Vector2.zero,
		Transparency = 1,
	})

	function control:layout()
		local bodyLines = wrapText(self.body, math.max(20, math.floor(self.size.X / 7.2)))
		writeProperty(self.drawings.title, "Position", self.position)
		writeProperty(self.drawings.body, "Text", table.concat(bodyLines, "\n"))
		writeProperty(self.drawings.body, "Position", self.position + Vector2.new(0, 18))
		self.height = 18 + self.drawings.body.TextBounds.Y + 4
	end

	function control:applyTheme()
		writeProperty(self.drawings.title, "Color", self.app.theme.Text)
		writeProperty(self.drawings.body, "Color", self.app.theme.SubText)
		writeProperty(self.drawings.title, "Size", self.app.theme.SectionTitleSize)
		writeProperty(self.drawings.body, "Size", self.app.theme.TextSize)
	end

	function control:SetText(nextText)
		self.body = tostring(nextText or "")
		self.app:MarkLayoutDirty()
	end

	control:applyTheme()
	return addHostChild(host, control)
end

local function addInlineSectionLabel(host, text)
	local control = makeBaseControl(host, "InlineSection", 20)
	control.text = tostring(text or "")

	control.drawings.text = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.HighlightText,
		Size = host.app.theme.SectionTitleSize,
		Font = host.app.theme.Font,
		Outline = false,
		Text = control.text,
		Position = Vector2.zero,
		Transparency = 1,
	})

	control.drawings.line = createDrawing("Line", {
		Visible = true,
		Color = host.app.theme.SectionLine,
		Thickness = 1,
		From = Vector2.zero,
		To = Vector2.zero,
		Transparency = 1,
	})

	function control:layout()
		writeProperty(self.drawings.text, "Position", self.position)
		local textWidth = self.drawings.text.TextBounds.X
		local lineY = self.position.Y + 9
		writeProperty(self.drawings.line, "From", Vector2.new(self.position.X + textWidth + 12, lineY))
		writeProperty(self.drawings.line, "To", Vector2.new(self.position.X + self.size.X, lineY))
	end

	function control:applyTheme()
		writeProperty(self.drawings.text, "Color", self.app.theme.HighlightText)
		writeProperty(self.drawings.text, "Size", self.app.theme.SectionTitleSize)
		writeProperty(self.drawings.line, "Color", self.app.theme.SectionLine)
	end

	control:applyTheme()
	return addHostChild(host, control)
end

local function addButton(host, text, callback)
	local control = makeBaseControl(host, "Button", host.app.density.rowHeight)
	control.text = tostring(text or "")
	control.callback = callback or function() end
	control.activationBinding = nil
	control.blocksWindowDrag = true

	control.drawings.frame = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = host.app.theme.Button,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.outline = createDrawing("Square", {
		Visible = true,
		Filled = false,
		Color = host.app.theme.Border,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.text = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.Text,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = control.text,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})

	function control:layout()
		writeProperty(self.drawings.frame, "Position", self.position)
		writeProperty(self.drawings.frame, "Size", self.size)
		writeProperty(self.drawings.outline, "Position", self.position)
		writeProperty(self.drawings.outline, "Size", self.size)
		local fitted = fitDrawingText(self.drawings.text, self.text, self.size.X - 20)
		writeProperty(self.drawings.text, "Text", fitted)
		writeProperty(self.drawings.text, "Position", self.position + Vector2.new(10, math.floor((self.size.Y - self.drawings.text.TextBounds.Y) * 0.5)))
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
		if self.pressing and self:hitTest(point) then
			self:TriggerActivation()
		end
		self.pressing = false
	end

	function control:TriggerActivation()
		self.callback()
	end

	function control:onStep(mousePosition, _, dt)
		self.hovered = self:IsDisplayed() and self:hitTest(mousePosition)
		self.hoverAlpha = animateToward(self.hoverAlpha or 0, (self.hovered or self.pressing) and 1 or 0, getMotionDuration(self.app, "fast"), dt)
		writeProperty(self.drawings.frame, "Color", colorLerp(self.app.theme.Button, self.app.theme.ButtonHover, self.hoverAlpha))
		writeProperty(self.drawings.outline, "Color", self.hoverAlpha > 0.2 and colorLerp(self.app.theme.Border, self.app.theme.AccentSoft, self.hoverAlpha * 0.4) or self.app.theme.Border)
	end

	function control:applyTheme()
		writeProperty(self.drawings.text, "Color", self.app.theme.Text)
		writeProperty(self.drawings.frame, "Color", self.app.theme.Button)
		writeProperty(self.drawings.outline, "Color", self.app.theme.Border)
	end

	function control:SetText(nextText)
		self.text = tostring(nextText or "")
		self.app:MarkLayoutDirty()
	end

	function control:SetActivationBinding(binding)
		self.activationBinding = binding
	end

	control:applyTheme()
	table.insert(host.app.boundControls, control)
	return addHostChild(host, control)
end

local function addButtonRow(host, buttons)
	local height = host.app.density.rowHeight
	local control = makeBaseControl(host, "ButtonRow", height)
	control.buttons = {}
	control.blocksWindowDrag = true

	for index, definition in ipairs(buttons or {}) do
		control.buttons[index] = {
			text = tostring(definition.text or ("Button " .. index)),
			callback = definition.callback or function() end,
			frame = createDrawing("Square", {
				Visible = true,
				Filled = true,
				Color = host.app.theme.Button,
				Position = Vector2.zero,
				Size = Vector2.zero,
				Transparency = 1,
			}),
			outline = createDrawing("Square", {
				Visible = true,
				Filled = false,
				Color = host.app.theme.Border,
				Position = Vector2.zero,
				Size = Vector2.zero,
				Transparency = 1,
			}),
			textDrawing = createDrawing("Text", {
				Visible = true,
				Color = host.app.theme.Text,
				Size = host.app.theme.TextSize,
				Font = host.app.theme.Font,
				Text = tostring(definition.text or ("Button " .. index)),
				Position = Vector2.zero,
				Outline = false,
				Transparency = 1,
			}),
			hoverAlpha = 0,
		}
	end

	function control:getButtonRect(index)
		local count = math.max(1, #self.buttons)
		local gap = 10
		local width = (self.size.X - ((count - 1) * gap)) / count
		return self.position + Vector2.new((index - 1) * (width + gap), 0), Vector2.new(width, self.size.Y)
	end

	function control:layout()
		for index, button in ipairs(self.buttons) do
			local position, size = self:getButtonRect(index)
			writeProperty(button.frame, "Position", position)
			writeProperty(button.frame, "Size", size)
			writeProperty(button.outline, "Position", position)
			writeProperty(button.outline, "Size", size)
			fitDrawingText(button.textDrawing, button.text, size.X - 20)
			writeProperty(button.textDrawing, "Position", position + Vector2.new(10, math.floor((size.Y - button.textDrawing.TextBounds.Y) * 0.5)))
		end
	end

	function control:hitTest(point)
		for index, _ in ipairs(self.buttons) do
			local position, size = self:getButtonRect(index)
			if pointInRect(point, position, size) then
				return index
			end
		end
		return nil
	end

	function control:onMouseDown(point)
		self.pressedIndex = self:hitTest(point)
	end

	function control:onMouseUp(point)
		local index = self:hitTest(point)
		if self.pressedIndex ~= nil and self.pressedIndex == index then
			self.buttons[index].callback()
		end
		self.pressedIndex = nil
	end

	function control:onStep(mousePosition, _, dt)
		local hoveredIndex = self:IsDisplayed() and self:hitTest(mousePosition) or nil
		for index, button in ipairs(self.buttons) do
			button.hoverAlpha = animateToward(button.hoverAlpha, hoveredIndex == index and 1 or 0, getMotionDuration(self.app, "fast"), dt)
			writeProperty(button.frame, "Color", colorLerp(self.app.theme.Button, self.app.theme.ButtonHover, button.hoverAlpha))
			writeProperty(button.outline, "Color", button.hoverAlpha > 0.2 and colorLerp(self.app.theme.Border, self.app.theme.AccentSoft, button.hoverAlpha * 0.4) or self.app.theme.Border)
		end
	end

	function control:applyTheme()
		for _, button in ipairs(self.buttons) do
			writeProperty(button.textDrawing, "Color", self.app.theme.Text)
			writeProperty(button.frame, "Color", self.app.theme.Button)
			writeProperty(button.outline, "Color", self.app.theme.Border)
		end
	end

	function control:setZIndex(z)
		for _, button in ipairs(self.buttons) do
			writeProperty(button.frame, "ZIndex", z)
			writeProperty(button.outline, "ZIndex", z + 1)
			writeProperty(button.textDrawing, "ZIndex", z + 2)
		end
	end

	function control:destroy()
		for _, button in ipairs(self.buttons) do
			destroyDrawing(button.frame)
			destroyDrawing(button.outline)
			destroyDrawing(button.textDrawing)
		end
	end

	control:applyTheme()
	return addHostChild(host, control)
end

local function addToggle(host, text, initialValue, callback)
	local control = makeBaseControl(host, "Toggle", host.app.density.rowHeight)
	control.text = tostring(text or "")
	control.value = initialValue == true
	control.callback = callback or function() end
	control.configKey = control.text
	control.blocksWindowDrag = true

	control.drawings.label = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.Text,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = control.text,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	control.drawings.state = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.SubText,
		Size = host.app.theme.SmallTextSize,
		Font = host.app.theme.Font,
		Text = control.value and "ON" or "OFF",
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	control.drawings.track = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = host.app.theme.Toggle,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.knob = createDrawing("Circle", {
		Visible = true,
		Filled = true,
		Color = Color3.fromRGB(245, 248, 252),
		Radius = 7,
		Position = Vector2.zero,
		NumSides = 18,
		Transparency = 1,
	})

	control.toggleAlpha = control.value and 1 or 0

	function control:layout()
		writeProperty(self.drawings.label, "Position", self.position + Vector2.new(0, 2))
		writeProperty(self.drawings.state, "Position", self.position + Vector2.new(self.size.X - 74, 4))
		local trackSize = Vector2.new(38, 16)
		local trackPosition = self.position + Vector2.new(self.size.X - trackSize.X, 1)
		writeProperty(self.drawings.track, "Position", trackPosition)
		writeProperty(self.drawings.track, "Size", trackSize)
	end

	function control:updateVisuals()
		local trackPosition = self.position + Vector2.new(self.size.X - 38, 1)
		local knobX = lerp(trackPosition.X + 8, trackPosition.X + 30, self.toggleAlpha)
		writeProperty(self.drawings.knob, "Position", Vector2.new(knobX, trackPosition.Y + 8))
		writeProperty(self.drawings.track, "Color", colorLerp(self.app.theme.Toggle, self.app.theme.ToggleEnabled, self.toggleAlpha))
		writeProperty(self.drawings.state, "Color", colorLerp(self.app.theme.SubText, self.app.theme.Accent, self.toggleAlpha))
		writeProperty(self.drawings.state, "Text", self.value and "ON" or "OFF")
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
		if self.pressing and self:hitTest(point) then
			self:SetValue(not self.value)
			self.callback(self.value)
		end
		self.pressing = false
	end

	function control:onStep(_, _, dt)
		self.toggleAlpha = animateToward(self.toggleAlpha, self.value and 1 or 0, getMotionDuration(self.app, "standard"), dt)
		self:updateVisuals()
	end

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.app.theme.Text)
		writeProperty(self.drawings.state, "Color", self.app.theme.SubText)
		writeProperty(self.drawings.track, "Color", self.app.theme.Toggle)
	end

	function control:SetValue(nextValue)
		self.value = nextValue == true
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

	control:applyTheme()
	return addHostChild(host, control)
end

local function addSlider(host, text, minimum, maximum, initialValue, callback)
	local control = makeBaseControl(host, "Slider", host.app.density.rowHeight + 16)
	control.text = tostring(text or "")
	control.minimum = tonumber(minimum) or 0
	control.maximum = tonumber(maximum) or 100
	control.value = clamp(tonumber(initialValue) or control.minimum, control.minimum, control.maximum)
	control.displayValue = control.value
	control.callback = callback or function() end
	control.configKey = control.text
	control.blocksWindowDrag = true

	control.drawings.label = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.Text,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = control.text,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	control.drawings.value = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.SubText,
		Size = host.app.theme.SmallTextSize,
		Font = host.app.theme.Font,
		Text = tostring(control.value),
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	control.drawings.track = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = host.app.theme.SliderTrack,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.fill = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = host.app.theme.SliderFill,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.knob = createDrawing("Circle", {
		Visible = true,
		Filled = true,
		Color = host.app.theme.Text,
		Position = Vector2.zero,
		Radius = 6,
		NumSides = 18,
		Transparency = 1,
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
		local barPosition = self.position + Vector2.new(0, self.app.theme.TextSize + 8)
		local alpha = self:getDisplayAlpha()
		local fillWidth = round(self.size.X * alpha)
		writeProperty(self.drawings.track, "Position", barPosition)
		writeProperty(self.drawings.track, "Size", Vector2.new(self.size.X, 6))
		writeProperty(self.drawings.fill, "Position", barPosition)
		writeProperty(self.drawings.fill, "Size", Vector2.new(fillWidth, 6))
		writeProperty(self.drawings.knob, "Position", Vector2.new(barPosition.X + fillWidth, barPosition.Y + 3))
		writeProperty(self.drawings.value, "Text", string.format("%.2f", self.value))
	end

	function control:layout()
		writeProperty(self.drawings.label, "Position", self.position)
		writeProperty(self.drawings.value, "Position", self.position + Vector2.new(self.size.X - 64, 1))
		self:updateVisuals()
	end

	function control:setFromMouse(mousePosition)
		local alpha = clamp((mousePosition.X - self.position.X) / math.max(1, self.size.X), 0, 1)
		local nextValue = lerp(self.minimum, self.maximum, alpha)
		if math.abs(nextValue - self.value) > 0.0001 then
			self.value = nextValue
			self.callback(self.value)
		end
	end

	function control:hitTest(point)
		return pointInRect(point, self.position, Vector2.new(self.size.X, self.size.Y))
	end

	function control:onMouseDown(point)
		if self:hitTest(point) then
			self.dragging = true
			self:setFromMouse(point)
			self:updateVisuals()
		end
	end

	function control:onMouseUp()
		self.dragging = false
	end

	function control:onStep(mousePosition, _, dt)
		if self.dragging then
			self:setFromMouse(mousePosition)
		end
		local token = self.dragging and "emphasized" or "standard"
		self.displayValue = animateToward(self.displayValue, self.value, getMotionDuration(self.app, token), dt)
		if math.abs(self.displayValue - self.value) < 0.001 then
			self.displayValue = self.value
		end
		self:updateVisuals()
	end

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.app.theme.Text)
		writeProperty(self.drawings.value, "Color", self.app.theme.SubText)
		writeProperty(self.drawings.track, "Color", self.app.theme.SliderTrack)
		writeProperty(self.drawings.fill, "Color", self.app.theme.SliderFill)
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

	control:applyTheme()
	return addHostChild(host, control)
end

local function createChoiceOverlay(control)
	control.optionDrawings = control.optionDrawings or {}
	for _, row in ipairs(control.optionDrawings) do
		destroyDrawing(row.frame)
		destroyDrawing(row.outline)
		destroyDrawing(row.text)
		if row.check ~= nil then
			destroyDrawing(row.check)
		end
	end
	control.optionDrawings = {}

	for _, option in ipairs(control.options) do
		local row = {
			frame = createDrawing("Square", {
				Visible = false,
				Filled = true,
				Color = control.app.theme.Input,
				Position = Vector2.zero,
				Size = Vector2.zero,
				Transparency = 1,
			}),
			outline = createDrawing("Square", {
				Visible = false,
				Filled = false,
				Color = control.app.theme.Border,
				Position = Vector2.zero,
				Size = Vector2.zero,
				Transparency = 1,
			}),
			text = createDrawing("Text", {
				Visible = false,
				Color = control.app.theme.Text,
				Size = control.app.theme.TextSize,
				Font = control.app.theme.Font,
				Text = tostring(option),
				Position = Vector2.zero,
				Outline = false,
				Transparency = 1,
			}),
		}
		table.insert(control.optionDrawings, row)
	end
end

local function getOverlayBaseRect(control)
	return makeRect(control.position + Vector2.new(0, control.app.theme.TextSize + 6), Vector2.new(control.size.X, control.app.density.inputHeight))
end

local function addDropdown(host, text, options, defaultValue, callback)
	local control = makeBaseControl(host, "Dropdown", host.app.theme.TextSize + 6 + host.app.density.inputHeight)
	control.text = tostring(text or "")
	control.options = table.clone(options or {})
	control.value = defaultValue or control.options[1] or "Select"
	control.callback = callback or function() end
	control.configKey = control.text
	control.open = false
	control.openAlpha = 0
	control.hoverIndex = nil
	control.blocksWindowDrag = true
	control.isDropdown = true

	control.drawings.label = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.Text,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = control.text,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	control.drawings.frame = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = host.app.theme.Input,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.outline = createDrawing("Square", {
		Visible = true,
		Filled = false,
		Color = host.app.theme.Border,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.value = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.SubText,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = tostring(control.value),
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	control.drawings.arrow = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.SubText,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = "v",
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})

	createChoiceOverlay(control)

	function control:getOptionHeight()
		return self.app.density.inputHeight - 4
	end

	function control:getOverlayRect()
		local baseRect = getOverlayBaseRect(self)
		local visibleRows = math.max(0, round(#self.options * self.openAlpha))
		return makeRect(
			baseRect.position + Vector2.new(0, baseRect.size.Y + 8),
			Vector2.new(baseRect.size.X, visibleRows * self:getOptionHeight())
		)
	end

	function control:layout()
		writeProperty(self.drawings.label, "Position", self.position)
		local baseRect = getOverlayBaseRect(self)
		writeProperty(self.drawings.frame, "Position", baseRect.position)
		writeProperty(self.drawings.frame, "Size", baseRect.size)
		writeProperty(self.drawings.outline, "Position", baseRect.position)
		writeProperty(self.drawings.outline, "Size", baseRect.size)
		fitDrawingText(self.drawings.value, tostring(self.value), baseRect.size.X - 36)
		writeProperty(self.drawings.value, "Position", baseRect.position + Vector2.new(10, 7))
		writeProperty(self.drawings.arrow, "Position", baseRect.position + Vector2.new(baseRect.size.X - 18, 7))
		self:layoutOverlay()
	end

	function control:layoutOverlay()
		local overlayRect = self:getOverlayRect()
		local rowHeight = self:getOptionHeight()
		for index, row in ipairs(self.optionDrawings) do
			local visible = self.openAlpha > 0 and index <= round(#self.options * self.openAlpha)
			local rowPosition = overlayRect.position + Vector2.new(0, (index - 1) * rowHeight)
			local rowSize = Vector2.new(overlayRect.size.X, rowHeight)
			setDrawingVisibility(row.frame, visible, 1)
			setDrawingVisibility(row.outline, visible, 1)
			setDrawingVisibility(row.text, visible, 1)
			if visible then
				writeProperty(row.frame, "Position", rowPosition)
				writeProperty(row.frame, "Size", rowSize)
				writeProperty(row.outline, "Position", rowPosition)
				writeProperty(row.outline, "Size", rowSize)
				writeProperty(row.text, "Position", rowPosition + Vector2.new(10, 6))
			end
		end
	end

	function control:SetOpen(isOpen)
		local nextValue = isOpen == true and #self.options > 0
		if nextValue then
			self.app:OpenOverlay(self)
		elseif self.app.openOverlay == self then
			self.app:CloseOverlay(nil)
		else
			self.open = false
		end
	end

	function control:SetValue(nextValue)
		self.value = nextValue
		writeProperty(self.drawings.value, "Text", tostring(nextValue))
	end

	function control:SetOptions(nextOptions, nextValue)
		self.options = table.clone(nextOptions or {})
		self.value = nextValue or self.options[1] or "Select"
		createChoiceOverlay(self)
		self.app:MarkLayoutDirty()
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

	function control:hitTest(point)
		local baseRect = getOverlayBaseRect(self)
		return pointInBounds(point, baseRect)
	end

	function control:getOverlayIndex(point)
		if not self.open then
			return nil
		end
		local overlayRect = self:getOverlayRect()
		if not pointInBounds(point, overlayRect) then
			return nil
		end
		return clamp(math.floor((point.Y - overlayRect.position.Y) / self:getOptionHeight()) + 1, 1, #self.options)
	end

	function control:onMouseDown(point)
		if self:hitTest(point) then
			self.pressing = true
		end
	end

	function control:onMouseUp(point)
		if self.pressing and self:hitTest(point) then
			self:SetOpen(not self.open)
		end
		self.pressing = false
	end

	function control:overlayHitTest(point)
		return self:getOverlayIndex(point) ~= nil
	end

	function control:onOverlayMouseDown(point)
		self.overlayPressedIndex = self:getOverlayIndex(point)
	end

	function control:onOverlayMouseUp(point)
		local index = self:getOverlayIndex(point)
		if self.overlayPressedIndex ~= nil and index == self.overlayPressedIndex then
			self:SetValue(self.options[index])
			self.callback(self.value)
			self.app:CloseOverlay(nil)
		end
		self.overlayPressedIndex = nil
	end

	function control:onStep(mousePosition, _, dt)
		self.openAlpha = animateToward(self.openAlpha, self.open and 1 or 0, getMotionDuration(self.app, "standard"), dt)
		self.hovered = self:IsDisplayed() and self:hitTest(mousePosition)
		writeProperty(self.drawings.frame, "Color", self.hovered and self.app.theme.InputHover or self.app.theme.Input)
		writeProperty(self.drawings.outline, "Color", (self.open or self.hovered) and colorLerp(self.app.theme.Border, self.app.theme.AccentSoft, 0.35) or self.app.theme.Border)
		self.hoverIndex = self:getOverlayIndex(mousePosition)
		for index, row in ipairs(self.optionDrawings) do
			local selected = self.options[index] == self.value
			local hovered = self.hoverIndex == index
			writeProperty(row.frame, "Color", selected and colorLerp(self.app.theme.Input, self.app.theme.NavActive, 0.85) or hovered and self.app.theme.InputHover or self.app.theme.Input)
			writeProperty(row.outline, "Color", selected and self.app.theme.AccentSoft or self.app.theme.Border)
		end
		self:layoutOverlay()
	end

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.app.theme.Text)
		writeProperty(self.drawings.frame, "Color", self.app.theme.Input)
		writeProperty(self.drawings.outline, "Color", self.app.theme.Border)
		writeProperty(self.drawings.value, "Color", self.app.theme.SubText)
		writeProperty(self.drawings.arrow, "Color", self.app.theme.SubText)
		for _, row in ipairs(self.optionDrawings) do
			writeProperty(row.text, "Color", self.app.theme.Text)
			writeProperty(row.frame, "Color", self.app.theme.Input)
			writeProperty(row.outline, "Color", self.app.theme.Border)
		end
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.label, "ZIndex", z)
		writeProperty(self.drawings.frame, "ZIndex", z)
		writeProperty(self.drawings.outline, "ZIndex", z + 1)
		writeProperty(self.drawings.value, "ZIndex", z + 2)
		writeProperty(self.drawings.arrow, "ZIndex", z + 2)
		local overlayBase = self.app.zBase + 400
		for index, row in ipairs(self.optionDrawings) do
			writeProperty(row.frame, "ZIndex", overlayBase + (index * 3))
			writeProperty(row.outline, "ZIndex", overlayBase + (index * 3) + 1)
			writeProperty(row.text, "ZIndex", overlayBase + (index * 3) + 2)
		end
	end

	function control:destroy()
		destroyDrawings(self.drawings)
		for _, row in ipairs(self.optionDrawings) do
			destroyDrawing(row.frame)
			destroyDrawing(row.outline)
			destroyDrawing(row.text)
		end
	end

	control:applyTheme()
	return addHostChild(host, control)
end

local function normalizeSearchDropdownMaxSize(maxSize)
	local value = tonumber(maxSize)
	if value == nil then
		return 6
	end
	return clamp(math.floor(value), 3, 10)
end

local function resolveSearchDropdownArguments(defaultValue, maxSizeOrCallback, callback)
	if type(maxSizeOrCallback) == "function" and callback == nil then
		return defaultValue, 6, maxSizeOrCallback
	end
	return defaultValue, normalizeSearchDropdownMaxSize(maxSizeOrCallback), callback
end

local function addSearchDropdown(host, text, options, defaultValue, maxSizeOrCallback, callback)
	local resolvedDefaultValue, resolvedMaxSize, resolvedCallback = resolveSearchDropdownArguments(defaultValue, maxSizeOrCallback, callback)
	local control = addDropdown(host, text, options, resolvedDefaultValue, resolvedCallback)
	control.kind = "SearchDropdown"
	control.searchText = ""
	control.maxSize = resolvedMaxSize
	control.filteredIndices = {}
	control.acceptsTextInput = true
	control.scrollOffset = 0
	control.focused = false

	control.drawings.searchFrame = createDrawing("Square", {
		Visible = false,
		Filled = true,
		Color = control.app.theme.Input,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.searchOutline = createDrawing("Square", {
		Visible = false,
		Filled = false,
		Color = control.app.theme.Border,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.searchText = createDrawing("Text", {
		Visible = false,
		Color = control.app.theme.SubText,
		Size = control.app.theme.TextSize,
		Font = control.app.theme.Font,
		Text = "",
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})

	function control:updateFilter()
		table.clear(self.filteredIndices)
		local query = string.lower(self.searchText or "")
		for index, option in ipairs(self.options) do
			if query == "" or string.find(string.lower(tostring(option)), query, 1, true) ~= nil then
				table.insert(self.filteredIndices, index)
			end
		end
		self.scrollOffset = clamp(self.scrollOffset, 0, math.max(0, #self.filteredIndices - self.maxSize))
	end

	function control:getVisibleRowCount()
		return math.min(#self.filteredIndices, self.maxSize)
	end

	function control:getOverlayRect()
		local baseRect = getOverlayBaseRect(self)
		local rowHeight = self:getOptionHeight()
		local visibleRows = round(self:getVisibleRowCount() * self.openAlpha)
		return makeRect(
			baseRect.position + Vector2.new(0, baseRect.size.Y + 8 + baseRect.size.Y + 6),
			Vector2.new(baseRect.size.X, visibleRows * rowHeight)
		)
	end

	function control:getSearchRect()
		local baseRect = getOverlayBaseRect(self)
		return makeRect(baseRect.position + Vector2.new(0, baseRect.size.Y + 8), Vector2.new(baseRect.size.X, baseRect.size.Y))
	end

	function control:getOverlayIndex(point)
		if not self.open then
			return nil
		end
		local overlayRect = self:getOverlayRect()
		if not pointInBounds(point, overlayRect) then
			return nil
		end
		local rowIndex = clamp(math.floor((point.Y - overlayRect.position.Y) / self:getOptionHeight()) + 1, 1, self:getVisibleRowCount())
		return self.filteredIndices[self.scrollOffset + rowIndex]
	end

	function control:layoutOverlay()
		local searchRect = self:getSearchRect()
		local overlayRect = self:getOverlayRect()
		local rowHeight = self:getOptionHeight()
		local showSearch = self.openAlpha > 0
		setDrawingVisibility(self.drawings.searchFrame, showSearch, 1)
		setDrawingVisibility(self.drawings.searchOutline, showSearch, 1)
		setDrawingVisibility(self.drawings.searchText, showSearch, 1)

		if showSearch then
			writeProperty(self.drawings.searchFrame, "Position", searchRect.position)
			writeProperty(self.drawings.searchFrame, "Size", searchRect.size)
			writeProperty(self.drawings.searchOutline, "Position", searchRect.position)
			writeProperty(self.drawings.searchOutline, "Size", searchRect.size)
			writeProperty(self.drawings.searchText, "Text", self.searchText ~= "" and self.searchText or "Search...")
			writeProperty(self.drawings.searchText, "Position", searchRect.position + Vector2.new(10, 7))
		end

		for index, row in ipairs(self.optionDrawings) do
			local visibleRowIndex
			for offset = 1, self:getVisibleRowCount() do
				if self.filteredIndices[self.scrollOffset + offset] == index then
					visibleRowIndex = offset
					break
				end
			end
			local visible = self.openAlpha > 0 and visibleRowIndex ~= nil
			setDrawingVisibility(row.frame, visible, 1)
			setDrawingVisibility(row.outline, visible, 1)
			setDrawingVisibility(row.text, visible, 1)
			if visible then
				local rowPosition = overlayRect.position + Vector2.new(0, (visibleRowIndex - 1) * rowHeight)
				local rowSize = Vector2.new(overlayRect.size.X, rowHeight)
				writeProperty(row.frame, "Position", rowPosition)
				writeProperty(row.frame, "Size", rowSize)
				writeProperty(row.outline, "Position", rowPosition)
				writeProperty(row.outline, "Size", rowSize)
				writeProperty(row.text, "Position", rowPosition + Vector2.new(10, 6))
			end
		end
	end

	function control:SetOpen(isOpen)
		local nextValue = isOpen == true and #self.options > 0
		if nextValue then
			self:updateFilter()
			self.app:OpenOverlay(self)
		else
			self.focused = false
			if activeTextbox == self then
				clearTextboxFocus(false)
			end
			if self.app.openOverlay == self then
				self.app:CloseOverlay(nil)
			else
				self.open = false
			end
		end
	end

	function control:SetSearchText(nextText)
		self.searchText = tostring(nextText or "")
		self:updateFilter()
		self:layoutOverlay()
	end

	function control:SetMaxSize(nextMaxSize)
		self.maxSize = normalizeSearchDropdownMaxSize(nextMaxSize)
		self:updateFilter()
		self.app:MarkLayoutDirty()
	end

	function control:SetOptions(nextOptions, nextValue, nextMaxSize)
		self.options = table.clone(nextOptions or {})
		self.value = nextValue or self.options[1] or "Select"
		self.maxSize = normalizeSearchDropdownMaxSize(nextMaxSize or self.maxSize)
		createChoiceOverlay(self)
		self:updateFilter()
		self.app:MarkLayoutDirty()
	end

	function control:Blur(submit)
		self.focused = false
		if submit and self.filteredIndices[1] ~= nil then
			self:SetValue(self.options[self.filteredIndices[1]])
			self.callback(self.value)
		end
		updateInputBlocker()
	end

	function control:HandleKeyboardInput(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if input.KeyCode == Enum.KeyCode.Backspace then
			self.searchText = string.sub(self.searchText, 1, math.max(0, #self.searchText - 1))
		elseif input.KeyCode == Enum.KeyCode.Return then
			self:Blur(true)
		elseif input.KeyCode == Enum.KeyCode.Escape then
			self:Blur(false)
		elseif input.KeyCode == Enum.KeyCode.Space then
			self.searchText = self.searchText .. " "
		else
			local textValue = input.KeyCode.Name
			if #textValue == 1 then
				self.searchText = self.searchText .. string.lower(textValue)
			else
				return
			end
		end
		self:updateFilter()
		self:layoutOverlay()
	end

	function control:onMouseDown(point)
		if self:hitTest(point) then
			self.pressing = true
			return
		end
		if pointInBounds(point, self:getSearchRect()) then
			self.focused = true
			activeTextbox = self
			updateInputBlocker()
		end
	end

	function control:overlayHitTest(point)
		return pointInBounds(point, self:getSearchRect()) or self:getOverlayIndex(point) ~= nil
	end

	function control:onOverlayMouseDown(point)
		if pointInBounds(point, self:getSearchRect()) then
			self.focused = true
			activeTextbox = self
			updateInputBlocker()
			return
		end
		self.overlayPressedIndex = self:getOverlayIndex(point)
	end

	function control:onOverlayMouseWheel(delta)
		if #self.filteredIndices <= self.maxSize then
			return false
		end
		self.scrollOffset = clamp(self.scrollOffset - delta, 0, math.max(0, #self.filteredIndices - self.maxSize))
		self:layoutOverlay()
		return true
	end

	function control:onOverlayMouseUp(point)
		local index = self:getOverlayIndex(point)
		if self.overlayPressedIndex ~= nil and index == self.overlayPressedIndex then
			self:SetValue(self.options[index])
			self.callback(self.value)
			self.app:CloseOverlay(nil)
		end
		self.overlayPressedIndex = nil
	end

	local previousStep = control.onStep
	function control:onStep(mousePosition, ownsHover, dt)
		previousStep(self, mousePosition, ownsHover, dt)
		self.openAlpha = animateToward(self.openAlpha, self.open and 1 or 0, getMotionDuration(self.app, "standard"), dt)
		writeProperty(self.drawings.searchFrame, "Color", self.focused and self.app.theme.InputFocused or self.app.theme.Input)
		writeProperty(self.drawings.searchOutline, "Color", self.focused and colorLerp(self.app.theme.Border, self.app.theme.AccentSoft, 0.35) or self.app.theme.Border)
		writeProperty(self.drawings.searchText, "Color", self.searchText == "" and self.app.theme.Muted or self.app.theme.SubText)
		self.hoverIndex = self:getOverlayIndex(mousePosition)
		self:layoutOverlay()
	end

	local previousApplyTheme = control.applyTheme
	function control:applyTheme()
		previousApplyTheme(self)
		writeProperty(self.drawings.searchFrame, "Color", self.app.theme.Input)
		writeProperty(self.drawings.searchOutline, "Color", self.app.theme.Border)
		writeProperty(self.drawings.searchText, "Color", self.app.theme.SubText)
	end

	local previousSetZIndex = control.setZIndex
	function control:setZIndex(z)
		previousSetZIndex(self, z)
		local overlayBase = self.app.zBase + 400
		writeProperty(self.drawings.searchFrame, "ZIndex", overlayBase)
		writeProperty(self.drawings.searchOutline, "ZIndex", overlayBase + 1)
		writeProperty(self.drawings.searchText, "ZIndex", overlayBase + 2)
	end

	local previousDestroy = control.destroy
	function control:destroy()
		previousDestroy(self)
		destroyDrawing(self.drawings.searchFrame)
		destroyDrawing(self.drawings.searchOutline)
		destroyDrawing(self.drawings.searchText)
	end

	control:updateFilter()
	return control
end

local function addTextbox(host, text, placeholder, callback)
	local control = makeBaseControl(host, "Textbox", host.app.theme.TextSize + 6 + host.app.density.inputHeight)
	control.text = tostring(text or "")
	control.placeholder = tostring(placeholder or "")
	control.value = ""
	control.callback = callback or function() end
	control.configKey = control.text
	control.acceptsTextInput = true
	control.blocksWindowDrag = true
	control.focused = false

	control.drawings.label = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.Text,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = control.text,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	control.drawings.frame = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = host.app.theme.Input,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.outline = createDrawing("Square", {
		Visible = true,
		Filled = false,
		Color = host.app.theme.Border,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.value = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.SubText,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = control.placeholder,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})

	function control:getDisplayText()
		if self.value == "" then
			return self.placeholder, self.app.theme.Muted
		end
		return self.value, self.app.theme.SubText
	end

	function control:layout()
		writeProperty(self.drawings.label, "Position", self.position)
		local rect = getOverlayBaseRect(self)
		writeProperty(self.drawings.frame, "Position", rect.position)
		writeProperty(self.drawings.frame, "Size", rect.size)
		writeProperty(self.drawings.outline, "Position", rect.position)
		writeProperty(self.drawings.outline, "Size", rect.size)
		local displayText, displayColor = self:getDisplayText()
		writeProperty(self.drawings.value, "Text", displayText)
		writeProperty(self.drawings.value, "Color", displayColor)
		writeProperty(self.drawings.value, "Position", rect.position + Vector2.new(10, 7))
	end

	function control:hitTest(point)
		return pointInBounds(point, getOverlayBaseRect(self))
	end

	function control:onMouseDown(point)
		if self:hitTest(point) then
			self.focused = true
			activeTextbox = self
			updateInputBlocker()
		end
	end

	function control:Blur(submit)
		if submit then
			self.callback(self.value)
		end
		self.focused = false
		self:layout()
		updateInputBlocker()
	end

	function control:HandleKeyboardInput(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if input.KeyCode == Enum.KeyCode.Backspace then
			self.value = string.sub(self.value, 1, math.max(0, #self.value - 1))
		elseif input.KeyCode == Enum.KeyCode.Return then
			clearTextboxFocus(true)
			return
		elseif input.KeyCode == Enum.KeyCode.Escape then
			clearTextboxFocus(false)
			return
		elseif input.KeyCode == Enum.KeyCode.Space then
			self.value = self.value .. " "
		else
			local name = input.KeyCode.Name
			if #name == 1 then
				local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
				self.value = self.value .. (shift and string.upper(name) or string.lower(name))
			else
				return
			end
		end
		self:layout()
	end

	function control:onStep(mousePosition)
		self.hovered = self:IsDisplayed() and self:hitTest(mousePosition)
		writeProperty(self.drawings.frame, "Color", self.focused and self.app.theme.InputFocused or self.hovered and self.app.theme.InputHover or self.app.theme.Input)
		writeProperty(self.drawings.outline, "Color", self.focused and colorLerp(self.app.theme.Border, self.app.theme.AccentSoft, 0.4) or self.app.theme.Border)
	end

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.app.theme.Text)
		writeProperty(self.drawings.frame, "Color", self.app.theme.Input)
		writeProperty(self.drawings.outline, "Color", self.app.theme.Border)
	end

	function control:SetText(nextText)
		self.value = tostring(nextText or "")
		self:layout()
	end

	function control:GetConfigValue()
		return self.value
	end

	function control:ApplyConfigValue(nextValue, fireCallback)
		self.value = tostring(nextValue or "")
		self:layout()
		if fireCallback ~= false then
			self.callback(self.value)
		end
	end

	control:applyTheme()
	return addHostChild(host, control)
end

local function addKeybind(host, text, defaultKey, callback, changedCallback)
	local control = makeBaseControl(host, "Keybind", host.app.theme.TextSize + 6 + host.app.density.inputHeight)
	control.text = tostring(text or "")
	control.configKey = control.text
	control.binding = deserializeInputBinding(defaultKey) or (typeof(defaultKey) == "EnumItem" and { kind = "Keyboard", code = defaultKey } or defaultKey)
	control.callback = callback or function() end
	control.changedCallback = changedCallback or function() end
	control.listening = false
	control.allowMouseInputs = false
	control.blocksWindowDrag = true
	control.capturesBindings = true

	control.drawings.label = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.Text,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = control.text,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	control.drawings.frame = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = host.app.theme.Input,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.outline = createDrawing("Square", {
		Visible = true,
		Filled = false,
		Color = host.app.theme.Border,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.value = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.SubText,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = formatInputBinding(control.binding),
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})

	function control:layout()
		writeProperty(self.drawings.label, "Position", self.position)
		local rect = getOverlayBaseRect(self)
		writeProperty(self.drawings.frame, "Position", rect.position)
		writeProperty(self.drawings.frame, "Size", rect.size)
		writeProperty(self.drawings.outline, "Position", rect.position)
		writeProperty(self.drawings.outline, "Size", rect.size)
		writeProperty(self.drawings.value, "Position", rect.position + Vector2.new(10, 7))
		writeProperty(self.drawings.value, "Text", self.listening and "Press a key..." or formatInputBinding(self.binding))
	end

	function control:hitTest(point)
		return pointInBounds(point, getOverlayBaseRect(self))
	end

	function control:SetListening(isListening)
		self.listening = isListening == true
		self:layout()
		updateInputBlocker()
	end

	function control:SetBinding(nextBinding)
		self.binding = nextBinding
		self:layout()
	end

	function control:SetAllowMouseInputs(allowMouse)
		self.allowMouseInputs = allowMouse == true
	end

	function control:GetConfigValue()
		return serializeInputBinding(self.binding)
	end

	function control:ApplyConfigValue(nextBinding, fireCallback)
		local resolved = deserializeInputBinding(nextBinding)
		if nextBinding == nil or resolved ~= nil then
			self:SetBinding(resolved)
		end
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

	function control:onStep(mousePosition)
		self.hovered = self:IsDisplayed() and self:hitTest(mousePosition)
		writeProperty(self.drawings.frame, "Color", self.listening and self.app.theme.InputFocused or self.hovered and self.app.theme.InputHover or self.app.theme.Input)
		writeProperty(self.drawings.outline, "Color", self.listening and colorLerp(self.app.theme.Border, self.app.theme.AccentSoft, 0.4) or self.app.theme.Border)
	end

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.app.theme.Text)
		writeProperty(self.drawings.frame, "Color", self.app.theme.Input)
		writeProperty(self.drawings.outline, "Color", self.app.theme.Border)
		writeProperty(self.drawings.value, "Color", self.app.theme.SubText)
	end

	control:applyTheme()
	table.insert(host.app.boundControls, control)
	return addHostChild(host, control)
end

local function addMultiDropdown(host, text, options, defaultValues, callback)
	local control = addDropdown(host, text, options, nil, callback)
	control.kind = "MultiDropdown"
	control.values = {}
	control.callback = callback or function() end
	control.configKey = tostring(text or "")
	control.selectedLookup = {}

	for _, value in ipairs(defaultValues or {}) do
		table.insert(control.values, value)
		control.selectedLookup[value] = true
	end

	createChoiceOverlay(control)
	for _, row in ipairs(control.optionDrawings) do
		row.check = createDrawing("Text", {
			Visible = false,
			Color = control.app.theme.Accent,
			Size = control.app.theme.TextSize,
			Font = control.app.theme.Font,
			Text = "x",
			Position = Vector2.zero,
			Outline = false,
			Transparency = 1,
		})
	end

	function control:getDisplayText()
		if #self.values == 0 then
			return "Select"
		end
		return table.concat(self.values, ", ")
	end

	function control:SetValue()
	end

	function control:SetValues(nextValues)
		self.values = {}
		self.selectedLookup = {}
		for _, value in ipairs(nextValues or {}) do
			table.insert(self.values, value)
			self.selectedLookup[value] = true
		end
		writeProperty(self.drawings.value, "Text", self:getDisplayText())
	end

	function control:GetConfigValue()
		return table.clone(self.values)
	end

	function control:ApplyConfigValue(nextValues, fireCallback)
		self:SetValues(nextValues)
		if fireCallback ~= false then
			self.callback(table.clone(self.values))
		end
	end

	function control:toggleValue(option)
		if self.selectedLookup[option] then
			self.selectedLookup[option] = nil
			for index, value in ipairs(self.values) do
				if value == option then
					table.remove(self.values, index)
					break
				end
			end
		else
			self.selectedLookup[option] = true
			table.insert(self.values, option)
		end
		writeProperty(self.drawings.value, "Text", self:getDisplayText())
	end

	local previousOnOverlayMouseUp = control.onOverlayMouseUp
	function control:onOverlayMouseUp(point)
		local index = self:getOverlayIndex(point)
		if self.overlayPressedIndex ~= nil and index == self.overlayPressedIndex then
			local option = self.options[index]
			self:toggleValue(option)
			self.callback(table.clone(self.values))
		end
		self.overlayPressedIndex = nil
	end

	local previousOnStep = control.onStep
	function control:onStep(mousePosition, ownsHover, dt)
		previousOnStep(self, mousePosition, ownsHover, dt)
		writeProperty(self.drawings.value, "Text", self:getDisplayText())
		for index, row in ipairs(self.optionDrawings) do
			local selected = self.selectedLookup[self.options[index]] == true
			if row.check ~= nil then
				setDrawingVisibility(row.check, self.openAlpha > 0, 1)
				if self.openAlpha > 0 then
					writeProperty(row.check, "Position", Vector2.new(row.frame.Position.X + row.frame.Size.X - 18, row.frame.Position.Y + 6))
					writeProperty(row.check, "Text", selected and "x" or "")
				end
				writeProperty(row.outline, "Color", selected and self.app.theme.AccentSoft or row.outline.Color)
			end
		end
	end

	local previousSetZIndex = control.setZIndex
	function control:setZIndex(z)
		previousSetZIndex(self, z)
		local overlayBase = self.app.zBase + 402
		for index, row in ipairs(self.optionDrawings) do
			if row.check ~= nil then
				writeProperty(row.check, "ZIndex", overlayBase + (index * 3) + 2)
			end
		end
	end

	local previousDestroy = control.destroy
	function control:destroy()
		previousDestroy(self)
		for _, row in ipairs(self.optionDrawings) do
			destroyDrawing(row.check)
		end
	end

	return control
end

local function addColorPicker(host, text, defaultColor, callback)
	local control = makeBaseControl(host, "ColorPicker", host.app.theme.TextSize + 6 + host.app.density.inputHeight)
	control.text = tostring(text or "")
	control.color = defaultColor or Color3.fromRGB(255, 255, 255)
	control.callback = callback or function() end
	control.configKey = control.text
	control.hue, control.sat, control.val = control.color:ToHSV()
	control.blocksWindowDrag = true
	control.isDropdown = true
	control.open = false
	control.openAlpha = 0
	control.dragMode = nil

	control.drawings.label = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.Text,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = control.text,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	control.drawings.frame = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = host.app.theme.Input,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.outline = createDrawing("Square", {
		Visible = true,
		Filled = false,
		Color = host.app.theme.Border,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.preview = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = control.color,
		Position = Vector2.zero,
		Size = Vector2.new(24, 16),
		Transparency = 1,
	})
	control.drawings.hex = createDrawing("Text", {
		Visible = true,
		Color = host.app.theme.SubText,
		Size = host.app.theme.TextSize,
		Font = host.app.theme.Font,
		Text = "#FFFFFF",
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	control.drawings.overlayFrame = createDrawing("Square", {
		Visible = false,
		Filled = true,
		Color = host.app.theme.Panel,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.overlayOutline = createDrawing("Square", {
		Visible = false,
		Filled = false,
		Color = host.app.theme.Border,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	control.drawings.svMarker = createDrawing("Circle", {
		Visible = false,
		Filled = false,
		Color = host.app.theme.Text,
		Position = Vector2.zero,
		Radius = 5,
		Thickness = 1,
		NumSides = 18,
		Transparency = 1,
	})
	control.drawings.hueMarker = createDrawing("Square", {
		Visible = false,
		Filled = false,
		Color = host.app.theme.Text,
		Position = Vector2.zero,
		Size = Vector2.new(14, 10),
		Thickness = 1,
		Transparency = 1,
	})

	control.svCells = {}
	for row = 0, 11 do
		for column = 0, 17 do
			table.insert(control.svCells, createDrawing("Square", {
				Visible = false,
				Filled = true,
				Color = control.color,
				Position = Vector2.zero,
				Size = Vector2.new(8, 8),
				Transparency = 1,
			}))
		end
	end

	control.hueCells = {}
	for index = 1, 18 do
		table.insert(control.hueCells, createDrawing("Square", {
			Visible = false,
			Filled = true,
			Color = Color3.fromHSV((index - 1) / 18, 1, 1),
			Position = Vector2.zero,
			Size = Vector2.new(12, 8),
			Transparency = 1,
		}))
	end

	function control:applyColor()
		self.color = Color3.fromHSV(self.hue, self.sat, self.val)
		writeProperty(self.drawings.preview, "Color", self.color)
		writeProperty(self.drawings.hex, "Text", string.format("#%02X%02X%02X", round(self.color.R * 255), round(self.color.G * 255), round(self.color.B * 255)))
	end

	function control:getOverlayRect()
		local baseRect = getOverlayBaseRect(self)
		return makeRect(baseRect.position + Vector2.new(0, baseRect.size.Y + 8), Vector2.new(198, 166 * self.openAlpha))
	end

	function control:getSvRect()
		local rect = self:getOverlayRect()
		return makeRect(rect.position + Vector2.new(12, 12), Vector2.new(144, 96))
	end

	function control:getHueRect()
		local rect = self:getOverlayRect()
		return makeRect(rect.position + Vector2.new(12, 120), Vector2.new(144, 10))
	end

	function control:updateOverlay()
		local overlayRect = self:getOverlayRect()
		local show = self.openAlpha > 0
		setDrawingVisibility(self.drawings.overlayFrame, show, 1)
		setDrawingVisibility(self.drawings.overlayOutline, show, 1)
		setDrawingVisibility(self.drawings.svMarker, show, 1)
		setDrawingVisibility(self.drawings.hueMarker, show, 1)
		if not show then
			for _, cell in ipairs(self.svCells) do
				setDrawingVisibility(cell, false, 1)
			end
			for _, cell in ipairs(self.hueCells) do
				setDrawingVisibility(cell, false, 1)
			end
			return
		end

		writeProperty(self.drawings.overlayFrame, "Position", overlayRect.position)
		writeProperty(self.drawings.overlayFrame, "Size", overlayRect.size)
		writeProperty(self.drawings.overlayOutline, "Position", overlayRect.position)
		writeProperty(self.drawings.overlayOutline, "Size", overlayRect.size)

		local svRect = self:getSvRect()
		local cellWidth = svRect.size.X / 18
		local cellHeight = svRect.size.Y / 12
		for row = 0, 11 do
			for column = 0, 17 do
				local index = (row * 18) + column + 1
				local sat = column / 17
				local val = 1 - (row / 11)
				local cell = self.svCells[index]
				setDrawingVisibility(cell, true, 1)
				writeProperty(cell, "Color", Color3.fromHSV(self.hue, sat, val))
				writeProperty(cell, "Position", svRect.position + Vector2.new(column * cellWidth, row * cellHeight))
				writeProperty(cell, "Size", Vector2.new(math.ceil(cellWidth), math.ceil(cellHeight)))
			end
		end

		local hueRect = self:getHueRect()
		local hueWidth = hueRect.size.X / 18
		for index, cell in ipairs(self.hueCells) do
			setDrawingVisibility(cell, true, 1)
			writeProperty(cell, "Color", Color3.fromHSV((index - 1) / 18, 1, 1))
			writeProperty(cell, "Position", hueRect.position + Vector2.new((index - 1) * hueWidth, 0))
			writeProperty(cell, "Size", Vector2.new(math.ceil(hueWidth), 10))
		end

		writeProperty(self.drawings.svMarker, "Position", svRect.position + Vector2.new(self.sat * svRect.size.X, (1 - self.val) * svRect.size.Y))
		writeProperty(self.drawings.hueMarker, "Position", hueRect.position + Vector2.new(self.hue * hueRect.size.X, 5))
	end

	function control:SetColor(nextColor)
		self.color = nextColor
		self.hue, self.sat, self.val = self.color:ToHSV()
		self:applyColor()
		self:updateOverlay()
	end

	function control:GetConfigValue()
		return { r = self.color.R, g = self.color.G, b = self.color.B }
	end

	function control:ApplyConfigValue(nextValue, fireCallback)
		if type(nextValue) == "table" then
			self:SetColor(Color3.new(nextValue.r or 1, nextValue.g or 1, nextValue.b or 1))
			if fireCallback ~= false then
				self.callback(self.color)
			end
		end
	end

	function control:SetOpen(isOpen)
		local nextValue = isOpen == true
		if nextValue then
			self.app:OpenOverlay(self)
		elseif self.app.openOverlay == self then
			self.app:CloseOverlay(nil)
		else
			self.open = false
		end
	end

	function control:layout()
		writeProperty(self.drawings.label, "Position", self.position)
		local rect = getOverlayBaseRect(self)
		writeProperty(self.drawings.frame, "Position", rect.position)
		writeProperty(self.drawings.frame, "Size", rect.size)
		writeProperty(self.drawings.outline, "Position", rect.position)
		writeProperty(self.drawings.outline, "Size", rect.size)
		writeProperty(self.drawings.preview, "Position", rect.position + Vector2.new(10, 9))
		writeProperty(self.drawings.hex, "Position", rect.position + Vector2.new(42, 7))
		self:applyColor()
		self:updateOverlay()
	end

	function control:hitTest(point)
		return pointInBounds(point, getOverlayBaseRect(self))
	end

	function control:overlayHitTest(point)
		return pointInBounds(point, self:getOverlayRect())
	end

	function control:onMouseDown(point)
		if self:hitTest(point) then
			self.pressing = true
		end
	end

	function control:onMouseUp(point)
		if self.pressing and self:hitTest(point) then
			self:SetOpen(not self.open)
		end
		self.pressing = false
	end

	function control:setHueFromMouse(point)
		local hueRect = self:getHueRect()
		self.hue = clamp((point.X - hueRect.position.X) / hueRect.size.X, 0, 1)
		self:applyColor()
		self:updateOverlay()
		self.callback(self.color)
	end

	function control:setSvFromMouse(point)
		local svRect = self:getSvRect()
		self.sat = clamp((point.X - svRect.position.X) / svRect.size.X, 0, 1)
		self.val = 1 - clamp((point.Y - svRect.position.Y) / svRect.size.Y, 0, 1)
		self:applyColor()
		self:updateOverlay()
		self.callback(self.color)
	end

	function control:onOverlayMouseDown(point)
		if pointInBounds(point, self:getHueRect()) then
			self.dragMode = "hue"
			self:setHueFromMouse(point)
		elseif pointInBounds(point, self:getSvRect()) then
			self.dragMode = "sv"
			self:setSvFromMouse(point)
		end
	end

	function control:onOverlayMouseUp()
		self.dragMode = nil
	end

	function control:onStep(mousePosition, _, dt)
		self.openAlpha = animateToward(self.openAlpha, self.open and 1 or 0, getMotionDuration(self.app, "standard"), dt)
		self.hovered = self:IsDisplayed() and self:hitTest(mousePosition)
		writeProperty(self.drawings.frame, "Color", self.hovered and self.app.theme.InputHover or self.app.theme.Input)
		writeProperty(self.drawings.outline, "Color", (self.open or self.hovered) and colorLerp(self.app.theme.Border, self.app.theme.AccentSoft, 0.35) or self.app.theme.Border)
		if self.dragMode == "hue" then
			self:setHueFromMouse(mousePosition)
		elseif self.dragMode == "sv" then
			self:setSvFromMouse(mousePosition)
		else
			self:updateOverlay()
		end
	end

	function control:applyTheme()
		writeProperty(self.drawings.label, "Color", self.app.theme.Text)
		writeProperty(self.drawings.frame, "Color", self.app.theme.Input)
		writeProperty(self.drawings.outline, "Color", self.app.theme.Border)
		writeProperty(self.drawings.hex, "Color", self.app.theme.SubText)
		writeProperty(self.drawings.overlayFrame, "Color", self.app.theme.Panel)
		writeProperty(self.drawings.overlayOutline, "Color", self.app.theme.Border)
	end

	function control:setZIndex(z)
		writeProperty(self.drawings.label, "ZIndex", z)
		writeProperty(self.drawings.frame, "ZIndex", z)
		writeProperty(self.drawings.outline, "ZIndex", z + 1)
		writeProperty(self.drawings.preview, "ZIndex", z + 2)
		writeProperty(self.drawings.hex, "ZIndex", z + 2)
		local overlayBase = self.app.zBase + 400
		writeProperty(self.drawings.overlayFrame, "ZIndex", overlayBase)
		writeProperty(self.drawings.overlayOutline, "ZIndex", overlayBase + 1)
		for index, cell in ipairs(self.svCells) do
			writeProperty(cell, "ZIndex", overlayBase + 2 + index)
		end
		for index, cell in ipairs(self.hueCells) do
			writeProperty(cell, "ZIndex", overlayBase + 300 + index)
		end
		writeProperty(self.drawings.svMarker, "ZIndex", overlayBase + 600)
		writeProperty(self.drawings.hueMarker, "ZIndex", overlayBase + 601)
	end

	function control:destroy()
		destroyDrawings(self.drawings)
		for _, cell in ipairs(self.svCells) do
			destroyDrawing(cell)
		end
		for _, cell in ipairs(self.hueCells) do
			destroyDrawing(cell)
		end
	end

	control:applyColor()
	control:applyTheme()
	return addHostChild(host, control)
end

function Group:IsDisplayed()
	return self.visible and self.host:IsDisplayed()
end

function Group:MarkLayoutDirty()
	self.app:MarkLayoutDirty()
end

function Group:GetHeight()
	local total = 28
	local childGap = self.app.density.groupGap
	local expandedAlpha = self.expandAlpha or (self.expanded and 1 or 0)
	if expandedAlpha <= 0 then
		return total
	end

	local childHeight = 0
	for index, item in ipairs(self.items) do
		if item.visible then
			childHeight = childHeight + item:GetHeight()
			if index < #self.items then
				childHeight = childHeight + childGap
			end
		end
	end

	return total + math.floor((childHeight + 12) * expandedAlpha)
end

function Group:Layout(position, width)
	self.position = position
	self.size = Vector2.new(width, self:GetHeight())
	writeProperty(self.drawings.frame, "Position", position)
	writeProperty(self.drawings.frame, "Size", Vector2.new(width, 28))
	writeProperty(self.drawings.outline, "Position", position)
	writeProperty(self.drawings.outline, "Size", Vector2.new(width, 28))
	writeProperty(self.drawings.marker, "Position", position + Vector2.new(10, 9))
	writeProperty(self.drawings.text, "Position", position + Vector2.new(22, 7))
	writeProperty(self.drawings.arrow, "Position", position + Vector2.new(width - 18, 7))
	writeProperty(self.drawings.arrow, "Text", self.expanded and "v" or ">")

	local childY = position.Y + 40
	for _, item in ipairs(self.items) do
		item.position = Vector2.new(position.X + 12, childY)
		item.size = Vector2.new(width - 24, item:GetHeight())
		if item.Layout ~= nil then
			item:Layout(item.position, width - 24)
		elseif item.layout ~= nil then
			item:layout()
		end
		childY = childY + item:GetHeight() + self.app.density.groupGap
	end
end

function Group:Step(mousePosition, dt)
	self.expandAlpha = animateToward(self.expandAlpha, self.expanded and 1 or 0, getMotionDuration(self.app, "standard"), dt)
	self.hovered = self:IsDisplayed() and pointInRect(mousePosition, self.position, Vector2.new(self.size.X, 28))
	writeProperty(self.drawings.frame, "Color", self.hovered and self.app.theme.Panel or self.app.theme.PanelHeader)
	writeProperty(self.drawings.outline, "Color", self.hovered and colorLerp(self.app.theme.Border, self.app.theme.AccentSoft, 0.22) or self.app.theme.Border)
	if math.abs(self.expandAlpha - (self.expanded and 1 or 0)) > 0.001 then
		self.app:MarkLayoutDirty()
	end
	for _, item in ipairs(self.items) do
		setItemVisibility(item, self.expandAlpha > 0.02 and self:IsDisplayed())
		if item.onStep then
			item:onStep(mousePosition, true, dt)
		end
	end
end

function Group:hitTest(point)
	return pointInRect(point, self.position, Vector2.new(self.size.X, 28))
end

function Group:onMouseDown(point)
	if self:hitTest(point) then
		self.pressing = true
		return true
	end
	if not self.expanded then
		return false
	end
	for _, item in ipairs(self.items) do
		if item.hitTest ~= nil and item:hitTest(point) then
			item:onMouseDown(point)
			return true
		end
	end
	return false
end

function Group:onMouseUp(point)
	if self.pressing and self:hitTest(point) then
		self.expanded = not self.expanded
		self:MarkLayoutDirty()
	end
	self.pressing = false
	for _, item in ipairs(self.items) do
		if item.onMouseUp then
			item:onMouseUp(point)
		end
	end
end

function Group:applyTheme()
	writeProperty(self.drawings.frame, "Color", self.app.theme.PanelHeader)
	writeProperty(self.drawings.outline, "Color", self.app.theme.Border)
	writeProperty(self.drawings.marker, "Color", self.app.theme.Accent)
	writeProperty(self.drawings.text, "Color", self.app.theme.HighlightText)
	writeProperty(self.drawings.arrow, "Color", self.app.theme.SubText)
	for _, item in ipairs(self.items) do
		if item.applyTheme then
			item:applyTheme()
		end
	end
end

function Group:setZIndex(z)
	writeProperty(self.drawings.frame, "ZIndex", z)
	writeProperty(self.drawings.outline, "ZIndex", z + 1)
	writeProperty(self.drawings.marker, "ZIndex", z + 2)
	writeProperty(self.drawings.text, "ZIndex", z + 2)
	writeProperty(self.drawings.arrow, "ZIndex", z + 2)
	local childZ = z + 4
	for _, item in ipairs(self.items) do
		if item.setZIndex then
			item:setZIndex(childZ)
			childZ = childZ + 10
		end
	end
end

function Group:destroy()
	destroyDrawings(self.drawings)
	for _, item in ipairs(self.items) do
		if item.destroy then
			item:destroy()
		end
	end
end

function Group:AddLabel(text)
	return addLabel(self, text)
end

function Group:AddParagraph(title, text)
	return addParagraph(self, title, text)
end

function Group:AddSection(text)
	return addInlineSectionLabel(self, text)
end

function Group:AddButton(text, callback)
	return addButton(self, text, callback)
end

function Group:AddButtonRow(buttons)
	return addButtonRow(self, buttons)
end

function Group:AddToggle(text, initialValue, callback)
	return addToggle(self, text, initialValue, callback)
end

function Group:AddSlider(text, minimum, maximum, initialValue, callback)
	return addSlider(self, text, minimum, maximum, initialValue, callback)
end

function Group:AddDropdown(text, options, defaultValue, callback)
	return addDropdown(self, text, options, defaultValue, callback)
end

function Group:AddSearchDropdown(text, options, defaultValue, maxSizeOrCallback, callback)
	return addSearchDropdown(self, text, options, defaultValue, maxSizeOrCallback, callback)
end

function Group:AddMultiDropdown(text, options, defaultValues, callback)
	return addMultiDropdown(self, text, options, defaultValues, callback)
end

function Group:AddColorPicker(text, defaultColor, callback)
	return addColorPicker(self, text, defaultColor, callback)
end

function Group:AddTextbox(text, placeholder, callback)
	return addTextbox(self, text, placeholder, callback)
end

function Group:AddKeybind(text, defaultKey, callback, changedCallback)
	return addKeybind(self, text, defaultKey, callback, changedCallback)
end

function Section:IsDisplayed()
	return self.visible and self.page == self.app.activePage
end

function Section:MarkLayoutDirty()
	self.app:MarkLayoutDirty()
end

function Section:GetHeight()
	local pad = self.app.density.cardPadding
	local total = pad
	if self.title ~= "" then
		total = total + 22
	end
	if self.description ~= "" then
		total = total + 18
	end
	if self.title ~= "" or self.description ~= "" then
		total = total + 12
	end
	for index, item in ipairs(self.items) do
		if item.visible then
			total = total + item:GetHeight()
			if index < #self.items then
				total = total + getItemGap(self)
			end
		end
	end
	total = total + pad
	return total
end

function Section:Layout(position, size, viewport, index)
	self.position = position
	self.size = size
	self.viewport = viewport
	self.index = index
	writeProperty(self.drawings.shadow, "Position", position + Vector2.new(0, 3))
	writeProperty(self.drawings.shadow, "Size", size)
	writeProperty(self.drawings.frame, "Position", position)
	writeProperty(self.drawings.frame, "Size", size)
	writeProperty(self.drawings.outline, "Position", position)
	writeProperty(self.drawings.outline, "Size", size)
	writeProperty(self.drawings.topBand, "Position", position)
	writeProperty(self.drawings.topBand, "Size", Vector2.new(size.X, 3))

	local pad = self.app.density.cardPadding
	local currentY = position.Y + pad
	if self.title ~= "" then
		writeProperty(self.drawings.title, "Visible", true)
		writeProperty(self.drawings.title, "Position", Vector2.new(position.X + pad, currentY))
		currentY = currentY + 20
	else
		writeProperty(self.drawings.title, "Visible", false)
	end
	if self.description ~= "" then
		writeProperty(self.drawings.description, "Visible", true)
		local lines = wrapText(self.description, math.max(18, math.floor((size.X - (pad * 2)) / 7.2)))
		writeProperty(self.drawings.description, "Text", table.concat(lines, "\n"))
		writeProperty(self.drawings.description, "Position", Vector2.new(position.X + pad, currentY))
		currentY = currentY + self.drawings.description.TextBounds.Y + 10
	else
		writeProperty(self.drawings.description, "Visible", false)
	end

	local contentWidth = size.X - (pad * 2)
	for _, item in ipairs(self.items) do
		item.position = Vector2.new(position.X + pad, currentY)
		item.size = Vector2.new(contentWidth, item:GetHeight())
		if item.Layout ~= nil then
			item:Layout(item.position, contentWidth)
		elseif item.layout ~= nil then
			item:layout()
		end
		currentY = currentY + item:GetHeight() + getItemGap(self)
	end
end

function Section:Step(mousePosition, dt)
	local targetAlpha = self.page == self.app.activePage and 1 or 0
	self.revealAlpha = animateToward(self.revealAlpha, targetAlpha, getMotionDuration(self.app, "emphasized"), dt)
	local visible = self:IsDisplayed() and self.revealAlpha > 0.01
	local viewportRect = makeRect(self.viewport.position, self.viewport.size)
	local onScreen = visible and (
		self.position.Y + self.size.Y >= viewportRect.position.Y - 30
		and self.position.Y <= viewportRect.position.Y + viewportRect.size.Y + 30
	)
	local displayOffset = shouldUseTranslation(self.app) and (1 - self.revealAlpha) * 6 or 0
	writeProperty(self.drawings.shadow, "Visible", onScreen)
	writeProperty(self.drawings.frame, "Visible", onScreen)
	writeProperty(self.drawings.outline, "Visible", onScreen)
	writeProperty(self.drawings.topBand, "Visible", onScreen)
	writeProperty(self.drawings.title, "Visible", onScreen and self.title ~= "")
	writeProperty(self.drawings.description, "Visible", onScreen and self.description ~= "")

	if onScreen then
		writeProperty(self.drawings.shadow, "Position", Vector2.new(self.position.X, self.position.Y + 3 - displayOffset))
		writeProperty(self.drawings.frame, "Position", Vector2.new(self.position.X, self.position.Y - displayOffset))
		writeProperty(self.drawings.outline, "Position", Vector2.new(self.position.X, self.position.Y - displayOffset))
		writeProperty(self.drawings.topBand, "Position", Vector2.new(self.position.X, self.position.Y - displayOffset))
		self.hovered = pointInRect(mousePosition, Vector2.new(self.position.X, self.position.Y - displayOffset), self.size)
		writeProperty(self.drawings.frame, "Color", self.hovered and self.app.theme.CardHover or self.app.theme.Card)
		writeProperty(self.drawings.outline, "Color", self.hovered and colorLerp(self.app.theme.Border, self.app.theme.AccentSoft, 0.26) or self.app.theme.Border)
		for _, item in ipairs(self.items) do
			setItemVisibility(item, true)
			if item.Step ~= nil then
				item:Step(mousePosition, dt)
			elseif item.onStep ~= nil then
				item:onStep(mousePosition, true, dt)
			end
		end
	else
		for _, item in ipairs(self.items) do
			setItemVisibility(item, false)
		end
	end
end

function Section:HitTest(point)
	if not self:IsDisplayed() then
		return nil
	end
	for _, item in ipairs(self.items) do
		if item.hitTest ~= nil and item:hitTest(point) then
			return item
		end
		if item.items ~= nil and item.expanded ~= nil then
			if item:hitTest(point) then
				return item
			end
			for _, child in ipairs(item.items) do
				if child.hitTest ~= nil and child:hitTest(point) then
					return child
				end
			end
		end
	end
	return nil
end

function Section:HandleMouseDown(point)
	for _, item in ipairs(self.items) do
		if item.hitTest ~= nil and item:hitTest(point) then
			item:onMouseDown(point)
			return true
		end
		if item.items ~= nil and item:onMouseDown(point) then
			return true
		end
	end
	return false
end

function Section:HandleMouseUp(point)
	for _, item in ipairs(self.items) do
		if item.onMouseUp ~= nil then
			item:onMouseUp(point)
		end
	end
end

function Section:applyTheme()
	writeProperty(self.drawings.shadow, "Color", self.app.theme.Shadow)
	writeProperty(self.drawings.frame, "Color", self.app.theme.Card)
	writeProperty(self.drawings.outline, "Color", self.app.theme.Border)
	writeProperty(self.drawings.topBand, "Color", self.app.theme.AccentSoft)
	writeProperty(self.drawings.title, "Color", self.app.theme.Text)
	writeProperty(self.drawings.description, "Color", self.app.theme.SubText)
	for _, item in ipairs(self.items) do
		if item.applyTheme then
			item:applyTheme()
		end
	end
end

function Section:setZIndex(z)
	writeProperty(self.drawings.shadow, "ZIndex", z)
	writeProperty(self.drawings.frame, "ZIndex", z + 1)
	writeProperty(self.drawings.outline, "ZIndex", z + 2)
	writeProperty(self.drawings.topBand, "ZIndex", z + 3)
	writeProperty(self.drawings.title, "ZIndex", z + 4)
	writeProperty(self.drawings.description, "ZIndex", z + 4)
	local childZ = z + 8
	for _, item in ipairs(self.items) do
		if item.setZIndex then
			item:setZIndex(childZ)
			childZ = childZ + 16
		end
	end
end

function Section:destroy()
	destroyDrawings(self.drawings)
	for _, item in ipairs(self.items) do
		if item.destroy then
			item:destroy()
		end
	end
end

function Section:AddGroup(options, maybeExpanded)
	local settings
	if type(options) == "table" then
		settings = options
	else
		settings = {
			title = tostring(options or "Group"),
			collapsible = true,
			defaultOpen = maybeExpanded ~= false,
		}
	end

	local group = setmetatable({
		app = self.app,
		page = self.page,
		host = self,
		items = {},
		title = tostring(settings.title or "Group"),
		collapsible = settings.collapsible ~= false,
		expanded = settings.defaultOpen ~= false,
		expandAlpha = settings.defaultOpen == false and 0 or 1,
		visible = true,
		drawings = {},
	}, Group)

	group.drawings.frame = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = self.app.theme.PanelHeader,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	group.drawings.outline = createDrawing("Square", {
		Visible = true,
		Filled = false,
		Color = self.app.theme.Border,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	group.drawings.marker = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = self.app.theme.Accent,
		Position = Vector2.zero,
		Size = Vector2.new(6, 6),
		Transparency = 1,
	})
	group.drawings.text = createDrawing("Text", {
		Visible = true,
		Color = self.app.theme.HighlightText,
		Size = self.app.theme.TextSize,
		Font = self.app.theme.Font,
		Text = group.title,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	group.drawings.arrow = createDrawing("Text", {
		Visible = true,
		Color = self.app.theme.SubText,
		Size = self.app.theme.SmallTextSize,
		Font = self.app.theme.Font,
		Text = group.expanded and "v" or ">",
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})

	return addHostChild(self, group)
end

function Section:AddLabel(text)
	return addLabel(self, text)
end

function Section:AddParagraph(title, text)
	return addParagraph(self, title, text)
end

function Section:AddSection(text)
	return addInlineSectionLabel(self, text)
end

function Section:AddButton(text, callback)
	return addButton(self, text, callback)
end

function Section:AddButtonRow(buttons)
	return addButtonRow(self, buttons)
end

function Section:AddToggle(text, initialValue, callback)
	return addToggle(self, text, initialValue, callback)
end

function Section:AddSlider(text, minimum, maximum, initialValue, callback)
	return addSlider(self, text, minimum, maximum, initialValue, callback)
end

function Section:AddDropdown(text, options, defaultValue, callback)
	return addDropdown(self, text, options, defaultValue, callback)
end

function Section:AddSearchDropdown(text, options, defaultValue, maxSizeOrCallback, callback)
	return addSearchDropdown(self, text, options, defaultValue, maxSizeOrCallback, callback)
end

function Section:AddMultiDropdown(text, options, defaultValues, callback)
	return addMultiDropdown(self, text, options, defaultValues, callback)
end

function Section:AddColorPicker(text, defaultColor, callback)
	return addColorPicker(self, text, defaultColor, callback)
end

function Section:AddTextbox(text, placeholder, callback)
	return addTextbox(self, text, placeholder, callback)
end

function Section:AddKeybind(text, defaultKey, callback, changedCallback)
	return addKeybind(self, text, defaultKey, callback, changedCallback)
end

local function makeSection(app, page, options)
	local settings = type(options) == "table" and options or { title = tostring(options or "") }
	local section = setmetatable({
		app = app,
		page = page,
		items = {},
		title = tostring(settings.title or ""),
		description = tostring(settings.description or ""),
		columnSpan = clamp(tonumber(settings.columnSpan) or 12, 1, 12),
		variant = settings.variant or "card",
		visible = settings.visible ~= false,
		revealAlpha = page == app.activePage and 1 or 0,
		drawings = {},
	}, Section)

	section.drawings.shadow = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = app.theme.Shadow,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 0.45,
	})
	section.drawings.frame = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = app.theme.Card,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	section.drawings.outline = createDrawing("Square", {
		Visible = true,
		Filled = false,
		Color = app.theme.Border,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	section.drawings.topBand = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = app.theme.AccentSoft,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	section.drawings.title = createDrawing("Text", {
		Visible = true,
		Color = app.theme.Text,
		Size = app.theme.SectionTitleSize,
		Font = app.theme.Font,
		Text = section.title,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	section.drawings.description = createDrawing("Text", {
		Visible = true,
		Color = app.theme.SubText,
		Size = app.theme.TextSize,
		Font = app.theme.Font,
		Text = section.description,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})

	return section
end

local function makePage(app, options)
	local settings = type(options) == "table" and options or {
		id = tostring(options or "page"),
		label = tostring(options or "Page"),
	}

	local page = setmetatable({
		app = app,
		id = tostring(settings.id or settings.label or ("page-" .. tostring(#app.pages + 1))),
		label = tostring(settings.label or settings.id or "Page"),
		icon = tostring(settings.icon or string.sub(tostring(settings.label or settings.id or "P"), 1, 1)),
		badge = settings.badge,
		description = tostring(settings.description or ""),
		sections = {},
		asideSections = {},
		scrollOffset = 0,
		asideScrollOffset = 0,
		defaultSection = nil,
		navHoverAlpha = 0,
		drawings = {},
	}, Page)

	page.drawings.frame = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = app.theme.Nav,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	page.drawings.activePill = createDrawing("Square", {
		Visible = true,
		Filled = true,
		Color = app.theme.NavActive,
		Position = Vector2.zero,
		Size = Vector2.zero,
		Transparency = 1,
	})
	page.drawings.icon = createDrawing("Text", {
		Visible = true,
		Color = app.theme.NavText,
		Size = app.theme.TextSize,
		Font = app.theme.TitleFont,
		Text = page.icon,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	page.drawings.text = createDrawing("Text", {
		Visible = true,
		Color = app.theme.NavText,
		Size = app.theme.TextSize,
		Font = app.theme.Font,
		Text = page.label,
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})
	page.drawings.badge = createDrawing("Text", {
		Visible = settings.badge ~= nil,
		Color = app.theme.HighlightText,
		Size = app.theme.SmallTextSize,
		Font = app.theme.Font,
		Text = settings.badge ~= nil and tostring(settings.badge) or "",
		Position = Vector2.zero,
		Outline = false,
		Transparency = 1,
	})

	return page
end

local function makeContainerHost(app, page, sectionList)
	local host = {}
	function host:AddSection(options)
		local section = makeSection(app, page, options)
		table.insert(sectionList, section)
		app:MarkLayoutDirty()
		return section
	end
	function host:AddGroup(options, expanded)
		local section = self:AddSection({ title = "" })
		return section:AddGroup(options, expanded)
	end
	return host
end

function Page:EnsureDefaultSection()
	if self.defaultSection == nil then
		self.defaultSection = self:AddSection({
			title = "",
			description = "",
			columnSpan = 12,
		})
	end
	return self.defaultSection
end

function Page:AddSection(options)
	if type(options) ~= "table" then
		return self:EnsureDefaultSection():AddSection(options)
	end
	local section = makeSection(self.app, self, options)
	table.insert(self.sections, section)
	self.app:MarkLayoutDirty()
	return section
end

function Page:AddAsideSection(options)
	local section = makeSection(self.app, self, options)
	table.insert(self.asideSections, section)
	self.app:MarkLayoutDirty()
	return section
end

function Page:SetAside(builder)
	self.asideSections = {}
	if type(builder) == "function" then
		builder(makeContainerHost(self.app, self, self.asideSections))
	end
	self.app:MarkLayoutDirty()
	return self
end

function Page:AddGroup(options, expanded)
	return self:EnsureDefaultSection():AddGroup(options, expanded)
end

function Page:AddLabel(text)
	return self:EnsureDefaultSection():AddLabel(text)
end

function Page:AddParagraph(title, text)
	return self:EnsureDefaultSection():AddParagraph(title, text)
end

function Page:AddButton(text, callback)
	return self:EnsureDefaultSection():AddButton(text, callback)
end

function Page:AddButtonRow(buttons)
	return self:EnsureDefaultSection():AddButtonRow(buttons)
end

function Page:AddToggle(text, initialValue, callback)
	return self:EnsureDefaultSection():AddToggle(text, initialValue, callback)
end

function Page:AddSlider(text, minimum, maximum, initialValue, callback)
	return self:EnsureDefaultSection():AddSlider(text, minimum, maximum, initialValue, callback)
end

function Page:AddDropdown(text, options, defaultValue, callback)
	return self:EnsureDefaultSection():AddDropdown(text, options, defaultValue, callback)
end

function Page:AddSearchDropdown(text, options, defaultValue, maxSizeOrCallback, callback)
	return self:EnsureDefaultSection():AddSearchDropdown(text, options, defaultValue, maxSizeOrCallback, callback)
end

function Page:AddMultiDropdown(text, options, defaultValues, callback)
	return self:EnsureDefaultSection():AddMultiDropdown(text, options, defaultValues, callback)
end

function Page:AddColorPicker(text, defaultColor, callback)
	return self:EnsureDefaultSection():AddColorPicker(text, defaultColor, callback)
end

function Page:AddTextbox(text, placeholder, callback)
	return self:EnsureDefaultSection():AddTextbox(text, placeholder, callback)
end

function Page:AddKeybind(text, defaultKey, callback, changedCallback)
	return self:EnsureDefaultSection():AddKeybind(text, defaultKey, callback, changedCallback)
end

function Page:Select()
	self.app:SetActivePage(self)
end

local function createShellDrawings(app)
	app.drawings = {
		shadow = createDrawing("Square", {
			Visible = app.visible,
			Filled = true,
			Color = app.theme.Shadow,
			Position = Vector2.zero,
			Size = Vector2.zero,
			Transparency = 0.35,
		}),
		frame = createDrawing("Square", {
			Visible = app.visible,
			Filled = true,
			Color = app.theme.WindowBackground,
			Position = Vector2.zero,
			Size = Vector2.zero,
			Transparency = 1,
		}),
		outline = createDrawing("Square", {
			Visible = app.visible,
			Filled = false,
			Color = app.theme.Border,
			Position = Vector2.zero,
			Size = Vector2.zero,
			Transparency = 1,
		}),
		sidebar = createDrawing("Square", {
			Visible = app.visible,
			Filled = true,
			Color = app.theme.SidebarBackground,
			Position = Vector2.zero,
			Size = Vector2.zero,
			Transparency = 1,
		}),
		header = createDrawing("Square", {
			Visible = app.visible,
			Filled = true,
			Color = app.theme.HeaderBackground,
			Position = Vector2.zero,
			Size = Vector2.zero,
			Transparency = 1,
		}),
		canvas = createDrawing("Square", {
			Visible = app.visible,
			Filled = true,
			Color = app.theme.CanvasBackground,
			Position = Vector2.zero,
			Size = Vector2.zero,
			Transparency = 1,
		}),
		aside = createDrawing("Square", {
			Visible = false,
			Filled = true,
			Color = app.theme.AsideBackground,
			Position = Vector2.zero,
			Size = Vector2.zero,
			Transparency = 1,
		}),
		sidebarDivider = createDrawing("Line", {
			Visible = app.visible,
			Color = app.theme.InnerBorder,
			From = Vector2.zero,
			To = Vector2.zero,
			Thickness = 1,
			Transparency = 1,
		}),
		headerDivider = createDrawing("Line", {
			Visible = app.visible,
			Color = app.theme.InnerBorder,
			From = Vector2.zero,
			To = Vector2.zero,
			Thickness = 1,
			Transparency = 1,
		}),
		asideDivider = createDrawing("Line", {
			Visible = false,
			Color = app.theme.InnerBorder,
			From = Vector2.zero,
			To = Vector2.zero,
			Thickness = 1,
			Transparency = 1,
		}),
		identity = createDrawing("Text", {
			Visible = app.visible,
			Color = app.theme.Text,
			Size = app.theme.AppTitleSize,
			Font = app.theme.TitleFont,
			Text = app.title,
			Position = Vector2.zero,
			Outline = false,
			Transparency = 1,
		}),
		identitySub = createDrawing("Text", {
			Visible = app.visible,
			Color = app.theme.Muted,
			Size = app.theme.SmallTextSize,
			Font = app.theme.Font,
			Text = "Control deck",
			Position = Vector2.zero,
			Outline = false,
			Transparency = 1,
		}),
		pageTitle = createDrawing("Text", {
			Visible = app.visible,
			Color = app.theme.Text,
			Size = app.theme.TitleSize,
			Font = app.theme.TitleFont,
			Text = app.title,
			Position = Vector2.zero,
			Outline = false,
			Transparency = 1,
		}),
		pageSubtitle = createDrawing("Text", {
			Visible = app.visible,
			Color = app.theme.SubText,
			Size = app.theme.TextSize,
			Font = app.theme.Font,
			Text = app.subtitle,
			Position = Vector2.zero,
			Outline = false,
			Transparency = 1,
		}),
		searchChip = createDrawing("Square", {
			Visible = app.visible,
			Filled = true,
			Color = app.theme.Panel,
			Position = Vector2.zero,
			Size = Vector2.zero,
			Transparency = 1,
		}),
		searchChipOutline = createDrawing("Square", {
			Visible = app.visible,
			Filled = false,
			Color = app.theme.SoftBorder,
			Position = Vector2.zero,
			Size = Vector2.zero,
			Transparency = 1,
		}),
		searchChipText = createDrawing("Text", {
			Visible = app.visible,
			Color = app.theme.SubText,
			Size = app.theme.SmallTextSize,
			Font = app.theme.Font,
			Text = "Quick Jump",
			Position = Vector2.zero,
			Outline = false,
			Transparency = 1,
		}),
		contentScrollbar = createDrawing("Square", {
			Visible = false,
			Filled = true,
			Color = app.theme.AccentSoft,
			Position = Vector2.zero,
			Size = Vector2.zero,
			Transparency = 0.85,
		}),
		asideScrollbar = createDrawing("Square", {
			Visible = false,
			Filled = true,
			Color = app.theme.AccentSoft,
			Position = Vector2.zero,
			Size = Vector2.zero,
			Transparency = 0.85,
		}),
	}
end

function App:MarkLayoutDirty()
	self.layoutDirty = true
end

function App:MarkPaintDirty()
	self.paintDirty = true
end

function App:GetActiveSections()
	if self.activePage == nil then
		return {}
	end
	return self.activePage.sections
end

function App:GetActiveAsideSections()
	if self.activePage == nil then
		return {}
	end
	local sections = {}
	for _, section in ipairs(self.sharedAsideSections) do
		table.insert(sections, section)
	end
	for _, section in ipairs(self.activePage.asideSections) do
		table.insert(sections, section)
	end
	return sections
end

function App:HasAside()
	return #self:GetActiveAsideSections() > 0
end

function App:CloseOverlay(except)
	if self.openOverlay ~= nil and self.openOverlay ~= except then
		self.openOverlay.open = false
	end
	if except == nil then
		self.openOverlay = nil
	end
	if activeTextbox ~= nil and activeTextbox.app == self and activeTextbox ~= except then
		clearTextboxFocus(false)
	end
end

function App:OpenOverlay(control)
	if self.openOverlay ~= nil and self.openOverlay ~= control then
		self.openOverlay.open = false
	end
	self.openOverlay = control
	control.open = true
end

function App:GetConfigId()
	return sanitizeFileName(self.configId or self.title)
end

function App:GetConfigFolder()
	return (self.configRoot or "drawing-ui-lib-configs") .. "/" .. self:GetConfigId()
end

function App:EnsureConfigFolder()
	if not hasFilesystem() then
		return false
	end
	local folder = self:GetConfigFolder()
	if not isfolder(folder) then
		local ok = pcall(makefolder, folder)
		if not ok then
			return false
		end
	end
	return true
end

function App:BuildConfig()
	local data = {}
	for _, page in ipairs(self.pages) do
		for _, section in ipairs(page.sections) do
			for _, item in ipairs(section.items) do
				if item.configKey ~= nil and item.GetConfigValue ~= nil then
					data[item.configKey] = item:GetConfigValue()
				elseif item.items ~= nil then
					for _, child in ipairs(item.items) do
						if child.configKey ~= nil and child.GetConfigValue ~= nil then
							data[child.configKey] = child:GetConfigValue()
						end
					end
				end
			end
		end
	end
	return data
end

function App:ApplyConfig(config, fireCallbacks)
	for _, page in ipairs(self.pages) do
		for _, section in ipairs(page.sections) do
			for _, item in ipairs(section.items) do
				if item.configKey ~= nil and item.ApplyConfigValue ~= nil and config[item.configKey] ~= nil then
					item:ApplyConfigValue(config[item.configKey], fireCallbacks)
				elseif item.items ~= nil then
					for _, child in ipairs(item.items) do
						if child.configKey ~= nil and child.ApplyConfigValue ~= nil and config[child.configKey] ~= nil then
							child:ApplyConfigValue(config[child.configKey], fireCallbacks)
						end
					end
				end
			end
		end
	end
end

function App:ListConfigs()
	if not self:EnsureConfigFolder() then
		return {}
	end
	local names = {}
	local ok, files = pcall(listfiles, self:GetConfigFolder())
	if not ok or type(files) ~= "table" then
		return {}
	end
	for _, path in ipairs(files) do
		local name = path:match("([^\\/]+)%.json$")
		if name ~= nil then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

function App:SaveConfig(name)
	if not self:EnsureConfigFolder() then
		return false, "filesystem unavailable"
	end
	local safeName = sanitizeFileName(name)
	local path = self:GetConfigFolder() .. "/" .. safeName .. ".json"
	local encodedOk, encoded = pcall(HttpService.JSONEncode, HttpService, self:BuildConfig())
	if not encodedOk then
		return false, "encode failed"
	end
	local writeOk = pcall(writefile, path, encoded)
	if not writeOk then
		return false, "write failed"
	end
	return true, safeName
end

function App:LoadConfig(name, fireCallbacks)
	if not self:EnsureConfigFolder() then
		return false, "filesystem unavailable"
	end
	local safeName = sanitizeFileName(name)
	local path = self:GetConfigFolder() .. "/" .. safeName .. ".json"
	if typeof(isfile) ~= "function" or not isfile(path) then
		return false, "missing file"
	end
	local readOk, contents = pcall(readfile, path)
	if not readOk then
		return false, "read failed"
	end
	local decodedOk, decoded = pcall(HttpService.JSONDecode, HttpService, contents)
	if not decodedOk or type(decoded) ~= "table" then
		return false, "invalid json"
	end
	self:ApplyConfig(decoded, fireCallbacks)
	return true, safeName
end

function App:DeleteConfig(name)
	if not self:EnsureConfigFolder() then
		return false, "filesystem unavailable"
	end
	local safeName = sanitizeFileName(name)
	local path = self:GetConfigFolder() .. "/" .. safeName .. ".json"
	if typeof(delfile) ~= "function" then
		return false, "delete unavailable"
	end
	if typeof(isfile) ~= "function" or not isfile(path) then
		return false, "missing file"
	end
	local ok = pcall(delfile, path)
	if not ok then
		return false, "delete failed"
	end
	return true, safeName
end

function App:GetResizeMode(point)
	local edge = SHELL.ResizeEdge
	local right = self.position.X + self.size.X
	local bottom = self.position.Y + self.size.Y
	local onRight = math.abs(point.X - right) <= edge and point.Y >= self.position.Y and point.Y <= bottom
	local onBottom = math.abs(point.Y - bottom) <= edge and point.X >= self.position.X and point.X <= right
	if onRight and onBottom then
		return "corner"
	elseif onRight then
		return "right"
	elseif onBottom then
		return "bottom"
	end
	return nil
end

function App:HasPoint(point)
	if pointInRect(point, self.position, self.size) then
		return true
	end
	if self.openOverlay ~= nil and self.openOverlay.overlayHitTest ~= nil and self.openOverlay:overlayHitTest(point) then
		return true
	end
	return false
end

function App:IsPointInHeader(point)
	return pointInRect(point, Vector2.new(self.chrome.header.position.X, self.chrome.header.position.Y), self.chrome.header.size)
end

function App:GetNavAt(point)
	for _, page in ipairs(self.pages) do
		if pointInRect(point, page.navPosition, page.navSize) then
			return page
		end
	end
	return nil
end

function App:GetHeaderActionAt(point)
	for index, action in ipairs(self.header.actions) do
		if pointInRect(point, action.position, action.size) then
			return index, action
		end
	end
	return nil
end

function App:GetControlAt(point)
	for _, section in ipairs(self:GetActiveSections()) do
		local item = section:HitTest(point)
		if item ~= nil then
			return item
		end
	end
	for _, section in ipairs(self:GetActiveAsideSections()) do
		local item = section:HitTest(point)
		if item ~= nil then
			return item
		end
	end
	return nil
end

function App:GetPageById(id)
	for _, page in ipairs(self.pages) do
		if page.id == id or page.label == id then
			return page
		end
	end
	return nil
end

function App:SetActivePage(pageOrId)
	local page = type(pageOrId) == "table" and pageOrId or self:GetPageById(pageOrId)
	if page == nil then
		return
	end
	self.activePage = page
	self.pageTransitionAlpha = 0
	self:CloseOverlay(nil)
	clearKeybindListening()
	self:MarkLayoutDirty()
end

function App:SetHeader(options)
	local settings = options or {}
	self.header.title = tostring(settings.title or self.header.title or self.title)
	self.header.subtitle = tostring(settings.subtitle or self.header.subtitle or self.subtitle)
	self.header.status = tostring(settings.status or self.header.status or "")
	for _, action in ipairs(self.header.actions) do
		destroyDrawing(action.frame)
		destroyDrawing(action.outline)
		destroyDrawing(action.textDrawing)
	end
	self.header.actions = {}
	for _, action in ipairs(settings.actions or {}) do
		table.insert(self.header.actions, {
			text = tostring(action.text or "Action"),
			callback = action.callback or function() end,
			position = Vector2.zero,
			size = Vector2.zero,
			frame = createDrawing("Square", {
				Visible = self.visible,
				Filled = true,
				Color = self.theme.Panel,
				Position = Vector2.zero,
				Size = Vector2.zero,
				Transparency = 1,
			}),
			outline = createDrawing("Square", {
				Visible = self.visible,
				Filled = false,
				Color = self.theme.SoftBorder,
				Position = Vector2.zero,
				Size = Vector2.zero,
				Transparency = 1,
			}),
			textDrawing = createDrawing("Text", {
				Visible = self.visible,
				Color = self.theme.Text,
				Size = self.theme.SmallTextSize,
				Font = self.theme.Font,
				Text = tostring(action.text or "Action"),
				Position = Vector2.zero,
				Outline = false,
				Transparency = 1,
			}),
			hoverAlpha = 0,
		})
	end
	self:MarkLayoutDirty()
end

function App:SetAside(builder)
	self.sharedAsideSections = {}
	if type(builder) == "function" then
		builder(makeContainerHost(self, self.activePage or self.pages[1], self.sharedAsideSections))
	end
	self:MarkLayoutDirty()
end

function App:SetDensity(density)
	self.densityName = density == "compact" and "compact" or "comfortable"
	self.density = DENSITY[self.densityName]
	self:MarkLayoutDirty()
end

function App:SetMotion(mode)
	self.motionMode = mode == "off" and "off" or mode == "reduced" and "reduced" or "full"
	self:MarkPaintDirty()
end

function App:SetTheme(themeOverrides)
	self.theme = mergeTheme(themeOverrides or {})
	destroyDrawings(self.drawings)
	createShellDrawings(self)
	for _, page in ipairs(self.pages) do
		writeProperty(page.drawings.frame, "Color", self.theme.Nav)
		writeProperty(page.drawings.activePill, "Color", self.theme.NavActive)
		writeProperty(page.drawings.icon, "Color", self.theme.NavText)
		writeProperty(page.drawings.text, "Color", self.theme.NavText)
		writeProperty(page.drawings.badge, "Color", self.theme.HighlightText)
		for _, section in ipairs(page.sections) do
			section:applyTheme()
		end
		for _, section in ipairs(page.asideSections) do
			section:applyTheme()
		end
	end
	for _, section in ipairs(self.sharedAsideSections) do
		section:applyTheme()
	end
	for _, action in ipairs(self.header.actions) do
		writeProperty(action.frame, "Color", self.theme.Panel)
		writeProperty(action.outline, "Color", self.theme.SoftBorder)
		writeProperty(action.textDrawing, "Color", self.theme.Text)
	end
	self:MarkLayoutDirty()
end

function App:SetTitle(text)
	self.title = tostring(text or "")
	self.header.title = self.title
	writeProperty(self.drawings.identity, "Text", self.title)
	writeProperty(self.drawings.pageTitle, "Text", self.title)
	self:MarkLayoutDirty()
end

function App:SetSubtitle(text)
	self.subtitle = tostring(text or "")
	self.header.subtitle = self.subtitle
	self:MarkLayoutDirty()
end

function App:SetVisible(isVisible)
	self.visible = isVisible == true
	if not self.visible then
		if activeTextbox ~= nil and activeTextbox.app == self then
			clearTextboxFocus(false)
		end
		if listeningKeybind ~= nil and listeningKeybind.app == self then
			clearKeybindListening()
		end
		self:CloseOverlay(nil)
		for _, page in ipairs(self.pages) do
			for _, section in ipairs(page.sections) do
				setItemVisibility(section, false)
			end
			for _, section in ipairs(page.asideSections) do
				setItemVisibility(section, false)
			end
		end
		for _, section in ipairs(self.sharedAsideSections) do
			setItemVisibility(section, false)
		end
	end
	self:MarkPaintDirty()
end

function App:SetPosition(position)
	self.position = position
	self:MarkLayoutDirty()
end

function App:SetSize(size)
	self.size = Vector2.new(math.max(size.X, self.minimumSize.X), math.max(size.Y, self.minimumSize.Y))
	self:MarkLayoutDirty()
end

function App:ClampToViewport()
	local viewport = getViewportSize()
	local maxWidth = math.max(self.minimumSize.X, viewport.X - 16)
	local maxHeight = math.max(self.minimumSize.Y, viewport.Y - 16)
	self.size = Vector2.new(
		clamp(self.size.X, self.minimumSize.X, maxWidth),
		clamp(self.size.Y, self.minimumSize.Y, maxHeight)
	)
	self.position = Vector2.new(
		clamp(self.position.X, 8, viewport.X - self.size.X - 8),
		clamp(self.position.Y, 8, viewport.Y - self.size.Y - 8)
	)
end

function App:RefreshZIndex()
	local z = self.zBase
	writeProperty(self.drawings.shadow, "ZIndex", z)
	writeProperty(self.drawings.frame, "ZIndex", z + 1)
	writeProperty(self.drawings.sidebar, "ZIndex", z + 2)
	writeProperty(self.drawings.header, "ZIndex", z + 2)
	writeProperty(self.drawings.canvas, "ZIndex", z + 2)
	writeProperty(self.drawings.aside, "ZIndex", z + 2)
	writeProperty(self.drawings.outline, "ZIndex", z + 3)
	writeProperty(self.drawings.sidebarDivider, "ZIndex", z + 4)
	writeProperty(self.drawings.headerDivider, "ZIndex", z + 4)
	writeProperty(self.drawings.asideDivider, "ZIndex", z + 4)
	writeProperty(self.drawings.identity, "ZIndex", z + 5)
	writeProperty(self.drawings.identitySub, "ZIndex", z + 5)
	writeProperty(self.drawings.pageTitle, "ZIndex", z + 5)
	writeProperty(self.drawings.pageSubtitle, "ZIndex", z + 5)
	writeProperty(self.drawings.searchChip, "ZIndex", z + 6)
	writeProperty(self.drawings.searchChipOutline, "ZIndex", z + 7)
	writeProperty(self.drawings.searchChipText, "ZIndex", z + 8)
	writeProperty(self.drawings.contentScrollbar, "ZIndex", z + 10)
	writeProperty(self.drawings.asideScrollbar, "ZIndex", z + 10)
	for index, page in ipairs(self.pages) do
		local base = z + 20 + (index * 8)
		writeProperty(page.drawings.frame, "ZIndex", base)
		writeProperty(page.drawings.activePill, "ZIndex", base + 1)
		writeProperty(page.drawings.icon, "ZIndex", base + 2)
		writeProperty(page.drawings.text, "ZIndex", base + 2)
		writeProperty(page.drawings.badge, "ZIndex", base + 3)
	end
	for _, action in ipairs(self.header.actions) do
		writeProperty(action.frame, "ZIndex", z + 30)
		writeProperty(action.outline, "ZIndex", z + 31)
		writeProperty(action.textDrawing, "ZIndex", z + 32)
	end
	local sectionZ = z + 60
	for _, page in ipairs(self.pages) do
		for _, section in ipairs(page.sections) do
			section:setZIndex(sectionZ)
			sectionZ = sectionZ + 80
		end
		for _, section in ipairs(page.asideSections) do
			section:setZIndex(sectionZ)
			sectionZ = sectionZ + 80
		end
	end
	for _, section in ipairs(self.sharedAsideSections) do
		section:setZIndex(sectionZ)
		sectionZ = sectionZ + 80
	end
end

function App:UpdateChrome()
	self:ClampToViewport()
	local chrome = {}
	chrome.sidebarWidth = self.size.X < 900 and SHELL.SidebarCollapsedWidth or SHELL.SidebarWidth
	chrome.showAside = self:HasAside() and self.size.X >= 1100 and self.asideCollapsed ~= true
	chrome.asideWidth = chrome.showAside and SHELL.AsideWidth or 0
	chrome.frame = makeRect(self.position, self.size)
	chrome.sidebar = makeRect(self.position, Vector2.new(chrome.sidebarWidth, self.size.Y))
	chrome.header = makeRect(self.position + Vector2.new(chrome.sidebarWidth, 0), Vector2.new(self.size.X - chrome.sidebarWidth, SHELL.HeaderHeight))
	chrome.canvas = makeRect(self.position + Vector2.new(chrome.sidebarWidth, SHELL.HeaderHeight), Vector2.new(self.size.X - chrome.sidebarWidth - chrome.asideWidth, self.size.Y - SHELL.HeaderHeight))
	chrome.contentViewport = makeRect(chrome.canvas.position, chrome.canvas.size)
	chrome.contentInner = makeRect(chrome.canvas.position + Vector2.new(SHELL.OuterPadding, SHELL.OuterPadding), chrome.canvas.size - Vector2.new(SHELL.OuterPadding * 2, SHELL.OuterPadding * 2))
	chrome.aside = makeRect(self.position + Vector2.new(self.size.X - chrome.asideWidth, SHELL.HeaderHeight), Vector2.new(chrome.asideWidth, self.size.Y - SHELL.HeaderHeight))
	self.chrome = chrome

	writeProperty(self.drawings.shadow, "Position", self.position + Vector2.new(0, 6))
	writeProperty(self.drawings.shadow, "Size", self.size)
	writeProperty(self.drawings.frame, "Position", self.position)
	writeProperty(self.drawings.frame, "Size", self.size)
	writeProperty(self.drawings.outline, "Position", self.position)
	writeProperty(self.drawings.outline, "Size", self.size)
	writeProperty(self.drawings.sidebar, "Position", chrome.sidebar.position)
	writeProperty(self.drawings.sidebar, "Size", chrome.sidebar.size)
	writeProperty(self.drawings.header, "Position", chrome.header.position)
	writeProperty(self.drawings.header, "Size", chrome.header.size)
	writeProperty(self.drawings.canvas, "Position", chrome.canvas.position)
	writeProperty(self.drawings.canvas, "Size", chrome.canvas.size)
	setDrawingVisibility(self.drawings.aside, chrome.showAside, 1)
	setDrawingVisibility(self.drawings.asideDivider, chrome.showAside, 1)
	if chrome.showAside then
		writeProperty(self.drawings.aside, "Position", chrome.aside.position)
		writeProperty(self.drawings.aside, "Size", chrome.aside.size)
		writeProperty(self.drawings.asideDivider, "From", Vector2.new(chrome.aside.position.X, chrome.aside.position.Y))
		writeProperty(self.drawings.asideDivider, "To", Vector2.new(chrome.aside.position.X, chrome.aside.position.Y + chrome.aside.size.Y))
	end
	writeProperty(self.drawings.sidebarDivider, "From", Vector2.new(chrome.sidebar.position.X + chrome.sidebar.size.X, chrome.sidebar.position.Y))
	writeProperty(self.drawings.sidebarDivider, "To", Vector2.new(chrome.sidebar.position.X + chrome.sidebar.size.X, chrome.sidebar.position.Y + chrome.sidebar.size.Y))
	writeProperty(self.drawings.headerDivider, "From", Vector2.new(chrome.header.position.X, chrome.header.position.Y + chrome.header.size.Y))
	writeProperty(self.drawings.headerDivider, "To", Vector2.new(chrome.header.position.X + chrome.header.size.X, chrome.header.position.Y + chrome.header.size.Y))

	local sidebarCollapsed = chrome.sidebarWidth == SHELL.SidebarCollapsedWidth
	writeProperty(self.drawings.identity, "Text", sidebarCollapsed and string.sub(self.title, 1, 1) or self.title)
	writeProperty(self.drawings.identity, "Position", chrome.sidebar.position + Vector2.new(18, 20))
	setDrawingVisibility(self.drawings.identitySub, not sidebarCollapsed, 1)
	if not sidebarCollapsed then
		writeProperty(self.drawings.identitySub, "Position", chrome.sidebar.position + Vector2.new(18, 44))
	end

	local activePage = self.activePage or self.pages[1]
	writeProperty(self.drawings.pageTitle, "Text", self.header.title ~= "" and self.header.title or (activePage and activePage.label or self.title))
	writeProperty(self.drawings.pageSubtitle, "Text", self.header.subtitle)
	writeProperty(self.drawings.pageTitle, "Position", chrome.header.position + Vector2.new(24, 14))
	writeProperty(self.drawings.pageSubtitle, "Position", chrome.header.position + Vector2.new(24, 34))

	local searchSize = Vector2.new(118, SHELL.TopActionHeight)
	local searchPosition = chrome.header.position + Vector2.new(chrome.header.size.X - searchSize.X - 24, 13)
	writeProperty(self.drawings.searchChip, "Position", searchPosition)
	writeProperty(self.drawings.searchChip, "Size", searchSize)
	writeProperty(self.drawings.searchChipOutline, "Position", searchPosition)
	writeProperty(self.drawings.searchChipOutline, "Size", searchSize)
	writeProperty(self.drawings.searchChipText, "Position", searchPosition + Vector2.new(12, 8))

	local nextActionX = searchPosition.X - 12
	for _, action in ipairs(self.header.actions) do
		action.size = Vector2.new(84, SHELL.TopActionHeight)
		action.position = Vector2.new(nextActionX - action.size.X, 13 + chrome.header.position.Y)
		nextActionX = nextActionX - action.size.X - 8
		writeProperty(action.frame, "Position", action.position)
		writeProperty(action.frame, "Size", action.size)
		writeProperty(action.outline, "Position", action.position)
		writeProperty(action.outline, "Size", action.size)
		writeProperty(action.textDrawing, "Position", action.position + Vector2.new(10, 8))
	end

	local navY = chrome.sidebar.position.Y + 96
	for _, page in ipairs(self.pages) do
		page.navPosition = Vector2.new(chrome.sidebar.position.X + 14, navY)
		page.navSize = Vector2.new(chrome.sidebar.size.X - 28, SHELL.NavItemHeight)
		navY = navY + SHELL.NavItemHeight + 8
		writeProperty(page.drawings.frame, "Position", page.navPosition)
		writeProperty(page.drawings.frame, "Size", page.navSize)
		writeProperty(page.drawings.activePill, "Position", page.navPosition)
		writeProperty(page.drawings.activePill, "Size", page.navSize)
		writeProperty(page.drawings.icon, "Position", page.navPosition + Vector2.new(10, 11))
		writeProperty(page.drawings.text, "Position", page.navPosition + Vector2.new(34, 11))
		writeProperty(page.drawings.badge, "Position", page.navPosition + Vector2.new(page.navSize.X - 18, 12))
		setDrawingVisibility(page.drawings.text, not sidebarCollapsed, 1)
		setDrawingVisibility(page.drawings.badge, not sidebarCollapsed and page.badge ~= nil, 1)
	end
end

function App:LayoutSections()
	local sections = self:GetActiveSections()
	local inner = self.chrome.contentInner
	local columns = self.size.X < 900 and 1 or 12
	local gutter = SHELL.GridGap
	local colWidth = columns == 1 and inner.size.X or ((inner.size.X - (gutter * (columns - 1))) / columns)
	local scrollOffset = self.activePage and self.activePage.scrollOffset or 0
	local cursorCol = 1
	local currentY = inner.position.Y - scrollOffset
	local rowHeight = 0
	local rowSections = {}
	local sectionIndex = 0

	local function flushRow()
		if #rowSections == 0 then
			return
		end
		for _, entry in ipairs(rowSections) do
			entry.section:Layout(entry.position, Vector2.new(entry.sizeX, rowHeight), self.chrome.contentViewport, entry.index)
		end
		currentY = currentY + rowHeight + self.density.cardGap
		rowHeight = 0
		cursorCol = 1
		table.clear(rowSections)
	end

	for _, section in ipairs(sections) do
		local span = columns == 1 and 1 or clamp(section.columnSpan, 1, 12)
		if columns ~= 1 and cursorCol + span - 1 > 12 then
			flushRow()
		end
		sectionIndex = sectionIndex + 1
		local x = inner.position.X + ((cursorCol - 1) * (colWidth + gutter))
		local width = columns == 1 and inner.size.X or ((colWidth * span) + (gutter * (span - 1)))
		local height = section:GetHeight()
		table.insert(rowSections, {
			section = section,
			position = Vector2.new(x, currentY),
			sizeX = width,
			index = sectionIndex,
		})
		rowHeight = math.max(rowHeight, height)
		cursorCol = cursorCol + span
	end

	flushRow()

	local contentHeight = math.max(0, currentY - inner.position.Y + scrollOffset)
	self.activePage.maxScroll = math.max(0, contentHeight - self.chrome.contentViewport.size.Y + SHELL.OuterPadding)
	self.activePage.scrollOffset = clamp(self.activePage.scrollOffset, 0, self.activePage.maxScroll)
	if self.activePage.maxScroll > 0 then
		local trackHeight = self.chrome.contentViewport.size.Y - 48
		local thumbHeight = math.max(36, trackHeight * (self.chrome.contentViewport.size.Y / math.max(self.chrome.contentViewport.size.Y, contentHeight + 1)))
		local scrollAlpha = self.activePage.scrollOffset / math.max(1, self.activePage.maxScroll)
		setDrawingVisibility(self.drawings.contentScrollbar, true, 0.75)
		writeProperty(self.drawings.contentScrollbar, "Position", Vector2.new(self.chrome.contentViewport.position.X + self.chrome.contentViewport.size.X - 6, self.chrome.contentViewport.position.Y + 24 + ((trackHeight - thumbHeight) * scrollAlpha)))
		writeProperty(self.drawings.contentScrollbar, "Size", Vector2.new(3, thumbHeight))
	else
		setDrawingVisibility(self.drawings.contentScrollbar, false, 1)
	end
end

function App:LayoutAside()
	local asideSections = self:GetActiveAsideSections()
	if not self.chrome.showAside then
		setDrawingVisibility(self.drawings.asideScrollbar, false, 1)
		return
	end
	local viewport = makeRect(self.chrome.aside.position, self.chrome.aside.size)
	local inner = makeRect(self.chrome.aside.position + Vector2.new(18, 18), self.chrome.aside.size - Vector2.new(36, 36))
	local page = self.activePage
	local scrollOffset = page.asideScrollOffset or 0
	local currentY = inner.position.Y - scrollOffset
	local totalHeight = 0
	for index, section in ipairs(asideSections) do
		local height = section:GetHeight()
		section:Layout(Vector2.new(inner.position.X, currentY), Vector2.new(inner.size.X, height), viewport, index)
		currentY = currentY + height + self.density.cardGap
		totalHeight = totalHeight + height + self.density.cardGap
	end
	page.maxAsideScroll = math.max(0, totalHeight - viewport.size.Y + 16)
	page.asideScrollOffset = clamp(page.asideScrollOffset, 0, page.maxAsideScroll)
	if page.maxAsideScroll > 0 then
		local trackHeight = viewport.size.Y - 40
		local thumbHeight = math.max(32, trackHeight * (viewport.size.Y / math.max(viewport.size.Y, totalHeight)))
		local scrollAlpha = page.asideScrollOffset / math.max(1, page.maxAsideScroll)
		setDrawingVisibility(self.drawings.asideScrollbar, true, 0.75)
		writeProperty(self.drawings.asideScrollbar, "Position", Vector2.new(viewport.position.X + viewport.size.X - 6, viewport.position.Y + 20 + ((trackHeight - thumbHeight) * scrollAlpha)))
		writeProperty(self.drawings.asideScrollbar, "Size", Vector2.new(3, thumbHeight))
	else
		setDrawingVisibility(self.drawings.asideScrollbar, false, 1)
	end
end

function App:UpdateLayout()
	self:UpdateChrome()
	if self.activePage ~= nil then
		self:LayoutSections()
		self:LayoutAside()
	end
	self.layoutDirty = false
	self:RefreshZIndex()
end

function App:UpdateShellVisuals(mousePosition, dt)
	local sidebarCollapsed = self.chrome.sidebarWidth == SHELL.SidebarCollapsedWidth
	for _, page in ipairs(self.pages) do
		local hovered = self.visible and pointInRect(mousePosition, page.navPosition, page.navSize)
		page.navHoverAlpha = animateToward(page.navHoverAlpha, hovered and 1 or 0, getMotionDuration(self, "fast"), dt)
		local active = self.activePage == page
		writeProperty(page.drawings.frame, "Color", active and self.theme.NavActive or colorLerp(self.theme.Nav, self.theme.NavHover, page.navHoverAlpha))
		setDrawingVisibility(page.drawings.activePill, active, 1)
		writeProperty(page.drawings.icon, "Color", active and self.theme.Text or colorLerp(self.theme.NavText, self.theme.Text, page.navHoverAlpha * 0.2))
		writeProperty(page.drawings.text, "Color", active and self.theme.Text or self.theme.NavText)
		writeProperty(page.drawings.badge, "Color", active and self.theme.HighlightText or self.theme.Muted)
		if sidebarCollapsed then
			setDrawingVisibility(page.drawings.text, false, 1)
			setDrawingVisibility(page.drawings.badge, false, 1)
		end
	end
	for _, action in ipairs(self.header.actions) do
		local hovered = pointInRect(mousePosition, action.position, action.size)
		action.hoverAlpha = animateToward(action.hoverAlpha, hovered and 1 or 0, getMotionDuration(self, "fast"), dt)
		writeProperty(action.frame, "Color", colorLerp(self.theme.Panel, self.theme.ButtonHover, action.hoverAlpha))
		writeProperty(action.outline, "Color", action.hoverAlpha > 0.2 and self.theme.AccentSoft or self.theme.SoftBorder)
	end
end

function App:HandleMouseWheel(point, delta)
	if self.openOverlay ~= nil and self.openOverlay.overlayHitTest ~= nil and self.openOverlay:overlayHitTest(point) then
		if self.openOverlay.onOverlayMouseWheel ~= nil then
			return self.openOverlay:onOverlayMouseWheel(delta) == true
		end
		return false
	end
	if pointInBounds(point, self.chrome.contentViewport) then
		self.activePage.scrollOffset = clamp(self.activePage.scrollOffset - (delta * 30), 0, self.activePage.maxScroll or 0)
		self:MarkLayoutDirty()
		return true
	end
	if self.chrome.showAside and pointInBounds(point, self.chrome.aside) then
		self.activePage.asideScrollOffset = clamp(self.activePage.asideScrollOffset - (delta * 30), 0, self.activePage.maxAsideScroll or 0)
		self:MarkLayoutDirty()
		return true
	end
	return false
end

function App:HandleMouseDown(point)
	if self.openOverlay ~= nil and self.openOverlay.overlayHitTest ~= nil and self.openOverlay:overlayHitTest(point) then
		self.openOverlay:onOverlayMouseDown(point)
		return
	end
	local resizeMode = self:GetResizeMode(point)
	if resizeMode ~= nil then
		self.resizing = resizeMode
		self.resizeStart = { mouse = point, size = self.size, position = self.position }
		return
	end
	local page = self:GetNavAt(point)
	if page ~= nil then
		self:SetActivePage(page)
		return
	end
	local actionIndex, action = self:GetHeaderActionAt(point)
	if actionIndex ~= nil then
		self.pressedHeaderAction = action
		return
	end
	if self:IsPointInHeader(point) then
		self.dragging = true
		self.dragOffset = point - self.position
		return
	end
	local control = self:GetControlAt(point)
	if control ~= nil then
		if not control.acceptsTextInput then
			clearTextboxFocus(true)
		end
		if not control.capturesBindings then
			clearKeybindListening()
		end
		if not control.isDropdown and self.openOverlay ~= control then
			self:CloseOverlay(nil)
		end
		control:onMouseDown(point)
	else
		clearTextboxFocus(true)
		clearKeybindListening()
		self:CloseOverlay(nil)
	end
end

function App:HandleMouseUp(point)
	self.dragging = false
	self.resizing = nil
	if self.openOverlay ~= nil and self.openOverlay.onOverlayMouseUp ~= nil then
		self.openOverlay:onOverlayMouseUp(point)
	end
	if self.pressedHeaderAction ~= nil and pointInRect(point, self.pressedHeaderAction.position, self.pressedHeaderAction.size) then
		self.pressedHeaderAction.callback()
	end
	self.pressedHeaderAction = nil
	for _, section in ipairs(self:GetActiveSections()) do
		section:HandleMouseUp(point)
	end
	for _, section in ipairs(self:GetActiveAsideSections()) do
		section:HandleMouseUp(point)
	end
end

function App:Step(mousePosition, dt)
	if not self.visible then
		for _, drawing in pairs(self.drawings) do
			writeProperty(drawing, "Visible", false)
		end
		for _, page in ipairs(self.pages) do
			for _, drawing in pairs(page.drawings) do
				writeProperty(drawing, "Visible", false)
			end
			for _, section in ipairs(page.sections) do
				setItemVisibility(section, false)
			end
			for _, section in ipairs(page.asideSections) do
				setItemVisibility(section, false)
			end
		end
		for _, section in ipairs(self.sharedAsideSections) do
			setItemVisibility(section, false)
		end
		return
	end
	for _, drawing in pairs(self.drawings) do
		writeProperty(drawing, "Visible", true)
	end
	for _, page in ipairs(self.pages) do
		for _, drawing in pairs(page.drawings) do
			writeProperty(drawing, "Visible", true)
		end
	end
	if self.dragging then
		self.position = mousePosition - self.dragOffset
		self:MarkLayoutDirty()
	end
	if self.resizing ~= nil and self.resizeStart ~= nil then
		local delta = mousePosition - self.resizeStart.mouse
		if self.resizing == "right" or self.resizing == "corner" then
			self.size = Vector2.new(math.max(self.minimumSize.X, self.resizeStart.size.X + delta.X), self.size.Y)
		end
		if self.resizing == "bottom" or self.resizing == "corner" then
			self.size = Vector2.new(self.size.X, math.max(self.minimumSize.Y, self.resizeStart.size.Y + delta.Y))
		end
		self:MarkLayoutDirty()
	end
	self.openAlpha = animateToward(self.openAlpha, 1, getMotionDuration(self, "open"), dt)
	if self.layoutDirty then
		self:UpdateLayout()
	end
	self.pageTransitionAlpha = animateToward(self.pageTransitionAlpha, 1, getMotionDuration(self, "fast"), dt)
	self:UpdateShellVisuals(mousePosition, dt)
	for _, section in ipairs(self:GetActiveSections()) do
		section:Step(mousePosition, dt)
	end
	for _, section in ipairs(self:GetActiveAsideSections()) do
		section:Step(mousePosition, dt)
	end
	if self.openOverlay ~= nil and self.openOverlay.onStep ~= nil then
		self.openOverlay:onStep(mousePosition, true, dt)
	end
end

function App:Destroy()
	if activeTextbox ~= nil and activeTextbox.app == self then
		clearTextboxFocus(false)
	end
	if listeningKeybind ~= nil and listeningKeybind.app == self then
		clearKeybindListening()
	end
	self:CloseOverlay(nil)
	for _, page in ipairs(self.pages) do
		destroyDrawings(page.drawings)
		for _, section in ipairs(page.sections) do
			section:destroy()
		end
		for _, section in ipairs(page.asideSections) do
			section:destroy()
		end
	end
	for _, section in ipairs(self.sharedAsideSections) do
		section:destroy()
	end
	for _, action in ipairs(self.header.actions) do
		destroyDrawing(action.frame)
		destroyDrawing(action.outline)
		destroyDrawing(action.textDrawing)
	end
	destroyDrawings(self.drawings)
	for index, app in ipairs(apps) do
		if app == self then
			table.remove(apps, index)
			break
		end
	end
	if #apps == 0 then
		if frameConnection ~= nil then
			frameConnection:Disconnect()
			frameConnection = nil
		end
		if inputBeganConnection ~= nil then
			inputBeganConnection:Disconnect()
			inputBeganConnection = nil
		end
		if inputChangedConnection ~= nil then
			inputChangedConnection:Disconnect()
			inputChangedConnection = nil
		end
		if inputEndedConnection ~= nil then
			inputEndedConnection:Disconnect()
			inputEndedConnection = nil
		end
	end
end

function App:AddPage(options)
	local page = makePage(self, options)
	table.insert(self.pages, page)
	if self.activePage == nil then
		self.activePage = page
	end
	self:MarkLayoutDirty()
	return page
end

function App:EnsureDefaultPage()
	if self.defaultPage == nil then
		self.defaultPage = self:AddPage({ id = "overview", label = "Overview", icon = "O" })
	end
	return self.defaultPage
end

function App:AddLabel(text)
	return self:EnsureDefaultPage():AddLabel(text)
end
function App:AddParagraph(title, text)
	return self:EnsureDefaultPage():AddParagraph(title, text)
end
function App:AddSection(value)
	if type(value) == "table" then
		return self:EnsureDefaultPage():AddSection(value)
	end
	return self:EnsureDefaultPage():AddSection(value)
end
function App:AddSubTab(text, expanded)
	return self:EnsureDefaultPage():AddGroup({ title = text, collapsible = true, defaultOpen = expanded ~= false })
end
function App:AddButton(text, callback)
	return self:EnsureDefaultPage():AddButton(text, callback)
end
function App:AddButtonRow(buttons)
	return self:EnsureDefaultPage():AddButtonRow(buttons)
end
function App:AddToggle(text, initialValue, callback)
	return self:EnsureDefaultPage():AddToggle(text, initialValue, callback)
end
function App:AddSlider(text, minimum, maximum, initialValue, callback)
	return self:EnsureDefaultPage():AddSlider(text, minimum, maximum, initialValue, callback)
end
function App:AddDropdown(text, options, defaultValue, callback)
	return self:EnsureDefaultPage():AddDropdown(text, options, defaultValue, callback)
end
function App:AddSearchDropdown(text, options, defaultValue, maxSizeOrCallback, callback)
	return self:EnsureDefaultPage():AddSearchDropdown(text, options, defaultValue, maxSizeOrCallback, callback)
end
function App:AddMultiDropdown(text, options, defaultValues, callback)
	return self:EnsureDefaultPage():AddMultiDropdown(text, options, defaultValues, callback)
end
function App:AddColorPicker(text, defaultColor, callback)
	return self:EnsureDefaultPage():AddColorPicker(text, defaultColor, callback)
end
function App:AddTextbox(text, placeholder, callback)
	return self:EnsureDefaultPage():AddTextbox(text, placeholder, callback)
end
function App:AddKeybind(text, defaultKey, callback, changedCallback)
	return self:EnsureDefaultPage():AddKeybind(text, defaultKey, callback, changedCallback)
end
function App:AddTab(name)
	return self:AddPage({ id = sanitizeFileName(name), label = tostring(name or "Page"), icon = string.sub(tostring(name or "P"), 1, 1) })
end
function App:SetActiveTab(nameOrTab)
	self:SetActivePage(nameOrTab)
end

local function ensureLoop()
	if frameConnection == nil then
		frameConnection = RunService.RenderStepped:Connect(function(dt)
			local mousePosition = getMousePosition()
			for _, app in ipairs(apps) do
				app:Step(mousePosition, dt)
			end
		end)
	end
	if inputBeganConnection == nil then
		inputBeganConnection = UserInputService.InputBegan:Connect(function(input, processed)
			if input.UserInputType == Enum.UserInputType.Keyboard and activeTextbox ~= nil then
				activeTextbox:HandleKeyboardInput(input)
				return
			end
			if listeningKeybind ~= nil then
				listeningKeybind:CaptureInput(input)
				return
			end
			if processed then
				return
			end
			for _, app in ipairs(apps) do
				for _, control in ipairs(app.boundControls) do
					if control.kind == "Keybind" and bindingMatchesInput(control.binding, input) then
						control.callback(control.binding)
					elseif control.kind == "Button" and control.activationBinding ~= nil and bindingMatchesInput(control.activationBinding, input) then
						control:TriggerActivation()
					end
				end
			end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local point = getMousePosition()
			local app = topAppAt(point)
			if app == nil then
				clearTextboxFocus(true)
				clearKeybindListening()
				return
			end
			bringAppToFront(app)
			app:HandleMouseDown(point)
		end)
	end
	if inputChangedConnection == nil then
		inputChangedConnection = UserInputService.InputChanged:Connect(function(input, processed)
			if processed then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				local point = getMousePosition()
				local app = topAppAt(point)
				if app ~= nil then
					app:HandleMouseWheel(point, input.Position.Z > 0 and 1 or -1)
				end
			end
		end)
	end
	if inputEndedConnection == nil then
		inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local point = getMousePosition()
			for _, app in ipairs(apps) do
				app:HandleMouseUp(point)
			end
		end)
	end
end

function DrawingUI.CreateTheme(overrides)
	return mergeTheme(overrides)
end

function DrawingUI.CreateApp(options)
	local settings = shallowCopy(DEFAULT_OPTIONS)
	for key, value in pairs(options or {}) do
		settings[key] = value
	end
	local size = settings.Size or computeDefaultSize()
	local position = settings.Position or computeDefaultPosition(size)
	local theme = type(settings.Theme) == "table" and mergeTheme(settings.Theme) or mergeTheme(DEFAULT_THEME)
	local app = setmetatable({
		title = tostring(settings.Title or "Drawing UI"),
		subtitle = "",
		position = position,
		size = size,
		minimumSize = settings.MinSize or Vector2.new(SHELL.MinWidth, SHELL.MinHeight),
		visible = settings.Visible ~= false,
		configRoot = settings.ConfigRoot,
		configId = settings.ConfigId,
		theme = theme,
		densityName = settings.Density == "compact" and "compact" or "comfortable",
		density = DENSITY[settings.Density == "compact" and "compact" or "comfortable"],
		motionMode = settings.MotionMode == "reduced" and "reduced" or settings.MotionMode == "off" and "off" or "full",
		layoutDirty = true,
		paintDirty = true,
		openAlpha = 0,
		pageTransitionAlpha = 1,
		header = { title = tostring(settings.Title or "Drawing UI"), subtitle = "", status = "", actions = {} },
		pages = {},
		sharedAsideSections = {},
		activePage = nil,
		defaultPage = nil,
		openOverlay = nil,
		asideCollapsed = false,
		zBase = 100,
		boundControls = {},
		dragAnywhere = settings.DragAnywhere == true,
	}, App)
	createShellDrawings(app)
	app:SetHeader({ title = app.title, subtitle = "", actions = {} })
	table.insert(apps, app)
	bringAppToFront(app)
	ensureLoop()
	app:UpdateLayout()
	return app
end

function DrawingUI.CreateWindow(options)
	local app = DrawingUI.CreateApp(options)
	app.compatWindow = true
	return app
end

DrawingUI.new = DrawingUI.CreateWindow
DrawingUI.Version = VERSION
DrawingUI.Themes = {
	Default = mergeTheme(THEMES.Default),
	Amber = mergeTheme(THEMES.Amber),
	Midnight = mergeTheme(THEMES.Midnight),
	Circuit = mergeTheme(THEMES.Circuit),
}

function DrawingUI.ClearAll()
	while #apps > 0 do
		apps[#apps]:Destroy()
	end
	if typeof(cleardrawcache) == "function" then
		pcall(cleardrawcache)
	end
end

return DrawingUI
