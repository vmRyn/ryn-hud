RynHud = RynHud or {}
RynHud.Loaded = false
RynHud.Peeking = false
RynHud.InVehicle = false
RynHud.VehicleVisible = false
RynHud.Obscured = false
RynHud.AdminOpen = false

local hideComponents = { 1, 2, 3, 4, 6, 7, 8, 9, 13, 17, 19, 20, 21, 22 }
local RESOURCE = GetCurrentResourceName()

local function hideNativeHud()
    for i = 1, #hideComponents do
        HideHudComponentThisFrame(hideComponents[i])
    end
end

local function bootHud()
    if RynHud.Loaded then
        return
    end
    RynHud.Loaded = true
    RynHud.SendNui('setVisible', true)
    TriggerServerEvent('ryn-hud:server:requestTheme')
    if Config.Debug then
        print(('[ryn-hud] booted (%s)'):format(RynHud.GetFramework()))
    end
end

CreateThread(function()
    DisplayRadar(false)
    SetRadarBigmapEnabled(false, false)
end)

RynHud.GetBridge().onPlayerLoaded(bootHud)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(250)
    end
    Wait(1500)
    bootHud()
end)

CreateThread(function()
    while true do
        hideNativeHud()
        Wait(0)
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= RESOURCE then
        return
    end
    if NetworkIsPlayerActive(PlayerId()) then
        RynHud.Loaded = false
        bootHud()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE then
        return
    end
    SetNuiFocus(false, false)
    DisplayRadar(true)
end)

RegisterNUICallback('nuiReady', function(_, cb)
    cb({ ok = true, resource = RESOURCE })
    RynHud.SendNui('setVisible', true)
    TriggerServerEvent('ryn-hud:server:requestTheme')
end)

CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. Config.AdminCommand, L('cmd_admin'))
    TriggerEvent('chat:addSuggestion', '/' .. Config.PeekCommand, L('cmd_peek'))
    TriggerEvent('chat:addSuggestion', '/' .. Config.CinematicCommand, L('cmd_cinematic'))
end)

RegisterKeyMapping(Config.AdminCommand, L('cmd_admin'), 'keyboard', '')
RegisterKeyMapping(Config.CinematicCommand, L('cmd_cinematic'), 'keyboard', '')
