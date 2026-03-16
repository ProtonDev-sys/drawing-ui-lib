# DrawingUI

## Quick Start

```lua
local DrawingUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/drawing-ui-lib/main/DrawingUI.lua?v=0.11.1"))()

local window = DrawingUI.CreateWindow({
	Title = "Example Hub",
	Position = Vector2.new(140, 90),
	Size = Vector2.new(500, 350),
	ConfigId = "example-hub",
	Theme = DrawingUI.Themes.Circuit,
})

window:SetSubtitle("basic showcase")

local mainTab = window:AddTab("Main")
local settingsGroup = mainTab:AddSubTab("Settings", true)
local statusLabel = settingsGroup:AddLabel("Enabled: false")

settingsGroup:AddToggle("Enabled", false, function(value)
	statusLabel:SetText("Enabled: " .. tostring(value))
end)

settingsGroup:AddSlider("FOV Radius", 40, 400, 140, function(value)
	print("FOV:", math.floor(value + 0.5))
end)

settingsGroup:AddSearchDropdown("Target Part", { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }, "Head", 4, function(value)
	print("Selected target:", value)
end)

settingsGroup:AddButton("Hide UI", function()
	window:SetVisible(false)
end)

window:SetActiveTab("Main")
```

For a complete usage sample, see `examples/example_ui.lua`.

## Core Concepts

### Window-first API

You start by creating a window with `DrawingUI.CreateWindow(options)`. Controls can be added directly to the window or inside tabs.

### Tabs

`window:AddTab(name)` returns a tab object. Tabs are the primary way to organize larger menus.

### Subtabs

`window:AddSubTab(...)` and `tab:AddSubTab(...)` return an expandable group object. A subtab is a collapsible section that exposes the same `Add*` control methods as a tab.

### Control ownership

If a window has tabs, build your interactive layout inside those tabs or their subtabs. Root-level controls are best used on untabbed windows.

## Creating A Window

Create a window with:

```lua
local window = DrawingUI.CreateWindow(options)
```

Supported `options` keys:

- `Title`: window title string. Default: `"Drawing UI"`
- `Position`: `Vector2` window position. Default: `Vector2.new(200, 160)`
- `Size`: `Vector2` window size. Default: `Vector2.new(470, 360)`
- `MinSize`: optional `Vector2` minimum size. Default: `Vector2.new(Size.X, 220)`
- `Visible`: initial visibility. Default: `true`
- `DragAnywhere`: whether dragging can start anywhere in the window. Default: `true`
- `Theme`: a theme override table or preset theme table
- `ConfigId`: optional config folder identifier
- `ConfigRoot`: optional config root folder. Default: `"drawing-ui-lib-configs"`

Notes:

- The default subtitle is empty until you call `window:SetSubtitle(...)`.
- The window clamps itself to the current viewport while dragging.
- The initial width becomes the minimum width unless you supply `MinSize`.
- `window:SetSize(...)` updates the stored minimum width to the new width.

## Module API

- `DrawingUI.CreateWindow(options)`
- `DrawingUI.new(options)`
- `DrawingUI.CreateTheme(overrides)`
- `DrawingUI.ClearAll()`
- `DrawingUI.Version`
- `DrawingUI.Themes.Default`
- `DrawingUI.Themes.Amber`
- `DrawingUI.Themes.Midnight`
- `DrawingUI.Themes.Circuit`

## Window API

- `window:AddLabel(text)`
- `window:AddParagraph(title, text)`
- `window:AddSection(text)`
- `window:AddSubTab(text, expanded?)`
- `window:AddButton(text, callback)`
- `window:AddButtonRow(buttons)`
- `window:AddToggle(text, initialValue, callback)`
- `window:AddSlider(text, min, max, initialValue, callback)`
- `window:AddDropdown(text, options, defaultValue, callback)`
- `window:AddSearchDropdown(text, options, defaultValue, callback)`
- `window:AddSearchDropdown(text, options, defaultValue, maxSize, callback)`
- `window:AddMultiDropdown(text, options, defaultValues, callback)`
- `window:AddColorPicker(text, defaultColor, callback)`
- `window:AddTextbox(text, placeholder, callback)`
- `window:AddKeybind(text, defaultKey, callback, changedCallback?)`
- `window:AddTab(name)`
- `window:SetActiveTab(nameOrTab)`
- `window:SetTheme(themeOverrides)`
- `window:SetTitle(text)`
- `window:SetSubtitle(text)`
- `window:SetPosition(Vector2)`
- `window:SetSize(Vector2)`
- `window:SetVisible(boolean)`
- `window:GetConfigId()`
- `window:GetConfigFolder()`
- `window:BuildConfig()`
- `window:ApplyConfig(config, fireCallbacks?)`
- `window:ListConfigs()`
- `window:SaveConfig(name)`
- `window:LoadConfig(name, fireCallbacks?)`
- `window:DeleteConfig(name)`
- `window:Destroy()`

## Tab API

- `tab:AddLabel(text)`
- `tab:AddParagraph(title, text)`
- `tab:AddSection(text)`
- `tab:AddSubTab(text, expanded?)`
- `tab:AddButton(text, callback)`
- `tab:AddButtonRow(buttons)`
- `tab:AddToggle(text, initialValue, callback)`
- `tab:AddSlider(text, min, max, initialValue, callback)`
- `tab:AddDropdown(text, options, defaultValue, callback)`
- `tab:AddSearchDropdown(text, options, defaultValue, callback)`
- `tab:AddSearchDropdown(text, options, defaultValue, maxSize, callback)`
- `tab:AddMultiDropdown(text, options, defaultValues, callback)`
- `tab:AddColorPicker(text, defaultColor, callback)`
- `tab:AddTextbox(text, placeholder, callback)`
- `tab:AddKeybind(text, defaultKey, callback, changedCallback?)`
- `tab:Select()`

## Subtab Group API

Subtab groups expose the same layout and control builders as tabs:

- `group:AddLabel(text)`
- `group:AddParagraph(title, text)`
- `group:AddSection(text)`
- `group:AddButton(text, callback)`
- `group:AddButtonRow(buttons)`
- `group:AddToggle(text, initialValue, callback)`
- `group:AddSlider(text, min, max, initialValue, callback)`
- `group:AddDropdown(text, options, defaultValue, callback)`
- `group:AddSearchDropdown(text, options, defaultValue, callback)`
- `group:AddSearchDropdown(text, options, defaultValue, maxSize, callback)`
- `group:AddMultiDropdown(text, options, defaultValues, callback)`
- `group:AddColorPicker(text, defaultColor, callback)`
- `group:AddTextbox(text, placeholder, callback)`
- `group:AddKeybind(text, defaultKey, callback, changedCallback?)`

## Control Reference

### Static content

- `AddLabel(text)`: single-line text label
- `AddParagraph(title, text)`: wrapped description block
- `AddSection(text)`: section header with separator line
- `AddSubTab(text, expanded?)`: collapsible content group

### Buttons

- `AddButton(text, callback)`: fires `callback()` on click
- `AddButtonRow(buttons)`: creates a horizontal button group

`AddButtonRow(buttons)` expects an array of tables in this shape:

```lua
tab:AddButtonRow({
	{ text = "Save", callback = function() end },
	{ text = "Load", callback = function() end },
	{ text = "Delete", callback = function() end },
})
```

### Toggles

- `AddToggle(text, initialValue, callback)`: callback receives `boolean`

### Sliders

- `AddSlider(text, min, max, initialValue, callback)`: callback receives the current numeric value

### Dropdowns

- `AddDropdown(text, options, defaultValue, callback)`: callback receives the selected option
- `AddSearchDropdown(text, options, defaultValue, callback)`: searchable dropdown with default visible row count
- `AddSearchDropdown(text, options, defaultValue, maxSize, callback)`: searchable dropdown with explicit visible row cap
- `AddMultiDropdown(text, options, defaultValues, callback)`: callback receives a cloned array of selected options

For searchable dropdowns, `maxSize` limits how many filtered rows are visible at once. Extra matches remain accessible through scrolling and search refinement.

### Text input

- `AddTextbox(text, placeholder, callback)`: callback fires when the textbox is submitted, typically on Enter or when focus is committed

### Color input

- `AddColorPicker(text, defaultColor, callback)`: callback receives `Color3`

### Keybinds

- `AddKeybind(text, defaultKey, callback, changedCallback?)`

Keybind callback behavior:

- `callback(binding)` fires when the active binding is pressed
- `changedCallback(binding)` fires when the user changes the binding

Accepted `defaultKey` forms:

- `Enum.KeyCode.RightShift`
- `{ kind = "Keyboard", code = Enum.KeyCode.RightShift }`
- `{ kind = "MouseButton1" }`
- `{ kind = "MouseButton2" }`
- `{ kind = "MouseButton3" }`
- `nil`

Pressing `Escape` while rebinding clears the binding.

Returned keybind controls reject mouse inputs by default. To allow them:

```lua
local bindControl = tab:AddKeybind("Aim Bind", nil, function() end, function(binding)
	print(binding)
end)

bindControl:SetAllowMouseInputs(true)
```

## Returned Control Objects

Most constructors return a control object. These are useful when your UI state changes dynamically.

Common mutators exposed by the current implementation:

- Labels, paragraphs, buttons, and textboxes: `control:SetText(text)`
- Buttons and toggles: `control:SetActivationBinding(binding)`
- Toggles and sliders: `control:SetValue(value)`
- Dropdowns: `control:SetValue(value)`, `control:SetOptions(options, defaultValue?)`, `control:SetOpen(boolean)`
- Searchable dropdowns: `control:SetValue(value)`, `control:SetOptions(options, defaultValue?, maxSize?)`, `control:SetSearchText(text)`, `control:SetMaxSize(maxSize?)`, `control:SetOpen(boolean)`
- Multi-dropdowns: `control:SetValues(values)`, `control:SetOpen(boolean)`
- Color pickers: `control:SetColor(color3)`
- Keybinds: `control:SetListening(boolean)`, `control:SetBinding(binding)`, `control:SetAllowMouseInputs(boolean)`
- Tabs: `tab:Select()`

These mutators are part of the current public-facing implementation and are safe to use for normal menu state updates.

## Theming

Use a built-in preset:

```lua
window:SetTheme(DrawingUI.Themes.Circuit)
```

Or apply overrides:

```lua
window:SetTheme({
	Accent = Color3.fromRGB(255, 90, 90),
	ToggleEnabled = Color3.fromRGB(255, 90, 90),
	SliderFill = Color3.fromRGB(255, 90, 90),
})
```

`DrawingUI.CreateTheme(overrides)` merges your overrides into the default theme and returns a reusable theme table.

Available theme keys:

- `Accent`
- `WindowBackground`
- `HeaderBackground`
- `Border`
- `Text`
- `SubText`
- `Muted`
- `Button`
- `ButtonHover`
- `Input`
- `InputHover`
- `InputFocused`
- `Tab`
- `TabHover`
- `TabActive`
- `Panel`
- `PanelHeader`
- `Toggle`
- `ToggleEnabled`
- `SliderTrack`
- `SliderFill`
- `SectionLine`
- `InnerBorder`
- `HighlightText`
- `Font`
- `TitleSize`
- `TextSize`
- `SmallTextSize`

`window:SetTheme(...)` merges into the current theme, not a fresh default. If you want a full theme switch, pass a complete preset such as `DrawingUI.Themes.Circuit` first, then apply smaller overrides if needed.

## Config Persistence

If your environment supports executor filesystem APIs, each window can save and load control values as JSON.

Available methods:

- `window:BuildConfig()`
- `window:ApplyConfig(config, fireCallbacks?)`
- `window:ListConfigs()`
- `window:SaveConfig(name)`
- `window:LoadConfig(name, fireCallbacks?)`
- `window:DeleteConfig(name)`

Saved files are stored under:

```text
<ConfigRoot>/<ConfigId>/*.json
```

Defaults:

- `ConfigRoot`: `drawing-ui-lib-configs`
- `ConfigId`: sanitized `window.Title`

Important behavior:

- Only controls with a config value participate in save/load: toggles, sliders, dropdowns, searchable dropdowns, multi-dropdowns, textboxes, color pickers, and keybinds
- Config keys are derived from the control label text, so stateful controls should use unique labels if you rely on persistence
- `window:LoadConfig(name, false)` applies values silently
- `window:LoadConfig(name, true)` reapplies values and fires callbacks

## Cleanup

Destroy one window:

```lua
window:Destroy()
```

Destroy every window created by the library:

```lua
DrawingUI.ClearAll()
```

`DrawingUI.ClearAll()` also calls `cleardrawcache()` when that function exists in the current environment.


If you load directly from the raw GitHub URL, consumers only receive changes after they are committed and pushed to `main`.
