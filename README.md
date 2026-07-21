# BetterScale

> A UI scaling solution for Roblox, without the headache.
>
> [![License](https://img.shields.io/badge/license-BloxLibs-blue)](LICENSE)
> [![Wally](https://img.shields.io/badge/wally-pcoidev%2Fbetterscale-red)](https://wally.run/package/pcoidev/betterscale)
> [![Pesde](https://img.shields.io/badge/pesde-bloxlibs%2Fbetterscale-orange)](https://pesde.dev/packages/bloxlibs/betterscale)

---

Roblox's built-in scaling tools have real gaps. `AutomaticSize` breaks layouts. `AutomaticCanvasSize` is unreliable. There's no built-in way to say "I designed this for 1080p, scale it accordingly."

BetterScale fixes this by managing a `UIScale` for you; it computes the ratio between the player's screen and your reference resolution, applies any overrides you've configured, and keeps it updated on resize.

```lua
local BetterScale = require(ReplicatedStorage.BetterScale)
local betterScale = BetterScale.new(yourUIScale)
betterScale:Track()
```

Done.

---

## Setup

```lua
local uiScale = script.Parent.UIScale

-- Resolution you designed at (default: 1280×720)
uiScale:SetAttribute("Resolution", Vector2.new(1920, 1080))

-- Clamp so extreme screens don't break anything
uiScale:SetAttribute("Range", NumberRange.new(0.5, 2.0))

local betterScale = BetterScale.new(uiScale)
betterScale:Track()
```

All configuration is done through attributes on the `UIScale` instance. You can set them in the Properties panel in Studio; no code required.

| Attribute       | Type            | Default     | Description                                         |
| --------------- | --------------- | ----------- | --------------------------------------------------- |
| `Resolution`    | `Vector2`       | `1280, 720` | Reference resolution you designed for.              |
| `Ratio`         | `number`        | `1.0`       | Global multiplier on top of the computed scale.     |
| `Range`         | `NumberRange`   | -           | Min/max clamp for the final scale value.            |
| `Axis`          | `Enum`          | `XY`        | Scale by width (`X`), height (`Y`), or both (`XY`). |
| `DisplayRatios` | `string` (JSON) | -           | Per-device ratio overrides.                         |

---

## Examples

**Mobile needs bigger UI**

```lua
uiScale:SetAttribute("DisplayRatios", '{"Small": 1.3}')
```

**Horizontal-only scaling**

```lua
uiScale:SetAttribute("Axis", Enum.ScrollingDirection.X)
```

**Scale down slightly on large monitors**

```lua
uiScale:SetAttribute("DisplayRatios", '{"Large": 0.9}')
```

---

## How it works

On every resize, BetterScale computes `screenSize / resolution` on the configured axis, clamps it to `Range`, then multiplies by `Ratio` (with any matching `DisplayRatios` entry already folded in). The result goes straight to `UIScale.Scale`.

The initial update after `Track()` is deferred to the next `RenderStepped` frame so the UI has time to lay out first.

---

## API

```lua
local BetterScale = require(path.to.BetterScale)
local uiScale = path.to.UIScale

-- Configure scaling attributes
uiScale:SetAttribute("Ratio", 1.2)
uiScale:SetAttribute("Range", NumberRange.new(0.5, 2.0))
uiScale:SetAttribute("Resolution", Vector2.new(1920, 1080))
uiScale:SetAttribute("Axis", Enum.ScrollingDirection.X) -- X | Y | XY
uiScale:SetAttribute("DisplayRatios", '{"Large": 0.8, "Small": 1.3}')

-- Quick usage: create + track in one call
local cleanup = BetterScale.build(uiScale)
cleanup()

-- Or manual control
local betterScale = BetterScale.new(uiScale)
betterScale:Track()

-- Force a refresh manually
betterScale:Update()

-- Type checking
if BetterScale.is(betterScale) then
	print("It's a BetterScale instance!")
end

-- Later cleanup
betterScale:Destroy()
```

---

## Projects using BetterScale

| Project                | Link                                                                       |
| ---------------------- | -------------------------------------------------------------------------- |
| Squid Game Tower       | [View](https://www.roblox.com/games/103410145208388/Squid-Game-Tower)      |
| Squid Game Troll Tower | [View](https://www.roblox.com/games/75139493550474/Squid-Game-Troll-Tower) |

Using BetterScale in your project? Contact [PcoiDev](https://pcoi.dev) to get listed.
