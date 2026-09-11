Config = {}

-- 'auto' | 'qb' | 'qbx' | 'esx'
Config.Framework = 'auto'

Config.Locale = 'en'

Config.AdminCommand = 'hudadmin'
-- ACE: add_ace group.admin ryn-hud.admin allow
Config.AdminAce = 'ryn-hud.admin'
Config.AdminGroups = {
    god = true,
    admin = true,
    superadmin = true,
}

Config.PeekCommand = 'cash'
Config.PeekControl = 19 -- INPUT_CHARACTER_WHEEL (Left Alt)

Config.CinematicCommand = 'cinematic'
Config.CinematicBarHeight = 11 -- vh, sent to NUI letterbox bars

-- Extra fuel providers tried in order after built-ins (resource + export name).
Config.FuelProviders = {
    { resource = 'Renewed-Fuel', export = 'GetFuel' },
    { resource = 'lc_fuel', export = 'GetFuel' },
    { resource = 'okokGasStation', export = 'GetFuel' },
    { resource = 'ti_fuel', export = 'GetFuel' },
    { resource = 'lj-fuel', export = 'GetFuel' },
}

-- Show odometer from jg-vehiclemileage inside the vehicle HUD.
-- https://github.com/jgscripts/jg-vehiclemileage
-- When true: ensure jg-vehiclemileage is started, and set its Config.ShowMileage = false
-- so the default JG odometer UI does not stack on top of this HUD.
Config.JGMileage = false

-- Seatbelt toggle events from other resources (handler registered for each).
Config.SeatbeltEvents = {
    'seatbelt:client:ToggleSeatbelt',
    'qb-seatbelt:client:ToggleSeatbelt',
    'qbx_seatbelt:client:ToggleSeatbelt',
    'cd_carhud:ToggleSeatbelt',
}

Config.SeatbeltSounds = true
Config.SeatbeltSoundVolume = 0.45

Config.StatusTick = 200
Config.VehicleTick = 100
Config.CompassTick = 400
Config.IdentityTick = 1000

-- Display HP that maps to a full health glyph (GTA ped: entity 100 + this value).
-- Health above this (e.g. drugs raising max/current) shows as overheal on the glyph.
Config.BaseMaxHealth = 100
-- Hard cap for displayed overheal (100 = normal full, 150 = +50 overflow).
Config.MaxDisplayHealth = 150

Config.MinimapDelayMs = 80
Config.RadarHideAfterExitMs = 420

-- Extra spawn names (or model hashes) treated as electric / hybrid (battery icon).
-- Array or map — both work:
--   { 'myev', 'customtesla' }
--   { myev = true, [`customtesla`] = true }
Config.ElectricModels = {
    -- 'myev',
}

-- Custom / add-on weapons. Keys are WEAPON_* names or hashes.
-- label = chip name, fireMode = Semi / Auto / Pump / Bolt / Single (optional).
Config.Weapons = {
    -- WEAPON_CUSTOMRIFLE = { label = 'AR-15', fireMode = 'Auto' },
    -- ['WEAPON_BEANBAG'] = { label = 'Beanbag', fireMode = 'Pump' },
}

-- Optional toast / announcement notifications (exports + net events).
-- Set enabled = false to no-op Notify / Announce / ClearNotifications.
Config.Notifications = {
    enabled = true,
    position = 'top-right', -- top-left | top-right | bottom-left | bottom-right
    offsetX = 2.2,
    offsetY = 2.0,
    maxVisible = 5,
    defaultDuration = 5000,
    itemDuration = 3200, -- lighter item pickup toasts
    maxDuration = 20000,
    sound = true,
    soundVolume = 0.4,
}

-- Optional bottom-center progress bar (always centered; stacks above status glyphs
-- when the status cluster is also bottom-center).
Config.Progress = {
    enabled = true,
    cancelControl = 73, -- INPUT_VEH_DUCK / X — used when canCancel = true
}

-- In-vehicle seat swapper (key opens a seat diagram; progress runs before the warp).
Config.SeatSwap = {
    enabled = true,
    command = 'seatswap',
    defaultKey = 'G', -- RegisterKeyMapping; players can rebind in FiveM settings
    progressMs = 3000, -- wait before swapping (0 = instant, no progress bar)
    canCancel = true, -- cancel progress with Config.Progress.cancelControl
    maxSpeedMph = 15, -- 0 = allow at any speed
    blockWhenSeatbelt = true,
}

-- Print boot/framework info to the F8 console.
Config.Debug = false
