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

-- Seatbelt toggle events from other resources (handler registered for each).
Config.SeatbeltEvents = {
    'seatbelt:client:ToggleSeatbelt',
    'qb-seatbelt:client:ToggleSeatbelt',
    'qbx_seatbelt:client:ToggleSeatbelt',
    'cd_carhud:ToggleSeatbelt',
}

Config.StatusTick = 200
Config.VehicleTick = 100
Config.CompassTick = 400
Config.IdentityTick = 1000

Config.MinimapDelayMs = 80
Config.RadarHideAfterExitMs = 420

-- Print boot/framework info to the F8 console.
Config.Debug = false
