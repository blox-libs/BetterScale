# BetterScale v2.0 Documentation

A lightweight, responsive UI scaling solution for Roblox that automatically adjusts UI elements based on screen size and aspect ratio.

## Installation

Place the BetterScale ModuleScript in your game and require it:

```lua
local BetterScale = require(path.to.BetterScale)
```

## Quick Start

```lua
local BetterScale = require(ReplicatedStorage.BetterScale)
local uiScale = script.Parent.UIScale

-- Configure scaling attributes
uiScale:SetAttribute("Ratio", 1.0)
uiScale:SetAttribute("Range", NumberRange.new(0.5, 2.0))
uiScale:SetAttribute("Resolution", Vector2.new(1920, 1080))
uiScale:SetAttribute("Axis", Enum.ScrollingDirection.XY)

-- Create and start tracking
local BetterScale = BetterScale.new(uiScale)
BetterScale:Track()

-- Clean up when done
BetterScale:Destroy()
```

## Attributes

Configure BetterScale behavior by setting attributes on your UIScale instance:

### `Ratio` (number)
**Default:** `1.0`

Base scaling multiplier applied to the computed scale.

```lua
uiScale:SetAttribute("Ratio", 1.2) -- 20% larger than base
uiScale:SetAttribute("Ratio", 0.8) -- 20% smaller than base
```

### `Range` (NumberRange)
**Default:** `NumberRange.new(0, math.huge)`

Minimum and maximum scale limits to prevent UI from becoming too small or large.

```lua
uiScale:SetAttribute("Range", NumberRange.new(0.5, 2.0))
```

### `Resolution` (Vector2)
**Default:** `Vector2.new(1280, 720)`

Reference resolution used for scale calculations. UI will scale proportionally from this base resolution.

```lua
uiScale:SetAttribute("Resolution", Vector2.new(1920, 1080))
```

### `Axis` (Enum.ScrollingDirection)
**Default:** `Enum.ScrollingDirection.XY`

Determines which axis to use for scaling calculations:

- **`X`** - Scale based on horizontal resolution only
- **`Y`** - Scale based on vertical resolution only  
- **`XY`** - Scale uniformly based on the most constrained dimension (recommended)

```lua
uiScale:SetAttribute("Axis", Enum.ScrollingDirection.XY)
```

### `InnerRatios` (string - JSON)
**Default:** `nil`

Device-specific ratio multipliers based on `GuiService.ViewportDisplaySize`. Useful for different device categories.

```lua
uiScale:SetAttribute("InnerRatios", '{"Large": 0.8, "Small": 1.3}')
```

Available display sizes: `"Large"`, `"Small"` (check `GuiService.ViewportDisplaySize.Name` for your device)

## API Reference

### Constructor

#### `BetterScale.new(uiScale: UIScale): BetterScale`

Creates a new BetterScale instance for the given UIScale object.

```lua
local BetterScale = BetterScale.new(uiScale)
```

### Methods

#### `BetterScale:Track()`

Starts tracking and automatically updating the UIScale based on viewport changes.

```lua
BetterScale:Track()
```

#### `BetterScale:UnTrack()`

Stops tracking viewport changes. The scale will no longer update automatically.

```lua
BetterScale:UnTrack()
```

#### `BetterScale:UpdateScale()`

Manually triggers a scale update. Automatically batched to next frame to prevent redundant calculations.

```lua
BetterScale:UpdateScale()
```

#### `BetterScale:ComputeScale(): number?`

Computes and returns the scale value without applying it. Returns `nil` if no GUI container is found.

```lua
local scale = BetterScale:ComputeScale()
if scale then
    print("Computed scale:", scale)
end
```

#### `BetterScale:GetAttributes(displaySize: Enum.DisplaySize?): Attributes`

Returns the current attributes with defaults applied. Optionally applies InnerRatios for a specific display size.

```lua
local attributes = BetterScale:GetAttributes()
print(attributes.Ratio, attributes.Resolution)
```

#### `BetterScale:GetAbsoluteSize(): Vector2?`

Returns the AbsoluteSize of the GUI container, or `nil` if not found.

```lua
local size = BetterScale:GetAbsoluteSize()
```

#### `BetterScale:Destroy()`

Cleans up all connections and stops tracking. Should be called when the BetterScale instance is no longer needed.

```lua
BetterScale:Destroy()
```

## Supported Containers

BetterScale automatically detects and works with:

- `ScreenGui`
- `BillboardGui`
- `SurfaceGui`
- `DockWidgetPluginGui`

## Examples

### Basic Responsive UI

```lua
local BetterScale = require(ReplicatedStorage.BetterScale)
local uiScale = script.Parent.UIScale

uiScale:SetAttribute("Resolution", Vector2.new(1920, 1080))
uiScale:SetAttribute("Axis", Enum.ScrollingDirection.XY)

local BetterScale = BetterScale.new(uiScale)
BetterScale:Track()
```

### Mobile-Optimized Scaling

```lua
local uiScale = script.Parent.UIScale

uiScale:SetAttribute("Ratio", 1.0)
uiScale:SetAttribute("Resolution", Vector2.new(1920, 1080))
uiScale:SetAttribute("Range", NumberRange.new(0.7, 1.5))
uiScale:SetAttribute("InnerRatios", '{"Small": 1.2}')

local BetterScale = BetterScale.new(uiScale)
BetterScale:Track()
```

### Horizontal-Only Scaling

```lua
local uiScale = script.Parent.UIScale

uiScale:SetAttribute("Axis", Enum.ScrollingDirection.X)
uiScale:SetAttribute("Resolution", Vector2.new(1920, 1080))

local BetterScale = BetterScale.new(uiScale)
BetterScale:Track()
```

### Manual Control

```lua
local BetterScale = BetterScale.new(uiScale)

-- Compute without applying
local scale = BetterScale:ComputeScale()
if scale and scale > 1.5 then
    print("Screen is very large!")
end

-- Apply manually when needed
BetterScale:UpdateScale()
```

## How It Works

### Scaling Algorithm

BetterScale calculates scale based on the ratio between current screen size and reference resolution:

**X-Axis:**
```
scale = (currentWidth / referenceWidth) * ratio
```

**Y-Axis:**
```
scale = (currentHeight / referenceHeight) * ratio
```

**XY (Uniform):**
```
scaleX = currentWidth / referenceWidth
scaleY = currentHeight / referenceHeight
scale = min(scaleX, scaleY) * ratio
```

The computed scale is clamped to the specified Range, ensuring UI never becomes too small or large.

### Performance Optimizations

- **Frame Batching** - Multiple updates in the same frame are batched into a single calculation on the next RenderStepped
- **Early Returns** - Skips computation if container is missing or tracking is disabled
- **Smart Updates** - Only applies new scale if it differs from current value
- **Efficient Container Detection** - Uses parent traversal instead of multiple FindFirstAncestor calls

## Best Practices

1. **Set Resolution to your design resolution** - If you design at 1920x1080, use that as your reference
2. **Use XY axis for uniform scaling** - Prevents UI distortion on different aspect ratios
3. **Set appropriate Range limits** - Prevents UI from becoming unusable on extreme screen sizes
4. **Clean up properly** - Always call `:Destroy()` when done to prevent memory leaks
5. **Use InnerRatios sparingly** - Only needed if you want different scaling on different device categories

## Projects using BetterScale

Below is a list of experiences, games, or projects which use  **BetterScale**, **Responsiveness** or **QuickScale**.  
If your project uses our libraries and you want it listed, feel free to contact [PcoiDev](https://pcoi.dev).

| Name | Link |
|-------------|----------------|
| Squid Game Tower | [View Game](https://www.roblox.com/games/103410145208388/Squid-Game-Tower) |
| Squid Game Troll Tower | [View Game](https://www.roblox.com/games/75139493550474/Squid-Game-Troll-Tower) |
