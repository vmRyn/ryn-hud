local saveCooldown = {}
local COOLDOWN_MS = 1200

local function takeCooldown(src)
    local now = GetGameTimer()
    local last = saveCooldown[src]
    if last and (now - last) < COOLDOWN_MS then
        return false
    end
    saveCooldown[src] = now
    return true
end

AddEventHandler('playerDropped', function()
    saveCooldown[source] = nil
end)

RegisterNetEvent('ryn-hud:server:tryOpenAdmin', function()
    local src = source
    if not RynHud.IsAdmin(src) then
        TriggerClientEvent('ryn-hud:client:adminDenied', src)
        return
    end
    TriggerClientEvent('ryn-hud:client:openAdmin', src, RynHud.GetStoredTheme())
end)

RegisterNetEvent('ryn-hud:server:saveTheme', function(theme)
    local src = source
    if not RynHud.IsAdmin(src) then
        TriggerClientEvent('ryn-hud:client:adminDenied', src)
        return
    end
    if type(theme) ~= 'table' then
        return
    end
    if not takeCooldown(src) then
        return
    end
    local saved = RynHud.SaveTheme(theme)
    TriggerClientEvent('ryn-hud:client:applyTheme', -1, saved)
    TriggerClientEvent('ryn-hud:client:themeSaved', src)
end)

RegisterNetEvent('ryn-hud:server:resetTheme', function()
    local src = source
    if not RynHud.IsAdmin(src) then
        TriggerClientEvent('ryn-hud:client:adminDenied', src)
        return
    end
    if not takeCooldown(src) then
        return
    end
    local saved = RynHud.ResetTheme()
    TriggerClientEvent('ryn-hud:client:applyTheme', -1, saved)
    TriggerClientEvent('ryn-hud:client:openAdmin', src, saved)
end)

RegisterNetEvent('ryn-hud:server:requestTheme', function()
    local src = source
    if type(src) ~= 'number' or src <= 0 then
        return
    end
    TriggerClientEvent('ryn-hud:client:applyTheme', src, RynHud.GetStoredTheme())
end)

exports('GetTheme', function()
    return RynHud.GetStoredTheme()
end)
