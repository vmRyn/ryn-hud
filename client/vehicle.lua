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
                RynHud.PatchState({
                    vehicle = {
                        active = true,
                        speed = RynHud.Round(speed),
                        rpm = RynHud.Round(RynHud.Clamp(rpm * 100, 0, 100)),
                        gear = gearLabel(vehicle, speedMs, airborne),
                        fuel = RynHud.Round(RynHud.Clamp(getFuel(vehicle), 0, 100)),
                        engine = RynHud.Round(engine),
                        seatbelt = getSeatbelt(),
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
                    RynHud.PatchState({
                        vehicle = {
                            active = false,
                            speed = 0,
                            rpm = 0,
                            gear = 'N',
                            fuel = 0,
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
