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
- Tabs
- Labels
- Section headers
- Buttons
- Switch-style toggles
- Sliders
- Window mutators for title, subtitle, position, size, and visibility
- Full drawing cleanup through `:Destroy()` and `DrawingUI.ClearAll()`

## Example

See `examples/example_ui.lua`.

## Window API

- `DrawingUI.CreateWindow(options)`
- `window:AddSection(text)`
- `window:AddLabel(text)`
- `window:AddButton(text, callback)`
- `window:AddToggle(text, initialValue, callback)`
- `window:AddSlider(text, min, max, initialValue, callback)`
- `window:AddTab(name)`
- `window:SetActiveTab(nameOrTab)`
- `window:SetTitle(text)`
- `window:SetSubtitle(text)`
- `window:SetPosition(Vector2)`
- `window:SetSize(Vector2)`
- `window:SetVisible(boolean)`
- `window:Destroy()`

## Tab API

- `tab:AddSection(text)`
- `tab:AddLabel(text)`
- `tab:AddButton(text, callback)`
- `tab:AddToggle(text, initialValue, callback)`
- `tab:AddSlider(text, min, max, initialValue, callback)`
- `tab:Select()`

## Note

The example uses the public raw GitHub URL for `DrawingUI.lua`, so updates only take effect after pushing changes to `main`.
