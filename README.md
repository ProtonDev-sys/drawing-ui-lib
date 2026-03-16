# DrawingUI

Small drawing-based UI library for Roblox Luau environments that expose `Drawing.new(...)`.

## Files

- `DrawingUI.lua`
- `examples/example_ui.lua`
- `README.md`

## Loadstring Usage

```lua
local DrawingUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProtonDev-sys/drawing-ui-lib/main/DrawingUI.lua"))()
```

## Included

- Draggable window container
- Viewport clamping so the window stays on-screen while dragging
- Drag-anywhere window movement by default
- Tabs
- Paragraph text blocks
- Labels
- Section headers
- Buttons
- Switch-style toggles
- Sliders
- Dropdowns
- Multi-select dropdowns
- Color picker control
- Textboxes
- Keybind controls
- Theme presets and theme override tables
- Window mutators for title, subtitle, position, size, and visibility
- Full drawing cleanup through `:Destroy()` and `DrawingUI.ClearAll()`

## Example

See `examples/example_ui.lua`.

## Window API

- `DrawingUI.CreateWindow(options)`
- `window:AddSection(text)`
- `window:AddLabel(text)`
- `window:AddParagraph(title, text)`
- `window:AddButton(text, callback)`
- `window:AddToggle(text, initialValue, callback)`
- `window:AddSlider(text, min, max, initialValue, callback)`
- `window:AddDropdown(text, options, defaultValue, callback)`
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
- `window:Destroy()`

## Tab API

- `tab:AddSection(text)`
- `tab:AddLabel(text)`
- `tab:AddParagraph(title, text)`
- `tab:AddButton(text, callback)`
- `tab:AddToggle(text, initialValue, callback)`
- `tab:AddSlider(text, min, max, initialValue, callback)`
- `tab:AddDropdown(text, options, defaultValue, callback)`
- `tab:AddMultiDropdown(text, options, defaultValues, callback)`
- `tab:AddColorPicker(text, defaultColor, callback)`
- `tab:AddTextbox(text, placeholder, callback)`
- `tab:AddKeybind(text, defaultKey, callback, changedCallback?)`
- `tab:Select()`

## Theme API

- `DrawingUI.CreateTheme(overrides)`
- `DrawingUI.Themes.Default`
- `DrawingUI.Themes.Amber`
- `DrawingUI.Themes.Midnight`

Useful theme keys include `Accent`, `WindowBackground`, `HeaderBackground`, `Button`, `ButtonHover`, `Input`, `InputHover`, `InputFocused`, `ToggleEnabled`, `SliderFill`, `Border`, `Text`, `SubText`, `Muted`, `Font`, `TitleSize`, `TextSize`, and `SmallTextSize`.

`CreateWindow` also accepts `DragAnywhere = false` if you want classic titlebar-only dragging.

## Note

The example uses the public raw GitHub URL for `DrawingUI.lua`, so updates only take effect after pushing changes to `main`.
