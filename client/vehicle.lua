local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

local BUILTIN_FUEL_PROVIDERS = {
    { resource = 'ox_fuel', type = 'state', key = 'fuel' },
    { resource = 'LegacyFuel', export = 'GetFuel' },
    { resource = 'cdn-fuel', export = 'GetFuel' },
    { resource = 'ps-fuel', export = 'GetFuel' },
}

-- Resolved once every few seconds so GetResourceState isn't hit every vehicle tick.
local cachedFuelProvider = nil
local fuelProviderUntil = 0

local function getFuelFromProvider(vehicle, provider)
    if provider.type == 'state' then
        local ok, state = pcall(function()
            return Entity(vehicle).state
        end)
        if not ok or not state then
            return nil
        end
        local fuel = state[provider.key or 'fuel']
        if type(fuel) == 'number' then
            return fuel
        end
        return nil
    end

    if not provider.export or not provider.resource then
        return nil
    end

    local ok, fuel = pcall(function()
        return exports[provider.resource][provider.export](vehicle)
    end)
    if ok and type(fuel) == 'number' then
        return fuel
    end
    return nil
end

local function resolveFuelProvider()
    local now = GetGameTimer()
    if now < fuelProviderUntil then
        return cachedFuelProvider
    end
    fuelProviderUntil = now + 2500

    for i = 1, #BUILTIN_FUEL_PROVIDERS do
        local provider = BUILTIN_FUEL_PROVIDERS[i]
        if resourceStarted(provider.resource) then
            cachedFuelProvider = provider
            return provider
        end
    end

    if type(Config.FuelProviders) == 'table' then
        for i = 1, #Config.FuelProviders do
            local provider = Config.FuelProviders[i]
            if provider and provider.resource and resourceStarted(provider.resource) then
                cachedFuelProvider = provider
                return provider
            end
        end
    end

    cachedFuelProvider = false
    return false
end

local function getFuel(vehicle)
    local provider = resolveFuelProvider()
    if provider then
        local fuel = getFuelFromProvider(vehicle, provider)
        if fuel ~= nil then
            return fuel
        end
        -- Provider started but returned nil once — fall through to native and retry resolve soon.
        fuelProviderUntil = 0
    end
    return GetVehicleFuelLevel(vehicle)
end

local function getSeatbelt()
    if LocalPlayer.state.seatbelt ~= nil then
        return LocalPlayer.state.seatbelt == true
    end
    if LocalPlayer.state.harness == true then
        return true
    end
    return RynHud.Seatbelt == true
end

local function setSeatbeltState(state)
    if type(state) == 'boolean' then
        RynHud.Seatbelt = state
    else
        RynHud.Seatbelt = not RynHud.Seatbelt
    end
end

local function registerSeatbeltEvents()
    local events = Config.SeatbeltEvents or {}
    for i = 1, #events do
        local eventName = events[i]
        if type(eventName) == 'string' and eventName ~= '' then
            RegisterNetEvent(eventName, function(state)
                setSeatbeltState(state)
            end)
        end
    end
end

registerSeatbeltEvents()

local lastSeatbeltSound = nil

local function playSeatbeltSound(on)
    if Config.SeatbeltSounds == false then
        return
    end
    RynHud.SendNui('playSound', {
        id = on and 'seatbeltOn' or 'seatbeltOff',
        volume = RynHud.Clamp(tonumber(Config.SeatbeltSoundVolume) or 0.45, 0, 1),
    })
end

local ELECTRIC_MODELS = {
    [`voltic`] = true,
    [`voltic2`] = true,
    [`neon`] = true,
    [`raiden`] = true,
    [`tezeract`] = true,
    [`cyclone`] = true,
    [`cyclone2`] = true,
    [`iwagen`] = true,
    [`omnisegt`] = true,
    [`virtue`] = true,
    [`powersurge`] = true,
    [`khamelion`] = true,
    [`dilettante`] = true,
    [`dilettante2`] = true,
    [`surge`] = true,
    [`caddy`] = true,
    [`caddy2`] = true,
    [`caddy3`] = true,
    [`airtug`] = true,
}

local function addElectricModel(entry)
    if type(entry) == 'string' and entry ~= '' then
        ELECTRIC_MODELS[joaat(entry)] = true
    elseif type(entry) == 'number' then
        ELECTRIC_MODELS[entry] = true
    end
end

if type(Config.ElectricModels) == 'table' then
    for key, value in pairs(Config.ElectricModels) do
        if type(key) == 'string' then
            addElectricModel(key)
            if value ~= true and value ~= false then
                addElectricModel(value)
            end
        elseif value == true and type(key) == 'number' then
            addElectricModel(key)
        else
            addElectricModel(value)
        end
    end
end

local function isElectricVehicle(vehicle)
    local okState, entState = pcall(function()
        return Entity(vehicle).state
    end)
    if okState and entState then
        local kind = entState.fuelType or entState.powertrain
        if type(kind) == 'string' then
            kind = kind:lower()
            if kind == 'electric' or kind == 'ev' or kind == 'hybrid' then
                return true
            end
            if kind == 'petrol' or kind == 'diesel' or kind == 'gas' then
                return false
            end
        end
        if entState.electric == true then
            return true
        end
    end

    if type(GetIsVehicleElectric) == 'function' then
        local ok, electric = pcall(GetIsVehicleElectric, vehicle)
        if ok and electric then
            return true
        end
    end

    local model = GetEntityModel(vehicle)
    if ELECTRIC_MODELS[model] then
        return true
    end

    local okTank, tank = pcall(GetVehicleHandlingFloat, vehicle, 'CHandlingData', 'fPetrolTankVolume')
    return okTank and type(tank) == 'number' and tank <= 0.01
end

local function gearLabel(vehicle, speedMs, airborne)
    if airborne then
        return 'N'
    end
    local gear = GetVehicleCurrentGear(vehicle)
    if gear == 0 then
        return 'R'
    end
    local rpm = GetVehicleCurrentRpm(vehicle)
    if speedMs < 0.15 and rpm < 0.28 then
        return 'N'
    end
    return tostring(gear)
end

local JG_MILEAGE_RESOURCE = 'jg-vehiclemileage'
local jgMileageUnit = nil

local function jgMileageEnabled()
    return Config.JGMileage == true and resourceStarted(JG_MILEAGE_RESOURCE)
end

local function refreshJgMileageUnit()
    if not jgMileageEnabled() then
        jgMileageUnit = nil
        return
    end
    local ok, unit = pcall(function()
        return exports[JG_MILEAGE_RESOURCE]:getUnit()
    end)
    if ok and (unit == 'miles' or unit == 'kilometers') then
        jgMileageUnit = unit
    else
        jgMileageUnit = 'miles'
    end
end

-- Classes JG skips for the odometer (cycles/boats/heli/plane/service/trains).
local function jgMileageClassAllowed(class)
    return class ~= 13 and class ~= 14 and class ~= 15 and class ~= 16 and class ~= 17 and class ~= 21
end

-- JG stores km in entity state; only show once tracking has populated it.
local function getJgMileage(vehicle, class)
    if not jgMileageEnabled() or not jgMileageClassAllowed(class) then
        return nil, nil
    end
    if not jgMileageUnit then
        refreshJgMileageUnit()
    end

    local ok, state = pcall(function()
        return Entity(vehicle).state
    end)
    if not ok or not state then
        return nil, nil
    end

    local km = state.vehicleMileage
    if type(km) ~= 'number' then
        return nil, nil
    end

    local unit = jgMileageUnit or 'miles'
    local value = unit == 'miles' and (km * 0.621371) or km
    return math.floor(value), unit == 'miles' and 'mi' or 'km'
end

CreateThread(function()
    while true do
        if Config.JGMileage == true then
            refreshJgMileageUnit()
        else
            jgMileageUnit = nil
        end
        Wait(5000)
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == JG_MILEAGE_RESOURCE and Config.JGMileage == true then
        refreshJgMileageUnit()
    end
    fuelProviderUntil = 0
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == JG_MILEAGE_RESOURCE then
        jgMileageUnit = nil
    end
    fuelProviderUntil = 0
end)

-- Per-vehicle statics (class / EV / seatbelt UI) — refreshed on vehicle change only.
local vehMeta = {
    entity = 0,
    class = 0,
    airborne = false,
    seatbeltVisible = false,
    electric = false,
    mileage = nil,
    mileageUnit = nil,
    mileageAt = 0,
}

local function refreshVehMeta(vehicle)
    if vehMeta.entity == vehicle then
        return
    end
    local class = GetVehicleClass(vehicle)
    local airborne = class == 15 or class == 16
    vehMeta.entity = vehicle
    vehMeta.class = class
    vehMeta.airborne = airborne
    vehMeta.seatbeltVisible = not airborne and class ~= 8 and class ~= 13 and class ~= 14 and class ~= 21
    vehMeta.electric = isElectricVehicle(vehicle)
    vehMeta.mileage = nil
    vehMeta.mileageUnit = nil
    vehMeta.mileageAt = 0
end

local function readMileage(vehicle)
    local now = GetGameTimer()
    if now - vehMeta.mileageAt < 1000 then
        return vehMeta.mileage, vehMeta.mileageUnit
    end
    local mileage, unit = getJgMileage(vehicle, vehMeta.class)
    vehMeta.mileage = mileage
    vehMeta.mileageUnit = unit
    vehMeta.mileageAt = now
    return mileage, unit
end

CreateThread(function()
    while true do
        local wait = Config.VehicleTick or 100
        if RynHud.Loaded then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            if vehicle ~= 0 then
                RynHud.InVehicle = true
                refreshVehMeta(vehicle)
                if RynHud.ShouldPushHud and not RynHud.ShouldPushHud() then
                    wait = math.max(wait, 250)
                else
                    local speedMs = GetEntitySpeed(vehicle)
                    local units = (RynHud.Theme and RynHud.Theme.vehicle and RynHud.Theme.vehicle.units) or 'mph'
                    local speed = units == 'kph' and (speedMs * 3.6) or (speedMs * 2.236936)
                    local rpm = GetVehicleCurrentRpm(vehicle)
                    local engine = RynHud.Clamp(GetVehicleEngineHealth(vehicle) / 10.0, 0, 100)
                    local airborne = vehMeta.airborne
                    local seatbeltVisible = vehMeta.seatbeltVisible
                    local seatbelt = getSeatbelt()
                    if seatbeltVisible and lastSeatbeltSound ~= nil and lastSeatbeltSound ~= seatbelt then
                        playSeatbeltSound(seatbelt)
                    end
                    lastSeatbeltSound = seatbelt
                    local mileage, mileageUnit = readMileage(vehicle)
                    local showMileage = mileage ~= nil
                    RynHud.PatchState({
                        vehicle = {
                            active = true,
                            speed = RynHud.Round(speed),
                            rpm = RynHud.Round(RynHud.Clamp(rpm * 100, 0, 100)),
                            gear = gearLabel(vehicle, speedMs, airborne),
                            fuel = RynHud.Round(RynHud.Clamp(getFuel(vehicle), 0, 100)),
                            fuelKind = vehMeta.electric and 'electric' or 'petrol',
                            engine = RynHud.Round(engine),
                            seatbelt = seatbelt,
                            seatbeltVisible = seatbeltVisible,
                            cruise = LocalPlayer.state.cruise == true,
                            airborne = airborne,
                            altitude = airborne and RynHud.Round(GetEntityHeightAboveGround(vehicle)) or 0,
                            heading = airborne and RynHud.Round(GetEntityHeading(vehicle)) or 0,
                            mileage = showMileage and mileage or 0,
                            mileageUnit = mileageUnit or 'mi',
                            mileageVisible = showMileage,
                        },
                    })
                end
            else
                if RynHud.InVehicle then
                    RynHud.InVehicle = false
                    RynHud.Seatbelt = false
                    lastSeatbeltSound = nil
                    vehMeta.entity = 0
                    RynHud.PatchState({
                        vehicle = {
                            active = false,
                            speed = 0,
                            rpm = 0,
                            gear = 'N',
                            fuel = 0,
                            fuelKind = 'petrol',
                            engine = 100,
                            seatbelt = false,
                            seatbeltVisible = false,
                            cruise = false,
                            airborne = false,
                            altitude = 0,
                            heading = 0,
                            mileage = 0,
                            mileageUnit = 'mi',
                            mileageVisible = false,
                        },
                    })
                end
                wait = 350
            end
        else
            wait = 500
        end
        Wait(wait)
    end
end)
