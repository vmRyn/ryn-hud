--- Server helpers to push HUD toasts to one player or everyone.
--- Prefer client exports when you already run on the client.

local function notify(target, data, maybeType, maybeDuration)
    if target == nil then
        return false
    end
    TriggerClientEvent('ryn-hud:client:notify', target, data, maybeType, maybeDuration)
    return true
end

local function announce(target, data, maybeDuration)
    if target == nil then
        return false
    end
    TriggerClientEvent('ryn-hud:client:announce', target, data, maybeDuration)
    return true
end

local function clear(target)
    if target == nil then
        return false
    end
    TriggerClientEvent('ryn-hud:client:clearNotifications', target)
    return true
end

exports('Notify', notify)
exports('Announce', announce)
exports('ClearNotifications', clear)
