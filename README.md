# ryn-hud

A contextual FiveM HUD with a quiet on-foot cluster, a coordinated vehicle + minimap swipe, and an **admin-only** look editor. Built for QBCore, Qbox, and ESX (auto-detected). Players do not get a personal settings menu — admins set the server look once.

## Features

- Status cluster: health, armor, hunger, thirst, and stress when the framework provides it — plus extra pills from other resources (`SetStatus`)
- Vehicle scene: digital, minimal, analog, or circular speedo — plus gear, petrol or electric fuel, engine, and a square or circular minimap
- Contextual only: voice / radio, stamina, oxygen, weapon name + fire mode, parachute, harness
- Damage flash when health or engine drops
- Optional compass + street, and cash / job chips (off by default; hold Left Alt or `/cash` to peek)
- Optional notification toasts (info / success / warning / error / announce) with client + server exports
- Optional bottom-center progress bar that stacks above status glyphs when they share that position
- Admin look editor: colors, icons, visibility, vehicle units
- Theme saved to `data/theme.json` and KVP, then broadcast to everyone

## Install

1. Place this folder in `resources` as `ryn-hud`.
2. Start it **after** your framework, voice, and fuel:

```cfg
ensure qbx_core          # or qb-core / es_extended
ensure pma-voice
ensure ox_fuel           # or LegacyFuel / cdn-fuel / ps-fuel
ensure ryn-hud
```

3. Grant the look editor (ACE and/or framework groups):

```cfg
add_ace group.admin ryn-hud.admin allow
```

Framework groups `god`, `admin`, and `superadmin` are also accepted (see `Config.AdminGroups`).

The NUI is already built in `html/`. You do not need Node on the game server.

## In-game

| Action | How |
| --- | --- |
| Open look editor | `/hudadmin` |
| Peek cash / job | Hold **Left Alt**, or `/cash` |
| Cinematic mode | `/cinematic` (toggles HUD off + letterbox bars) |
| Close editor | `Esc` (does not save) |

Save in the editor applies the look to **all players**. Reset restores the shipped Night Glass default.

## Config

Edit [`config.lua`](config.lua):

| Option | Default | Notes |
| --- | --- | --- |
| `Config.Framework` | `'auto'` | `'auto'` \| `'qb'` \| `'qbx'` \| `'esx'` |
| `Config.AdminCommand` | `'hudadmin'` | Command name |
| `Config.AdminAce` | `'ryn-hud.admin'` | ACE permission |
| `Config.PeekCommand` | `'cash'` | Short identity peek |
| `Config.PeekControl` | `19` | Left Alt |
| `Config.CinematicCommand` | `'cinematic'` | Toggle cinematic letterbox mode |
| `Config.CinematicBarHeight` | `11` | Top/bottom bar height (vh) |
| `Config.MinimapDelayMs` | `80` | Radar waits so it does not pop before the swipe |
| `Config.SeatbeltSounds` | `true` | Buckle / unbuckle MP3s |
| `Config.SeatbeltSoundVolume` | `0.45` | 0–1 NUI volume |
| `Config.ElectricModels` | `{}` | Extra EV/hybrid spawn names or hashes |
| `Config.Weapons` | `{}` | Custom weapon labels and fire modes |
| `Config.Notifications` | enabled table | Optional toast stack (position, duration, max visible) |
| `Config.Progress` | enabled table | Optional bottom-center progress bar |

Fuel is read from `ox_fuel`, `LegacyFuel`, `cdn-fuel`, or `ps-fuel` when started, otherwise native fuel. Seatbelt uses `LocalPlayer.state.seatbelt` and common toggle events.

Other resources can toggle cinematic mode, hide the HUD, read the current look, or hang extra status pills on the cluster:

```lua
exports['ryn-hud']:SetHudVisible(false)
exports['ryn-hud']:SetHudVisible(true)
exports['ryn-hud']:IsHudVisible()

exports['ryn-hud']:SetCinematic(true)
exports['ryn-hud']:ToggleCinematic()
exports['ryn-hud']:IsCinematic()

exports['ryn-hud']:GetTheme()

exports['ryn-hud']:SetStatus('drunk', {
    value = 40,
    icon = 'waves',
    color = '#8B6BC8',
})
exports['ryn-hud']:SetStatus('drunk', 12)
exports['ryn-hud']:RemoveStatus('drunk')
exports['ryn-hud']:ClearStatuses()
```

`AddStatus` is an alias of `SetStatus`. Up to 8 extras. Electric / hybrid vehicles show a battery icon instead of a fuel pump (statebag `fuelType` / `electric`, native EV flag, empty petrol tank, or `Config.ElectricModels`).

The HUD also hides itself while the pause menu is open and while the screen is faded out.

## Exports API

Safe wrapper other resources can copy:

```lua
local HUD = 'ryn-hud'

local function hudStarted()
    return GetResourceState(HUD) == 'started'
end

local function Notify(...)
    if hudStarted() then return exports[HUD]:Notify(...) end
end

local function Progress(...)
    if hudStarted() then return exports[HUD]:Progress(...) end
    return false
end
```

### Notifications (client)

Aliases: `Notify`, `ShowNotification`, `SendNotification`

| Call | Result |
| --- | --- |
| `Notify('Synced')` | info toast, returns id |
| `Notify('Low fuel', 'warning')` | typed toast |
| `Notify('Denied', 'error', 4000)` | typed + duration ms |
| `Notify({ title, message, type, duration, icon, color })` | full toast |
| `Announce('Restart soon')` | announce style |
| `ClearNotifications()` | clear stack |
| `IsNotificationsEnabled()` | config flag |
| `GetActiveNotificationCount()` | approximate live count |

Types: `info` · `success` · `warning` · `error` · `announce`  
Also accepted: `primary`, `inform`, `warn`, `danger`, `ok`, …

Message keys accepted: `message`, `description`, `text`, `msg`  
Title keys accepted: `title`, `header`, `caption`, `subject`

### Notifications (server)

Same names; first argument is the player id (`source`) or `-1` for everyone:

```lua
exports['ryn-hud']:Notify(source, 'Welcome back', 'info')
exports['ryn-hud']:Notify(source, {
    title = 'Bank',
    message = 'Transfer complete',
    type = 'success',
})
exports['ryn-hud']:Announce(-1, 'City event in 10 minutes')
exports['ryn-hud']:ClearNotifications(source)
```

### Progress (client)

Aliases: `Progress`, `ProgressBar`, `progressBar`

| Call | Result |
| --- | --- |
| `Progress({ label, duration, canCancel, icon, color })` | **blocks** until done → `true` / `false` |
| `Progress('Lockpicking', 5000)` | shorthand timed |
| `Progress({ label, value = 0 })` | manual mode → `true` immediately |
| `StartProgress({ ... })` | non-blocking; use `onFinish` |
| `UpdateProgress(42)` / `SetProgress(42)` | manual update |
| `UpdateProgress({ value = 100, label = 'Done' })` | update + label |
| `CancelProgress()` / `HideProgress()` | cancel → false |
| `CompleteProgress()` / `FinishProgress()` | force success |
| `IsProgressActive()` | busy? |
| `GetProgress()` | `{ id, label, value, ... }` or nil |

```lua
-- Blocking (recommended for interactions)
if exports['ryn-hud']:Progress({
    label = 'Lockpicking',
    duration = 5000,
    canCancel = true,
    icon = 'bolt',
}) then
    -- finished
end

-- Callback style
exports['ryn-hud']:Progress({
    label = 'Searching',
    duration = 3000,
    onFinish = function(success) end,
})

-- Non-blocking start
exports['ryn-hud']:StartProgress({
    label = 'Hacking',
    duration = 8000,
    onFinish = function(ok) end,
})

-- Manual
exports['ryn-hud']:Progress({ label = 'Uploading', value = 0 })
exports['ryn-hud']:UpdateProgress(55)
exports['ryn-hud']:CompleteProgress()
```

### Progress (server)

Fire-and-forget only (no completion boolean). First arg is player id or `-1`:

```lua
exports['ryn-hud']:Progress(source, { label = 'Searching', duration = 3000 })
exports['ryn-hud']:CancelProgress(source)
exports['ryn-hud']:UpdateProgress(source, 40)
```

### Events

```lua
TriggerClientEvent('ryn-hud:client:notify', source, { title = 'Keys', message = 'Locked', type = 'info' })
TriggerClientEvent('ryn-hud:client:announce', -1, 'Server restart soon')
TriggerClientEvent('ryn-hud:client:clearNotifications', source)
TriggerClientEvent('ryn-hud:client:progress', source, { label = 'Searching', duration = 3000 })
TriggerClientEvent('ryn-hud:client:updateProgress', source, 50)
TriggerClientEvent('ryn-hud:client:cancelProgress', source)
TriggerClientEvent('ryn-hud:client:completeProgress', source)
```

## Browser preview

Iterate on the UI without a game client:

```bash
cd web
npm install
npm run dev
```

Opens [http://localhost:5173](http://localhost:5173) with mock vitals, a fake minimap, and a **Preview** panel. `` ` `` hides the panel.

- Vehicle swipe, speedometer styles, admin editor, sliders, and live speed are mock-only
- Notification buttons exercise info / success / warning / error / announce toasts
- Progress buttons exercise timed and manual progress bars
- Admin **Save** in the browser writes `localStorage`, not the server

After UI changes, rebuild for FiveM:

```bash
cd web
npm run build
```

Output goes to `html/`. `npm run preview` serves that production build.

## Project layout

```
ryn-hud/
  config.lua
  fxmanifest.lua
  bridge/          QB / Qbox / ESX / standalone
  client/          status, vehicle, radar, NUI, admin
  server/          permissions, theme persist, sync
  data/theme.json  default + last saved look
  web/             Vue 3 + Vite source
  html/            built NUI (what FiveM loads)
```

## Requirements

- FiveM (cerulean, Lua 5.4)
- One of: Qbox, QBCore, or ESX Legacy (standalone still shows health/armor)
- Node 18+ only if you edit the NUI
