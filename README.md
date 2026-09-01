# ryn-hud

A contextual FiveM HUD with a quiet on-foot cluster, a coordinated vehicle + minimap swipe, and an **admin-only** look editor. Built for QBCore, Qbox, and ESX (auto-detected). Players do not get a personal settings menu — admins set the server look once.

## Features

- Status cluster: health, armor, hunger, thirst, and stress when the framework provides it — plus extra pills from other resources (`SetStatus`)
- Vehicle scene: digital, minimal, analog, or circular speedo — plus gear, petrol or electric fuel, engine, and a square or circular minimap
- Contextual only: voice / radio, stamina, oxygen, weapon name + fire mode, parachute, harness
- Damage flash when health or engine drops
- Optional compass + street, and cash / job chips (off by default; hold Left Alt or `/cash` to peek)
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
| `Config.RadarHideAfterExitMs` | `420` | Matches the exit animation |
| `Config.ElectricModels` | `{}` | Extra EV/hybrid spawn names or hashes |
| `Config.Weapons` | `{}` | Custom weapon labels and fire modes |

Fuel is read from `ox_fuel`, `LegacyFuel`, `cdn-fuel`, or `ps-fuel` when started, otherwise native fuel. Seatbelt uses `LocalPlayer.state.seatbelt` and common toggle events.

Other resources can toggle cinematic mode, hide the HUD, read the current look, or hang extra status pills on the cluster:

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
})
exports['ryn-hud']:SetStatus('drunk', 12)  -- update value only
exports['ryn-hud']:RemoveStatus('drunk')
exports['ryn-hud']:ClearStatuses()
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
