local adminOpen = false
RynHud.AdminOpen = false

local function closeAdmin()
    if not adminOpen then
        return
    end
    adminOpen = false
    RynHud.AdminOpen = false
    SetNuiFocus(false, false)
    RynHud.SendNui('closeAdmin', {})
end

RegisterCommand(Config.AdminCommand, function()
    TriggerServerEvent('ryn-hud:server:tryOpenAdmin')
end, false)

RegisterNetEvent('ryn-hud:client:openAdmin', function(theme)
    if RynHud.Cinematic then
        RynHud.SetCinematic(false, true)
    end
    adminOpen = true
    RynHud.AdminOpen = true
    SetNuiFocus(true, true)
    RynHud.ApplyTheme(theme)
    RynHud.SendNui('openAdmin', {
        theme = RynHud.SanitizeTheme(theme),
    })
end)

RegisterNetEvent('ryn-hud:client:adminDenied', function()
    RynHud.Notify('admin_denied')
end)

RegisterNetEvent('ryn-hud:client:applyTheme', function(theme)
    RynHud.ApplyTheme(theme)
end)

RegisterNetEvent('ryn-hud:client:themeSaved', function()
    RynHud.Notify('admin_saved')
end)

RegisterNUICallback('closeAdmin', function(_, cb)
    closeAdmin()
    TriggerServerEvent('ryn-hud:server:requestTheme')
    cb({ ok = true })
end)

RegisterNUICallback('previewTheme', function(data, cb)
    if adminOpen and data and data.theme then
        RynHud.ApplyTheme(data.theme)
    end
    cb({ ok = true })
end)

RegisterNUICallback('saveTheme', function(data, cb)
    if adminOpen then
        TriggerServerEvent('ryn-hud:server:saveTheme', data and data.theme or {})
    end
    cb({ ok = true })
end)

RegisterNUICallback('resetTheme', function(_, cb)
    if adminOpen then
        TriggerServerEvent('ryn-hud:server:resetTheme')
    end
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if adminOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 322, true)
            if IsDisabledControlJustReleased(0, 322) then
                closeAdmin()
                TriggerServerEvent('ryn-hud:server:requestTheme')
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    if adminOpen then
        SetNuiFocus(false, false)
        adminOpen = false
        RynHud.AdminOpen = false
    end
end)
