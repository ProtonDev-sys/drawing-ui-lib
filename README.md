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
- Labels
- Section headers
- Buttons
- Toggles
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
- `window:SetTitle(text)`
- `window:SetSubtitle(text)`
- `window:SetPosition(Vector2)`
- `window:SetSize(Vector2)`
- `window:SetVisible(boolean)`
- `window:Destroy()`

## Note

`game:HttpGet(rawgithuburl)` will not be able to fetch this file while the repository is private unless you use some authenticated mirror or make the repo public.
