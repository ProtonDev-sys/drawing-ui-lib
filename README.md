# DrawingUI

`DrawingUI` is a drawing-based UI library for Roblox Luau environments that expose `Drawing.new(...)`.

It is built for executor-style environments with Drawing API support, not standard Roblox Studio GUI development. The library provides a draggable window system, common controls, tabs, theming, and cleanup utilities on top of `Drawing`, `UserInputService`, and `RunService`.

## What this project gives you

- Draggable window container with viewport clamping
- Optional drag-anywhere or header-only dragging
- Tabs
- Labels, sections, and paragraph blocks
- Buttons
- Toggles
- Sliders
- Dropdowns
- Searchable dropdowns
- Multi-select dropdowns
- Color picker
- Textboxes
- Keybind controls
- Built-in theme presets plus custom theme overrides
- Window mutators for title, subtitle, position, size, theme, tab selection, and visibility
- Cleanup helpers through `window:Destroy()` and `DrawingUI.ClearAll()`

## Repository layout

- `DrawingUI.lua`: main library
- `examples/example_ui.lua`: example menu using the public API
- `README.md`: project documentation

## Requirements

- A Roblox Luau environment that supports `Drawing.new(...)`
- Access to services such as `UserInputService`, `RunService`, and `Workspace`

If your environment does not expose the Drawing API, this library will not run.

## Loading the library

### Remote loadstring

```lua
local DrawingUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/drawing-ui-lib/main/DrawingUI.lua?v=0.10.3"))()
```

### Local usage

If you ship the file yourself, load `DrawingUI.lua` however your environment expects.

## Quick start

```lua
local DrawingUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/drawing-ui-lib/main/DrawingUI.lua?v=0.10.3"))()

local window = DrawingUI.CreateWindow({
	Title = "Example Hub",
	Position = Vector2.new(140, 90),
	Size = Vector2.new(510, 350),
	Theme = DrawingUI.Themes.Amber,
})

window:SetSubtitle("demo")

local mainTab = window:AddTab("Main")
local statusLabel = mainTab:AddLabel("Enabled: false")

mainTab:AddToggle("Enabled", false, function(value)
	statusLabel:SetText("Enabled: " .. tostring(value))
end)

mainTab:AddSearchDropdown("Target Part", { "Head", "Torso", "Closest" }, "Head", function(value)
	print("Selected:", value)
end)

mainTab:AddButton("Hide UI", function()
	window:SetVisible(false)
end)

window:SetActiveTab("Main")
```

For a fuller example, see `examples/example_ui.lua`.

## Creating a window

Create a window with:

```lua
local window = DrawingUI.CreateWindow(options)
```

Supported `options` keys:

- `Title`: window title string. Default: `"Drawing UI"`
- `Position`: `Vector2` window position. Default: `Vector2.new(200, 160)`
- `Size`: `Vector2` window size. Default: `Vector2.new(470, 360)`
- `Visible`: initial visibility. Default: `true`
- `DragAnywhere`: whether dragging can start from anywhere in the window. Default: `true`
- `Theme`: a theme override table or preset theme table

Notes:

- The default subtitle is `"drag me"` until you call `window:SetSubtitle(...)`.
- The window clamps itself to the current viewport while dragging.
- The initial size also becomes the minimum size.

## API overview

### Module API

- `DrawingUI.CreateWindow(options)`
- `DrawingUI.CreateTheme(overrides)`
- `DrawingUI.ClearAll()`
- `DrawingUI.Version`
- `DrawingUI.Themes.Default`
- `DrawingUI.Themes.Amber`
- `DrawingUI.Themes.Midnight`

### Window API

- `window:AddSection(text)`
- `window:AddLabel(text)`
- `window:AddParagraph(title, text)`
- `window:AddButton(text, callback)`
- `window:AddButtonRow(buttons)`
- `window:AddToggle(text, initialValue, callback)`
- `window:AddSlider(text, min, max, initialValue, callback)`
- `window:AddDropdown(text, options, defaultValue, callback)`
- `window:AddSearchDropdown(text, options, defaultValue, callback)`
- `window:AddMultiDropdown(text, options, defaultValues, callback)`
- `window:AddColorPicker(text, defaultColor, callback)`
- `window:AddTextbox(text, placeholder, callback)`
- `window:AddKeybind(text, defaultKey, callback, changedCallback?)`
- `window:AddTab(name)`
- `window:AddSubTab(text, expanded?)`
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

### Tab API

- `tab:AddSection(text)`
- `tab:AddLabel(text)`
- `tab:AddParagraph(title, text)`
- `tab:AddButton(text, callback)`
- `tab:AddButtonRow(buttons)`
- `tab:AddToggle(text, initialValue, callback)`
- `tab:AddSlider(text, min, max, initialValue, callback)`
- `tab:AddDropdown(text, options, defaultValue, callback)`
- `tab:AddSearchDropdown(text, options, defaultValue, callback)`
- `tab:AddMultiDropdown(text, options, defaultValues, callback)`
- `tab:AddColorPicker(text, defaultColor, callback)`
- `tab:AddTextbox(text, placeholder, callback)`
- `tab:AddKeybind(text, defaultKey, callback, changedCallback?)`
- `tab:AddSubTab(text, expanded?)`
- `tab:Select()`

## Callback behavior

- `AddButton`: fires on click
- `AddToggle`: callback receives `boolean`
- `AddSlider`: callback receives the current numeric value
- `AddDropdown`: callback receives the selected option
- `AddSearchDropdown`: callback receives the selected option
- `AddMultiDropdown`: callback receives a cloned array of selected options
- `AddColorPicker`: callback receives `Color3`
- `AddTextbox`: callback receives the submitted text
- `AddKeybind`:
  - `callback(binding)` fires when the bound input is pressed
  - `changedCallback(binding)` fires when the user changes the binding

For keybinds, `defaultKey` can be:

- An `Enum.KeyCode`
- A binding table such as `{ kind = "Keyboard", code = Enum.KeyCode.RightShift }`
- `nil` for no initial binding

Pressing `Escape` while rebinding clears the keybind.

## Returned control objects

Most constructor calls return a control object, which is useful if your menu updates dynamically.

Common mutators exposed by the current implementation include:

- Labels, paragraphs, buttons, and textboxes: `control:SetText(text)`
- Buttons and toggles: `control:SetActivationBinding(binding)`
- Toggles and sliders: `control:SetValue(value)`
- Dropdowns: `control:SetValue(value)`, `control:SetOptions(options, defaultValue?)`, `control:SetOpen(boolean)`
- Searchable dropdowns: `control:SetValue(value)`, `control:SetOptions(options, defaultValue?)`, `control:SetSearchText(text)`, `control:SetOpen(boolean)`
- Multi-dropdowns: `control:SetValues(values)`, `control:SetOpen(boolean)`
- Color pickers: `control:SetColor(color3)`
- Keybinds: `control:SetListening(boolean)`, `control:SetBinding(binding)`, `control:SetAllowMouseInputs(boolean)`

The primary supported surface is still the `window:*` and `tab:*` API above. Treat lower-level control mutators as convenience methods tied to the current implementation.

## Theming

Use a built-in preset:

```lua
window:SetTheme(DrawingUI.Themes.Amber)
```

Or pass partial overrides:

```lua
window:SetTheme({
	Accent = Color3.fromRGB(255, 90, 90),
	ToggleEnabled = Color3.fromRGB(255, 90, 90),
	SliderFill = Color3.fromRGB(255, 90, 90),
})
```

Useful theme keys include:

- `Accent`
- `WindowBackground`
- `HeaderBackground`
- `Button`
- `ButtonHover`
- `Input`
- `InputHover`
- `InputFocused`
- `Tab`
- `TabHover`
- `TabActive`
- `Toggle`
- `ToggleEnabled`
- `SliderTrack`
- `SliderFill`
- `SectionLine`
- `Border`
- `Text`
- `SubText`
- `Muted`
- `Font`
- `TitleSize`
- `TextSize`
- `SmallTextSize`

`DrawingUI.CreateTheme(overrides)` returns a merged theme table if you want to define reusable presets.

`CreateWindow` also accepts `DragAnywhere = false` if you want classic titlebar-only dragging, plus `ConfigId` and `ConfigRoot` if you want the built-in config API to save somewhere specific.

## Cleanup

Destroy a single window:

```lua
window:Destroy()
```

Destroy every window created by the library:

```lua
DrawingUI.ClearAll()
```

`DrawingUI.ClearAll()` also calls `cleardrawcache()` when that function exists in the current environment.

## Development notes

- `examples/example_ui.lua` is the best reference for typical usage
- If you load from the raw GitHub URL, consumers only receive updates after changes are pushed to `main`
