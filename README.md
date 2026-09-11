# ryn-hud

Contextual FiveM HUD for QBCore, Qbox, and ESX (auto-detected). Quiet on foot, coordinated vehicle + minimap swipe, and an **admin-only** look editor — players do not get a personal settings menu.

## Features

- **Status** — health, armor, hunger, thirst, stress (when provided), plus extra pills via `SetStatus`
- **Vehicle** — digital / minimal / analog / circular speedo, gear, petrol or electric fuel, engine, square or circular minimap
- **Contextual** — voice / radio, stamina, oxygen, weapon + fire mode, parachute, harness
- **Extras** — damage flash, optional compass + street, cash / job peek (Left Alt or `/cash`)
- **Notifications** — info / success / warning / error / announce / item toasts
- **Progress** — bottom-center bar; stacks above status glyphs when they share that position
- **Admin look editor** — colors, icons, visibility, vehicle units; saved to `data/theme.json` and broadcast to everyone

## Requirements

- FiveM (cerulean, Lua 5.4)
- Qbox, QBCore, or ESX Legacy (standalone still shows health / armor)
- Node 18+ only if you edit the NUI (`html/` is already built)

## Install

1. Place this folder in `resources` as `ryn-hud`.
2. Start it **after** your framework, voice, and fuel:

```cfg
ensure qbx_core          # or qb-core / es_extended
ensure pma-voice
ensure ox_fuel           # or LegacyFuel / cdn-fuel / ps-fuel
ensure ryn-hud
```

3. Grant the look editor:

```cfg
add_ace group.admin ryn-hud.admin allow
```

Framework groups `god`, `admin`, and `superadmin` are also accepted (`Config.AdminGroups`).

## In-game

| Action | How |
| --- | --- |
| Open look editor | `/hudadmin` |
| Peek cash / job | Hold **Left Alt**, or `/cash` |
| Cinematic mode | `/cinematic` |
| Close editor | `Esc` (does not save) |

**Save** applies the look to all players. **Reset** restores the shipped Night Glass default.

The HUD hides while the pause menu is open and while the screen is faded out.

## Config

Edit [`config.lua`](config.lua).

| Option | Default | Notes |
| --- | --- | --- |
| `Config.Framework` | `'auto'` | `'auto'` \| `'qb'` \| `'qbx'` \| `'esx'` |
| `Config.AdminCommand` | `'hudadmin'` | Look editor command |
| `Config.AdminAce` | `'ryn-hud.admin'` | ACE permission |
| `Config.PeekCommand` | `'cash'` | Identity peek command |
| `Config.PeekControl` | `19` | Left Alt |
| `Config.CinematicCommand` | `'cinematic'` | Letterbox toggle |
| `Config.CinematicBarHeight` | `11` | Bar height (vh) |
| `Config.MinimapDelayMs` | `80` | Radar waits for the vehicle swipe |
| `Config.SeatbeltSounds` | `true` | Buckle / unbuckle MP3s |
| `Config.SeatbeltSoundVolume` | `0.45` | 0–1 |
| `Config.ElectricModels` | `{}` | Extra EV / hybrid models |
| `Config.Weapons` | `{}` | Custom weapon labels / fire modes |
| `Config.Notifications` | table | Toasts — position, duration, sound |
| `Config.Progress` | table | Progress bar — `enabled`, `cancelControl` |
| `Config.JGMileage` | `false` | Show jg-vehiclemileage in the vehicle HUD |
| `Config.Debug` | `false` | Boot / framework prints to F8 |

**Fuel** is read from `ox_fuel`, `LegacyFuel`, `cdn-fuel`, `ps-fuel`, or `Config.FuelProviders`, then native fuel.  
**Seatbelt** uses `LocalPlayer.state.seatbelt` and `Config.SeatbeltEvents`.  
**Electric** vehicles use a battery icon (statebag, native EV flag, empty petrol tank, or `Config.ElectricModels`).

---

## Exports

Safe wrapper for other resources:

```lua
local HUD = 'ryn-hud'

local function hud()
    return GetResourceState(HUD) == 'started'
end

local function Notify(...)
    if hud() then return exports[HUD]:Notify(...) end
end

local function Progress(...)
    if hud() then return exports[HUD]:Progress(...) end
    return false
end
```

### Core

```lua
exports['ryn-hud']:SetHudVisible(false)   -- death screens, cutscenes, etc.
exports['ryn-hud']:SetHudVisible(true)
exports['ryn-hud']:IsHudVisible()

exports['ryn-hud']:SetCinematic(true)
exports['ryn-hud']:ToggleCinematic()
exports['ryn-hud']:IsCinematic()

exports['ryn-hud']:GetTheme()             -- client or server
```

### Extra status pills

Up to 8 extras. `AddStatus` is an alias of `SetStatus`.

```lua
exports['ryn-hud']:SetStatus('drunk', {
    value = 40,
    icon = 'waves',       -- see icons below
    color = '#8B6BC8',
})
exports['ryn-hud']:SetStatus('drunk', 12)  -- value only
exports['ryn-hud']:RemoveStatus('drunk')
exports['ryn-hud']:ClearStatuses()
```

**Icons:** `heart`, `shield`, `utensils`, `droplet`, `activity`, `fuel`, `seatbelt`, `mic`, `wind`, `waves`, `bolt`, `crosshair`, `star`, `parachute`, `info`, `check`, `warning`, `x`, `megaphone`, `package`

### Notifications

Aliases: `Notify`, `ShowNotification`, `SendNotification`

| Call | Result |
| --- | --- |
| `Notify('Synced')` | info toast → id |
| `Notify('Low fuel', 'warning')` | typed toast |
| `Notify('Denied', 'error', 4000)` | typed + duration (ms) |
| `Notify({ title, message, type, duration, icon, color })` | full toast |
| `Announce('Restart soon')` | announce style |
| `ClearNotifications()` | clear stack |

**Types:** `info` · `success` · `warning` · `error` · `announce` · `item`  
Also accepted: `primary`, `inform`, `warn`, `danger`, `ok`, `pickup`, …

**Server** — first argument is player id or `-1` for everyone:

```lua
exports['ryn-hud']:Notify(source, 'Welcome back', 'info')
exports['ryn-hud']:Announce(-1, 'City event in 10 minutes')
exports['ryn-hud']:ClearNotifications(source)
```

### Item pickup

Lightweight single-line toast. Aliases: `NotifyItem`, `ItemNotify`

```lua
-- Client
exports['ryn-hud']:NotifyItem('Lockpick', 2)    -- Received Lockpick ×2
exports['ryn-hud']:NotifyItem('Lockpick')       -- Received Lockpick
exports['ryn-hud']:NotifyItem({
    name = 'Bandage',
    count = 3,
    removed = true,     -- Removed Bandage ×3
})

-- Server
exports['ryn-hud']:NotifyItem(source, 'Lockpick', 2)
```

### Progress

Always bottom-center. Aliases: `Progress`, `ProgressBar`, `progressBar`

| Call | Result |
| --- | --- |
| `Progress({ label, duration, canCancel, icon })` | **blocks** until done → `true` / `false` |
| `Progress('Lockpicking', 5000)` | timed shorthand |
| `Progress({ label, value = 0 })` | manual → `true` immediately |
| `StartProgress({ ... })` | non-blocking (`onFinish`) |
| `UpdateProgress(42)` / `SetProgress(42)` | manual update |
| `CancelProgress()` / `CompleteProgress()` | cancel / force finish |
| `IsProgressActive()` / `GetProgress()` | state helpers |

```lua
-- Client (blocking — use for interactions)
if exports['ryn-hud']:Progress({
    label = 'Lockpicking',
    duration = 5000,
    canCancel = true,
    icon = 'bolt',
}) then
    -- finished
end

-- Client (manual)
exports['ryn-hud']:Progress({ label = 'Uploading', value = 0 })
exports['ryn-hud']:UpdateProgress(55)
exports['ryn-hud']:CompleteProgress()

-- Server (fire-and-forget — no completion boolean)
exports['ryn-hud']:Progress(source, { label = 'Searching', duration = 3000 })
exports['ryn-hud']:CancelProgress(source)
```

### Events

```lua
TriggerClientEvent('ryn-hud:client:notify', source, { title = 'Keys', message = 'Locked', type = 'info' })
TriggerClientEvent('ryn-hud:client:announce', -1, 'Server restart soon')
TriggerClientEvent('ryn-hud:client:notifyItem', source, 'Lockpick', 2)
TriggerClientEvent('ryn-hud:client:clearNotifications', source)
TriggerClientEvent('ryn-hud:client:progress', source, { label = 'Searching', duration = 3000 })
TriggerClientEvent('ryn-hud:client:updateProgress', source, 50)
TriggerClientEvent('ryn-hud:client:cancelProgress', source)
TriggerClientEvent('ryn-hud:client:completeProgress', source)
```

---

## Development

Browser preview (no game client):

```bash
cd web
npm install
npm run dev
```

Opens [http://localhost:5173](http://localhost:5173). Press `` ` `` to hide the Preview panel.

- Vehicle swipe, speedo styles, admin editor, and live speed are mock-only
- Notification / progress / item buttons exercise the toast and progress APIs
- Admin **Save** writes `localStorage`, not the server

Rebuild for FiveM:

```bash
cd web
npm run build
```

Output goes to `html/`.

## Layout

```
ryn-hud/
  config.lua
  fxmanifest.lua
  bridge/          QB / Qbox / ESX / standalone
  client/          status, vehicle, radar, NUI, notify, progress, admin
  server/          permissions, theme, sync, notify, progress
  data/theme.json  default + last saved look
  web/             Vue 3 + Vite source
  html/            built NUI (what FiveM loads)
```
