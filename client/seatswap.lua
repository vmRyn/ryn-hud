local open = false
local swapping = false
local lastVehicle = 0

RynHud.SeatSwapOpen = false

local function cfg()
    local c = Config.SeatSwap
    if type(c) ~= 'table' then
        return {
            enabled = c ~= false,
            command = 'seatswap',
            defaultKey = 'G',
            progressMs = 1500,
            canCancel = true,
            maxSpeedMph = 5,
            blockWhenSeatbelt = true,
        }
    end
    return c
end

local function enabled()
    return cfg().enabled ~= false
end

local function getSeatbeltOn()
    if LocalPlayer.state.seatbelt ~= nil then
        return LocalPlayer.state.seatbelt == true
    end
    return RynHud.Seatbelt == true
end

local function seatLabel(index, seatCount)
    if index == -1 then
        return L('seatswap_driver')
    end
    if index == 0 then
        if seatCount <= 2 then
            return L('seatswap_passenger')
        end
        return L('seatswap_front')
    end
    if index == 1 then
        return L('seatswap_rear_l')
    end
    if index == 2 then
        return L('seatswap_rear_r')
    end
    return (L('seatswap_seat')):format(index + 1)
end

local function buildSeats(vehicle)
    local model = GetEntityModel(vehicle)
    local seatCount = GetVehicleModelNumberOfSeats(model) or 0
    if seatCount < 1 then
        seatCount = 1
    end

    local class = GetVehicleClass(vehicle)
    local stacked = seatCount <= 2 or class == 8 or class == 13
    local ped = PlayerPedId()
    local seats = {}

    for i = 0, seatCount - 1 do
        local index = i - 1
        local occupiedPed = GetPedInVehicleSeat(vehicle, index)
        local occupied = occupiedPed ~= 0 and occupiedPed ~= ped and DoesEntityExist(occupiedPed)
        local current = occupiedPed == ped
        local row, col
        if stacked then
            row = i
            col = 0
        else
            row = math.floor(i / 2)
            col = i % 2
        end
        seats[#seats + 1] = {
            index = index,
            label = seatLabel(index, seatCount),
            occupied = occupied,
            current = current,
            row = row,
            col = col,
        }
    end

    return {
        seats = seats,
        seatCount = seatCount,
        layout = stacked and 'stacked' or 'grid',
        title = L('seatswap_title'),
        hint = L('seatswap_hint'),
    }
end

local function closeSeatSwap(silent)
    if not open then
        return false
    end
    open = false
    RynHud.SeatSwapOpen = false
    SetNuiFocus(false, false)
    RynHud.SendNui('closeSeatSwap', {})
    return true
end

local function canOpen()
    if not enabled() or open or swapping then
        return false
    end
    if RynHud.AdminOpen or RynHud.Cinematic then
        return false
    end
    if IsPauseMenuActive() or IsNuiFocused() then
        return false
    end
    if RynHud.IsProgressActive and RynHud.IsProgressActive() then
        return false
    end

    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        RynHud.Notify('seatswap_need_vehicle')
        return false
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        RynHud.Notify('seatswap_need_vehicle')
        return false
    end

    local maxMph = tonumber(cfg().maxSpeedMph)
    if maxMph and maxMph > 0 then
        local speedMs = GetEntitySpeed(vehicle)
        if (speedMs * 2.236936) > maxMph then
            RynHud.Notify('seatswap_speed')
            return false
        end
    end

    if cfg().blockWhenSeatbelt ~= false and getSeatbeltOn() then
        RynHud.Notify('seatswap_belt')
        return false
    end

    return true, vehicle
end

local function openSeatSwap()
    local ok, vehicle = canOpen()
    if not ok then
        return false
    end

    lastVehicle = vehicle
    open = true
    RynHud.SeatSwapOpen = true
    SetNuiFocus(true, true)
    RynHud.SendNui('openSeatSwap', buildSeats(vehicle))
    return true
end

local function toggleSeatSwap()
    if open then
        closeSeatSwap()
        return false
    end
    return openSeatSwap()
end

local function warpToSeat(vehicle, seat)
    local ped = PlayerPedId()
    if not DoesEntityExist(vehicle) or not IsPedInAnyVehicle(ped, false) then
        return false
    end
    if GetVehiclePedIsIn(ped, false) ~= vehicle then
        return false
    end
    if not IsVehicleSeatFree(vehicle, seat) then
        local occupant = GetPedInVehicleSeat(vehicle, seat)
        if occupant ~= 0 and occupant ~= ped then
            return false
        end
    end

    ClearPedTasks(ped)
    SetPedIntoVehicle(ped, vehicle, seat)
    return GetPedInVehicleSeat(vehicle, seat) == ped
end

local function selectSeat(seatIndex)
    if not open or swapping then
        return false
    end

    seatIndex = tonumber(seatIndex)
    if seatIndex == nil then
        return false
    end

    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        closeSeatSwap()
        RynHud.Notify('seatswap_need_vehicle')
        return false
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        closeSeatSwap()
        return false
    end

    if GetPedInVehicleSeat(vehicle, seatIndex) == ped then
        closeSeatSwap()
        return true
    end

    if not IsVehicleSeatFree(vehicle, seatIndex) then
        RynHud.Notify('seatswap_busy')
        return false
    end

    local maxMph = tonumber(cfg().maxSpeedMph)
    if maxMph and maxMph > 0 then
        local speedMs = GetEntitySpeed(vehicle)
        if (speedMs * 2.236936) > maxMph then
            RynHud.Notify('seatswap_speed')
            return false
        end
    end

    if cfg().blockWhenSeatbelt ~= false and getSeatbeltOn() then
        RynHud.Notify('seatswap_belt')
        return false
    end

    closeSeatSwap()

    swapping = true
    lastVehicle = vehicle

    CreateThread(function()
        local ok = true
        local duration = math.floor(tonumber(cfg().progressMs) or 1500)
        if duration < 0 then
            duration = 0
        end

        if duration > 0 then
            local progressOn = RynHud.IsProgressEnabled and RynHud.IsProgressEnabled()
            if progressOn and RynHud.Progress then
                ok = RynHud.Progress({
                    label = L('seatswap_progress'),
                    duration = duration,
                    canCancel = cfg().canCancel ~= false,
                    disable = true,
                    icon = 'info',
                }) == true
            else
                local endsAt = GetGameTimer() + duration
                while GetGameTimer() < endsAt do
                    if not DoesEntityExist(vehicle) or GetVehiclePedIsIn(PlayerPedId(), false) ~= vehicle then
                        ok = false
                        break
                    end
                    Wait(0)
                end
            end
        end

        if not ok then
            swapping = false
            return
        end

        if not DoesEntityExist(vehicle) or GetVehiclePedIsIn(PlayerPedId(), false) ~= vehicle then
            RynHud.Notify('seatswap_failed')
            swapping = false
            return
        end

        if not IsVehicleSeatFree(vehicle, seatIndex) then
            RynHud.Notify('seatswap_busy')
            swapping = false
            return
        end

        if not warpToSeat(vehicle, seatIndex) then
            RynHud.Notify('seatswap_failed')
        end
        swapping = false
    end)

    return true
end

RynHud.CloseSeatSwap = closeSeatSwap
RynHud.OpenSeatSwap = openSeatSwap
RynHud.ToggleSeatSwap = toggleSeatSwap

RegisterCommand(cfg().command or 'seatswap', function()
    toggleSeatSwap()
end, false)

RegisterKeyMapping(cfg().command or 'seatswap', L('cmd_seatswap'), 'keyboard', cfg().defaultKey or 'G')

RegisterNUICallback('closeSeatSwap', function(_, cb)
    closeSeatSwap()
    cb({ ok = true })
end)

RegisterNUICallback('selectSeat', function(data, cb)
    local index = data and (data.index or data.seat)
    local ok = selectSeat(index)
    cb({ ok = ok == true })
end)

CreateThread(function()
    while true do
        if open then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 75, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 322, true)

            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) or IsPauseMenuActive() then
                closeSeatSwap()
            elseif IsDisabledControlJustReleased(0, 322) then
                closeSeatSwap()
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. (cfg().command or 'seatswap'), L('cmd_seatswap'))
end)

exports('OpenSeatSwap', openSeatSwap)
exports('CloseSeatSwap', closeSeatSwap)
exports('ToggleSeatSwap', toggleSeatSwap)
exports('IsSeatSwapOpen', function()
    return open == true
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    if open then
        SetNuiFocus(false, false)
        open = false
        RynHud.SeatSwapOpen = false
    end
end)
