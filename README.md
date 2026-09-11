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

Other resources can toggle cinematic mode, hide the HUD, read the current look, hang extra status pills on the cluster, push notifications, or run a progress bar:

```lua
exports['ryn-hud']:SetHudVisible(false)   -- death screens, minigames, cutscenes
exports['ryn-hud']:SetHudVisible(true)
exports['ryn-hud']:IsHudVisible()

exports['ryn-hud']:SetCinematic(true)      -- screenshots with letterbox bars
exports['ryn-hud']:ToggleCinematic()
exports['ryn-hud']:IsCinematic()

exports['ryn-hud']:GetTheme()              -- current theme table (client or server)

exports['ryn-hud']:SetStatus('drunk', {    -- extra pill on the status cluster
    value = 40,
    icon = 'waves',                        -- heart, shield, utensils, droplet, activity,
    color = '#8B6BC8',                     -- fuel, seatbelt, mic, wind, waves, bolt, star, parachute
})                                         -- info, check, warning, x, megaphone
exports['ryn-hud']:SetStatus('drunk', 12)  -- update value only
exports['ryn-hud']:RemoveStatus('drunk')
exports['ryn-hud']:ClearStatuses()

-- Notifications (Config.Notifications.enabled)
exports['ryn-hud']:Notify('Inventory synced')                 -- string message
exports['ryn-hud']:Notify('Tank is low', 'warning')           -- message + type
exports['ryn-hud']:Notify({                                   -- full toast
    title = 'Bank',
    message = 'Transfer complete',
    type = 'success',                     -- info | success | warning | error | announce
    duration = 5000,                      -- ms
    icon = 'check',                       -- optional icon name
})
exports['ryn-hud']:Announce('City event in 10 minutes')       -- announce-styled toast
exports['ryn-hud']:ClearNotifications()

-- From server (target player id, or -1 for everyone)
exports['ryn-hud']:Notify(source, 'Welcome back', 'info')
exports['ryn-hud']:Announce(-1, {
    title = 'Announcement',
    message = 'Restart in 15 minutes.',
    duration = 8000,
})

-- Progress bar (always bottom-center; sits above glyphs when status is bottom-center)
if exports['ryn-hud']:Progress({
    label = 'Lockpicking',
    duration = 5000,
    canCancel = true,                     -- X cancels when Config.Progress.cancelControl
    icon = 'bolt',
}) then
    -- completed
else
    -- cancelled or busy
end

exports['ryn-hud']:Progress({ label = 'Uploading', value = 0 })  -- manual mode
exports['ryn-hud']:UpdateProgress(42)
exports['ryn-hud']:UpdateProgress({ value = 100, label = 'Done' })
exports['ryn-hud']:CancelProgress()
exports['ryn-hud']:IsProgressActive()
```

Events mirror the same payloads:

```lua
TriggerClientEvent('ryn-hud:client:notify', source, { title = 'Keys', message = 'Locked', type = 'info' })
TriggerClientEvent('ryn-hud:client:announce', -1, 'Server restart soon')
TriggerClientEvent('ryn-hud:client:clearNotifications', source)
TriggerClientEvent('ryn-hud:client:progress', source, { label = 'Searching', duration = 3000 })
```

`AddStatus` is an alias of `SetStatus`. Up to 8 extras. Electric / hybrid vehicles show a battery icon instead of a fuel pump (statebag `fuelType` / `electric`, native EV flag, empty petrol tank, or `Config.ElectricModels`).

The HUD also hides itself while the pause menu is open and while the screen is faded out.

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
