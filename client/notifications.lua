local seq = 0
local active = 0

local TYPES = {
    info = true,
    success = true,
    warning = true,
    error = true,
    announce = true,
    item = true,
}

local TYPE_ALIASES = {
    info = 'info',
    inform = 'info',
    information = 'info',
    primary = 'info',
    success = 'success',
    ok = 'success',
    warning = 'warning',
    warn = 'warning',
    error = 'error',
    danger = 'error',
    destructive = 'error',
    fail = 'error',
    announce = 'announce',
    announcement = 'announce',
    item = 'item',
    pickup = 'item',
    inventory = 'item',
    received = 'item',
}

local POSITIONS = {
    ['top-left'] = true,
    ['top-right'] = true,
    ['bottom-left'] = true,
    ['bottom-right'] = true,
}

local function cfg()
    local c = Config.Notifications
    if type(c) ~= 'table' then
        return {
            enabled = c ~= false,
            position = 'top-right',
            offsetX = 2.2,
            offsetY = 2.0,
            maxVisible = 5,
            defaultDuration = 5000,
            maxDuration = 20000,
            sound = true,
            soundVolume = 0.4,
        }
    end
    return c
end

local function enabled()
    return cfg().enabled ~= false
end

local function pushConfig()
    if not RynHud.SendNui then
        return
    end
    local c = cfg()
    local position = POSITIONS[c.position] and c.position or 'top-right'
    RynHud.SendNui('setNotifyConfig', {
        enabled = c.enabled ~= false,
        position = position,
        offsetX = RynHud.Clamp(tonumber(c.offsetX) or 2.2, 0, 12),
        offsetY = RynHud.Clamp(tonumber(c.offsetY) or 2.0, 0, 12),
        maxVisible = math.floor(RynHud.Clamp(tonumber(c.maxVisible) or 5, 1, 8)),
        sound = c.sound ~= false,
        soundVolume = RynHud.Clamp(tonumber(c.soundVolume) or 0.4, 0, 1),
    })
end

local function sanitizeType(value)
    if type(value) ~= 'string' then
        return 'info'
    end
    local key = value:lower():gsub('%s+', '')
    local mapped = TYPE_ALIASES[key]
    if mapped and TYPES[mapped] then
        return mapped
    end
    return 'info'
end

local function sanitizeText(value, maxLen)
    if type(value) ~= 'string' then
        return nil
    end
    value = value:gsub('%s+', ' '):match('^%s*(.-)%s*$') or ''
    if value == '' then
        return nil
    end
    if #value > maxLen then
        value = value:sub(1, maxLen)
    end
    return value
end

--- Show a toast notification.
--- Notify('message')
--- Notify('message', 'success')
--- Notify('message', 'warning', 6000)
--- Notify('message', { type = 'error', title = 'Denied', duration = 4000 })
--- Notify({ title = 'Bank', message = 'Paid', type = 'success', icon = 'check', color = '#4CB8A8' })
---@return string|false id
local function showNotification(data, maybeType, maybeDuration)
    if not enabled() then
        return false
    end

    local opts = {}
    if type(data) == 'string' then
        opts.message = data
        if type(maybeType) == 'string' then
            opts.type = maybeType
        elseif type(maybeType) == 'table' then
            for k, v in pairs(maybeType) do
                opts[k] = v
            end
            opts.message = data
        end
        if type(maybeDuration) == 'number' then
            opts.duration = maybeDuration
        end
    elseif type(data) == 'table' then
        opts = data
    else
        return false
    end

    local message = sanitizeText(
        opts.message or opts.description or opts.text or opts.msg,
        220
    )
    if not message then
        return false
    end

    local title = sanitizeText(opts.title or opts.header or opts.caption or opts.subject, 48)
    local nType = sanitizeType(opts.type or opts.level or opts.style or 'info')
    local c = cfg()
    local defaultDuration = tonumber(c.defaultDuration) or 5000
    if nType == 'item' then
        defaultDuration = tonumber(c.itemDuration) or 3200
    end
    local maxDuration = tonumber(c.maxDuration) or 20000
    local duration = tonumber(opts.duration) or defaultDuration
    duration = math.floor(RynHud.Clamp(duration, 1200, maxDuration))

    local icon = opts.icon
    if icon and not (RynHud.IsAllowedIcon and RynHud.IsAllowedIcon(icon)) then
        icon = nil
    end
    if not icon and nType == 'item' then
        icon = 'package'
    end

    local color = RynHud.SanitizeColor and RynHud.SanitizeColor(opts.color, nil) or nil
    local count = tonumber(opts.count or opts.amount or opts.qty)
    if count then
        count = math.floor(RynHud.Clamp(count, -9999, 9999))
        if count == 0 then
            count = nil
        end
    end

    seq = seq + 1
    active = active + 1
    local id = ('n-%d-%d'):format(GetGameTimer(), seq)

    RynHud.SendNui('notify', {
        id = id,
        title = title,
        message = message,
        type = nType,
        duration = duration,
        icon = icon,
        color = color,
        count = count,
    })

    SetTimeout(duration + 400, function()
        active = math.max(0, active - 1)
    end)

    return id
end

local function clearNotifications()
    if not enabled() then
        return false
    end
    active = 0
    RynHud.SendNui('clearNotifications')
    return true
end

--- Announce-styled toast (title defaults to Announcement).
---@return string|false id
local function announce(data, maybeDuration)
    if type(data) == 'string' then
        return showNotification({
            message = data,
            type = 'announce',
            title = 'Announcement',
            duration = maybeDuration,
        })
    end
    if type(data) == 'table' then
        local copy = RynHud.DeepCopy(data) or {}
        copy.type = 'announce'
        if not copy.title and not copy.header and not copy.caption then
            copy.title = 'Announcement'
        end
        return showNotification(copy)
    end
    return false
end

--- Lightweight item pickup / remove feedback.
--- NotifyItem('Lockpick', 2)                 → "Received Lockpick ×2"
--- NotifyItem('Lockpick')                    → "Received Lockpick"
--- NotifyItem({ name = 'Lockpick', count = 2, removed = true })
--- NotifyItem({ name = 'Bandage', count = 3, icon = 'heart' })
---@return string|false id
local function notifyItem(data, maybeCount, maybeOpts)
    if not enabled() then
        return false
    end

    local opts = {}
    if type(data) == 'string' then
        opts.name = data
        if type(maybeCount) == 'number' then
            opts.count = maybeCount
        elseif type(maybeCount) == 'table' then
            for k, v in pairs(maybeCount) do
                opts[k] = v
            end
            opts.name = data
        end
        if type(maybeOpts) == 'table' then
            for k, v in pairs(maybeOpts) do
                opts[k] = v
            end
            opts.name = opts.name or data
        end
    elseif type(data) == 'table' then
        opts = data
    else
        return false
    end

    local name = sanitizeText(opts.name or opts.item or opts.label or opts.message, 48)
    if not name then
        return false
    end

    local count = tonumber(opts.count or opts.amount or opts.qty)
    if type(maybeCount) == 'number' and opts.count == nil then
        count = maybeCount
    end
    if count then
        count = math.floor(count)
    end

    local removed = opts.removed == true or opts.action == 'removed' or opts.action == 'remove' or opts.lose == true
    local verb = sanitizeText(opts.verb, 24)
    if not verb then
        verb = removed and 'Removed' or 'Received'
    end

    local message = opts.message or opts.text
    if type(message) ~= 'string' or message == '' then
        if count and math.abs(count) ~= 1 then
            message = ('%s %s ×%d'):format(verb, name, math.abs(count))
        else
            message = ('%s %s'):format(verb, name)
        end
    end

    return showNotification({
        type = 'item',
        message = message,
        count = count,
        icon = opts.icon,
        color = opts.color,
        duration = opts.duration,
    })
end

local function isNotificationsEnabled()
    return enabled()
end

local function getActiveNotificationCount()
    return active
end

RynHud.ShowNotification = showNotification
RynHud.NotifyItem = notifyItem
RynHud.ClearNotifications = clearNotifications
RynHud.PushNotifyConfig = pushConfig

exports('Notify', showNotification)
exports('ShowNotification', showNotification)
exports('SendNotification', showNotification)
exports('Announce', announce)
exports('NotifyItem', notifyItem)
exports('ItemNotify', notifyItem)
exports('ClearNotifications', clearNotifications)
exports('IsNotificationsEnabled', isNotificationsEnabled)
exports('GetActiveNotificationCount', getActiveNotificationCount)

RegisterNetEvent('ryn-hud:client:notify', function(data, maybeType, maybeDuration)
    showNotification(data, maybeType, maybeDuration)
end)

RegisterNetEvent('ryn-hud:client:announce', function(data, maybeDuration)
    announce(data, maybeDuration)
end)

RegisterNetEvent('ryn-hud:client:notifyItem', function(data, maybeCount, maybeOpts)
    notifyItem(data, maybeCount, maybeOpts)
end)

RegisterNetEvent('ryn-hud:client:clearNotifications', function()
    clearNotifications()
end)

AddEventHandler('ryn-hud:client:nuiReady', function()
    pushConfig()
end)

CreateThread(function()
    Wait(0)
    pushConfig()
end)
