local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

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

local function getFuel(vehicle)
    local providers = {
        { resource = 'ox_fuel', type = 'state', key = 'fuel' },
        { resource = 'LegacyFuel', export = 'GetFuel' },
        { resource = 'cdn-fuel', export = 'GetFuel' },
        { resource = 'ps-fuel', export = 'GetFuel' },
    }

    for i = 1, #providers do
        local provider = providers[i]
        if resourceStarted(provider.resource) then
            local fuel = getFuelFromProvider(vehicle, provider)
            if fuel ~= nil then
                return fuel
            end
        end
    end

    if type(Config.FuelProviders) == 'table' then
        for i = 1, #Config.FuelProviders do
            local provider = Config.FuelProviders[i]
            if provider and provider.resource and resourceStarted(provider.resource) then
                local fuel = getFuelFromProvider(vehicle, provider)
                if fuel ~= nil then
                    return fuel
                end
            end
        end
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

local function isAirborne(vehicle)
    local class = GetVehicleClass(vehicle)
    return class == 15 or class == 16
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

CreateThread(function()
    while true do
        local wait = Config.VehicleTick or 100
        if RynHud.Loaded then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            if vehicle ~= 0 then
                RynHud.InVehicle = true
                local speedMs = GetEntitySpeed(vehicle)
                local units = (RynHud.Theme and RynHud.Theme.vehicle and RynHud.Theme.vehicle.units) or 'mph'
                local speed = units == 'kph' and (speedMs * 3.6) or (speedMs * 2.236936)
                local rpm = GetVehicleCurrentRpm(vehicle)
                local engine = RynHud.Clamp(GetVehicleEngineHealth(vehicle) / 10.0, 0, 100)
                local airborne = isAirborne(vehicle)
                local class = GetVehicleClass(vehicle)
                local seatbeltVisible = not airborne and class ~= 8 and class ~= 13 and class ~= 14 and class ~= 21
                local seatbelt = getSeatbelt()
                if seatbeltVisible and lastSeatbeltSound ~= nil and lastSeatbeltSound ~= seatbelt then
                    playSeatbeltSound(seatbelt)
                end
                lastSeatbeltSound = seatbelt
                RynHud.PatchState({
                    vehicle = {
                        active = true,
                        speed = RynHud.Round(speed),
                        rpm = RynHud.Round(RynHud.Clamp(rpm * 100, 0, 100)),
                        gear = gearLabel(vehicle, speedMs, airborne),
                        fuel = RynHud.Round(RynHud.Clamp(getFuel(vehicle), 0, 100)),
                        fuelKind = isElectricVehicle(vehicle) and 'electric' or 'petrol',
                        engine = RynHud.Round(engine),
                        seatbelt = seatbelt,
                        seatbeltVisible = seatbeltVisible,
                        cruise = LocalPlayer.state.cruise == true,
                        airborne = airborne,
                        altitude = airborne and RynHud.Round(GetEntityHeightAboveGround(vehicle)) or 0,
                        heading = airborne and RynHud.Round(GetEntityHeading(vehicle)) or 0,
                    },
                })
            else
                if RynHud.InVehicle then
                    RynHud.InVehicle = false
                    RynHud.Seatbelt = false
                    lastSeatbeltSound = nil
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
                        },
                    })
                end
                wait = 250
            end
        else
            wait = 500
        end
        Wait(wait)
    end
end)
