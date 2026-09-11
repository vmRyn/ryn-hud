local seq = 0
local active = 0

local TYPES = {
    info = true,
    success = true,
    warning = true,
    error = true,
    announce = true,
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
    local maxDuration = tonumber(c.maxDuration) or 20000
    local duration = tonumber(opts.duration) or defaultDuration
    duration = math.floor(RynHud.Clamp(duration, 1200, maxDuration))

    local icon = opts.icon
    if icon and not (RynHud.IsAllowedIcon and RynHud.IsAllowedIcon(icon)) then
        icon = nil
    end

    local color = RynHud.SanitizeColor and RynHud.SanitizeColor(opts.color, nil) or nil

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

local function isNotificationsEnabled()
    return enabled()
end

local function getActiveNotificationCount()
    return active
end

RynHud.ShowNotification = showNotification
RynHud.ClearNotifications = clearNotifications
RynHud.PushNotifyConfig = pushConfig

exports('Notify', showNotification)
exports('ShowNotification', showNotification)
exports('SendNotification', showNotification)
exports('Announce', announce)
exports('ClearNotifications', clearNotifications)
exports('IsNotificationsEnabled', isNotificationsEnabled)
exports('GetActiveNotificationCount', getActiveNotificationCount)

RegisterNetEvent('ryn-hud:client:notify', function(data, maybeType, maybeDuration)
    showNotification(data, maybeType, maybeDuration)
end)

RegisterNetEvent('ryn-hud:client:announce', function(data, maybeDuration)
    announce(data, maybeDuration)
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
