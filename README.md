# BetterScale

> Responsive UI scaling for Roblox. Set it up once and forget about it.
> 
[![License](https://img.shields.io/badge/license-BloxLibs-blue)](LICENSE)
[![Wally](https://img.shields.io/badge/wally-blox--libs%2Fbetterscale-orange)](https://wally.run/package/blox-libs/betterscale)
[![Pesde](https://img.shields.io/badge/pesde-blox--libs%2Fbetterscale-orange)](https://pesde.dev/packages/blox-libs/betterscale)

---

Roblox's built-in scaling tools have real gaps. `AutomaticSize` breaks layouts. `AutomaticCanvasSize` is unreliable. There's no built-in way to say "I designed this for 1080p, scale it accordingly."

BetterScale fixes this by managing a `UIScale` for you — it computes the ratio between the player's screen and your reference resolution, applies any overrides you've configured, and keeps it updated on resize.

```lua
local BetterScale = require(ReplicatedStorage.BetterScale)
local betterScale = BetterScale.new(yourUIScale)
betterScale:Track()
```

Done.

---

## Installation

**Manual** — drop the module into `ReplicatedStorage`.

**Wally** — add to your `wally.toml` and run `wally install`:
```toml
[dependencies]
BetterScale = "blox-libs/betterscale@latest"
```

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

All configuration is done through attributes on the `UIScale` instance. You can set them in the Properties panel in Studio — no code required.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `Resolution` | `Vector2` | `1280, 720` | Reference resolution you designed for. |
| `Ratio` | `number` | `1.0` | Global multiplier on top of the computed scale. |
| `Range` | `NumberRange` | — | Min/max clamp for the final scale value. |
| `Axis` | `Enum` | `XY` | Scale by width (`X`), height (`Y`), or both (`XY`). |
| `InnerRatios` | `string` (JSON) | — | Per-device ratio overrides. |

---

## Examples

**Mobile needs bigger UI**
```lua
uiScale:SetAttribute("InnerRatios", '{"Small": 1.3}')
```

**Horizontal-only scaling**
```lua
uiScale:SetAttribute("Axis", Enum.ScrollingDirection.X)
```

**Scale down slightly on large monitors**
```lua
uiScale:SetAttribute("InnerRatios", '{"Large": 0.9}')
```

---

## How it works

On every resize event, BetterScale computes `currentScreenSize / referenceResolution` on the configured axis. The result is multiplied by `Ratio` — with any matching `InnerRatios` entry folded into `Ratio` directly — then clamped to `Range`.

Updates are scheduled via `RunService.RenderStepped:Once` so multiple resize events in the same frame produce a single scale write. When nothing changes, nothing runs.

---

## API

```lua
-- Create an instance
local betterScale = BetterScale.new(uiScale: UIScale)

-- Start tracking (calculates immediately, then on every resize)
betterScale:Track()

-- Pause tracking without destroying the instance
betterScale:UnTrack()

-- Clean up fully when done
betterScale:Destroy()
```

---

## Supported containers

`ScreenGui` · `BillboardGui` · `SurfaceGui` · `DockWidgetPluginGui`

---

## Projects using BetterScale

| Project | Link |
|---------|------|
| Squid Game Tower | [View](https://www.roblox.com/games/103410145208388/Squid-Game-Tower) |
| Squid Game Troll Tower | [View](https://www.roblox.com/games/75139493550474/Squid-Game-Troll-Tower) |

Using BetterScale in your project? Contact [PcoiDev](https://pcoi.dev) to get listed.
