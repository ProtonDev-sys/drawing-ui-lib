# DrawingUI v2

DrawingUI v2 rebuilds the library around a desktop-style workspace shell:

- left navigation rail instead of top tabs
- fixed command/header bar
- independently scrollable content canvas
- optional right utility rail
- card-based page sections
- motion and density controls
- compatibility aliases for the v1 `CreateWindow` / `AddTab` / `AddSubTab` flow

## Quick Start

```lua
local DrawingUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/drawing-ui-lib/v2/DrawingUI.lua?v=2.0.0"))()

local app = DrawingUI.CreateApp({
	Title = "Example Hub",
	ConfigId = "example-hub-v2",
	Theme = DrawingUI.Themes.Circuit,
})

app:SetHeader({
	title = "Example Hub",
	subtitle = "premium control deck",
})

local overview = app:AddPage({
	id = "overview",
	label = "Overview",
	icon = "O",
	badge = "LIVE",
})

local section = overview:AddSection({
	title = "Primary Controls",
	description = "Main workspace content.",
	columnSpan = 7,
})

section:AddToggle("Enabled", false, function(value)
	print("Enabled:", value)
end)

section:AddSlider("FOV Radius", 40, 400, 140, function(value)
	print("FOV:", value)
end)

section:AddDropdown("Target Part", { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" }, "Head", function(value)
	print("Target:", value)
end)

overview:SetAside(function(aside)
	local utility = aside:AddSection({
		title = "Utility Rail",
		description = "Optional side context.",
	})

	utility:AddParagraph("Status", "Ready")
end)
```

For a fuller showcase, see [examples/example_ui.lua](/C:/Users/proton/Documents/Development/drawing%20lib%20ui%20lib/examples/example_ui.lua).

## Core API

### Root

- `DrawingUI.CreateApp(options)`
- `DrawingUI.CreateWindow(options)`
- `DrawingUI.new(options)`
- `DrawingUI.CreateTheme(overrides)`
- `DrawingUI.ClearAll()`
- `DrawingUI.Version`
- `DrawingUI.Themes.Default`
- `DrawingUI.Themes.Amber`
- `DrawingUI.Themes.Midnight`
- `DrawingUI.Themes.Circuit`

### App

- `app:AddPage({ id, label, icon?, badge?, description? })`
- `app:SetHeader({ title?, subtitle?, status?, actions? })`
- `app:SetAside(function(aside) ... end)`
- `app:SetDensity("comfortable" | "compact")`
- `app:SetMotion("full" | "reduced" | "off")`
- `app:SetTheme(themeOverrides)`
- `app:SetTitle(text)`
- `app:SetSubtitle(text)`
- `app:SetPosition(Vector2)`
- `app:SetSize(Vector2)`
- `app:SetVisible(boolean)`
- `app:SetActivePage(idOrPage)`
- `app:GetConfigId()`
- `app:GetConfigFolder()`
- `app:BuildConfig()`
- `app:ApplyConfig(config, fireCallbacks?)`
- `app:ListConfigs()`
- `app:SaveConfig(name)`
- `app:LoadConfig(name, fireCallbacks?)`
- `app:DeleteConfig(name)`
- `app:Destroy()`

### Page

- `page:AddSection({ title?, description?, columnSpan?, variant? })`
- `page:AddAsideSection({ title?, description?, columnSpan?, variant? })`
- `page:SetAside(function(aside) ... end)`
- `page:AddGroup({ title?, collapsible?, defaultOpen? })`
- `page:AddLabel(text)`
- `page:AddParagraph(title, text)`
- `page:AddButton(text, callback)`
- `page:AddButtonRow(buttons)`
- `page:AddToggle(text, initialValue, callback)`
- `page:AddSlider(text, min, max, initialValue, callback)`
- `page:AddDropdown(text, options, defaultValue, callback)`
- `page:AddSearchDropdown(text, options, defaultValue, callback)`
- `page:AddSearchDropdown(text, options, defaultValue, maxSize, callback)`
- `page:AddMultiDropdown(text, options, defaultValues, callback)`
- `page:AddColorPicker(text, defaultColor, callback)`
- `page:AddTextbox(text, placeholder, callback)`
- `page:AddKeybind(text, defaultKey, callback, changedCallback?)`
- `page:Select()`

### Section and Group

Sections and groups share the same control builders:

- `AddLabel`
- `AddParagraph`
- `AddSection`
- `AddButton`
- `AddButtonRow`
- `AddToggle`
- `AddSlider`
- `AddDropdown`
- `AddSearchDropdown`
- `AddMultiDropdown`
- `AddColorPicker`
- `AddTextbox`
- `AddKeybind`

Groups are created with:

- `section:AddGroup({ title?, collapsible?, defaultOpen? })`
- `page:AddGroup({ title?, collapsible?, defaultOpen? })`
- `app:AddSubTab(title, expanded?)`

## Control Objects

Current mutators exposed by v2:

- Labels and paragraphs: `SetText(text)`
- Buttons: `SetText(text)`, `SetActivationBinding(binding)`
- Toggles: `SetValue(boolean)`
- Sliders: `SetValue(number)`
- Dropdowns: `SetValue(value)`, `SetOptions(options, defaultValue?)`, `SetOpen(boolean)`
- Search dropdowns: `SetValue(value)`, `SetOptions(options, defaultValue?, maxSize?)`, `SetSearchText(text)`, `SetMaxSize(number)`, `SetOpen(boolean)`
- Multi dropdowns: `SetValues(values)`
- Color pickers: `SetColor(color3)`, `SetOpen(boolean)`
- Textboxes: `SetText(text)`
- Keybinds: `SetListening(boolean)`, `SetBinding(binding)`, `SetAllowMouseInputs(boolean)`

## Options

`CreateApp(options)` supports:

- `Title`
- `Position`
- `Size`
- `MinSize`
- `Visible`
- `DragAnywhere`
- `Theme`
- `ConfigId`
- `ConfigRoot`
- `Density`
- `MotionMode`

Defaults:

- adaptive window sizing based on viewport
- minimum size of `860x560`
- comfortable density
- full motion
- hidden right utility rail until aside content exists and width allows it

## Theme Keys

The v2 theme keeps the old color hooks and adds shell-specific surface roles.

Available keys include:

- `Accent`
- `AccentSoft`
- `WindowBackground`
- `HeaderBackground`
- `CanvasBackground`
- `SidebarBackground`
- `AsideBackground`
- `Card`
- `CardHover`
- `Panel`
- `PanelHeader`
- `Input`
- `InputHover`
- `InputFocused`
- `Button`
- `ButtonHover`
- `Border`
- `InnerBorder`
- `SoftBorder`
- `Shadow`
- `Text`
- `SubText`
- `Muted`
- `HighlightText`
- `Nav`
- `NavHover`
- `NavActive`
- `NavText`
- `Toggle`
- `ToggleEnabled`
- `SliderTrack`
- `SliderFill`
- `SectionLine`
- `Success`
- `Warning`
- `Danger`
- `Font`
- `TitleFont`
- `AppTitleSize`
- `TitleSize`
- `SectionTitleSize`
- `TextSize`
- `SmallTextSize`

## Motion

Motion modes:

- `full`: normal fades and small translations
- `reduced`: quick fades, no decorative travel
- `off`: state changes snap immediately

Use:

```lua
app:SetMotion("reduced")
```

## Config Persistence

State is stored under:

```text
<ConfigRoot>/<ConfigId>/*.json
```

The current implementation persists:

- toggles
- sliders
- dropdowns
- search dropdowns
- multi dropdowns
- textboxes
- color pickers
- keybinds

Control labels are still used as config keys, so stateful controls should keep unique labels.

## Compatibility Layer

v1-style entrypoints still exist:

- `CreateWindow(options)` maps to `CreateApp(options)`
- `AddTab(name)` maps to `AddPage({ id = sanitize(name), label = name })`
- `SetActiveTab(nameOrTab)` maps to `SetActivePage(nameOrTab)`
- `AddSubTab(name, expanded?)` maps to a group inserted into the implicit default page/section
- root-level `Add*` calls are routed into an implicit default page

That means older scripts can still run while new scripts can move to the page/section model.

## Notes

- v2 is desktop-first.
- The renderer stays inside core Drawing primitives.
- The current implementation focuses on shell/layout/motion/control architecture rather than every legacy micro-behavior matching v1 pixel-for-pixel.
