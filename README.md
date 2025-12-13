# BetterScale

Responsive UI scaling solution for Roblox. Set it up once and forget about it. Built for both scripters and UI designers.

## Why?

Roblox's built-in scaling is too limited. AutomaticSize breaks layouts, AutomaticCanvasSize is unreliable, and there aren't enough properties to control how things scale. BetterScale gives you full control without the headaches.

```lua
local BetterScale = require(ReplicatedStorage.BetterScale)
local betterScale = BetterScale.new(yourUIScale)
betterScale:Track()
```

Done. Your UI now adapts to any screen.

## Installation

Grab the latest release and drop it in ReplicatedStorage. Or use Wally if that's your thing.

## Basic Setup

```lua
local uiScale = script.Parent.UIScale

-- Tell it what resolution you designed for
uiScale:SetAttribute("Resolution", Vector2.new(1920, 1080))

-- Optional: set some limits so it doesn't get crazy
uiScale:SetAttribute("Range", NumberRange.new(0.5, 2.0))

-- Start tracking
local betterScale = BetterScale.new(uiScale)
betterScale:Track()
```

That's literally it.

## Configuration

Everything is controlled through attributes on your UIScale:
- **Resolution** - What screen size did you design for? (default: 1280x720)
- **Ratio** - Want everything bigger or smaller? Multiply by this (default: 1.0)
- **Range** - Min/max limits so UI doesn't break on weird screens (default: no limits)
- **Axis** - Scale based on width (X), height (Y), or both (XY) (default: XY like UIAspectRatioConstraints)
- **InnerRatios** - Different ratios for different devices. JSON string like `{"Small": 1.2}`

## Examples

### Just make it work
```lua
local betterScale = BetterScale.new(uiScale)
betterScale:Track()
```

### I designed for 1080p
```lua
uiScale:SetAttribute("Resolution", Vector2.new(1920, 1080))
local betterScale = BetterScale.new(uiScale)
betterScale:Track()
```

### Mobile needs to be bigger
```lua
uiScale:SetAttribute("InnerRatios", '{"Small": 1.3}')
local betterScale = BetterScale.new(uiScale)
betterScale:Track()
```

### Only scale horizontally
```lua
uiScale:SetAttribute("Axis", Enum.ScrollingDirection.X)
local betterScale = BetterScale.new(uiScale)
betterScale:Track()
```

## How it works

Calculates the ratio between current screen size and your reference resolution, then applies it. Also clamps to your min/max range if you set one.

Updates happen automatically when the screen resizes. Multiple updates per frame get batched together so it's not wasteful.

When nothing changes, it does nothing. Zero performance cost when idle.

## Cleanup

```lua
betterScale:Destroy()
```

Call this when you're done. It disconnects everything properly.

## Docs

Check the [Wiki](https://github.com/blox-libs/BetterScale/wiki) for the full API reference and advanced usage.

## Performance

It's fast. Updates only fire when screen size changes, and multiple rapid changes get combined into one update. Event-driven, not polling.

## Supported Containers

Works with ScreenGui, BillboardGui, SurfaceGui, and DockWidgetPluginGui. (even tho you'll probably use this only on ScreenGuis/DockWidgetPluginGui)

## License

BloxLibs License. Do whatever you want with it. I only have the right to reference experiences, games, or projects using BetterScale

## Credits

Built on ideas from QuickScale and Responsiveness. Thanks to everyone who contributed feedback.

## Projects using BetterScale

Below is a list of experiences, games, or projects which use  **BetterScale**, **Responsiveness** or **QuickScale**.  
If your project uses our libraries and you want it listed, feel free to contact [PcoiDev](https://pcoi.dev).

| Name | Link |
|-------------|----------------|
| Squid Game Tower | [View Game](https://www.roblox.com/games/103410145208388/Squid-Game-Tower) |
| Squid Game Troll Tower | [View Game](https://www.roblox.com/games/75139493550474/Squid-Game-Troll-Tower) |
